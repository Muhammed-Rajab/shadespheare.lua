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

local reloadDelay = 0.25
local pendingReload = false
local reloadTimer = 0

local function safeRead(path)
	local ok, data = pcall(love.filesystem.read, path)
	if ok and data then
		return data
	else
		return nil
	end
end

local function loadShader(dt)
	local info = love.filesystem.getInfo(shader_path)
	if info and info.modtime > last_modified then
		-- file changed
		last_modified = info.modtime -- important line
		pendingReload = true
		reloadTimer = 0
	end

	if pendingReload then
		reloadTimer = reloadTimer + dt
		if reloadTimer >= reloadDelay then
			local code = safeRead(shader_path)
			if code then
				local ok, s = pcall(love.graphics.newShader, code)
				if ok then
					shader = s
					print("shader reloaded at", os.date("%H:%M:%S"))
				else
					-- maybe set the shader to nil, so shit won't get executed?
					shader = nil
					print("shader compile error:\n", s)
				end
			else
				-- skip temporary missing files
				return
			end
			pendingReload = false
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
	loadShader(0)
end

local function sendUniform(shader, name, value)
	if shader:hasUniform(name) then
		shader:send(name, value)
	end
end

function love.update(dt)
	loadShader(dt)

	if shader then
		sendUniform(shader, "iTime", love.timer.getTime())

		local width, height = love.graphics.getDimensions()
		sendUniform(shader, "iResolution", { width, height })
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
