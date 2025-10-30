-- logical window dimensions
WIDTH = nil
HEIGHT = nil
SCALE = nil
I_SCALE = nil

local settings = require("settings")
local utils = require("src.utils")
local fontman = require("src.fontmanager")
local LiveShader = require("src.live-shader")

local shader
local shader_path = "shader.glsl"

function love.load()
	-- window setup
	WIDTH = love.graphics.getWidth()
	HEIGHT = love.graphics.getHeight()

	SCALE = settings.scale_factor
	I_SCALE = 1 / SCALE

	love.window.setMode(WIDTH * SCALE, HEIGHT * SCALE)

	-- your setup
	utils.loadDefaultFonts()
	shader = LiveShader.new(shader_path, 0.25)
	shader:update(0)
end

function love.update(dt)
	shader:update(dt)

	if not shader:loaded() then
		return
	end

	local ok, err = shader:set_uniform("iTime", love.timer.getTime())
	if not ok then
		print(err)
	end

	local width, height = love.graphics.getDimensions()
	ok, err = shader:set_uniform("iResolution", { width, height })
	if not ok then
		print(err)
	end
end

function love.draw()
	-- WARN: scaling causes the font rendering to misbehave. use with caution.

	love.graphics.push()
	love.graphics.scale(SCALE, SCALE)
	love.graphics.setBackgroundColor(0.08, 0.08, 0.08, 1)

	if shader:loaded() then
		shader:use()
		love.graphics.rectangle("fill", 0, 0, WIDTH, HEIGHT)
		love.graphics.setShader()
	end
	love.graphics.pop()

	love.graphics.setColor(0, 0, 0, 255)
	love.graphics.rectangle("fill", 7, 10, 157, 40)
	love.graphics.setColor(0, 255, 0, 255)
	love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
end
