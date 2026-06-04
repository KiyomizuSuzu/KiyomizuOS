# KiyomizuOS
This is a playbook based on Winhance that primarily relies on PowerShell scripts, preferably PowerShell 7, to debloat and customize Windows 11.

### Installation Guide

1. Ensure you have [AME Beta](https://github.com/Ameliorated-LLC/trusted-uninstaller-cli) and a valid [Windows 11 ISO](https://massgrave.dev/windows_11_links).
2. Open AME Beta and drag your `.iso` file into the application.
3. Select the `KiyomizuOS.apbx` file.
4. Follow the on-screen instructions and pass all requirement checks.
5. Customize any available features to modify the playbook's functionality.
6. Build the KiyomizuOS ISO.
7. Mount the generated `.iso` file in File Explorer and run `setup.exe` from the root directory of the mounted ISO.
8. Perform a clean installation or an in-place upgrade of Windows using the generated ISO.

> Only ISO Injection is supported. Live installation is not supported and will not be supported in future releases.

### To Package the Playbook
Ensure you have 7-Zip ZS installed from https://github.com/mcmilk/7-Zip-zstd

Then, open up Powershell in the repository root directory and run the following command:
```powershell
& "C:\Program Files\7-Zip-Zstandard\7z.exe" a -t7z KiyomizuOS.apbx Configuration Executables Images playbook.conf playbook.png -pmalte
```

## Third-Party Software Downloads
This playbook includes downloads from third-party projects.

- [LibreWolf](https://librewolf.net/) — MPL 2.0 License
- [Helium](https://github.com/imputnet/helium) — GPL-3.0 License
- [PowerShell 7](https://github.com/PowerShell/PowerShell) — MIT License
- [7-Zip ZS](https://github.com/mcmilk/7-Zip-zstd) — GNU LGPL v2.1-or-later License
- [Microsoft Visual C++ v14 Redistributable](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170#latest-supported-redistributable-version) — Microsoft Software License Terms
- [File Unlocker for Windows](https://github.com/marianpekar/file-unlocker-for-windows) — MIT License

The original licenses and copyright notices for third-party software are included with their respective distributions.

## AGPL-3.0 license
Source: https://www.gnu.org/licenses/agpl-3.0.en.html

This is an OSI-approved open-source license. Free to fork, modify, and redistribute under the terms of the AGPL-3.0.

By complying with the AGPL-3.0 license, you must keep the same license for the covered work and cannot relicense that covered part under a different license.
Anyone who receives the software (including through purchase or as a service) must also be provided access to the corresponding source code under the same license.

The point is that if you share modified code with someone, whether privately or not, any scripts derived from AGPL-3.0 code must retain a header comment indicating that they are licensed under AGPL-3.0.

Copyright (c) 2026 KiyomizuSuzu
