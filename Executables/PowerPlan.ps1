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
function New-Powerplan {
    param (
        [Parameter(Mandatory)]
        [string]$Guid,
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [ValidateSet(
            'Ultimate Performance',
            'High Performance',
            'Balanced'
        )]
        [string]$Base,
        [Parameter(Mandatory)]
        [string]$Desc
    )
    switch ($Base) {
        'Ultimate Performance'  { $scheme = 'e9a42b02-d5df-448d-aa00-03f14749eb61'}
        'High Performance'      { $scheme = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'}
        'Balanced'              { $scheme = '381b4222-f694-41f0-9685-ff5bb260df2e'}
    }
    $guidExists = powercfg /query $Guid 2>$null
    if ($guidExists -notmatch "The power scheme, subgroup or setting specified does not exist.") {
        Write-Log "Powerplan already exists" 'WARN'
        return
    }
    else {
        powercfg /duplicatescheme $scheme $Guid
        powercfg /changename $Guid $Name $Desc
        Write-Log "Successfully create powerplan $Name"
    }
}
function Enable-Hiddensettings {
    param (
        [Parameter(Mandatory)]
        [string]$Subgroup,
        [Parameter(Mandatory)]
        [string]$Setting,
        [string]$Desc
    )
    $mainPath = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerSettings'
    $subgroupPath = Join-Path $mainPath $Subgroup
    $settingPath  = Join-Path $subgroupPath $Setting
    try {
        #overwrites any existing value if needed
        New-ItemProperty `
            -Path $settingPath `
            -Name "Attributes" `
            -Value 0 `
            -Force | Out-Null
        Write-Log "Successfully enabled show $Setting"
    }
    catch {
        Write-Log "Failed to enable show $Setting because $($_.Exception.Message)" 'ERROR'
    }
}
function Set-Powersettings {
    param (
        [Parameter(Mandatory)]
        [string]$ID,
        [Parameter(Mandatory)]
        [string]$Set,
        [Parameter(Mandatory)]
        [string]$Group,
        [Parameter(Mandatory)]
        [string]$Plugged,
        [Parameter(Mandatory)]
        [string]$Battery,
        [string]$Desc #not required
    )
    $idExists = powercfg /query $ID 2>$null
    if ($idExists -match "The power scheme, subgroup or setting specified does not exist.") {
        Write-Log "$ID doesn't exist." 'ERROR'
        return
    }
    if (-not ($idExists -match "$Set")) {
        Write-Log "$Set doesn't exist." 'ERROR'
        return
    }
    elseif (-not ($idExists -match "$Group")) {
        Write-Log "$Group doesn't exist." 'ERROR'
        return
    }
    else {
        powercfg /setacvalueindex $ID $Group $Set $Plugged
        powercfg /setdcvalueindex $ID $Group $Set $Battery
        Write-Log "Successfully set $Set"
    }
}
function Set-ActivePowerplan {
    param(
        [Parameter(Mandatory)]
        [string]$Identifier
    )
    $activeScheme = powercfg /getactivescheme 2>$null
    if ($activeScheme -match [regex]::Escape($Identifier)) {
        Write-Log "Powerplan $Identifier is already active." 'WARN'
        return
    }
    else {
        powercfg /setactive $Identifier
        Write-Log "Successfully activated power plan $Identifier"
    }
}
# ============================================================================
# DATA
# ============================================================================
$chassisType = (Get-CimInstance -ClassName Win32_SystemEnclosure).ChassisTypes
$laptop = $chassisType -match '8|9|10|14|30|31|32'
$desktop = $chassisType -match '3|4|5|6|7|12|13|22|23|24|29'
$others = $chassisType -match '1|2|11|15|16|17|18|19|20|21|25|26|27|28'
if ($laptop) {
    Write-Log "This is a laptop."
    $device = 0 #disabled
} 
elseif ($desktop) {
    Write-Log "This is a desktop PC."
    $device = 2 #aggressive
}
elseif ($others) {
    Write-Log "This doesn't appear to be Desktop or a laptop either." 'WARN'
    $device = 1 #enabled by default
}
$hiddenSettingsToEnable = @(
    @{ Subgroup = "2a737441-1930-4402-8d77-b2bebba308a3"; Setting = "0853a681-27c8-4100-a2fd-82013e970683"; Desc = 'USB selective suspend setting'}
    @{ Subgroup = "2a737441-1930-4402-8d77-b2bebba308a3"; Setting = "d4e98f31-5ffe-4ce1-be31-1b38b384c009"; Desc = 'USB 3 Link Power Management'}
    @{ Subgroup = "4f971e89-eebd-4455-a8de-9e59040e7347"; Setting = "7648efa3-dd9c-4e3e-b566-50f929386280"; Desc = 'SUB_BUTTONS PBUTTONACTION' }
    @{ Subgroup = "4f971e89-eebd-4455-a8de-9e59040e7347"; Setting = "96996bc0-ad50-47ec-923b-6f41874dd9eb"; Desc = 'SUB_BUTTONS SBUTTONACTION' }
    @{ Subgroup = "4f971e89-eebd-4455-a8de-9e59040e7347"; Setting = "5ca83367-6e45-459f-a27b-476b1d01c936"; Desc = 'SUB_BUTTONS LIDACTION'}
    @{ Subgroup = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "94d3a615-a899-4ac5-ae2b-e4d8f634367f"; Desc = 'SUB_PROCESSOR SYSCOOLPOL' }
    @{ Subgroup = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "be337238-0d82-4146-a960-4f3749d470c7"; Desc = 'SUB_PROCESSOR PERFBOOSTMODE' }
    @{ Subgroup = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "465e1f50-b610-473a-ab58-00d1077dc418"; Desc = 'SUB_PROCESSOR PERFINCPOL' }
    @{ Subgroup = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "40fbefc7-2e9d-4d25-a185-0cfd8574bac6"; Desc = 'SUB_PROCESSOR PERFDECPOL' }
    @{ Subgroup = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "0cc5b647-c1df-4637-891a-dec35c318583"; Desc = 'SUB_PROCESSOR CPMINCORES' }
    @{ Subgroup = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "ea062031-0e34-4ff1-9b6d-eb1059334028"; Desc = 'SUB_PROCESSOR CPMAXCORES' }
    @{ Subgroup = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "36687f9e-e3a5-4dbf-b1dc-15eb381c6863"; Desc = 'SUB_PROCESSOR PERFEPP' }
    @{ Subgroup = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "06cadf0e-64ed-448a-8927-ce7bf90eb35d"; Desc = 'SUB_PROCESSOR PERFINCTHRESHOLD' }
    @{ Subgroup = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "12a0ab44-fe28-4fa9-b3bd-4b64f44960a6"; Desc = 'SUB_PROCESSOR PERFDECTHRESHOLD' }
)
$settingsToApply = @(
    @{ Sub="SUB_VIDEO";                             Main="VIDEOIDLE";                               AC=0; DC=300
        Desc="Specifies the period of inactivity before Windows turns off the display" 
    },
    @{ Sub="SUB_DISK";                              Main="DISKIDLE";                                AC=0; DC=600
        Desc="Specifies the period of inactivity before Windows turns off the hard disk" 
    },
    @{ Sub="0d7dbae2-4294-402a-ba8e-26777e8488cd";  Main="309dce9b-bef4-4119-9921-a851fb12f0f4";    AC=1; DC=1
        Desc="Allow or prevent Windows from rotating through multiple wallpaper images" 
    },
    @{ Sub="19cbb8fa-5279-450e-9fac-8a3d5fedd0c1";  Main="12bbebe6-58d6-4636-95bb-3217ef867c1a";    AC=0; DC=2
        Desc="Balance wireless network performance with battery life by adjusting adapter power usage" 
    },
    @{ Sub="SUB_SLEEP";                             Main="STANDBYIDLE";                             AC=0; DC=900
        Desc="Specifies the period of inactivity before Windows puts the computer to sleep" 
    },
    @{ Sub="SUB_SLEEP";                             Main="RTCWAKE";                                 AC=0; DC=0
        Desc="Allow scheduled tasks and applications to wake your computer from sleep" 
    },
    @{ Sub="SUB_SLEEP";                             Main="HIBERNATEIDLE";                           AC=0; DC=0
        Desc="Specifies the period of inactivity before Windows hibernates the computer" 
    },
    @{ Sub="2a737441-1930-4402-8d77-b2bebba308a3";  Main="0853a681-27c8-4100-a2fd-82013e970683";    AC=0; DC=1000
        Desc="Set how long USB hubs wait idle before powering down to save energy" 
    },
    @{ Sub="2a737441-1930-4402-8d77-b2bebba308a3";  Main="48e6b7a6-50f5-4782-a5d4-53bb8f07e226";    AC=0; DC=1
        Desc="Allow Windows to power down individual USB ports when devices are idle to save energy" 
    },
    @{ Sub="2a737441-1930-4402-8d77-b2bebba308a3";  Main="d4e98f31-5ffe-4ce1-be31-1b38b384c009";    AC=0; DC=2
        Desc="Control how aggressively USB 3.0 ports enter low-power states when devices are idle" 
    },
    @{ Sub="SUB_BUTTONS";                           Main="PBUTTONACTION";                           AC=0; DC=0
        Desc="Choose what happens when you press the physical power button on your computer" 
    },
    @{ Sub="SUB_BUTTONS";                           Main="SBUTTONACTION";                           AC=0; DC=0
        Desc="Choose what happens when you press the dedicated sleep button on your keyboard or computer" 
    },
    @{ Sub="SUB_BUTTONS";                           Main="LIDACTION";                               AC=2; DC=2
        Desc="Choose what happens when you close your laptop lid" 
    },
    @{ Sub="SUB_PCIEXPRESS";                        Main="ASPM";                                    AC=0; DC=2
        Desc="Control power savings for PCIe devices like graphics cards, SSDs, and expansion cards" 
    },
    @{ Sub="SUB_PROCESSOR";                         Main="PROCTHROTTLEMIN";                         AC=100; DC=5
        Desc="Set the lowest CPU speed allowed as a percentage of maximum frequency" 
    },
    @{ Sub="SUB_PROCESSOR";                         Main="PROCTHROTTLEMAX";                         AC=100; DC=100
        Desc="Set the highest CPU speed allowed as a percentage of maximum frequency" 
    },
    @{ Sub="SUB_PROCESSOR";                         Main="SYSCOOLPOL";                              AC=1; DC=1
        Desc="Choose whether to slow down the processor first (passive) or speed up fans first (active) when hot" 
    },
    @{ Sub="SUB_PROCESSOR";                         Main="PERFBOOSTMODE";                           AC=$device; DC=0
        Desc="Control how aggressively your CPU boosts above base frequency for demanding tasks" 
    },
    @{ Sub="SUB_PROCESSOR";                         Main="PERFINCPOL";                              AC=2; DC=0
        Desc="Control how quickly CPU ramps up speed when workload increases (for legacy non-HWP processors)" 
    },
    @{ Sub="SUB_PROCESSOR";                         Main="PERFDECPOL";                              AC=1; DC=2
        Desc="Control how quickly CPU reduces speed when workload decreases (for legacy non-HWP processors)" 
    },
    @{ Sub="SUB_PROCESSOR";                         Main="CPMINCORES";                              AC=0; DC=0
        Desc="Set the minimum percentage of CPU cores that must remain active and responsive" 
    },
    @{ Sub="SUB_PROCESSOR";                         Main="CPMAXCORES";                              AC=100; DC=100
        Desc="Set the maximum percentage of CPU cores allowed to be active (100% for best performance)" 
    },
    @{ Sub="SUB_PROCESSOR";                         Main="PERFEPP";                                 AC=0; DC=50
        Desc="Balance power efficiency and performance for modern CPUs with HWP (0 = max performance, 100 = max efficiency)" 
    },
    @{ Sub="SUB_PROCESSOR";                         Main="PERFINCTHRESHOLD";                        AC=10; DC=30
        Desc="Set CPU usage percentage that triggers speed increase (lower = more responsive, for legacy non-HWP CPUs)" 
    },
    @{ Sub="SUB_PROCESSOR";                         Main="PERFDECTHRESHOLD";                        AC=8; DC=20
        Desc="Set CPU usage percentage that triggers speed reduction (lower = maintains performance longer, for legacy non-HWP CPUs)" 
    },
    @{ Sub="9596fb26-9850-41fd-ac3e-f7c3c00afd4b";  Main="10778347-1370-4ee0-8bbd-33bdacaade49";    AC=1; DC=1
        Desc="Prioritize smooth video playback over battery life when watching videos" 
    },
    @{ Sub="9596fb26-9850-41fd-ac3e-f7c3c00afd4b";  Main="34c7b99f-9a6d-4b3c-8dc7-b6693b78cef4";    AC=0; DC=0
        Desc="Balance video quality and power consumption during video playback" 
    },
    @{ Sub="SUB_BATTERY";                           Main="BATFLAGSCRIT";                            AC=1; DC=1
        Desc="Show notification when battery reaches critically low level"
    },
    @{ Sub="SUB_BATTERY";                           Main="BATACTIONCRIT";                           AC=2; DC=2
        Desc="Choose what happens when battery reaches critically low level" 
    },
    @{ Sub="SUB_BATTERY";                           Main="BATLEVELLOW";                              AC=10; DC=10
        Desc="Set the battery percentage that triggers low battery warnings and actions" 
    },
    @{ Sub="SUB_BATTERY";                           Main="BATLEVELCRIT";                            AC=5; DC=5
        Desc="Set the battery percentage that triggers critical battery warnings and emergency actions" 
    },
    @{ Sub="SUB_BATTERY";                           Main="BATFLAGSLOW";                             AC=1; DC=1
        Desc="Show notification when battery reaches low battery level" 
    },
    @{ Sub="SUB_BATTERY";                           Main="BATACTIONLOW";                            AC=0; DC=0
        Desc="Choose what happens when battery reaches low battery level" 
    },
    @{ Sub="SUB_BATTERY";                           Main="f3c5027d-cd16-4930-aa6b-90db844a8f00";    AC=7; DC=7
        Desc="Set battery percentage reserved to protect battery health and prevent unexpected shutdowns" 
    }
)
# ============================================================================
# EXECUTION
# ============================================================================
$CustomPlanGuid = '57696e68-616e-6365-506f-776572abcdef'
New-Powerplan -Guid $CustomPlanGuid `
    -Name 'Winhance Ultimate' `
    -Base 'Ultimate Performance' `
    -Desc 'Modified by KiyomizuSuzu'

Write-Log "Enabling hidden powerplan settings"
foreach ($hidden in $hiddenSettingsToEnable) {
    Enable-Hiddensettings -Subgroup $hidden.Subgroup `
        -Setting $hidden.Setting
}
Write-Log "Applying current powerplan settings"
foreach ($setting in $settingsToApply) {
    Set-Powersettings -ID $CustomPlanGuid `
        -Set $setting.Main `
        -Group $setting.Sub `
        -Plugged $setting.AC `
        -Battery $setting.DC
}
Set-ActivePowerplan -Identifier $CustomPlanGuid