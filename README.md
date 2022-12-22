# Space Manager

This [Hammerspoon](http://www.hammerspoon.org/) config enhances MacOS mission control by providing more functionalities for using keyboard (without mouse) to work with spaces. They are:
* Workspace switcher wrap around.
* Add/Remove workspace.
* Move focused window to a space.
* Move mouse to a monitor.
* Space indicator in menubar or OSD.

## Prerequisites

* [Hammerspoon](http://www.hammerspoon.org/) must be installed.
* Keyboard shortcut for Mission Control -> Move left a space and Move right a space must be default as Control–Left Arrow (⌃←) and Control–Right Arrow (⌃→).

## Usage

- Download and copy `utils.lua`, `spaces.lua` and `space-indicator.lua` in `dot-hammerspoon` to your `~/.hammerspoon`.
- Append content of `dot-hammerspoon/init.lua` to your `~/.hammerspoon/init.lua`.

Default keyboard shortcuts are:
| Command                       | hotkey |
|-------------------------------|--------|
| Move left a space             | ⌘⌃←    |
| Move right a space            | ⌘⌃→    |
| Insert a space                | ⌘⌃↓    |
| Remove last space             | ⌘⌃↑    |
| Move window to left space     | ⌘⌃⇧←   |
| Move window to right space    | ⌘⌃⇧→   |
| Move mouse to previous screen | ⌘⌥⇧↑   |
| Move mouse to next screen     | ⌘⌥⇧↓   |
| Start Space Indicator         | ⌘⌃⌥⇧S  |

## Customization
To set diferent hotkey you can change the value of `spaces.hotkeys[function]`. For example this bind ⌘⌥← to Move left a space and ⌘⌥→ to Move right a space.

```lua
local spaces = require('spaces')
local spaceIndicator = require('space-indicator')

spaces.hotkeys.moveLeftSpace = { mods = {'cmd', 'alt'}, key = 'left' }
spaces.hotkeys.moveLeftSpace = { mods = {'cmd', 'alt'}, key = 'right' }

spaces.insertRemoveSpaceCallback = spaceIndicator.render

spaces.init()
spaceIndicator.init()
```

To add more hotkey to a function you can do something like this:

```lua
...
hs.hotkey.bind({'cmd', 'alt', 'shift'}, 'left', spaces.moveMouseToPreviousScreen)
hs.hotkey.bind({'cmd', 'alt', 'shift'}, 'left', spaces.moveMouseToNextScreen)
...
```

## Reference

Full list of function of spaces module

| Function Name             |
|---------------------------|
| moveLeftSpace             |
| moveRightSpace            |
| insertSpace               |
| removeSpace               |
| moveWindowToLeftSpace     |
| moveWindowToRightSpace    |
| moveMouseToPreviousScreen |
| moveMouseToNextScreen     |