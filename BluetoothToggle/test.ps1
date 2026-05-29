# One-time setup
Install-Package Microsoft.Windows.SDK.NET.Ref -Source https://api.nuget.org/v3/index.json -Force

# Then reference the DLL and use it
$sdkPath = (Get-Package Microsoft.Windows.SDK.NET.Ref).Source | Split-Path
Add-Type -Path "$sdkPath\ref\netstandard2.0\WinRT.Runtime.dll"
Add-Type -Path "$sdkPath\ref\netstandard2.0\Microsoft.Windows.SDK.NET.dll"

$radios = [Windows.Devices.Radios.Radio]::GetRadiosAsync().AsTask().GetAwaiter().GetResult()
$bt = $radios | Where-Object { $_.Kind -eq 'Bluetooth' }
$bt.SetStateAsync('Off').AsTask().GetAwaiter().GetResult()