#Requires -RunAsAdministrator

$VC_VERSION_major = [int] ${env:VC_VERSION}.split(".")[0]

$VC_DOWNLOAD_LINK = "https://aka.ms/vs/$VC_VERSION_major/release/vs_BuildTools.exe"

$COLLECT_DOWNLOAD_LINK = "https://aka.ms/vscollect.exe"
$VC_INSTALL_ARGS = @("--nocache","--quiet","--wait", "--add Microsoft.VisualStudio.Workload.VCTools",
                                                     "--add Microsoft.Component.MSBuild",
                                                     "--add Microsoft.VisualStudio.Component.Roslyn.Compiler",
                                                     "--add Microsoft.VisualStudio.Component.TextTemplating",
                                                     "--add Microsoft.VisualStudio.Component.VC.CoreIde",
                                                     "--add Microsoft.VisualStudio.Component.VC.Redist.14.Latest",
                                                     "--add Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Core",
                                                     "--add Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
                                                     "--add Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Win81")

if (${env:INSTALL_WINDOWS_SDK} -eq "1") {
    $VC_INSTALL_ARGS += "--add Microsoft.VisualStudio.Component.Windows10SDK.20348"
}

echo "Downloading Visual Studio installer from $VC_DOWNLOAD_LINK."
curl.exe --retry 3 -kL $VC_DOWNLOAD_LINK --output vs_installer.exe
if ($LASTEXITCODE -ne 0) {
    echo "Download of the VS ${env:VC_YEAR} Version ${env:VC_VERSION} installer failed"
    exit 1
}

$pathToRemove = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\${env:VC_YEAR}\BuildTools"
if (${env:VC_UNINSTALL_PREVIOUS} -eq "1") {
    echo "Uninstalling $pathToRemove."
    $VC_UNINSTALL_ARGS = @("uninstall", "--installPath", "`"$pathToRemove`"", "--quiet","--wait")
    $process = Start-Process "${PWD}\vs_installer.exe" -ArgumentList "$VC_UNINSTALL_ARGS" -NoNewWindow -Wait -PassThru
    $exitCode = $process.ExitCode
    if (($exitCode -ne 0) -and ($exitCode -ne 3010)) {
        echo "Original BuildTools uninstall failed with code $exitCode"
        # exit 1
    }
    Remove-Item -Path "$pathToRemove" -Recurse -Force
    echo "Other versioned BuildTools uninstalled."
}

echo "Installing Visual Studio version ${env:VC_VERSION}."
$process = Start-Process "${PWD}\vs_installer.exe" -ArgumentList $VC_INSTALL_ARGS -NoNewWindow -Wait -PassThru
Remove-Item -Path vs_installer.exe -Force
$exitCode = $process.ExitCode
if (($exitCode -ne 0) -and ($exitCode -ne 3010)) {
    echo "VS ${env:VC_YEAR} installer exited with code $exitCode, which should be one of [0, 3010]."
    curl.exe --retry 3 -kL $COLLECT_DOWNLOAD_LINK --output Collect.exe
    if ($LASTEXITCODE -ne 0) {
        echo "Download of the VS Collect tool failed."
        exit 1
    }
    Start-Process "${PWD}\Collect.exe" -NoNewWindow -Wait -PassThru
    New-Item -Path "C:\w\build-results" -ItemType "directory" -Force
    Copy-Item -Path "${env:TEMP}\vslogs.zip" -Destination "C:\w\build-results\"
    exit 1
}