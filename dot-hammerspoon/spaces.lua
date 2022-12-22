local utils = require('utils')

local cache = {}
cache.isAnimating = false

cache.watcher = hs.spaces.watcher.new(function()
  cache.resetAnimating()
end)

cache.setAnimating = function()
  cache.isAnimating = true
  cache.timer = hs.timer.doAfter(1, cache.resetAnimating)
end

cache.resetAnimating = function()
  cache.isAnimating = false

  if cache.timer then
    cache.timer:stop()
    cache.timer = nil
  end

  if cache.spaceToRemove then
    hs.spaces.removeSpace(cache.spaceToRemove)
    cache.spaceToRemove = false

    if type(module.insertRemoveSpaceCallback) == 'function' then
      module.insertRemoveSpaceCallback()
    end
  end
end

cache.performIfNotAnimating = function(callback)
  if not cache.isAnimating then
    callback()
  end
end

cache.moveToSpace = function(fromIndex, toIndex)
  if fromIndex == toIndex then
    return
  end

  cache.setAnimating()

  local direction = utils.ternary(toIndex < fromIndex, 'left', 'right')

  hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, true):post()
  for i = 1, math.abs(toIndex - fromIndex) do
    hs.eventtap.event.newKeyEvent(direction, true):post()
    hs.eventtap.event.newKeyEvent(direction, false):post()
  end
  hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, false):post()
end

cache.moveOneSpace = function(direction)
  local currentScreen = hs.mouse.getCurrentScreen()
  local screenSpaces = hs.spaces.spacesForScreen(currentScreen)

  if #screenSpaces > 1 then
    local activeSpace = hs.spaces.activeSpaceOnScreen(currentScreen)
    local index = utils.findIndex(screenSpaces, activeSpace)
    local nextIndex = utils.getNextIndex(index, #screenSpaces, direction)

    cache.moveToSpace(index, nextIndex)
  end
end

cache.moveWindowOneSpace = function(direction)
  local currentWindow = hs.window.focusedWindow()

  if currentWindow == nil then
    return
  end

  local currentScreen = currentWindow:screen()
  local mouseScreen = hs.mouse.getCurrentScreen()
  local screenSpaces = hs.spaces.spacesForScreen(currentScreen)

  if #screenSpaces > 1 then
    local activeSpace = hs.spaces.activeSpaceOnScreen(currentScreen)
    local index = utils.findIndex(screenSpaces, activeSpace)
    local nextIndex = utils.getNextIndex(index, #screenSpaces, direction)

    if currentScreen ~= mouseScreen then
      cache.moveMouseToCenterScreen(currentScreen)
    end

    cache.moveToSpace(index, nextIndex)
    hs.spaces.moveWindowToSpace(currentWindow, screenSpaces[nextIndex])
  end
end

cache.moveMouseToCenterScreen = function(screen)
  local rect = screen:fullFrame()
  local center = hs.geometry.rectMidPoint(rect)

  hs.mouse.absolutePosition(center)
end

cache.moveMouseOneScreen = function(direction)
  local allScreens = hs.screen.allScreens()

  if #allScreens > 1 then
    local currentScreen = hs.mouse.getCurrentScreen()
    local index = utils.findIndex(allScreens, currentScreen)
    local nextIndex = utils.getNextIndex(index, #allScreens, direction)

    cache.moveMouseToCenterScreen(allScreens[nextIndex])
  end
end

-- Module

local module = {
  hotkeys = {
    moveLeftSpace = { mods = {'cmd', 'ctrl'}, key = 'left' },
    moveRightSpace = { mods = {'cmd', 'ctrl'}, key = 'right' },
    insertSpace = { mods = {'cmd', 'ctrl'}, key = 'down'},
    removeSpace = { mods = {'cmd', 'ctrl'}, key = 'up'},
    moveWindowToLeftSpace = { mods = {'cmd', 'ctrl', 'shift'}, key = 'left'},
    moveWindowToRightSpace = { mods = {'cmd', 'ctrl', 'shift'}, key = 'right'},
    moveMouseToPreviousScreen = { mods = {'cmd', 'alt', 'shift'}, key = 'up'},
    moveMouseToNextScreen = { mods = {'cmd', 'alt', 'shift'}, key = 'down'}
  },
  insertRemoveSpaceCallback = nil
}

module.init = function()
  local funcs = {
    'moveLeftSpace', 'moveRightSpace',
    'insertSpace', 'removeSpace',
    'moveWindowToLeftSpace', 'moveWindowToRightSpace',
    'moveMouseToPreviousScreen', 'moveMouseToNextScreen'
  }

  for i = 1, #funcs do
    local func = funcs[i]

    if module.hotkeys[func] and type(module[func]) == 'function' then
      local hotkey = module.hotkeys[func]

      hs.hotkey.bind(hotkey.mods, hotkey.key, module[func])
    end
  end

  cache.watcher:start()
end

module.isAnimating = function()
  return cache.isAnimating
end

module.moveLeftSpace = function()
  cache.performIfNotAnimating(function()
    cache.moveOneSpace('left')
  end)
end

module.moveRightSpace = function()
  cache.performIfNotAnimating(function()
    cache.moveOneSpace('right')
  end)
end

module.moveWindowToLeftSpace = function()
  cache.performIfNotAnimating(function()
    cache.moveWindowOneSpace('left')
  end)
end

module.moveWindowToRightSpace = function()
  cache.performIfNotAnimating(function()
    cache.moveWindowOneSpace('right')
  end)
end

module.insertSpace = function()
  cache.performIfNotAnimating(function()
    local currentScreen = hs.mouse.getCurrentScreen()
    hs.spaces.addSpaceToScreen(currentScreen)

    if type(module.insertRemoveSpaceCallback) == 'function' then
      module.insertRemoveSpaceCallback()
    end
  end)
end

module.removeSpace = function()
  cache.performIfNotAnimating(function()
    local currentScreen = hs.mouse.getCurrentScreen()
    local screenSpaces = hs.spaces.spacesForScreen(currentScreen)

    if #screenSpaces > 1 then
      local activeSpace = hs.spaces.activeSpaceOnScreen(currentScreen)

      if (activeSpace == screenSpaces[#screenSpaces]) then
        cache.spaceToRemove = activeSpace
        cache.moveOneSpace('left')
      else
        hs.spaces.removeSpace(screenSpaces[#screenSpaces])

        if type(module.insertRemoveSpaceCallback) == 'function' then
          module.insertRemoveSpaceCallback()
        end
      end
    end
  end)
end

module.moveMouseToNextScreen = function()
  cache.moveMouseOneScreen('right')
end

module.moveMouseToPreviousScreen = function()
  cache.moveMouseOneScreen('left')
end

-- URL Events
hs.urlevent.bind('moveLeftSpace', module.moveLeftSpace)
hs.urlevent.bind('moveRightSpace', module.moveRightSpace)
hs.urlevent.bind('insertSpace', module.insertSpace)
hs.urlevent.bind('removeSpace', module.removeSpace)
hs.urlevent.bind('moveWindowToLeftSpace', module.moveWindowToLeftSpace)
hs.urlevent.bind('moveWindowToRightSpace', module.moveWindowToRightSpace)
hs.urlevent.bind('moveMouseToPreviousScreen', module.moveMouseToPreviousScreen)
hs.urlevent.bind('moveMouseToNextScreen', module.moveMouseToNextScreen)

return module