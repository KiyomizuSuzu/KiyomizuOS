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
            New-Item -Path $Path `
                -Force `
                -ErrorAction Stop | Out-Null
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
        Set-ItemProperty -Path $Path `
            -Name $Name `
            -Type Binary `
            -Value $bytes `
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
        Set-ItemProperty -Path $Path `
            -Name $Name `
            -Type Binary `
            -Value $bytes `
            -ErrorAction Stop | Out-Null
        Write-Log "Successfully set byte $Name to 0x$($ByteValue.ToString('X2'))" 
    } 
    catch {
        Write-Log "Failed to set byte $Name because $($_.Exception.Message)" 'ERROR'
    }
}
$AMEexists = Test-Path -Path 'Registry::HKEY_USERS\AME_UserHive_Default'
if ($AMEexists) {
    $userHive = 'Registry::HKEY_USERS\AME_UserHive_Default'
}
else {
    $userHive = 'Registry::HKEY_CURRENT_USER'
}
$totalRAMinKB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB) * 1MB
$icoPath = "C:\Windows\blank.ico"
try {
    $icoMadeAlready = Test-Path -Path $icoPath
    if (-not $icoMadeAlready) {
        $b64='AAABAAEAAAAAAAEAIAC5BwAAFgAAAIlQTkcNChoKAAAADUlIRFIAAAEAAAABAAgGAAAAXHKoZgAAB4BJREFUeNrt3eGSmzYAhVFnp+//xJlM67ZJ3Y0XkJBA0j1nJn+yDggEnzG2N98eQKxvdw8AuI8AQDABgGACAMEEAIIJAAQTAAgmABBMACCYAEAwAYBgAgDBBACCCQAEEwAIJgAQTAAgmABAMAGAYAIAwQQAggkABBMACCYAEEwAIJgAQDABgGACAMEEAIIJAAQTAAgmABBMACCYAEAwAYBgAgDBBACCJQXg48Bjftw9SLjSSgHYO8GPnNwfBY+F6c0cgM8nfMuT9qPx8mBIMwbgqmdpVwMsb7YA3PHM7GqAZc0UgDtPRBFgSTMEYJRLcRFgOSMHYJQT/3U8o4wFmhg1AKOebKOOC6qMGICRT7KRxwbFBGC98cFhowVghpNrhjHCIQKw9jhh00gBGO2u/95YZxgnbBKAc+OdZazw1igB+HkyzXRSzTRWeGuEAHw+kWY6sWYaK/xGANqOneuZgxPuDsC7yZtpQmca66rMwQkC0GcbuI79f4IA9NkGrmUOKglAn23gWuag0ogB2Pr7Ec001lWZg0oC0G8buJZ5qCAAfbeD65iDCgLQdzu4jjmoIAB9t4NrmYdCowZg72ejmWmsKzMPhQSg/3ZwHfNQ6O4AbJlpMmca68rMQyEByBvrysxDIQHIG+vqzEUBAcgb6+rMRYGRA/A0y2TOMs4E5qKAAGSNM4G5KCAAWeNMYC4KCEDGGJOYjwICsPb4UpmXgwRg7fGlMi8HCcCaY0tnbg4SgLXGxT/Mz0ECUDemx4Dj4j8jHjdDEoC5x8N75ukgATg+jscgY+GYUY6doQnA/vofN4+BOncfO1MQgDHXzXnm7wABeL/Oxw3rpS0BOEAA/r+ux4Xroy8BOGD0ADx97Py8dpI/L9fBsh4R2DF6AD7+/fN95zE/dn7+jgNjfQKwY4YAPO1N4tZVggMglwDsmCEANZNo0nkSgB2jB+CpZhLd0ONJAHasGoDXf/s48e+ZnwhsWD0ALZfBnMz9hhkC8CQC1DLvGwSA1Zn3DUkBaLkc5mHON6QFoPWyGJ/53pAYgB7LY2zm+wsCQALz/YVZAvAkAtQy119IDkCvZTIe8/yF9AD0XO679XzmoLyGAHxBAPove2v5DsxyryEt2Xf29RsC0H/5W8tNOShb/vKV2u93pOzrIgLQd/lHlrn6gfl5+858Qevnsmq/Ibryfq4iAP3WcXRZR36j0dHlvBrhYG/90kcAGhOAPusoPanPvkwoWd5Verz0aXH1wAsB6LOeVs/qPx/7eJSfTHcf8C0DUHvjb7R9MpyZAvA0w1XA0Wfsx8H1bD221Ul29YesagLgy2AdCEDb9ZRerp+NRYsTrcdvTbryCqjluHrvl+EIQNv19ArAuxtfLd5hKB1Lj32w9ZhH4/EJwCcC0G5dtQf+0ZO05mQteYlw1w3QksdcFYEz7zZMRQDarW/EAGw9tmYsLfZDi58/TozzjquiYQlAm/X1fFZ7d0COGoDak7vmLn+Pl2m9ojis2QLwNOLLgLOve0sv1R+F+6D15w5Kt/HMjcya9dWOccS3U7sSgDbr63nZ2+qjtEevHlqdkHvP6q1usrW4V9NznwxNANqs7+obX2ee+a4IwF7QHifWcXbMtTc/l4yAALRZX82l794yWl82l9w/6PFR3aP7oudbsO8eJwCTuWMiau9M3/WR15Ix1mzv1pg/vnhcz5t7tdvW6q3eaT8zIADt1tnqN/70PJhava3ZM1Sfl39E7Ul8xf2Doc0YgDtMPckNt3naZ7ovtqvFuwhTHxsCcMzUk3xyu1+tsA8E4IUAHDf1RPNLi4/5LvNpQQE4buqJ5pcWL2OW+a6AAJRZ4TVwupYfQGqxnFsJQJklJj3c9M/ajfx9LAsAaQTgZR8IAGR4+9kNAYC1bb5sFQBYS9FnNwQA5nX64+cCAPNo/slMAYAxtfpy2SYBgPtsfevxkrcqBQDaO/p15ts/jyAAUG7vBL/9xD5KAOBrZ3+70fAEgHS3vw6/kwCQIPok3yIArGT5S/bWBIDZeDZvSAAYzTJ32GcgAFzNCT4QAaA1J/hEBIBabrgtQADY4obb4gSAJ8/mj8cff/35fvcgriYAOTyb8xsBWI9ncw4TgPmt+P/3cREBgGACAMEEAIIJAAQTAAgmABBMACCYAEAwAYBgAgDBBACCCQAEEwAIJgAQTAAgmABAMAGAYAIAwQQAggkABBMACCYAEEwAIJgAQDABgGACAMEEAIIJAAQTAAgmABBMACCYAEAwAYBgAgDBBACCCQAEEwAIJgAQTAAgmABAMAGAYAIAwQQAggkABBMACCYAEEwAIJgAQDABgGACAMEEAIIJAAQTAAgmABBMACCYAEAwAYBgAgDBBACCCQAEEwAIJgAQTAAgmABAMAGAYAIAwQQAggkABBMACCYAEEwAIJgAQDABgGACAMEEAIIJAAQTAAgmABBMACCYAEAwAYBgAgDBBACCCQAEEwAIJgAQTAAgmABAMAGAYAIAwQQAggkABBMACCYAEEwAIJgAQDABgGACAMEEAIIJAAQTAAgmABBMACCYAEAwAYBgAgDB/gRG/ewS3uwoeAAAAABJRU5ErkJggg=='
        [IO.File]::WriteAllBytes($icoPath,[Convert]::FromBase64String($b64))
        Write-Log "Created $icoPath"
    }
    else {
        Write-Log "$icoPath already made." 'WARN'
    }
}
catch {
    Write-Log "Failed to create $icoPath because $($_.Exception.Message)" 'ERROR'
}
# ============================================================================
# PRIVACY & SECURITY SETTINGS
# ============================================================================
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WorkplaceJoin' `
    -Name 'BlockAADWorkplaceJoin' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Show Allow my organization to manage my device prompts throughout Windows'
    Set-RegistryValue -Path "$userHive\SOFTWARE\Policies\Microsoft\Windows\WorkplaceJoin" `
        -Name 'BlockAADWorkplaceJoin' `
        -Type 'DWord' `
        -Value 1 `
        -Desc 'Show ''Allow my organization to manage my device'' prompts throughout Windows'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting' `
    -Name 'Value' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Allow sharing WiFi passwords with contacts and automatically connecting to suggested open hotspots'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots' `
    -Name 'Value' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Allow sharing WiFi passwords with contacts and automatically connecting to suggested open hotspots'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting' `
    -Name 'Disabled' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Choose if Windows should send crash reports and error Log to Microsoft'
    Set-RegistryValue -Path "$userHive\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" `
        -Name 'Disabled' `
        -Type 'DWord' `
        -Value 1 `
        -Desc 'Controls Windows crash reporting to Microsoft'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Remote Assistance' `
    -Name 'fAllowToGetHelp' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Remote Assistance access control'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CI\Policy' `
    -Name 'VerifiedAndReputablePolicyState' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Smart App Control state configuration'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell' `
    -Name 'ExecutionPolicy' `
    -Type 'String' `
    -Value 'RemoteSigned' `
    -Desc 'PowerShell script execution policy'
    Set-RegistryValue -Path "$userHive\Software\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" `
        -Name 'ExecutionPolicy' `
        -Type 'String' `
        -Value 'RemoteSigned' `
        -Desc 'Controls PowerShell script execution policy'


Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name 'ContentDeliveryAllowed' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables promotional content delivery'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name 'SubscribedContentEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables subscribed promotional content'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name 'FeatureManagementEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables feature-driven promotional installations'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name 'SoftLandingEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables tips and suggestions'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name 'OemPreInstalledAppsEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Blocks OEM bloatware installs'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name 'PreInstalledAppsEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Blocks Microsoft suggested app installs'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name 'PreInstalledAppsEverEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables tracking of preinstalled app activation'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name 'SilentInstalledAppsEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Prevents silent app installs'


Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name 'RotatingLockScreenEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables Windows Spotlight lock screen rotation'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name 'RotatingLockScreenOverlayEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables lock screen tips overlay'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name 'SubscribedContent-338387Enabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables lock screen content suggestions'


Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" `
    -Name 'Enabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables advertising ID'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\CPSS\Store\AdvertisingInfo" `
    -Name 'Value' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables advertising personalization'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo' `
    -Name 'DisabledByGroupPolicy' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Advertising ID control'
    Set-RegistryValue -Path "$userHive\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" `
        -Name 'DisabledByGroupPolicy' `
        -Type 'DWord' `
        -Value 1 `
        -Desc 'Disables advertising ID via policy'
Set-RegistryValue -Path "$userHive\Control Panel\International\User Profile" `
    -Name 'HttpAcceptLanguageOptOut' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Prevents websites from reading language preferences'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name 'Start_TrackProgs' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables Start menu app tracking'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name 'SubscribedContent-338393Enabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables Settings app suggestions'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name 'SubscribedContent-353694Enabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables Settings app suggestions'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name 'SubscribedContent-353696Enabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables Settings app suggestions'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications" `
    -Name 'EnableAccountNotifications' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables account notifications in Settings'


Set-RegistryValue -Path "$userHive\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" `
    -Name 'HasAccepted' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables online speech recognition consent'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Narrator\NoRoam" `
    -Name 'OnlineServicesEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables Narrator cloud services'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Narrator\NoRoam" `
    -Name 'ScriptingEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables Narrator scripting'


Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\CPSS\Store\InkingAndTypingPersonalization" `
    -Name 'Value' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables typing and handwriting personalization'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Personalization\Settings" `
    -Name 'AcceptedPrivacyPolicy' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables personalization consent tracking'
Set-RegistryValue -Path "$userHive\Software\Microsoft\InputPersonalization" `
    -Name 'RestrictImplicitTextCollection' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Restricts typing data collection'
Set-RegistryValue -Path "$userHive\Software\Microsoft\InputPersonalization\TrainedDataStore" `
    -Name 'HarvestContacts' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables contact-based learning'


Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack" `
    -Name 'ShowedToastAtLevel' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Diagnostic tracking state'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' `
    -Name 'AllowTelemetry' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Telemetry level control'
    Set-RegistryValue -Path "$userHive\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" `
        -Name 'AllowTelemetry' `
        -Type 'DWord' `
        -Value 0 `
        -Desc 'Disables telemetry'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection' `
    -Name 'AllowTelemetry' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Data collection policy'
    Set-RegistryValue -Path "$userHive\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
        -Name 'AllowTelemetry' `
        -Type 'DWord' `
        -Value 0 `
        -Desc 'Disables telemetry via policy'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' `
    -Name 'MaxTelemetryAllowed' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Maximum telemetry level'
    Set-RegistryValue -Path "$userHive\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" `
        -Name 'MaxTelemetryAllowed' `
        -Type 'DWord' `
        -Value 0 `
        -Desc 'Sets telemetry maximum level to zero'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AppCompat' `
    -Name 'AITEnable' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Application compatibility telemetry'
    Set-RegistryValue -Path "$userHive\SOFTWARE\Policies\Microsoft\Windows\AppCompat" `
        -Name 'AITEnable' `
        -Type 'DWord' `
        -Value 0 `
        -Desc 'Disables application telemetry'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Input\TIPC" `
    -Name 'Enabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables inking and typing telemetry'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\CPSS\Store\ImproveInkingAndTyping" `
    -Name 'Value' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables typing improvement telemetry'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Privacy" `
    -Name 'TailoredExperiencesWithDiagnosticDataEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables tailored experiences'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection' `
    -Name 'DoNotShowFeedbackNotifications' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Feedback prompt suppression'
    Set-RegistryValue -Path "$userHive\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
        -Name 'DoNotShowFeedbackNotifications' `
        -Type 'DWord' `
        -Value 1 `
        -Desc 'Disables feedback prompts'
Set-RegistryValue -Path "$userHive\SOFTWARE\Microsoft\Siuf\Rules" `
    -Name 'NumberOfSIUFInPeriod' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables feedback frequency'


Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\SearchSettings" `
    -Name 'IsDeviceSearchHistoryEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables local search history'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\SearchSettings" `
    -Name 'IsDynamicSearchBoxEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables search suggestions'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\SearchSettings" `
    -Name 'IsMSACloudSearchEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables Microsoft account cloud search'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\SearchSettings" `
    -Name 'IsAADCloudSearchEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables work/school cloud search'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Search' `
    -Name 'AllowCortana' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Cortana availability'
    Set-RegistryValue -Path "$userHive\SOFTWARE\Policies\Microsoft\Windows\Windows Search" `
        -Name 'AllowCortana' `
        -Type 'DWord' `
        -Value 0 `
        -Desc 'Disables Cortana'


Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location' `
    -Name 'Value' `
    -Type 'String' `
    -Value 'Deny' `
    -Desc 'Location access control'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive' `
    -Name 'KFMBlockOptIn' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'OneDrive backup control'
    Set-RegistryValue -Path "$userHive\SOFTWARE\Policies\Microsoft\OneDrive" `
        -Name 'KFMBlockOptIn' `
        -Type 'DWord' `
        -Value 1 `
        -Desc 'Blocks OneDrive folder backup'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration" `
    -Name 'IsOneDriveResumeAllowed' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Blocks OneDrive from using Resume feature'


Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsCopilot' `
    -Name 'TurnOffWindowsCopilot' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Windows Copilot disable'
    Set-RegistryValue -Path "$userHive\Software\Policies\Microsoft\Windows\WindowsCopilot" `
        -Name 'TurnOffWindowsCopilot' `
        -Type 'DWord' `
        -Value 1 `
        -Desc 'Disables Windows Copilot'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' `
    -Name 'DisableAIDataAnalysis' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'AI data analysis control'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' `
    -Name 'AllowRecallEnablement' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Recall feature enablement'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' `
    -Name 'TurnOffSavingSnapshots' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Recall snapshot storage'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' `
    -Name 'DisableClickToDo' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Click to Do feature'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' `
    -Name 'DisableSettingsAgent' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Settings AI agent'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' `
    -Name 'DisableAgentConnectors' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'AI agent connectors'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' `
    -Name 'DisableAgentWorkspaces' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'AI workspaces'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' `
    -Name 'DisableRemoteAgentConnectors' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Remote AI connectors'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CopilotKey' `
    -Name 'SetCopilotHardwareKey' `
    -Type 'String' `
    -Value '' `
    -Desc 'Copilot hardware key mapping'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' `
    -Name 'AllowCopilotRuntime' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Copilot runtime control'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\Shell\Copilot" `
    -Name 'IsCopilotAvailable' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables Copilot in shell'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\Shell\Copilot\BingChat" `
    -Name 'IsUserEligible' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables Bing Chat eligibility'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\generativeAI' `
    -Name 'Value' `
    -Type 'String' `
    -Value 'Deny' `
    -Desc 'Generative AI access'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy' `
    -Name 'LetAppsAccessGenerativeAI' `
    -Type 'DWord' `
    -Value 2 `
    -Desc 'App generative AI access'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\systemAIModels' `
    -Name 'Value' `
    -Type 'String' `
    -Value 'Deny' `
    -Desc 'System AI models access'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy' `
    -Name 'LetAppsAccessSystemAIModels' `
    -Type 'DWord' `
    -Value 2 `
    -Desc 'App system AI model access'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\systemAIModels' `
    -Name 'RecordUsageData' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'AI usage data recording'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone\Microsoft.Copilot_8wekyb3d8bbwe" `
    -Name 'Value' `
    -Type 'String' `
    -Value 'Deny' `
    -Desc 'Blocks Copilot microphone access'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone\Microsoft.MicrosoftOfficeHub_8wekyb3d8bbwe" `
    -Name 'Value' `
    -Type 'String' `
    -Value 'Deny' `
    -Desc 'Blocks Office Hub microphone access'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Paint' `
    -Name 'DisableImageCreator' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Paint Image Creator'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Paint' `
    -Name 'DisableCocreator' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Paint Cocreator'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Paint' `
    -Name 'DisableGenerativeFill' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Paint Generative Fill'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Paint' `
    -Name 'DisableGenerativeErase' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Paint Generative Erase'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Paint' `
    -Name 'DisableRemoveBackground' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Paint Remove Background'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Input\Settings" `
    -Name 'InsightsEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables input insights'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name 'ShowCopilotNudges' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables Copilot nudges'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\CloudContent' `
    -Name 'DisableConsumerAccountStateContent' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Consumer content recommendations'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\CloudContent' `
    -Name 'DisableCloudOptimizedContent' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Remove new Outlook pinned from the taskbar'


Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge' `
    -Name 'CopilotCDPPageContext' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Edge Copilot page context CDP'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge' `
    -Name 'CopilotPageContext' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Edge Copilot page context'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge' `
    -Name 'HubsSidebarEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Edge Copilot Sidebar'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge' `
    -Name 'EdgeEntraCopilotPageContext' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Edge Entra Copilot context'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge' `
    -Name 'Microsoft365CopilotChatIconEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Edge M365 Copilot icon'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge' `
    -Name 'EdgeHistoryAISearchEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Edge AI history search'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge' `
    -Name 'ComposeInlineEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Edge AI compose'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge' `
    -Name 'GenAILocalFoundationalModelSettings' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Edge local AI models'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge' `
    -Name 'BuiltInAIAPIsEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Edge AI APIs'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge' `
    -Name 'AIGenThemesEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Edge AI themes'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge' `
    -Name 'DevToolsGenAiSettings' `
    -Type 'DWord' `
    -Value 2 `
    -Desc 'Edge DevTools AI'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge' `
    -Name 'ShareBrowsingHistoryWithCopilotSearchAllowed' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Edge Copilot history sharing'


Set-RegistryValue -Path "$userHive\Software\Policies\Microsoft\Office\16.0\Common\AI\Training" `
    -Name 'optionalconnectedexperiencesenabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables Office AI training data'
Set-RegistryValue -Path "$userHive\Software\Policies\Microsoft\Office\16.0\Common\Privacy" `
    -Name 'controllerconnectedservicesenabled' `
    -Type 'DWord' `
    -Value 2 `
    -Desc 'Controls Office connected experiences'
Set-RegistryValue -Path "$userHive\Software\Policies\Microsoft\Office\16.0\Common\Privacy" `
    -Name 'usercontentdisabled' `
    -Type 'DWord' `
    -Value 2 `
    -Desc 'Controls Office user content access'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Office\16.0\Word\Options" `
    -Name 'EnableCopilot' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables Word Copilot'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Office\16.0\Excel\Options" `
    -Name 'EnableCopilot' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables Excel Copilot'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Office\16.0\OneNote\Options\Other" `
    -Name 'EnableCopilot' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables OneNote Copilot'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Office\16.0\OneNote\Options\Other" `
    -Name 'EnableCopilotNotebooks' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables Copilot notebooks'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Office\16.0\OneNote\Options\Other" `
    -Name 'EnableCopilotSkittle' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables Copilot UI elements'
Set-RegistryValue -Path "$userHive\Software\Policies\Microsoft\Office\16.0\Common\AI" `
    -Name 'contentsafetyserviceenabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables Office AI content safety services'


# ============================================================================
# POWER SETTINGS
# ============================================================================
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Session Manager\Power' `
    -Name 'HiberbootEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Hibernate system state during shutdown for faster boot times (does not affect restart)'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings' `
    -Name 'ShowHibernateOption' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Display the Hibernate option in the Start Menu power button menu'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' `
    -Name 'PowerThrottlingOff' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Allow Windows to reduce CPU performance for background processes to save power'


# ============================================================================
# GAMING & PERFORMANCE SETTINGS
# ============================================================================
Set-RegistryValue -Path "$userHive\Control Panel\Mouse" `
    -Name 'MouseSpeed' `
    -Type 'String' `
    -Value '0' `
    -Desc 'Adjust cursor speed based on movement velocity (mouse acceleration). Most competitive gamers disable this for consistent aiming in FPS games'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy' `
    -Name 'LetAppsRunInBackground' `
    -Type 'DWord' `
    -Value 2 `
    -Desc 'Control whether apps can run in the background via Group Policy. Force Deny removes per-app background settings from Windows Settings. Use User in Control if you need apps like Teams, Zoom, or WhatsApp'
    Set-RegistryValue -Path "$userHive\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" `
        -Name 'LetAppsRunInBackground' `
        -Type 'DWord' `
        -Value 2 `
        -Desc 'Control whether apps can run in the background via Group Policy'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\8\1694661260' `
    -Name 'EnabledState' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Allow Windows Search to use WebView2 (Edge) for rendering search results. Disabling removes Edge processes spawned by SearchHost.exe, reducing resource usage. Uses an undocumented Windows Feature Management override (feature ID 37926450) that may change in future Windows updates'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\8\1694661260' `
    -Name 'EnabledStateOptions' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Allow Windows Search to use WebView2 (Edge) for rendering search results. Disabling removes Edge processes spawned by SearchHost.exe, reducing resource usage. Uses an undocumented Windows Feature Management override (feature ID 37926450) that may change in future Windows updates'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\8\1694661260' `
    -Name 'Variant' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Allow Windows Search to use WebView2 (Edge) for rendering search results. Disabling removes Edge processes spawned by SearchHost.exe, reducing resource usage. Uses an undocumented Windows Feature Management override (feature ID 37926450) that may change in future Windows updates'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\8\1694661260' `
    -Name 'VariantPayload' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Allow Windows Search to use WebView2 (Edge) for rendering search results. Disabling removes Edge processes spawned by SearchHost.exe, reducing resource usage. Uses an undocumented Windows Feature Management override (feature ID 37926450) that may change in future Windows updates'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\8\1694661260' `
    -Name 'VariantPayloadKind' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Allow Windows Search to use WebView2 (Edge) for rendering search results. Disabling removes Edge processes spawned by SearchHost.exe, reducing resource usage. Uses an undocumented Windows Feature Management override (feature ID 37926450) that may change in future Windows updates'
Set-RegistryValue -Path "$userHive\Control Panel\Desktop" `
    -Name 'JPEGImportQuality' `
    -Type 'DWord' `
    -Value 100 `
    -Desc 'JPEG wallpaper quality setting'
Set-RegistryValue -Path "$userHive\Control Panel\Desktop" `
    -Name 'MenuShowDelay' `
    -Type 'String' `
    -Value '0' `
    -Desc 'Menu display delay (0 = instant)'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name 'MultiTaskingAltTabFilter' `
    -Type 'DWord' `
    -Value 3 `
    -Desc 'Show only traditional open windows in Alt+Tab instead of including Microsoft Edge and other Windows suggestions'

Set-RegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' `
  -Name 'Win32PrioritySeparation' `
  -Type 'DWord' `
  -Value 38
  -Desc 'Adjust processor for best performance of programs or background services'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' `
    -Name 'SystemResponsiveness' `
    -Type 'DWord' `
    -Value 10 `
    -Desc 'Minimize background task interference by allocating more CPU time to active applications'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' `
    -Name 'Priority' `
    -Type 'DWord' `
    -Value 6 `
    -Desc 'Give games higher CPU scheduling priority'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' `
    -Name 'Scheduling Category' `
    -Type 'String' `
    -Value 'High' `
    -Desc 'Assign high-priority scheduling category for games'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control' `
    -Name 'SvcHostSplitThresholdInKB' `
    -Type 'DWord' `
    -Value $totalRAMinKB `
    -Desc 'Lower process count by limiting amount of svchostsplit processes'


Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' `
    -Name 'GPU Priority' `
    -Type 'DWord' `
    -Value 8 `
    -Desc 'Give games higher GPU scheduling priority'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\GraphicsDrivers' `
    -Name 'HwSchMode' `
    -Type 'DWord' `
    -Value 2 `
    -Desc 'Hardware-Accelerated GPU Scheduling'
Set-RegistryValue -Path "$userHive\Software\Microsoft\DirectX\UserGpuPreferences" `
    -Name 'DirectXUserGlobalSettings' `
    -Type 'String' `
    -Value 'VRROptimizeEnable=1;AutoHDREnable=1;' `
    -Desc 'Auto HDR'


Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard' `
    -Name 'EnableVirtualizationBasedSecurity' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Virtualization Based Security (VBS)'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' `
    -Name 'Enabled' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Memory integrity enable state'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' `
    -Name 'WasEnabledBy' `
    -Type 'DWord' `
    -Value 2 `
    -Desc 'Notify Memory Integrity was turned on by the user, not set as an administrative policy'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\KernelShadowStacks' `
    -Name 'Enabled' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Kerne-mode Hardware-enforced Stack Protection enable state'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WTDS\Components' `
    -Name 'CaptureThreatWindow' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disable automatically collect data from phishing protection'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender' `
    -Name 'PUAProtection' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Enable Potentially Unwanted App Blocking'


Set-RegistryValue -Path "$userHive\System\GameConfigStore" `
    -Name 'GameDVR_Enabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Record gameplay clips and screenshots via Xbox Game Bar'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\GameDVR" `
    -Name 'AppCaptureEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Record gameplay clips and screenshots via Xbox Game Bar'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\GameDVR' `
    -Name 'AllowGameDVR' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Xbox Game Bar recording'
Set-RegistryValue -Path "$userHive\Software\Microsoft\GameBar" `
    -Name 'UseNexusForGameBarEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disable Xbox controller Game Bar shortcut'
Set-RegistryValue -Path "$userHive\Software\Microsoft\GameBar" `
    -Name 'ShowStartupPanel' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disable Game Bar startup tips'


Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control' `
    -Name 'ServicesPipeTimeout' `
    -Type 'DWord' `
    -Value 30000 `
    -Desc 'Service startup timeout'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' `
    -Name 'EnablePrefetcher' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Prefetch behavior'
Set-RegistryValue -Path "$userHive\Software\Microsoft\input" `
    -Name 'IsInputAppPreloadEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables input experience features (touch keyboard, emoji, handwriting, etc.)'


Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" `
    -Name 'VisualFXSetting' `
    -Type 'DWord' `
    -Value 3 `
    -Desc 'Visual effects configuration'


Set-RegistryValue -Path "$userHive\Software\Microsoft\Narrator\NoRoam" `
    -Name 'WinEnterLaunchEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Narrator shortcut'
Set-RegistryValue -Path "$userHive\Control Panel\Accessibility\StickyKeys" `
    -Name 'Flags' `
    -Type 'String' `
    -Value 2 `
    -Desc 'StickyKeys shortcut'
Set-RegistryValue -Path "$userHive\Control Panel\Accessibility\Keyboard Response" `
    -Name 'Flags' `
    -Type 'String' `
    -Value 2 `
    -Desc 'FilterKeys shortcut'
Set-RegistryValue -Path "$userHive\Control Panel\Accessibility\ToggleKeys" `
    -Name 'Flags' `
    -Type 'String' `
    -Value 34 `
    -Desc 'ToggleKeys shortcut'
Set-RegistryValue -Path "$userHive\Control Panel\Accessibility\MouseKeys" `
    -Name 'Flags' `
    -Type 'String' `
    -Value 130 `
    -Desc 'MouseKeys shortcut'


# ============================================================================
# WINDOWS UPDATE SETTINGS
# ============================================================================
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' `
    -Name 'NoAutoUpdate' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Controls Windows Update automatic installation behavior'
    Set-RegistryValue -Path "$userHive\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" `
        -Name 'NoAutoUpdate' `
        -Type 'DWord' `
        -Value 1 `
        -Desc 'Controls Windows Update automatic behavior for user scope'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' `
    -Name 'PauseUpdatesStartTime' `
    -Type 'String' `
    -Value '2025-01-01T00:00:00Z' `
    -Desc 'General update pause start time'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' `
    -Name 'PauseUpdatesExpiryTime' `
    -Type 'String' `
    -Value '2051-12-31T00:00:00Z' `
    -Desc 'General update pause expiry time'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' `
    -Name 'FlightSettingsMaxPauseDays' `
    -Type 'DWord' `
    -Value 10023 `
    -Desc 'Maximum update pause duration setting'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' `
    -Name 'PausedFeatureStatus' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Feature update pause status'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' `
    -Name 'PauseFeatureUpdatesStartTime' `
    -Type 'String' `
    -Value '2025-01-01T00:00:00Z' `
    -Desc 'Feature update pause start time'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' `
    -Name 'PauseFeatureUpdatesEndTime' `
    -Type 'String' `
    -Value '2051-12-31T00:00:00Z' `
    -Desc 'Feature update pause end time'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' `
    -Name 'PausedFeatureDate' `
    -Type 'String' `
    -Value '2025-01-01T00:00:00Z' `
    -Desc 'Feature update pause date'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' `
    -Name 'PausedQualityStatus' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Quality update pause status'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' `
    -Name 'PauseQualityUpdatesStartTime' `
    -Type 'String' `
    -Value '2025-01-01T00:00:00Z' `
    -Desc 'Quality update pause start time'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' `
    -Name 'PauseQualityUpdatesEndTime' `
    -Type 'String' `
    -Value '2051-12-31T00:00:00Z' `
    -Desc 'Quality update pause end time'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' `
    -Name 'PausedQualityDate' `
    -Type 'String' `
    -Value '2025-01-01T00:00:00Z' `
    -Desc 'Quality update pause date'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' `
    -Name 'AUOptions' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Controls Windows Update notification and install mode'
    Set-RegistryValue -Path "$userHive\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" `
        -Name 'AUOptions' `
        -Type 'DWord' `
        -Value 1 `
        -Desc 'Controls Windows Update install mode for user scope'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' `
    -Name 'NoAUShutdownOption' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Controls shutdown option availability during updates'
    Set-RegistryValue -Path "$userHive\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" `
        -Name 'NoAUShutdownOption' `
        -Type 'DWord' `
        -Value 1 `
        -Desc 'Controls shutdown option during updates'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' `
    -Name 'AlwaysAutoRebootAtScheduledTime' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Controls automatic reboot scheduling behavior'
    Set-RegistryValue -Path "$userHive\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" `
        -Name 'AlwaysAutoRebootAtScheduledTime' `
        -Type 'DWord' `
        -Value 0 `
        -Desc 'Controls automatic reboot behavior'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' `
    -Name 'AutoInstallMinorUpdates' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Controls automatic installation of minor updates'
    Set-RegistryValue -Path "$userHive\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" `
        -Name 'AutoInstallMinorUpdates' `
        -Type 'DWord' `
        -Value 0 `
        -Desc 'Controls minor update auto-installation'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' `
    -Name 'UseWUServer' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Controls WSUS server usage for updates'
    Set-RegistryValue -Path "$userHive\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" `
        -Name 'UseWUServer' `
        -Type 'DWord' `
        -Value 0 `
        -Desc 'Controls WSUS usage'
        

Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' `
    -Name 'DODownloadMode' `
    -Type 'DWord' `
    -Value 99 `
    -Desc 'Delivery Optimization peer-to-peer download mode'
    Set-RegistryValue -Path "$userHive\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" `
        -Name 'DODownloadMode' `
        -Type 'DWord' `
        -Value 99 `
        -Desc 'Controls Delivery Optimization peer-to-peer update sharing'


Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' `
    -Name 'IsContinuousInnovationOptedIn' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Controls early access to non-security updates'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\WindowsUpdate\UX\Settings' `
    -Name 'IsExpedited' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Controls expedited restart behavior'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' `
    -Name 'NoAutoRebootWithLoggedOnUsers' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Prevents automatic restart while users are logged in'
    Set-RegistryValue -Path "$userHive\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" `
        -Name 'NoAutoRebootWithLoggedOnUsers' `
        -Type 'DWord' `
        -Value 1 `
        -Desc 'Prevents reboot while user is logged in'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' `
    -Name 'AllowAutoWindowsUpdateDownloadOverMeteredNetwork' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Controls updates over metered connections'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\WindowsUpdate\UX\Settings' `
    -Name 'ExcludeWUDriversInQualityUpdate' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Excludes drivers from quality updates'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' `
    -Name 'ExcludeWUDriversInQualityUpdate' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Controls inclusion of driver updates in Windows Update'
    Set-RegistryValue -Path "$userHive\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" `
        -Name 'ExcludeWUDriversInQualityUpdate' `
        -Type 'DWord' `
        -Value 1 `
        -Desc 'Controls driver inclusion in Windows Update'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Device Metadata' `
    -Name 'PreventDeviceMetadataFromNetwork' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Prevents device metadata download'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Device Metadata' `
    -Name 'PreventDeviceMetadataFromNetwork' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Policy-level metadata blocking'
Set-RegistryValue -Path "$userHive\Software\Policies\Microsoft\Windows\DriverSearching" `
    -Name 'DontSearchWindowsUpdate' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Prevents Windows Update from searching drivers'
Set-RegistryValue -Path "$userHive\Software\Policies\Microsoft\Windows\DriverSearching" `
    -Name 'DriverUpdateWizardWuSearchEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables driver update wizard search'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\DriverSearching' `
    -Name 'SearchOrderConfig' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disables Windows Update driver search order'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\DriverSearching' `
    -Name 'DontPromptForWindowsUpdate' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'System-wide suppression of driver prompts'
    Set-RegistryValue -Path "$userHive\Software\Policies\Microsoft\Windows\DriverSearching" `
        -Name 'DontPromptForWindowsUpdate' `
        -Type 'DWord' `
        -Value 1 `
        -Desc 'Stops driver update prompts'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Installer' `
    -Name 'DisableCoInstallers' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Prevents vendor-installed software during driver installation'


# ============================================================================
# NOTIFICATIONS SETTINGS
# ============================================================================
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" `
    -Name 'NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disable lock screen toast notifications'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\PushNotifications" `
    -Name 'LockScreenToastEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disable lock screen toast notifications'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" `
    -Name 'NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disable critical notifications on lock screen'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name 'ShowNotificationIcon' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Hide notification icon in system tray'


Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name 'SubscribedContent-310093Enabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disable "Whats new" suggestions after updates'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" `
    -Name 'ScoobeSystemSettingEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disable Windows setup suggestions'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name 'SubscribedContent-338389Enabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disable Windows tips and suggestions'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name 'SystemPaneSuggestionsEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disable Action Center suggestions'


Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.CapabilityAccess" `
    -Name 'Enabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disable capability access notifications'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.StartupApp" `
    -Name 'Enabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disable startup app notifications'
Set-RegistryValue -Path "$userHive\Control Panel\Desktop" `
    -Name 'DstNotification' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disable daylight saving time notifications'


Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" `
    -Name 'ShowGlobalPrompts' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Disable location access prompts'


# ============================================================================
# SOUND SETTINGS
# ============================================================================
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation' `
    -Name 'DisableStartupSound' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Controls Windows startup sound behavior during boot'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\EditionOverrides' `
    -Name 'UserSetting_DisableStartupSound' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Overrides user setting for Windows startup sound'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Multimedia\Audio" `
    -Name 'UserDuckingPreference' `
    -Type 'DWord' `
    -Value 3 `
    -Desc 'Controls automatic audio ducking during communication activity'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Narrator\NoRoam" `
    -Name 'DuckAudio' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Controls whether Narrator reduces system audio volume while speaking'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\SpeechOneCore\Settings' `
    -Name 'AgentActivationEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Controls voice activation features such as "Hey Cortana"'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\SpeechOneCore\Settings' `
    -Name 'AgentActivationLastUsed' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Stores last used voice activation configuration state'
Set-RegistryValue -Path "$userHive\Control Panel\Accessibility" `
    -Name 'Sound on Activation' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Controls sounds when accessibility features are activated'
Set-RegistryValue -Path "$userHive\Control Panel\Accessibility" `
    -Name 'Warning Sounds' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Controls warning sounds for accessibility events'


# ============================================================================
# WINDOWS THEME
# ============================================================================
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
    -Name 'EnableTransparency' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Enable translucent effects for the Start Menu, taskbar, and other Windows interface elements'


# ============================================================================
# TASKBAR SETTINGS
# ============================================================================
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name 'TaskbarCompanion' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Show or hide Copilot companion button on the taskbar'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name 'CopilotPWAPin' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Show or hide Copilot PWA pin on the taskbar'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name 'RecallPin' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Show or hide Recall pin on the taskbar'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Dsh' `
    -Name 'AllowNewsAndInterests' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Show the Widgets button that displays personalized news, weather, calendar, and other information'
Set-RegistryValue -Path "$userHive\Software\Policies\Microsoft\Dsh" `
    -Name 'AllowNewsAndInterests' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Show Widgets button with personalized news, weather, calendar, and other content'


Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name 'ExtendedUIHoverTime' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Controls delay before auto-hidden taskbar appears when hovering (milliseconds). Lower values make it appear faster'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" `
    -Name 'TaskbarEndTask' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Adds End Task option to taskbar right-click menu for quickly terminating apps'


# ============================================================================
# START MENU SETTINGS
# ============================================================================
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Explorer' `
    -Name 'ConfigureStartPins' `
    -Type 'String' `
    -Value '{"pinnedList":[]}' `
    -Desc 'Clean Start Menu'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Start" `
    -Name 'ShowFrequentList' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Display your frequently launched applications at the top of the All Apps list for quick access'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name 'Start_TrackDocs' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Display recently opened documents and files in Start Menu SvcHostSplitThresholdInKB section for quick access'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name 'Start_IrisRecommendations' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Display personalized Windows suggestions such as tips, shortcuts, and Microsoft Store app recommendations in SvcHostSplitThresholdInKB section'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name 'Start_AccountNotifications' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Display Microsoft account notifications including sign-in prompts, sync status, and account suggestions'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Explorer' `
    -Name 'DisableSearchBoxSuggestions' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Show web results from Bing alonghivee local files and apps when searching in the Start Menu'
    Set-RegistryValue -Path "$userHive\Software\Policies\Microsoft\Windows\Explorer" `
        -Name 'DisableSearchBoxSuggestions' `
        -Type 'DWord' `
        -Value 1 `
        -Desc 'Show web results from Bing alonghivee local files and apps when searching in the Start Menu'
Set-RegistryValue -Path "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Search" `
    -Name 'BingSearchEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Show web results from Bing alongside local files and apps when searching in the Start Menu'


# ============================================================================
# EXPLORER SETTINGS
# ============================================================================
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons' `
    -Name '29' `
    -Type 'String' `
    -Value 'C:\Windows\blank.ico' `
    -Desc 'Controls the small arrow overlay on desktop shortcut icons' 


Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked' `
    -Name '{9F156763-7844-4DC4-B2B1-901F640F5155}' `
    -Type 'String' `
    -Value '' `
    -Desc 'Displays the Windows Terminal option when right-clicking folders and backgrounds in File Explorer'
Set-RegistryValue -Path 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\Edit-Run-with' `
    -Name 'MUIVerb' `
    -Type 'String' `
    -Value 'Run with powershell' `
    -Desc 'Adds a right-click cascading menu to .ps1 files with options to run or edit with PowerShell, PowerShell 7, PowerShell ISE, and Notepad (including as administrator). PowerShell 7 must be installed separately for the PowerShell 7 options to work'
Set-RegistryValue -Path 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\Edit-Run-with' `
    -Name 'SubCommands' `
    -Type 'String' `
    -Value '' `
    -Desc 'Initialize submenu container for PowerShell actions'
Set-RegistryValue -Path 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\Edit-Run-with\shell\001flyout' `
    -Name 'MUIVerb' `
    -Type 'String' `
    -Value 'PowerShell (User)' `
    -Desc 'Adds Run with PowerShell option to .ps1 context menu'
Set-RegistryValue -Path 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\Edit-Run-with\shell\001flyout' `
    -Name 'Icon' `
    -Type 'String' `
    -Value 'powershell.exe' `
    -Desc 'Sets PowerShell icon for Run with PowerShell option'
Set-RegistryValue -Path 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\Edit-Run-with\shell\001flyout\Command' `
    -Name '(default)' `
    -Type 'String' `
    -Value '"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" "-Command" "if((Get-ExecutionPolicy) -ne ''AllSigned'') { Set-ExecutionPolicy -Scope Process Bypass }; & ''%1''"' `
    -Desc 'Executes .ps1 file with PowerShell while temporarily bypassing execution policy'
Set-RegistryValue -Path 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\Edit-Run-with\shell\002flyout' `
    -Name 'MUIVerb' `
    -Type 'String' `
    -Value 'PowerShell (Administrator)' `
    -Desc 'Run PS1 elevated'
Set-RegistryValue -Path 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\Edit-Run-with\shell\002flyout' `
    -Name 'HasLUAShield' `
    -Type 'String' `
    -Value '' `
    -Desc 'Show admin shield icon'
Set-RegistryValue -Path 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\Edit-Run-with\shell\002flyout' `
    -Name 'Icon' `
    -Type 'String' `
    -Value 'powershell.exe' `
    -Desc 'PowerShell icon'
Set-RegistryValue -Path 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\Edit-Run-with\shell\002flyout\Command' `
    -Name '(default)' `
    -Type 'String' `
    -Value '"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Command "& {Start-Process PowerShell.exe -ArgumentList ''-ExecutionPolicy RemoteSigned -File \"%1\"'' -Verb RunAs}"' `
    -Desc 'Run as admin with PowerShell'
Set-RegistryValue -Path 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\Edit-Run-with\shell\003flyout' `
    -Name 'MUIVerb' `
    -Type 'String' `
    -Value 'PowerShell 7 (User)' `
    -Desc 'Run PS1 with PowerShell 7'
Set-RegistryValue -Path 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\Edit-Run-with\shell\003flyout' `
    -Name 'Icon' `
    -Type 'String' `
    -Value 'pwsh.exe' `
    -Desc 'PowerShell 7 icon'
Set-RegistryValue -Path 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\Edit-Run-with\shell\003flyout\Command' `
    -Name '(default)' `
    -Type 'String' `
    -Value '"C:\Program Files\PowerShell\7\pwsh.exe" "-Command" "if((Get-ExecutionPolicy) -ne ''AllSigned'') { Set-ExecutionPolicy -Scope Process Bypass }; & ''%1''"' `
    -Desc 'Run script with PowerShell 7'
Set-RegistryValue -Path 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\Edit-Run-with\shell\004flyout' `
    -Name 'MUIVerb' `
    -Type 'String' `
    -Value 'PowerShell 7 (Administrator)' `
    -Desc 'Run PS1 elevated with PS7'
Set-RegistryValue -Path 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\Edit-Run-with\shell\004flyout' `
    -Name 'HasLUAShield' `
    -Type 'String' `
    -Value '' `
    -Desc 'Admin shield icon'
Set-RegistryValue -Path 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\Edit-Run-with\shell\004flyout' `
    -Name 'Icon' `
    -Type 'String' `
    -Value 'pwsh.exe' `
    -Desc 'PowerShell 7 icon'
Set-RegistryValue -Path 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\Edit-Run-with\shell\004flyout\Command' `
    -Name '(default)' `
    -Type 'String' `
    -Value '"C:\Program Files\PowerShell\7\pwsh.exe" -Command "& {Start-Process pwsh.exe -ArgumentList ''-ExecutionPolicy RemoteSigned -File \"%1\"'' -Verb RunAs}"' `
    -Desc 'Run as admin with PowerShell 7'
Remove-RegistryKey -Path 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\Windows.PowerShell.Run' `
    -Desc 'Remove default run with powershell'


Set-RegistryValue -Path "$userHive\Software\Microsoft\Lighting" `
    -Name 'AmbientLightingEnabled' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Allow Windows Dynamic Lighting to control ambient RGB effects on compatible devices'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Lighting" `
    -Name 'ControlledByForegroundApp' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Allow compatible apps to control device lighting effects'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows NT\CurrentVersion\Windows" `
    -Name 'LegacyDefaultPrinterMode' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Let Windows automatically set your default printer based on your location or last used printer'
Set-RegistryValue -Path "$userHive\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" `
    -Name 'DisableAutoplay' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Autoplay which sends a dialog what to do from USB when connected.' 
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' `
    -Name 'NoDriveTypeAutoRun' `
    -Type 'DWord' `
    -Value 255 `
    -Desc 'AutoRun files without notice from USB when connected.' 


Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name 'LaunchTo' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Choose what happens when File Explorer is opened'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer" `
    -Name 'ShowRecent' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Displays recently accessed files and recommendations in Quick Access'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer" `
    -Name 'ShowRecommendations' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Displays recently accessed files and recommendations in Quick Access'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer" `
    -Name 'ShowFrequent' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Displays your most accessed folders in Quick Access section'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer" `
    -Name 'ShowCloudFilesInQuickAccess' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Displays cloud files from your Office.com account in Quick Access'


Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" `
    -Name 'FullPath' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Allow Windows Dynamic Lighting to control ambient RGB effects on compatible devices'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name 'ShowTypeOverlay' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Shows file type icon overlay on bottom-right corner of thumbnail previews'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name 'Hidden' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Displays items with the hidden attribute set'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name 'HideFileExt' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Displays file type extensions (like .txt, .pdf) after file names'
Remove-RegistryValue -Path 'Registry::HKEY_CLASSES_ROOT\lnkfile' `
    -Name 'NeverShowExt' `
    -Desc 'Shows the .lnk extension on shortcut files when file extensions are enabled. Helps spot malicious shortcuts disguised as folders or documents.'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name 'HideMergeConflicts' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Automatically merges folders with same name without confirmation dialog'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name 'ShowEncryptCompressedColor' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Show encrypted or compressed NTFS files in color'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name 'ShowPreviewHandlers' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Enables file content preview when selecting files in Explorer'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name 'ShowSyncProviderNotifications' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Displays cloud sync status notifications from OneDrive and other sync providers'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name 'SharingWizardOn' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Shows simplified sharing dialog instead of advanced security permissions'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem' `
    -Name 'LongPathsEnabled' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Enables support for file paths with up to 32,767 characters instead of the traditional 260-character limit'


Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Applications\notepad.exe' `
    -Name 'NoOpenWith' `
    -Type 'String' `
    -Value '' `
    -Desc 'Open text files with no notepad.exe'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe' `
    -Name 'UseFilter' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Filter notepad.exe out from txt files'


Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\NonEnum' `
    -Name '{f874310e-b6b7-47dc-bc84-b9e6b38f5903}' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Show Home folder'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}' `
    -Name 'HiddenByDefault' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Show Home folder'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\NonEnum' `
    -Name '{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Show Gallery folder'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}' `
    -Name 'HiddenByDefault' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Show Gallery folder'
Set-RegistryValue -Path "$userHive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name 'NavPaneExpandToCurrentFolder' `
    -Type 'DWord' `
    -Value 0 `
    -Desc 'Automatically expands navigation tree to highlight current folder location'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\NonEnum' `
    -Name '{031E4825-7B94-4dc3-B131-E946B44C8DD5}' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Pins the Libraries folder as a top-level item in the navigation pane. Has no effect when Show All Folders is enabled, as Libraries becomes part of the folder tree instead'
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{031E4825-7B94-4dc3-B131-E946B44C8DD5}' `
    -Name 'HiddenByDefault' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Pins the Libraries folder as a top-level item in the navigation pane. Has no effect when Show All Folders is enabled, as Libraries becomes part of the folder tree instead'
Remove-RegistryKey -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}' `
  -Desc 'Show removable drives as separate entries in the navigation pane in addition to under This PC'
Remove-RegistryKey -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}' `
  -Desc 'Show removable drives as separate entries in the navigation pane in addition to under This PC'


# ============================================================================
# CUSTOM
# ============================================================================
Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' `
    -Name 'VerboseStatus' `
    -Type 'DWord' `
    -Value 1 `
    -Desc 'Enables verbose startup/shutdown status messages'
Set-RegistryValue -Path "$userHive\Control Panel\Keyboard" `
    -Name 'InitialKeyboardIndicators' `
    -Type 'String' `
    -Value 2 `
    -Desc 'Enabled numpad by default after a warm boot (restart)'
Set-RegistryValue -Path "Registry::HKEY_USERS\.DEFAULT\Control Panel\Keyboard" `
    -Name 'InitialKeyboardIndicators' `
    -Type 'String' `
    -Value 2 `
    -Desc 'Enabled numpad by default after a cold boot (shutdown)'
$services = @(
    'DisplayEnhancementService'
    'PcaSvc'
    'WdiSystemHost'
    'AudioEndpointBuilder'
    'DeviceAssociationService'
    'NcbService'
    'StorSvc'
    'SysMain'
    'TextInputManagementService'
    'TrkWks'
    'hidserv'
    'Appinfo'
    'BITS'
    'LanmanServer'
    'SENS'
    'Schedule'
    'ShellHWDetection'
    'Themes'
    'TokenBroker'
    'UserManager'
    'UsoSvc'
    'Winmgmt'
    'WpnService'
    'gpsvc'
    'iphlpsvc'
    'wuauserv'
    'WinHttpAutoProxySvc'
    'EventLog'
    'TimeBrokerSvc'
    'lmhosts'
    'Dhcp'
    'FontCache'
    'nsi'
    'netprofm'
    'SstpSvc'
    'DispBrokerDesktopSvc'
    'CDPSvc'
    'EventSystem'
    'LicenseManager'
    'SystemEventsBroker'
    'Power'
    'LSM'
    'DcomLaunch'
    'BrokerInfrastructure'
    'CoreMessagingRegistrar'
    'DPS'
    'NcdAutoSetup'
    'AppXSvc'
    'ClipSVC'
    'camsvc'
    'StateRepository'
    'FDResPub'
    'SSDPSRV'
    'CryptSvc'
    'Dnscache'
    'NlaSvc'
    'LanmanWorkstation'
    'KeyIso'
    'VaultSvc'
    'SamSs'
)
foreach ($name in $services) {
    $serviceExists = Get-Service -Name $name
    if ($serviceExists) {
        Set-RegistryValue -Path "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\$name" `
            -Name 'SvcHostSplitDisable' `
            -Type 'DWord' `
            -Value 1 `
            -Desc "Disable SvcHost split for $name"
    }
    else {
        Write-Log "$name service does not exist." 'ERROR'
    }
}