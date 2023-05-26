local obj = {}
obj.__index = obj
local logger = hs.logger.new("MissionControl", "debug")

-- Metadata
obj.name = "MissionControl"
obj.version = "1.0"
obj.author = "Ivan Balashov <ivanbalashov239@gmail.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"




local letters = {}
local charcodes = {}
charcodes[49] = "space"
local charorder = "aoeuidhtnspyfgcrlqjkxbwvz:,.'-/@\\[]{}=*+()!#"
-- local charorder = "jkluiopyhnmfdsatgvcewqzx1234567890",

function obj:startshortcuts(args)
    self.event_start_flags = {}
    self.spaceid = 0
    self.eventtap:start()
    -- self:show_hints()
end

function obj:setSpace(newspaceid)
    local newspaceid = newspaceid
    hs.spaces.gotoSpace(newspaceid)
end

function obj:act(name)
    local screen = hs.mouse.getCurrentScreen()
    local spaces = hs.spaces.spacesForScreen(screen)
    -- local spaceid = hs.spaces.activeSpaceOnScreen(screen)
    local spaceid = self.spaceid
    if name == "prevspace" or name == "nextspace" then
        if     name == "prevspace" then
            self.spaceid = self.spaceid - 1
        elseif name == "nextspace" then
            self.spaceid = self.spaceid + 1
        end
    end
end


function obj:init(args)
    local args = args or {}
    local mods = args.mods or {"cmd"}
    self.mods = mods
    local keys = args.keys or {}
    keys["e"]="prevspace"
    keys["u"]="nextspace"
    self.keys = keys
    local charorder = args.charorder or charorder
    for c in charorder:gmatch"." do
        letters[c] = c
        charcodes[hs.keycodes.map[c]] = c
    end
    self.spaceswitcher = hs.timer.new(0.1, function()
        if self.spaceid and self.spaceid ~= 0 then
            -- self.spaceswitcher:stop()
            local screen = hs.mouse.getCurrentScreen()
            local spaces = hs.spaces.spacesForScreen(screen)
            local spaceid = nil
            local current = hs.spaces.activeSpaceOnScreen(screen)
            for i,s in pairs(spaces) do
                if s == current then
                    spaceid = i
                    break
                end
            end
            spaceid = spaceid + self.spaceid
            self.spaceid = 0
            spaceid = math.fmod(spaceid, #spaces)
            if spaceid < 1 then
                spaceid = #spaces + spaceid
            end
            logger.d(spaceid)
            hs.spaces.gotoSpace(spaces[spaceid])
            -- self.spaceswitcher:start()
        end
    end)
    self.eventtap = hs.eventtap.new({ hs.eventtap.event.types.keyUp, hs.eventtap.event.types.keyDown, hs.eventtap.event.types.flagsChanged }, function(event)
        local flags = event:getFlags()
        local keycode = event:getKeyCode()
        local char = charcodes[keycode]
        local keydown = hs.eventtap.event.types[event:getType()] == "keyDown"
        local keyup = not keydown
        local function exit()
            -- hs.alert.show("stop eventtap")
            self.event_start_flags = {}
            self.spaceswitcher:fire()
            self.spaceswitcher:stop()
            self.eventtap:stop()
            for i, flag in pairs(flags) do
                logger.d(tostring(i).." flag "..tostring(flag))
            end
            logger.d("missioncontrol keycode="..tostring(keycode).." key="..tostring(char).." originalkey="..tostring(hs.keycodes.map[keycode]).." keyDown="..tostring(keydown))
            logger.d("missioncontrol stopped")
            hs.timer.doAfter(0.5, function()
                hs.eventtap.keyStroke({}, "Escape")
                hs.spaces.closeMissionControl()
            end)
            return false
        end
        logger.d("missioncontrol keycode="..tostring(keycode).." key="..tostring(char).." originalkey="..tostring(hs.keycodes.map[keycode]).." keyDown="..tostring(keydown))
        if not hs.fnutils.some(self.event_start_flags, function() return true end) then
            self.event_start_flags = flags
            logger.d("missioncontrol started")
            hs.spaces.openMissionControl()
            self.spaceswitcher:start()
            hs.spaces.data_missionControlAXUIElementData(function(results) hs.console.clearConsole() ; print(hs.inspect(results)) end)
            -- if char == self.key then
            --     logger.d("key "..self.key)
            --     return false
            -- end
        end
        if char and keyup and self.keys[char] then
            logger.d("missioncontrol act")
            self:act(self.keys[char])
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

function obj:start()
    for key, action in pairs(self.keys) do
        hs.hotkey.bind(self.mods, key, function()
            self:startshortcuts()
        end)
    end
end



return obj