Import-Module "$PSScriptRoot\Module.psm1"
if (-not (Initialize-RuntimeDefaults)) { 
    return 
}
# ============================================================================
# MAIN FUNCTION
# ============================================================================
function Set-GenericKey {
    param(
        [Parameter(Mandatory)]
        [string]$License
    )
    try {
        $service = Get-CimInstance -ClassName SoftwareLicensingService
        Invoke-CimMethod -InputObject $service `
            -MethodName InstallProductKey `
            -Arguments @{ ProductKey = $License } `
            -ErrorAction Stop | Out-Null
        Write-Log "Successfully apply key $License"
    }
    catch {
        Write-Log "Failed to apply product key because $($_.Exception.Message)" 'ERROR'
    }
}
# ============================================================================
# EXECUTION
# ============================================================================
Set-GenericKey -License 'DXG7C-N36C4-C4HTG-X4T3X-2YV77'