param ($dryrun = $false)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$VerbosePreference = "SilentlyContinue"
$DebugPreference = "SilentlyContinue"

$workdir = join-path $psscriptroot ".." ".." ".koksmat" "workdir"

if (-not (Test-Path $workdir)) {
  New-Item -Path $workdir -ItemType Directory | Out-Null
}

$workdir = Resolve-Path $workdir
$env:WORKDIR = $workdir
write-host "Workdir: $workdir"

$root = join-path $PSScriptRoot .. ..

$root = [System.IO.Path]::GetFullPath($root) 
$koksmatPwsh = join-path $root ".koksmat" "pwsh"
write-host "Root: $root"

write-host "Checking environment"

. "$koksmatPwsh/check-env.ps1" 'DEVICEKPIBLOB', 'GRAPH_APPID', 'GRAPH_APPSECRET', 'GRAPH_APPDOMAIN', 'POSTGRES_DB', 'MAILTO', 'MAILFROM'

write-host "Connecting to Magic Mix"

. "$koksmatPwsh/connectors/magic-mix/connect.ps1"

write-host "Connecting to Office Graph"

. "$koksmatPwsh/connectors/graph/connect.ps1"

write-host "Running integration"
. "$root/excel-postgres-blob/run.ps1" -DryRun $dryrun