param([ValidateSet('Startup', 'OOBE')][string]$Mode)
Import-Module "$PSScriptRoot\Module.psm1"
Initialize-RuntimeDefaults
# ============================================================================
# CONFIGURATION
# ============================================================================
$UpgradeKey = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\Setup\Upgrade'
$LocalAccounts = (Get-LocalUser).Where({
                $_.Name -notin @(
                    'Administrator',
                    'DefaultAccount',
                    'Guest',
                    'WDAGUtilityAccount',
                    'defaultuser0'
                )
            })
# ============================================================================
# EXECUTION
# ============================================================================
switch ($Mode) {
    'Startup' {
        $UpgradeKeyExists = Test-Path -Path $UpgradeKey
        $winLogonPath = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
        $currentShell = (Get-ItemProperty -Path $winLogonPath -Name 'Shell').Shell
        if ($UpgradeKeyExists) {
            $service = Get-Service 'ameoobe'
            if ($service.Status -ne 'Running') {
                Start-Service $service
            }
            $lightTheme = ((Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\AME').UseLightTheme -eq 1) ? 1 : 0
            Set-RegistryValue -Path "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
                -Name 'AppsUseLightTheme' `
                -Type 'DWord' `
                -Value $lightTheme `
                -Desc 'App theme mode'
            Set-RegistryValue -Path "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
                -Name 'SystemUsesLightTheme' `
                -Type 'DWord' `
                -Value $lightTheme `
                -Desc 'System theme mode'
        }
        elseif ($currentShell -ne 'explorer.exe') {
            Write-Log "InPlaceUpgrade detected! Restoring explorer.exe for you..."
            Set-RegistryValue -Path $path `
                -Name 'Shell' `
                -Type 'String' `
                -Value 'explorer.exe' `
                -Desc 'Set explorer.exe as shell'
            Start-Process explorer.exe
        }
    }
    'OOBE' {
        if ($LocalAccounts.Count -eq 0) {
            Write-Log "No Local Account was made yet."
            Register-ScheduledTask -TaskName "AME Upgrade" `
                -Action (New-ScheduledTaskAction -Execute "C:\Program Files\PowerShell\7\pwsh.exe" `
                -Argument '-NoProfile -ExecutionPolicy Bypass -File "C:\ProgramData\AME\ActiveSetup\InplaceUpgrade.ps1" -Mode Startup') `
                -Trigger (New-ScheduledTaskTrigger -AtLogOn) `
                -Principal (New-ScheduledTaskPrincipal -GroupId "S-1-5-4" -RunLevel Highest) `
                -Settings (New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries)
        }
        else {
            Write-Log "Found $($LocalAccounts.Name -join ', ')" 'WARN'
            Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' `
                -Name 'EnableFirstLogonAnimation' `
                -Type 'DWord' `
                -Value 0 `
                -Desc 'Remove the animation setting up new user'
            Remove-RegistryKey -Path $UpgradeKey `
                -Desc 'Reset upgrade state'
        }
    }
}