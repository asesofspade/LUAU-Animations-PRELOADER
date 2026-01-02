local parryhandler = {}

local player = game:GetService("Players").LocalPlayer
local Broadcast = game.ReplicatedStorage.Remotes.Broadcast
local comms = game.ReplicatedStorage.Remotes.Comms
local RunService = game:GetService("RunService")

local gameconfig
local parryActive = false
local parryStartTime = 0

Broadcast.OnClientEvent:Connect(function(tag, data)
    if tag == "gameconfig" and data then
        gameconfig = data
    end
end)

comms.Event:Connect(function(tag)
    if type(tag) ~= "table" then return end
    if tag.Parry and tag.Parry.state == "start" then
        if not gameconfig or not gameconfig.InputMap.Parry then return end
        parryActive = true
        parryStartTime = tick()
    elseif tag.Parry and tag.Parry.state == "end" then
        if not parryActive or not gameconfig or not gameconfig.InputMap.Parry then return end
        parryActive = false
        local elapsed = tick() - parryStartTime
        local thresholds = gameconfig.InputMap.Parry.DamageTaken
        local parryDuration = gameconfig.InputMap.Parry.Duration or 2
        local perfectTime = thresholds.Perfect * parryDuration
        local goodTime = thresholds.Good * parryDuration
        local quality
        if elapsed <= perfectTime then
            quality = "Perfect"
        elseif elapsed <= goodTime then
            quality = "Good"
        else
            quality = "Bad"
        end
        print("[ParryHandler] Parry ended! Quality:", quality)
    end
end)

return parryhandler
