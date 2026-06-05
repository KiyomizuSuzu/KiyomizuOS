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
# ============================================================================
# DATA
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
    Write-Log "Found $LocalAccount" 'WARN'
    $lightTheme = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\AME').UseLightTheme
    if ($lightTheme -eq 1) {
        Write-Log "Lightmode is selected."
    }
    else {
        $lightTheme = 0
        Write-Log "Darkmode is selected."
    }
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