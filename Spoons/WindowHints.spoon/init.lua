local obj = {}
obj.__index = obj
local logger = hs.logger.new("windowHints", "debug")

-- Metadata
obj.name = "WindowHints"
obj.version = "1.0"
obj.author = "Ivan Balashov <ivanbalashov239@gmail.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.apps = {}
local history_path = "~/.hammerspoon/hints.json"
local history = hs.json.read(history_path) or {}
local spaces = {}
local hints = {}
local hintboxes = {}
local windows = {}
local letters = {}
local charcodes = {}
charcodes[49] = "space"
local charorder = "aoeuidhtnspyfgcrlqjkxbwvz:,.'-/@\\[]{}=*+()!#"
-- local charorder = "jkluiopyhnmfdsatgvcewqzx1234567890",

local function newhint(hint)
    local hframe = hs.geometry.new({w=100, h=100})
    local c = hs.canvas.new(hframe)
    c:insertElement({
        type = "rectangle",
        id = "background",
        fillColor = {  red = 1, green = 1, blue = 0},
        canvasAlpha=0.5,
        roundedRectRadii={ xRadius = 10, yRadius = 10 }
    })
    c:insertElement({ 
        type="text",
        -- text=hs.styledtext.new(hint,{
        --     textAlignment="center",
        --     textSize="500"
        -- }),
        text=string.upper(hint),
        textColor= {red=0, green=0, blue=0},
        textAlignment="center",
        textSize=70,
        absoluteSize=false,
        absolutePosition=false,
    })
    return c
end

function obj:get_char(strings)
    -- logger.d("get_char")
    for _, s in pairs(strings) do
        s = string.lower(s)
        -- logger.d("        "..s)
        for c in s:gmatch"." do
            if letters[c] and not self:get_window(c) then
                -- logger.d("        "..c)
                local h = history[s] or {}
                table.insert(h, c)
                history[s] = h
                hs.json.write(history, history_path, true, true)
                return c
            end
        end
    end
end

function obj:callback_window_created(w, appName, event)
    if w and appName and appName ~= "Hammerspoon" then
        -- logger.d(tostring(w:id()).." "..appName.." "..tostring(self:get_hint(w)))
        local hint = self:get_char({ appName, w:title() })
        if hint then
            hints[hint] = w
            windows[w:id()] = hint
            -- hs.alert.show(appName.." "..hint)
            -- logger.d("added"..tostring(w:id()).." "..appName.." "..tostring(self:get_hint(w)))
        end
    end
end
function obj:callback_window_destroyed(w, appName, event)
    if w then
        if windows[w:id()]  then
            hint = windows[w:id()]
            if hint then
                hints[hint] = nil
            end
            windows[w:id()] = nil
            -- logger.d("removed"..tostring(w:id()).." "..appName.." "..tostring(self:get_hint(w)))
        end
    end
end

function obj:get_hint(w)
    -- for nw, hint in pairs(windows) do
    --     hs.alert.show(hint)
    -- end
    return windows[w:id()]
end

function obj:get_window(h)
    -- for nw, hint in pairs(windows) do
    --     hs.alert.show(hint)
    -- end
    return hints[h]
end

local function strim(s)
    return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
 end

local function set_line(canvas, args)
    local args = args or {}
    local canvas = canvas
    local bundleID = args.bundleID
    local hint = args.hint
    local appName = args.appName
    local title = args.title
    local n = args.n
    local i = args.i
    local sframe = args.sframe
    local line_height = args.line_height
    local text = "" 
    if title:sub(-#appName):lower() == appName:lower() then
        title = title:sub(1, -#appName-1)
    elseif title:sub(1, #appName):lower() == appName:lower() then
        title = title:sub(#appName+1, #title)
    end
    local line_height_perc = line_height/sframe.h*100
    if line_height_perc > 20 then
        line_height_perc = 20
    end
    appName = strim(appName)
    title = strim(title)
    text = appName.." "..title
    -- logger.d(text)
    canvas:insertElement({
        type = "rectangle",
        id = "background",
        fillColor = {  red = 0, green = 0, blue = 0},
        canvasAlpha=0.5,
        roundedRectRadii={ xRadius = 20, yRadius = 20 },
        frame = {
            y = tostring(i*line_height_perc+1).."%",
            h = tostring(line_height_perc-1).."%",
            x = "1%",
            w = "99%",
        },
    })
    canvas:insertElement({ 
        type="image",
        absoluteSize=false,
        absolutePosition=false,
        image = hs.image.imageFromAppBundle(bundleID),
        frame = {
            y = tostring(i*line_height_perc+2).."%",
            h = tostring(line_height_perc).."%",
            x = "0%",
            w = "20%",
        },
    })
    local hint_frame = {
            y = tostring(i*line_height_perc+9).."%",
            -- h = tostring(line_height/sframe.h*100).."%",
            x = "10%",
            w = "10%",
            h = "7%",
    }
    canvas:insertElement({
        type = "circle",
        id = "background",
        fillColor = {  red = 1, green = 1, blue = 0},
        canvasAlpha=0.5,
        -- roundedRectRadii={ xRadius = 50, yRadius = 50 },
        -- frame = hint_frame,
        radius = "5%",
        center = {
            y = tostring(i*line_height_perc+12).."%",
            x = "15%",
        },
    })
    canvas:insertElement({ 
        type="text",
        text=hint,
        textColor= {red=0, green=0, blue=0},
        textAlignment="center",
        textSize=40,
        absoluteSize=false,
        absolutePosition=false,
        frame = hint_frame,
    })
    logger.d(title)
    logger.d(#title)
    if #title < 5 then
        text = appName.." "..title
    else
        text = appName
    end
    canvas:insertElement({ 
        type="text",
        text=text,
        textColor= {red=1, green=1, blue=1},
        textAlignment="left",
        textSize=50,
        absoluteSize=false,
        absolutePosition=false,
        frame = {
            y = tostring(i*line_height_perc+2).."%",
            h = tostring(line_height_perc).."%",
            x = "21%",
            w = "79%",
        },
    })
    if #title >= 5 then
        canvas:insertElement({ 
            type="text",
            text=title,
            textColor= {red=1, green=1, blue=1},
            textAlignment="left",
            textSize=30,
            absoluteSize=false,
            absolutePosition=false,
            frame = {
                y = tostring(i*line_height_perc+8).."%",
                h = tostring(line_height_perc).."%",
                x = "21%",
                w = "79%",
            },
        })
    end

    return canvas
end
local hframe = hs.geometry.new({w=500, h=1000})

obj.menu_canvases = {}
-- TODO MAKE IT PER SCREEN AND ON ITERATION ADD NEW TEXT ELEMENTS INSTEAD OF TEXT LINE WITH YOUR OWN COORD CALCULATION
function obj:show_menu(allwindows)
    local screens = {}
    for _, w in pairs(allwindows) do
        local screen = w:screen():getUUID()
        -- logger.d("screen "..tostring(screens[screen]).." "..tostring(screen))
        if screens[screen] then
            table.insert(screens[screen], w) 
        else
            screens[screen] = {}
            table.insert(screens[screen], w) 
        end
    end
    for uuid, windows in pairs(screens) do
        local screen = hs.screen.find(uuid)
        local sframe = screen:frame()
        if self.menu_canvases[screen] then
            self.menu_canvases[screen]:hide()
        end
        sframe.w = sframe.w/3
        local menu_canvas = hs.canvas.new(sframe)
        local n = 0
        for _,w in pairs(windows) do
            n = n + 1
        end
        local line_height = sframe.h/n
        -- logger.d("line_height "..tostring(line_height))
        -- menu_canvas:insertElement({
        --     type = "rectangle",
        --     id = "background",
        --     fillColor = {  red = 0, green = 0, blue = 0},
        --     canvasAlpha=0.5,
        --     roundedRectRadii={ xRadius = 10, yRadius = 10 },
        -- })
        -- logger.d(" text "..tostring(#windows))
        local i = 0
        for _,w in pairs(windows) do
            local hint = self:get_hint(w)
            if not hint then
                self:callback_window_created(w, w:application():name(), "created")
            end
            hint = self:get_hint(w)
            if hint then
                hint = string.upper(tostring(hint))
                menu_canvas = set_line(menu_canvas, {
                    hint=hint,
                    appName=w:application():name(),
                    title=w:title(),
                    n=n,
                    i=i,
                    sframe=sframe,
                    bundleID=w:application():bundleID(),
                    line_height = line_height
                })
                i = i + 1
            end
        end
        -- logger.d(text)
        menu_canvas:show()
        menu_canvas:bringToFront(true)
        self.menu_canvases[screen] = menu_canvas
    end
end
function obj:hide_menu()
    for _, menu in pairs(self.menu_canvases) do
        menu:hide()
    end
end
function obj:show_hints()
    -- logger.d("show_hints")
    -- for h, w in pairs(hints) do
        -- logger.d(h.." "..w:application():name()..w:title())
    -- end
    if obj.event_start_flags then
        local visiblewindows = {}
        local otherwindows = {}
        local normal = hs.window.filter.new(hs.window.filter.default):getWindows()
        local allwindows = hs.window.orderedWindows()
        hs.fnutils.each(allwindows, function(window)
            if hs.fnutils.contains(normal, window ) then
                local wframe = window:frame()
                for _, w in pairs(visiblewindows) do
                    if wframe:intersect(w:frame()).area >= wframe.area*0.95 then
                        -- logger.d(w:id().." "..w:application():name().." "..w:title().." already")
                        -- logger.d(window:id().." "..window:application():name().." "..window:title().." behind and smaller")
                        return
                    end
                end
                visiblewindows[window:id()] = window
            end
        end)
        for _,w in pairs(normal) do
            if not hs.fnutils.contains(visiblewindows, w ) then
                otherwindows[w:id()] = w 
            end
        end
        for _,w in pairs(visiblewindows) do
            if w then
                local hint = self:get_hint(w)
                if not hint then
                    self:callback_window_created(w, w:application():name(), "created")
                end
                hint = self:get_hint(w)
                -- logger.d(w:id().." "..w:application():name().." "..w:title().." "..tostring(hint))
                if hint then
                    local wframe = w:frame()
                    local c = hintboxes[hint]
                    local hframe = c:frame()
                    hframe.center = wframe.center
                    c:frame({w=100, h=100, x=wframe.x+wframe.w/2, y=wframe.y+wframe.h/2})
                    c:show()
                    c:bringToFront(true)
                end
            end
        end
        self:show_menu(otherwindows)
    end
end
function obj:hide_hints()
    for hint, hintbox in pairs(hintboxes) do
        hintbox:hide()
    end
    self:hide_menu()
end
function obj:switcher(args)
    self.event_start_flags = {}
    self.eventtap:start()
    self:show_hints()
end
function obj.windowsForSpace(spaceid)
    return spaces[spaceid]
end
obj.filter = hs.window.filter.new(hs.window.filter.default)
function obj.addWindowsToSpace(spaceid, windows)
    local spaceid = spaceid
    local screen = hs.mouse.getCurrentScreen()
    local layout = nil
    local normalwindows = obj.filter:getWindows()
    local windows = windows or {}
    if #windows > 0 then
        if not spaceid then
            local spaces = hs.spaces.spacesForScreen(screen)
            if #windows > 1 then
                -- logger.d("looking for spaceid")
                layout = "Tall"
                for i, space in pairs(spaces) do
                    -- logger.d(tostring(i).." "..tostring(space))
                    -- local spw = hs.spaces.windowsForSpace(space)
                    local spw = hs.fnutils.filter(hs.spaces.windowsForSpace(space), function(el)
                        if hs.fnutils.contains(normalwindows, hs.window.get(el)) then
                            return true
                        end
                    end)
                    -- logger.d(tostring(space).." windows="..tostring(#spw))
                    if #spw == #windows and hs.fnutils.every(windows, function(el) return hs.fnutils.contains(spw, el:id()) end) then
                        -- logger.d("using existing space")
                        spaceid = space
                        if not spaceid == hs.spaces.activeSpaceOnScreen(screen) then
                            hs.spaces.gotoSpace(spaceid)
                        end
                        return
                    elseif i > 1 and #spw == 0 then
                        -- logger.d("reusing an empty one")
                        spaceid = space
                        break
                    elseif i == #spaces then
                        -- logger.d("created a new one")
                        hs.spaces.addSpaceToScreen(screen, false)
                        local lspaces = hs.spaces.spacesForScreen(screen)
                        spaceid = lspaces[#lspaces]
                        break
                    end
                end
            else
                -- logger.d("using fullscreen space")
                spaceid = spaces[1]
            end
        else
            screen = hs.screen.find(hs.spaces.spaceDisplay(spaceid))
        end
        -- local spw = hs.spaces.windowsForSpace(spaceid)
        local spw = hs.fnutils.filter(hs.spaces.windowsForSpace(spaceid), function(el)
            if hs.fnutils.contains(normalwindows, hs.window.get(el)) then
                return true
            end
        end)
        local another_screen = nil
        for _,s in pairs(hs.screen.allScreens()) do
            if s ~= screen then
                another_screen = s
            end
        end
        if another_screen then
            local current_space=hs.spaces.activeSpaceOnScreen(screen) 
            -- logger.d("space is "..tostring(spaceid))
            for i, w in pairs(windows) do
                if not hs.fnutils.contains(spw, w:id()) then
                    -- logger.d("moved out "..w:application():name())
                    w:moveToScreen(another_screen, true, false, 0)
                else
                    w:focus()
                end
            end
            -- logger.d("switched to space "..tostring(spaceid))
            if not spaceid == current_space then
                hs.spaces.gotoSpace(spaceid)
            end
            -- logger.d("start timer")
            hs.timer.doAfter(0.2, function()
                -- logger.d("started timedout function")
                for _, w in pairs(windows) do
                    hs.timer.doAfter(0.2, function()
                        if not hs.fnutils.contains(spw, w:id()) then
                            w:moveToScreen(screen, true, false, 0)
                            -- logger.d(w:application():name().." moved to space on your screen")
                        else
                            w:focus()
                        end
                        -- w:move(screen:frame(), screen, nil, 0)
                    end)
                end
                -- reload_layout(layout)
                hs.timer.doAfter(0.5, function()
                    reload_layout(layout)
                    windows[1]:focus()
                    reload_layout(layout)
                end)
                -- logger.d("moved to space on your screen")
            end)
        else
            hs.alert.show("needs a dummy screen to move windows to other spaces")
        end
    end
end
--- WindowHints:init()
--- Method
--- Init WindowHints
---
--- Parameters:
---  * args
--- args.mods
--- args.key
--- args.charorder
function obj:init(args)
    local args = args or {}
    local mods = args.mods or {"cmd"}
    self.mods = mods
    local key = args.key or "space"
    self.key = key
    local charorder = args.charorder or charorder
    for c in charorder:gmatch"." do
        letters[c] = c
        charcodes[hs.keycodes.map[c]] = c
        hintboxes[c] = newhint(c)
    end
    self.screentimer = hs.timer.new(1, function()
        self.screentimer:stop()
        -- logger.d("screen timer fired")
        local screens = hs.screen.allScreens()
        local n = 0
        local dummy = 0
        for _,s in pairs(screens) do
            -- logger.d(s:name():gmatch(".*"))
            if not string.find(s:name(), "Dummy") then
                n = n + 1
            else
                dummy = dummy + 1
            end
        end
        if n == 1 and dummy == 0 then
            hs.osascript.applescriptFromFile("enable_dummy_screens.osa") 
        elseif n > 1 and dummy > 0 then
            hs.osascript.applescriptFromFile("disable_dummy_screens.osa") 
        end
    end)
    self.screenwatcher = hs.screen.watcher.new(function()
        self.screentimer:stop()
        self.screentimer:start()
    end)
    self.eventtap = hs.eventtap.new({hs.eventtap.event.types.keyUp, hs.eventtap.event.types.keyDown, hs.eventtap.event.types.flagsChanged}, function(event)
        local flags = event:getFlags()
        local keycode = event:getKeyCode()
        local char = charcodes[keycode]
        local keydown = hs.eventtap.event.types[event:getType()] == "keyDown"
        local keyup = not keydown
        -- for i, flag in pairs(flags) do
        --     logger.d(tostring(i).." flag "..tostring(flag))
        -- end
        local function exit()
            -- hs.alert.show("stop eventtap")
            self.event_start_flags = {}
            self.eventtap:stop()
            self:hide_hints()
            -- logger.d("hintseventtap stopped")
            if self.selecting then
                self.addWindowsToSpace(nil, self.selected)
            end
            self.selecting = false
            return false
        end
        -- logger.d("hintseventtap keycode="..tostring(keycode).." key="..tostring(char).." originalkey="..tostring(hs.keycodes.map[keycode]).." keyDown="..tostring(keydown))
        if not hs.fnutils.some(self.event_start_flags, function() return true end) then
            self.event_start_flags = flags
            self.selected = {}
            -- logger.d("hintseventtap started")
            if char == self.key then
                -- logger.d("key "..self.key)
                return false
            end
        end
        if char and keyup then
            if char == self.key then
                self.selecting = not self.selecting
            end
            local window = self:get_window(char)
            -- hs.alert.show(tostring(window).." "..char.." "..tostring(keycode).." "..tostring(keydown).." "..tostring(keyup))
            if window then
                if self.selecting then
                    -- logger.d("selected "..window:title())
                    table.insert(self.selected, window)
                else
                    window:focus()
                    return exit()
                end
            end
        else
            local running = true
            for _, name in pairs(self.mods) do
                -- hs.alert.show(name)
                running = running and flags[name]
            end
            if not running then
                return exit()
            end
        end
        self.event_start_flags = flags
        -- hs.alert.show(" "..char.." "..tostring(keycode).." "..tostring(keydown).." "..tostring(keyup))
        return true
    end)
end

--- WindowHints:start()
--- Method
--- Start WindowHints
---
--- Parameters:
---  * None
function obj:start()
    -- self.eventtap = {}
    -- self.eventtap = hs.eventtap.new({hs.eventtap.event.types.gesture},
    --                                 hs.fnutils.partial(self.pressure_handler,

    --                                                    self))
    -- self.eventtap:start()

    local windows = self.filter:getWindows()
    for _,w in pairs(windows) do
        if w then
            self:callback_window_created(w, w:application():name(), "created")
        end
    end

    local function fc(...)
        self:callback_window_created(...)
    end
    local function fd(...)
        self:callback_window_destroyed(...)
    end
    self.filter:subscribe(hs.window.filter.windowCreated, fc)
    self.filter:subscribe(hs.window.filter.windowDestroyed, fd)
    self.screenwatcher:start()
    -- self.filter:subscribe({hs.window.filter.windowInCurrentSpace, hs.window.filter.windowNotInCurrentSpace}, function(w, appName, event)
    --     if w then
    --         local screen = w:screen()
    --         local spaceid = hs.spaces.activeSpaceOnScreen(screen)
    --         local spw = spaces[spaceid]
    --         if spw then
    --         else
    --             spw = {}
    --         end
    --         if event == "windowInCurrentSpace" then
    --             table.insert(spw, w:id())
    --         else
    --             for i, s in pairs(spw) do
    --                 if s == w:id() then
    --                     table.remove(spw, i)
    --                     break
    --                 end
    --             end
    --         end
    --         spaces[spaceid] = spw
    --         -- local normalwindows = self.filter:getWindows()
    --         -- local spw = hs.spaces.windowsForSpace(spaceid)
    --         -- local spw = hs.fnutils.filter(hs.spaces.windowsForSpace(spaceid), function(el)
    --         --             if hs.fnutils.contains(normalwindows, hs.window.get(el)) then
    --         --                 return true
    --         --             end
    --         -- end)
    --         -- spaces[spaceid] = spw
    --         logger.d(event.." "..tostring(spaceid).." updated spaces "..#spw)
    --     end
    -- end)
    hs.hotkey.bind(obj.mods, obj.key, function(...)
        self:switcher(...)
    end)
    return obj
end



return obj
