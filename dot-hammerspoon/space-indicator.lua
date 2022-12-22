local utils = require('utils')

local cache = {
  alertIcon = '⬜',
  alertActiveIcon = '🔳',
  icon = '▧',
  activeIcon = '□',
  menuBar = hs.menubar.new(false),
  previousScreen = hs.screen.mainScreen()
}

cache.hotkeyToString = function(hotkey)
  return utils.ternary(utils.hasValue(hotkey.mods, 'cmd') or utils.hasValue(hotkey.mods, 'command'), '⌘', '')
    .. utils.ternary(utils.hasValue(hotkey.mods, 'ctrl') or utils.hasValue(hotkey.mods, 'control'), '⌃', '')
    .. utils.ternary(utils.hasValue(hotkey.mods, 'alt') or utils.hasValue(hotkey.mods, 'option'), '⌥', '')
    .. utils.ternary(utils.hasValue(hotkey.mods, 'shift'), '⇧', '')
    .. ' + ' .. string.upper(hotkey.key)
end

cache.render = function()
  local activeScreen = hs.screen.mainScreen()
  local currentScreen = hs.mouse.getCurrentScreen()
  local screenSpaces = hs.spaces.spacesForScreen(currentScreen)
  local activeSpace = hs.spaces.activeSpaceOnScreen(currentScreen)
  local menuBarContent = ''
  local alertContent = ''

  for i = 1, #screenSpaces do
    if screenSpaces[i] == activeSpace then
      menuBarContent = menuBarContent .. cache.activeIcon
      alertContent = alertContent .. cache.alertActiveIcon
    else
      menuBarContent = menuBarContent .. cache.icon
      alertContent = alertContent .. cache.alertIcon
    end
  end

  if module.enableAlert then
    if module.alertOnScreenChange or cache.previousScreen == activeScreen then
      hs.alert.closeAll(0)
      hs.alert(alertContent, {radius=10, textSize=50}, currentScreen)
    end
  end

  cache.menuBar:setTitle(menuBarContent)
end

local spaceWatcher = hs.spaces.watcher.new(cache.render)
local screenWatcher = hs.screen.watcher.newWithActiveScreen(function()
  cache.render()
  cache.previousScreen = hs.screen.mainScreen()
end)

module = {
  hotkey = { mods = {'cmd', 'ctrl', 'alt', 'shift'}, key = 's'},
  name = 'space-indicator',
  enableMenuBarIcon = true,
  enableAlert = true,
  alertOnScreenChange = false,
  render = cache.render
}

module.init = function()
  utils.loadSetting(module, 'enableMenuBarIcon', true)
  utils.loadSetting(module, 'enableAlert', true)
  utils.loadSetting(module, 'alertOnScreenChange', false)

  if module.hotkey then
    hs.hotkey.bind(module.hotkey.mods, module.hotkey.key, module.start)
  end

  module.start()
  module.initMenu()
end

module.initMenu = function()
  module.setMenu({
    {
      title = 'Options',
      menu = {
        {
          title = 'Enable Menubar Icon',
          checked = module.enableMenuBarIcon,
          tooltip = utils.ternary(module.enableMenuBarIcon, 'Hide  Menubar Icon. Press ' .. cache.hotkeyToString(module.hotkey) .. ' to show the icon again.', nil),
          fn = function()
            utils.saveSetting(module, 'enableMenuBarIcon', not module.enableMenuBarIcon)
            module.initMenu()

            if module.enableMenuBarIcon then
              module.showMenubar()
            else
              module.hideMenubar()
            end
          end
        },
        {
          title = 'Enable Alert',
          checked = module.enableAlert,
          fn = function()
            utils.saveSetting(module, 'enableAlert', not module.enableAlert)
            module.initMenu()
          end
        },
        {
          title = 'Alert On Active Screen Change',
          checked = module.alertOnScreenChange,
          disabled = not module.enableAlert,
          fn = function()
            utils.saveSetting(module, 'alertOnScreenChange', not module.alertOnScreenChange)
            module.initMenu()
          end
        }
      }
    },
    {
      title = '-'
    },
    {
      title = 'Quit',
      tooltip = 'Stop Space Indicator. Press ' .. cache.hotkeyToString(module.hotkey) .. ' to start again.',
      fn = function()
        module:stop()
      end
    }
  })
end

module.setClickCallback = function(modifiers)
  cache.menuBar:setClickCallback(modifiers)
end

module.setMenu = function(menuTable)
  cache.menuBar:setMenu(menuTable)
end

module.start = function()
  cache.menuBar:returnToMenuBar()
  cache.render()

  spaceWatcher:start()
  screenWatcher:start()

  if module.watcherInterval and module.watcherInterval > 0 then
    if module.timer then
      module.timer:start()
    else
      module.timer = hs.timer.doEvery(module.watcherInterval, function()
        local currentScreen = hs.mouse.getCurrentScreen()
        local screenSpaces = hs.spaces.spacesForScreen(currentScreen)

        if cache.previousNumberOfSpaces ~= #screenSpaces then
          cache.render()
        end

        cache.previousNumberOfSpaces = #screenSpaces
      end):start()
    end
  end

  hs.timer.doAfter(10, function()
    if not module.enableMenuBarIcon then
      cache.menuBar:removeFromMenuBar()
    end
  end)
end

module.stop = function()
  cache.menuBar:removeFromMenuBar()
  spaceWatcher:stop()
  screenWatcher:stop()

  if module.timer then
    module.timer:stop()
  end
end

module.showMenubar = function()
  cache.menuBar:returnToMenuBar()
end

module.hideMenubar = function()
  cache.menuBar:removeFromMenuBar()
end

return module