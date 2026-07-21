Import-Module "$PSScriptRoot\Module.psm1"
Initialize-RuntimeDefaults
# ============================================================================
# MAIN FUNCTION
# ============================================================================
function Invoke-Parallel {
    param (
        [array]$Items,
        [scriptblock]$ScriptBlock,
        [int]$ThrottleLimit = 10,
        [string]$Label,
        [string]$SuccessFormat,
        [string]$FailFormat
    )
    if (-not $Items -or $Items.Count -eq 0) {
        return
    }
    else {
        Write-Log "Processing $($Items.Count) $Label in parallel (threads=$ThrottleLimit)..."
        $ScriptText = $ScriptBlock.ToString()
        $results = $Items | ForEach-Object -Parallel {
            $item = $_
            $data = [scriptblock]::Create($using:ScriptText)
            try {
                & $data $item
            }
            catch {
                @{
                    Name    = $item
                    Success = $false
                    Error   = $_.Exception.Message
                }
            }
        } -ThrottleLimit $ThrottleLimit
        foreach ($format in $results) {
            if ($format.Success) {
                Write-Log ($SuccessFormat -f $format.Name)
            }
            else {
                Write-Log ($FailFormat -f $format.Name, $format.Error)
            }
        }
        Write-Log "Completed processing for $Label"
    }
}
# ============================================================================
# DATA
# ============================================================================
$packages = @(
    'Microsoft.BingSearch'
    'Microsoft.BingNews'
    'Microsoft.BingWeather'
    'Microsoft.WindowsCamera'
    'Clipchamp.Clipchamp'
    'Microsoft.WindowsAlarms'
    'Microsoft.GetHelp'
    'Microsoft.WindowsCalculator'
    'Microsoft.Windows.DevHome'
    'MSTeams'
    'Microsoft.WindowsFeedbackHub'
    'Microsoft.WindowsTerminal'
    'Microsoft.MicrosoftOfficeHub'
    'Microsoft.OutlookForWindows'
    'Microsoft.PowerAutomateDesktop'
    'MicrosoftCorporationII.QuickAssist'
    'Microsoft.MicrosoftSolitaireCollection'
    'Microsoft.GamingApp'
    'Microsoft.XboxIdentityProvider'
    'Microsoft.Xbox.TCUI'
    'Microsoft.XboxGamingOverlay'
    'Microsoft.XboxSpeechToTextOverlay'
    'Microsoft.WindowsSoundRecorder'
    'Microsoft.MicrosoftStickyNotes'
    'Microsoft.Todos'
    'Microsoft.YourPhone'
    'MicrosoftWindows.CrossDevice'
    'MicrosoftWindows.Client.WebExperience'
)
$capabilities = @(
    'Browser.InternetExplorer'
    'Microsoft.Windows.PowerShell.ISE'
    'App.StepsRecorder'
    'Media.WindowsMediaPlayer'
    'Microsoft.Windows.Notepad'
    'OpenSSH.Client'
    'MathRecognizer'
)
$optionalFeatures = @(
    'Microsoft-RemoteDesktopConnection'
)
# ============================================================================
# MAIN
# ============================================================================
Write-Log "Discovering installed packages..."
$allInstalled = Get-AppxPackage -AllUsers 
$allProvisioned = Get-AppxProvisionedPackage -Online 
$packagesToRemove = [System.Collections.Generic.List[string]]::new()
$provisionedToRemove = [System.Collections.Generic.List[string]]::new()
$notFound = [System.Collections.Generic.List[string]]::new()
foreach ($package in $packages) {
    $installed = @($allInstalled | Where-Object Name -eq $package)
    $provisioned = @($allProvisioned | Where-Object DisplayName -eq $package)
    if ($installed) {
        foreach ($pkg in $installed) {
            $packagesToRemove.Add($pkg.PackageFullName)
        }
    }
    if ($provisioned) {
        foreach ($pkg in $provisioned) {
            $provisionedToRemove.Add($pkg.PackageName)
        }
    }
    if (-not $installed -and -not $provisioned) {
        $notFound.Add($package)
    }
}
if ($notFound.Count -gt 0) {
    Write-Log "Packages not found: $($notFound -join ', ')"
}
Invoke-Parallel -Items $provisionedToRemove `
    -ThrottleLimit 4 `
    -Label "provisioned packages" `
    -ScriptBlock {
        param($PackageName)
        try {
            Remove-AppxProvisionedPackage `
                -Online `
                -PackageName $PackageName `
                -ErrorAction Stop | Out-Null
            @{
                Name    = $PackageName
                Success = $true
                Error   = $null
            }
        }
        catch {
            @{
                Name    = $PackageName
                Success = $false
                Error   = $_.Exception.Message
            }
        }
    } `
    -SuccessFormat "Deprovisioned: {0}" `
    -FailFormat "Failed to deprovision {0}: {1}"
Invoke-Parallel -Items $packagesToRemove `
    -ThrottleLimit 4 `
    -Label "installed packages" `
    -ScriptBlock {
        param($PackageName)
        try {
            Remove-AppxPackage `
                -Package $PackageName `
                -AllUsers `
                -ErrorAction Stop | Out-Null
            @{
                Name    = $PackageName
                Success = $true
                Error   = $null
            }
        }
        catch {
            @{
                Name    = $PackageName
                Success = $false
                Error   = $_.Exception.Message
            }
        }
    } `
    -SuccessFormat "Removed installed package: {0}" `
    -FailFormat "Failed to remove installed package {0}: {1}"


Write-Log "Processing capabilities..."
$allCaps = Get-WindowsCapability -Online
$capNamesToRemove = [System.Collections.Generic.List[string]]::new()
foreach ($capability in $capabilities) {
    $matching = @()
    foreach ($item in $allCaps) {
        if ($item.Name -like "$capability*" -and $item.State -eq "Installed") {
            $matching += $item
        }
    }
    if ($matching) {
        foreach ($cap in $matching) {
            $capNamesToRemove.Add($cap.Name)
        }
    }
    else {
        Write-Log "Capability not found or not installed: $capability"
    }
}
Invoke-Parallel -Items $capNamesToRemove `
    -ThrottleLimit 4 `
    -Label "capabilities" `
    -ScriptBlock {
        param($CapabilityName)
        try {
            Remove-WindowsCapability `
                -Online `
                -Name $CapabilityName `
                -ErrorAction Stop | Out-Null
            @{
                Name    = $CapabilityName
                Success = $true
                Error   = $null
            }
        }
        catch {
            @{
                Name    = $CapabilityName
                Success = $false
                Error   = $_.Exception.Message
            }
        }
    } `
    -SuccessFormat "Removed capability: {0}" `
    -FailFormat "Failed to remove capability {0}: {1}"


Write-Log "Processing optional features..."
$enabledFeatures = foreach ($feature in $optionalFeatures) {
    try {
        $existing = Get-WindowsOptionalFeature `
            -Online `
            -FeatureName $feature `
            -ErrorAction Stop
        if ($existing.State -eq 'Enabled') {
            $feature
        }
        else {
            Write-Log "Feature already disabled: $feature"
        }
    }
    catch {
        Write-Log "Feature not found: $feature"
    }
}
if ($enabledFeatures.Count -gt 0) {
    $results = Invoke-Parallel -Items $enabledFeatures `
        -ThrottleLimit 4 `
        -Label "optional features" `
        -ScriptBlock {
            param($FeatureName)
            try {
                Disable-WindowsOptionalFeature `
                    -Online `
                    -FeatureName $FeatureName `
                    -NoRestart `
                    -WarningAction SilentlyContinue `
                    -ErrorAction Stop | Out-Null
                @{
                    Name          = $FeatureName
                    Success       = $true
                    Error         = $null
                }
            }
            catch {
                @{
                    Name          = $FeatureName
                    Success       = $false
                    Error         = $_.Exception.Message
                }
            }
        } `
        -SuccessFormat "Disabled feature: {0}" `
        -FailFormat "Failed to disable feature {0}: {1}"
}


$hasXbox = $packages -contains 'Microsoft.GamingApp' -or
           $packages -contains 'Microsoft.XboxGamingOverlay'
if ($hasXbox) {
    Write-Log "Applying Xbox/Game Bar registry settings..."
    $protocols = @(
        'ms-gamebar',
        'ms-gamebarservices'
    )
    $failed = @()
    foreach ($xbox in $protocols) {
        $base = "Registry::HKEY_CLASSES_ROOT\$xbox"
        $cmdPath = Join-Path $base 'shell\open\command'
        try {
            Set-RegistryValue -Path $base `
                -Name '(default)' `
                -Type 'String' `
                -Value "URL:$xbox" `
                -Desc 'URL Link to open apps'
            Set-RegistryValue -Path $base `
                -Name 'URL Protocol' `
                -Value '' `
                -Type 'String' `
                -Desc 'Leave empty to not launch url links'
            Set-RegistryValue -Path $base `
                -Name 'NoOpenWith' `
                -Value '' `
                -Type 'String' `
                -Desc 'Not visible on open with what dialogs'
            Set-RegistryValue -Path $cmdPath `
                -Name '(default)' `
                -Type 'String' `
                -Value "C:\Windows\System32\systray.exe" `
                -Desc 'shell thing for commands'
        }
        catch {
            $failed += $xbox
        }
    }
    if ($failed.Count -eq 0) {
        Write-Log "Game Bar protocol redirects applied successfully"
    }
    else {
        Write-Log "Game Bar protocol redirects failed for: $($failed -join ', ')" 'ERROR'
    }
    $verified = $true
    try {
        Write-Log "Applying Game DVR settings..."
        $AME = 'Registry::HKEY_USERS\AME_UserHive_Default'
        $userHive = (Test-Path $AME) ? $AME : 'Registry::HKEY_CURRENT_USER'
        $gameDvrPath    = "$userHive\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"
        $gameConfigPath = "$userHive\System\GameConfigStore"
        $policyPath     = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\GameDVR'
        Set-RegistryValue -Path $gameDvrPath `
            -Name 'AppCaptureEnabled' `
            -Value 0 `
            -Type 'DWord' `
            -Desc 'Capture recording'
        Set-RegistryValue -Path $gameConfigPath `
            -Name 'GameDVR_Enabled' `
            -Value 0 `
            -Type 'DWord' `
            -Desc 'Disable captures feature'
        Set-RegistryValue -Path $policyPath `
            -Name 'AllowGameDVR' `
            -Value 0 `
            -Type 'DWord' `
            -Desc 'policy set by administrative'
    }
    catch {
        $verified = $false
        Write-Log "Game DVR settings failed: $($_.Exception.Message)" 'ERROR'
    }
    if ($verified) {
        Write-Log "Xbox Game DVR settings applied successfully"
    }
}