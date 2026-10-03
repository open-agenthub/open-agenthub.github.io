# Runs install.ps1 against mocked docker/k3d/kubectl/helm and checks what it would do.
#
#   powershell -File install-ps1-mock.ps1 <path-to-install.ps1>   # Windows PowerShell 5.1
#   pwsh       -File install-ps1-mock.ps1 <path-to-install.ps1>   # PowerShell 7
#
# Hosted Windows runners have no Linux containers, so a real deployment is impossible
# there. Mocks still execute every line of the script under the real PowerShell
# edition — which is what broke before (.NET-Core-only APIs, stderr turning into
# terminating errors under 5.1) — and pin down the calls it makes.
param([Parameter(Mandatory)] [string]$Script)

$ErrorActionPreference = 'Stop'
$source = Get-Content -Raw $Script
$failures = New-Object System.Collections.Generic.List[string]
function Check($ok, $what) {
    if ($ok) { Write-Host "  ok   $what" } else { Write-Host "  FAIL $what" -ForegroundColor Red; $failures.Add($what) }
}

# --- mocks -------------------------------------------------------------------------
# Functions win over executables for `& name`, and Get-Command finds them, so the
# script neither downloads tools nor touches a real cluster.
function global:docker { $global:LASTEXITCODE = 0 }
function global:k3d    { $global:Calls.Add("k3d $args"); $global:LASTEXITCODE = 0 }
function global:helm {
    $global:Calls.Add("helm $args")
    $global:LASTEXITCODE = 0
    if ($args[0] -eq 'repo' -and $global:Mock.RepoFails) { $global:LASTEXITCODE = 1 }
}
function global:kubectl {
    $line = "$args"
    $global:Calls.Add("kubectl $line")
    $global:LASTEXITCODE = 0
    if ($line -match 'get secret (\S+) -o jsonpath=\{\.data\.(\S+)\}') {
        $value = $global:Mock.Secrets["$($Matches[1])/$($Matches[2])"]
        if ($value) { [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($value)) }
        else { [Console]::Error.WriteLine("Error from server (NotFound)"); $global:LASTEXITCODE = 1 }
        return
    }
    if ($line -match '/garage bucket list') { $global:Mock.BucketList; return }
    if ($line -match '/garage layout show') { 'Current cluster layout version: 0'; return }
    if ($line -match '/garage node id') { 'aaaabbbbcccc@10.0.0.1:3901'; return }
}

function Invoke-Install($mock) {
    $global:Mock = $mock
    $global:Calls = New-Object System.Collections.Generic.List[string]
    $env:AGENTHUB_CHART = $null
    $env:AGENTHUB_OBJECT_STORAGE = $mock.ObjectStorage
    $thrown = $null
    try { $source | Invoke-Expression *> $null } catch { $thrown = $_ }
    return $thrown
}
function HelmInstall { $global:Calls | Where-Object { $_ -like 'helm *upgrade --install*' } | Select-Object -First 1 }

Write-Host "PowerShell $($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))"

# --- fresh install -------------------------------------------------------------------
Write-Host 'fresh install'
$err = Invoke-Install @{ Secrets = @{}; BucketList = 'List of buckets:' }
Check ($null -eq $err) "completes without error $(if ($err) { ": $err" })"
$install = HelmInstall
Check ($install -match '--kube-context k3d-agenthub') 'helm pins the k3d context'
Check ($install -match 'postgres\.password=[0-9a-f]{48}(\s|$)') 'generates a 24-byte postgres password'
Check ($install -match 'objectStorage\.enabled=true') 'enables object storage'
Check ($install -match 'objectStorage\.accessKey=GK[0-9a-f]{24}(\s|$)') 'generates a Garage-shaped access key'
Check ($install -match 'ingress\.enabled=false') 'disables the ingress'
Check (@($global:Calls | Where-Object { $_ -like 'helm repo add*--force-update*' }).Count -eq 1) 'refreshes the helm repository index'
Check (@($global:Calls | Where-Object { $_ -like 'kubectl *' -and $_ -notlike 'kubectl --context k3d-agenthub *' }).Count -eq 0) 'every kubectl call pins the context'
Check (@($global:Calls | Where-Object { $_ -match 'layout assign -z dc1 -c 18GB aaaabbbbcccc$' }).Count -eq 1) 'assigns the Garage layout to the node'
Check (@($global:Calls | Where-Object { $_ -match 'layout apply --version 1$' }).Count -eq 1) 'applies layout version 1'
Check (@($global:Calls | Where-Object { $_ -match '/garage bucket create agenthub$' }).Count -eq 1) 'creates the bucket'
$key = if ($install -match 'objectStorage\.accessKey=(GK[0-9a-f]{24})') { $Matches[1] } else { '<none>' }
Check (@($global:Calls | Where-Object { $_ -match "key import --yes $key " }).Count -eq 1) 'imports the same key into Garage'

# --- re-run keeps secrets --------------------------------------------------------------
Write-Host 're-run with existing secrets'
$existing = @{
    'postgres-secret/password'        = 'existing-pg-password'
    'agenthub-secrets/S3__AccessKey'  = 'GK000000000000000000000001'
    'agenthub-secrets/S3__SecretKey'  = 'existing-s3-secret'
    'garage-secrets/rpc_secret'       = 'existing-rpc'
    'garage-secrets/admin_token'      = 'existing-admin'
}
$err = Invoke-Install @{ Secrets = $existing; BucketList = "List of buckets:`n  agenthub    0123abcd" }
Check ($null -eq $err) "completes without error $(if ($err) { ": $err" })"
$install = HelmInstall
Check ($install -match 'postgres\.password=existing-pg-password') 'reuses the postgres password'
Check ($install -match 'objectStorage\.accessKey=GK000000000000000000000001') 'reuses the storage access key'
Check ($install -match 'objectStorage\.rpcSecret=existing-rpc') 'reuses the Garage rpc secret'
Check (@($global:Calls | Where-Object { $_ -match '/garage bucket create' }).Count -eq 0) 'skips the bootstrap when the bucket exists'

# --- object storage opt-out ----------------------------------------------------------
Write-Host 'object storage disabled'
$err = Invoke-Install @{ Secrets = @{}; BucketList = ''; ObjectStorage = '0' }
Check ($null -eq $err) 'completes without error'
Check ((HelmInstall) -notmatch 'objectStorage\.enabled') 'does not enable object storage'
Check (@($global:Calls | Where-Object { $_ -match '/garage ' }).Count -eq 0) 'does not touch Garage'

# --- unreachable helm repository -----------------------------------------------------
Write-Host 'unreachable helm repository'
$err = Invoke-Install @{ Secrets = @{}; BucketList = ''; RepoFails = $true }
Check ($null -ne $err -and "$err" -match 'Helm repository') 'fails with a clear error'
Check ($null -eq (HelmInstall)) 'does not install a cached chart'

$env:AGENTHUB_OBJECT_STORAGE = $null
if ($failures.Count) { Write-Host "$($failures.Count) check(s) failed" -ForegroundColor Red; exit 1 }
Write-Host 'all checks passed'
