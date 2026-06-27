Import-Module "$PSScriptRoot\Module.psm1"
Initialize-RuntimeDefaults
# ============================================================================
# MAIN FUNCTION
# ============================================================================
function Set-StartupType {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [ValidateSet('Automatic','Manual','Disabled')]
        [string]$StartupType,
        [string]$Desc #not required
    )
    try {
        Set-Service -Name $Name `
            -StartupType $StartupType `
            -ErrorAction Stop
        Write-Log "Succesfully changed $Name to $StartupType"
    }
    catch {
        Write-Log "Failed to change $Name startup because $($_.Exception.Message)" 'ERROR'
    }
}
function Rename-File {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Name,
        [string]$Desc #not required
    )
    $backup = [System.IO.Path]::ChangeExtension($Path, '.old.exe')
    $fileExists = Test-Path -Path $Path
    $backupExists = Test-Path -Path $backup
    if (-not $fileExists) {
        Write-Log "$Name not found so nothing to rename." 'WARN'
    }
    else {
        Write-Log "Found file $Name to rename."
        if ($backupExists) {
            Write-Log "Already renamed $Name to $backup." 'WARN'
        }
        else {
            try {
                $findProcess = [System.IO.Path]::GetFileNameWithoutExtension($Name)
                #stop any running process if needed
                Stop-Process -Name $findProcess -Force
                Rename-Item -Path $Path `
                            -NewName (Split-Path $backup -Leaf) `
                            -ErrorAction Stop
                Write-Log "Renamed $Name to $(Split-Path $backup -Leaf)"
            }
            catch {
                Write-Log "Failed to rename $Name because $($_.Exception.Message)" 'ERROR'
            }
        }
    }
}
# ============================================================================
# DATA
# ============================================================================
$servicesToSet = @(
    @{  Name='SysMain';             Startup='Disabled';     Desc='SysMain service' }
    @{  Name='WSearch';             Startup='Manual';       Desc='Windows Search indexing service' }
    @{  Name='Spooler';             Startup='Manual';       Desc='Print spooler service' }
    @{  Name='DiagTrack';           Startup='Manual';       Desc='Telemetry service' }
    @{  Name='CDPSvc';              Startup='Manual';       Desc='Connected devices platform service' }
    @{  Name='CDPUserSvc';          Startup='Manual';       Desc='Connected devices user service' }
    @{  Name='WerSvc';              Startup='Manual';       Desc='Windows error reporting service' }
    @{  Name='lfsvc';               Startup='Manual';       Desc='Location service' }
    @{  Name='RetailDemo';          Startup='Manual';       Desc='Retail demo service' }
    @{  Name='wisvc';               Startup='Manual';       Desc='Windows Insider service' }
    @{  Name='PhoneSvc';            Startup='Manual';       Desc='Phone connectivity service' }
    @{  Name='WalletService';       Startup='Manual';       Desc='Wallet service' }
    @{  Name='SEMgrSvc';            Startup='Manual';       Desc='NFC security service' }
    @{  Name='SCardSvr';            Startup='Manual';       Desc='Smart card service' }
    @{  Name='ScDeviceEnum';        Startup='Manual';       Desc='Smart card device enumeration' }
    @{  Name='SCPolicySvc';         Startup='Manual';       Desc='Smart card policy service' }
    @{  Name='MapsBroker';          Startup='Manual';       Desc='Maps service' }
    @{  Name='icssvc';              Startup='Manual';       Desc='Internet connection sharing service' }
    @{  Name='SmsRouter';           Startup='Manual';       Desc='SMS routing service' }
    @{  Name='WpcMonSvc';           Startup='Manual';       Desc='Parental controls service' }
    @{  Name='svsvc';               Startup='Manual';       Desc='File system verification service' }
    @{  Name='RasMan';              Startup='Manual';       Desc='VPN service' }
    @{  Name='RasAuto';             Startup='Manual';       Desc='Auto VPN service' }
    @{  Name='TermService';         Startup='Manual';       Desc='Remote Desktop service' }
    @{  Name='SessionEnv';          Startup='Manual';       Desc='RDP configuration service' }
    @{  Name='UmRdpService';        Startup='Manual';       Desc='RDP redirection service' }
    @{  Name='XblAuthManager';      Startup='Manual';       Desc='Xbox authentication' }
    @{  Name='XblGameSave';         Startup='Manual';       Desc='Xbox save service' }
    @{  Name='XboxNetApiSvc';       Startup='Manual';       Desc='Xbox networking' }
    @{  Name='WbioSrvc';            Startup='Manual';       Desc='Biometric service' }
    @{  Name='TapiSrv';             Startup='Manual';       Desc='Telephony service' }
    @{  Name='SensrSvc';            Startup='Manual';       Desc='Sensor service' }
    @{  Name='SensorDataService';   Startup='Manual';       Desc='Sensor data service' }
    @{  Name='WSAIFabricSvc';       Startup='Disabled';     Desc='Windows AI service' }
    @{	Name='PcaSvc';		        Startup='Disabled';	    Desc='Program Compatibility Assistance service' }
)
$filesToModify = @(
    @{  Path='C:\Windows\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\TextInputHost.exe'
        Name='TextInputHost.exe'
        Desc='Text input process'
    }
)
# ============================================================================
# EXECUTION
# ============================================================================
Write-Log "Changing startup services"
foreach ($service in $servicesToSet) {
    Set-StartupType -Name $service.Name `
        -StartupType $service.Startup 
}
Write-Log "Renaming files"
foreach ($file in $filesToModify) {
    Rename-File -Path $file.Path `
        -Name $file.Name
}