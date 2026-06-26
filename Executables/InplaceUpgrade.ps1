Import-Module "$PSScriptRoot\Module.psm1"
Initialize-RuntimeDefaults
# ============================================================================
# CONFIGURATION
# ============================================================================
$LocalAccount = (Get-LocalUser).Where({
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
if ($LocalAccount.Count -eq 0) {
    Write-Log "No Local Account was made yet."
}
else {
    Write-Log "Found $($LocalAccount -join ', ')" 'WARN'
    $lightTheme = ((Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\AME').UseLightTheme -eq 1) ? 1 : 0
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
    Set-RegistryValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' `
        -Name 'Shell' `
        -Type 'String' `
        -Value 'explorer.exe' `
        -Desc 'Set explorer.exe as shell'
    Remove-RegistryKey -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\ameoobe' `
        -Desc 'Remove ameoobe service'
    Restart-Computer -Force
}