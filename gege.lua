local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/1nig1htmare1234/SCRIPTS/main/Orion.lua"))()
repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer and game.Players.LocalPlayer.Character
task.wait(1.5)

local Player = game.Players.LocalPlayer

local Window = OrionLib:MakeWindow({
    Name = "YoxanXHub V2.1 | Hypershot Gunfight",
    HidePremium = false,
    SaveConfig = false,
    IntroText = "YoxanXHub V2.1 Loading...",
})

-- Tabs
local AimbotTab = Window:MakeTab({Name = "Aimbot", Icon = "🎯", PremiumOnly = false})
local GunModsTab = Window:MakeTab({Name = "GunMods", Icon = "🔫", PremiumOnly = false})

-- Silent Aim Placeholder
AimbotTab:AddToggle({
    Name = "Silent Aim (WIP)",
    Default = false,
    Callback = function(value)
        OrionLib:MakeNotification({
            Name = "Silent Aim",
            Content = value and "Enabled" or "Disabled",
            Time = 2
        })
    end
})

-- GunMods Toggle (Anti Recoil, Spread, etc)
GunModsTab:AddToggle({
    Name = "Enable Gun Mods (Anti Recoil, Spread, etc)",
    Default = false,
    Callback = function(state)
        if not state then return end
        local success, err = pcall(function()
            for _, v in next, getgc(true) do
                if typeof(v) == "table" and rawget(v, "Spread") then
                    rawset(v, "Spread", 0)
                    rawset(v, "BaseSpread", 0)
                    rawset(v, "MinCamRecoil", Vector3.new())
                    rawset(v, "MaxCamRecoil", Vector3.new())
                    rawset(v, "MinRotRecoil", Vector3.new())
                    rawset(v, "MaxRotRecoil", Vector3.new())
                    rawset(v, "MinTransRecoil", Vector3.new())
                    rawset(v, "MaxTransRecoil", Vector3.new())
                    rawset(v, "ScopeSpeed", 100)
                end
            end
        end)
        OrionLib:MakeNotification({
            Name = "GunMods",
            Content = success and "Applied successfully." or ("Error: "..tostring(err)),
            Time = 3
        })
    end
})
