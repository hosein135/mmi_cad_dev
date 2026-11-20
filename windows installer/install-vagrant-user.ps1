param(
    [string]$Msi = $env:MMI_VAGRANT_MSI,
    [string]$Dest = $env:MMI_VAGRANT_DEST,
    [Parameter(Mandatory = $true)][string]$ExpectedSha256,
    [Parameter(Mandatory = $true)][string]$ExpectedVersion
)

# Hashicorp ships Vagrant for Windows as a per-machine MSI. msiexec /a
# unpacks that MSI for the current user, without administrator rights.
$ErrorActionPreference = "Stop"

function Write-Fail([string]$Message) {
    Write-Host $Message
    exit 1
}

if (-not $Msi -or -not (Test-Path -LiteralPath $Msi)) {
    Write-Fail "Vagrant MSI not found: $Msi"
}
if (-not $Dest) {
    Write-Fail "Vagrant destination was not provided."
}

$hash = (Get-FileHash -LiteralPath $Msi -Algorithm SHA256).Hash
if ($hash -ne $ExpectedSha256.ToUpperInvariant()) {
    Write-Fail "Vagrant MSI checksum does not match $ExpectedVersion ($hash)."
}

$staging = Join-Path $env:TEMP ("mmi-vagrant-extract-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $staging | Out-Null
try {
    $msiArgs = "/a `"$Msi`" /qn TARGETDIR=`"$staging`""
    Write-Host "Extracting Vagrant $ExpectedVersion"
    $proc = Start-Process -FilePath "$env:SystemRoot\System32\msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru
    if ($proc.ExitCode -ne 0) {
        Write-Fail "msiexec /a failed with exit $($proc.ExitCode)."
    }
    $knownExe = Join-Path $staging "Vagrant\bin\vagrant.exe"
    if (Test-Path -LiteralPath $knownExe) {
        $exe = Get-Item -LiteralPath $knownExe
    } else {
        $exe = Get-ChildItem -LiteralPath $staging -Recurse -Filter "vagrant.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    }
    if (-not $exe -or -not $exe.Directory -or -not $exe.Directory.Parent) {
        Write-Fail "vagrant.exe was not found in the extracted MSI."
    }
    $root = $exe.Directory.Parent.FullName
    $destParent = Split-Path -Parent $Dest
    if (-not (Test-Path -LiteralPath $destParent)) {
        New-Item -ItemType Directory -Path $destParent -Force | Out-Null
    }
    if (Test-Path -LiteralPath $Dest) {
        & cmd.exe /c "rd /s /q `"$Dest`""
    }
    Move-Item -LiteralPath $root -Destination $Dest
    $installed = Join-Path $Dest "bin\vagrant.exe"
    if (-not (Test-Path -LiteralPath $installed)) {
        Write-Fail "vagrant.exe was not placed in $installed."
    }
    $env:VAGRANT_CHECKPOINT_DISABLE = "1"
    $versionText = & $installed --version 2>&1 | Out-String
    if ($versionText -notmatch [regex]::Escape($ExpectedVersion)) {
        Write-Fail "Expected Vagrant $ExpectedVersion and found: $($versionText.Trim())"
    }
    Write-Host "$($versionText.Trim()) ready at $installed"
} catch {
    Write-Host $_.Exception.Message
    exit 1
} finally {
    if (Test-Path -LiteralPath $staging) {
        & cmd.exe /c "rd /s /q `"$staging`""
    }
}
exit 0
