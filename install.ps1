# Open AgentHub — all-in-one quickstart for Windows
#
#   iwr -useb https://open-agenthub.github.io/install.ps1 | iex
#
# Uses Docker Desktop and creates a single-node k3d cluster, then deploys
# Open AgentHub from the official Helm repository — including persistent
# object storage (Garage) for session resume, history and artifacts.
# No winget/choco needed — k3d, kubectl and helm are downloaded to a local
# tools directory if missing. Works in Windows PowerShell 5.1 and PowerShell 7.
# Recommended: 4 vCPU / 6 GB RAM for the Docker VM (good for up to ~6 users).
#
# Optional environment variables:
#   AGENTHUB_OBJECT_STORAGE=0   skip the bundled object storage (not recommended)
#   AGENTHUB_CHART=<ref>        chart to install (default: agenthub/open-agenthub)

# Everything runs in its own scope: `iex` would otherwise leave variables, functions
# and preference changes behind in the caller's session.
& {
# Native tools (k3d, kubectl, helm) report progress on stderr, which Windows
# PowerShell 5.1 turns into terminating errors under 'Stop'. Exit codes are checked
# explicitly instead; cmdlets that must not fail carry -ErrorAction Stop.
$ErrorActionPreference = 'Continue'

$HelmRepo  = 'https://open-agenthub.github.io/open-agenthub'
$Namespace = 'agenthub'
$Cluster   = 'agenthub'
$Context   = "k3d-$Cluster"
$Bin       = Join-Path $env:LOCALAPPDATA 'open-agenthub\bin'
$Chart     = if ($env:AGENTHUB_CHART) { $env:AGENTHUB_CHART } else { 'agenthub/open-agenthub' }
$WithObjectStorage = $env:AGENTHUB_OBJECT_STORAGE -ne '0'

function Say($msg)  { Write-Host "[open-agenthub] $msg" -ForegroundColor Yellow }
function Fail($msg) { Write-Host "[open-agenthub] ERROR: $msg" -ForegroundColor Red; throw "open-agenthub: $msg" }
function Assert-Ok($what) { if ($LASTEXITCODE -ne 0) { Fail "$what failed" } }

# Works on .NET Framework (Windows PowerShell 5.1) as well as .NET Core.
function New-HexSecret([int]$Bytes) {
    $buffer = New-Object byte[] $Bytes
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($buffer) } finally { $rng.Dispose() }
    return (($buffer | ForEach-Object { $_.ToString('x2') }) -join '')
}

# Reads a value out of an existing secret; empty when absent. Secrets are never
# regenerated on a re-run: Postgres keeps the password it was initialised with,
# and a new storage key would leave every stored object unreachable.
function Get-ExistingSecretValue([string]$Secret, [string]$Key) {
    $encoded = & kubectl --context $Context -n $Namespace get secret $Secret -o "jsonpath={.data.$Key}" 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($encoded)) { return '' }
    try { return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encoded)) } catch { return '' }
}

# --- Docker Desktop -------------------------------------------------------------
$dockerOk = $true
try { & docker info *> $null; if ($LASTEXITCODE -ne 0) { $dockerOk = $false } } catch { $dockerOk = $false }
if (-not $dockerOk) {
    Fail 'Docker is not running - install/start Docker Desktop first: https://www.docker.com/products/docker-desktop/'
}

# --- Local tools dir ------------------------------------------------------------
New-Item -ItemType Directory -Force $Bin -ErrorAction Stop | Out-Null
if ($env:Path -notlike "*$Bin*") { $env:Path = "$Bin;$env:Path" }
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Say 'downloading kubectl'
    $kver = (Invoke-WebRequest -UseBasicParsing -ErrorAction Stop 'https://dl.k8s.io/release/stable.txt').Content.Trim()
    Invoke-WebRequest -UseBasicParsing -ErrorAction Stop "https://dl.k8s.io/release/$kver/bin/windows/amd64/kubectl.exe" -OutFile (Join-Path $Bin 'kubectl.exe')
}

if (-not (Get-Command k3d -ErrorAction SilentlyContinue)) {
    Say 'downloading k3d'
    Invoke-WebRequest -UseBasicParsing -ErrorAction Stop 'https://github.com/k3d-io/k3d/releases/latest/download/k3d-windows-amd64.exe' -OutFile (Join-Path $Bin 'k3d.exe')
}

if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
    Say 'downloading helm'
    $hver = (Invoke-WebRequest -UseBasicParsing -ErrorAction Stop 'https://get.helm.sh/helm-latest-version').Content.Trim()
    $zip = Join-Path $env:TEMP 'helm.zip'
    Invoke-WebRequest -UseBasicParsing -ErrorAction Stop "https://get.helm.sh/helm-$hver-windows-amd64.zip" -OutFile $zip
    Expand-Archive -Force -ErrorAction Stop $zip (Join-Path $env:TEMP 'helm-extract')
    Copy-Item (Join-Path $env:TEMP 'helm-extract\windows-amd64\helm.exe') (Join-Path $Bin 'helm.exe') -Force -ErrorAction Stop
    Remove-Item -Recurse -Force $zip, (Join-Path $env:TEMP 'helm-extract') -ErrorAction SilentlyContinue
}

# --- Kubernetes: single-node k3d cluster inside Docker Desktop -------------------
# Every kubectl/helm call below pins --kube-context, so whatever cluster your
# current context points at is never touched.
$clusters = (& k3d cluster list --no-headers 2>$null) -join "`n"
if ($clusters -notmatch "(?m)^$Cluster\s") {
    Say "creating k3d cluster `"$Cluster`" (inside Docker Desktop)"
    & k3d cluster create $Cluster --wait
    Assert-Ok 'k3d cluster creation'
} else {
    Say "k3d cluster `"$Cluster`" already exists - using it"
    & k3d cluster start $Cluster --wait *> $null
}
& kubectl --context $Context get nodes *> $null
Assert-Ok "reaching the cluster (context $Context)"

# --- Configuration ----------------------------------------------------------------
$pgpw = Get-ExistingSecretValue 'postgres-secret' 'password'
if (-not $pgpw) { $pgpw = New-HexSecret 24 }

$helmArgs = @(
    '--set-string', "postgres.password=$pgpw",
    '--set', 'postgres.persistence=true',
    # No ingress controller for it in this cluster; the UI is reached via port-forward.
    '--set', 'ingress.enabled=false'
)

if ($WithObjectStorage) {
    # Garage only accepts an access key id shaped like its own: GK plus 24 hex characters.
    $s3Access  = Get-ExistingSecretValue 'agenthub-secrets' 'S3__AccessKey'
    $s3Secret  = Get-ExistingSecretValue 'agenthub-secrets' 'S3__SecretKey'
    $rpcSecret = Get-ExistingSecretValue 'garage-secrets' 'rpc_secret'
    $adminTok  = Get-ExistingSecretValue 'garage-secrets' 'admin_token'
    if (-not $s3Access)  { $s3Access  = "GK$(New-HexSecret 12)" }
    if (-not $s3Secret)  { $s3Secret  = New-HexSecret 32 }
    if (-not $rpcSecret) { $rpcSecret = New-HexSecret 32 }
    if (-not $adminTok)  { $adminTok  = New-HexSecret 16 }
    $helmArgs += @(
        '--set', 'objectStorage.enabled=true',
        '--set-string', "objectStorage.accessKey=$s3Access",
        '--set-string', "objectStorage.secretKey=$s3Secret",
        '--set-string', "objectStorage.rpcSecret=$rpcSecret",
        '--set-string', "objectStorage.adminToken=$adminTok"
    )
} else {
    Say 'WARNING: object storage disabled - sessions cannot be resumed and finished sessions keep no history.'
}

# --- Deploy Open AgentHub --------------------------------------------------------
if ($Chart -eq 'agenthub/open-agenthub') {
    Say 'adding Helm repository'
    # --force-update re-downloads the index, so an unreachable repository fails here
    # instead of silently installing a stale chart from the local cache.
    & helm repo add agenthub $HelmRepo --force-update | Out-Null
    Assert-Ok "fetching the Helm repository $HelmRepo"
}

Say "deploying Open AgentHub ($Chart)"
& helm --kube-context $Context upgrade --install agenthub $Chart `
    -n $Namespace --create-namespace @helmArgs --wait --timeout 10m
Assert-Ok 'helm install'

# Garage creates nothing by itself: a fresh node has no layout, no bucket and no
# key. Each step is skipped when it is already done, so a re-run costs nothing.
if ($WithObjectStorage) {
    & kubectl --context $Context -n $Namespace rollout status statefulset/garage --timeout=180s
    Assert-Ok 'object storage rollout'
    function Invoke-Garage { & kubectl --context $Context -n $Namespace exec garage-0 -- /garage @args }

    $buckets = (Invoke-Garage bucket list 2>$null) -join "`n"
    if ($buckets -notmatch '\sagenthub\s') {
        Say 'initialising object storage'
        $layout = (Invoke-Garage layout show 2>$null) -join "`n"
        $version = 0
        if ($layout -match 'Current cluster layout version: (\d+)') { $version = [int]$Matches[1] }
        if ($version -lt 1) {
            $nodeId = ((Invoke-Garage node id -q 2>$null) -join '').Trim().Split('@')[0]
            if (-not $nodeId) { Fail 'could not read the Garage node id' }
            Invoke-Garage layout assign -z dc1 -c 18GB $nodeId | Out-Null; Assert-Ok 'Garage layout assign'
            Invoke-Garage layout apply --version ($version + 1) | Out-Null; Assert-Ok 'Garage layout apply'
        }
        Invoke-Garage bucket create agenthub | Out-Null; Assert-Ok 'Garage bucket create'
        Invoke-Garage key import --yes $s3Access $s3Secret -n agenthub-key | Out-Null; Assert-Ok 'Garage key import'
        Invoke-Garage bucket allow --read --write --owner agenthub --key agenthub-key | Out-Null; Assert-Ok 'Garage bucket allow'
        # The backend checked the bucket at startup; restart it so it picks the storage up.
        & kubectl --context $Context -n $Namespace rollout restart deployment/agenthub-backend | Out-Null
        & kubectl --context $Context -n $Namespace rollout status deployment/agenthub-backend --timeout=180s
        Assert-Ok 'backend restart'
    }
    Say 'object storage ready'
}

Say ''
Say 'done! Open AgentHub is running.'
Say ''
Say 'next steps:'
Say '  1. Reach the UI (no ingress configured):'
Say "       kubectl --context $Context -n $Namespace port-forward svc/agenthub-frontend 8080:80"
Say '     then open http://localhost:8080'
Say '     For production, set ingress.host + TLS: https://github.com/open-agenthub/open-agenthub'
Say '  2. Auth is DISABLED by default (dev mode). Enable your OIDC provider:'
Say "       helm --kube-context $Context upgrade agenthub $Chart -n $Namespace --reuse-values --set oidc.authority=https://<provider>/realms/<realm>"
Say '  3. In the UI: store your credentials, start your first session.'
Say ''
Say "note: tools live in $Bin (only on PATH in this session)"
}
