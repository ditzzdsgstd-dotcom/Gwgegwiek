-- YoxanXHub V2.1 | Hypershot Gunfight | Part 1/10
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/1nig1htmare1234/SCRIPTS/main/Orion.lua"))()
local Window = OrionLib:MakeWindow({Name="YoxanXHub V2.1 | Hypershot Gunfight", HidePremium=false, SaveConfig=false, IntroText="YoxanXHub Loaded", ConfigFolder="YoxanX"})

local AimTab = Window:MakeTab({Name="Silent Aim", Icon="🎯", PremiumOnly=false})
local GunTab = Window:MakeTab({Name="Gun Mods", Icon="🔫", PremiumOnly=false})

getgenv().SilentAim = true
getgenv().AutoFire = true
getgenv().AntiRecoil = true
getgenv().AntiSpread = true

AimTab:Toggle("Silent Aim (100% Head)", getgenv().SilentAim, function(v)
    getgenv().SilentAim = v
end)

AimTab:Toggle("Auto Fire", getgenv().AutoFire, function(v)
    getgenv().AutoFire = v
end)

GunTab:Toggle("Anti Recoil", getgenv().AntiRecoil, function(v)
    getgenv().AntiRecoil = v
end)

GunTab:Toggle("Anti Spread", getgenv().AntiSpread, function(v)
    getgenv().AntiSpread = v
end)

-- Gun Mods (Recoil & Spread)
spawn(function()
    while task.wait(1) do
        if getgenv().AntiRecoil or getgenv().AntiSpread then
            for _, v in next, getgc(true) do
                if typeof(v) == 'table' and rawget(v, 'Spread') then
                    if getgenv().AntiSpread then
                        rawset(v, 'Spread', 0)
                        rawset(v, 'BaseSpread', 0)
                    end
                    if getgenv().AntiRecoil then
                        rawset(v, 'MinCamRecoil', Vector3.new())
                        rawset(v, 'MaxCamRecoil', Vector3.new())
                        rawset(v, 'MinRotRecoil', Vector3.new())
                        rawset(v, 'MaxRotRecoil', Vector3.new())
                        rawset(v, 'MinTransRecoil', Vector3.new())
                        rawset(v, 'MaxTransRecoil', Vector3.new())
                    end
                end
            end
        end
    end
end)

-- YoxanXHub V2.1 | Part 2/10 - ESP & Visibility
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

getgenv().ESPEnabled = true
getgenv().WallCheck = true
getgenv().VisibleOnly = true

local VisualTab = Window:MakeTab({Name="ESP", Icon="👁️", PremiumOnly=false})
VisualTab:Toggle("Enable ESP", getgenv().ESPEnabled, function(v)
    getgenv().ESPEnabled = v
end)
VisualTab:Toggle("WallCheck 3D", getgenv().WallCheck, function(v)
    getgenv().WallCheck = v
end)
VisualTab:Toggle("Visible Targets Only", getgenv().VisibleOnly, function(v)
    getgenv().VisibleOnly = v
end)

local function CreateESP(plr)
    if plr == LocalPlayer then return end
    local box = Instance.new("BoxHandleAdornment", plr.Character)
    box.Name = "YoxanXESP"
    box.Size = Vector3.new(2, 5, 1)
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Adornee = plr.Character:FindFirstChild("HumanoidRootPart")
    box.Color3 = (plr.Team == LocalPlayer.Team) and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    box.Transparency = 0.5
end

local function ClearESP()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr.Character and plr.Character:FindFirstChild("YoxanXESP") then
            plr.Character:FindFirstChild("YoxanXESP"):Destroy()
        end
    end
end

RunService.RenderStepped:Connect(function()
    if getgenv().ESPEnabled then
        ClearESP()
        for _, plr in pairs(Players:GetPlayers()) do
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local isEnemy = plr.Team ~= LocalPlayer.Team
                local isVisible = true
                if getgenv().VisibleOnly then
                    local ray = Ray.new(Camera.CFrame.Position, (plr.Character.HumanoidRootPart.Position - Camera.CFrame.Position).unit * 1000)
                    local hit = workspace:FindPartOnRay(ray, LocalPlayer.Character)
                    isVisible = hit and hit:IsDescendantOf(plr.Character)
                end
                if isEnemy and isVisible then
                    CreateESP(plr)
                end
            end
        end
    else
        ClearESP()
    end
end)

-- YoxanXHub V2.1 | Part 3/10 - Smart Aim Logic
local TargetTab = Window:MakeTab({Name="Targeting", Icon="🎯", PremiumOnly=false})

getgenv().SmartDelay = 0.05
getgenv().PingAdjust = true
getgenv().PriorityMode = "Distance" -- options: Distance, HP, FOV

TargetTab:Slider("Smart Wait Delay (seconds)", 1, 50, getgenv().SmartDelay * 1000, function(v)
    getgenv().SmartDelay = v / 1000
end)

TargetTab:Toggle("Auto Ping Adjuster", getgenv().PingAdjust, function(v)
    getgenv().PingAdjust = v
end)

TargetTab:AddDropdown({
    Name = "Aim Priority",
    Default = "Distance",
    Options = {"Distance", "HP", "FOV"},
    Callback = function(v)
        getgenv().PriorityMode = v
    end
})

-- Priority Function Example
function GetTarget()
    local closest = nil
    local shortest = math.huge
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr ~= game.Players.LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (plr.Character.HumanoidRootPart.Position - workspace.CurrentCamera.CFrame.Position).magnitude
            local hp = plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health or 100

            if getgenv().PriorityMode == "Distance" and dist < shortest then
                closest = plr
                shortest = dist
            elseif getgenv().PriorityMode == "HP" and hp < shortest then
                closest = plr
                shortest = hp
            elseif getgenv().PriorityMode == "FOV" then
                -- FOV calculation (not implemented fully for demo)
                closest = plr
            end
        end
    end
    return closest
end

function GetHitPart(character)
    return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart") or character:FindFirstChildWhichIsA("Part")
end

-- YoxanXHub V2.1 | Part 4/10 - Lock & Filtering
local LockTab = Window:MakeTab({Name="Lock Settings", Icon="🔐", PremiumOnly=false})

getgenv().StickyLock = true
getgenv().IgnoreDowned = true
getgenv().AntiKnockback = true
getgenv().CheckTeam = true

LockTab:Toggle("Sticky Lock", getgenv().StickyLock, function(v)
    getgenv().StickyLock = v
end)
LockTab:Toggle("Team Check", getgenv().CheckTeam, function(v)
    getgenv().CheckTeam = v
end)
LockTab:Toggle("Ignore Downed Players", getgenv().IgnoreDowned, function(v)
    getgenv().IgnoreDowned = v
end)
LockTab:Toggle("Anti Knockback", getgenv().AntiKnockback, function(v)
    getgenv().AntiKnockback = v
end)

-- Example filtering (used later in lock logic)
function IsValidTarget(plr)
    if not plr or plr == game.Players.LocalPlayer then return false end
    if getgenv().CheckTeam and plr.Team == game.Players.LocalPlayer.Team then return false end
    if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then return false end
    if getgenv().IgnoreDowned and plr.Character:FindFirstChild("Downed") then return false end
    return true
end

-- Apply Anti Knockback logic (can be expanded)
if getgenv().AntiKnockback then
    local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = false
    end
end

-- YoxanXHub V2.1 | Part 5/10 - Smart Fire + Wallbang
local FireTab = Window:MakeTab({Name="Combat Logic", Icon="💥", PremiumOnly=false})

getgenv().AutoFire = true
getgenv().Wallbang = true
getgenv().MaxLockDistance = 500

FireTab:Toggle("Auto Fire", getgenv().AutoFire, function(v)
    getgenv().AutoFire = v
end)
FireTab:Toggle("Wallbang Enabled", getgenv().Wallbang, function(v)
    getgenv().Wallbang = v
end)
FireTab:Slider("Max Lock Distance", 100, 2000, getgenv().MaxLockDistance, function(v)
    getgenv().MaxLockDistance = v
end)

-- Wallcheck Logic (Raycast)
function IsVisible(part)
    if not part then return false end
    local origin = workspace.CurrentCamera.CFrame.Position
    local direction = (part.Position - origin)
    local ray = Ray.new(origin, direction)
    local hit = workspace:FindPartOnRay(ray, game.Players.LocalPlayer.Character, false, true)
    if not hit then return true end
    if getgenv().Wallbang then return true end
    return hit:IsDescendantOf(part.Parent)
end

-- Auto Fire Handler
function TryFire(target)
    if getgenv().AutoFire and target and target.Character then
        local head = target.Character:FindFirstChild("Head")
        if head and IsVisible(head) then
            mouse1click()
        end
    end
end

-- YoxanXHub V2.1 | Part 6/10 - ESP Full System
local EspTab = Window:MakeTab({Name="ESP & Visuals", Icon="🔭", PremiumOnly=false})

getgenv().EnableESP = true
getgenv().ESPColorTeam = true
getgenv().ShowHealth = true
getgenv().ShowBox = true
getgenv().ShowHitText = true

EspTab:Toggle("Enable ESP", getgenv().EnableESP, function(v)
    getgenv().EnableESP = v
end)
EspTab:Toggle("Team Color ESP", getgenv().ESPColorTeam, function(v)
    getgenv().ESPColorTeam = v
end)
EspTab:Toggle("Show Health Bar", getgenv().ShowHealth, function(v)
    getgenv().ShowHealth = v
end)
EspTab:Toggle("Show Box", getgenv().ShowBox, function(v)
    getgenv().ShowBox = v
end)
EspTab:Toggle("Hitmarker Text", getgenv().ShowHitText, function(v)
    getgenv().ShowHitText = v
end)

-- Simple ESP Drawing (text only, basic for mobile)
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

RunService.RenderStepped:Connect(function()
    if not getgenv().EnableESP then return end
    for _, v in pairs(game.Players:GetPlayers()) do
        if v ~= game.Players.LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local pos, onScreen = Camera:WorldToViewportPoint(v.Character.HumanoidRootPart.Position)
            if onScreen then
                local name = v.Name
                local hp = v.Character:FindFirstChild("Humanoid") and math.floor(v.Character.Humanoid.Health) or 0
                local teamColor = v.Team == game.Players.LocalPlayer.Team and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                if getgenv().ESPColorTeam then
                    Drawing.new("Text", {
                        Text = name .. " [".. hp .. "%]",
                        Position = Vector2.new(pos.X, pos.Y),
                        Color = teamColor,
                        Center = true,
                        Outline = true,
                        Size = 15,
                        Visible = true,
                        RemoveOnOutOfScreen = true
                    })
                end
            end
        end
    end
end)

-- Hitmarker (simplified)
function ShowHit()
    if getgenv().ShowHitText then
        local hitText = Drawing.new("Text")
        hitText.Text = "Hit"
        hitText.Color = Color3.fromRGB(255, 255, 255)
        hitText.Size = 18
        hitText.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y - 80)
        hitText.Center = true
        hitText.Outline = true
        hitText.Visible = true
        task.delay(0.3, function() hitText:Remove() end)
    end
end

-- YoxanXHub V2.1 | Part 7/10 - Bypass & Target Logic
local TargetTab = Window:MakeTab({Name="Target Logic", Icon="🎯", PremiumOnly=false})

getgenv().IgnoreShields = true
getgenv().BypassFreeze = true
getgenv().MultiTarget = true
getgenv().EnableHitPriority = true

TargetTab:Toggle("Ignore Part Shields", getgenv().IgnoreShields, function(v)
    getgenv().IgnoreShields = v
end)
TargetTab:Toggle("Freeze Bypass", getgenv().BypassFreeze, function(v)
    getgenv().BypassFreeze = v
end)
TargetTab:Toggle("Multi Target Mode", getgenv().MultiTarget, function(v)
    getgenv().MultiTarget = v
end)
TargetTab:Toggle("Headshot Priority", getgenv().EnableHitPriority, function(v)
    getgenv().EnableHitPriority = v
end)

-- Fallback Part Selection
function GetBestHitPart(char)
    if not char then return nil end
    local head = char:FindFirstChild("Head")
    local torso = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if getgenv().EnableHitPriority and head then return head end
    if torso then return torso end
    return head or torso
end

-- Shield Detection
function IsShielded(part)
    if not getgenv().IgnoreShields then return false end
    if part and part:IsA("BasePart") and (part.Name:lower():find("force") or part.Name:lower():find("shield")) then
        return true
    end
    return false
end

-- YoxanXHub V2.1 | Part 8/10 - Locking Rules
local LockTab = Window:MakeTab({Name="Lock Control", Icon="🔒", PremiumOnly=false})

getgenv().StickyLock = true
getgenv().TeamCheck = true
getgenv().BypassInvis = true
getgenv().AntiOverkill = true
getgenv().MaxLockDistance = 500
getgenv().MaxLockAngle = 90 -- degrees

LockTab:Toggle("Sticky Lock", getgenv().StickyLock, function(v)
    getgenv().StickyLock = v
end)
LockTab:Toggle("Team Check", getgenv().TeamCheck, function(v)
    getgenv().TeamCheck = v
end)
LockTab:Toggle("Bypass Invisible Targets", getgenv().BypassInvis, function(v)
    getgenv().BypassInvis = v
end)
LockTab:Toggle("Anti Overkill", getgenv().AntiOverkill, function(v)
    getgenv().AntiOverkill = v
end)
LockTab:Slider("Max Lock Distance", 100, 1000, getgenv().MaxLockDistance, function(v)
    getgenv().MaxLockDistance = v
end)
LockTab:Slider("Max Lock Angle", 15, 180, getgenv().MaxLockAngle, function(v)
    getgenv().MaxLockAngle = v
end)

function IsValidTarget(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
    if getgenv().TeamCheck and player.Team == game.Players.LocalPlayer.Team then return false end
    if getgenv().BypassInvis and player.Character:FindFirstChild("Transparency") and player.Character.Transparency == 1 then return true end
    local dist = (player.Character.HumanoidRootPart.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
    if dist > getgenv().MaxLockDistance then return false end
    return true
end

-- YoxanXHub V2.1 | Part 9/10 - Silent Fire & Prediction
local SilentTab = Window:MakeTab({Name="Silent Core", Icon="🎯", PremiumOnly=false})

getgenv().SilentAim = true
getgenv().WallCheck3D = true
getgenv().ShowCrosshairLock = true
getgenv().AutoPrediction = true

SilentTab:Toggle("Silent Aim Enabled", getgenv().SilentAim, function(v)
    getgenv().SilentAim = v
end)
SilentTab:Toggle("WallCheck 3D", getgenv().WallCheck3D, function(v)
    getgenv().WallCheck3D = v
end)
SilentTab:Toggle("Crosshair Lock Indicator", getgenv().ShowCrosshairLock, function(v)
    getgenv().ShowCrosshairLock = v
end)
SilentTab:Toggle("Auto Prediction", getgenv().AutoPrediction, function(v)
    getgenv().AutoPrediction = v
end)

-- Simple Prediction
function GetPredictedPosition(part, velocity)
    if not part then return nil end
    local ping = game.Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    local delay = (getgenv().AutoPrediction and ping / 1000) or 0.1
    return part.Position + (velocity * delay)
end

-- Raycast WallCheck
function IsClearSight(from, to)
    if not getgenv().WallCheck3D then return true end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {game.Players.LocalPlayer.Character}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    local result = workspace:Raycast(from, (to - from), params)
    return not result
end

-- Silent Shoot Handler
function SilentShoot(target)
    if getgenv().SilentAim and target and target.Character then
        local head = target.Character:FindFirstChild("Head")
        local vel = target.Character:FindFirstChild("HumanoidRootPart") and target.Character.HumanoidRootPart.Velocity or Vector3.new()
        local predicted = GetPredictedPosition(head, vel)
        if head and IsClearSight(workspace.CurrentCamera.CFrame.Position, predicted) then
            -- Shoot logic here
            mouse1click()
        end
    end
end

-- YoxanXHub V2.1 | Part 10/10 - Finalization & Stats
local StatsTab = Window:MakeTab({Name="Stats & Debug", Icon="📊", PremiumOnly=false})

-- FPS & Ping Display
local fps = 0
local last = tick()
game:GetService("RunService").RenderStepped:Connect(function()
    local now = tick()
    fps = math.floor(1 / (now - last))
    last = now
end)

StatsTab:AddParagraph("📊 FPS Tracker", function()
    return "FPS: " .. fps
end)

StatsTab:AddParagraph("📶 Ping", function()
    return "Ping: " .. math.floor(game.Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) .. " ms"
end)

-- Locked Target Display
getgenv().CurrentTarget = nil
StatsTab:AddParagraph("🎯 Locked Target", function()
    return getgenv().CurrentTarget and getgenv().CurrentTarget.Name or "No Target"
end)

-- Player Count
StatsTab:AddParagraph("👥 Players in Server", function()
    return "Players: " .. #game.Players:GetPlayers()
end)

-- Bypass Fake Input for AntiCheat
local function BypassInput()
    local vim = game:GetService("VirtualInputManager")
    task.spawn(function()
        while true do
            if getgenv().SilentAim and getgenv().AutoFire then
                vim:SendMouseButtonEvent(500, 500, 0, true, game, 0)
                vim:SendMouseButtonEvent(500, 500, 0, false, game, 0)
            end
            task.wait(0.1)
        end
    end)
end
BypassInput()

-- Final Notification
OrionLib:MakeNotification({
    Name = "YoxanXHub V2.1",
    Content = "All features loaded successfully 🔥",
    Time = 6
})

OrionLib:MakeNotification({
    Name = "YoxanXHub V2.1",
    Content = "YoxanXHub Loaded | Ready",
    Image = "rbxassetid://7733964641",
    Time = 4
})
