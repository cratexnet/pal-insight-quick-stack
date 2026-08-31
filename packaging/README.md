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
```

Nexus and CurseForge use the same sealed ZIP. The user supplies the
Palworld-specific experimental UE4SS runtime separately.

## Steam Workshop

The Workshop uploader receives a package rooted at the item directory:

```text
Info.json
thumbnail.png
Scripts/
```

`enabled.txt` is intentionally omitted because Palworld Mod Management owns
Workshop activation. `Info.json` declares `UE4SSExperimentalPW` as the required
dependency and installs only the client Lua scripts.

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
