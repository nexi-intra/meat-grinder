if ($null -eq $env:WORKDIR ) {
  $env:WORKDIR = join-path $psscriptroot ".." ".koksmat" "workdir"
}
$workdir = $env:WORKDIR

if (-not (Test-Path $workdir)) {
  New-Item -Path $workdir -ItemType Directory | Out-Null
}

$workdir = Resolve-Path $workdir

write-host "Workdir: $workdir"
Push-Location
set-location $workdir
try {
  git clone --depth=1 https://github.com/magicbutton/magic-mix  
  
  set-location (Join-Path $workdir magic-mix ".koksmat" "app")
  go install
  magic-mix sql query mix "select 1"
}
catch {
  write-host "Failed to clone magic-mix"
}
Pop-Location



