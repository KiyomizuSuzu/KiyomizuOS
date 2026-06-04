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
function Test-LegacyEdgeInstalled {
    $mainPath = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages'
    $allPackages = Get-ChildItem -Path $mainPath -Name
    try {
        $matchingPackages = @()
        foreach ($package in $allPackages) {
            $isBrowserPackage = $package -match 'Microsoft-Windows-Internet-Browser-Package'
            $hasTildeMarker = $package -match '~~'
            if ($isBrowserPackage -and $hasTildeMarker) {
                $matchingPackages += $package
            }
        }
        foreach ($legacyEdge in $matchingPackages) {
            $packageInfo = dism.exe /online /Get-PackageInfo /PackageName:$legacyEdge
            if ($packageInfo -match 'State\s*:\s*Installed') {
                Write-Log "Found $legacyEdge installed."
                return $legacyEdge
            }
        }
        throw #trigger catch
    }
    catch {
        Write-Log "Found no Legacy Edge installed." 'ERROR'
        return $false
    }
}
function Test-ChromiumEdgeInstalled {
    $edgeFolders = @(
        'Edge',
        'EdgeCore',
        'EdgeUpdate'
    )
    $programFiles = @(
        'C:\Program Files',
        'C:\Program Files (x86)'
    )
    try{
        foreach ($program in $programFiles) {
            foreach ($folder in $edgeFolders) {
                $directory = Join-Path $program "Microsoft\$folder"
                $dirExists = Test-Path -Path $directory
                if ($dirExists) {
                    Write-Log "Found $directory installed."
                    return $true
                }
            }
        }
        $appExists = Get-CimInstance -Namespace root\cimv2 `
                        -ClassName Win32_InstalledStoreProgram `
                        -Filter "Name like '%Microsoft.MicrosoftEdge.Stable%'"
        if ($appExists) {
            Write-Log "Found Microsoft.MicrosoftEdge.Stable installed."
            return $true
        }
        throw #trigger catch
    }
    catch {
        Write-Log "Found no Chromium Edge installed." 'ERROR'
        return $false
    }
}
function Stop-EdgeProcesses {
    $targets = @(
        'MicrosoftEdgeUpdate',
        'CrossDeviceResume'
    )
    foreach ($name in $targets) {
        $running = Get-Process -Name $name
        if ($running) {
            $count = $running.Count
            foreach ($process in $running) {
                #stop any running process if needed
                Stop-Process -Id $process.Id `
                    -Force 
            }
            Write-Log "Stopped $count instance(s) of $name"
        }
        else {
            Write-Log "$name isn't running." 'ERROR'
        }
    }
}
function Remove-LegacyEdge {
    $mainPath = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages'
    $package = $null
    $allPackages = Get-ChildItem -Path $mainPath -Name
    foreach ($pkg in $allPackages) {
        if ($pkg -match 'Microsoft-Windows-Internet-Browser-Package' -and
            $pkg -match '~~') {
            $package = $pkg
            break
        }
    }
    $packagePath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\$package"
    #overwrites any existing value if needed
    Set-ItemProperty -Path $packagePath `
        -Name Visibility `
        -Value 1 `
        -Type DWord `
        -Force | Out-Null
    $ownersPath = Join-Path $packagePath 'Owners'
    $ownerExists = Test-Path -Path $ownersPath
    if ($ownerExists) {
        #delete any value if needed
        Remove-Item -Path $ownersPath `
            -Recurse | Out-Null
    }
    try{
        Write-Log 'Removing Legacy Edge package via DISM'
        $dismProcess = Start-Process -FilePath 'dism.exe' `
                            -ArgumentList @(
                                '/online',
                                '/Remove-Package',
                                "/PackageName:$package",
                                '/NoRestart'
                            ) `
                            -NoNewWindow `
                            -Wait
        $dismProcess.Dispose()
        throw #trigger catch
    }
    catch {
        Write-Log 'Removing Legacy UWP Edge package'
        $legacyPackages = Get-AppxPackage -AllUsers -Name "Microsoft.MicrosoftEdge"
        foreach ($UWP in $legacyPackages) {
            Remove-AppxPackage -Package $UWP.PackageFullName -AllUsers
        }
        Write-Log 'Successfully removed Legacy Edge.'
    }
}
function Remove-ChromiumEdge {
    $edgePath = 'C:\Windows\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe'
    New-Item -Path $edgePath `
        -ItemType Directory | Out-Null
    New-Item -Path (Join-Path $edgePath 'MicrosoftEdge.exe') `
        -ItemType File | Out-Null
    Write-Log 'Searching for uninstall strings'
    $uninstallKeys = Get-ChildItem 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    foreach ($key in $uninstallKeys) {
        $find = Get-ItemProperty $key.PSPath
        if ($find.DisplayName -like '*Microsoft Edge*') {
            $uninstallString = $find.UninstallString
            Write-Log 'Running Edge uninstaller'
            if ($uninstallString -like '*msiexec*') {
                if ($uninstallString -match '\{.*\}') {
                    $productCode = $matches[0]
                    Start-Process "msiexec.exe" -ArgumentList "/x $productCode /quiet /norestart" -Wait
                }
            }
            else {
                if ($uninstallString -match '^"(.+?)"\s*(.*)$') {
                    $exe = $matches[1]
                    $arg = $matches[2]
                }
                else {
                    $exe = $uninstallString
                    $arg = ""
                }
                Start-Process -FilePath $exe -ArgumentList "$arg --force-uninstall --silent" -Wait
            }
        }
    }
    $chromiumPackages = Get-AppxPackage -AllUsers -Name 'Microsoft.MicrosoftEdge.Stable'
    foreach ($chromium in $chromiumPackages) {
        Remove-AppxPackage -Package $chromium.PackageFullName -AllUsers
    }
    #deletes any files if needed
    Remove-Item -Path $edgePath `
        -Recurse | Out-Null
    Write-Log 'Successfully removed Chromium Edge'
}
function Remove-EdgeRegistryKeys {
    $multiplekeys = @(
        'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Edge',
        'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Edge',
        'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update'
    )
    foreach ($path in $multiplekeys) {
        try{
            #deletes any value if needed
            Remove-Item -Path $path `
                -Recurse `
                -ErrorAction Stop | Out-Null
            Write-Log "Removed key $path"
        }
        catch {
            Write-Log "$path not found" 'ERROR'
        }
    }
}
function Remove-AdditionalEdgeFolders {
    $folderPaths = @(
        'C:\ProgramData\Microsoft\EdgeUpdate',
        'C:\Windows\Temp\MsEdgeCrashpad'
    )
    try {
        foreach ($folder in $folderPaths) {
            #deletes any files if needed
            Remove-Item $folder `
                -Recurse | Out-Null
            Write-Log "Removed folder $folder"
        }
    }
    catch {
        Write-Log "$folder not found." 'ERROR'
    }
    $profiles = @()
    $allProfiles = Get-ChildItem -Path 'C:\Users' -Directory
    foreach ($userProfile in $allProfiles) {
        $profileExists = Test-Path -Path (Join-Path $userProfile.FullName 'NTUSER.DAT')
        if ($profileExists) {
            $profiles += $userProfile
        }
    }
    try{
        foreach ($userProfile in $profiles) {
            $edgeLocal = Join-Path $userProfile.FullName 'AppData\Local\Microsoft\Edge'
            #remove any files if needed
            Remove-Item -Path $edgeLocal `
                -Recurse
        }
    }
    catch {
        Write-Log "$edgeLocal not found." 'ERROR'
    }
}
function Install-EdgeProtocolRedirect {
    $scriptsDir = 'C:\ProgramData\AME\OpenWebSearch'
    New-Item -ItemType Directory `
        -Path $scriptsDir | Out-Null
    $stubTargetPath = Join-Path $scriptsDir 'ie_to_edge_stub.exe'
    $stubExists = Test-Path $stubTargetPath
    if (-not $stubExists) {
        Write-Log "$stubTargetPath not found" 'ERROR'
        return
    }
    else {
        $edgeProto = 'Registry::HKEY_CLASSES_ROOT\microsoft-edge'
        $cmdPath = 'Registry::HKEY_CLASSES_ROOT\microsoft-edge\shell\open\command'
        Set-RegistryValue `
            -Path $edgeProto `
            -Name '(default)' `
            -Type 'String' `
            -Value 'URL:microsoft-edge'
        Set-RegistryValue `
            -Path $edgeProto `
            -Name 'URL Protocol' `
            -Type 'String' `
            -Value ''
        Set-RegistryValue `
            -Path $edgeProto `
            -Name 'NoOpenWith' `
            -Type 'String' `
            -Value ''
        Set-RegistryValue `
            -Path $cmdPath `
            -Name '(default)' `
            -Type 'String' `
            -Value "$stubTargetPath %1"
        Write-Log "Protocol redirect installed"
    }
}
# ============================================================================
# EXECUTION
# ============================================================================
Write-Log 'Checking for Edge installations'
$legacyInstalled = Test-LegacyEdgeInstalled
$chromiumInstalled = Test-ChromiumEdgeInstalled
$cleanup = $false
$stubPath = $null

if (-not $legacyInstalled -and -not $chromiumInstalled) {
    Write-Log 'No Edge installations detected' 'ERROR'
}
else {
    if ($chromiumInstalled) {
        Write-Log 'Searching for ie_to_edge_stub.exe'
        #search subfolders also
        $stubFiles = Get-ChildItem -Path "C:\Program Files (x86)\Microsoft\Edge" `
                        -Filter 'ie_to_edge_stub.exe' `
                        -Recurse 
        if ($stubFiles.Count -gt 0) {
            $stubSearch = $stubFiles[0]
        } else {
            $stubSearch = $null
        }
        if ($stubSearch) {
            $stubPath = $stubSearch.FullName
            Write-Log "Found stub: $stubPath"
            $scriptsDir = 'C:\ProgramData\AME\OpenWebSearch'
            New-Item -ItemType Directory `
                -Path $scriptsDir | Out-Null
            Copy-Item $stubPath (Join-Path $scriptsDir 'ie_to_edge_stub.exe') | Out-Null
            Write-Log 'Copied ie_to_edge_stub.exe'
        }
        else {
            Write-Log "ie_to_edge_stub.exe not found."
        }
        Write-Log 'Chromium Edge detected'
        Stop-EdgeProcesses
        Remove-ChromiumEdge
        $cleanup = $true
    }
    if ($legacyInstalled) {
        Write-Log 'Legacy Edge detected'
        Remove-LegacyEdge
        $cleanup = $true
    }
    if ($cleanup) {
        Write-Log 'Cleaning Edge folders'
        $allFolders = Get-ChildItem -Path "C:\Program Files (x86)\Microsoft" `
                        -Directory 
        $edgeFolders = @()
        foreach ($folder in $allFolders) {
            if (($folder.Name -like '*Edge*' -or $folder.Name -like '*Temp*') -and
                ($folder.Name -notlike '*EdgeWebView*')) {
                $edgeFolders += $folder
            }
        }
        $folderCount = $edgeFolders.Count
        if ($folderCount -gt 0) {
            foreach ($folder in $edgeFolders) {
                #remove any files if needed
                Remove-Item -Path $folder.FullName `
                    -Recurse
            }
        }
        Remove-EdgeRegistryKeys
        Remove-AdditionalEdgeFolders
    }
    $stubPath = 'C:\ProgramData\AME\OpenWebSearch\ie_to_edge_stub.exe'
    $stubPathExists = Test-Path -Path $stubPath
    if ($stubPathExists) {
        $msEdgePath = 'Registry::HKEY_CLASSES_ROOT\MSEdgeHTM\shell\open\command'
        Set-RegistryValue `
            -Path $msEdgePath `
            -Name '(default)' `
            -Type 'String' `
            -Value "`"$stubPath`" %1"
        Write-Log 'Redirected MSEdgeHTM'
    }
    else {
        #delete any value if needed
        Remove-Item -Path 'Registry::HKEY_CLASSES_ROOT\MSEdgeHTM' `
            -Recurse | Out-Null
        Write-Log "$stubPath is missing, removed MSEdgeHTM handler completely as fallback" 'WARN'
    }
    Install-EdgeProtocolRedirect
    $edgeTasks = Get-ScheduledTask -TaskName '*Edge*'
    foreach ($task in $edgeTasks) {
        try {
            Unregister-ScheduledTask -TaskName $task.TaskName `
                -TaskPath $task.TaskPath `
                -Confirm:$false 
            Write-Log "Deleted scheduled task: $($task.TaskName)"
        }
        catch {
            Write-Log "Failed deleting task: $($task.TaskName)" 'ERROR'
        }
    }
}