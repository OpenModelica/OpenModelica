# Sign files with the eToken of the release build machine, as OpenModelicaSetup's
# BuildWindowsRelease.sh signs the release installer, and verify the signatures.
#
#   windows-sign.ps1 <file or directory>...
#
# A directory stands for each .exe and .dll below it.
#
# TOKEN_PW, the eToken password (a Jenkins credential), unlocks the token without
# a SafeNet login. TOKEN_CERT, TOKEN_CONTAINER and TOKEN_CSP default to the values
# of the release build machine.
param([Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)][string[]] $Paths)
$ErrorActionPreference = 'Stop'

$cert = if ($env:TOKEN_CERT) { $env:TOKEN_CERT } else { 'C:\dev\sign\osmc.cer' }
$container = if ($env:TOKEN_CONTAINER) { $env:TOKEN_CONTAINER } else { 'p11#1c15877afe5ca77f' }
$csp = if ($env:TOKEN_CSP) { $env:TOKEN_CSP } else { 'eToken Base Cryptographic Provider' }
if (-not $env:TOKEN_PW) {
  throw 'TOKEN_PW is not set'
}
$signtool = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64\signtool.exe" |
  Sort-Object FullName | Select-Object -Last 1
if (-not $signtool) {
  throw 'signtool.exe not found in the Windows 10 SDK'
}

$files = foreach ($path in $Paths) {
  if (Test-Path -LiteralPath $path -PathType Container) {
    Get-ChildItem -LiteralPath $path -Recurse -File -Include *.exe, *.dll | ForEach-Object FullName
  } else {
    (Resolve-Path -LiteralPath $path).Path
  }
}
if (-not $files) {
  throw "no files to sign in $Paths"
}
Write-Output "signing $(@($files).Count) files"

# One call for all files, so the token is unlocked once.
& $signtool.FullName sign /f $cert /csp $csp /kc "[{{$($env:TOKEN_PW)}}]=$container" `
  /tr http://timestamp.globalsign.com/tsa/r6advanced1 /fd SHA256 /td SHA256 $files
if ($LASTEXITCODE -ne 0) {
  throw 'signing failed'
}
& $signtool.FullName verify /pa $files
if ($LASTEXITCODE -ne 0) {
  throw 'a signature does not verify'
}
