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
function Disable-ScheduledTasks {
    param (
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [string]$Path,
        [string]$Desc #not required
    )
    $taskPath = "$Path\"
    try {
        $findTask = Get-ScheduledTask -TaskPath $taskPath `
                        -TaskName $Name
        Disable-ScheduledTask -InputObject $findTask `
            -ErrorAction Stop | Out-Null
        Write-Log "Successfully disabled $Name task"
    }
    catch {
        Write-Log "Failed to disable $Name task because $($_.Exception.Message)" 'ERROR'
    }
}
# ============================================================================
# DATA
# ============================================================================
$tasksToDisable = @(
    @{  Path='\Microsoft\Windows\Application Experience'
        Name='Microsoft Compatibility Appraiser Exp'
        Desc='Compatibility telemetry'
    },
    @{
        Path = "\Microsoft\Windows\Application Experience"
        Name = "MareBackup"
        Desc = "Recovery backup"
    },
    @{  Path='\Microsoft\Windows\Application Experience'
        Name='StartupAppTask'
        Desc='Startup tracking'
    },
    @{  Path='\Microsoft\Windows\Maps'
        Name='MapsUpdateTask'
        Desc='Updates offline maps data'
    },
    @{
        Path='\Microsoft\Windows\Autochk'
        Name='Proxy'
        Desc='Disk check task'
    },
    @{
        Path='\Microsoft\Windows\Customer Experience Improvement Program'
        Name='Consolidator'
        Desc='CEIP data upload'
    },
    @{
        Path='\Microsoft\Windows\Customer Experience Improvement Program'
        Name='UsbCeip'
        Desc='USB telemetry'
    },
    @{
        Path='\Microsoft\Windows\DiskDiagnostic'
        Name='Microsoft-Windows-DiskDiagnosticDataCollector'
        Desc='Disk diagnostics'
    },
    @{
        Path='\Microsoft\Windows\Feedback\Siuf'
        Name='DmClient'
        Desc='Feedback collection'
    },
    @{
        Path='\Microsoft\Windows\Feedback\Siuf'
        Name='DmClientOnScenarioDownload'
        Desc='Feedback scenarios'
    },
    @{
        Path='\Microsoft\Windows\PI'
        Name='Sqm-Tasks'
        Desc='Usage metrics'
    },
    @{
        Path='\Microsoft\Windows\Power Efficiency Diagnostics'
        Name='AnalyzeSystem'
        Desc='Power diagnostics'
    },
    @{
        Path='\Microsoft\Windows\Shell'
        Name='FamilySafetyMonitor'
        Desc='Family safety monitor'
    },
    @{
        Path='\Microsoft\Windows\Windows Error Reporting'
        Name='QueueReporting'
        Desc='Crash reporting'
    }
)
# ============================================================================
# EXECUTION
# ============================================================================
Write-Log "Disabling scheduled tasks"
foreach ($task in $tasksToDisable) {
    Disable-ScheduledTasks -Name $task.Name `
        -Path $task.Path
}