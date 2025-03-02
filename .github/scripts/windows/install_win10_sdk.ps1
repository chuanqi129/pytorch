#Requires -RunAsAdministrator
<#
.SYNOPSIS
Silently install or update Windows 10 SDK without forced reboot.
.DESCRIPTION
- Downloads latest Windows SDK
- Uninstalls old versions (optional)
- Silent installation
- Verifies installation
- Refreshes environment
#>
 
# Configuration
$SDKDownloadURL = "https://go.microsoft.com/fwlink/?linkid=2164145"  # Win10 sdk version 2104
$SDKInstallerPath = "$env:USERPROFILE\Downloads\winsdksetup.exe"
$InstallLogPath = "$env:TEMP\WindowsSDK_Install.log"
 
# 1. Download SDK Installer
function Download-SDK {
    Write-Host "Downloading Windows SDK..."
    try {
        Invoke-WebRequest -Uri $SDKDownloadURL -OutFile $SDKInstallerPath -UseBasicParsing
        if (-not (Test-Path $SDKInstallerPath)) {
            throw "Download failed: File not found"
        }
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
        exit 1
    }
}
 
# 2. Uninstall Old SDK Versions (Optional)
function Uninstall-OldSDK {
    Write-Host "Uninstalling previous SDK versions..."
    $UninstallKeys = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" |
                    ForEach-Object { Get-ItemProperty $_.PSPath } |
                    Where-Object { $_.DisplayName -like "*Windows Software Development Kit*" }
 
    foreach ($key in $UninstallKeys) {
        $ProductCode = $key.PSChildName
        Write-Host "Uninstalling $($key.DisplayName)..."
        Start-Process -Wait -FilePath "msiexec.exe" -ArgumentList "/x $ProductCode /quiet /norestart"
    }
}
 
# 3. Silent SDK Installation
function Install-SDK {
    Write-Host "Installing SDK silently..."
    $Arguments = "/features + /quiet /norestart /log $InstallLogPath"
    $Process = Start-Process -FilePath $SDKInstallerPath -ArgumentList $Arguments -PassThru -Wait
 
    if ($Process.ExitCode -ne 0) {
        Write-Host "Installation failed. Exit code: $($Process.ExitCode). Check log: $InstallLogPath" -ForegroundColor Red
        exit 2
    }
}
 
# 4. Verify Installation
function Verify-Install {
    Write-Host "Verifying installation..."
    # Check installation directory
    $SDKBinPath = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.20348.0"
    if (Test-Path $SDKBinPath) {
        Write-Host "SDK installed successfully at: $SDKBinPath" -ForegroundColor Green
    } else {
        Write-Host "Warning: SDK directory not found. Installation may be incomplete." -ForegroundColor Yellow
    }
 
    # Check registry
    $KitsRoot = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows Kits\Installed Roots").KitsRoot10
    if ($KitsRoot) {
        Write-Host "Registry SDK path: $KitsRoot" -ForegroundColor Cyan
    }
}
 
# 5. Refresh Environment Variables
function Refresh-Environment {
    Write-Host "Refreshing environment variables..."
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}
 
# Main Execution
try {
    Download-SDK
    # Uninstall-OldSDK  # Comment this line to skip uninstallation
    Install-SDK
    Verify-Install
    Refresh-Environment
    Write-Host "Operation completed! Reboot is optional but recommended for full functionality." -ForegroundColor Green
} catch {
    Write-Host "Critical error: $_" -ForegroundColor Red
    exit 3
}