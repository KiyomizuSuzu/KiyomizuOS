# ============================================================================
# RUNTIME DEFAULTS
# ============================================================================
if ($PSVersionTable.PSEdition -ne "Core") {
    Write-Host "Windows Powershell is not supported, please use https://github.com/PowerShell/PowerShell/releases/latest" -ForegroundColor DarkCyan
    return
}
$ErrorActionPreference = 'SilentlyContinue'
# ============================================================================
# SETUP LOGGING
# ============================================================================
function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    switch ($Level) {
        'INFO'  { $color = 'Cyan' }
        'WARN'  { $color = 'Yellow' }
        'ERROR' { $color = 'Red' }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}
# ============================================================================
# MAIN FUNCTION
# ============================================================================
function Set-RegistryValue {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [ValidateSet(
            'String',
            'ExpandString',
            'Binary',
            'DWord',
            'MultiString',
            'QWord'
        )]
        [string]$Type,
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        $Value,
        [string]$Desc #not required
    )
    $keyExists = Test-Path -Path $Path
    if (-not $keyExists) {
        #create any subkeys if needed
        New-Item -Path $Path `
            -Force | Out-Null
    }
    else {
        try {
            switch ($Type) {
                'String'       { $Value = [string]$Value }
                'ExpandString' { $Value = [string]$Value }
                'Binary'       { $Value = [byte[]]$Value }
                'DWord'        { $Value = [int]$Value }
                'QWord'        { $Value = [long]$Value }
                'MultiString'  { $Value = [string[]]$Value }
            }
            #overwrites any existing value if needed
            Set-ItemProperty -Path $Path `
                -Name $Name `
                -Value $Value `
                -Force `
                -ErrorAction Stop | Out-Null
            Write-Log "Successfully set $Name value to $Value"
        }
        catch {
            Write-Log "Failed to set value $Name because $($_.Exception.Message)" 'ERROR'
        }
    }
}
function Remove-RegistryValue {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Name,
        [string]$Desc #not required
    )
    $keyExists = Test-Path -Path $Path
    if ($keyExists) {
        try {
            $item = Get-ItemProperty -Path $Path
            if ($item.PSObject.Properties.Match($Name)) {
                Remove-ItemProperty -Path $Path `
                    -Name $Name `
                    -ErrorAction Stop | Out-Null
                Write-Log "Successfully removed value $Name"
            }
            else {
                Write-Log "Value $Name doesn't exists." 'WARN'
            }
        }
        catch {
            Write-Log "Failed to remove value $Name because $($_.Exception.Message)" 'ERROR'
        }
    }
    else {
        Write-Log "Key $Path doesn't exists." 'WARN'
    }
}
function Remove-RegistryKey {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [string]$Desc #not required
    )
    $Name = ($Path -split '\\')[-1]
    $keyExists = Test-Path -Path $Path
    if ($keyExists) {
        try {
            #deletes any existing value if needed
            Remove-Item -Path $Path `
                -Recurse `
                -ErrorAction Stop | Out-Null
            Write-Log "Successfully removed key $Name"
        }
        catch {
            Write-Log "Failed to remove key $Name because $($_.Exception.Message)" 'ERROR'
        }
    }
    else {
        Write-Log "Key $Path doesn't exist." 'WARN'
    }
}
function Remove-File {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [string]$Desc  # optional description
    )
    $Name = Split-Path -Path $Path -Leaf
    try {
        Remove-Item -Path $Path `
            -ErrorAction Stop | Out-Null
        Write-Log "Successfully removed file $Name"
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