local logger = hs.logger.new("init", "debug")
local hyper = {"ctrl", "alt", "cmd", "shift"}
function sortedbyvalue(inp, f)
    local f = f or function(a, b)
        return a[2] > b[2]
    end
    local temp = {}
    for k,v in pairs(inp) do
        table.insert(temp, {k,v})
    end
    table.sort(temp, f)
    return temp
end
function maxvalue(inp, f)
    local result = nil
    local temp = sortedbyvalue(inp, f)
    if #temp > 0 then
        result = temp[1]
    end
    return result
end
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
function reload_layout(layout)
    hs.timer.doAfter(0.1, function()
        if layout == "Tall" then
            hs.eventtap.keyStroke({"option", "shift" }, "a")
        elseif layout == "Fullscreen" then
            hs.eventtap.keyStroke({"option", "shift" }, "d")
        end
        hs.timer.doAfter(0.1, function()
            hs.eventtap.keyStroke({"cmd", "shift", "alt"}, "z")
        end)
    end)
end
function reloadConfig(files)
    doReload = false
    for _,file in pairs(files) do
        if file:sub(-4) == ".lua" then
            doReload = true
        end
    end
    if doReload then
        hs.reload()
    end
end
myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()

require("hs.ipc")
if hs.ipc.cliInstall("/opt/homebrew/") then
    hs.alert.show("cli installed")
else
    hs.alert.show("cli did't install")
end

hs.hotkey.bind(hyper, "+", function()
    hs.reload()
end)

--  // Window switcher
--local switcher  = require('switcher')
-- Alt-B is bound to the switcher dialog for all apps.
-- Alt-shift-B is bound to the switcher dialog for the current app.

-- Hyper + "app key" launches/switches to the window of the app or cycles through its open windows if already focused
  -- switcherfunc() cycles through all widows of the frontmost app.
-- Hyper + tab cycles to the previously focused app.



-- expose = hs.expose.new(nil,{})
-- hs.hotkey.bind('option','i','Expose',function()expose:toggleShow()end)
--hs.hotkey.bind('option','space',nil,function()hs.hints.windowHints()end)

hs.loadSpoon("WindowHints")
spoon.WindowHints:init()
spoon.WindowHints:start()

hs.loadSpoon("HoldToQuit")
spoon.HoldToQuit:init()
spoon.HoldToQuit:start()

-- hs.loadSpoon("PushToTalk")
-- -- spoon.SpoonInstall:andUse("PushToTalk", {start = true, config = { app_switcher = { ['zoom.us'] = 'push-to-talk' }}})
-- spoon.PushToTalk:init()
-- spoon.PushToTalk.app_switcher = { 
--     ['zoom.us'] = 'push-to-talk',
--     ['com.microsoft.teams'] = 'push-to-talk'
-- }
-- spoon.PushToTalk.detect_on_start = true
-- spoon.PushToTalk:start()
-- function ptt_ipc(scheme, msgID, msg)
--     -- if msgID == 900 then
--     --     return "version:2.0a"
--     -- end
--     msg = msg:sub(2,-1)

--     if msgID == 0 then
--         states = {"push-to-talk", "release-to-talk", "mute", "unmute", "toggle"}
--         if hs.fnutils.contains(states, msg) then
--             if msg == "toggle" then
--             else
--                 states = {msg}
--             end
--             spoon.PushToTalk:toggleStates(states)
--             return "ok"
--         end
--         if msg == "get_state" then
--             return spoon.PushToTalk.state
--         end
--     end
-- end
-- pttport = hs.ipc.localPort("PushToTalk", ptt_ipc)
-- spoon.PushToTalk.menubar:autosaveName("pushtotalk")

-- hs.loadSpoon("ForceTouchMapper")
-- spoon.ForceTouchMapper:init()
-- spoon.ForceTouchMapper.apps = {
--     ["com.microsoft.VSCode"] = {keyStroke = {{"cmd"}, 'Equal'}}
-- }
-- spoon.ForceTouchMapper:start()

-- bind hotkey
hs.hotkey.bind(hyper, '\\', function()
    -- get the focused window
    local win = hs.window.focusedWindow()
    -- get the screen where the focused window is displayed, a.k.a. current screen
    local screen = win:screen()
    -- compute the unitRect of the focused window relative to the current screen
    -- and move the window to the next screen setting the same unitRect 
    -- win:move(win:frame():toUnitRect(screen:frame()), screen:next(), true, 0)
    local nextscreen = screen:next()
    win:moveToScreen(nextscreen, true, false, 0)

    reload_layout()
  end)


autofocus = hs.timer.delayed.new(0.2, function()
            local w = hs.window.focusedWindow()
            -- logger.d(hs.inspect({event="autofocus", w=w}))
            if w then
                local mouse_geometry = hs.mouse.absolutePosition()
                local screen = hs.mouse.getCurrentScreen()
                mouse_geometry = hs.geometry.point({x=mouse_geometry.x, y=mouse_geometry.y})
                window_geometry = w:frame()
                if not mouse_geometry:inside(screen:fullFrame()) or ( mouse_geometry:inside(screen:frame()) and not mouse_geometry:inside(window_geometry)) then
                    hs.mouse.absolutePosition(window_geometry.center)
                end
                autofocus:stop()
            end
        end)
theWindows = hs.window.filter.new()
local function callback_window_focused(w, appName, event)
    autofocus:start()
end
theWindows:subscribe(hs.window.filter.windowFocused, callback_window_focused)



local playwrightfilter = hs.window.filter.new()
playwrightfilter:subscribe(hs.window.filter.windowCreated, function(w, appName, event)
    if w and (appName == "Chromium") then
        local allscreens = hs.screen.allScreens()
        -- local l = hs.logger.new("playwright", "debug")
        local frame = w:frame()
        -- hs.alert.show(frame.x)
        -- hs.alert.show(frame.y)
        local main = hs.screen.mainScreen():currentMode()
        local point = hs.geometry.point({x=main.w*0.99, y=-100})
        local screen = hs.screen.find(point)
        hs.fnutils.some(allscreens, function(s)
            if s then
                local frame = s:frame()
                if point:inside(frame) then
                    screen = s
                    return
                end
            end
        end)
        -- hs.alert.show(main.w)
        -- local screen = hs.screen.find("2")
        -- local screen = hs.screen.find({x=0, y=0})
        if screen then
            w:moveToScreen(screen, true, false, 0)
            reload_layout()
        end
    end
end)



local currentSpaceFilter = hs.window.filter.new(hs.window.filter.defaultCurrentSpace)
hs.hotkey.bind(hyper, 'h', function()
    local win = hs.window.focusedWindow()
    local screen = win:screen()
    local windows = currentSpaceFilter:getWindows()
    win:focusWindowWest(windows)
end)
hs.hotkey.bind(hyper, 's', function()
    local win = hs.window.focusedWindow()
    local screen = win:screen()
    local windows = currentSpaceFilter:getWindows()
    win:focusWindowEast(windows)
end)
hs.hotkey.bind(hyper, 'n', function()
    local win = hs.window.focusedWindow()
    local screen = win:screen()
    local windows = currentSpaceFilter:getWindows()
    win:focusWindowNorth(windows)
end)

hs.hotkey.bind(hyper, 't', function()
    local win = hs.window.focusedWindow()
    local screen = win:screen()
    local windows = currentSpaceFilter:getWindows()
    win:focusWindowSouth(windows)
end)
hs.hotkey.bind(hyper, 'x', function()
    local win = hs.window.focusedWindow()
    local screen = win:screen()
    local spaces = hs.spaces.spacesForScreen(screen)
    local spaceid = hs.spaces.activeSpaceOnScreen(screen)
    local spacewindows = hs.fnutils.map(hs.spaces.windowsForSpace(spaceid), function(el)
        return hs.window.get(el)
    end)
    spoon.WindowHints.addWindowsToSpace(spaces[1], spacewindows)
    hs.timer.doAfter(0.2, function()
        logger.d("spaceid")
        logger.d(hs.spaces.removeSpace(spaceid))
    end)
end)

local bluetoothon = hs.task.new("/opt/homebrew/bin/blueutil", function(i)end, function() end, {"-p", "1"})
local bluetoothoff = hs.task.new("/opt/homebrew/bin/blueutil", function(i)end, function() end, {"-p", "0"})
local bluetoothbose = hs.task.new("/opt/homebrew/bin/blueutil", function(i)end, function() end, {"-p","1", "--connect", "2c-41-a1-01-67-ca"})
 

local sleepwatcher = hs.caffeinate.watcher.new(function(event)
    if event == hs.caffeinate.watcher.systemWillSleep then
        hs.wifi.setPower(false)
        bluetoothoff:start()
    elseif event == hs.caffeinate.watcher.systemDidWake then
        hs.wifi.setPower(true)
        bluetoothbose:start()
    end
end)
sleepwatcher:start()

--   ["1800x1125@2x 120Hz 8bpp"] = {
--     depth = 8.0,
--     freq = 120.0,
--     h = 1125,
--     scale = 2.0,
--     w = 1800
--   },
--   ["1800x1125@2x 47Hz 8bpp"] = {
--     depth = 8.0,
--     freq = 47.0,
--     h = 1125,
--     scale = 2.0,
--     w = 1800
--   },
--   ["1800x1125@2x 48Hz 8bpp"] = {
--     depth = 8.0,
--     freq = 48.0,
--     h = 1125,
--     scale = 2.0,
--     w = 1800
--   },
--   ["1800x1125@2x 50Hz 8bpp"] = {
--     depth = 8.0,
--     freq = 50.0,
--     h = 1125,
--     scale = 2.0,
--     w = 1800
--   },
--   ["1800x1125@2x 59Hz 8bpp"] = {
--     depth = 8.0,
--     freq = 59.0,
--     h = 1125,
--     scale = 2.0,
--     w = 1800
--   },
--   ["1800x1125@2x 60Hz 8bpp"] = {
--     depth = 8.0,
--     freq = 60.0,
--     h = 1125,
--     scale = 2.0,
--     w = 1800
--   },
--   ["1800x1169@2x 120Hz 8bpp"] = {
--     depth = 8.0,
--     freq = 120.0,
--     h = 1169,
--     scale = 2.0,
--     w = 1800
--   },
--   ["1800x1169@2x 47Hz 8bpp"] = {
--     depth = 8.0,
--     freq = 47.0,
--     h = 1169,
--     scale = 2.0,
--     w = 1800
--   },
--   ["1800x1169@2x 48Hz 8bpp"] = {
--     depth = 8.0,
--     freq = 48.0,
--     h = 1169,
--     scale = 2.0,
--     w = 1800
--   },
--   ["1800x1169@2x 50Hz 8bpp"] = {
--     depth = 8.0,
--     freq = 50.0,
--     h = 1169,
--     scale = 2.0,
--     w = 1800
--   },
--   ["1800x1169@2x 59Hz 8bpp"] = {
--     depth = 8.0,
--     freq = 59.0,
--     h = 1169,
--     scale = 2.0,
--     w = 1800
--   },
--   ["1800x1169@2x 60Hz 8bpp"] = {
--     depth = 8.0,
--     freq = 60.0,
--     h = 1169,
--     scale = 2.0,
--     w = 1800
--   },

menubartoggle = hs.menubar.new()
menubartoggle:setTitle("*")
menubartoggle:autosaveName("menubartoggle")
menubartoggle:setMenu( function()
    local uuid = "37D8832A-2D66-02CA-B9F7-8F30A301B230"
    local screen = hs.screen.find(uuid)
    local mode = screen:currentMode()
    local modes = screen:availableModes()
    local smallname = "1800x1125@2x 120Hz 8bpp"
    local bigname = "1800x1169@2x 120Hz 8bpp"
    logger.d(hs.inspect(mode))
    if  mode.desc == smallname then
        mode = modes[bigname]
        screen:setMode(1800, 1169, 2, 120, 8)
    else
        mode = modes[smallname]
        screen:setMode(1800, 1125, 2, 120, 8)
    end
    return {}
end)

hs.loadSpoon("Wallpaper")
spoon.Wallpaper:init()
spoon.Wallpaper:start()

-- hs.loadSpoon("MissionControl")
-- spoon.MissionControl:init({mods=hyper})
-- spoon.MissionControl:start()

-- hs.window.highlight.ui.overlayColor = { 1, 1, 1, 1 }
-- hs.window.highlight.ui.overlay = false
-- hs.window.highlight.ui.frameWidth = 10
-- hs.window.highlight.ui.frameColor = { 0, 0, 0, 0.25 }
-- local filter = hs.window.filter.new()
-- hs.window.highlight.start()

hs.alert.show("Config loaded")