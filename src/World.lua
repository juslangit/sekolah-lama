-- Builds the grey-box school from Config so no manual building is needed yet.
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local World = {}

local HEIGHT = Config.WallHeight
local HALF_CORRIDOR = Config.CorridorWidth / 2
local OUTER = HALF_CORRIDOR + Config.RoomDepth
local LENGTH = Config.RoomsPerSide * Config.RoomWidth
local HALF_LOBBY = Config.LobbyWidth / 2
local HALF_GATE = Config.GateWidth / 2
local HALF_DOOR = Config.DoorWidth / 2
local HALF_WALL = 0.5
local PORCH = 12 -- floor past the gate
local DESK_HEIGHT = 3

local WALL_COLOR = Color3.fromRGB(104, 108, 92)
local FLOOR_COLOR = Color3.fromRGB(70, 66, 60)
local CEILING_COLOR = Color3.fromRGB(50, 50, 48)
local DESK_COLOR = Color3.fromRGB(96, 70, 48)
local GATE_COLOR = Color3.fromRGB(90, 30, 28)
local LAMP_COLOR = Color3.fromRGB(255, 214, 150)
local TALISMAN_COLOR = Color3.fromRGB(240, 205, 80)

local random = Random.new()

local function newPart(parent, name, size, cframe, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Parent = parent
	return part
end

-- Fills the box between two corners. Every wall, floor and desk is made this way.
local function box(parent, name, x0, x1, y0, y1, z0, z1, color, material)
	local size = Vector3.new(math.abs(x1 - x0), math.abs(y1 - y0), math.abs(z1 - z0))
	local center = CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
	return newPart(parent, name, size, center, color, material)
end

-- A wall running along X at the given z.
local function wallX(parent, x0, x1, z, y0, y1)
	return box(parent, "Wall", x0, x1, y0 or 0, y1 or HEIGHT, z - HALF_WALL, z + HALF_WALL, WALL_COLOR, Enum.Material.Concrete)
end

-- A wall running along Z at the given x.
local function wallZ(parent, x, z0, z1, y0, y1)
	return box(parent, "Wall", x - HALF_WALL, x + HALF_WALL, y0 or 0, y1 or HEIGHT, z0, z1, WALL_COLOR, Enum.Material.Concrete)
end

local function addLamp(parent, x, z, brightness, range)
	local lamp = newPart(parent, "Lamp", Vector3.new(3, 0.4, 1), CFrame.new(x, HEIGHT - 0.2, z), LAMP_COLOR, Enum.Material.Neon)
	lamp.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color = LAMP_COLOR
	light.Brightness = brightness
	light.Range = range
	light.Parent = lamp
	return lamp
end

function World.build()
	local map = Instance.new("Folder")
	map.Name = "Map"
	map.Parent = Workspace

	local lobbyX = -Config.LobbyLength

	box(map, "Floor", lobbyX - PORCH, LENGTH, -1, 0, -OUTER, OUTER, FLOOR_COLOR, Enum.Material.Concrete)
	box(map, "Ceiling", lobbyX, LENGTH, HEIGHT, HEIGHT + 1, -OUTER, OUTER, CEILING_COLOR)

	-- Shell: far end, both long sides, and the wall that separates the lobby from the classrooms.
	wallZ(map, LENGTH, -OUTER, OUTER)
	for _, side in { 1, -1 } do
		wallX(map, 0, LENGTH, side * OUTER)
		wallZ(map, 0, side * HALF_CORRIDOR, side * OUTER)
		wallX(map, lobbyX, 0, side * HALF_LOBBY)
		wallZ(map, lobbyX, side * HALF_GATE, side * HALF_LOBBY)
	end
	wallZ(map, lobbyX, -HALF_GATE, HALF_GATE, Config.DoorHeight, HEIGHT)

	local gate = box(map, "Gate", lobbyX - HALF_WALL, lobbyX + HALF_WALL, 0, Config.DoorHeight, -HALF_GATE, HALF_GATE, GATE_COLOR, Enum.Material.Metal)

	-- Touching this once the gate is open ends the round.
	local escape = box(map, "Escape", lobbyX - PORCH, lobbyX - 3, 0, Config.DoorHeight, -HALF_LOBBY, HALF_LOBBY, GATE_COLOR)
	escape.Transparency = 1
	escape.CanCollide = false

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(lobbyX / 2, 0.5, 0)
	spawn.Color = FLOOR_COLOR
	spawn.Material = Enum.Material.Concrete
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = map

	addLamp(map, lobbyX / 2, 0, 0.8, 26)

	local rooms = {}
	local waypoints = {}

	for index = 1, Config.RoomsPerSide do
		local x0 = (index - 1) * Config.RoomWidth
		local x1 = index * Config.RoomWidth
		local centerX = (x0 + x1) / 2

		table.insert(waypoints, Vector3.new(centerX, 0, 0))
		if index % 2 == 1 then
			addLamp(map, centerX, 0, 0.5, 22)
		end

		for _, side in { 1, -1 } do
			-- Corridor wall with a doorway in the middle.
			local doorZ = side * HALF_CORRIDOR
			wallX(map, x0, centerX - HALF_DOOR, doorZ)
			wallX(map, centerX + HALF_DOOR, x1, doorZ)
			wallX(map, centerX - HALF_DOOR, centerX + HALF_DOOR, doorZ, Config.DoorHeight, HEIGHT)

			if index < Config.RoomsPerSide then
				wallZ(map, x1, side * HALF_CORRIDOR, side * OUTER)
			end

			-- Desks. Their tops are where talismans can appear.
			local spots = {}
			for column = -1, 1 do
				for row = 1, 2 do
					local x = centerX + column * 9
					local z = side * (HALF_CORRIDOR + row * Config.RoomDepth / 3)
					box(map, "Desk", x - 2, x + 2, 0, DESK_HEIGHT, z - 1.25, z + 1.25, DESK_COLOR, Enum.Material.Wood)
					table.insert(spots, Vector3.new(x, DESK_HEIGHT, z))
				end
			end

			local center = Vector3.new(centerX, 0, side * (HALF_CORRIDOR + Config.RoomDepth / 2))
			table.insert(rooms, { center = center, spots = spots })
			table.insert(waypoints, center)
		end
	end

	local talismans = Instance.new("Folder")
	talismans.Name = "Talismans"
	talismans.Parent = map

	return {
		map = map,
		gate = gate,
		escape = escape,
		rooms = rooms,
		waypoints = waypoints,
		talismans = talismans,
		length = LENGTH,
	}
end

function World.setGate(world, open)
	world.gate.CanCollide = not open
	world.gate.Transparency = open and 1 or 0
end

-- Clears the old talismans and places new ones, one per randomly chosen classroom.
function World.spawnTalismans(world)
	world.talismans:ClearAllChildren()

	local rooms = table.clone(world.rooms)
	for index = #rooms, 2, -1 do
		local other = random:NextInteger(1, index)
		rooms[index], rooms[other] = rooms[other], rooms[index]
	end

	local placed = {}
	for index = 1, math.min(Config.TalismanCount, #rooms) do
		local spots = rooms[index].spots
		local spot = spots[random:NextInteger(1, #spots)]

		local talisman = newPart(world.talismans, "Talisman", Vector3.new(1, 0.1, 1.6), CFrame.new(spot + Vector3.new(0, 0.05, 0)), TALISMAN_COLOR, Enum.Material.Neon)
		talisman.CanCollide = false

		local glow = Instance.new("PointLight")
		glow.Color = TALISMAN_COLOR
		glow.Brightness = 0.6
		glow.Range = 7
		glow.Parent = talisman

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Take"
		prompt.ObjectText = "Talisman"
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 8
		prompt.RequiresLineOfSight = false
		prompt.Parent = talisman

		table.insert(placed, talisman)
	end
	return placed
end

return World
