Push-Location
try {
  Set-Location $PSScriptRoot
  . "$PSScriptRoot/../../env.ps1"
  . "$PSScriptRoot/temp"
  . "$PSScriptRoot/run.ps1"
}
catch {
  write-host "Error: $_" -ForegroundColor:Red
  <#Do this if a terminating exception happens#>
}
finally {
  Pop-Location
}