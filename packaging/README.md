# Release packaging

Quick Stack has one runtime source and two installed layouts.

## Nexus and CurseForge

The portable ZIP is extracted into the Palworld folder that contains `Pal`:

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

Nexus and CurseForge use the same sealed ZIP. The user supplies the
Palworld-specific experimental UE4SS runtime separately.

## Steam Workshop

The Workshop uploader receives a package rooted at the item directory:

Before assembling that package, build the Quick Stack-specific vote helper:

```powershell
& .\native\steam_vote\build.ps1
```

All three channels include `assets/about/`, which contains the same About-panel
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
node .\toolchain\tools\release\pal_insight_quick_stack_release_inventory.js artifact --root . --channel curseforge --artifact <directory>
node .\toolchain\tools\release\pal_insight_quick_stack_release_inventory.js artifact --root . --channel workshop --artifact <directory>
```

The gate rejects development versions, enabled diagnostic switches, mismatched
metadata, missing public documents, invalid Workshop metadata, and any missing
or unexpected artifact file.
