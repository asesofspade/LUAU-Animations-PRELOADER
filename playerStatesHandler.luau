local playerHandler = {}

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local Broadcast = game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Broadcast")
local comms = game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Comms")

local ObjectOriented
local gameconfig

local currentState = "Idle"
local runKeyDown = false

local WALK_SPEED = 16
local RUN_SPEED = 24
local currentWalkSpeed = WALK_SPEED
local weaponWalkSpeed = nil

local baseAnimations = {}
local weaponAnimations = {}
local stateAnimations = nil

local allowRun = true
local weaponAllowCrouch = true
local weaponEquipped = false

local crouching = false
local crawling = false
local lastCPressTime = 0
local DOUBLE_TAP_THRESHOLD = 0.2

local connections = {}

local function clearConnections()
	for _, c in ipairs(connections) do
		if c and c.Connected then
			c:Disconnect()
		end
	end
	table.clear(connections)
end

local function stopAllAnims()
	if not ObjectOriented then return end
	local char = player.Character
	if not char or not char.PrimaryPart then return end
	ObjectOriented:Fire(char, { Animation = { animType = "StopAll" } })
end

local function unequipWeapon()
	if weaponEquipped then
		comms:Fire("ForceUnequipWeapon")
	end
	weaponAnimations = {}
	weaponWalkSpeed = nil
	allowRun = true
	weaponAllowCrouch = true
	weaponEquipped = false

	stateAnimations = nil
end

local function getAnim(animKey)
	if stateAnimations and stateAnimations[animKey] then
		return stateAnimations[animKey]
	end
	if weaponAnimations[animKey] then
		return weaponAnimations[animKey]
	end
	return baseAnimations[animKey]
end

local function playPlayerAnim(animKey)
	if not ObjectOriented then return end
	local char = player.Character
	if not char or not char.PrimaryPart then return end
	local animId = getAnim(animKey)
	if not animId then return end
	ObjectOriented:Fire(char, {
		Animation = {
			animType = "Play",
			animId = animId,
			looped = true,
			isState = true
		}
	})
end

local function refreshCurrentAnim()
	if currentState:find("Idle") then
		playPlayerAnim("Idle")
	elseif currentState:find("Walk") then
		playPlayerAnim("Walk")
	elseif currentState == "Run" and allowRun then
		playPlayerAnim("Run")
	elseif currentState == "Fall" then
		playPlayerAnim("Fall")
	end
end

local function applyWalkSpeed(humanoid)
	humanoid.WalkSpeed = currentWalkSpeed
end

local function enterCrouch(humanoid)
	unequipWeapon()
	crouching = true
	crawling = false
	stateAnimations = gameconfig.Player.Animations.Crouch
	stopAllAnims()
	currentWalkSpeed = WALK_SPEED / 2
	applyWalkSpeed(humanoid)
	currentState = "CrouchIdle"
	playPlayerAnim("Idle")
end

local function enterCrawl(humanoid)
	unequipWeapon()
	crouching = true
	crawling = true
	stateAnimations = gameconfig.Player.Animations.Crawl
	stopAllAnims()
	currentWalkSpeed = WALK_SPEED / 3
	applyWalkSpeed(humanoid)
	currentState = "CrawlIdle"
	playPlayerAnim("Idle")
end

local function exitCrouch(humanoid)
	crouching = false
	crawling = false
	stateAnimations = nil
	currentWalkSpeed = weaponWalkSpeed or WALK_SPEED
	applyWalkSpeed(humanoid)
	currentState = "Idle"
	refreshCurrentAnim()
end

local function updateWeaponAnimations(payload)
	if crouching or crawling or currentState == "Climb" then return end

	weaponAnimations = {
		Idle = payload.Idle,
		Walk = payload.Walk,
		Run = payload.Run
	}

	weaponWalkSpeed = payload.WalkSpeed
	allowRun = payload.AllowRun ~= false
	weaponAllowCrouch = payload.AllowCrouch ~= false
	weaponEquipped = true
	currentWalkSpeed = weaponWalkSpeed or WALK_SPEED

	stateAnimations = weaponAnimations

	local humanoid = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		applyWalkSpeed(humanoid)
	end

	refreshCurrentAnim()
end


local function setupPlayerAnimations()
	if not gameconfig then return end
	local char = player.Character
	if not char then return end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	clearConnections()
	stopAllAnims()

	baseAnimations = gameconfig.Player.Animations
	unequipWeapon()
	stateAnimations = nil

	currentState = "Idle"
	crouching = false
	crawling = false
	runKeyDown = false

	currentWalkSpeed = WALK_SPEED
	applyWalkSpeed(humanoid)

	table.insert(connections, UIS.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.C then
			if weaponEquipped and weaponAllowCrouch == false then
				return
			end
			local now = tick()
			if not crouching then
				enterCrouch(humanoid)
			elseif crouching and not crawling then
				if now - lastCPressTime <= DOUBLE_TAP_THRESHOLD then
					enterCrawl(humanoid)
				else
					exitCrouch(humanoid)
				end
			else
				exitCrouch(humanoid)
			end
			lastCPressTime = now
		elseif input.KeyCode == Enum.KeyCode.LeftShift and allowRun and not crouching then
			runKeyDown = true
			humanoid.WalkSpeed = (weaponWalkSpeed or WALK_SPEED) * 1.5
		end
	end))

	table.insert(connections, UIS.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift then
			runKeyDown = false
			applyWalkSpeed(humanoid)
		end
	end))

	table.insert(connections, humanoid.Running:Connect(function(speed)
		local hasInput = humanoid.MoveDirection.Magnitude > 0.05
		if speed > 0 and hasInput then
			if runKeyDown and allowRun and not crouching then
				currentState = "Run"
				playPlayerAnim("Run")
			else
				currentState = crouching and "CrouchWalk" or crawling and "CrawlWalk" or "Walk"
				playPlayerAnim("Walk")
			end
		else
			currentState = crouching and "CrouchIdle" or crawling and "CrawlIdle" or "Idle"
			playPlayerAnim("Idle")
		end
	end))

	table.insert(connections, humanoid.StateChanged:Connect(function(old, new)
		if new == Enum.HumanoidStateType.Freefall then
			currentState = "Fall"
			playPlayerAnim("Fall")
		elseif new == Enum.HumanoidStateType.Climbing then
			unequipWeapon()
			stateAnimations = { Idle = gameconfig.Player.Animations.Climb }
			stopAllAnims()
			currentState = "Climb"
			playPlayerAnim("Idle")
		elseif old == Enum.HumanoidStateType.Climbing then
			stateAnimations = nil
			currentState = humanoid.MoveDirection.Magnitude > 0.05 and "Walk" or "Idle"
			refreshCurrentAnim()
		elseif old == Enum.HumanoidStateType.Freefall then
			if humanoid.MoveDirection.Magnitude < 0.05 then
				currentState = "Idle"
			else
				currentState = runKeyDown and allowRun and "Run" or "Walk"
			end
			refreshCurrentAnim()
		end
	end))
end

comms.Event:Connect(updateWeaponAnimations)

Broadcast.OnClientEvent:Connect(function(tag, data)
	if tag == "gameconfig" then
		gameconfig = data
		ObjectOriented = game:WaitForChild("CustomService").Public.ObjectOriented
		setupPlayerAnimations()
	end
end)

player.CharacterAdded:Connect(setupPlayerAnimations)

return playerHandler
