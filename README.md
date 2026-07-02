<details>
<summary>日本語</summary>

<p align="center">
  <img src="https://github.com/KiyomizuSuzu/KiyomizuSuzu.github.io/blob/main/KiyomizuOS.avif"
       width="50%">
</p>
<h1 align="center">KiyomizuOS</h1>
<p align="center">
<a href="https://winhance.net">Winhance</a>をベースにしたプレイブック。主にPowerShellスクリプト（できればPowerShell 7）を使い、<a href="https://amelabs.net">AME Wizard</a>経由でWindows 11のデブロートとカスタマイズを行う。
</p>

<h2 align="center">制限事項</h1>
<div align="center">
  
| 適用範囲     | クリーンインストール | 上書きアップグレード | 稼働中のシステム |
|----------------|--------------|-------------------|-------------|
| 現在のユーザー   | :white_check_mark: | :x: | :white_check_mark: |
| 新規ユーザー      | :white_check_mark: | :white_check_mark: | :x: |
| システム全体    | :white_check_mark: | :white_check_mark: | :white_check_mark: |
</div>

<p align="center">
  <i>まずはクリーンインストールで使い、必要に応じて上書きアップグレードや稼働中のシステムへの適用を検討するといい。</i>
</p>

## 変更内容
- ノートPC・デスクトップ両対応でWinhance純正の電源プランをカスタマイズ（自動判定）
- Pro For Workstationエディションに変更（エンタープライズ機能なしのコンシューマー向けWindowsとしては最上位）
- UIアニメーションと視覚効果をほぼ無効化
- Windows Updateを一時停止し、ドライバー検索を無効化
- メモリ整合性とカーネルモードのハードウェア強制スタック保護はデフォルトで有効
- スマートアプリコントロールはOFFに、迷惑なアプリのブロックはデフォルトで有効
- クリーンインストール直後のWindows 11起動時、Bluetoothはデフォルトでオフ
- 不要なタスクスケジューラは削除・無効化し、サービスも起動時無効に設定
- 通常は上書きされてしまうレジストリ値を維持するため、Active Setupを登録
- スタートメニューをクリーンアップ（「はじめに」アプリのみ残す）、タスクバーは中央寄せのまま検索バーはアイコンのみに変更
- 自作スクリプトが正しく動くよう、PowerShell 7と7-Zip ZSを依存関係として必須化
- Microsoft Visual C++ Redistributable v14を同梱、任意でMicrosoft Edgeの代わりにLibreWolfまたはHeliumを導入可能
- Wi-Fiのランダムハードウェアアドレスはデフォルトで有効、最終アクセス日時とファイル名の8.3形式生成は無効化
- Microsoftアカウント未使用でもドライブが自動暗号化されないよう、アクティベーション待ち状態にしてBitLockerをOFFに
- デフォルトのWindows 11壁紙はテーマ設定に応じて自動適用
- ログオン時の詳細メッセージ表示とテンキー入力を両方有効化
- LibreWolfまたはHeliumを既定のブラウザに設定し、タスクバーにピン留め

その他の細かい変更点はここには載せていないが、[Registry.ps1](https://github.com/KiyomizuSuzu/KiyomizuOS/blob/main/Executables/Registry.ps1)で確認できる。

## 削除されるコンポーネント一覧
### 手動削除（非標準）:
- Microsoft EdgeとOneDrive

### Appxパッケージ:
| パッケージ名 | アプリ名 |
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
| Microsoft.XboxSpeechToTextOverlay | Xbox Speech-to-Text Overlay |
| Microsoft.WindowsSoundRecorder | Sound Recorder |
| Microsoft.MicrosoftStickyNotes | Sticky Notes |
| Microsoft.Todos | Microsoft To Do |
| Microsoft.YourPhone | Phone Link |
| MicrosoftWindows.CrossDevice | Cross Device Experience |
| MicrosoftWindows.Client.WebExperience | Windows Web Experience Pack |

### Capabilities:
| Capability | 名前 | 状態 |
|------------|------|--------|
| Browser.InternetExplorer | Internet Explorer | <div align="center">廃止予定</div> |
| Microsoft.Windows.PowerShell.ISE | PowerShell ISE | <div align="center">廃止予定</div> |
| App.StepsRecorder | Steps Recorder | <div align="center">廃止予定</div> |
| Media.WindowsMediaPlayer | Windows Media Player | <div align="center">レガシー</div> |
| Microsoft.Windows.Notepad | Notepad | <div align="center">レガシー</div> |
| OpenSSH.Client | OpenSSH Client | <div align="center">有効</div> |
| MathRecognizer | Math Recognition | <div align="center">廃止予定</div> |

### オプション機能:
| Feature | 名前 | 状態 |
|---------|------|--------|
| Microsoft-RemoteDesktopConnection | Remote Desktop Connection | <div align="center">有効</div> |
---
### インストール手順

1. [AME Beta](https://github.com/Ameliorated-LLC/trusted-uninstaller-cli/releases/latest)と有効な[Windows 11 ISO](https://massgrave.dev/windows_11_links)を用意する。
2. AME Betaを開き、`.iso`ファイルをアプリにドラッグする。
3. `KiyomizuOS.apbx` ファイルを選択する。
4. 画面の指示に従い、すべての要件チェックを通過する。
5. プレイブックの動作を調整したい場合は、任意の機能をカスタマイズする。
6. KiyomizuOSのISOをビルドする。
7. 生成された`.iso`ファイルをエクスプローラーでマウントし、マウントしたISOのルートにある`setup.exe`を実行する。
8. セットアップ中はクリーンインストールを選ぶ。


>[!NOTE]
> 上書きアップグレードにも対応しているが、既存のユーザープロファイルを維持するため、現在のユーザー設定は変更されない。
>
> 稼働中のシステムに適用した場合、影響が及ぶのは主に現在サインインしているユーザーアカウントで、ローカルマシン側への変更は副次的なものにとどまる。

### プレイブックのパッケージ化
7-Zip ZSが必要。https://github.com/mcmilk/7-Zip-zstd からインストールできる。

リポジトリのルートでPowerShellを開き、以下を実行すればいい。
```powershell
& "C:\Program Files\7-Zip-Zstandard\7z.exe" a -t7z KiyomizuOS.apbx Configuration Executables Images playbook.conf playbook.png -pmalte
```
---
## サードパーティ製ソフトウェアのダウンロード
このプレイブックには、サードパーティ製プロジェクトからのダウンロードが含まれる。

- [LibreWolf](https://codeberg.org/librewolf/source) — MPL 2.0ライセンス
- [Helium](https://github.com/imputnet/helium) — GPL-3.0ライセンス
- [PowerShell 7](https://github.com/PowerShell/PowerShell) — MITライセンス
- [7-Zip ZS](https://github.com/mcmilk/7-Zip-zstd) — GNU LGPL v2.1-or-laterライセンス
- [Microsoft Visual C++ v14 Redistributable](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170#latest-supported-redistributable-version) — Microsoftソフトウェアライセンス条項
- [Sysinternals Handle](https://learn.microsoft.com/en-us/sysinternals/downloads/handle) — Sysinternalsソフトウェアライセンス条項

サードパーティ製ソフトウェアの元のライセンスおよび著作権表示は、それぞれの配布物に含まれている。

## AGPL-3.0 ライセンス
参照：https://licenses.opensource.jp/AGPL-3.0/AGPL-3.0.html

[OSI承認済み](https://opensource.org/licenses?ls=GNU+Affero+General+Public+License+version+3)のオープンソースライセンス。AGPL-3.0の条件のもとで、自由にフォーク・改変・再配布してもらって構わない。

AGPL-3.0に従う以上、対象コードは同じライセンスのまま維持する必要があり、別のライセンスへの再ライセンスはできない。また、このソフトウェアを受け取った人（購入やサービス経由も含む）には、同じライセンス条件のもとで対応するソースコードへのアクセスを提供する必要がある。

ライセンス全文は[LICENSE.txt](https://github.com/KiyomizuSuzu/Bluetooth/blob/main/LICENSE.txt)を参照。
</details>

---
<details open>
<summary>English</summary>

<p align="center">
  <img src="https://github.com/KiyomizuSuzu/KiyomizuSuzu.github.io/blob/main/KiyomizuOS.avif"
       width="50%">
</p>
<h1 align="center">KiyomizuOS</h1>
<p align="center">
This is a playbook based on <a href="https://winhance.net">Winhance</a> that primarily relies on PowerShell scripts, preferably PowerShell 7, to debloat and customize Windows 11 using <a href="https://amelabs.net">AME Wizard</a>.
</p>

<h2 align="center">Limitations</h1>
<div align="center">
  
| Applies to     | Fresh install | In-place upgrade | Live system |
|----------------|--------------|-------------------|-------------|
| Current user   | :white_check_mark: | :x: | :white_check_mark: |
| New users      | :white_check_mark: | :white_check_mark: | :x: |
| System-wide    | :white_check_mark: | :white_check_mark: | :white_check_mark: |
</div>

<p align="center">
  <i>Fresh install should be used first, followed by an in-place upgrade or a live system, depending on your needs.</i>
</p>

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
- Start Menu cleaned (except for Get Started app) and taskbar remains centered with search bar changed to icon only
- Required PowerShell 7 and 7-ZIP ZS as dependencies for my scripts to work properly
- Bundled Microsoft Visual C++ Redistributable v14, and optionally LibreWolf or Helium to replace Microsoft Edge
- WIFI random hardware addresses enabled by default, Last Access Time Stamp and 8.3 Filename Creation are set to disabled
- BitLocker turned OFF to not automatically encrypt drives even without using a Microsoft Account because it's waiting for activation
- Default Windows 11 wallpapers are set accordingly to your theme settings
- Enabled both verbose messages and numpad at logon
- Librewolf or Helium is now set as default browser and pinned to the taskbar

Most additional changes are not listed here but can be found in [Registry.ps1](https://github.com/KiyomizuSuzu/KiyomizuOS/blob/main/Executables/Registry.ps1).

## List of removed components
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
| Microsoft.XboxSpeechToTextOverlay | Xbox Speech-to-Text Overlay |
| Microsoft.WindowsSoundRecorder | Sound Recorder |
| Microsoft.MicrosoftStickyNotes | Sticky Notes |
| Microsoft.Todos | Microsoft To Do |
| Microsoft.YourPhone | Phone Link |
| MicrosoftWindows.CrossDevice | Cross Device Experience |
| MicrosoftWindows.Client.WebExperience | Windows Web Experience Pack |

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
8. Perform a clean installation during the setup process.

<blockquote>
<p><strong>Note</strong><br>
<p>An in-place upgrade is supported but it will not modify your current user settings, this is done to preserve your existing user profile.</p>
<p>The live system primarily affects the currently signed-in user account, while making only secondary changes to the local machine.</p>
</p>
</blockquote>

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
- [Sysinternals Handle](https://learn.microsoft.com/en-us/sysinternals/downloads/handle) — Sysinternals Software License Terms

The original licenses and copyright notices for third-party software are included with their respective distributions.

## AGPL-3.0 License
Source: https://www.gnu.org/licenses/agpl-3.0.en.html

This is an [OSI-approved](https://opensource.org/licenses?ls=GNU+Affero+General+Public+License+version+3) open-source license. Free to fork, modify, and redistribute under the terms of the AGPL-3.0.

By complying with the AGPL-3.0 license, you must keep the same license for the covered work and cannot relicense that covered part under a different license.
Anyone who receives the software (including through purchase or as a service) must also be provided access to the corresponding source code under the same license.

See the [LICENSE.txt](https://github.com/KiyomizuSuzu/KiyomizuOS/blob/main/LICENSE.txt) for the full license text.
</details>
