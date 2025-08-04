-- YoxanXHub V2 | Hypershot Gunfight | 1/20
local orionlib = loadstring(game:HttpGet("https://raw.githubusercontent.com/1nig1htmare1234/SCRIPTS/main/Orion.lua"))()

getgenv().OrionLoaded = false
repeat wait() until OrionLib

local OrionLib = OrionLib
local Window = OrionLib:MakeWindow({
    Name = "YoxanXHub | Hypershot V2",
    HidePremium = false,
    SaveConfig = false,
    ConfigFolder = "YoxanX",
})

getgenv().OrionWindow = Window
getgenv().SilentAim = true
getgenv().ESP = true
getgenv().AutoFire = true -- Tetap aktif otomatis
getgenv().SmartWaitDelay = 0.05
getgenv().WallCheck = true
getgenv().TeamCheck = true

OrionLib:MakeNotification({
    Name = "YoxanXHub V2 Loaded",
    Content = "Ready to Aim. 100% Headshot Enabled.",
    Image = "rbxassetid://4483345998",
    Time = 5
})

-- Tabs
local Tab_Main = Window:MakeTab({
    Name = "Main",
    Icon = "🔫",
    PremiumOnly = false
})

local Tab_Visual = Window:MakeTab({
    Name = "Visual",
    Icon = "👁️",
    PremiumOnly = false
})

local Tab_Safety = Window:MakeTab({
    Name = "Safety",
    Icon = "🛡️",
    PremiumOnly = false
})

local Tab_Debug = Window:MakeTab({
    Name = "Info",
    Icon = "📊",
    PremiumOnly = false
})

-- Toggles UI
Tab_Main:AddToggle({
    Name = "Silent Aim",
    Default = true,
    Callback = function(v)
        getgenv().SilentAim = v
    end
})

Tab_Main:AddSlider({
    Name = "Smart Delay",
    Min = 0,
    Max = 0.2,
    Default = 0.05,
    Increment = 0.01,
    Callback = function(v)
        getgenv().SmartWaitDelay = v
    end
})

Tab_Main:AddToggle({
    Name = "Wall Check (3D)",
    Default = true,
    Callback = function(v)
        getgenv().WallCheck = v
    end
})

Tab_Main:AddToggle({
    Name = "Team Check",
    Default = true,
    Callback = function(v)
        getgenv().TeamCheck = v
    end
})

-- YoxanXHub V2 | Part 2/20 - Silent Aim Core
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

getgenv().TargetPart = "Head"

function IsVisible(targetPart)
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * 1000
    local result = workspace:Raycast(origin, direction, RaycastParams.new())
    return result == nil or result.Instance:IsDescendantOf(targetPart.Parent)
end

function GetClosestTarget()
    local closestTarget, shortestDistance = nil, math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(TargetPart) then
            local targetPart = player.Character[TargetPart]
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
            local teamCheck = not getgenv().TeamCheck or player.Team ~= LocalPlayer.Team
            local visibleCheck = not getgenv().WallCheck or IsVisible(targetPart)

            if teamCheck and visibleCheck and distance < shortestDistance then
                closestTarget = targetPart
                shortestDistance = distance
            end
        end
    end
    return closestTarget
end

-- Hook Mouse/Remote
local __namecall
__namecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if getgenv().SilentAim and tostring(self) == "Hit" and method == "FireServer" then
        local target = GetClosestTarget()
        if target then
            args[1] = target.Position
            args[2] = target
            return __namecall(self, unpack(args))
        end
    end

    return __namecall(self, ...)
end)

-- YoxanXHub V2 | Part 3/20 - Smart Lock Priority
getgenv().SmartLockMode = "ClosestCrosshair" -- "ClosestCrosshair", "LowestHP", "Nearest"

local function GetHealth(player)
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health or math.huge
end

function GetSmartTarget()
    local closestTarget = nil
    local closestValue = math.huge

    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer and player.Character and player.Character:FindFirstChild(getgenv().TargetPart) then
            local head = player.Character[getgenv().TargetPart]
            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local teamCheck = not getgenv().TeamCheck or player.Team ~= game.Players.LocalPlayer.Team
                local visibleCheck = not getgenv().WallCheck or IsVisible(head)
                if teamCheck and visibleCheck then
                    if getgenv().SmartLockMode == "Nearest" then
                        local dist = (LocalPlayer.Character.Head.Position - head.Position).Magnitude
                        if dist < closestValue then
                            closestValue = dist
                            closestTarget = head
                        end
                    elseif getgenv().SmartLockMode == "LowestHP" then
                        local hp = GetHealth(player)
                        if hp < closestValue then
                            closestValue = hp
                            closestTarget = head
                        end
                    elseif getgenv().SmartLockMode == "ClosestCrosshair" then
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                        if distance < closestValue then
                            closestValue = distance
                            closestTarget = head
                        end
                    end
                end
            end
        end
    end

    return closestTarget
end

-- Replace GetClosestTarget with Smart Lock
GetClosestTarget = GetSmartTarget

-- YoxanXHub V2 | Part 4/20 - Prediction Strong Mode
getgenv().PredictionEnabled = true
getgenv().PredictionMultiplier = 0.225 -- Lebih tinggi untuk kecepatan lari
getgenv().PredictionFallback = true

local function GetPing()
    local stats = game:GetService("Stats"):FindFirstChild("PerformanceStats")
    if stats and stats:FindFirstChild("Ping") then
        local pingText = stats.Ping.Text:match("%d+")
        return tonumber(pingText) or 50
    end
    return 50
end

local function PredictPosition(part)
    local velocity = part.Velocity or Vector3.zero
    local ping = GetPing()
    local delay = (ping / 1000) + getgenv().SmartWaitDelay
    local offset = velocity * delay * getgenv().PredictionMultiplier
    local result = part.Position + offset

    -- Fallback jika velocity 0 atau prediksi tidak valid
    if getgenv().PredictionFallback and offset.Magnitude < 0.5 then
        result = part.Position
    end
    return result
end

-- Silent Aim override
local __namecall
__namecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = { ... }

    if getgenv().SilentAim and tostring(self) == "Hit" and method == "FireServer" then
        local target = GetClosestTarget()
        if target then
            local predicted = PredictPosition(target)
            args[1] = predicted
            args[2] = target
            return __namecall(self, unpack(args))
        end
    end

    return __namecall(self, ...)
end)

-- YoxanXHub V2 | Part 5/20 - Smart Wait + Anti Knockback + Auto Fire

getgenv().SmartWaitDelay = 0.05 -- Delay antar hit (bisa diubah via slider nanti)
getgenv().AutoFire = true
getgenv().AntiKnockback = true

-- Anti Knockback patch
if getgenv().AntiKnockback then
    local __index
    __index = hookmetamethod(game, "__index", function(self, key)
        if key == "Velocity" and tostring(self) == "HumanoidRootPart" then
            return Vector3.new(0, 0, 0)
        end
        return __index(self, key)
    end)
end

-- AutoFire Engine (menembak otomatis ke musuh saat target valid)
task.spawn(function()
    while task.wait(getgenv().SmartWaitDelay) do
        if getgenv().AutoFire and getgenv().SilentAim then
            local target = GetClosestTarget()
            if target then
                local args = {
                    [1] = PredictPosition(target),
                    [2] = target
                }
                local event = LocalPlayer.Character:FindFirstChild("Gun") and LocalPlayer.Character.Gun:FindFirstChild("Hit")
                if event then
                    event:FireServer(unpack(args))
                end
            end
        end
    end
end)

-- YoxanXHub V2 | Part 6/20 - ESP Full System
getgenv().ESPEnabled = true
getgenv().ESPTeamColor = true
getgenv().ESPBox = true
getgenv().ESPName = true

local function CreateESP(player)
    if player == LocalPlayer then return end
    local Billboard = Instance.new("BillboardGui")
    Billboard.Name = "YoxanX_ESP"
    Billboard.Adornee = player.Character and player.Character:FindFirstChild("Head")
    Billboard.AlwaysOnTop = true
    Billboard.Size = UDim2.new(0, 200, 0, 50)
    Billboard.StudsOffset = Vector3.new(0, 3, 0)
    Billboard.Parent = player.Character and player.Character:FindFirstChild("Head")

    local NameLabel = Instance.new("TextLabel", Billboard)
    NameLabel.Size = UDim2.new(1, 0, 1, 0)
    NameLabel.Text = player.Name
    NameLabel.TextColor3 = player.Team == LocalPlayer.Team and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    NameLabel.BackgroundTransparency = 1
    NameLabel.TextStrokeTransparency = 0.5
    NameLabel.Font = Enum.Font.SourceSansBold
    NameLabel.TextScaled = true
end

game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if getgenv().ESPEnabled then
            task.wait(1)
            CreateESP(player)
        end
    end)
end)

for _, player in ipairs(game.Players:GetPlayers()) do
    if player.Character and player ~= LocalPlayer and getgenv().ESPEnabled then
        CreateESP(player)
    end
end

-- YoxanXHub V2 | Part 7/20 - ESP Box + Wall Transparency

getgenv().ESPBox = true
getgenv().WallTransparency = true
getgenv().WallTransparencyValue = 0.2 -- Semakin kecil = semakin transparan

local function ApplyWallTransparency(target)
    if not target or not getgenv().WallTransparency then return end
    local cam = workspace.CurrentCamera
    local ray = Ray.new(cam.CFrame.Position, (target.Position - cam.CFrame.Position).Unit * 1000)
    local part, pos = workspace:FindPartOnRay(ray, LocalPlayer.Character, false, true)

    if part and part.Transparency < 0.9 and not part:IsDescendantOf(target.Parent) then
        part.Transparency = getgenv().WallTransparencyValue
        part.Material = Enum.Material.ForceField
    end
end

local function CreateESPBox(player)
    if player == LocalPlayer or not getgenv().ESPBox then return end
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "YoxanX_Box"
    box.Size = Vector3.new(3, 5, 1.5)
    box.Adornee = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Transparency = 0.4
    box.Color3 = player.Team == LocalPlayer.Team and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    box.Parent = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

for _, p in ipairs(game.Players:GetPlayers()) do
    if p ~= LocalPlayer and p.Character and getgenv().ESPBox then
        CreateESPBox(p)
    end
end

game:GetService("RunService").RenderStepped:Connect(function()
    if not getgenv().ESPBox and not getgenv().WallTransparency then return end
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if getgenv().ESPBox then
                local adorn = player.Character.HumanoidRootPart:FindFirstChild("YoxanX_Box")
                if not adorn then
                    CreateESPBox(player)
                end
            end
            if getgenv().WallTransparency then
                ApplyWallTransparency(player.Character.HumanoidRootPart)
            end
        end
    end
end)

-- YoxanXHub V2 | Part 8/20 - Hitmarker, Hit Sound, Crosshair Lock

getgenv().EnableHitmarker = true
getgenv().EnableHitSound = true
getgenv().EnableLockIcon = true

-- Hitmarker UI
local function ShowHitMarker()
    if not getgenv().EnableHitmarker then return end
    local marker = Instance.new("TextLabel")
    marker.Size = UDim2.new(0, 100, 0, 30)
    marker.Position = UDim2.new(0.5, -50, 0.5, -15)
    marker.BackgroundTransparency = 1
    marker.TextColor3 = Color3.new(1, 1, 1)
    marker.TextStrokeTransparency = 0
    marker.Font = Enum.Font.SourceSansBold
    marker.TextScaled = true
    marker.Text = "HIT"
    marker.Parent = game:GetService("CoreGui")

    task.delay(0.25, function()
        if marker then marker:Destroy() end
    end)
end

-- Hit sound
local function PlayHitSound()
    if not getgenv().EnableHitSound then return end
    local sound = Instance.new("Sound", workspace)
    sound.SoundId = "rbxassetid://12222225" -- Ganti dengan ID suara hit
    sound.Volume = 1
    sound:Play()
    game.Debris:AddItem(sound, 1)
end

-- Crosshair Lock Icon
local function CreateLockIcon()
    if not getgenv().EnableLockIcon then return end
    local gui = Instance.new("ScreenGui", game.CoreGui)
    gui.Name = "YoxanX_Lock"

    local img = Instance.new("ImageLabel", gui)
    img.Size = UDim2.new(0, 24, 0, 24)
    img.Position = UDim2.new(0.5, -12, 0.5, -12)
    img.BackgroundTransparency = 1
    img.Image = "rbxassetid://3926305904" -- Icon crosshair

    return gui
end

local LockGui = CreateLockIcon()

-- Hubungkan ke event Silent Aim Fire
function OnSuccessfulHit()
    ShowHitMarker()
    PlayHitSound()
end

-- YoxanXHub V2 | Part 9/20 - Sticky Lock, Freeze Bypass, Name Filter

getgenv().StickyTarget = true
getgenv().IgnoreFrozen = true
getgenv().IgnoreNames = { "Noob123", "AdminGuy", "TestDummy" }

local LastTarget = nil

function IsFrozen(target)
    local humanoid = target:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.PlatformStand or false
end

function IsNameIgnored(target)
    for _, name in ipairs(getgenv().IgnoreNames) do
        if string.lower(target.Name) == string.lower(name) then
            return true
        end
    end
    return false
end

function GetClosestTarget()
    local closest
    local shortest = math.huge
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            if not IsNameIgnored(player) then
                local distance = (player.Character.Head.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
                if distance < shortest and distance < 500 then
                    if getgenv().IgnoreFrozen and IsFrozen(player.Character) then
                        continue
                    end
                    closest = player
                    shortest = distance
                end
            end
        end
    end
    if getgenv().StickyTarget and LastTarget and LastTarget.Character and LastTarget.Character:FindFirstChild("Head") then
        return LastTarget
    else
        LastTarget = closest
        return closest
    end
end

-- YoxanXHub V2 | Part 10/20 - HP Filter, Team Check, Debug Info

getgenv().HPFilterEnabled = true
getgenv().HPThreshold = 100 -- Musuh dengan HP <= ini akan ditarget

getgenv().TeamCheck = true
getgenv().ShowDebug = true

local DebugGui = nil

-- Cek HP target
function CheckHP(target)
    local human = target:FindFirstChildOfClass("Humanoid")
    if not human then return false end
    return human.Health <= getgenv().HPThreshold
end

-- Cek Team target
function IsEnemy(target)
    local plr = game.Players:GetPlayerFromCharacter(target)
    if not plr then return true end
    if getgenv().TeamCheck and plr.Team == LocalPlayer.Team then return false end
    return true
end

-- Tampilkan info di layar
function UpdateDebugInfo(target)
    if not getgenv().ShowDebug then return end
    if DebugGui and DebugGui.Parent then
        DebugGui:Destroy()
    end

    DebugGui = Instance.new("ScreenGui", game.CoreGui)
    DebugGui.Name = "YoxanX_Debug"

    local info = Instance.new("TextLabel", DebugGui)
    info.Size = UDim2.new(0, 220, 0, 50)
    info.Position = UDim2.new(0, 15, 0.75, 0)
    info.BackgroundTransparency = 0.4
    info.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    info.BorderSizePixel = 0
    info.TextColor3 = Color3.fromRGB(0, 255, 127)
    info.TextStrokeTransparency = 0
    info.Font = Enum.Font.SourceSansBold
    info.TextSize = 18

    if target then
        local plr = game.Players:GetPlayerFromCharacter(target)
        local hp = target:FindFirstChildOfClass("Humanoid") and math.floor(target:FindFirstChildOfClass("Humanoid").Health) or 0
        info.Text = "🎯 Target: " .. (plr and plr.Name or "Unknown") .. "\n❤️ HP: " .. hp
    else
        info.Text = "No Target"
    end
end

-- YoxanXHub V2 | Part 11/20 - Smart Aim Priority, Smart Delay, Max Distance

getgenv().AimPriority = "Distance" -- Pilihan: "Distance", "HP", "Screen"
getgenv().SmartWaitDelay = 0.05
getgenv().MaxLockDistance = 500

-- Cek prioritas target
function EvaluateTarget(player)
    if not player.Character or not player.Character:FindFirstChild("Head") then return math.huge end
    local head = player.Character.Head
    local camPos = workspace.CurrentCamera.CFrame.Position
    local distance = (head.Position - camPos).Magnitude

    if getgenv().AimPriority == "HP" then
        local hp = player.Character:FindFirstChildOfClass("Humanoid") and player.Character:FindFirstChildOfClass("Humanoid").Health or 0
        return 100 - hp
    elseif getgenv().AimPriority == "Screen" then
        local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(head.Position)
        return onScreen and (screenPos - Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)).Magnitude or math.huge
    end

    return distance
end

function GetBestTarget()
    local best, bestScore = nil, math.huge
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            if not IsEnemy(player.Character) then continue end
            if getgenv().HPFilterEnabled and not CheckHP(player.Character) then continue end
            if getgenv().IgnoreFrozen and IsFrozen(player.Character) then continue end
            if IsNameIgnored(player) then continue end

            local score = EvaluateTarget(player)
            local dist = (player.Character.Head.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
            if dist <= getgenv().MaxLockDistance and score < bestScore then
                best = player
                bestScore = score
            end
        end
    end
    return best
end

--[[ YoxanXHub V2 | Part 12 - Gabungan UI dan Fungsi ]]
-- Pastikan ini dijalankan setelah OrionLib dan Tab sudah dibuat

getgenv().ForceHeadshot = true
getgenv().AntiKnockback = true

-- UI Togglenya:
Tab:Toggle("Force Headshot", getgenv().ForceHeadshot, function(t)
    getgenv().ForceHeadshot = t
end)

Tab:Toggle("Anti Knockback", getgenv().AntiKnockback, function(t)
    getgenv().AntiKnockback = t
end)

-- Fungsi warna ESP berdasarkan tim
function ColorByTeam(player)
    if player.Team == game.Players.LocalPlayer.Team then
        return Color3.fromRGB(0, 255, 0) -- Hijau untuk teman
    else
        return Color3.fromRGB(255, 0, 0) -- Merah untuk musuh
    end
end

-- Fungsi paksa Headshot
function GetHitPart(character)
    if getgenv().ForceHeadshot and character:FindFirstChild("Head") then
        return character.Head
    end
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
end

-- Fungsi Anti Knockback
if getgenv().AntiKnockback then
    game:GetService("RunService").Stepped:Connect(function()
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.Velocity = Vector3.new()
        end
    end)
end

--[[ YoxanXHub V2 | Part 13 - ESP Box, Name, Tracer + Toggle ]]
getgenv().ESP_Enabled = true
getgenv().ESP_Box = true
getgenv().ESP_Name = true
getgenv().ESP_Tracer = true

-- UI Toggle
Tab:Toggle("ESP Master Toggle", getgenv().ESP_Enabled, function(v)
    getgenv().ESP_Enabled = v
end)
Tab:Toggle("ESP Box", getgenv().ESP_Box, function(v)
    getgenv().ESP_Box = v
end)
Tab:Toggle("ESP Name", getgenv().ESP_Name, function(v)
    getgenv().ESP_Name = v
end)
Tab:Toggle("ESP Tracer", getgenv().ESP_Tracer, function(v)
    getgenv().ESP_Tracer = v
end)

local Run = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local Local = Players.LocalPlayer

-- Helper warna berdasarkan tim
local function GetTeamColor(player)
    if player.Team == Local.Team then
        return Color3.fromRGB(0, 255, 0)
    else
        return Color3.fromRGB(255, 0, 0)
    end
end

-- Core ESP
Run.RenderStepped:Connect(function()
    if not getgenv().ESP_Enabled then return end
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= Local and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local char = v.Character
            local root = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")
            if not root or not head then continue end

            local color = GetTeamColor(v)
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)

            if onScreen then
                -- BOX
                if getgenv().ESP_Box then
                    local box = Drawing.new("Square")
                    box.Size = Vector2.new(50, 100)
                    box.Position = Vector2.new(pos.X - 25, pos.Y - 50)
                    box.Color = color
                    box.Thickness = 1.5
                    box.Transparency = 1
                    box.Visible = true
                    task.delay(0.03, function() box:Remove() end)
                end

                -- NAME
                if getgenv().ESP_Name then
                    local text = Drawing.new("Text")
                    text.Text = v.Name
                    text.Position = Vector2.new(pos.X - (#v.Name * 2.5), pos.Y - 60)
                    text.Color = color
                    text.Size = 13
                    text.Center = true
                    text.Outline = true
                    text.Transparency = 1
                    text.Visible = true
                    task.delay(0.03, function() text:Remove() end)
                end

                -- TRACER
                if getgenv().ESP_Tracer then
                    local tracer = Drawing.new("Line")
                    tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    tracer.To = Vector2.new(pos.X, pos.Y)
                    tracer.Color = color
                    tracer.Thickness = 1.5
                    tracer.Transparency = 1
                    tracer.Visible = true
                    task.delay(0.03, function() tracer:Remove() end)
                end
            end
        end
    end
end)

-- YoxanXHub V2 | Part 14 | Crosshair Lock, Sticky Aim, FPS Tracker
getgenv().ShowCrosshairLock = true
getgenv().StickyLock = true
getgenv().ShowFPS = true

local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local Local = Players.LocalPlayer

Tab:Toggle("Crosshair Lock Icon", getgenv().ShowCrosshairLock, function(v)
    getgenv().ShowCrosshairLock = v
end)
Tab:Toggle("Sticky Lock-on", getgenv().StickyLock, function(v)
    getgenv().StickyLock = v
end)
Tab:Toggle("FPS Tracker", getgenv().ShowFPS, function(v)
    getgenv().ShowFPS = v
end)

local Cross = Drawing.new("Text")
Cross.Center = true
Cross.Outline = true
Cross.Size = 20
Cross.Color = Color3.fromRGB(255, 0, 0)
Cross.Text = "⚠️"
Cross.Visible = false

-- Show crosshair icon when target is enemy
RunService.RenderStepped:Connect(function()
    if getgenv().ShowCrosshairLock and CurrentTarget and CurrentTarget:FindFirstChild("HumanoidRootPart") then
        local plr = Players:GetPlayerFromCharacter(CurrentTarget)
        if plr and plr.Team ~= Local.Team then
            local pos, onScreen = Camera:WorldToViewportPoint(CurrentTarget.HumanoidRootPart.Position)
            Cross.Position = Vector2.new(pos.X, pos.Y)
            Cross.Visible = onScreen
        else
            Cross.Visible = false
        end
    else
        Cross.Visible = false
    end
end)

-- Sticky Lock-on (camera look at enemy only)
RunService.RenderStepped:Connect(function()
    if getgenv().StickyLock and CurrentTarget and CurrentTarget:FindFirstChild("HumanoidRootPart") then
        local plr = Players:GetPlayerFromCharacter(CurrentTarget)
        if plr and plr.Team ~= Local.Team then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, CurrentTarget.HumanoidRootPart.Position)
        end
    end
end)

-- FPS Tracker
local FPSText = Drawing.new("Text")
FPSText.Position = Vector2.new(10, 10)
FPSText.Size = 14
FPSText.Color = Color3.fromRGB(0, 255, 0)
FPSText.Outline = true
FPSText.Visible = true

local frames, fps = 0, 0
RunService.RenderStepped:Connect(function()
    frames += 1
end)

task.spawn(function()
    while true do
        task.wait(1)
        fps = frames
        frames = 0
        if getgenv().ShowFPS then
            FPSText.Text = "FPS: "..fps
            FPSText.Visible = true
        else
            FPSText.Visible = false
        end
    end
end)

-- YoxanXHub V2 | Part 15 | Hitmarker, Freeze Bypass, Shield Bypass
getgenv().EnableHitmarker = true
getgenv().BypassFrozenTargets = true
getgenv().IgnorePartShields = true

Tab:Toggle("Hitmarker Effect", getgenv().EnableHitmarker, function(v)
    getgenv().EnableHitmarker = v
end)
Tab:Toggle("Freeze Bypass", getgenv().BypassFrozenTargets, function(v)
    getgenv().BypassFrozenTargets = v
end)
Tab:Toggle("Anti Part Shield", getgenv().IgnorePartShields, function(v)
    getgenv().IgnorePartShields = v
end)

-- Hitmarker visual (bottom "Hit")
local function ShowHitmarker()
    if not getgenv().EnableHitmarker then return end
    local txt = Drawing.new("Text")
    txt.Text = "HIT!"
    txt.Size = 18
    txt.Color = Color3.fromRGB(255, 255, 0)
    txt.Center = true
    txt.Outline = true
    txt.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y - 40)
    txt.Visible = true
    task.delay(0.3, function()
        txt:Remove()
    end)
end

-- Fungsi ini harus dipanggil saat peluru kena musuh
getgenv().OnHit = ShowHitmarker

-- Ignore frozen / lagged targets
function IsTargetFrozen(target)
    if not getgenv().BypassFrozenTargets then return false end
    local hrp = target:FindFirstChild("HumanoidRootPart")
    if not hrp then return true end
    return hrp.AssemblyLinearVelocity.Magnitude < 0.1
end

-- Ignore shielded parts (e.g., forcefield)
function IsShielded(target)
    if not getgenv().IgnorePartShields then return false end
    for _, obj in ipairs(target:GetDescendants()) do
        if obj:IsA("ForceField") or obj.Name:lower():find("shield") then
            return true
        end
    end
    return false
end

-- YoxanXHub V2 | Part 16 | Auto Leave, Multi Target, Team ESP
getgenv().AutoLeaveMod = true
getgenv().MultiTarget = true
getgenv().ESPTeamColor = true

Tab:Toggle("Auto Leave on Mod", getgenv().AutoLeaveMod, function(v)
    getgenv().AutoLeaveMod = v
end)
Tab:Toggle("Multi Target Mode", getgenv().MultiTarget, function(v)
    getgenv().MultiTarget = v
end)
Tab:Toggle("ESP Color by Team", getgenv().ESPTeamColor, function(v)
    getgenv().ESPTeamColor = v
end)

-- Auto Leave Logic
local Mods = {"Owner", "Mod", "Admin", "Developer"}
game.Players.PlayerAdded:Connect(function(plr)
    if getgenv().AutoLeaveMod then
        for _, v in pairs(Mods) do
            if plr:GetRoleInGroup and string.find(string.lower(plr.Name), string.lower(v)) then
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId)
            end
        end
    end
end)

-- ESP Box and Name Color by Team
local function CreateESP(plr)
    local espName = Drawing.new("Text")
    espName.Center = true
    espName.Size = 14
    espName.Outline = true
    espName.Font = 2
    espName.Visible = false

    RunService.RenderStepped:Connect(function()
        if getgenv().ESPTeamColor and plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
            espName.Text = plr.Name
            espName.Position = Vector2.new(pos.X, pos.Y - 25)
            espName.Visible = onScreen
            if plr.Team ~= game.Players.LocalPlayer.Team then
                espName.Color = Color3.fromRGB(255, 0, 0)
            else
                espName.Color = Color3.fromRGB(0, 255, 0)
            end
        else
            espName.Visible = false
        end
    end)
end

for _, player in pairs(game.Players:GetPlayers()) do
    if player ~= game.Players.LocalPlayer then
        CreateESP(player)
    end
end

game.Players.PlayerAdded:Connect(function(player)
    if player ~= game.Players.LocalPlayer then
        CreateESP(player)
    end
end)

-- YoxanXHub V2 | Part 17 | Prediction Boost, Head Lock Enhancer, Smooth Lock
getgenv().PredictionBoost = true
getgenv().ForceHeadLock = true
getgenv().SmoothLockEnabled = true

Tab:Toggle("Prediction Overclock", getgenv().PredictionBoost, function(v)
    getgenv().PredictionBoost = v
end)
Tab:Toggle("Head Focus Enhancer", getgenv().ForceHeadLock, function(v)
    getgenv().ForceHeadLock = v
end)
Tab:Toggle("Lock Smoothing", getgenv().SmoothLockEnabled, function(v)
    getgenv().SmoothLockEnabled = v
end)

-- Prediction Engine Override
function GetPredictedPosition(target)
    if not target or not target:FindFirstChild("HumanoidRootPart") then return nil end
    local vel = target.HumanoidRootPart.Velocity
    local pos = target.HumanoidRootPart.Position
    local multiplier = getgenv().PredictionBoost and 0.22 or 0.15
    return pos + (vel * multiplier)
end

-- Always target head logic
function GetLockPart(target)
    if not target then return nil end
    if getgenv().ForceHeadLock and target:FindFirstChild("Head") then
        return target.Head
    end
    return target:FindFirstChild("HumanoidRootPart")
end

-- Smooth camera movement to target
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
RunService.RenderStepped:Connect(function()
    if getgenv().SmoothLockEnabled and CurrentTarget and CurrentTarget:FindFirstChild("HumanoidRootPart") then
        local targetPart = GetLockPart(CurrentTarget)
        if targetPart then
            local pos = GetPredictedPosition(CurrentTarget)
            if pos then
                local current = Camera.CFrame.Position
                local newLook = (pos - current).Unit
                Camera.CFrame = CFrame.new(current, current + newLook)
            end
        end
    end
end)

-- YoxanXHub V2 | Part 18 | Hit Direction, Outline Glow, Notification Sound
getgenv().EnableHitDirection = true
getgenv().EnableOutlineGlow = true
getgenv().EnableLockSound = true

Tab:Toggle("Hit Direction Visual", getgenv().EnableHitDirection, function(v)
    getgenv().EnableHitDirection = v
end)
Tab:Toggle("Outline Glow Target", getgenv().EnableOutlineGlow, function(v)
    getgenv().EnableOutlineGlow = v
end)
Tab:Toggle("Lock Sound", getgenv().EnableLockSound, function(v)
    getgenv().EnableLockSound = v
end)

-- Hit Direction Visual (top arrow)
function ShowHitDirection(fromPos)
    if not getgenv().EnableHitDirection then return end
    local arrow = Drawing.new("Text")
    arrow.Text = "←"
    arrow.Size = 30
    arrow.Center = true
    arrow.Color = Color3.fromRGB(255, 100, 100)
    arrow.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X/2, 60)
    arrow.Visible = true
    task.delay(0.4, function()
        arrow:Remove()
    end)
end

-- Outline Glow (SelectionBox)
function AddOutlineGlow(target)
    if not getgenv().EnableOutlineGlow then return end
    if target and target:FindFirstChild("HumanoidRootPart") and not target:FindFirstChild("YoxanX_Glow") then
        local box = Instance.new("SelectionBox", target)
        box.Adornee = target
        box.LineThickness = 0.08
        box.Name = "YoxanX_Glow"
        box.Color3 = Color3.fromRGB(255, 0, 0)
        box.Transparency = 0.2
    end
end

-- Custom Lock Sound
function PlayLockSound()
    if not getgenv().EnableLockSound then return end
    local sound = Instance.new("Sound", game.SoundService)
    sound.SoundId = "rbxassetid://9118823109" -- short click
    sound.Volume = 1
    sound:Play()
    task.delay(1, function()
        sound:Destroy()
    end)
end

-- YoxanXHub V2 | Part 19 | Wall Highlight, Range Display, FPS Optimizer
getgenv().EnableWallHighlight = true
getgenv().ShowTargetRange = true
getgenv().EnableFPSOptimizer = false

Tab:Toggle("Wall Highlight (Transparent)", getgenv().EnableWallHighlight, function(v)
    getgenv().EnableWallHighlight = v
end)
Tab:Toggle("Show Target Range", getgenv().ShowTargetRange, function(v)
    getgenv().ShowTargetRange = v
end)
Tab:Toggle("FPS Optimizer", getgenv().EnableFPSOptimizer, function(v)
    getgenv().EnableFPSOptimizer = v
end)

-- Transparent walls near enemy
local function MakeWallTransparent(part)
    if getgenv().EnableWallHighlight and part:IsA("BasePart") and not part:IsDescendantOf(game.Players.LocalPlayer.Character) then
        part.Transparency = 0.5
        part.Material = Enum.Material.ForceField
    end
end

local function HighlightWallsNear(target)
    if not target or not getgenv().EnableWallHighlight then return end
    local radius = 30
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (v.Position - target.Position).Magnitude < radius then
            MakeWallTransparent(v)
        end
    end
end

-- Show distance to locked target
local targetRangeText = Drawing.new("Text")
targetRangeText.Size = 14
targetRangeText.Color = Color3.fromRGB(255, 255, 255)
targetRangeText.Outline = true
targetRangeText.Center = true

game:GetService("RunService").RenderStepped:Connect(function()
    if getgenv().ShowTargetRange and CurrentTarget and CurrentTarget:FindFirstChild("HumanoidRootPart") then
        local dist = math.floor((CurrentTarget.HumanoidRootPart.Position - workspace.CurrentCamera.CFrame.Position).Magnitude)
        local screenPos, visible = workspace.CurrentCamera:WorldToViewportPoint(CurrentTarget.HumanoidRootPart.Position)
        if visible then
            targetRangeText.Position = Vector2.new(screenPos.X, screenPos.Y + 20)
            targetRangeText.Text = "Distance: " .. dist .. " studs"
            targetRangeText.Visible = true
        else
            targetRangeText.Visible = false
        end
    else
        targetRangeText.Visible = false
    end
end)

-- FPS Optimizer (disable shadows & debris)
if getgenv().EnableFPSOptimizer then
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    game.Lighting.GlobalShadows = false
    game.Lighting.FogEnd = 100000
    game.Debris.MaxItems = 0
end

-- YoxanXHub V2 | Part 20 | Freeze Bypass, Custom Crosshair, No Zoom Recoil
getgenv().EnableFreezeBypass = true
getgenv().EnableCustomCrosshair = true
getgenv().DisableZoomRecoil = true

Tab:Toggle("Freeze Bypass", getgenv().EnableFreezeBypass, function(v)
    getgenv().EnableFreezeBypass = v
end)
Tab:Toggle("Custom Crosshair", getgenv().EnableCustomCrosshair, function(v)
    getgenv().EnableCustomCrosshair = v
end)
Tab:Toggle("No Zoom Recoil", getgenv().DisableZoomRecoil, function(v)
    getgenv().DisableZoomRecoil = v
end)

-- Freeze bypass logic (head still tracked)
function IsFrozen(target)
    if not target or not target:FindFirstChild("HumanoidRootPart") then return false end
    return target.HumanoidRootPart.AssemblyLinearVelocity.Magnitude < 0.1
end

RunService.RenderStepped:Connect(function()
    if getgenv().EnableFreezeBypass and CurrentTarget and IsFrozen(CurrentTarget) then
        -- Aim at head even if frozen
        workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, CurrentTarget.Head.Position)
    end
end)

-- Custom crosshair
local crosshair = Drawing.new("Text")
crosshair.Text = "+"
crosshair.Size = 24
crosshair.Center = true
crosshair.Outline = true
crosshair.Color = Color3.fromRGB(255, 255, 255)
crosshair.Visible = false

RunService.RenderStepped:Connect(function()
    if getgenv().EnableCustomCrosshair then
        crosshair.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2)
        crosshair.Visible = true
    else
        crosshair.Visible = false
    end
end)

-- Disable zoom recoil
if getgenv().DisableZoomRecoil then
    for _, v in next, getgc(true) do
        if typeof(v) == 'table' and rawget(v, 'ScopeKick') then
            rawset(v, 'ScopeKick', Vector3.zero)
            rawset(v, 'ScopeSway', 0)
        end
    end
end

-- YoxanXHub V2 | Part 21 | Adaptive FOV, Smart Head Lock, Lag Compensation
getgenv().EnableAdaptiveFOV = true
getgenv().EnableSmartHeadTrack = true
getgenv().EnableLagCompensator = true

Tab:Toggle("Adaptive FOV Lock", getgenv().EnableAdaptiveFOV, function(v)
    getgenv().EnableAdaptiveFOV = v
end)
Tab:Toggle("Smart Head Tracker", getgenv().EnableSmartHeadTrack, function(v)
    getgenv().EnableSmartHeadTrack = v
end)
Tab:Toggle("Lag Compensation", getgenv().EnableLagCompensator, function(v)
    getgenv().EnableLagCompensator = v
end)

-- Adaptive FOV Logic (narrow if target is close, wide if far)
function GetAdaptiveFOV(dist)
    if dist <= 100 then return 15
    elseif dist <= 300 then return 35
    else return 50 end
end

-- Head tracker (adjust upward when crouching or jumping)
function GetSmartHeadPos(target)
    if not target or not target:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = target.HumanoidRootPart
    local yOffset = 1.5
    if target:FindFirstChild("Humanoid") then
        if target.Humanoid:GetState() == Enum.HumanoidStateType.Jumping then
            yOffset = 2
        elseif target.Humanoid:GetState() == Enum.HumanoidStateType.Seated then
            yOffset = 1
        end
    end
    return hrp.Position + Vector3.new(0, yOffset, 0)
end

-- Lag Compensation: adjust prediction based on ping
function GetPingPrediction()
    local stats = game:GetService("Stats")
    local pingMs = stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    return math.clamp((pingMs or 50)/1000, 0.05, 0.3)
end

-- YoxanXHub V2 | Part 22–23 | Anti Fly Miss, Reload Skip, Killfeed ESP
getgenv().EnableAntiFlyMiss = true
getgenv().EnableReloadSkip = true
getgenv().EnableKillfeedESP = true

Tab:Toggle("Anti Fly Miss", getgenv().EnableAntiFlyMiss, function(v)
    getgenv().EnableAntiFlyMiss = v
end)
Tab:Toggle("Reload Skip", getgenv().EnableReloadSkip, function(v)
    getgenv().EnableReloadSkip = v
end)
Tab:Toggle("Killfeed ESP", getgenv().EnableKillfeedESP, function(v)
    getgenv().EnableKillfeedESP = v
end)

-- Anti Fly Miss: adjust aim if flying target detected
function IsFlying(target)
    if not target:FindFirstChild("HumanoidRootPart") then return false end
    return target.HumanoidRootPart.Velocity.Y > 20
end

RunService.RenderStepped:Connect(function()
    if getgenv().EnableAntiFlyMiss and CurrentTarget and IsFlying(CurrentTarget) then
        workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, CurrentTarget.Head.Position + Vector3.new(0, 0.5, 0))
    end
end)

-- Reload Skip (force instant reload)
if getgenv().EnableReloadSkip then
    for _, func in pairs(getgc(true)) do
        if typeof(func) == "function" and islclosure(func) then
            local dump = debug.getinfo(func).name
            if dump and string.find(dump, "Reload") then
                hookfunction(func, function(...)
                    return -- skip
                end)
            end
        end
    end
end

-- Killfeed ESP (draws player kills above heads)
local tagText = {}
game:GetService("Players").PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        local head = char:WaitForChild("Head", 5)
        if head and getgenv().EnableKillfeedESP then
            local label = Drawing.new("Text")
            label.Size = 14
            label.Color = Color3.fromRGB(255, 200, 0)
            label.Outline = true
            label.Center = true
            tagText[plr.Name] = label

            RunService.RenderStepped:Connect(function()
                if label and head and head:IsDescendantOf(workspace) then
                    local pos, visible = workspace.CurrentCamera:WorldToViewportPoint(head.Position)
                    label.Position = Vector2.new(pos.X, pos.Y - 30)
                    label.Text = "[KILLER] " .. plr.DisplayName
                    label.Visible = visible and getgenv().EnableKillfeedESP
                else
                    label.Visible = false
                end
            end)
        end
    end)
end)-- YoxanXHub V2 | Part 24 | Rotation Bypass, Hit Flash, Wall Detection
getgenv().EnableRotationBypass = true
getgenv().EnableHitFlashEffect = true
getgenv().EnableAdvWallDetect = true

Tab:Toggle("Rotation Bypass", getgenv().EnableRotationBypass, function(v)
    getgenv().EnableRotationBypass = v
end)
Tab:Toggle("Hit Flash Effect", getgenv().EnableHitFlashEffect, function(v)
    getgenv().EnableHitFlashEffect = v
end)
Tab:Toggle("Adv Wall Detection", getgenv().EnableAdvWallDetect, function(v)
    getgenv().EnableAdvWallDetect = v
end)

-- Rotation Bypass: forcibly update CFrame to head even on spin
RunService.RenderStepped:Connect(function()
    if getgenv().EnableRotationBypass and CurrentTarget and CurrentTarget:FindFirstChild("Head") then
        local pos = CurrentTarget.Head.Position
        workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, pos)
    end
end)

-- Hit Flash Effect
game:GetService("Players").LocalPlayer:GetMouse().Button1Down:Connect(function()
    if not getgenv().EnableHitFlashEffect then return end
    local flash = Drawing.new("Square")
    flash.Size = Vector2.new(10000, 10000)
    flash.Position = Vector2.new(0, 0)
    flash.Color = Color3.fromRGB(255, 255, 255)
    flash.Transparency = 0.6
    flash.ZIndex = 9999
    flash.Visible = true
    task.delay(0.07, function()
        flash:Remove()
    end)
end)

-- Advanced Wall Detection (for accurate wallcheck & wallbang)
function IsWallBetween(origin, targetPos)
    local ray = RaycastParams.new()
    ray.FilterType = Enum.RaycastFilterType.Blacklist
    ray.FilterDescendantsInstances = {game:GetService("Players").LocalPlayer.Character}
    local result = workspace:Raycast(origin, (targetPos - origin).Unit * 500, ray)
    if result and result.Instance and not result.Instance:IsDescendantOf(workspace:WaitForChild("Enemies")) then
        return true -- wall exists
    end
    return false -- clear shot
end

-- YoxanXHub V2 | Part 25 | Auto Target Switch, Kill Confirm, UI Restore
getgenv().EnableAutoSwitchTarget = true
getgenv().EnableKillSound = true
getgenv().EnableSmartExitUI = true

Tab:Toggle("Auto Target Switch", getgenv().EnableAutoSwitchTarget, function(v)
    getgenv().EnableAutoSwitchTarget = v
end)
Tab:Toggle("Kill Lock Sound", getgenv().EnableKillSound, function(v)
    getgenv().EnableKillSound = v
end)
Tab:Toggle("Smart Exit Button", getgenv().EnableSmartExitUI, function(v)
    getgenv().EnableSmartExitUI = v
end)

-- Auto Switch Target (immediately locks onto another enemy after kill)
function OnEnemyKilled(deadEnemy)
    if not getgenv().EnableAutoSwitchTarget then return end
    local closest = nil
    local dist = math.huge
    for _, plr in pairs(game:GetService("Players"):GetPlayers()) do
        if plr ~= game.Players.LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            local mag = (plr.Character.HumanoidRootPart.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
            if mag < dist then
                closest = plr.Character
                dist = mag
            end
        end
    end
    if closest then
        CurrentTarget = closest
    end
end

-- Kill Confirm Sound
function PlayKillSound()
    if not getgenv().EnableKillSound then return end
    local s = Instance.new("Sound", workspace)
    s.SoundId = "rbxassetid://9118823107" -- simple click/kill confirm
    s.Volume = 2
    s:Play()
    game.Debris:AddItem(s, 2)
end

-- Hook Humanoid death event to both
game:GetService("Players").PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid", 6)
        if hum then
            hum.Died:Connect(function()
                OnEnemyKilled(char)
                PlayKillSound()
            end)
        end
    end)
end)

-- Smart Exit Button UI (creates small toggle when closed)
if getgenv().EnableSmartExitUI then
    local OrionLib = _G.OrionLib
    local uis = game:GetService("UserInputService")
    local coreGui = game:GetService("CoreGui")
    local icon = Instance.new("TextButton")
    icon.Name = "YoxanXReturnIcon"
    icon.Size = UDim2.new(0, 40, 0, 40)
    icon.Position = UDim2.new(0, 10, 0.5, -20)
    icon.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    icon.Text = "📌"
    icon.TextColor3 = Color3.fromRGB(255, 255, 255)
    icon.Parent = coreGui
    icon.Visible = false

    OrionLib:Init()
    OrionLib:OnClose(function()
        icon.Visible = true
    end)

    icon.MouseButton1Click:Connect(function()
        OrionLib:Init()
        icon.Visible = false
    end)
end
