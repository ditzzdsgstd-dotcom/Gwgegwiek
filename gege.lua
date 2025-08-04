--// OrionLib Setup
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/1nig1htmare1234/SCRIPTS/main/Orion.lua"))()
local Window = OrionLib:MakeWindow({
    Name = "YoxanXHub | V2.2 Hypershot Gunfight",
    HidePremium = false,
    SaveConfig = false,
    IntroEnabled = true,
    IntroText = "YoxanXHub V2.2 Loaded!",
    ConfigFolder = "YoxanXConfig"
})

--// Tabs
local AimbotTab = Window:MakeTab({
    Name = "Aimbot",
    Icon = "rbxassetid://7734053494",
    PremiumOnly = false
})

local VisualTab = Window:MakeTab({
    Name = "ESP",
    Icon = "rbxassetid://7734053494",
    PremiumOnly = false
})

local CombatTab = Window:MakeTab({
    Name = "Combat",
    Icon = "rbxassetid://7734053494",
    PremiumOnly = false
})

local UtilityTab = Window:MakeTab({
    Name = "Utility",
    Icon = "rbxassetid://7734053494",
    PremiumOnly = false
})

local InfoTab = Window:MakeTab({
    Name = "Info",
    Icon = "rbxassetid://7734053494",
    PremiumOnly = false
})

-- Silent Aim Toggle
getgenv().SilentAimEnabled = false

AimbotTab:AddToggle({
    Name = "Silent Aim [Head Only]",
    Default = false,
    Callback = function(v)
        getgenv().SilentAimEnabled = v
    end
})

-- Function to get closest target
local function GetClosestHead()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local Camera = workspace.CurrentCamera
    local Closest, Distance = nil, math.huge

    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("Head") then
            local Head = v.Character:FindFirstChild("Head")
            local Pos, OnScreen = Camera:WorldToViewportPoint(Head.Position)
            if OnScreen and (v.Team ~= LocalPlayer.Team) and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
                local dist = (Vector2.new(Pos.X, Pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                if dist < Distance then
                    Closest = Head
                    Distance = dist
                end
            end
        end
    end

    return Closest
end

-- Hook to Redirect Shots
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    if SilentAimEnabled and method == "FindPartOnRayWithIgnoreList" then
        local target = GetClosestHead()
        if target then
            local origin = workspace.CurrentCamera.CFrame.Position
            local direction = (target.Position - origin).Unit * 1000
            args[1] = Ray.new(origin, direction)
            return oldNamecall(self, unpack(args))
        end
    end

    return oldNamecall(self, ...)
end)

setreadonly(mt, true)

-- Prediction Settings
getgenv().PredictionEnabled = true
getgenv().PredictionVelocity = 0.165 -- Default delay offset
getgenv().AutoPingAdjust = true

AimbotTab:AddToggle({
    Name = "Prediction [Auto Adjust]",
    Default = true,
    Callback = function(v)
        getgenv().PredictionEnabled = v
    end
})

AimbotTab:AddSlider({
    Name = "Prediction Delay",
    Min = 0.05,
    Max = 0.3,
    Default = 0.165,
    Increment = 0.005,
    ValueName = "seconds",
    Callback = function(val)
        getgenv().PredictionVelocity = val
    end
})

-- Auto Ping Adjuster (runs in background)
task.spawn(function()
    while task.wait(1) do
        if AutoPingAdjust then
            local ping = math.clamp(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue(), 50, 300)
            getgenv().PredictionVelocity = ping / 1000
        end
    end
end)

-- Modified GetClosestHead with Prediction
local function PredictedHead()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local Camera = workspace.CurrentCamera
    local Closest, Distance = nil, math.huge

    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("Head") then
            local Head = v.Character.Head
            local Hum = v.Character:FindFirstChildOfClass("Humanoid")
            if Hum and Hum.Health > 0 and (v.Team ~= LocalPlayer.Team) then
                local pos, visible = Camera:WorldToViewportPoint(Head.Position)
                if visible then
                    local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if dist < Distance then
                        Distance = dist
                        if PredictionEnabled then
                            local root = v.Character:FindFirstChild("HumanoidRootPart")
                            if root and root.Velocity then
                                Closest = Head.Position + (root.Velocity * PredictionVelocity)
                            else
                                Closest = Head.Position
                            end
                        else
                            Closest = Head.Position
                        end
                    end
                end
            end
        end
    end

    return Closest
end

-- Settings
getgenv().WallcheckEnabled = true
getgenv().WallbangEnabled = true

AimbotTab:AddToggle({
    Name = "WallCheck 3D",
    Default = true,
    Callback = function(v)
        getgenv().WallcheckEnabled = v
    end
})

AimbotTab:AddToggle({
    Name = "Wallbang [Bypass Wall]",
    Default = true,
    Callback = function(v)
        getgenv().WallbangEnabled = v
    end
})

-- Wallcheck Function
local function IsVisible(targetPosition)
    local origin = workspace.CurrentCamera.CFrame.Position
    local direction = (targetPosition - origin).Unit * 1000

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {game:GetService("Players").LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist

    local result = workspace:Raycast(origin, direction, rayParams)

    if result then
        local hitPart = result.Instance
        if hitPart and hitPart:IsDescendantOf(game.Players.LocalPlayer.Character) then
            return true
        end

        if WallbangEnabled then
            return true -- force shoot through wall
        else
            return false -- blocked by wall
        end
    end

    return true -- no obstruction
end

-- Settings
getgenv().AutoFireEnabled = true
getgenv().SmartWaitDelay = 0.05
getgenv().AntiOverkillEnabled = true

AimbotTab:AddToggle({
    Name = "Auto Fire",
    Default = true,
    Callback = function(v)
        getgenv().AutoFireEnabled = v
    end
})

AimbotTab:AddSlider({
    Name = "Smart Wait Delay",
    Min = 0.01,
    Max = 0.3,
    Default = 0.05,
    Increment = 0.01,
    ValueName = "s",
    Callback = function(val)
        getgenv().SmartWaitDelay = val
    end
})

AimbotTab:AddToggle({
    Name = "Anti Overkill (Auto Next)",
    Default = true,
    Callback = function(v)
        getgenv().AntiOverkillEnabled = v
    end
})

-- Smart Auto Fire Loop
task.spawn(function()
    while task.wait(getgenv().SmartWaitDelay) do
        local Target = PredictedHead and PredictedHead()
        if Target and getgenv().AutoFireEnabled and IsVisible(Target) then
            mouse1press()
            task.wait(0.01)
            mouse1release()
        end
    end
end)

-- Anti Overkill (auto switch target)
task.spawn(function()
    while task.wait(0.1) do
        if getgenv().AntiOverkillEnabled then
            local closest = nil
            for _, p in pairs(game.Players:GetPlayers()) do
                if p ~= game.Players.LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") then
                    if p.Character.Humanoid.Health > 0 then
                        closest = p
                        break
                    end
                end
            end
            if closest then
                -- instantly retarget
                PredictedHead = function()
                    return closest.Character.Head.Position
                end
            end
        end
    end
end)

-- Settings
getgenv().GunModEnabled = true

AimbotTab:AddToggle({
    Name = "Anti Recoil / Spread",
    Default = true,
    Callback = function(v)
        getgenv().GunModEnabled = v
    end
})

-- Gun Mod Logic
task.spawn(function()
    while task.wait(1) do
        if getgenv().GunModEnabled then
            for _, v in next, getgc(true) do
                if typeof(v) == "table" and rawget(v, "Spread") then
                    pcall(function()
                        rawset(v, "Spread", 0)
                        rawset(v, "BaseSpread", 0)
                        rawset(v, "MinCamRecoil", Vector3.new())
                        rawset(v, "MaxCamRecoil", Vector3.new())
                        rawset(v, "MinRotRecoil", Vector3.new())
                        rawset(v, "MaxRotRecoil", Vector3.new())
                        rawset(v, "MinTransRecoil", Vector3.new())
                        rawset(v, "MaxTransRecoil", Vector3.new())
                        rawset(v, "ScopeSpeed", 100)
                    end)
                end
            end
        end
    end
end)

-- Settings
getgenv().StickyLockEnabled = true
getgenv().TeamCheck = true
getgenv().IgnoreDowned = true
getgenv().InvisibleBypass = true

AimbotTab:AddToggle({
    Name = "Sticky Lock Target",
    Default = true,
    Callback = function(v)
        getgenv().StickyLockEnabled = v
    end
})

AimbotTab:AddToggle({
    Name = "Team Check",
    Default = true,
    Callback = function(v)
        getgenv().TeamCheck = v
    end
})

AimbotTab:AddToggle({
    Name = "Ignore Downed Players",
    Default = true,
    Callback = function(v)
        getgenv().IgnoreDowned = v
    end
})

AimbotTab:AddToggle({
    Name = "Invisible Target Bypass",
    Default = true,
    Callback = function(v)
        getgenv().InvisibleBypass = v
    end
})

-- Crosshair Lock Icon
local cross = Drawing.new("Text")
cross.Text = "🎯"
cross.Size = 18
cross.Center = true
cross.Outline = true
cross.Visible = false

RunService.RenderStepped:Connect(function()
    if getgenv().StickyLockEnabled and Target and Target.Character and Target.Character:FindFirstChild("Head") then
        local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(Target.Character.Head.Position)
        if onScreen then
            cross.Position = Vector2.new(screenPos.X, screenPos.Y)
            cross.Visible = true
        else
            cross.Visible = false
        end
    else
        cross.Visible = false
    end
end)

-- Settings
getgenv().ESPEnabled = true
getgenv().NameESPEnabled = true
getgenv().HitmarkerEnabled = true

VisualTab:AddToggle({
    Name = "ESP Box (Color Team)",
    Default = true,
    Callback = function(v)
        getgenv().ESPEnabled = v
    end
})

VisualTab:AddToggle({
    Name = "Name ESP",
    Default = true,
    Callback = function(v)
        getgenv().NameESPEnabled = v
    end
})

VisualTab:AddToggle({
    Name = "Hitmarker Effect",
    Default = true,
    Callback = function(v)
        getgenv().HitmarkerEnabled = v
    end
})

-- ESP logic
local function createESP(plr)
    if not plr.Character or not plr.Character:FindFirstChild("Head") then return end

    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Filled = false
    box.Visible = false

    local name = Drawing.new("Text")
    name.Size = 14
    name.Center = true
    name.Outline = true
    name.Visible = false

    RunService.RenderStepped:Connect(function()
        if not getgenv().ESPEnabled then
            box.Visible = false
            name.Visible = false
            return
        end

        local char = plr.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") and plr ~= LocalPlayer then
            local pos, onscreen = camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
            if onscreen then
                local color = (plr.Team ~= LocalPlayer.Team) and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
                box.Visible = true
                box.Color = color
                box.Size = Vector2.new(50, 70)
                box.Position = Vector2.new(pos.X - 25, pos.Y - 35)

                if getgenv().NameESPEnabled then
                    name.Visible = true
                    name.Text = plr.Name
                    name.Position = Vector2.new(pos.X, pos.Y - 45)
                    name.Color = color
                else
                    name.Visible = false
                end
            else
                box.Visible = false
                name.Visible = false
            end
        else
            box.Visible = false
            name.Visible = false
        end
    end)
end

-- Create ESP for all players
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then createESP(p) end
end

Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then
        p.CharacterAdded:Connect(function()
            wait(1)
            createESP(p)
        end)
    end
end)

-- Hitmarker Effect
local function showHit()
    if not getgenv().HitmarkerEnabled then return end
    local hit = Drawing.new("Text")
    hit.Text = "HIT!"
    hit.Size = 24
    hit.Center = true
    hit.Outline = true
    hit.Color = Color3.new(1, 1, 1)
    hit.Position = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/1.8)
    hit.Visible = true
    delay(0.2, function()
        hit:Remove()
    end)
end

-- Connect hit event (assuming BulletHitEvent exists)
local Remote = game.ReplicatedStorage:FindFirstChild("BulletHit")
if Remote then
    Remote.OnClientEvent:Connect(function()
        showHit()
    end)
end

-- Settings
getgenv().StrictHeadLock = true
getgenv().PredictionBooster = true
getgenv().UseFakeInput = true
getgenv().CrossVectorEnabled = true

AimbotTab:AddToggle({
    Name = "Strict Head Lock",
    Default = true,
    Callback = function(v)
        getgenv().StrictHeadLock = v
    end
})

AimbotTab:AddToggle({
    Name = "Prediction Booster",
    Default = true,
    Callback = function(v)
        getgenv().PredictionBooster = v
    end
})

AimbotTab:AddToggle({
    Name = "Fake Input Aimbot",
    Default = true,
    Callback = function(v)
        getgenv().UseFakeInput = v
    end
})

AimbotTab:AddToggle({
    Name = "Cross Vector Sync",
    Default = true,
    Callback = function(v)
        getgenv().CrossVectorEnabled = v
    end
})

-- HeadLock Strict & Prediction
function GetPredictedPosition(targetPart, velocity)
    local ping = game.Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    local pingAdjust = getgenv().PredictionBooster and (ping / 1000) or 0.165
    return targetPart.Position + (velocity * pingAdjust)
end

-- Fake Input Logic
function AimAt(position)
    if getgenv().UseFakeInput then
        mousemoverel((position.X - camera.ViewportSize.X / 2) * 0.1, (position.Y - camera.ViewportSize.Y / 2) * 0.1)
    else
        mouse1press()
        wait()
        mouse1release()
    end
end

-- Lock Target to Head Only
RunService.RenderStepped:Connect(function()
    if getgenv().StrictHeadLock and Target and Target.Character and Target.Character:FindFirstChild("Head") then
        local predicted = GetPredictedPosition(Target.Character.Head, Target.Character.HumanoidRootPart.Velocity)
        local screenPos, onScreen = camera:WorldToViewportPoint(predicted)

        if onScreen and getgenv().CrossVectorEnabled then
            AimAt(Vector2.new(screenPos.X, screenPos.Y))
        end
    end
end)

-- Settings
getgenv().MaxDistance = 500
getgenv().EnableDistanceCheck = true
getgenv().AutoSwitchTarget = true
getgenv().TargetFreezeBypass = true
getgenv().IgnorePartShield = true
getgenv().SafeTargetCheck = true

AimbotTab:AddToggle({
    Name = "Auto Switch Target (Anti Overkill)",
    Default = true,
    Callback = function(v)
        getgenv().AutoSwitchTarget = v
    end
})

AimbotTab:AddToggle({
    Name = "Target Freeze Bypass",
    Default = true,
    Callback = function(v)
        getgenv().TargetFreezeBypass = v
    end
})

AimbotTab:AddToggle({
    Name = "Ignore Shielded Targets",
    Default = true,
    Callback = function(v)
        getgenv().IgnorePartShield = v
    end
})

AimbotTab:AddToggle({
    Name = "Safe Target Check (No Dead/Invalid)",
    Default = true,
    Callback = function(v)
        getgenv().SafeTargetCheck = v
    end
})

AimbotTab:AddSlider({
    Name = "Max Distance (studs)",
    Min = 100,
    Max = 1000,
    Default = 500,
    Callback = function(v)
        getgenv().MaxDistance = v
    end
})

-- Target Filter Logic
function IsValidTarget(target)
    if not target or not target.Character then return false end
    if getgenv().EnableDistanceCheck and (target:DistanceFromCharacter(game.Players.LocalPlayer.Character.HumanoidRootPart.Position) > getgenv().MaxDistance) then
        return false
    end
    if getgenv().SafeTargetCheck and not target.Character:FindFirstChild("Humanoid") then return false end
    if getgenv().IgnorePartShield and target.Character:FindFirstChild("ForceField") then return false end
    if getgenv().TargetFreezeBypass and target.Character.HumanoidRootPart.Anchored then return true end
    return true
end

-- Auto Switch After Kill
game:GetService("RunService").RenderStepped:Connect(function()
    if getgenv().AutoSwitchTarget and Target and Target.Character and Target.Character:FindFirstChild("Humanoid") then
        if Target.Character.Humanoid.Health <= 0 then
            Target = GetNewTarget() -- Replace with your GetNewTarget function
        end
    end
end)
