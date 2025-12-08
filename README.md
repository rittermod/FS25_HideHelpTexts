# Hide Help Texts

When the game and mods all add their own help texts to the HUD it quickly gets crowded. Do you really need to be reminded that F turns on the flashlight or that there is a keybinding to show Courseplay's debug channels? This mod lets you hide the help texts you don't need so the ones you actually want are more visible.

## Beta Release

This is a beta release. Core functionality is stable and tested. Multiplayer compatible. Feedback welcome.

## Features

- **In-Game Settings Dialog:** Press RightShift+H to open settings (keybinding configurable)
- **Toggle Visibility:** ON/OFF toggles for each discovered help text
- **View Modes:** Switch between current context and all discovered help texts
- **Console Commands:** `hhtList` and `hhtToggle` for command-line control
- **Auto-Discovery:** Help texts are discovered automatically as you play
- **Persistent Settings:** Configuration saved to user settings, working across savefiles

## Usage

### In-Game Settings Dialog

Press **RightShift+H** to open the settings dialog (keybinding is configurable in game settings).

- Toggle help texts ON/OFF by selecting them and pressing Enter or using arrow keys
- Press **X** to switch between "Current" view (only active context) and "All" view (all discovered)
- Changes are saved when closing the dialog

### Console Commands

Open the console and use these commands:
(the key is usually `~` or `'` key depending on your keyboard layout)

| Command | Description |
|---------|-------------|
| `hhtList` | Lists all known help texts with visibility status |
| `hhtToggle <identifier>` | Toggle visibility of a specific help text |

### Workflow

1. Play the game normally - help texts are discovered automatically
2. Press **RightShift+H** to open the settings dialog
3. Toggle unwanted help texts to OFF
4. Use **X** to switch between current context and all discovered help texts
5. Settings are saved automatically

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

### 0.5.1.1 (beta)
- Code maintenance

### 0.5.1.0 (beta)
- Fixed spurious error log when registering keybind while in vehicle

### 0.5.0.0 (beta)
- First beta release
- Multiplayer support confirmed

### 0.4.0.0 (alpha)
- View mode toggle: show current context or all discovered help texts
- Display key bindings for each help text (e.g., Shift + H)
- Improved dialog layout and text readability

### 0.3.0.0 (alpha)
- Added in-game settings dialog (RightShift+H)
- Shows discovered help texts with ON/OFF toggles
- Arrow key navigation support

### 0.2.0.0 (alpha)
- Added console commands (`hhtList`, `hhtToggle`)
- Settings now persist to XML file
- Automatically discovers help texts during play
- User can manually edit settings.xml

### 0.1.0.0 (alpha)
- Initial release
