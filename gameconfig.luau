local gameconfig = {}

gameconfig.InputMap = {
    Roll = {
        Key = Enum.KeyCode.LeftControl,
        Forward = "rbxassetid://"..85508177664236,
        RightRoll = "rbxassetid://"..118194069677777,
        LeftRoll = "rbxassetid://"..111143366799199,
        BackRoll = "rbxassetid://"..85508177664236,
        Cooldown = 2,
    },
    Parry = {
        Key = Enum.UserInputType.MouseButton2,
        DamageTaken = {
            Perfect = 0,
            Good = 0.5,
            Bad = 1,
        },
        Duration = 2,
        Cooldown = 1,
    },
    Sprint = Enum.KeyCode.LeftShift,
    Focus = Enum.KeyCode.F,
}

gameconfig.Weapons = {
    DragonSlayer = {
        Type = "LongSword",
        Animations = {
            Idle = "rbxassetid://"..137700137725609,
            Walk = "rbxassetid://"..85454769679725,
            Slash = {
                Animation = "rbxassetid://"..119022884117298,
                ChangeFOV = { targetFOV = 50, speed = 5, duration = 0.3 },
                AppyImpulse = { force = Vector3.new(10, 0, 0), duration = 0.2 }, 
                SlowPlayer = {5, 2}
            },
            Slash2 = {
                Animation = "rbxassetid://"..131873035400644,
                ChangeFOV = { targetFOV = 55, speed = 5, duration = 0.3 },
                AppyImpulse = { force = Vector3.new(-10, 0, 0), duration = 0.2 },
                SlowPlayer = {5, 2}
            },
            Slash3 = {
                Animation = "rbxassetid://"..72949919666295,
                GroundImpact = { partName = "HumanoidRootPart", count = 20, radius = 10, delay = 0.2, options = {color = Color3.new(1.5,1.5,1.5), size = Vector3.new(3,3,3), offset = Vector3.new(0, 0, -10), duration = 3} },
                ChangeFOV = { targetFOV = 50, speed = 5, duration = 2 },
                ApplyShake = { amount = 0.5, duration = 0.1 },
                AppyImpulse = { force = Vector3.new(0, 25, 66), duration = 0.2 },
                SlowPlayer = {10, 3},
                SlashCooldown = 3,
            },
            Parry = {
                Animation = "rbxassetid://"..134104331411374,
            },
            SlashCooldown = 0.5,
            Damage = 20,
            DamageIncrement = 2.5,
        },
        WalkSpeed = 11,
        AllowRun = false,
        AllowCrouch = false,
    },
    SaintSword = {
        Type = "LongSword",
        Animations = {
            Idle = "rbxassetid://"..118489799561737,
            Walk = "rbxassetid://"..106813294636197,
            Slash = {
                Animation = "rbxassetid://"..86656278380701,
                ChangeFOV = { targetFOV = 50, speed = 5, duration = 2 },
                AppyImpulse = { force = Vector3.new(10, 0, 0), duration = 0.2 }, 
            },
            Slash2 = {
                Animation = "rbxassetid://"..139976456767158,
                ChangeFOV = { targetFOV = 50, speed = 5, duration = 2 },
                AppyImpulse = { force = Vector3.new(10, 0, 0), duration = 0.2 }, 
            },
            Slash3 = {
                Animation = "rbxassetid://"..128364810165437,
                ChangeFOV = { targetFOV = 50, speed = 5, duration = 2 },
                AppyImpulse = { force = Vector3.new(0,0,35), duration = 0.3 }, 
            },
            Parry = {
                Animation = "rbxassetid://"..81161050308594,
            },
            SlashCooldown = 0.5,
            Damage = 15,
            DamageIncrement = 1.5,

        },
        AllowRun = false,
        AllowCrouch = false,
    }
}


gameconfig.Player = {
    Animations = {
        Idle = "rbxassetid://"..83404028575145,
        Walk = "rbxassetid://"..129465674915225,
        Run = "rbxassetid://"..124299496401916,
        Climb = "rbxassetid://"..507765644,
        Fall = "rbxassetid://"..80911919887620,
        Crouch = {
            Idle = "rbxassetid://"..78754255805604,
            Walk = "rbxassetid://"..112529280719582,
        },
        Crawl = {
            Idle = "rbxassetid://"..105243683455041,
            Walk = "rbxassetid://"..75756057371771,
        }
    }
}

return gameconfig
