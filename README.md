# KiyomizuOS
This is a playbook based on [Winhance](https://winhance.net) that primarily relies on PowerShell scripts, preferably PowerShell 7, to debloat and customize Windows 11 using [AME Wizard](https://amelabs.net).

## Changes made
- Customized original Winhance power plan for both laptop and desktop (auto-detect)
- Switched to Pro For Workstation edition (highest consumer Windows edition without the enterprise features)
- Disabled most UI animations and visual effects
- Windows Update paused and driver searching disabled
- Memory Integrity and Kernel-mode Hardware-enforced Stack protection are enabled by default
- Smart App control set to OFF and block Potentially Unwanted Apps enabled by default
- Bluetooth is turned off by default on a fresh Windows 11 boot
- Unnecessary scheduled tasks removed or disabled and services set to disabled at startup
- Registered Active Setup to modify some registry values that would otherwise be overwritten

## What is removed is shown below
### Manual removal (non-standard):
- Microsoft Edge and OneDrive

### Appx Packages:
| Package Name | App Name |
|--------------|----------|
| Microsoft.BingSearch | Bing Search |
| Microsoft.BingNews | Bing News |
| Microsoft.BingWeather | Bing Weather |
| Microsoft.WindowsCamera | Camera |
| Clipchamp.Clipchamp | Clipchamp |
| Microsoft.WindowsAlarms | Alarms & Clock |
| Microsoft.GetHelp | Get Help |
| Microsoft.WindowsCalculator | Calculator |
| Microsoft.Windows.DevHome | Dev Home |
| MSTeams | Microsoft Teams |
| Microsoft.WindowsFeedbackHub | Feedback Hub |
| Microsoft.WindowsTerminal | Windows Terminal |
| Microsoft.MicrosoftOfficeHub | Microsoft Office Hub |
| Microsoft.OutlookForWindows | Outlook for Windows |
| Microsoft.PowerAutomateDesktop | Power Automate Desktop |
| MicrosoftCorporationII.QuickAssist | Quick Assist |
| Microsoft.MicrosoftSolitaireCollection | Microsoft Solitaire Collection |
| Microsoft.GamingApp | Xbox App |
| Microsoft.XboxIdentityProvider | Xbox Identity Provider |
| Microsoft.Xbox.TCUI | Xbox TCUI |
| Microsoft.XboxGamingOverlay | Xbox Game Bar Overlay |
| Microsoft.WindowsSoundRecorder | Sound Recorder |
| Microsoft.MicrosoftStickyNotes | Sticky Notes |
| Microsoft.Todos | Microsoft To Do |
| Microsoft.YourPhone | Phone Link |
| MicrosoftWindows.CrossDevice | Cross Device Experience |

### Capabilities:
| Capability | Name | Status |
|------------|------|--------|
| Browser.InternetExplorer | Internet Explorer | <div align="center">Deprecated</div> |
| Microsoft.Windows.PowerShell.ISE | PowerShell ISE | <div align="center">Deprecated</div> |
| App.StepsRecorder | Steps Recorder | <div align="center">Deprecated</div> |
| Media.WindowsMediaPlayer | Windows Media Player | <div align="center">Legacy</div> |
| Microsoft.Windows.Notepad | Notepad | <div align="center">Legacy</div> |
| OpenSSH.Client | OpenSSH Client | <div align="center">Active</div> |
| MathRecognizer | Math Recognition | <div align="center">Deprecated</div> |

### Optional Features:
| Feature | Name | Status |
|---------|------|--------|
| Microsoft-RemoteDesktopConnection | Remote Desktop Connection | <div align="center">Active</div> |
---
### Installation Guide

1. Ensure you have [AME Beta](https://github.com/Ameliorated-LLC/trusted-uninstaller-cli/releases/latest) and a valid [Windows 11 ISO](https://massgrave.dev/windows_11_links).
2. Open AME Beta and drag your `.iso` file into the application.
3. Select the `KiyomizuOS.apbx` file.
4. Follow the on-screen instructions and pass all requirement checks.
5. Customize any available features to modify the playbook's functionality.
6. Build the KiyomizuOS ISO.
7. Mount the generated `.iso` file in File Explorer and run `setup.exe` from the root directory of the mounted ISO.
8. Perform a clean installation or an in-place upgrade of Windows during the setup process.

> Only ISO Injection is supported. Live installation is not supported and will not be supported in future releases.

### To Package the Playbook
Ensure you have 7-Zip ZS installed from https://github.com/mcmilk/7-Zip-zstd

Then, open up Powershell in the repository root directory and run the following command:
```powershell
& "C:\Program Files\7-Zip-Zstandard\7z.exe" a -t7z KiyomizuOS.apbx Configuration Executables Images playbook.conf playbook.png -pmalte
```
---
## Third-Party Software Downloads
This playbook includes downloads from third-party projects.

- [LibreWolf](https://codeberg.org/librewolf/source) — MPL 2.0 License
- [Helium](https://github.com/imputnet/helium) — GPL-3.0 License
- [PowerShell 7](https://github.com/PowerShell/PowerShell) — MIT License
- [7-Zip ZS](https://github.com/mcmilk/7-Zip-zstd) — GNU LGPL v2.1-or-later License
- [Microsoft Visual C++ v14 Redistributable](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170#latest-supported-redistributable-version) — Microsoft Software License Terms
- [File Unlocker for Windows](https://github.com/marianpekar/file-unlocker-for-windows) — MIT License

The original licenses and copyright notices for third-party software are included with their respective distributions.

## AGPL-3.0 License
Source: https://www.gnu.org/licenses/agpl-3.0.en.html

This is an OSI-approved open-source license. Free to fork, modify, and redistribute under the terms of the AGPL-3.0.

By complying with the AGPL-3.0 license, you must keep the same license for the covered work and cannot relicense that covered part under a different license.
Anyone who receives the software (including through purchase or as a service) must also be provided access to the corresponding source code under the same license.

See the [LICENSE.txt](https://github.com/KiyomizuSuzu/KiyomizuOS/blob/main/LICENSE) for the full license text.
