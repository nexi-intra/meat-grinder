$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$VerbosePreference = "SilentlyContinue"
$DebugPreference = "SilentlyContinue"

write-host "Checking environment"

. "$psscriptroot/10-environments/graph-postgres/check.ps1"

write-host "Connecting to Magic Mix"

. "$psscriptroot/00-connectors/magic-mix/connect.ps1"

write-host "Connecting to Office Graph"

. "$psscriptroot/00-connectors/graph/connect.ps1"

write-host "Running integration"
. "$psscriptroot/office_graph/excel-postgres-blob/excel-postgres-blob.ps1"