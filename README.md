# Hide Help Texts

When the game and mods add help texts to the HUD it gets crowded. Do you really need to be reminded that F turns on the flashlight or that there is a keybinding to show Courseplay's debug channels?

This mod allows you to hide selected help texts from the HUD so the ones you actually need are more visible.

## Alpha Release

This is an alpha release. Core functionality works but there may be edge cases or issues. Feedback welcome.

## Features

- Hide selected help texts from the HUD
- Console commands for listing and toggling help texts
- Automatically discovers help texts as you play
- Settings persist across sessions
- Manual XML editing for advanced users
- (planned) In-game GUI for managing help texts

## Usage

### Console Commands

Open the console and use these commands:
(the key is usually `~` or `'` key depending on your keyboard layout)

| Command | Description |
|---------|-------------|
| `hhtList` | Lists all known help texts with visibility status |
| `hhtToggle <identifier>` | Toggle visibility of a specific help text |

### Workflow

1. Play the game normally - help texts are discovered automatically
2. Open console and run `hhtList` to see all known help texts
3. Use `hhtToggle IDENTIFIER` to hide unwanted texts
4. Settings are saved automatically

## Configuration

Settings are usually stored in:
```
Windows: %USERPROFILE%\Documents\My Games\FarmingSimulator2025\modSettings\FS25_HideHelpTexts\settings.xml
macOS: ~/Library/Application Support/FarmingSimulator2025/modSettings/FS25_HideHelpTexts/settings.xml
```

### XML Format

```xml
<?xml version="1.0" encoding="utf-8"?>
<hideHelpTexts>
    <helpText identifier="TOGGLE_LIGHTS" hidden="false" description="Toggle Lights" />
    <helpText identifier="HONK" hidden="true" description="Honk Horn" />
</hideHelpTexts>
```

You can manually edit this file to set `hidden="true"` for any help text.

## Installation

### From GitHub Releases
1. Download the latest release from [Releases](https://github.com/rittermod/FS25_HideHelpTexts/releases)
2. Place the `.zip` file in your mods folder:
   - **Windows**: `%USERPROFILE%\Documents\My Games\FarmingSimulator2025\mods\`
   - **macOS**: `~/Library/Application Support/FarmingSimulator2025/mods/`
3. Enable the mod in-game

### Manual Installation
1. Clone or download this repository
2. Copy the `FS25_HideHelpTexts` folder to your mods folder
3. Enable the mod in-game

## Changelog

### 0.2.0.0 (alpha)
- Added console commands (`hhtList`, `hhtToggle`)
- Settings now persist to XML file
- Automatically discovers help texts during play
- User can manually edit settings.xml

### 0.1.0.0 (alpha)
- Initial release
