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
  $magicmixpath = join-path $workdir "magic-mix"
  if (!(Test-Path $magicmixpath) ) {
    git clone --depth=1 https://github.com/magicbutton/magic-mix  
  
    set-location (Join-Path $workdir magic-mix ".koksmat" "app")
    go install  
  }
  $result = magic-mix sql query mix "select 1 as one"
  if ($result -ne '[{"one":1}]') {
    throw "Failed to connect to magic-mix"
  }
  write-host "Magic Mix connection successful"
}
catch {
  write-host "Failed to clone magic-mix"
  throw $_
}
Pop-Location



