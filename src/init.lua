-- logical window dimensions
WIDTH = nil
HEIGHT = nil
SCALE = nil
I_SCALE = nil

local settings = require("settings")
local utils = require("src.utils")
local fontman = require("src.fontmanager")

local shader
local shader_path = "shader.glsl"
local last_modified = 0

local function loadShader()
	local info = love.filesystem.getInfo(shader_path)
	if not info then
		print("shader file not found:", shader_path)
		return
	end

	-- reload if changed
	if info.modtime > last_modified then
		last_modified = info.modtime
		local code = love.filesystem.read(shader_path)
		local ok, s = pcall(love.graphics.newShader, code)
		if ok then
			shader = s
			print("shader reloaded at", os.date("%H:%M:%S"))
		else
			print("shader compile error:\n", s)
		end
	end
end

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

	-- load inital shader
	loadShader()
end

function love.update(dt)
	-----------------------------------
	-- your updation logic goes here --
	-----------------------------------
	loadShader()

	if shader then
		-- pass data to shader
		if shader:hasUniform("iTime") then
			shader:send("iTime", love.timer.getTime())
		end

		if shader:hasUniform("iResolution") then
			local width, height = love.graphics.getDimensions()
			shader:send("iResolution", { width, height })
		end
	end
end

function love.draw()
	-- WARN: scaling causes the font rendering to misbehave. use with caution.
	love.graphics.scale(SCALE, SCALE)
	love.graphics.setBackgroundColor(0.08, 0.08, 0.08, 1)

	if shader then
		love.graphics.setShader(shader)
		love.graphics.rectangle("fill", 0, 0, WIDTH, HEIGHT)
		love.graphics.setShader()
	end

	love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
end
