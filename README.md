# KiyomizuOS
This is a playbook based on Winhance that uses PowerShell scripts, preferably PowerShell 7, to debloat and customize Windows 11.

## To Package the Playbook
Ensure you have 7-Zip ZS installed from https://github.com/mcmilk/7-Zip-zstd/

Then, open a console in the repository root directory and run the following command:
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
