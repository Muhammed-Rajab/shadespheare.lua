-- logical window dimensions
WIDTH = nil
HEIGHT = nil
SCALE = nil
I_SCALE = nil

-- vector library
-- local vector = require("lib.hump.vector") -- table based vector
local vector = require("lib.hump.vector-light") -- pure numbers based operation

local settings = require("settings")
local utils = require("src.utils")
local fontman = require("src.fontmanager")

function love.load()
	-- window setup
	WIDTH = love.graphics.getWidth()
	HEIGHT = love.graphics.getHeight()

	SCALE = settings.scale_factor
	I_SCALE = 1 / SCALE

	love.window.setMode(WIDTH * SCALE, HEIGHT * SCALE)

	--------------------------
	-- your setup goes here --
	--------------------------
	-- WARN: loads JetBrainsMono fonts in different sizes. Can be EXPENSIVE
	utils.loadDefaultFonts()

	-- fontman:set("jbmono-regular", 32) -- loads font
end

function love.update(dt)
	-----------------------------------
	-- your updation logic goes here --
	-----------------------------------
end

function love.draw()
	-- WARN: scaling causes the font rendering to misbehave. use with caution.
	love.graphics.scale(SCALE, SCALE)
	love.graphics.setBackgroundColor(0.08, 0.08, 0.08, 1)
	love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)

	----------------------------------
	-- your drawing logic goes here --
	----------------------------------
	local x, y = utils.getMousePositionScaled()

	love.graphics.ellipse("fill", x, y, 50, 50)
end
