$ErrorActionPreference = 'Stop'

# Windows bootstrap for Micro Magic CAD:
#   hardware checks -> WinGet -> vfox -> pinned Vagrant -> VirtualBox
#   -> Ubuntu VM -> ./run.sh inside the VM.
# A later run sees Vagrant, VirtualBox, and the existing VM, skips install,
# and starts ./run.sh so the CAD applications can be opened again.
# Command lookup follows ../document/run.ps1: find winget/vfox when they are
# missing from PATH, and fall back to the user PATH if Machine PATH is locked.
# run.cmd calls powershell.exe by full path and requests administrator rights
# (VirtualBox and the Vagrant MSI need them). Extra arguments are passed to
# ./run.sh, for example:  run.cmd max

Set-Location -LiteralPath $PSScriptRoot
Write-Host "Working directory set to: $PSScriptRoot" -ForegroundColor Cyan

$script:ElevatedHere = $false
$script:VagrantExe = $null
$script:BrowserJob = $null
$RunArgs = @()
foreach ($a in $args) {
    if ($a -eq '-ElevatedChild') { $script:ElevatedHere = $true }
    else { $RunArgs += $a }
}

$vfoxVersion = "0.6.2"
$vfoxPackageId = "version-fox.vfox"
$vagrantVersion = "2.4.9"
$vagrantPluginZip = "https://github.com/johnxu16/vfox-vagrant/archive/1d8a1c7198f26439a796ac4e7169047a2dcd6c48.zip"
$virtualBoxVersion = "7.1.18"
$virtualBoxPackageId = "Oracle.VirtualBox"
$boxVersion = "202510.26.0"
$minFreeBytes = 24GB
$script:VmMemory = "6144"
$script:VmCpus = "2"
$script:SetupAlreadyComplete = $false
$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path

function Write-Section([string]$Title) {
    Write-Host ""
    Write-Host ("=" * 64) -ForegroundColor DarkCyan
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host ("=" * 64) -ForegroundColor DarkCyan
}

function Fail([string]$Message) {
    Write-Host ""
    Write-Host $Message -ForegroundColor Red
    if ($script:ElevatedHere) {
        Write-Host ""
        Write-Host "Press Enter to close this window."
        try { [void](Read-Host) } catch {}
    }
    exit 1
}

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($id)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Refresh-SessionPath {
    param([string]$WingetPackagesRoot)

    $machine = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $user = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machine;$user"

    foreach ($dir in @(
        "$env:LOCALAPPDATA\Microsoft\WindowsApps",
        "$env:LOCALAPPDATA\Microsoft\WinGet\Links",
        "$env:ProgramFiles\Oracle\VirtualBox"
    )) {
        if ((Test-Path -LiteralPath $dir) -and ($env:Path -notlike "*$dir*")) {
            $env:Path = "$dir;$env:Path"
        }
    }

    $appInstaller = Get-ChildItem "$env:ProgramFiles\WindowsApps" -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "Microsoft.DesktopAppInstaller_*" } |
        Sort-Object Name -Descending |
        Select-Object -First 1
    if ($appInstaller -and (Test-Path (Join-Path $appInstaller.FullName "winget.exe")) -and ($env:Path -notlike "*$($appInstaller.FullName)*")) {
        $env:Path = "$($appInstaller.FullName);$env:Path"
    }

    if ($WingetPackagesRoot -and (Test-Path -LiteralPath $WingetPackagesRoot)) {
        foreach ($exeName in @("vfox.exe", "vagrant.exe", "winget.exe")) {
            $exe = Get-ChildItem -Path $WingetPackagesRoot -Recurse -Filter $exeName -ErrorAction SilentlyContinue |
                Select-Object -First 1
            if ($exe -and ($env:Path -notlike "*$($exe.DirectoryName)*")) {
                $env:Path = "$($exe.DirectoryName);$env:Path"
            }
        }
    }

    foreach ($vfoxHome in @("$HOME\.vfox", "$HOME\.version-fox")) {
        if ((Test-Path -LiteralPath $vfoxHome) -and ($env:Path -notlike "*$vfoxHome*")) {
            $env:Path = "$vfoxHome;$env:Path"
        }
        $sdkRoot = Join-Path $vfoxHome "sdks"
        if (Test-Path -LiteralPath $sdkRoot) {
            $exe = Get-ChildItem -Path $sdkRoot -Recurse -Filter "vagrant.exe" -ErrorAction SilentlyContinue |
                Select-Object -First 1
            if ($exe -and ($env:Path -notlike "*$($exe.DirectoryName)*")) {
                $env:Path = "$($exe.DirectoryName);$env:Path"
            }
        }
    }
}

function Add-DirToMachinePath {
    param([Parameter(Mandatory = $true)][string]$BinDir)

    if (-not $BinDir -or -not (Test-Path -LiteralPath $BinDir)) { return $false }
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($machinePath -like "*$BinDir*") {
        if ($env:Path -notlike "*$BinDir*") { $env:Path = "$BinDir;$env:Path" }
        return $true
    }
    try {
        [System.Environment]::SetEnvironmentVariable("Path", "$BinDir;$machinePath", "Machine")
        Write-Host "  Added $BinDir to system PATH (permanent)" -ForegroundColor Green
    } catch {
        $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
        if ($userPath -notlike "*$BinDir*") {
            $joined = if ($userPath) { "$BinDir;$userPath" } else { $BinDir }
            [System.Environment]::SetEnvironmentVariable("Path", $joined, "User")
        }
        Write-Host "  Added $BinDir to your user PATH." -ForegroundColor Yellow
    }
    if ($env:Path -notlike "*$BinDir*") { $env:Path = "$BinDir;$env:Path" }
    return $true
}

function Test-UsableExe {
    param([string]$Path)
    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) { return $false }
    try {
        return ((Get-Item -LiteralPath $Path).Length -gt 0)
    } catch {
        return $false
    }
}

function Find-WingetExe {
    $cmd = Get-Command winget -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source -and (Test-Path -LiteralPath $cmd.Source)) {
        return $cmd.Source
    }

    foreach ($p in @(
        "$env:LOCALAPPDATA\Microsoft\WinGet\Links\winget.exe",
        "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
    )) {
        if (Test-UsableExe $p) { return $p }
    }

    $pkg = Get-AppxPackage -Name Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1
    if (-not $pkg) {
        $pkg = Get-AppxPackage -AllUsers -Name Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue |
            Sort-Object Version -Descending |
            Select-Object -First 1
    }
    if ($pkg -and $pkg.InstallLocation) {
        $pkgExe = Join-Path $pkg.InstallLocation "winget.exe"
        if (Test-UsableExe $pkgExe) { return $pkgExe }
    }

    $appsRoot = Join-Path $env:ProgramFiles "WindowsApps"
    if (Test-Path -LiteralPath $appsRoot) {
        $exe = Get-ChildItem -LiteralPath $appsRoot -Filter "winget.exe" -Recurse -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        if ($exe -and (Test-UsableExe $exe.FullName)) { return $exe.FullName }
    }
    return $null
}

function Add-WingetToPath {
    param([string]$WingetExe)
    if (-not $WingetExe) { return $false }
    $ok = Add-DirToMachinePath -BinDir (Split-Path -Parent $WingetExe)
    foreach ($dir in @(
        "$env:LOCALAPPDATA\Microsoft\WindowsApps",
        "$env:LOCALAPPDATA\Microsoft\WinGet\Links"
    )) {
        if (Test-Path -LiteralPath $dir) { Add-DirToMachinePath -BinDir $dir | Out-Null }
    }
    return $ok
}

function Download-File {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$Destination,
        [string]$Label = "Downloading"
    )
    Write-Host "  $Label" -ForegroundColor Cyan
    Write-Host "  URL: $Url" -ForegroundColor DarkGray
    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if ($curl) {
        $prevEAP = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        & curl.exe -L -# -o "$Destination" "$Url"
        $curlExit = $LASTEXITCODE
        $ErrorActionPreference = $prevEAP
        if ($curlExit -eq 0 -and (Test-Path -LiteralPath $Destination)) {
            $sizeMB = [math]::Round((Get-Item -LiteralPath $Destination).Length / 1MB, 1)
            Write-Host "  Done ($sizeMB MB)" -ForegroundColor Green
            return $true
        }
    }
    $prevProgress = $ProgressPreference
    $ProgressPreference = 'Continue'
    try {
        Invoke-WebRequest -Uri $Url -OutFile $Destination
        $sizeMB = [math]::Round((Get-Item -LiteralPath $Destination).Length / 1MB, 1)
        Write-Host "  Done ($sizeMB MB)" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  Download failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    } finally {
        $ProgressPreference = $prevProgress
    }
}

function Ensure-Winget {
    Refresh-SessionPath

    $exe = Find-WingetExe
    if ($exe) {
        Write-Host "WinGet is already installed; skipping download." -ForegroundColor Green
        Write-Host "  $exe" -ForegroundColor DarkGray
        Add-WingetToPath -WingetExe $exe | Out-Null
        Refresh-SessionPath
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            Fail "WinGet is installed but not on PATH after update. Open a new PowerShell and re-run."
        }
        return
    }

    $pkg = Get-AppxPackage -Name Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($pkg -and $pkg.InstallLocation -and (Test-Path (Join-Path $pkg.InstallLocation "winget.exe"))) {
        $pkgExe = Join-Path $pkg.InstallLocation "winget.exe"
        Write-Host "App Installer is already installed; skipping download and adding winget to PATH." -ForegroundColor Green
        Add-WingetToPath -WingetExe $pkgExe | Out-Null
        Refresh-SessionPath
        return
    }

    Write-Host "WinGet not found. Installing WinGet (App Installer)..." -ForegroundColor Yellow
    $installerPath = Join-Path $env:TEMP "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    $haveBundle = (Test-Path -LiteralPath $installerPath) -and ((Get-Item -LiteralPath $installerPath).Length -gt 1MB)
    if ($haveBundle) {
        Write-Host "  Using already-downloaded installer (skip redownload)." -ForegroundColor Green
    } else {
        $downloaded = Download-File -Url "https://aka.ms/getwinget" -Destination $installerPath -Label "Downloading WinGet (App Installer)"
        if (-not $downloaded) { Fail "Failed to download WinGet." }
    }
    Add-AppxPackage -Path $installerPath
    Write-Host "WinGet installed successfully." -ForegroundColor Green

    Start-Sleep -Seconds 2
    Refresh-SessionPath
    $exe = Find-WingetExe
    if (-not $exe) {
        Fail "WinGet installed but winget.exe was not found. Open a new PowerShell and re-run."
    }
    Add-WingetToPath -WingetExe $exe | Out-Null
    Refresh-SessionPath
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Fail "WinGet installed but is not on PATH. Open a new PowerShell and re-run."
    }
}

function Invoke-Vfox {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$VfoxArgs)
    $prevEAP = $ErrorActionPreference
    $prevNative = $null
    if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
        $prevNative = $PSNativeCommandUseErrorActionPreference
        $PSNativeCommandUseErrorActionPreference = $false
    }
    $ErrorActionPreference = 'Continue'
    $exe = (Get-Command vfox -ErrorAction SilentlyContinue).Source
    if (-not $exe) { $exe = 'vfox' }
    & $exe @VfoxArgs
    $code = $LASTEXITCODE
    $ErrorActionPreference = $prevEAP
    if ($null -ne $prevNative) { $PSNativeCommandUseErrorActionPreference = $prevNative }
    if ($null -eq $code) { $code = 0 }
    return $code
}

function Install-VfoxSdk {
    param(
        [Parameter(Mandatory = $true)][string]$Plugin,
        [Parameter(Mandatory = $true)][string]$Version
    )
    Write-Host "  Downloading and installing $Plugin@$Version via vfox..." -ForegroundColor Cyan
    Write-Host "  (vfox shows its own progress bar)" -ForegroundColor DarkGray
    $exitCode = Invoke-Vfox install "${Plugin}@${Version}"
    if ($exitCode -ne 0) {
        $listOut = & {
            $prev = $ErrorActionPreference
            $ErrorActionPreference = 'Continue'
            & vfox list $Plugin 2>&1 | Out-String
            $ErrorActionPreference = $prev
        }
        if ($listOut -match [regex]::Escape($Version)) {
            Write-Host "  $Plugin@$Version is already installed." -ForegroundColor Green
            return $true
        }
        Write-Host "  vfox install $Plugin@$Version failed (exit $exitCode)." -ForegroundColor Yellow
        return $false
    }
    Write-Host "  $Plugin@$Version installed." -ForegroundColor Green
    return $true
}

function Enable-VfoxSession {
    if (-not (Get-Command vfox -ErrorAction SilentlyContinue)) { return }
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $hook = & vfox activate pwsh 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0 -and $hook) {
            Invoke-Expression $hook
        }
    } catch {
        Write-Host "  vfox activate pwsh skipped: $($_.Exception.Message)" -ForegroundColor Yellow
    } finally {
        $ErrorActionPreference = $prev
    }
}

function Find-VagrantExe {
    $cmd = Get-Command vagrant -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source -and (Test-UsableExe $cmd.Source)) {
        $ver = & $cmd.Source --version 2>&1 | Out-String
        if ($ver -match [regex]::Escape($vagrantVersion)) { return $cmd.Source }
    }
    foreach ($root in @("$HOME\.version-fox", "$HOME\.vfox")) {
        if (-not (Test-Path -LiteralPath $root)) { continue }
        $exe = Get-ChildItem -Path $root -Recurse -Filter "vagrant.exe" -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match [regex]::Escape($vagrantVersion) } |
            Select-Object -First 1
        if ($exe) { return $exe.FullName }
        $any = Get-ChildItem -Path $root -Recurse -Filter "vagrant.exe" -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($any) { return $any.FullName }
    }
    return $null
}

function Install-VagrantMsiFallback {
    $msi = $null
    foreach ($root in @("$HOME\.version-fox", "$HOME\.vfox")) {
        if (-not (Test-Path -LiteralPath $root)) { continue }
        $msi = Get-ChildItem -Path $root -Recurse -Filter "vagrant_${vagrantVersion}_windows_amd64.msi" -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($msi) { break }
    }
    if (-not $msi) { return $false }
    $dest = Join-Path $msi.DirectoryName "release"
    $log = Join-Path $msi.DirectoryName "install.log"
    if (Test-Path -LiteralPath (Join-Path $dest "bin\vagrant.exe")) {
        Write-Host "  Vagrant MSI is already installed in $($msi.DirectoryName)" -ForegroundColor Green
        return $true
    }
    Write-Host "  vfox left the Vagrant MSI on disk. Installing it with msiexec..." -ForegroundColor Yellow
    $msiArgs = "/i `"$($msi.FullName)`" /qn /norestart /L*V `"$log`" LicenseAccepted=1 CostingComplete=1 INSTALLDIR=`"$dest`""
    $proc = Start-Process -FilePath "$env:SystemRoot\System32\msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru
    if ($proc.ExitCode -ne 0 -and $proc.ExitCode -ne 3010) {
        Write-Host "  msiexec exit $($proc.ExitCode). See $log" -ForegroundColor Yellow
        return $false
    }
    return (Test-Path -LiteralPath (Join-Path $dest "bin\vagrant.exe"))
}

function Ensure-SudoForVfoxPlugin {
    if (Get-Command sudo -ErrorAction SilentlyContinue) {
        Write-Host "sudo is available. The vfox Vagrant plugin will use it." -ForegroundColor Green
        return
    }
    # The plugin runs "sudo msiexec" and does not quote paths. This process is
    # already elevated, so sudo only needs to forward the command.
    $shim = Join-Path $env:TEMP "mmi-cad-sudo"
    New-Item -ItemType Directory -Force -Path $shim | Out-Null
    $cmdPath = Join-Path $shim "sudo.cmd"
    @(
        '@echo off',
        'REM Forward sudo to the elevated installer. vfox-vagrant prefixes msiexec with sudo.',
        '%*',
        'exit /b %ERRORLEVEL%'
    ) | Set-Content -LiteralPath $cmdPath -Encoding ASCII
    $env:Path = "$shim;$env:Path"
    Write-Host "Sudo for Windows is not installed. Using an elevated sudo shim for the Vagrant MSI." -ForegroundColor Yellow
}

function Find-VBoxManage {
    $cmd = Get-Command VBoxManage -ErrorAction SilentlyContinue
    if ($cmd -and (Test-UsableExe $cmd.Source)) { return $cmd.Source }
    foreach ($p in @(
        "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe",
        "${env:ProgramFiles(x86)}\Oracle\VirtualBox\VBoxManage.exe"
    )) {
        if (Test-UsableExe $p) { return $p }
    }
    return $null
}

function Get-VBoxVersion([string]$VBoxManage) {
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $text = & $VBoxManage --version 2>&1 | Out-String
    $ErrorActionPreference = $prev
    if ($text -match '(\d+\.\d+\.\d+)') { return $Matches[1] }
    return $null
}

function Ensure-VirtualBox {
    param([string]$WingetExe)

    $existing = Find-VBoxManage
    $ver = $null
    if ($existing) { $ver = Get-VBoxVersion $existing }
    if ($ver -eq $virtualBoxVersion) {
        Write-Host "VirtualBox $virtualBoxVersion is already installed." -ForegroundColor Green
        Write-Host "  $existing" -ForegroundColor DarkGray
        Add-DirToMachinePath -BinDir (Split-Path -Parent $existing) | Out-Null
        return $existing
    }
    if ($ver) {
        Write-Host "VirtualBox $ver is installed. WinGet will install the pinned $virtualBoxVersion." -ForegroundColor Yellow
    }

    Write-Host "Installing VirtualBox $virtualBoxVersion via winget ($virtualBoxPackageId)..." -ForegroundColor Yellow
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & $WingetExe install --id $virtualBoxPackageId --version $virtualBoxVersion --exact --accept-source-agreements --accept-package-agreements --disable-interactivity
    $wingetCode = $LASTEXITCODE
    $ErrorActionPreference = $prev
    Refresh-SessionPath
    $existing = Find-VBoxManage
    $ver = $null
    if ($existing) { $ver = Get-VBoxVersion $existing }
    if ($ver -eq $virtualBoxVersion) {
        if ($wingetCode -eq 3010) {
            Write-Host "VirtualBox $virtualBoxVersion is installed. Windows asked for a reboot before the driver can load." -ForegroundColor Yellow
        } else {
            Write-Host "VirtualBox $virtualBoxVersion installed via WinGet." -ForegroundColor Green
        }
        Add-DirToMachinePath -BinDir (Split-Path -Parent $existing) | Out-Null
        return $existing
    }

    if ($wingetCode -eq 3010) {
        Fail "WinGet installed VirtualBox $virtualBoxVersion and requested a reboot. Reboot Windows, then run this installer again."
    }
    Fail "WinGet did not install VirtualBox $virtualBoxVersion (exit $wingetCode). Remove any other VirtualBox version, then run this installer again."
}

function Get-FreeBytes([string]$LiteralPath) {
    $item = Get-Item -LiteralPath $LiteralPath
    $drive = Get-PSDrive -Name $item.PSDrive.Name
    return [int64]$drive.Free
}

function Format-GiB([int64]$Bytes) {
    return ("{0:N1} GiB" -f ($Bytes / 1GB))
}

function Test-PortFree([int]$Port) {
    $listener = $null
    try {
        $listener = New-Object System.Net.Sockets.TcpListener ([System.Net.IPAddress]::Loopback, $Port)
        $listener.Start()
        return $true
    } catch {
        return $false
    } finally {
        if ($listener) { $listener.Stop() }
    }
}

function Assert-HostCanRunVm {
    param([switch]$SkipDisk)

    $problems = @()

    if (-not [Environment]::Is64BitOperatingSystem -or $env:PROCESSOR_ARCHITECTURE -ne "AMD64") {
        $problems += "This installer needs 64-bit Windows on an x86_64 CPU. CAD builds ELF x86_64 binaries."
    }

    $os = Get-CimInstance Win32_OperatingSystem
    $build = 0
    [void][int]::TryParse([string]$os.BuildNumber, [ref]$build)
    if ($build -lt 17763) {
        $problems += "Windows build $build is older than Windows 10 version 1809. VirtualBox $virtualBoxVersion needs Windows 10 or newer."
    }
    if ([int]$os.ProductType -ne 1) {
        Write-Host "This is Windows Server. VirtualBox $virtualBoxVersion is documented for Windows 10 and Windows Server 2022. The installer will still try." -ForegroundColor Yellow
    }

    $cpus = @(Get-CimInstance Win32_Processor)
    $cpu = $cpus | Select-Object -First 1
    $hv = $false
    $cs = Get-CimInstance Win32_ComputerSystem
    if ($cs.HypervisorPresent) { $hv = $true }
    $fwOff = $false
    $fwOn = $false
    $slatOff = $false
    $slatOn = $false
    foreach ($one in $cpus) {
        if ($one.VirtualizationFirmwareEnabled -eq $true) { $fwOn = $true }
        if ($one.VirtualizationFirmwareEnabled -eq $false) { $fwOff = $true }
        if ($one.SecondLevelAddressTranslationExtensions -eq $true) { $slatOn = $true }
        if ($one.SecondLevelAddressTranslationExtensions -eq $false) { $slatOff = $true }
    }
    Write-Host ("CPU: {0}" -f $cpu.Name)
    if ($fwOn) {
        Write-Host "Firmware virtualization (Intel VT-x or AMD-V): on" -ForegroundColor Green
    } elseif ($hv) {
        Write-Host "A hypervisor is already running, so firmware virtualization is on." -ForegroundColor Green
        Write-Host "VirtualBox will use the Windows hypervisor (Hyper-V, WSL2, or memory integrity). The Ubuntu VM still runs." -ForegroundColor Yellow
    } elseif ($fwOff) {
        $problems += @"
Firmware virtualization is turned off.
Restart this PC, open BIOS or UEFI setup, and enable Intel VT-x or AMD-V.
The setting is often named Intel Virtualization Technology, VT-x, AMD-V, or SVM Mode.
Then run this installer again.
"@
    } else {
        Write-Host "Could not read the firmware virtualization flag. Continuing. VirtualBox fails if VT-x or AMD-V is off." -ForegroundColor Yellow
    }
    if ($slatOff) {
        $problems += "This CPU does not have second-level address translation (SLAT). VirtualBox cannot run a 64-bit Ubuntu guest."
    } elseif ($slatOn -or $hv) {
        Write-Host "Second-level address translation (SLAT): on" -ForegroundColor Green
    } else {
        Write-Host "Could not read the SLAT flag. Continuing. A 64-bit guest needs SLAT." -ForegroundColor Yellow
    }

    if ($SkipDisk) {
        if ($problems.Count -gt 0) {
            foreach ($item in $problems) {
                Write-Host ""
                Write-Host $item -ForegroundColor Red
            }
            Fail "This PC cannot run the CAD virtual machine until the items above are fixed."
        }
        return
    }

    $seenDrives = @{}
    foreach ($pair in @(
        @{ Label = "project drive"; Path = $projectRoot },
        @{ Label = "user profile"; Path = $env:USERPROFILE }
    )) {
        $driveName = ""
        try {
            $driveName = (Get-Item -LiteralPath $pair.Path).PSDrive.Name
        } catch {
            $driveName = $pair.Label
        }
        if ($seenDrives.ContainsKey($driveName)) { continue }
        $seenDrives[$driveName] = $true
        try {
            $free = Get-FreeBytes $pair.Path
        } catch {
            $problems += "Could not measure free space on $($pair.Label)."
            continue
        }
        Write-Host ("Free space ({0}): {1}" -f $pair.Label, (Format-GiB $free))
        if ($free -lt $minFreeBytes) {
            $problems += "Need at least 24 GiB free on the $($pair.Label) for the Ubuntu disk, the Vagrant box, and the CAD build."
        }
    }

    if (-not (Test-Path -LiteralPath (Join-Path $projectRoot "run.sh"))) {
        $problems += "run.sh was not found in $projectRoot."
    }

    if ($problems.Count -gt 0) {
        foreach ($item in $problems) {
            Write-Host ""
            Write-Host $item -ForegroundColor Red
        }
        Fail "This PC cannot run the CAD virtual machine until the items above are fixed."
    }
}

function Test-VmCreated {
    $idFile = Join-Path $PSScriptRoot ".vagrant\machines\default\virtualbox\id"
    return (Test-Path -LiteralPath $idFile)
}

function Write-SetupStamp {
    $stamp = Join-Path $PSScriptRoot ".setup-complete"
    @(
        "vagrant=$vagrantVersion"
        "virtualbox=$virtualBoxVersion"
        "box=bento/ubuntu-24.04@$boxVersion"
        "completed=$((Get-Date).ToString('o'))"
    ) | Set-Content -LiteralPath $stamp -Encoding ASCII
}

function Resolve-ReadyTools {
    Refresh-SessionPath
    $vagrant = Find-VagrantExe
    $vbox = Find-VBoxManage
    if (-not $vagrant -or -not $vbox) { return $false }
    $vboxVer = Get-VBoxVersion $vbox
    if ($vboxVer -ne $virtualBoxVersion) { return $false }
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $text = & $vagrant --version 2>&1 | Out-String
    $ErrorActionPreference = $prev
    if ($text -notmatch [regex]::Escape($vagrantVersion)) { return $false }
    $script:VagrantExe = $vagrant
    $env:Path = "$(Split-Path -Parent $vagrant);$(Split-Path -Parent $vbox);$env:Path"
    Write-Host "Vagrant $vagrantVersion is already installed." -ForegroundColor Green
    Write-Host "  $vagrant" -ForegroundColor DarkGray
    Write-Host "VirtualBox $vboxVer is already installed." -ForegroundColor Green
    Write-Host "  $vbox" -ForegroundColor DarkGray
    return $true
}

function Get-SavedNovncHostPort {
    $vbox = Find-VBoxManage
    if (-not $vbox) { return $null }
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $info = & $vbox showvminfo "mmi-cad" --machinereadable 2>&1 | Out-String
    $ErrorActionPreference = $prev
    if ($info -match 'Forwarding\(\d+\)="mmi-novnc,tcp,[^,]+,(\d+),,6080"') {
        return [int]$Matches[1]
    }
    return $null
}

function Enter-Admin {
    if (Test-IsAdmin) { return }
    Write-Host ""
    Write-Host "Administrator rights are required to install VirtualBox and Vagrant." -ForegroundColor Yellow
    $ps = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -ElevatedChild"
    foreach ($a in $RunArgs) {
        if ($a -match '[\s"]') {
            $argList += " `"$($a.Replace('"', '\"'))`""
        } else {
            $argList += " $a"
        }
    }
    $proc = Start-Process -FilePath $ps -ArgumentList $argList -Verb RunAs -Wait -PassThru
    if (-not $proc) { Fail "Administrator approval was cancelled." }
    exit $proc.ExitCode
}

function New-GuestRunCommand {
    param([int]$HostPort)
    # One remote command. vagrant.exe passes it through unchanged; bash on the
    # guest splits it. guest-run.sh lives on the shared project folder.
    $parts = @(
        "MMI_NOVNC_HOST_PORT=$HostPort",
        "bash",
        "'/mmi-src/windows installer/guest-run.sh'"
    )
    foreach ($a in $RunArgs) {
        $parts += ("'" + ($a -replace "'", "'\''") + "'")
    }
    return ($parts -join " ")
}

function Start-NovncBrowserWatcher {
    param([int]$Port)
    $script:BrowserJob = Start-Job -ScriptBlock {
        param($ListenPort)
        $url = "http://127.0.0.1:${ListenPort}/vnc.html?autoconnect=1&resize=remote"
        for ($i = 0; $i -lt 720; $i++) {
            $client = New-Object System.Net.Sockets.TcpClient
            try {
                $wait = $client.BeginConnect("127.0.0.1", $ListenPort, $null, $null)
                $ok = $wait.AsyncWaitHandle.WaitOne(1500, $false)
                if ($ok) {
                    $client.EndConnect($wait)
                    if ($client.Connected) {
                        Start-Process $url
                        return
                    }
                }
            } catch {
            } finally {
                $client.Dispose()
            }
            Start-Sleep -Seconds 5
        }
    } -ArgumentList $Port
}

try {
    Write-Section "Check this PC"
    if (-not (Test-Path -LiteralPath $projectRoot)) {
        Fail "CAD project not found at $projectRoot."
    }
    $vmExists = Test-VmCreated
    $stampExists = Test-Path -LiteralPath (Join-Path $PSScriptRoot ".setup-complete")
    Assert-HostCanRunVm -SkipDisk:($vmExists -and $stampExists)
    $toolsReady = Resolve-ReadyTools
    $script:SetupAlreadyComplete = $toolsReady -and $vmExists -and $stampExists

    if ($script:SetupAlreadyComplete) {
        Write-Section "Setup already complete"
        Write-Host "Vagrant, VirtualBox, and the Ubuntu VM are already installed." -ForegroundColor Green
        Write-Host "Starting the virtual machine and ./run.sh." -ForegroundColor Green
    } else {
        if (-not $toolsReady -and $HOME -match '\s') {
            Fail "The vfox Vagrant plugin passes the install path to msiexec without quotes. This profile path contains a space: $HOME. Run the installer from an account whose profile path has no spaces."
        }
        Enter-Admin
    }

    $hostPort = $null
    if ($vmExists) {
        $savedPort = Get-SavedNovncHostPort
        if ($savedPort) {
            $hostPort = $savedPort
            Write-Host "CAD desktop port for this VM: $hostPort" -ForegroundColor DarkGray
        }
    }
    if (-not $hostPort) {
        $hostPort = 6080
        if (-not (Test-PortFree $hostPort)) {
            $found = $false
            foreach ($candidate in 6081..6090) {
                if (Test-PortFree $candidate) {
                    $hostPort = $candidate
                    $found = $true
                    break
                }
            }
            if (-not $found) {
                Fail "Ports 6080-6090 are in use. Close the program using them and run this installer again."
            }
            Write-Host "Port 6080 is in use. The CAD desktop will be forwarded to $hostPort." -ForegroundColor Yellow
        }
    }

    if (-not $toolsReady) {
    Write-Section "Bootstrap: WinGet"
    Ensure-Winget
    $wingetPackagesRoot = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages"
    Refresh-SessionPath -WingetPackagesRoot $wingetPackagesRoot
    $wingetExe = Find-WingetExe
    if (-not $wingetExe) { Fail "winget.exe was not found after install." }

    Write-Section "Bootstrap: vfox + Vagrant $vagrantVersion"
    if (-not (Get-Command vfox -ErrorAction SilentlyContinue)) {
        Write-Host "Installing vfox version $vfoxVersion via winget..." -ForegroundColor Yellow
        & $wingetExe install --id $vfoxPackageId --version $vfoxVersion --exact --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -ne 0) {
            Refresh-SessionPath -WingetPackagesRoot $wingetPackagesRoot
            if (-not (Get-Command vfox -ErrorAction SilentlyContinue)) {
                Fail "Failed to install vfox $vfoxVersion."
            }
        }
    } else {
        Write-Host "vfox is already installed." -ForegroundColor Green
    }

    Refresh-SessionPath -WingetPackagesRoot $wingetPackagesRoot
    foreach ($p in @(
        "$env:LOCALAPPDATA\vfox",
        "$HOME\AppData\Local\vfox",
        "$env:ProgramFiles\vfox"
    )) {
        if ((Test-Path -LiteralPath $p) -and ($env:Path -notlike "*$p*")) { $env:Path = "$p;$env:Path" }
    }
    if (-not (Get-Command vfox -ErrorAction SilentlyContinue)) {
        Fail "vfox executable could not be resolved. Please verify package availability."
    }
    Write-Host "vfox successfully located. Activating session environment..." -ForegroundColor Green
    Enable-VfoxSession

    Ensure-SudoForVfoxPlugin
    Write-Host "Adding the Vagrant plugin to vfox..." -ForegroundColor Yellow
    $addCode = Invoke-Vfox add --source $vagrantPluginZip vagrant
    if ($addCode -ne 0) {
        Write-Host "Plugin add returned $addCode. Continuing if vagrant is already added." -ForegroundColor Yellow
        Invoke-Vfox add vagrant | Out-Null
    }

    $installed = Install-VfoxSdk -Plugin "vagrant" -Version $vagrantVersion
    if (-not $installed) {
        if (-not (Install-VagrantMsiFallback)) {
            Fail "Failed to install vagrant@$vagrantVersion via vfox."
        }
    }

    Write-Host "Activating Vagrant $vagrantVersion..." -ForegroundColor Yellow
    Invoke-Vfox use -g "vagrant@$vagrantVersion" | Out-Null
    Enable-VfoxSession
    Refresh-SessionPath -WingetPackagesRoot $wingetPackagesRoot

    $script:VagrantExe = Find-VagrantExe
    if (-not $script:VagrantExe) {
        if (Install-VagrantMsiFallback) {
            Refresh-SessionPath -WingetPackagesRoot $wingetPackagesRoot
            $script:VagrantExe = Find-VagrantExe
        }
    }
    if (-not $script:VagrantExe) {
        Fail "vagrant.exe was not found after the vfox install."
    }
    Add-DirToMachinePath -BinDir (Split-Path -Parent $script:VagrantExe) | Out-Null
    $env:Path = "$(Split-Path -Parent $script:VagrantExe);$env:Path"
    Write-Host "Verifying Vagrant version..." -ForegroundColor Cyan
    $vagrantText = & $script:VagrantExe --version 2>&1 | Out-String
    Write-Host $vagrantText.Trim()
    if ($vagrantText -notmatch [regex]::Escape($vagrantVersion)) {
        Fail "Expected Vagrant $vagrantVersion and found: $($vagrantText.Trim())"
    }

    Write-Section "Bootstrap: VirtualBox $virtualBoxVersion"
    $vbox = Ensure-VirtualBox -WingetExe $wingetExe
    $probe = Get-VBoxVersion $vbox
    if (-not $probe) {
        Fail "VBoxManage did not answer. Reboot Windows so the VirtualBox driver can load, then run this installer again."
    }
    }

    Write-Section "Start Ubuntu and run ./run.sh"
    if ($script:SetupAlreadyComplete) {
        Write-Host "Opening the CAD applications in the existing Ubuntu VM." -ForegroundColor Yellow
    } else {
        Write-Host "Box: bento/ubuntu-24.04 $boxVersion (amd64, VirtualBox)" -ForegroundColor DarkGray
        Write-Host "First start downloads the box and builds CAD. Leave this window open." -ForegroundColor Yellow
    }
    $novncUrl = "http://127.0.0.1:${hostPort}/vnc.html?autoconnect=1&resize=remote"
    Write-Host "CAD desktop, once Nix has started it: $novncUrl" -ForegroundColor Cyan

    $env:VAGRANT_EXPERIMENTAL = "disks"
    $env:VAGRANT_DEFAULT_PROVIDER = "virtualbox"
    $env:VAGRANT_CHECKPOINT_DISABLE = "1"
    $env:MMI_VM_MEMORY = $script:VmMemory
    $env:MMI_VM_CPUS = $script:VmCpus
    $env:MMI_NOVNC_HOST_PORT = "$hostPort"
    $env:VAGRANT_CWD = $PSScriptRoot

    $prevNative = $null
    if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
        $prevNative = $PSNativeCommandUseErrorActionPreference
        $PSNativeCommandUseErrorActionPreference = $false
    }
    try {
        if ($script:SetupAlreadyComplete) {
            & $script:VagrantExe up --provider=virtualbox --no-provision
        } else {
            & $script:VagrantExe up --provider=virtualbox --provision
        }
        if ($LASTEXITCODE -ne 0) {
            Fail "vagrant up failed (exit $LASTEXITCODE). If VirtualBox was just installed, reboot Windows and run this installer again."
        }
        $stamp = Join-Path $PSScriptRoot ".setup-complete"
        if (-not (Test-Path -LiteralPath $stamp)) { Write-SetupStamp }
        Start-NovncBrowserWatcher -Port $hostPort
        $remote = New-GuestRunCommand -HostPort $hostPort
        & $script:VagrantExe ssh -- -t $remote
        $sshCode = $LASTEXITCODE
    } finally {
        if ($null -ne $prevNative) { $PSNativeCommandUseErrorActionPreference = $prevNative }
        if ($script:BrowserJob) {
            Stop-Job -Job $script:BrowserJob -ErrorAction SilentlyContinue
            Remove-Job -Job $script:BrowserJob -Force -ErrorAction SilentlyContinue
        }
    }
    if ($sshCode -ne 0) {
        Fail "vagrant ssh ./run.sh failed (exit $sshCode)."
    }

    Write-Section "Done"
    Write-Host "The CAD shell in the Ubuntu VM has exited." -ForegroundColor Green
    Write-Host "Run this again to start it. Example: run.cmd max" -ForegroundColor Green
    Write-Host "Desktop URL: $novncUrl" -ForegroundColor Green
} catch {
    Fail $_.Exception.Message
}
