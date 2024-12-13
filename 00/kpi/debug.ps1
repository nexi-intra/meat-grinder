Push-Location
try {
  $root = join-path $PSScriptRoot .. ..
  $root = [System.IO.Path]::GetFullPath($root) 
  
  Set-Location $PSScriptRoot
  . "$root/.koksmat/pwsh/build-env.ps1"
  . "$PSScriptRoot/temp.ps1"
  
  . "$PSScriptRoot/run.ps1" -DryRun $false
}
catch {
  write-host "Error: $_" -ForegroundColor:Red
  <#Do this if a terminating exception happens#>
}
finally {
  Pop-Location
}