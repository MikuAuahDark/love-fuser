local love = require("love")
local math = math

local function getDPIScale()
	return math.min(love.graphics.getDPIScale(), 2)
end

local class = require("30log")

local Toast = class("Toast")

function Toast:init()
	self:center()

	self.eyes = {}
	self.eyes.closed_t = 0
	self.eyes.blink_t = 2

	self.look = {}
	self.look.target = { x = 0.2,  y = 0.2 }
	self.look.current = { x = 0.2,  y = 0.2 }
	self.look.DURATION = 0.5
	self.look.POINTS = {
		{ x = 0.8, y = 0.8 },
		{ x = 0.1, y = 0.1 },
		{ x = 0.8, y = 0.1 },
		{ x = 0.1, y = 0.8 },
	}
	self.look.point = 0
	self.look.point_t = 1
	self.look.t = 0
end

local function easeOut(t, b, c, d)
	t = t / d - 1
	return c * (math.pow(t, 3) + 1) + b
end

function Toast:center()
	local ww, wh = love.graphics.getDimensions()
	self.x = math.floor(ww / 2 / 32) * 32 + 16
	self.y = math.floor(wh / 2 / 32) * 32 + 16
end

function Toast:get_look_coordinates()
	local t = self.look.t

	local src = self.look.current
	local dst = self.look.target

	local look_x = easeOut(t, src.x, dst.x - src.x, self.look.DURATION)
	local look_y = easeOut(t, src.y, dst.y - src.y, self.look.DURATION)

	return look_x, look_y
end

function Toast:update(dt)
	self.look.t = math.min(self.look.t + dt, self.look.DURATION)
	self.eyes.closed_t = math.max(self.eyes.closed_t - dt, 0)
	self.eyes.blink_t = math.max(self.eyes.blink_t - dt, 0)
	self.look.point_t = math.max(self.look.point_t - dt, 0)

	if self.eyes.blink_t == 0 then
		self:blink()
	end

	if self.look.point_t == 0 then
		self:look_at_next_point()
	end

	local look_x, look_y = self:get_look_coordinates()

	self.offset_x = look_x * 4
	self.offset_y = (1 - look_y) * -4
end

function Toast:draw()
	local x = self.x
	local y = self.y

	local look_x, look_y = self:get_look_coordinates()

	love.graphics.draw(g_images.toast.back, x, y, self.r, 1, 1, 64, 64)
	love.graphics.draw(g_images.toast.front, x + self.offset_x, y + self.offset_y, self.r, 1, 1, 64, 64)
	love.graphics.draw(self:get_eyes_image(), x + self.offset_x * 2.5, y + self.offset_y * 2.5, self.r, 1, 1, 64, 64)
	love.graphics.draw(g_images.toast.mouth, x + self.offset_x * 2, y + self.offset_y * 2, self.r, 1, 1, 64, 64)
end

function Toast:get_eyes_image()
	if self.eyes.closed_t > 0 then
		return g_images.toast.eyes.closed
	end
	return g_images.toast.eyes.open
end

function Toast:blink()
	if self.eyes.closed_t > 0 then
		return
	end
	self.eyes.closed_t = 0.1
	self.eyes.blink_t = self.next_blink()
end

function Toast:next_blink()
	return 5 + love.math.random(0, 3)
end

function Toast:look_at(tx, ty)
	local look_x, look_y = self:get_look_coordinates()
	self.look.current.x = look_x
	self.look.current.y = look_y

	self.look.t = 0
	self.look.point_t = 3 + love.math.random(0, 1)

	self.look.target.x = tx
	self.look.target.y = ty
end

function Toast:look_at_next_point()
	self.look.point = self.look.point + 1
	if self.look.point > #self.look.POINTS then
		self.look.point = 1
	end
	local point = self.look.POINTS[self.look.point]
	self:look_at(point.x, point.y)
end

local Mosaic = class("Mosaic")

function Mosaic:init()
	local dpi = getDPIScale()
	local mosaic_image = g_images.mosaic[dpi]

	local sw, sh = mosaic_image:getDimensions()
	local ww, wh = love.graphics.getDimensions()

	local SIZE_X = math.floor(ww / 32 + 2)
	local SIZE_Y = math.floor(wh / 32 + 2)
	local SIZE = SIZE_X * SIZE_Y

	self.batch = love.graphics.newSpriteBatch(mosaic_image, SIZE, "stream")
	self.pieces = {}
	self.color_t = 1
	self.generation = 1

	local COLORS = {}

	for _,color in ipairs({
		{ 240, 240, 240 }, -- WHITE (ish)
		{ 232, 104, 162}, -- PINK
		{ 69, 155, 168 }, -- BLUE
		{ 67, 93, 119 }, -- DARK BLUE
	}) do
		table.insert(COLORS, color)
		table.insert(COLORS, color)
	end

	-- Insert only once. This way it appears half as often.
	table.insert(COLORS, { 220, 239, 113 }) -- LIME

	-- When using the higher-res mosaic sprite sheet, we want to draw its
	-- sprites at the same scale as the regular-resolution one, because
	-- we'll globally love.graphics.scale *everything* by the screen's
	-- pixel density ratio.
	-- We can avoid a lot of Quad scaling by taking advantage of the fact
	-- that Quads use normalized texture coordinates internally - if we use 
	-- the 'source image size' and quad size of the @1x image for the Quads
	-- even when rendering them using the @2x image, it will automatically
	-- scale as expected.
	local QUADS = {
		love.graphics.newQuad(0,  0,  32, 32, sw, sh),
		love.graphics.newQuad(0,  32, 32, 32, sw, sh),
		love.graphics.newQuad(32, 32, 32, 32, sw, sh),
		love.graphics.newQuad(32, 0,  32, 32, sw, sh),
	}

	local exclude_left = math.floor(ww / 2 / 32)
	local exclude_right = exclude_left + 3
	local exclude_top = math.floor(wh / 2 / 32)
	local exclude_bottom = exclude_top + 3
	local exclude_width = exclude_right - exclude_left + 1
	local exclude_height = exclude_bottom - exclude_top + 1
	local exclude_area = exclude_width * exclude_height

	local exclude_center_x = exclude_left + 1.5
	local exclude_center_y = exclude_top + 1.5

	self.generators = {
		function(piece, generation)
			return COLORS[love.math.random(1, #COLORS)]
		end,
		function(piece, generation)
			return COLORS[1 + (generation + piece.grid_x - piece.grid_y) % #COLORS]
		end,
		function(piece, generation)
			return COLORS[1 + (piece.grid_x + generation) % #COLORS]
		end,
		function(piece, generation)
			local len = generation + math.sqrt(piece.grid_x ^ 2 + piece.grid_y ^ 2)
			return COLORS[1 + math.floor(len) % #COLORS]
		end,
		function(piece, generation)
			local dx = piece.grid_x - exclude_center_x
			local dy = piece.grid_y - exclude_center_y
			local len = generation - math.sqrt(dx ^ 2 + dy ^ 2)
			return COLORS[1 + math.floor(len) % #COLORS]
		end,
		function(piece, generation)
			local dx = math.abs(piece.grid_x - exclude_center_x) - generation
			local dy = math.abs(piece.grid_y - exclude_center_y) - generation
			return COLORS[1 + math.floor(math.max(dx, dy)) % #COLORS]
		end,
	}

	self.generator = self.generators[1]

	local EXCLUDE = {}
	for y = exclude_top,exclude_bottom do
		EXCLUDE[y]  = {}
		for x = exclude_left,exclude_right do
			EXCLUDE[y][x] = true
		end
	end

	for y = 1,SIZE_Y do
		for x = 1,SIZE_X do
			if not EXCLUDE[y] or not EXCLUDE[y][x] then
				local piece = {
					grid_x = x,
					grid_y = y,
					x = (x - 1) * 32,
					y = (y - 1) * 32,
					r = love.math.random(0, 100) / 100 * math.pi,
					rv = 1,
					color = {},
					quad = QUADS[(x + y) % 4 + 1]
				}

				piece.color.prev = self.generator(piece, self.generation)
				piece.color.next = piece.color.prev
				table.insert(self.pieces, piece)
			end
		end
	end

	local GLYPHS = {
		N = love.graphics.newQuad(0,  64, 32, 32, sw, sh),
		O = love.graphics.newQuad(32, 64, 32, 32, sw, sh),
		G = love.graphics.newQuad(0,  96, 32, 32, sw, sh),
		A = love.graphics.newQuad(32, 96, 32, 32, sw, sh),
		M = love.graphics.newQuad(64, 96, 32, 32, sw, sh),
		E = love.graphics.newQuad(96, 96, 32, 32, sw, sh),

		U = love.graphics.newQuad(64, 0,  32, 32, sw, sh),
		P = love.graphics.newQuad(96, 0,  32, 32, sw, sh),
		o = love.graphics.newQuad(64, 32, 32, 32, sw, sh),
		S = love.graphics.newQuad(96, 32, 32, 32, sw, sh),
		R = love.graphics.newQuad(64, 64, 32, 32, sw, sh),
		T = love.graphics.newQuad(96, 64, 32, 32, sw, sh),
	}

	local INITIAL_TEXT_COLOR = { 240, 240, 240 }

	local put_text = function(str, offset, x, y)
		local idx = offset + SIZE_X * y + x
		for i = 1, #str do
			local c = str:sub(i, i)
			if c ~= " " then
				local piece = self.pieces[idx + i]
				if piece then
					piece.quad = GLYPHS[c]
					piece.r = 0
					piece.rv = 0
					piece.color.prev = INITIAL_TEXT_COLOR
					piece.color.next = INITIAL_TEXT_COLOR
				end
			end
		end
	end

	local text_center_x = math.floor(ww / 2 / 32)

	local no_game_text_offset = SIZE_X * exclude_bottom - exclude_area
	put_text("No GAME", no_game_text_offset, text_center_x - 2, 1)

	put_text("SUPER TOAST", 0, text_center_x - 4, exclude_top - 3)
end

function Mosaic:addGeneration()
	self.generation = self.generation + 1
	if self.generation % 5 == 0 then
		if love.math.random(0, 100) < 60 then
			self.generator = self.generators[love.math.random(2, #self.generators)]
		else
			self.generator = self.generators[1]
		end
	end
end

function Mosaic:update(dt)
	self.color_t = math.max(self.color_t - dt, 0)
	local change_color = self.color_t == 0
	if change_color then
		self.color_t = 1
		self:addGeneration()
	end
	local gen = self.generator
	for idx,piece in ipairs(self.pieces) do
		piece.r = piece.r + piece.rv * dt
		if change_color then
			piece.color.prev = piece.color.next
			piece.color.next = gen(piece, self.generation)
		end
	end
end

function Mosaic:draw()
	self.batch:clear()
	love.graphics.setColor(255/255, 255/255, 255/255, 64/255)
	for idx,piece in ipairs(self.pieces) do
		local ct = 1 - self.color_t
		local c0 = piece.color.prev
		local c1 = piece.color.next
		local r = easeOut(ct, c0[1], c1[1] - c0[1], 1)
		local g = easeOut(ct, c0[2], c1[2] - c0[2], 1)
		local b = easeOut(ct, c0[3], c1[3] - c0[3], 1)

		self.batch:setColor(r/255, g/255, b/255)
		self.batch:add(piece.quad, piece.x, piece.y, piece.r, 1, 1, 16, 16)
	end
	love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
	love.graphics.draw(self.batch, 0, 0)
end

function love.load()
	love.graphics.setBackgroundColor(136/255, 193/255, 206/255)

	local function load_image(file, name)
		return love.graphics.newImage(name)
	end

	g_images = {}
	g_images.toast = {}
	g_images.toast.back = load_image(toast_back_png, "toast_back.png")
	g_images.toast.front = load_image(toast_front_png, "toast_front.png")
	g_images.toast.eyes = {}
	g_images.toast.eyes.open = load_image(toast_eyes_open_png, "toast_eyes_open.png")
	g_images.toast.eyes.closed = load_image(toast_eyes_closed_png, "toast_eyes_closed.png")
	g_images.toast.mouth = load_image(toast_mouth_png, "toast_mouth.png")

	g_images.mosaic = {}
	g_images.mosaic[1] = load_image(mosaic_png, "mosaic.png")
	g_images.mosaic[2] = load_image(mosaic_2x_png, "mosaic@2x.png")

	g_entities = {}
	g_entities.toast = Toast()
	g_entities.mosaic = Mosaic()
end

function love.update(dt)
	dt = math.min(dt, 1/10)
	g_entities.toast:update(dt)
	g_entities.mosaic:update(dt)
end

function love.draw()
	love.graphics.setColor(255/255, 255/255, 255/255)
	love.graphics.push()
	g_entities.mosaic:draw()
	g_entities.toast:draw()
	love.graphics.pop()
end

function love.resize(w, h)
	g_entities.mosaic = Mosaic()
	g_entities.toast:center()
end

function love.keypressed(key)
	if key == "escape" then
		love.event.quit()
	end
end

function love.keyreleased(key)
	if key == "f" then
		local is_fs = love.window.getFullscreen()
		love.window.setFullscreen(not is_fs)
	end
end

function love.mousepressed(x, y, b)
	local tx = x / love.graphics.getWidth()
	local ty = y / love.graphics.getHeight()
	g_entities.toast:look_at(tx, ty)
end

function love.mousemoved(x, y)
	if love.mouse.isDown(1) then
		local tx = x / love.graphics.getWidth()
		local ty = y / love.graphics.getHeight()
		g_entities.toast:look_at(tx, ty)
	end
end

local last_touch = {time=0, x=0, y=0}

function love.touchpressed(id, x, y, pressure)
	-- Double-tap the screen (when using a touch screen) to exit.
	if #love.touch.getTouches() == 1 then
		local dist = math.sqrt((x-last_touch.x)^2 + (y-last_touch.y)^2)
		local difftime = love.timer.getTime() - last_touch.time
		if difftime < 0.3 and dist < 50 then
			if love.window.showMessageBox("L\195\150VE", "Exit No-Game Screen", {"OK", "Cancel"}) == 1 then
				love.event.quit()
			end
		end

		last_touch.time = love.timer.getTime()
		last_touch.x = x
		last_touch.y = y
	end
end


return love.nogame
