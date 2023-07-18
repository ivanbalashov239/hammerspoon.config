local obj = {}
obj.__index = obj
local logger = hs.logger.new("Wallpaper", "debug")

-- Metadata
obj.name = "Wallpaper"
obj.version = "1.0"
obj.author = "Ivan Balashov <ivanbalashov239@gmail.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"


function obj:setWallpaper(args)
    local args = args or {}
    local wallpaper = args.wallpaper or os.getenv("HOME") .. "/Downloads/wallpapers/peakpx.jpg"
    for _, screen in pairs(hs.screen.allScreens()) do
        screen:desktopImageURL("file://" .. wallpaper)
    end
    
end


--- Wallpaper:init()
--- Method
--- Init Wallpaper
---
--- Parameters:
---  * args
--- args.mods
--- args.key
--- args.charorder
function obj:init(args)
    local args = args or {}
    self.watcher = hs.screen.watcher.new(function()
        self:setWallpaper(args.wallpaper)
    end)
end

--- Wallpaper:start()
--- Method
--- Start Wallpaper
---
--- Parameters:
---  * None
function obj:start()
    self.watcher:start()
    self:setWallpaper()
end



return obj
