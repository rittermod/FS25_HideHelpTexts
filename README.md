# Hide Help Texts

When the game and mods add help texts to the hud it gets crowded. Do you really need to be reminded that F turns on the flashlight or that there is a keybinding to show Courseplay's debug channels?

This mod allows you to hide selected help texts from the HUD so the ones you actually need are more visible.

## Alpha Release
At the moment this is an alpha release, you should probably not use this. Only a few hardcoded help texts are hidden. 

You can find and alter the list of hidden texts in `FS25_HideHelpTexts.lua`. Future releases will include a configuration to customize which help texts to hide.

When saving the game the mod will log all help texts that were shown during the session to the log file. This can help you identify which help texts you want to hide.


## Features

- Hide selected help texts from the HUD
- (planned) GUI or configuration to customize help texts to hide

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

