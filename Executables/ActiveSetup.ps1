param([switch]$Phase2)
Import-Module "$PSScriptRoot\Module.psm1"
Initialize-RuntimeDefaults
# ============================================================================
# CONFIGURATION
# ============================================================================
$activeSetupFolder = "C:\ProgramData\AME\ActiveSetup"
$activeSetupScript = Join-Path -Path $activeSetupFolder "ActiveSetup.ps1"
$hasFolderExists = Test-Path $activeSetupFolder
try {
    if (-not $hasFolderExists) {
        New-Item -Path $activeSetupFolder -ItemType Directory | Out-Null
        Write-Host "Created folder: $activeSetupFolder" -ForegroundColor Green
    }
    if ($PSCommandPath) {
        if ($PSCommandPath -ne $activeSetupScript) {
            Copy-Item -Path $PSCommandPath `
                -Destination $activeSetupScript `
                -Force `
                -ErrorAction Stop | Out-Null
            Write-Host "activeSetup script saved to: $activeSetupScript" -ForegroundColor Green
        }
        else {
            Write-Host "Running from activeSetup script. Skipping copy." -ForegroundColor Cyan
        }
    }
    else {
        Write-Warning "PSCommandPath is null. Cannot copy nonexistent script."
    }
}
catch {
    Write-Host "Failed to place script: $($_.Exception.Message)" -ForegroundColor Red
}
$LogFolder = 'C:\ProgramData\AME\Logs'
$global:LogFile = Join-Path $LogFolder "ActiveSetup.log"
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
# EXECUTION
# ============================================================================
$guid = '{A1D61A0D-ACBE-4C42-AE1E-123456789ABC}'
$activeSetupPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\$guid"
$activeSetupexists = Test-Path -Path $activeSetupPath
if (-not $activeSetupexists) {
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
elseif (-not $Phase2) {
    Start-Process `
        "C:\Program Files\PowerShell\7\pwsh.exe" `
        -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command "& ''C:\ProgramData\AME\ActiveSetup\ActiveSetup.ps1'' -Phase2"' `
        -WindowStyle Hidden
    exit
}
else {
    Write-Log "Running Phase 2"
    $lightTheme = ((Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\AME').UseLightTheme -eq 1) ? 1 : 0
    $wallpaperFolder = 'C:\Windows\Web\Wallpaper\Windows'
    $wallpaperFile = ($lightTheme -eq 1) ? "$wallpaperFolder\img0.jpg" : "$wallpaperFolder\img19.jpg"
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
        -Value 10 `
        -Desc 'Wallpaper mode'
    Set-RegistryValue -Path 'Registry::HKEY_CURRENT_USER\Control Panel\Desktop' `
        -Name 'TileWallpaper' `
        -Type 'String' `
        -Value 0 `
        -Desc 'Choose a fit for the desktop image'
    Set-RegistryValue -Path 'Registry::HKEY_CURRENT_USER\Control Panel\Desktop' `
        -Name 'WallPaper' `
        -Type 'String' `
        -Value $wallpaperFile `
        -Desc 'Wallpaper JPG'


    Write-Log "Restarting Windows Explorer"
    Stop-process -name explorer -force
    $refresh = [System.Diagnostics.Stopwatch]::StartNew()
    while ($refresh.ElapsedMilliseconds -lt 60000) {
        $verifyWallpaper = (Get-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Control Panel\Desktop').Wallpaper
        if ($verifyWallpaper -ne $wallpaperFile) {
            Set-RegistryValue -Path 'Registry::HKEY_CURRENT_USER\Control Panel\Desktop' `
                -Name 'WallPaper' `
                -Type 'String' `
                -Value $wallpaperFile `
                -Desc 'Wallpaper JPG'
        }
        else {
            rundll32.exe user32.dll,UpdatePerUserSystemParameters 1, True
        }
    }
}