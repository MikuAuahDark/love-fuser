--[[
Copyright (c) 2006-2021 LOVE Development Team

This software is provided 'as-is', without any express or implied
warranty.  In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.
--]]

-- Make sure love exists.
local love = require("love")

R = {}

R.bg = {[1]={}, [2]={}}

-- cloud_1.png
R.bg[1].cloud_1_png = love.filesystem.read("data", "cloud_1.png")
-- cloud_1@2x.png
R.bg[2].cloud_1_png = love.filesystem.read("data", "cloud_1@2x.png")
-- cloud_2.png
R.bg[1].cloud_2_png = love.filesystem.read("data", "cloud_2.png")
-- cloud_2@2x.png
R.bg[2].cloud_2_png = love.filesystem.read("data", "cloud_2@2x.png")
-- cloud_3.png
R.bg[1].cloud_3_png = love.filesystem.read("data", "cloud_3.png")
-- cloud_3@2x.png
R.bg[2].cloud_3_png = love.filesystem.read("data", "cloud_3@2x.png")
-- cloud_4.png
R.bg[1].cloud_4_png = love.filesystem.read("data", "cloud_4.png")
-- cloud_4@2x.png
R.bg[2].cloud_4_png = love.filesystem.read("data", "cloud_4@2x.png")

R.chain = {[1]={}, [2]={}}

-- a.png
R.chain[1].a_png = love.filesystem.read("data", "a.png")
-- a@2x.png
R.chain[2].a_png = love.filesystem.read("data", "a@2x.png")
-- e.png
R.chain[1].e_png = love.filesystem.read("data", "e.png")
-- e@2x.png
R.chain[2].e_png = love.filesystem.read("data", "e@2x.png")
-- g.png
R.chain[1].g_png = love.filesystem.read("data", "g.png")
-- g@2x.png
R.chain[2].g_png = love.filesystem.read("data", "g@2x.png")
-- m.png
R.chain[1].m_png = love.filesystem.read("data", "m.png")
-- m@2x.png
R.chain[2].m_png = love.filesystem.read("data", "m@2x.png")
-- n.png
R.chain[1].n_png = love.filesystem.read("data", "n.png")
-- n@2x.png
R.chain[2].n_png = love.filesystem.read("data", "n@2x.png")
-- o.png
R.chain[1].o_png = love.filesystem.read("data", "o.png")
-- o@2x.png
R.chain[2].o_png = love.filesystem.read("data", "o@2x.png")
-- square.png
R.chain[1].square_png = love.filesystem.read("data", "square.png")
-- square@2x.png
R.chain[2].square_png = love.filesystem.read("data", "square@2x.png")

R.duckloon = {[1]={}, [2]={}}

-- blink.png
R.duckloon[1].blink_png = love.filesystem.read("data", "blink.png")
-- blink@2x.png
R.duckloon[2].blink_png = love.filesystem.read("data", "blink@2x.png")
-- normal.png
R.duckloon[1].normal_png = love.filesystem.read("data", "normal.png")
-- normal@2x.png
R.duckloon[2].normal_png = love.filesystem.read("data", "normal@2x.png")

local class = require("30log")

local g_t = 0 -- The current elapsed time.
local g_step = 0 -- The current physics step.
local STEP = 1/20 -- 20Hz physics.

-- Debug things.
local DEBUG = false
local LOCAL = true
local g_frame_count = 0
local g_step_count = 0

-- A State maintains two x,y,angle states for some
-- body, and interpolates between those states.
local State = class("State")

function State:init(body)
	self.t0 = 0
	self.x0 = body:getX()
	self.y0 = body:getY()
	self.r0 = body:getAngle()

	self.t1 = self.t0
	self.x1 = self.x0
	self.y1 = self.y0
	self.r1 = self.r0
end

-- Calculate the next state for Body, at time t.
function State:save(body, t)
	self.t0 = self.t1
	self.x0 = self.x1
	self.y0 = self.y1
	self.r0 = self.r1

	self.t1 = t
	self.x1 = body:getX()
	self.y1 = body:getY()
	self.r1 = body:getAngle()
end

function State:get(t)
	t = math.min(t, self.t1)
	t = math.max(t, self.t0)

	local p = (t - self.t0) / (self.t1 - self.t0)

	local x = self.x0 + p * (self.x1 - self.x0)
	local y = self.y0 + p * (self.y1 - self.y0)
	local r = self.r0 + p * (self.r1 - self.r0)

	return x, y, r
end

-- Simple class for figuring out whether the eyes
-- of the Duckloon should be closed.
local Blink = class("Blink")

function Blink:init()
	-- When this hits zero, we open the eyes.
	self.closed_t = 0

	-- When this hits zero, we close the eyes.
	self.next_blink_t = 5
end

function Blink:update(dt)
	self.next_blink_t = math.max(0, self.next_blink_t - dt)
	self.closed_t = math.max(0, self.closed_t - dt)

	if self.next_blink_t == 0 then
		self.next_blink_t = 5 + math.random(0, 3)
		self.closed_t = 0.1
	end
end

function Blink:is_closed()
	return self.closed_t > 0
end

-- Duckloon (TM)
local Duckloon = class("Duckloon")

function Duckloon:init(world, x, y)
	self.body = love.physics.newBody(world, x, y, "dynamic")
	self.body:setLinearDamping(0.8)
	self.body:setAngularDamping(0.8)
	self.shape = love.physics.newPolygonShape(-55, -60, 0, 90, 55, -60)
	self.fixture = love.physics.newFixture(self.body, self.shape, 1)
	self.fixture:setRestitution(0.5)
	self.img_normal = img_duckloon_normal
	self.img_blink = img_duckloon_blink
	self.img = self.img_normal
	self.blink = Blink()
	self.pin = love.physics.newMouseJoint(self.body, x, y - 80)
	self.state = State(self.body)
end

function Duckloon:step()
	self.state:save(self.body, g_step)

	if math.floor(g_step % 5) == 0 then
		self.body:applyForce(math.random(30, 50), 0)
	end
end

function Duckloon:update(dt)
	self.blink:update(dt)
end

function Duckloon:draw()
	local x, y, r = self.state:get(g_t)

	love.graphics.setColor(1, 1, 1)

	local img = self.img_normal
	if self.blink:is_closed() then
		img = self.img_blink
	end

	love.graphics.draw(img, x, y, r, 1, 1, img:getWidth() / 2, img:getHeight() / 2)

	if DEBUG then
		love.graphics.setColor(0.8, 0.3, 0.1)
		love.graphics.polygon("fill", self.body:getWorldPoints(self.shape:getPoints()))

		love.graphics.setColor(0, 1, 0)
		local ax, ay = self:attachment_point()
		love.graphics.circle("fill", ax, ay, 3)
	end
end

-- This is where to attach the Chain.
function Duckloon:attachment_point()
	return self.body:getWorldPoint(4, 90)
end

-- The chain is built from a string containing "# nogame",
-- which represents what should be "drawn" along the chain.
local Chain = class("Chain")

function Chain:init(world, x, y, str, duckloon)
	self.links = {}
	self.str = str

	local DRAW_INFO = {
		n = { r = 11, img = img_n },
		o = { r = 11, img = img_o },
		g = { r = 11, img = img_g },
		a = { r = 11, img = img_a },
		m = { r = 11, img = img_m },
		e = { r = 11, img = img_e },
		[" "] = { r = 4, img = nil },
		["#"] = { r = 7, img = img_square }
	}

	for i=1,#str do

		local prev = nil

		if i >=2 then
			prev = self.links[i - 1]
		end

		local byte = str:byte(i)
		local link = {}

		link.x = x
		link.y = y

		link.info = DRAW_INFO[string.char(byte)]
		link.radius = link.info.r

		if prev ~= nil then
			link.y = prev.y + prev.radius + link.radius
		end

		link.body = love.physics.newBody(world, link.x, link.y, "dynamic")
		link.body:setLinearDamping(0.5)
		link.body:setAngularDamping(0.5)
		link.shape = love.physics.newCircleShape(link.radius)
		link.fixture = love.physics.newFixture(link.body, link.shape, 0.1 / i)
		link.state = State(link.body)

		-- Note: every link must also be attached to the Duckloon. Otherwise the
		--       chain easily goes haywire on higher speeds.

		if prev ~= nil then
			link.joint = love.physics.newRevoluteJoint(link.body, prev.body, link.x, link.y - link.radius / 2)
			link.join2 = love.physics.newRopeJoint(link.body, duckloon.body, link.x, link.y, x, y, link.y - y)
		else
			link.joint = love.physics.newRevoluteJoint(link.body, duckloon.body, link.x, link.y)
		end

		table.insert(self.links, link)
	end

end

function Chain:step()
	for i, link in ipairs(self.links) do
		link.state:save(link.body, g_step)
	end
end

function Chain:update(dt)
end

function Chain:draw()
	local rope = {}

	for i, link in ipairs(self.links) do
		local x, y = link.state:get(g_t)
		table.insert(rope, x)
		table.insert(rope, y)
	end

	love.graphics.setLineWidth(3)
	love.graphics.setColor(1, 1, 1, 0.7)
	love.graphics.line(rope)

	for i, link in ipairs(self.links) do
		if link.info.img ~= nil then
			local x, y, r = link.state:get(g_t)
			local ox, oy = link.info.img:getWidth() / 2, link.info.img:getHeight() / 2
			love.graphics.setColor(1, 1, 1)
			love.graphics.draw(link.info.img, x, y, r, 1, 1, ox, oy)
		end
	end

	if DEBUG then
		for i, link in ipairs(self.links) do
			love.graphics.setColor(1, 0, 1)
			local x, y = link.body:getPosition()
			love.graphics.circle("fill", x, y, link.shape:getRadius())
		end
	end
end

-- Draws clouds in a repeating pattern of 1,2,3,4, but with
-- an offset on each track.
local CloudTrack = class("CloudTrack")

-- x,y: Top-left corner of cloud track.
function CloudTrack:init(x, y, offset, speed, img)
	self.x = x
	self.y = y
	self.initial_offset = offset
	self.h_spacing = 50
	self.img = img
	self.w = self.h_spacing + self.img:getWidth()
	self.speed = speed -- px/s
	self.count = love.graphics.getWidth() / self.w + 2
	self.initial_img = math.random(1, 4)
end

function CloudTrack:update(dt)
end

function CloudTrack:draw()
	local abs_offset = (self.initial_offset + (self.speed * g_t))
	local offset = abs_offset % self.w
	love.graphics.setColor(1, 1, 1, 0.3)
	for i=1, self.count do
		local x = self.x + (i - 1) * (self.img:getWidth() + self.h_spacing) + offset - self.w
		local y = self.y
		local img_no =  math.floor(abs_offset / self.w)
		love.graphics.draw(cloud_images[1 + (self.initial_img + i - img_no) % 4], x, y, -0.05)
	end
end

local Clouds = class("Clouds")

function Clouds:init()
	local layer_height = 100

	self.tracks = {}
	local max = (love.graphics.getHeight() / layer_height) + 1
	for i=1, max do
		table.insert(self.tracks, CloudTrack(0, 20 + (i - 1) * layer_height, img_cloud_1:getWidth() / 2 * i, 40, img_cloud_1))
	end
end

function Clouds:draw()
	for i,track in ipairs(self.tracks) do
		track:draw()
	end
end

-- Called on resize.
function create_world()
	local wx, wy = love.graphics.getDimensions()
	world = love.physics.newWorld(0, 9.81*64)
	duckloon = Duckloon(world, wx / 2, wy / 2 - 100)
	local ax, ay = duckloon:attachment_point()
	chain = Chain(world, ax, ay, "  n o # g a m e # ", duckloon)
	clouds = Clouds()

	g_objs = {
		chain,
		duckloon
	}
end

function love.load()
	love.graphics.setBackgroundColor(43/255, 165/255, 223/255)
	love.physics.setMeter(64)

	local dpiscale = love.window.getDPIScale() > 1 and 2 or 1
	local settings = {dpiscale = dpiscale}

	R.chain.n = R.chain[dpiscale].n_png
	R.chain.o = R.chain[dpiscale].o_png
	R.chain.g = R.chain[dpiscale].g_png
	R.chain.a = R.chain[dpiscale].a_png
	R.chain.m = R.chain[dpiscale].m_png
	R.chain.e = R.chain[dpiscale].e_png
	R.chain.square = R.chain[dpiscale].square_png
	R.duckloon.blink = R.duckloon[dpiscale].blink_png
	R.duckloon.normal = R.duckloon[dpiscale].normal_png
	R.bg.cloud_1 = R.bg[dpiscale].cloud_1_png
	R.bg.cloud_2 = R.bg[dpiscale].cloud_2_png
	R.bg.cloud_3 = R.bg[dpiscale].cloud_3_png
	R.bg.cloud_4 = R.bg[dpiscale].cloud_4_png

	img_duckloon_normal = love.graphics.newImage(R.duckloon.normal, settings)
	img_duckloon_blink = love.graphics.newImage(R.duckloon.blink, settings)

	img_n = love.graphics.newImage(R.chain.n, settings)
	img_o = love.graphics.newImage(R.chain.o, settings)
	img_g = love.graphics.newImage(R.chain.g, settings)
	img_a = love.graphics.newImage(R.chain.a, settings)
	img_m = love.graphics.newImage(R.chain.m, settings)
	img_e = love.graphics.newImage(R.chain.e, settings)
	img_square = love.graphics.newImage(R.chain.square, settings)

	img_cloud_1 = love.graphics.newImage(R.bg.cloud_1, settings)
	img_cloud_2 = love.graphics.newImage(R.bg.cloud_2, settings)
	img_cloud_3 = love.graphics.newImage(R.bg.cloud_3, settings)
	img_cloud_4 = love.graphics.newImage(R.bg.cloud_4, settings)

	cloud_images = {
		img_cloud_1,
		img_cloud_2,
		img_cloud_3,
		img_cloud_4,
	}

	create_world()
end

function love.update(dt)
	g_t = g_t + dt

	while g_t > g_step do
		world:update(STEP)
		g_step = g_step + STEP
		for i,v in ipairs(g_objs) do
			v:step()
		end
		g_step_count = g_step_count + 1
	end

	for i in ipairs(g_objs) do
		g_objs[i]:update(dt)
	end
end

function love.draw()
	clouds:draw()

	for i in ipairs(g_objs) do
		g_objs[i]:draw()
	end

	if DEBUG then
		love.graphics.setColor(0, 0, 0, 0.5)
		love.graphics.print("FPS: " .. love.timer.getFPS(), 50, 50)
		love.graphics.print("Time: " .. g_t, 50, 65)
		love.graphics.print("g_step: " .. g_step, 50, 80)
		love.graphics.print("Frame: " .. g_frame_count, 50, 95)
		love.graphics.print("Step: " .. g_step_count, 50, 110)
	end

	g_frame_count = g_frame_count + 1
end

function love.mousepressed(x, y, b, istouch, clicks)
	-- Double-tap the screen (when using a touch screen) to exit.
	if istouch and clicks == 2 then
		if love.window.showMessageBox("Exit No-Game Screen", "", {"OK", "Cancel"}) == 1 then
			love.event.quit()
		end
	end
end

function love.keypressed(key)
	if key == "escape" then
		love.event.quit()
	end
end

function love.resize()
	create_world()
end
