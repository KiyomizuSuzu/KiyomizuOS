Import-Module "$PSScriptRoot\Module.psm1"
Initialize-RuntimeDefaults
# ============================================================================
# CONFIGURATION
# ============================================================================
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
if ($LocalAccounts.Count -eq 0) {
    Write-Log "No Local Account was made yet."
}
else {
    Write-Log "Found $($LocalAccount.Name -join ', ')" 'WARN'
    $lightTheme = ((Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\AME').UseLightTheme -eq 1) ? 1 : 0
    foreach ($account in $LocalAccounts) {
        $sid = $account.SID.Value
        Set-RegistryValue -Path "Registry::HKEY_USERS\$sid\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
            -Name 'AppsUseLightTheme' `
            -Type 'DWord' `
            -Value $lightTheme `
            -Desc 'App theme mode'
        Set-RegistryValue -Path "Registry::HKEY_USERS\$sid\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
            -Name 'SystemUsesLightTheme' `
            -Type 'DWord' `
            -Value $lightTheme `
            -Desc 'System theme mode'
    }
    Set-registryValue -path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' `
        -Name 'EnableFirstLogonAnimation' `
        -Type: 'DWord' `
        -Value: 0 `
        -Desc 'Remove the animation setting up new user'
    Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' `
        -Name 'Shell' `
        -Type 'String' `
        -Value 'explorer.exe' `
        -Desc 'Set explorer.exe as shell'
    Remove-RegistryKey -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\ameoobe' `
        -Desc 'Remove ameoobe service'
    Restart-Computer -Force
}