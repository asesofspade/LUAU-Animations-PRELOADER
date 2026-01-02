# Roblox Animation Preloader

A simple **animation preloader module** for Roblox that automatically preloads all animation assets from a game configuration object.

This ensures smooth animation playback and prevents delays when playing animations during gameplay.

---

## Features

- Recursively scans a table (or nested tables) for Roblox animation IDs (`rbxassetid://`).
- Preloads animations using Roblox `ContentProvider`.
- Stores preloaded `Animation` instances for easy retrieval.
- Integrates with `Broadcast` RemoteEvent to automatically preload animations when `gameconfig` is sent from the server.

---

## Installation

1. Place `AnimationPreloader.lua` in your `ReplicatedStorage` (or preferred module location, e.g., `src/` folder).
2. Ensure you have a `Broadcast` RemoteEvent in `ReplicatedStorage.Remotes.Broadcast`.

---

## Usage

```lua
local AnimationPreloader = require(game.ReplicatedStorage.src.AnimationPreloader)

-- Automatically preloads animations when server sends gameconfig
-- Broadcast.OnClientEvent is already connected inside the module

-- Get a preloaded animation by ID
local anim = AnimationPreloader:GetAnimation("rbxassetid://123456789")
if anim then
    local humanoid = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    local track = humanoid:LoadAnimation(anim)
    track:Play()
end
```

---

## How it Works

1. When the server sends the `gameconfig` table via `Broadcast` RemoteEvent, the module scans all nested tables for animation IDs.
2. Each ID found creates a new `Animation` instance.
3. All animations are preloaded asynchronously with `ContentProvider:PreloadAsync`.
4. Preloaded animations are stored in `AnimationPreloader.Animations` and can be retrieved via `AnimationPreloader:GetAnimation(animId)`.

---

## Notes

- Works best with structured game configurations containing animation IDs.
- Automatically handles nested tables, so you can organize animations per weapon, player state, or enemy.
- Requires `ContentProvider` and `ReplicatedStorage` to be available.
