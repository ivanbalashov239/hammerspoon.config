local logger = hs.logger.new("init", "debug")
local hyper = {"ctrl", "alt", "cmd", "shift"}
-- function sortedbyvalue(inp, f)
--     local f = f or function(a, b)
--         return a[2] > b[2]
--     end
--     local temp = {}
--     for k,v in pairs(inp) do
--         table.insert(temp, {k,v})
--     end
--     table.sort(temp, f)
--     return temp
-- end
-- function maxvalue(inp, f)
--     local result = nil
--     local temp = sortedbyvalue(inp, f)
--     if #temp > 0 then
--         result = temp[1]
--     end
--     return result
-- end
-- function deepcopy(orig)
--     local orig_type = type(orig)
--     local copy
--     if orig_type == 'table' then
--         copy = {}
--         for orig_key, orig_value in next, orig, nil do
--             copy[deepcopy(orig_key)] = deepcopy(orig_value)
--         end
--         setmetatable(copy, deepcopy(getmetatable(orig)))
--     else -- number, string, boolean, etc
--         copy = orig
--     end
--     return copy
-- end
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

hs.loadSpoon("PushToTalk")
-- spoon.SpoonInstall:andUse("PushToTalk", {start = true, config = { app_switcher = { ['zoom.us'] = 'push-to-talk' }}})
spoon.PushToTalk:init()
spoon.PushToTalk.app_switcher = { 
    ['zoom.us'] = 'push-to-talk',
    ['com.microsoft.teams'] = 'push-to-talk'
}
spoon.PushToTalk.detect_on_start = true
spoon.PushToTalk:start()
function ptt_ipc(scheme, msgID, msg)
    -- if msgID == 900 then
    --     return "version:2.0a"
    -- end
    msg = msg:sub(2,-1)

    if msgID == 0 then
        states = {"push-to-talk", "release-to-talk", "mute", "unmute", "toggle"}
        if hs.fnutils.contains(states, msg) then
            if msg == "toggle" then
            else
                states = {msg}
            end
            spoon.PushToTalk:toggleStates(states)
            return "ok"
        end
        if msg == "get_state" then
            return spoon.PushToTalk.state
        end
    end
end
pttport = hs.ipc.localPort("PushToTalk", ptt_ipc)

hs.loadSpoon("ForceTouchMapper")
-- spoon.ForceTouchMapper:init()
-- spoon.ForceTouchMapper.apps = {
--     ["com.microsoft.VSCode"] = {keyStroke = {{"cmd"}, 'Equal'}}
-- }
spoon.ForceTouchMapper:start()

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


theWindows = hs.window.filter.new()
local function callback_window_focused(w, appName, event)
    if w then
        -- if window_geometry:inside()
        hs.timer.doAfter(0.2, function()
            local mouse_geometry = hs.mouse.absolutePosition()
            mouse_geometry = hs.geometry.point({x=mouse_geometry.x, y=mouse_geometry.y})
            window_geometry = w:frame()
            if not mouse_geometry:inside(window_geometry) then
                hs.mouse.absolutePosition(window_geometry.center)
            end
            -- hs.alert.show(spoon.WindowHints:get_hint(w))
        end)
    end
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


hs.loadSpoon("MissionControl")
spoon.MissionControl:init({mods=hyper})
spoon.MissionControl:start()

hs.alert.show("Config loaded")