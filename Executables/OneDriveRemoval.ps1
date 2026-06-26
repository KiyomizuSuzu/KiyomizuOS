Import-Module "$PSScriptRoot\Module.psm1"
Initialize-RuntimeDefaults
# ============================================================================
# MAIN FUNCTION
# ============================================================================
function Remove-File {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [string]$Desc #not required
    )
    $Name = Split-Path -Path $Path -Leaf
    try {
        $Exists = Test-Path -Path $Path
        if (-not $Exists) {
            Write-Log "File $Name does not exist." 'WARN'
        }
        else {
            Remove-Item -Path $Path `
                -ErrorAction Stop | Out-Null
            Write-Log "Successfully removed file $Name"
        }
    }
    catch {
        Write-Log "Failed to remove file $Name because $($_.Exception.Message)" 'ERROR'
    }
}
# ============================================================================
# EXECUTION
# ============================================================================
Write-Log 'Removing Onedrive from Windows 11'

$paths = @(
    "C:\Program Files\Microsoft OneDrive",
    "$env:LOCALAPPDATA\Microsoft\OneDrive",
    "C:\Users\Default\OneDrive"
)
$exeExists = Get-ChildItem $programFilesPath `
    -Filter "OneDriveSetup.exe" `
    -Recurse | Select-Object -First 1 -ExpandProperty FullName
if ($exeExists) {
    Write-Log "OneDrive installed" 'WARN'
    Get-Process *OneDrive* | Stop-Process -Force
    Start-Process -FilePath $exeExists -ArgumentList "/uninstall /allusers" -Wait
    Get-Process explorer, dllhost | Stop-Process -Force
    foreach ($found in $paths) {
        if (Test-Path -Path $path) {
            Write-Log "Removed $found"
            Remove-Item $path `
                -Recurse `
                -Force | Out-Null
        }
        else {
            Write-Log "$found wasn't found" 'WARN'
        }
    }
    Get-AppxPackage -AllUsers Microsoft.OneDriveSync | Remove-AppxPackage -AllUsers
}

Remove-RegistryKey -Path 'Registry::HKEY_USERS\AME_UserHive_Default\SOFTWARE\Microsoft\OneDrive' `
    -Desc 'Onedrive key for the main hive'

Remove-RegistryValue -Path 'Registry::HKEY_USERS\AME_UserHive_Default\Software\Microsoft\Windows\CurrentVersion\Run' `
    -Name 'OneDriveSetup' `
    -Desc 'Remove Onedrive setup autorun'

Remove-File -Path 'C:\Windows\System32\OneDriveSetup.exe' `
    -Desc 'OneDrivesetup in the system folder'

Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\OneDrive' `
    -Name 'DisableFileSyncNGSC' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'OneDrive disable policy'

Write-Log "OneDrive removal completed"