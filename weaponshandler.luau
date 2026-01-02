local weaponsHandler = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Broadcast = game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Broadcast")
local comms = game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Comms")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local ObjectOriented
local gameconfig
local equippedTools = {}
local COMBO_THRESHOLD = 1
local activeSlows = {}

local function recalcWalkSpeed(char)
	local humanoid = char:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then return end
	local tool = char:FindFirstChildWhichIsA("Tool")
	local toolName = tool and tool.Name
	local baseSpeed = (toolName and gameconfig.Weapons[toolName] and gameconfig.Weapons[toolName].WalkSpeed) or 16
	local totalSlow = 0
	for _, v in pairs(activeSlows) do totalSlow += v end
	humanoid.WalkSpeed = math.max(0, baseSpeed - totalSlow)
end

local function applySlowPlayer(char, slowData)
	if not slowData then return end
	local slowAmount = slowData[1] or 0
	local slowDuration = slowData[2] or 0.5
	local id = tick()
	activeSlows[id] = slowAmount
	recalcWalkSpeed(char)
	task.delay(slowDuration, function()
		activeSlows[id] = nil
		recalcWalkSpeed(char)
	end)
end

local function sendWeaponAnimations(toolName)
	if not gameconfig or not toolName then return end
	local weapon = gameconfig.Weapons[toolName]
	if not weapon then return end
	local a = weapon.Animations
	comms:Fire({
		Idle = a.Idle,
		Walk = a.Walk,
		Run  = a.Run,
		WalkSpeed = weapon.WalkSpeed,
		AllowRun = weapon.AllowRun
	})
end

local function clearWeaponAnimations()
	if not gameconfig then return end
	comms:Fire({
		Idle = gameconfig.Player.Animations.Idle,
		Walk = gameconfig.Player.Animations.Walk,
		Run  = gameconfig.Player.Animations.Run
	})
end

local activeParries = {}

local function playWeaponAnim(toolName, animKey)
	if not gameconfig or not ObjectOriented then return end
	local char = player.Character
	if not char or not char.PrimaryPart then return end
	local weapon = gameconfig.Weapons[toolName]
	if not weapon then return end
	local animData = weapon.Animations[animKey]
	if not animData then return end

	local eventData = {}

	if animData.SlowPlayer then
		applySlowPlayer(char, animData.SlowPlayer)
	end

	if type(animData) == "string" then
		eventData.Animation = { animType = "Play", animId = animData, looped = false }
	elseif type(animData) == "table" then
		if animData.Animation then
			eventData.Animation = { animType = "Play", animId = animData.Animation, looped = false }
		end
		if animData.ChangeFOV then eventData.ChangeFOV = animData.ChangeFOV end
		if animData.ApplyShake then eventData.ApplyShake = animData.ApplyShake end
		if animData.GroundImpact then eventData.GroundImpact = animData.GroundImpact end
		if animData.AppyImpulse then
			local f = animData.AppyImpulse.force or Vector3.zero
			local forward = char.PrimaryPart.CFrame.LookVector
			forward = Vector3.new(forward.X, 0, forward.Z).Unit
			eventData.AppyImpulse = {
				force = forward * f.Magnitude + Vector3.new(0, f.Y, 0),
				duration = animData.AppyImpulse.duration or 0.2
			}
		end
	end

	if animKey == "Parry" then
        if not gameconfig or not gameconfig.InputMap.Parry then return end
        local parrySettings = gameconfig.InputMap.Parry
        local id = tick()
        activeParries[id] = true
        local duration = parrySettings.Duration or 2
        local released = false
        local conn

        comms:Fire({ Parry = { state = "start" } })

        local function endParry()
            if released then return end
            released = true
            activeParries[id] = nil

            ObjectOriented:Fire(char, { Animation = { animId = animData.Animation, stop = true } })
            comms:Fire({ Parry = { state = "end" } })

            if conn and conn.Connected then conn:Disconnect() end

            local weapon = gameconfig.Weapons[toolName]
            if char and weapon and weapon.Animations.Idle then
                ObjectOriented:Fire(char, { Animation = { animId = weapon.Animations.Idle, isState = true } })
            end
        end


        conn = UIS.InputEnded:Connect(function(input)
            if input.UserInputType == parrySettings.Key then
                endParry()
            end
        end)

        task.delay(duration, function()
            if activeParries[id] then
                endParry()
            end
        end)
    end


	ObjectOriented:Fire(char, eventData)
end

local function equipTool(tool)
	if equippedTools[tool] then return end
	local connections = {}
	local comboIndex = 1
	local lastClickTime = 0
	local lastSlashTime = 0

	connections.Activated = tool.Activated:Connect(function()
		local weapon = gameconfig.Weapons[tool.Name]
		if not weapon then return end
		local now = tick()
		if now - lastSlashTime < (weapon.Animations.SlashCooldown or 0.5) then return end
		if now - lastClickTime > COMBO_THRESHOLD then comboIndex = 1 end
		local key = comboIndex == 1 and "Slash" or "Slash"..comboIndex
		playWeaponAnim(tool.Name, key)
		Broadcast:FireServer("UseWeapon", {
			toolName = tool.Name,
			comboIndex = comboIndex,
			timestamp = now
		})
		lastClickTime = now
		lastSlashTime = now
		comboIndex += 1
		local maxCombo = 1
		for k in pairs(weapon.Animations) do
			local n = tonumber(k:match("Slash(%d+)"))
			if n and n > maxCombo then maxCombo = n end
		end
		if comboIndex > maxCombo then comboIndex = 1 end
	end)

	connections.Parry = UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end
        if not gameconfig or not gameconfig.InputMap.Parry then return end
        local parryKey = gameconfig.InputMap.Parry.Key
        if input.UserInputType == parryKey then
            playWeaponAnim(tool.Name, "Parry")
        end
    end)

	sendWeaponAnimations(tool.Name)
	equippedTools[tool] = connections
end

local function unequipTool(tool)
	local conns = equippedTools[tool]
	if conns then
		for _, c in pairs(conns) do if c.Connected then c:Disconnect() end end
		equippedTools[tool] = nil
	end
	clearWeaponAnimations()
end

local function forceUnequip()
	local char = player.Character
	if not char then return end
	for tool, _ in pairs(equippedTools) do
		if tool.Parent == char then
			tool.Parent = player.Backpack
		end
		unequipTool(tool)
	end
	recalcWalkSpeed(char)
end

local function setupCharacter(char)
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and gameconfig.Weapons[child.Name] then
			equipTool(child)
		end
	end)

	char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and gameconfig.Weapons[child.Name] then
			unequipTool(child)
		end
	end)
end

comms.Event:Connect(function(tag)
	if tag == "ForceUnequipWeapon" then
		forceUnequip()
	end
end)

Broadcast.OnClientEvent:Connect(function(tag, data)
	if tag == "gameconfig" then
		gameconfig = data
		ObjectOriented = game:WaitForChild("CustomService").Public.ObjectOriented
		if player.Character then setupCharacter(player.Character) end
	end
end)

player.CharacterAdded:Connect(setupCharacter)

return weaponsHandler
