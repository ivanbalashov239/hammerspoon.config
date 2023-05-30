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
local launcher = {}
local function set_launcher()
    local perapp = {}
    for hint, byid in pairs(history) do
        for id, counter in pairs(byid) do
            local el = perapp[id] or {}
            el[hint] = counter
            perapp[id] = el
        end
    end
    for id, hints in pairs(perapp) do
        perapp[id] = maxvalue(hints)
    end

    local temphistory = deepcopy(history)
    for hint, byid in pairs(temphistory) do
        local b = sortedbyvalue(byid)
        for _, k in ipairs(b) do
            local id = k[1]
            local counter = k[2]
            if counter > 90 then
                -- logger.d(hint.." "..tostring(id).."="..tostring(counter))
                -- logger.d(hs.inspect(perapp[id]))
                if perapp[id] and perapp[id][1] == hint then
                    perapp[id] = nil
                    byid[id] = nil
                    if #b == 1 then
                        byid = nil
                    end
                    temphistory[hint] = byid
                    launcher[hint] = id
                    launcher[id] = hint
                    logger.d("launcher "..hint.." "..id)
                end
            end
        end
    end
    -- for hint, byid in pairs(temphistory) do
    --     -- logger.d(hint.." " ..hs.inspect(byid))
    --     if byid and not byid == {} then
    --         local mv = maxvalue(byid)[1]
    --         launcher[hint] = mv
    --         launcher[mv] = hint
    --         logger.d("launcher "..hint.." "..launcher[hint])
    --     end
    -- end
    -- logger.d(hs.inspect(launcher))
end
set_launcher()
hs.timer.doEvery(120,set_launcher)
local spaces = {}
local screen_hints = {}
local hints = {}
local hintboxes = {}
local hintboxcolor = {  red = 1, green = 1, blue = 0}
local hintboxselectedcolor = {  red = 0.5, green = 0.5, blue = 0.9}
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
        id = "hintbox"..string.lower(hint),
        fillColor = hintboxcolor,
        canvasAlpha=0.5,
        roundedRectRadii={ xRadius = 20, yRadius = 20 }
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
        textSize=hframe.h,
        absoluteSize=false,
        absolutePosition=false,
        frame = {
            x = 0,
            y = -10,
            w = hframe.w,
            h = hframe.h,
        },
    })
    return c
end

function obj:get_char(strings, bundleID)
    -- logger.d("get_char")
    for _, s in pairs(strings) do
        s = string.lower(s)
        -- logger.d("        "..s)
        if launcher[bundleID] and not self:get_window(launcher[bundleID]) then
            return launcher[bundleID]
        end
        for c in s:gmatch"." do
            if letters[c] and not launcher[c] and not self:get_window(c) then
                -- logger.d("        "..c)
                if bundleID then
                    local byid = history[c] or {}
                    local counter = byid[bundleID] or 0
                    counter = counter + 1
                    byid[bundleID] = counter
                    history[c] = byid
                    hs.json.write(history, history_path, true, true)
                end
                return c
            end
        end
    end
end

local normalfilter = hs.window.filter.new(hs.window.filter.default)
function obj:callback_window_created(w, appName, event)
    if w and appName and not hs.fnutils.contains({"Hammerspoon", "Amethyst"}, appName) then
        -- logger.d(tostring(w:id()).." "..appName.." "..tostring(self:get_hint(w)))
        if windows[w:id()] then
            return
        end
        local normalwindows = normalfilter:getWindows()
        if hs.fnutils.contains(normalwindows, w) then
            local hint = self:get_char({ appName, w:title() }, w:application():bundleID())
            if hint then
                hints[hint] = w
                windows[w:id()] = hint
                -- hs.alert.show(appName.." "..hint)
                -- logger.d("added"..tostring(w:id()).." "..appName.." "..tostring(self:get_hint(w)))
            end
        end
    end
end
function obj:callback_window_destroyed(w, appName, event)
    if w then
        if windows[w:id()]  then
            local hint = windows[w:id()]
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
function obj:get_windows()
    return hints
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
    if line_height/sframe.h*100 > 20 then
        line_height = sframe.h*0.16
    end
    local border = math.min(sframe.w*0.02, line_height*0.02)
    local text = "" 
    if title:sub(-#appName):lower() == appName:lower() then
        title = title:sub(1, -#appName-1)
    elseif title:sub(1, #appName):lower() == appName:lower() then
        title = title:sub(#appName+1, #title)
    end
    appName = strim(appName)
    title = strim(title)
    text = appName.." "..title
    -- logger.d(text)
    local backframe = {
            y = i*line_height+border,
            h = line_height-border*2,
            x = border,
            w = sframe.w-border*2,
        }
    canvas:insertElement({
        type = "rectangle",
        id = "background",
        fillColor = {  red = 0, green = 0, blue = 0},
        canvasAlpha=0.5,
        roundedRectRadii={ xRadius = 20, yRadius = 20 },
        frame = backframe,
    })
    local imageframe = {
            y = backframe.y+border,
            h = backframe.h-border*2,
            x = backframe.x+border,
            w = backframe.h-border*2,
        }
    canvas:insertElement({ 
        type="image",
        absoluteSize=false,
        absolutePosition=false,
        image = hs.image.imageFromAppBundle(bundleID),
        frame = imageframe,
    })
    local hintframe = {
            y = imageframe.y+imageframe.h/2,
            h = imageframe.h/2,
            x = imageframe.x+imageframe.w/2,
            w = imageframe.w/2,
    }
    canvas:insertElement({
        type = "rectangle",
        id = "hintbox"..string.lower(hint),
        fillColor = hintboxcolor,
        canvasAlpha=0.5,
        roundedRectRadii={ xRadius = 20, yRadius = 20 },
        frame = hintframe,
        -- radius = hintframe.h/2,
        -- center = {
        --     x = hintframe.x+hintframe.w/2,
        --     y = hintframe.y+hintframe.h/2
        -- },
    })
    canvas:insertElement({ 
        type="text",
        text=hint,
        textColor= {red=0, green=0, blue=0},
        textAlignment="center",
        textSize=hintframe.h*0.8,
        absoluteSize=false,
        absolutePosition=false,
        frame = hintframe,
    })
    -- logger.d(title)
    -- logger.d(#title)
    if #title < 5 then
        text = appName.." "..title
    else
        text = appName
    end
    local appnameframe = {
        y = imageframe.y,
        h = backframe.h/2-border*2,
        x = imageframe.x+imageframe.w+border*2,
        w = backframe.w-imageframe.w-border*4,
    }
    canvas:insertElement({ 
        type="text",
        id = "appname",
        text=text,
        textColor= {red=1, green=1, blue=1},
        textAlignment="left",
        textSize=appnameframe.h*0.8,
        absoluteSize=false,
        absolutePosition=false,
        frame = appnameframe,
    })
    if #title >= 5 then
        local titleframe = {
            y = appnameframe.y+appnameframe.h+border*2,
            h = backframe.h/2-border*2,
            x = appnameframe.x,
            w = appnameframe.w,
        }
        canvas:insertElement({ 
            type="text",
            text=title,
            textColor= {red=1, green=1, blue=1},
            textAlignment="left",
            textSize=titleframe.h*0.5,
            absoluteSize=false,
            absolutePosition=false,
            frame = titleframe,
        })
    end

    return canvas
end
local hframe = hs.geometry.new({w=500, h=1000})

obj.menu_canvases = {}
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
        if self.menu_canvases[screen] and self.menu_canvases[screen].hide then
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
    for _,screen in pairs(hs.screen.allScreens()) do
        local sframe = screen:frame()
        if not screens[screen:getUUID()] then
            local char = self:get_char({tostring(screen.name), tostring(uuid)})
            if char and not screen_hints[char] then
                -- logger.d(hs.inspect({screen, char}))
                local c = hintboxes[char]
                screen_hints[char] = screen
                local hframe = c:frame()
                hframe.center = sframe.center
                c:frame({w=100, h=100, x=sframe.x+sframe.w/2, y=sframe.y+sframe.h/2})
                c:show()
                c:bringToFront(true)
            end
        end
    end
end
function obj:hide_menu()
    screen_hints = {}
    for _, menu in pairs(self.menu_canvases) do
        menu:hide()
    end
end
-- TODO add hints for empty screens
function obj:show_hints()
    -- logger.d("show_hints")
    -- for h, w in pairs(hints) do
        -- logger.d(h.." "..w:application():name()..w:title())
    -- end
    if obj.event_start_flags then
        local visiblewindows = {}
        local otherwindows = {}
        -- local normal = hs.window.filter.new(hs.window.filter.default):getWindows()
        local allwindows = hs.window.orderedWindows()
        hs.fnutils.each(allwindows, function(window)
            if windows[window:id()] then
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
        for i,hint in pairs(windows) do
            if not visiblewindows[i] then
                otherwindows[i] = self:get_window(hint)
            end
        end
        self:show_menu(otherwindows)
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
    end
end
function obj:hide_hints()
    for hint, hintbox in pairs(hintboxes) do
        hintbox:hide()
    end
    self:hide_menu()
end

function obj:highlight_selected()
    local screens = hs.screen.allScreens()
    for hint, hintbox in pairs(hintboxes) do
        local color = nil
        local name ="hintbox"..string.lower(hint)
        if self.selected[hint] then
            color = hintboxselectedcolor
        else
            color = hintboxcolor
        end
        hintbox[name].fillColor = color
        for _, canvas in pairs(self.menu_canvases) do
            if canvas then
                local hintbox = canvas[name]
                if hintbox then
                    canvas[name].fillColor = color
                end
            end
        end
    end
end

function obj:switcher(args)
    self.event_start_flags = {}
    self.eventtap:start()
    self:show_hints()
end
function obj.updatespaces(spaceid)
    local spaceid = spaceid
    if spaceid == -1 then
        -- spaceid = 
        local screen = hs.mouse.getCurrentScreen()
        spaceid=hs.spaces.activeSpaceOnScreen(screen) 
    end
    local spw = hs.spaces.windowsForSpace(spaceid) or {}
    -- logger.d(hs.inspect({windows=windows}))
    spw = hs.fnutils.filter(spw, function(el)
        if windows[el] then
            -- logger.d(hs.inspect({id=el, hint=windows[el]}))
            return true
        end
        -- if hs.fnutils.contains(normalwindows, hs.window.get(el)) then
        --     return true
        -- end
    end)
    -- logger.d(hs.inspect({spw=spw}))

    spaces[spaceid] = spw
    -- logger.d(hs.inspect({
    --     spaces=spaces
    -- }))
end
function obj.windowsForSpace(spaceid)
    return spaces[spaceid] or {}
end
local function moveWinToSpace(w,spaceid)
    local screen = w:screen()
    local screenspaces = hs.spaces.spacesForScreen(screen)
    local spacescreen = hs.screen.find(hs.spaces.spaceDisplay(spaceid))
    local current_space=hs.spaces.activeSpaceOnScreen(screen) 
    local mapping = "[]{}=&*+()!#"
    if screen == spacescreen then
        local wspc = hs.spaces.windowSpaces(w:id())
        if not (#wspc > 0 and wspc[1] == spaceid )then
            for i,k in pairs(screenspaces) do
                if k == spaceid then 
                    -- local index = string.sub(mapping, i,i)
                    local index = hs.keycodes.map[hs.keycodes.map[tostring(i)]]
                    -- logger.d(hs.inspect({w, i, index, spaceid}))
                    w:focus()
                    hs.timer.usleep(200)
                    hs.eventtap.keyStroke({"control","option", "shift" }, index)
                    hs.timer.usleep(200)
                    w:focus()
                    hs.timer.usleep(400)
                    break
                end
            end
        else
            -- logger.d(hs.inspect({w, "focus"}))
            w:focus()
        end
    else
        -- logger.d(hs.inspect({w, "move to another screen and focus"}))
        hs.spaces.gotoSpace(spaceid)
        w:moveToScreen(spacescreen, true, false, 0)
        w:focus()
    end
end
obj.filter = hs.window.filter.new(hs.window.filter.default)
function obj.addWindowsToSpace(spaceid, selected)
    local spaceid = spaceid
    local screen = hs.mouse.getCurrentScreen()
    local layout = nil
    local normalwindows = obj.filter:getWindows()
    local selected = selected or {}
    local windows = {}
    for hint, w in pairs(selected) do
        table.insert(windows, w)
    end
    if #windows > 0 then
        if not spaceid then
            local screenspaces = hs.spaces.spacesForScreen(screen)
            if #windows > 1 then
                logger.d("looking for spaceid")
                layout = "Tall"
                -- logger.d(hs.inspect({spaces=spaces}))
                for i, space in ipairs(screenspaces) do
                    logger.d(hs.inspect({i, space}))
                    -- local spw = hs.spaces.windowsForSpace(space)
                    local spw = obj.windowsForSpace(space)
                    logger.d(hs.inspect({spaceid=space, spw=spw}))
                    -- logger.d(tostring(space).." windows="..tostring(#spw))
                    logger.d(hs.inspect({i= i, space=space, spaceid=spaceid, nspw=#spw, spw=spw, spaces=spaces, windows=windows}))
                    if not spaceid then
                        if i > 1 and #spw == #windows and hs.fnutils.every(windows, function(el) return hs.fnutils.contains(spw, el:id()) end) then
                            logger.d("using existing space")
                            spaceid = space
                            if spaceid ~= hs.spaces.activeSpaceOnScreen(screen) then
                                hs.spaces.gotoSpace(spaceid)
                            end
                            return
                        elseif i > 1 and #spw == 0 then
                            logger.d(hs.inspect({name="reusing an empty one ", i=i, space=space, spaceid=spaceid, nspw=#spw, spw=spw, spaces=spaces, windows=windows}))
                            spaceid = space
                            -- break
                        elseif i == #screenspaces then
                            logger.d("created a new one")
                            hs.spaces.addSpaceToScreen(screen)
                            local lspaces = hs.spaces.spacesForScreen(screen)
                            spaceid = lspaces[#lspaces]
                            -- break
                        end
                    else
                    end
                end
            else
                logger.d("using fullscreen space")
                spaceid = screenspaces[1]
            end
        else
            screen = hs.screen.find(hs.spaces.spaceDisplay(spaceid))
        end
        for i, w in pairs(windows) do
            moveWinToSpace(w, spaceid)
        end
        windows[1]:focus()
        hs.timer.doAfter(0.5, function()
            windows[1]:focus()
            reload_layout(layout)
        end)
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
    self.screenwatcher = hs.screen.watcher.new(function()
    end)
    self.spaceswatcher = hs.spaces.watcher.new(function(space)
        self.updatespaces(space)
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
            self.selected = {}
            self:highlight_selected()
            return false
        end
        -- logger.d("hintseventtap keycode="..tostring(keycode).." key="..tostring(char).." originalkey="..tostring(hs.keycodes.map[keycode]).." keyDown="..tostring(keydown))
        if not hs.fnutils.some(self.event_start_flags, function() return true end) then
            self.event_start_flags = flags
            self.selected = {}
            self:highlight_selected()
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
                    if self.selected[char]  then
                        self.selected[char] = nil
                    else
                        self.selected[char] = window
                    end
                    self:highlight_selected()
                else
                    window:focus()
                    return exit()
                end
            else
                if screen_hints[char] then
                    hs.mouse.absolutePosition(screen_hints[char]:frame().center)
                end
                if not self.selecting and launcher[char] then
                    local bundleID = launcher[char]
                    hs.application.launchOrFocusByBundleID(bundleID)
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
    self.spaceswatcher:start()
    self.filter:subscribe({hs.window.filter.windowInCurrentSpace, hs.window.filter.windowNotInCurrentSpace}, function(w, appName, event)
        if w and self:get_hint(w) then
            local screen = w:screen()
            local spaceid = hs.spaces.activeSpaceOnScreen(screen)
            if not spaceid then
                spaceid = hs.spaces.windowSpaces(w:id())[1] or nil
                local sh = {}
                for _, sp in pairs(hs.spaces.windowSpaces(w:id())) do
                    local spw = hs.spaces.windowsForSpace(sp) or {}
                    sh[sp]=spw
                end
                -- logger.d(hs.inspect(sh))
                -- logger.d(hs.inspect({windowspaces=hs.spaces.windowSpaces(w:id())}))
            end
            if spaceid then
                self.updatespaces(spaceid)
                -- logger.d(hs.inspect({app=appName, event=event, spaces=spaces}))
            else
                -- logger.d(hs.inspect({n="nospaceid", app=appName, event=event, spaces=spaces}))
            end
        end
    end)
    hs.hotkey.bind(obj.mods, obj.key, function(...)
        self:switcher(...)
    end)
    return obj
end



return obj
