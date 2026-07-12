# Open AgentHub — all-in-one quickstart for Windows
#
#   iwr -useb https://open-agenthub.github.io/install.ps1 | iex
#
# Uses Docker Desktop and creates a single-node k3d cluster, then deploys
# Open AgentHub from the official Helm repository. No winget/choco needed —
# k3d, kubectl and helm are downloaded to a local tools directory if missing.
# Recommended: 4 vCPU / 6 GB RAM for the Docker VM (good for up to ~6 users).

$ErrorActionPreference = 'Stop'

$HelmRepo  = 'https://open-agenthub.github.io/open-agenthub'
$Namespace = 'agenthub'
$Bin       = Join-Path $env:LOCALAPPDATA 'open-agenthub\bin'

function Say($msg)  { Write-Host "[open-agenthub] $msg" -ForegroundColor Yellow }
function Fail($msg) { Write-Host "[open-agenthub] ERROR: $msg" -ForegroundColor Red; exit 1 }

# --- Docker Desktop -------------------------------------------------------------
try { docker info *> $null } catch { $LASTEXITCODE = 1 }
if ($LASTEXITCODE -ne 0) {
    Fail 'Docker is not running - install/start Docker Desktop first: https://www.docker.com/products/docker-desktop/'
}

# --- Local tools dir ------------------------------------------------------------
New-Item -ItemType Directory -Force $Bin | Out-Null
if ($env:Path -notlike "*$Bin*") { $env:Path = "$Bin;$env:Path" }

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Say 'downloading kubectl'
    $kver = (Invoke-WebRequest -UseBasicParsing 'https://dl.k8s.io/release/stable.txt').Content.Trim()
    Invoke-WebRequest -UseBasicParsing "https://dl.k8s.io/release/$kver/bin/windows/amd64/kubectl.exe" -OutFile (Join-Path $Bin 'kubectl.exe')
}

if (-not (Get-Command k3d -ErrorAction SilentlyContinue)) {
    Say 'downloading k3d'
    Invoke-WebRequest -UseBasicParsing 'https://github.com/k3d-io/k3d/releases/latest/download/k3d-windows-amd64.exe' -OutFile (Join-Path $Bin 'k3d.exe')
}

if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
    Say 'downloading helm'
    $hver = (Invoke-WebRequest -UseBasicParsing 'https://get.helm.sh/helm-latest-version').Content.Trim()
    $zip = Join-Path $env:TEMP 'helm.zip'
    Invoke-WebRequest -UseBasicParsing "https://get.helm.sh/helm-$hver-windows-amd64.zip" -OutFile $zip
    Expand-Archive -Force $zip (Join-Path $env:TEMP 'helm-extract')
    Copy-Item (Join-Path $env:TEMP 'helm-extract\windows-amd64\helm.exe') (Join-Path $Bin 'helm.exe') -Force
    Remove-Item -Recurse -Force $zip, (Join-Path $env:TEMP 'helm-extract') -ErrorAction SilentlyContinue
}

# --- Kubernetes: single-node k3d cluster inside Docker Desktop -------------------
$clusters = (& k3d cluster list --no-headers 2>$null) -join "`n"
if ($clusters -notmatch '(?m)^agenthub\s') {
    Say 'creating k3d cluster "agenthub" (inside Docker Desktop)'
    & k3d cluster create agenthub --wait
    if ($LASTEXITCODE -ne 0) { Fail 'k3d cluster creation failed' }
} else {
    Say 'k3d cluster "agenthub" already exists - using it'
}

# --- Deploy Open AgentHub --------------------------------------------------------
Say 'adding Helm repository'
& helm repo add agenthub $HelmRepo | Out-Null
& helm repo update agenthub | Out-Null

# Generated once; kept in the cluster secret afterwards.
$bytes = New-Object byte[] 24
[System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
$pgpw = ($bytes | ForEach-Object { $_.ToString('x2') }) -join ''

Say 'deploying Open AgentHub'
& helm upgrade --install agenthub agenthub/open-agenthub `
    -n $Namespace --create-namespace `
    --set postgres.password=$pgpw `
    --set postgres.persistence=true `
    --wait --timeout 10m
if ($LASTEXITCODE -ne 0) { Fail 'helm install failed' }

Say ''
Say 'done! Open AgentHub is running.'
Say ''
Say 'next steps:'
Say '  1. Reach the UI (no ingress configured yet):'
Say "       kubectl -n $Namespace port-forward svc/agenthub-frontend 8080:80"
Say "       kubectl -n $Namespace port-forward svc/agenthub-backend 8081:80   # second terminal"
Say '     then open http://localhost:8080'
Say '     For production, set ingress.host + TLS: https://github.com/open-agenthub/open-agenthub'
Say '  2. Auth is DISABLED by default (dev mode). Enable your OIDC provider:'
Say "       helm upgrade agenthub agenthub/open-agenthub -n $Namespace --reuse-values --set oidc.authority=https://<provider>/realms/<realm>"
Say '  3. In the UI: store your credentials, start your first session.'
Say ''
Say "note: k3d/kubectl/helm were installed to $Bin (only on PATH in this session)"
