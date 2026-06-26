# ============================================================================
# RUNTIME DEFAULTS
# ============================================================================
function Initialize-RuntimeDefaults {
    if ($PSVersionTable.PSEdition -ne "Core") {
        throw "Windows Powershell is not supported, please use https://github.com/PowerShell/PowerShell/releases/latest"
    }
    $global:ErrorActionPreference = 'SilentlyContinue'
}
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
    if ($LogFile) {
        try {
            Add-Content -Path $LogFile `
                -Encoding UTF8 `
                -Value "$timestamp [$Level] $Message" `
                -ErrorAction Stop
        }
        catch {
            Write-Host "Failed to write to log file: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}
# ============================================================================
# REGISTRY FUNCTIONS
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
# EXPORT FUNCTIONS
# ============================================================================
Export-ModuleMember -Function Initialize-RuntimeDefaults
Export-ModuleMember -Function Write-Log
Export-ModuleMember -Function Set-RegistryValue
Export-ModuleMember -Function Remove-RegistryValue
Export-ModuleMember -Function New-RegistryKey
Export-ModuleMember -Function Remove-RegistryKey
Export-ModuleMember -Function Set-BinaryBit
Export-ModuleMember -Function Set-BinaryByte