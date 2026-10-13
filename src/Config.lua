-- Shared game values. Balance the game here, not in the scripts.
local Config = {}

-- School layout in studs. Classrooms line both sides of one corridor that runs along X from 0.
-- The lobby sits before X = 0 and is the safe zone: the ghost never enters it.
Config.RoomsPerSide = 4
Config.RoomWidth = 36
Config.RoomDepth = 30
Config.CorridorWidth = 14
Config.WallHeight = 14
Config.DoorWidth = 6
Config.DoorHeight = 9
Config.LobbyLength = 30
Config.LobbyWidth = 30
Config.GateWidth = 8

-- Talismans to find before the gate opens. At most one per classroom, so keep it
-- at or below RoomsPerSide * 2.
Config.TalismanCount = 5

Config.WalkSpeed = 10
Config.SprintSpeed = 20
Config.StaminaSeconds = 5 -- how long a full bar lasts
Config.StaminaRegen = 0.5 -- stamina seconds regained per second
Config.StaminaRecover = 1 -- stamina needed to sprint again after running out

Config.FirstPerson = true
Config.RespawnTime = 3
Config.RoundRestartTime = 8

-- The ghost floats through walls. Walls block her sight but not her hearing:
-- anyone moving faster than a walk inside HearRadius is noticed.
-- Keep ChaseSpeed between WalkSpeed and SprintSpeed so running works only while stamina lasts.
Config.Ghost = {
	PatrolSpeed = 7,
	ChaseSpeed = 16,
	SightRadius = 70,
	HearRadius = 45,
	CatchRadius = 4,
	LoseTime = 4, -- seconds she keeps following after losing a player
	RestTime = 3, -- pause after a catch
	DreadRadius = 60, -- distance at which the screen starts to redden
}

return Config
