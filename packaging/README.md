# Release packaging

Quick Stack has one runtime source and three installed layouts.

## Nexus and CurseForge

Nexus and CurseForge each receive two separately named portable ZIPs. The
standard archive is extracted into the Steam Palworld folder that contains
`Pal`:

```text
CHANGELOG.md
CREDITS.md
LICENSE.md
README.md
Pal/Binaries/Win64/ue4ss/Mods/PalInsightQuickStack/
  enabled.txt
  Scripts/
  assets/about/
```

Nexus and CurseForge use byte-identical sealed ZIPs for each matching layout.
The user supplies the Palworld-specific experimental UE4SS runtime separately.

The Game Pass archive has the same contents under the WinGDK runtime root:

```text
CHANGELOG.md
CREDITS.md
LICENSE.md
README.md
Pal/Binaries/WinGDK/ue4ss/Mods/PalInsightQuickStack/
  enabled.txt
  Scripts/
  assets/about/
```

It is for the Xbox App / PC Game Pass / Microsoft Store build only. Static
package validation does not count as a representative in-game WinGDK test.

## Steam Workshop

The Workshop uploader receives a package rooted at the item directory:

Before assembling that package, build the Quick Stack-specific vote helper:

```powershell
& .\native\steam_vote\build.ps1
```

All distributions include `assets/about/`, which contains the same About-panel
logos and product preview used by the runtime. The Workshop artifact alone also
includes `Scripts/PalInsightQuickStackSteamVote.dll` and the three feedback
icons. Nexus and CurseForge omit only the vote helper and feedback icons.

```text
Info.json
thumbnail.png
Scripts/
  PalInsightQuickStackSteamVote.dll
assets/about/
assets/steam-workshop-feedback/
```

`enabled.txt` is intentionally omitted because Palworld Mod Management owns
Workshop activation. `Info.json` declares `UE4SSExperimentalPW` as the required
dependency and installs the client runtime plus its Workshop-only vote assets.

## Gates

Before any build or package command:

```powershell
node .\toolchain\tools\release\pal_insight_quick_stack_release_inventory.js prebuild --root .
```

After an artifact is assembled and before upload:

```powershell
node .\toolchain\tools\release\pal_insight_quick_stack_release_inventory.js artifact --root . --channel nexus --artifact <directory>
node .\toolchain\tools\release\pal_insight_quick_stack_release_inventory.js artifact --root . --channel nexus-gamepass --artifact <directory>
node .\toolchain\tools\release\pal_insight_quick_stack_release_inventory.js artifact --root . --channel curseforge --artifact <directory>
node .\toolchain\tools\release\pal_insight_quick_stack_release_inventory.js artifact --root . --channel curseforge-gamepass --artifact <directory>
node .\toolchain\tools\release\pal_insight_quick_stack_release_inventory.js artifact --root . --channel workshop --artifact <directory>
```

The gate rejects development versions, enabled diagnostic switches, mismatched
metadata, missing public documents, invalid Workshop metadata, and any missing
or unexpected artifact file.
