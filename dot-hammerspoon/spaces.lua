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
  if not currentWindow then return end

  local currentScreen = currentWindow:screen()
  local mouseScreen = hs.mouse.getCurrentScreen()
  local screenSpaces = hs.spaces.spacesForScreen(currentScreen)

  if #screenSpaces <= 1 then return end

  local activeSpace = hs.spaces.activeSpaceOnScreen(currentScreen)
  local index = utils.findIndex(screenSpaces, activeSpace)
  local nextIndex = utils.getNextIndex(index, #screenSpaces, direction)

  -- Calculate steps and actual key direction, handling wrap-around
  local steps, actualKey
  if direction == 'right' and index == #screenSpaces then
    steps = #screenSpaces - 1
    actualKey = 'left'
  elseif direction == 'left' and index == 1 then
    steps = #screenSpaces - 1
    actualKey = 'right'
  else
    steps = 1
    actualKey = utils.ternary(direction == 'left', 'left', 'right')
  end

  if steps == 0 then return end

  cache.setAnimating()

  if currentScreen ~= mouseScreen then
    cache.moveMouseToCenterScreen(currentScreen)
  end

  -- Ensure window is frontmost before grabbing
  currentWindow:unminimize()
  currentWindow:raise()
  currentWindow:focus()

  local frame = currentWindow:frame()
  local originalFrame = { x = frame.x, y = frame.y, w = frame.w, h = frame.h }
  local clickPos = { x = frame.x + 50, y = frame.y + 10 }
  local centerPos = { x = frame.x + frame.w / 2, y = frame.y + frame.h / 2 }

  local function releaseAndRestore()
    local finalPos = hs.mouse.absolutePosition()
    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, finalPos):post()
    hs.timer.doAfter(0.05, function()
      if currentWindow:isVisible() then
        currentWindow:setFrame(originalFrame)
      end
      currentWindow:raise()
      currentWindow:focus()
      hs.mouse.absolutePosition(centerPos)
    end)
  end

  local function pressKeyStep(remaining)
    hs.eventtap.event.newKeyEvent('ctrl', true):post()
    hs.timer.doAfter(0.02, function()
      hs.eventtap.event.newKeyEvent(actualKey, true):post()
      hs.timer.doAfter(0.02, function()
        hs.eventtap.event.newKeyEvent(actualKey, false):post()
        hs.eventtap.event.newKeyEvent('ctrl', false):post()
        if remaining > 1 then
          hs.timer.doAfter(0.4, function() pressKeyStep(remaining - 1) end)
        else
          hs.timer.doAfter(0.6, releaseAndRestore)
        end
      end)
    end)
  end

  -- Step 1: move mouse to title bar
  hs.mouse.absolutePosition(clickPos)
  hs.timer.doAfter(0.05, function()
    -- Step 2: mouse down
    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, clickPos):post()
    hs.timer.doAfter(0.1, function()
      -- Step 3: tiny drag to register grab gesture
      local dragPos = { x = clickPos.x + 1, y = clickPos.y }
      hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDragged, dragPos)
        :setProperty(hs.eventtap.event.properties.mouseEventDeltaX, 1)
        :post()
      -- Step 4: fire key steps
      hs.timer.doAfter(0.05, function() pressKeyStep(steps) end)
    end)
  end)
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
hs.urlevent.bind('moveleftspace', module.moveLeftSpace)
hs.urlevent.bind('moverightspace', module.moveRightSpace)
hs.urlevent.bind('insertspace', module.insertSpace)
hs.urlevent.bind('removespace', module.removeSpace)
hs.urlevent.bind('movewindowtoleftspace', module.moveWindowToLeftSpace)
hs.urlevent.bind('movewindowtorightspace', module.moveWindowToRightSpace)
hs.urlevent.bind('movemousetopreviousscreen', module.moveMouseToPreviousScreen)
hs.urlevent.bind('movemousetonextscreen', module.moveMouseToNextScreen)

return module
