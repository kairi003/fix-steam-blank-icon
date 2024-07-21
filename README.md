# fix-steam-blank-icon.bat

Fixes blank icons for Steam games shortcuts.

ref: https://github.com/mrsimb/steam_blank_icon_fix

## Usage
Drag and drop blank steam game shortcuts on `fix-icon.bat`, or run on command prompt like following:

```cmd
fix-icon.bat .\Desktop\game1.url .\Desktop\game2.url ...
```

## What it does
- One reason the game shortcut icon turns into a blank sheet is because the `.ico` file in the Steam installation directory is missing.
  * This can happen if Steam is uninstalled while keeping the game library on another drive.
  * To see exactly which `.ico` file is being referenced, you can open the shortcut with a text editor like notepad.exe.
- From the end of the shortcut URL, you can determine the `gameid`.
- The desired icon can actually be obtained by accessing `https://steamdb.info/app/{gameid}/info/`. Download it and place it where it should be.
  * This script directly refers to the icon URL at `https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/{gameid}/{icon_name}`, but it may change in the future.
