param(
    [switch]$Phase2
)
# ============================================================================
# RUNTIME DEFAULTS
# ============================================================================
if ($PSVersionTable.PSEdition -ne "Core") {
    Write-Host "Windows Powershell is not supported, please use https://github.com/PowerShell/PowerShell/releases/latest" -ForegroundColor DarkCyan
    return
}
$ErrorActionPreference = 'SilentlyContinue'
# ============================================================================
# PERSISTENT SCRIPT SETUP (Run Once)
# ============================================================================
$persistentFolder = "C:\ProgramData\AME\ActiveSetup"
$persistentScript = Join-Path -Path $persistentFolder "ActiveSetup.ps1"
$ScriptExists = Test-Path -Path $persistentScript
try {
    if (-not $ScriptExists) {
        $setupExists = Test-Path -Path $persistentFolder
        if (-not $setupExists) {
            New-Item -Path $persistentFolder `
                -ItemType Directory | Out-Null
            Write-Host "Created folder: $persistentFolder" -ForegroundColor Green
        }
        $scriptCopyTrue = $PSCommandPath
        if ($scriptCopyTrue) {
            Copy-Item -Path $PSCommandPath `
                -Destination $persistentScript | Out-Null
            Write-Host "Persistent script saved to: $persistentScript" -ForegroundColor Green
        } else {
            Write-Warning "PSCommandPath is null. Cannot persist script."
        }
    } else {
        Write-Host "Persistent script already exists. Skipping copy." -ForegroundColor Cyan
    }
}
catch {
    Write-Host "Failed to persist script: $($_.Exception.Message)" -ForegroundColor Red
}
# ============================================================================
# LOGGING SETUP
# ============================================================================
$LogFolder = 'C:\ProgramData\AME\Logs'
$LogFile   = Join-Path $LogFolder "ActiveSetup.log"
$FolderExists = Test-Path $LogFolder
if (-not $FolderExists) {
    try {
        New-Item -Path $LogFolder `
            -ItemType Directory | Out-null
        Write-Host "Created log folder: $LogFolder" -ForegroundColor Green
    } 
    catch {
        Write-Host "Failed to create log folder: $($_.Exception.Message)" -ForegroundColor Red
    }
}
$LogFileExists = Test-Path -Path $LogFile
if (-not $Phase2 -and $LogFileExists) {
    Clear-Content $LogFile -Force
}
# ============================================================================
# LOGGING FUNCTION
# ============================================================================
function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'INFO'  { 'Cyan' }
        'WARN'  { 'Yellow' }
        'ERROR' { 'Red' }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
    try {
        Add-Content -Path $LogFile `
            -Encoding UTF8 `
            -Value "$timestamp [$Level] $Message"
    } catch {
        Write-Host "Failed to write to log file: $($_.Exception.Message)" -ForegroundColor Red
    }
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
    try {
        if (-not $keyExists) {
            #create any subkeys if needed
            New-Item -Path $Path `
                -Force | Out-Null
        }
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
	        -Type $Type `
            -Value $Value `
            -Force `
            -ErrorAction Stop | Out-Null
        Write-Log "Successfully set $Name value to $Value"
    }
    catch {
        Write-Log "Failed to set value $Name because $($_.Exception.Message)" 'ERROR'
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
function New-RegistryKey {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [string]$Desc #not required
    )
    $Name = ($Path -split '\\')[-1]
    $keyExists = Test-Path -Path $Path
    if (-not $keyExists) {
        try {
            #create any subkeys if needed
            New-Item -Path $Path `
                -Force | Out-Null
            Write-Log "Successfully created key $Name" 
        }
        catch {
            Write-Log "Failed to create key $Name because $($_.Exception.Message)" 'ERROR'
        }
    }
    else {
        Write-Log "Key $Path already exists." 'WARN'
    }
}
function Set-BinaryBit {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [int]$ByteIndex,
        [Parameter(Mandatory)]
        [byte]$BitMask,
        [Parameter(Mandatory)]
        [bool]$SetBit,
        [string]$Desc #not required
    )
    $keyExists = Test-Path -Path $Path
    if (-not $keyExists) {
        #create any subkeys if needed
        New-Item -Path $Path `
            -Force | Out-Null
    }
    try{
        $dataExists = Get-ItemProperty -Path $Path `
                            -Name $Name 
        if (-not $dataExists) {
            $bytes = [byte[]]::new([Math]::Max(12, $ByteIndex + 1))
        }
        else {
            $bytes = [byte[]]$dataExists.$Name
        }
        if ($SetBit -eq $true) {
            $bytes[$ByteIndex] = $bytes[$ByteIndex] -bor $BitMask
        }
        else {
            $bytes[$ByteIndex] = $bytes[$ByteIndex] -band (-bnot $BitMask)
        }
        #overwrites any existing value if needed
        Set-ItemProperty -Path $Path `
            -Name $Name `
            -Type Binary `
            -Value $bytes `
            -Force `
            -ErrorAction Stop | Out-Null
        Write-Log "Successfully set bit $Name to 0x$($BitMask.ToString('X2'))"
    }
    catch {
        Write-Log "Failed to set bit $Name because $($_.Exception.Message)" 'ERROR'
    }
}
function Set-BinaryByte {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [int]$ByteIndex,
        [Parameter(Mandatory)]
        [byte]$ByteValue,
        [string]$Desc #not required
    )
    $keyExists = Test-Path -Path $Path
    if (-not $keyExists) {
        #create any subkeys if needed
        New-Item -Path $Path `
            -Force | Out-Null
    }
    try{
        $dataExists = Get-ItemProperty -Path $Path `
                            -Name $Name 
        if (-not $dataExists) {
            $bytes = [byte[]]::new([Math]::Max(12, $ByteIndex + 1))
        }
        else {
            $bytes = [byte[]]$dataExists.$Name
        }
        $bytes[$ByteIndex] = $ByteValue
        #overwrites any existing value if needed
        Set-ItemProperty -Path $Path `
            -Name $Name `
            -Type Binary `
            -Value $bytes `
            -Force `
            -ErrorAction Stop | Out-Null
        Write-Log "Successfully set byte $Name to 0x$($ByteValue.ToString('X2'))" 
    } 
    catch {
        Write-Log "Failed to set byte $Name because $($_.Exception.Message)" 'ERROR'
    }
}
# ============================================================================
# EXECUTION
# ============================================================================
$guid = '{A1D61A0D-ACBE-4C42-AE1E-123456789ABC}'
$activeSetupPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\$guid"
$activeSetupexists = Test-Path -Path $activeSetupPath

if (-not $activeSetupexists -and -not $Phase2) {
    Write-Log "Registering Active Setup component"
    Set-RegistryValue -Path $activeSetupPath `
        -Name 'Version' `
        -Type 'String' `
        -Value '1,0' `
        -Desc 'Active Setup component version'
    Set-RegistryValue -Path $activeSetupPath `
        -Name 'IsInstalled' `
        -Type 'DWord' `
        -Value 1 `
        -Desc 'Enable Active Setup component'
    Set-RegistryValue -Path $activeSetupPath `
        -Name 'LocalizedName' `
        -Type 'String' `
        -Value 'AME First Logon Tweaks' `
        -Desc 'Active Setup display name'
    Set-RegistryValue -Path $activeSetupPath `
        -Name 'StubPath' `
        -Type 'String' `
        -Value '"C:\Program Files\PowerShell\7\pwsh.exe" -NoProfile -ExecutionPolicy Bypass -File "C:\ProgramData\AME\ActiveSetup\ActiveSetup.ps1"' `
        -Desc 'Execute first logon tweak script'
}
elseif ($activeSetupexists -and -not $Phase2) {
    Start-Process `
        "C:\Program Files\PowerShell\7\pwsh.exe" `
        -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command "& ''C:\ProgramData\AME\ActiveSetup\ActiveSetup.ps1'' -Phase2"' `
        -WindowStyle Hidden
    exit
}
else {
    Write-Log "Running Phase 2"
    $lightTheme = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\AME').UseLightTheme
    if ($lightTheme -eq 1) {
        Write-Log "Lightmode is selected."
        $wallpaperPath = 'C:\Windows\Web\Wallpaper\Windows\img0.jpg'
    }
    else {
        $lightTheme = 0
        Write-Log "Darkmode is selected."
        $wallpaperPath = 'C:\Windows\Web\Wallpaper\Windows\img19.jpg'
    }
    $waitingForWindows = $true
    while ($waitingForWindows) {
        $validExplorer = (Get-Process -Name explorer).MainWindowHandle
        if ($validExplorer) {
            $waitingForWindows = $false
            Write-Log "Windows Explorer has started."
        }
        else {
            Start-Sleep -Milliseconds 500
        }
    }
    Set-BinaryBit -Path "Registry::HKEY_CURRENT_USER\Control Panel\Desktop" `
        -Name 'UserPreferencesMask' `
        -ByteIndex 4 `
        -BitMask 0x02 `
        -SetBit $False `
        -Desc 'System UI animations'
    Set-RegistryValue -Path "Registry::HKEY_CURRENT_USER\Control Panel\Desktop\WindowMetrics" `
        -Name 'MinAnimate' `
        -Type 'String' `
        -Value 0 `
        -Desc 'Window minimize/maximize animation'
    Set-RegistryValue -Path "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
        -Name 'TaskbarAnimations' `
        -Type 'DWord' `
        -Value 0 `
        -Desc 'Taskbar animations'
    Set-RegistryValue -Path "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\DWM" `
        -Name 'EnableAeroPeek' `
        -Type 'DWord' `
        -Value 1 `
        -Desc 'Desktop peek feature'
    Set-BinaryBit -Path "Registry::HKEY_CURRENT_USER\Control Panel\Desktop" `
        -Name 'UserPreferencesMask' `
        -ByteIndex 0 `
        -BitMask 0x02 `
        -SetBit $False `
        -Desc 'Menu animations'
    Set-BinaryBit -Path "Registry::HKEY_CURRENT_USER\Control Panel\Desktop" `
        -Name 'UserPreferencesMask' `
        -ByteIndex 1 `
        -BitMask 0x08 `
        -SetBit $False `
        -Desc 'Tooltip animations'
    Set-BinaryBit -Path "Registry::HKEY_CURRENT_USER\Control Panel\Desktop" `
        -Name 'UserPreferencesMask' `
        -ByteIndex 1 `
        -BitMask 0x04 `
        -SetBit $False `
        -Desc 'Menu fade effects'
    Set-RegistryValue -Path "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\DWM" `
        -Name 'AlwaysHibernateThumbnails' `
        -Type 'DWord' `
        -Value 0 `
        -Desc 'Taskbar thumbnail caching'
    Set-BinaryBit -Path "Registry::HKEY_CURRENT_USER\Control Panel\Desktop" `
        -Name 'UserPreferencesMask' `
        -ByteIndex 1 `
        -BitMask 0x20 `
        -SetBit $True `
        -Desc 'Mouse cursor shadow'
    Set-BinaryBit -Path "Registry::HKEY_CURRENT_USER\Control Panel\Desktop" `
        -Name 'UserPreferencesMask' `
        -ByteIndex 2 `
        -BitMask 0x04 `
        -SetBit $False `
        -Desc 'Window shadows'
    Set-RegistryValue -Path "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
        -Name 'IconsOnly' `
        -Type 'DWord' `
        -Value 0 `
        -Desc 'File preview vs icons'
    Set-RegistryValue -Path "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
        -Name 'ListviewAlphaSelect' `
        -Type 'DWord' `
        -Value 0 `
        -Desc 'Selection box transparency'
    Set-RegistryValue -Path "Registry::HKEY_CURRENT_USER\Control Panel\Desktop" `
        -Name 'DragFullWindows' `
        -Type 'String' `
        -Value 1 `
        -Desc 'Show window contents while dragging'
    Set-RegistryValue -Path "Registry::HKEY_CURRENT_USER\Control Panel\Desktop" `
        -Name 'FontSmoothing' `
        -Type 'String' `
        -Value 2 `
        -Desc 'Font anti-aliasing'
    Set-BinaryBit -Path "Registry::HKEY_CURRENT_USER\Control Panel\Desktop" `
        -Name 'UserPreferencesMask' `
        -ByteIndex 0 `
        -BitMask 0x04 `
        -SetBit $False `
        -Desc 'Combo box animation'
    Set-BinaryBit -Path "Registry::HKEY_CURRENT_USER\Control Panel\Desktop" `
        -Name 'UserPreferencesMask' `
        -ByteIndex 0 `
        -BitMask 0x08 `
        -SetBit $False `
        -Desc 'Smooth scrolling'
    Set-RegistryValue -Path "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
        -Name 'ListviewShadow' `
        -Type 'DWord' `
        -Value 0 `
        -Desc 'Desktop icon text shadow'


    Set-RegistryValue -Path "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Search" `
        -Name 'SearchboxTaskbarMode' `
        -Type 'DWord' `
        -Value 1 `
        -Desc 'Choose how Windows search appears on the taskbar: hidden, icon only, icon with label, or full search box'
    Set-RegistryValue -Path "Registry::HKEY_CURRENT_USER\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" `
        -Name '(Default)' `
        -Type 'String' `
        -Value '' `
        -Desc 'Use the Windows 10-style right-click menu with all options visible instead of the simplified Windows 11 menu'
    Set-RegistryValue -Path "Registry::HKEY_CURRENT_USER\Control Panel\Accessibility\HighContrast" `
        -Name 'Flags' `
        -Type 'String' `
        -Value 4194 `
        -Desc 'High contrast shortcut'
    Set-RegistryValue -Path "Registry::HKEY_CURRENT_USER\Software\Classes\CLSID\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" `
        -Name 'System.IsPinnedToNameSpaceTree' `
        -Type 'DWord' `
        -Value 0 `
        -Desc 'Show Home folder'
    Set-RegistryValue -Path "Registry::HKEY_CURRENT_USER\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" `
        -Name 'System.IsPinnedToNameSpaceTree' `
        -Type 'DWord' `
        -Value 0 `
        -Desc 'Show Gallery folder'


    Set-RegistryValue -Path 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' `
        -Name 'AppsUseLightTheme' `
        -Type 'DWord' `
        -Value $lightTheme `
        -Desc 'App theme mode'
    Set-RegistryValue -Path 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' `
        -Name 'SystemUsesLightTheme' `
        -Type 'DWord' `
        -Value $lightTheme `
        -Desc 'System theme mode'
    Set-RegistryValue -Path 'Registry::HKEY_CURRENT_USER\Control Panel\Desktop' `
        -Name 'WallpaperStyle' `
        -Type 'String' `
        -Value '10' `
        -Desc 'Wallpaper mode'
    Set-RegistryValue -Path 'Registry::HKEY_CURRENT_USER\Control Panel\Desktop' `
        -Name 'TileWallpaper' `
        -Type 'String' `
        -Value '0' `
        -Desc 'Choose a fit for the desktop image'
    Set-RegistryValue -Path 'Registry::HKEY_CURRENT_USER\Control Panel\Desktop' `
        -Name 'WallPaper' `
        -Type 'String' `
        -Value $wallpaperPath `
        -Desc 'Wallpaper file'

    Write-Log "Restarting Windows Explorer"
    Stop-process -name explorer -force
    $refresh = [System.Diagnostics.Stopwatch]::StartNew()
    while ($refresh.ElapsedMilliseconds -lt 60000) {
        $verifyWallpaper = (Get-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Control Panel\Desktop').Wallpaper
        if ($verifyWallpaper -ne $wallpaperPath) {
            Write-Log "Wallpaper was overwritten: $VerifyWallpaper" 'WARN'
            Set-RegistryValue -Path 'Registry::HKEY_CURRENT_USER\Control Panel\Desktop' `
                -Name 'WallPaper' `
                -Type 'String' `
                -Value $wallpaperPath `
                -Desc 'Wallpaper file'
            $verifiedWallpaper = $false
        }
        else {
            rundll32.exe user32.dll,UpdatePerUserSystemParameters 1, True
            $verifiedWallpaper = $true
        }
    }
    if ($verifiedWallpaper) {
        Write-Log "Successfully notified changes to apply properly."
    }
    else {
        Write-Log "Changes made were not applied properly." 'ERROR'
    }
}
