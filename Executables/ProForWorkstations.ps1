# ============================================================================
# RUNTIME DEFAULTS
# ============================================================================
if ($PSVersionTable.PSEdition -ne "Core") {
    throw "Please use Powershell 7+ because it's simply better."
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