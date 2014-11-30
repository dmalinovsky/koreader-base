-- load common SDL input/video library
local SDL = require("ffi/SDL1_2")
local BB = require("ffi/blitbuffer")
local util = require("ffi/util")

local framebuffer = {
    -- this blitbuffer will be used when we use refresh emulation
    sdl_bb = nil,
}

function framebuffer:init()
	if not self.dummy then
		SDL.open()
		local bb = BB.new(SDL.screen.w, SDL.screen.h, BB.TYPE_BBRGB32,
			SDL.screen.pixels, SDL.screen.pitch)
        local flash = os.getenv("EMULATE_READER_FLASH")
        if flash then
            -- in refresh emulation mode, we use a shadow blitbuffer
            -- and blit refresh areas from it.
            self.sdl_bb = bb
            self.bb = BB.new(SDL.screen.w, SDL.screen.h, BB.TYPE_BBRGB32)
        else
            self.bb = bb
        end
	else
		self.bb = BB.new(600, 800)
	end

    self.bb:fill(BB.COLOR_WHITE)
	self:refreshFull()

    framebuffer.parent.init(self)
end

local function flip()
	if SDL.SDL.SDL_LockSurface(SDL.screen) < 0 then
		error("Locking screen surface")
	end

	SDL.SDL.SDL_UnlockSurface(SDL.screen)
	SDL.SDL.SDL_Flip(SDL.screen)
end

function framebuffer:refreshFullImp(x, y, w, h)
	if self.dummy then return end

    local bb = self.full_bb or self.bb

    if not (x and y and w and h) then
        x = 0
        y = 0
        w = bb:getWidth()
        h = bb:getHeight()
    end

    self.debug("refresh on physical rectangle", x, y, w, h)

    local flash = os.getenv("EMULATE_READER_FLASH")
    if flash then
        self.sdl_bb:invertRect(x, y, w, h)
        flip()
        util.usleep(tonumber(flash)*1000)
        self.sdl_bb:setRotation(bb:getRotation())
        self.sdl_bb:setInverse(bb:getInverse())
        self.sdl_bb:blitFrom(bb, x, y, x, y, w, h)
    end

    flip()
end

function framebuffer:close()
    SDL.SDL.SDL_Quit()
end

return require("ffi/framebuffer"):extend(framebuffer)
