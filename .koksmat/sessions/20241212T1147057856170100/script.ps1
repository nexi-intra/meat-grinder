$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$VerbosePreference = "SilentlyContinue"
$DebugPreference = "SilentlyContinue"

$root = join-path $PSScriptRoot ..
# make the root normalized
$root = [System.IO.Path]::GetFullPath($root) 

write-host "Checking environment"

. "$root/10-environments/graph-postgres/check.ps1"

write-host "Connecting to Magic Mix"

. "$root/00-connectors/magic-mix/connect.ps1"

write-host "Connecting to Office Graph"

. "$root/00-connectors/graph/connect.ps1"

write-host "Running integration"
. "$root/office_graph/excel-postgres-blob/excel-postgres-blob.ps1"