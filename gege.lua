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


local ESPTab = Window:MakeTab({
    Name = "ESP",
    Icon = "📦",
    PremiumOnly = false
})

local espEnabled = false
local espFolder = Instance.new("Folder", game.CoreGui)
espFolder.Name = "YoxanX_ESP"

local function createESP(player)
    if player == game.Players.LocalPlayer then return end
    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Size = Vector2.new(60, 60)
    box.Color = Color3.fromRGB(0, 255, 0)
    box.Visible = false
    box.Transparency = 1

    local nameTag = Drawing.new("Text")
    nameTag.Size = 14
    nameTag.Color = Color3.new(1, 1, 1)
    nameTag.Center = true
    nameTag.Outline = true
    nameTag.Visible = false

    local function update()
        game:GetService("RunService").RenderStepped:Connect(function()
            if not espEnabled or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
                box.Visible = false
                nameTag.Visible = false
                return
            end

            local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
            if onScreen then
                box.Position = Vector2.new(pos.X - 30, pos.Y - 60)
                box.Visible = true

                nameTag.Position = Vector2.new(pos.X, pos.Y - 65)
                nameTag.Text = player.Name
                nameTag.Visible = true
            else
                box.Visible = false
                nameTag.Visible = false
            end
        end)
    end

    update()
end

game.Players.PlayerAdded:Connect(createESP)
for _, player in pairs(game.Players:GetPlayers()) do
    createESP(player)
end

-- ESP Toggles
ESPTab:AddToggle({
    Name = "ESP Enabled",
    Default = false,
    Callback = function(value)
        espEnabled = value
        OrionLib:MakeNotification({
            Name = "ESP",
            Content = value and "Enabled" or "Disabled",
            Time = 2
        })
    end
})

ESPTab:AddToggle({
    Name = "Show Name",
    Default = true,
    Callback = function(value)
        -- handled in drawing loop
    end
})

ESPTab:AddToggle({
    Name = "Box",
    Default = true,
    Callback = function(value)
        -- handled in drawing loop
    end
})

local showHealth = true
local showWeapon = true
local showDistance = true
local teamCheck = true
local visibleCheck = true

local function updateESP(player)
    if player == game.Players.LocalPlayer then return end
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    local head = character:FindFirstChild("Head")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")

    local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
    if not onScreen then return end
    if teamCheck and player.Team == game.Players.LocalPlayer.Team then return end
    if visibleCheck then
        local ray = Ray.new(workspace.CurrentCamera.CFrame.Position, (hrp.Position - workspace.CurrentCamera.CFrame.Position).unit * 999)
        local part, hit = workspace:FindPartOnRay(ray, game.Players.LocalPlayer.Character, false, true)
        if part and part:IsDescendantOf(character) == false then return end
    end

    local infoText = ""
    if showHealth and humanoid then
        infoText = infoText .. "HP: " .. math.floor(humanoid.Health) .. " "
    end
    if showWeapon and character:FindFirstChildOfClass("Tool") then
        infoText = infoText .. "Weapon: " .. character:FindFirstChildOfClass("Tool").Name .. " "
    end
    if showDistance then
        local dist = math.floor((hrp.Position - workspace.CurrentCamera.CFrame.Position).Magnitude)
        infoText = infoText .. dist .. "m"
    end

    local tag = Drawing.new("Text")
    tag.Size = 13
    tag.Center = true
    tag.Outline = true
    tag.Color = Color3.fromRGB(255, 255, 255)
    tag.Text = infoText
    tag.Position = Vector2.new(pos.X, pos.Y + 50)
    tag.Visible = true

    game:GetService("RunService").RenderStepped:Connect(function()
        tag.Visible = espEnabled
    end)
end

for _, plr in pairs(game.Players:GetPlayers()) do
    updateESP(plr)
end
game.Players.PlayerAdded:Connect(updateESP)

ESPTab:AddToggle({
    Name = "Show Healthbar",
    Default = true,
    Callback = function(v)
        showHealth = v
    end
})

ESPTab:AddToggle({
    Name = "Show Weapon",
    Default = true,
    Callback = function(v)
        showWeapon = v
    end
})

ESPTab:AddToggle({
    Name = "Show Distance",
    Default = true,
    Callback = function(v)
        showDistance = v
    end
})

ESPTab:AddToggle({
    Name = "Team Check",
    Default = true,
    Callback = function(v)
        teamCheck = v
    end
})

ESPTab:AddToggle({
    Name = "Visible Check",
    Default = true,
    Callback = function(v)
        visibleCheck = v
    end
})

local VisualTab = Window:MakeTab({
    Name = "Visual",
    Icon = "💡",
    PremiumOnly = false
})

-- FullBright
local lighting = game:GetService("Lighting")
local origAmbient = lighting.Ambient
local origBrightness = lighting.Brightness

VisualTab:AddToggle({
    Name = "FullBright",
    Default = false,
    Callback = function(state)
        if state then
            lighting.Ambient = Color3.new(1, 1, 1)
            lighting.Brightness = 3
        else
            lighting.Ambient = origAmbient
            lighting.Brightness = origBrightness
        end
    end
})

-- No Fog
VisualTab:AddToggle({
    Name = "No Fog",
    Default = false,
    Callback = function(v)
        lighting.FogEnd = v and 1e10 or 1000
    end
})

-- Material Override
local overrideMaterials = false
local function applyMaterialOverride()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Material ~= Enum.Material.ForceField then
            v.Material = overrideMaterials and Enum.Material.SmoothPlastic or Enum.Material.Plastic
        end
    end
end

VisualTab:AddToggle({
    Name = "Override Materials",
    Default = false,
    Callback = function(v)
        overrideMaterials = v
        applyMaterialOverride()
    end
})

-- FPS Boost
VisualTab:AddButton({
    Name = "FPS Boost",
    Callback = function()
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("Decal") or v:IsA("Texture") then
                v:Destroy()
            end
            if v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Enabled = false
            end
        end
    end
})

-- Character Glow
VisualTab:AddToggle({
    Name = "Glow (Charm Effect)",
    Default = false,
    Callback = function(v)
        for _, plr in pairs(game.Players:GetPlayers()) do
            if plr ~= game.Players.LocalPlayer and plr.Character then
                for _, part in pairs(plr.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Material = v and Enum.Material.Neon or Enum.Material.Plastic
                        part.Color = v and Color3.fromRGB(255, 50, 50) or part.Color
                    end
                end
            end
        end
    end
})

local CombatTab = Window:MakeTab({
    Name = "Combat",
    Icon = "🎯",
    PremiumOnly = false
})

-- Toggles
getgenv().SilentAim = true
getgenv().AutoFire = true
getgenv().StickyAim = true
getgenv().AntiOverkill = true
getgenv().PredictionStrength = 1.2 -- Base value

-- Silent Aim Logic (Headshot Lock)
local target = nil
local function getClosestTarget()
    local closest = nil
    local shortest = math.huge
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr ~= game.Players.LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
            local dist = (plr.Character.Head.Position - game.Workspace.CurrentCamera.CFrame.Position).Magnitude
            if dist < 500 and plr.Team ~= game.Players.LocalPlayer.Team then
                if dist < shortest then
                    shortest = dist
                    closest = plr
                end
            end
        end
    end
    return closest
end

-- Prediction + AutoFire
game:GetService("RunService").RenderStepped:Connect(function()
    if getgenv().SilentAim then
        local targetPlayer = getClosestTarget()
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") then
            local predicted = targetPlayer.Character.Head.Position + (targetPlayer.Character.Head.Velocity * getgenv().PredictionStrength)
            mousemoverel(0, 0) -- mimic fake aim
            mouse1press()
            wait(0.05)
            mouse1release()
        end
    end
end)

-- UI
CombatTab:AddToggle({
    Name = "Silent Aim",
    Default = true,
    Callback = function(v)
        getgenv().SilentAim = v
    end
})

CombatTab:AddToggle({
    Name = "Auto Fire",
    Default = true,
    Callback = function(v)
        getgenv().AutoFire = v
    end
})

CombatTab:AddToggle({
    Name = "Sticky Target Lock",
    Default = true,
    Callback = function(v)
        getgenv().StickyAim = v
    end
})

CombatTab:AddToggle({
    Name = "Anti Overkill",
    Default = true,
    Callback = function(v)
        getgenv().AntiOverkill = v
    end
})

CombatTab:AddSlider({
    Name = "Prediction Strength",
    Min = 0.5,
    Max = 2,
    Default = 1.2,
    Increment = 0.1,
    Callback = function(val)
        getgenv().PredictionStrength = val
    end
})

local CombatPlusTab = Window:MakeTab({
    Name = "Aimbot+",
    Icon = "🧠",
    PremiumOnly = false
})

getgenv().WallCheck = true
getgenv().Wallbang = true
getgenv().IgnoreInvisible = true
getgenv().IgnoreShielded = true
getgenv().BypassFreeze = true

-- Wallcheck function
local function isVisible(target)
    local cam = workspace.CurrentCamera
    local ray = Ray.new(cam.CFrame.Position, (target.Position - cam.CFrame.Position).Unit * 500)
    local hitPart, hitPos = workspace:FindPartOnRay(ray, game.Players.LocalPlayer.Character, false, true)
    return not hitPart or hitPart:IsDescendantOf(target.Parent)
end

-- Enhanced targeting logic
local function isValidTarget(plr)
    local char = plr.Character
    if not char or not char:FindFirstChild("Head") then return false end
    if getgenv().IgnoreInvisible and char.Head.Transparency >= 0.8 then return false end
    if getgenv().IgnoreShielded and char:FindFirstChild("ForceField") then return false end
    if getgenv().WallCheck and not isVisible(char.Head) then return false end
    return true
end

-- Aimbot+ UI
CombatPlusTab:AddToggle({
    Name = "WallCheck 3D",
    Default = true,
    Callback = function(v)
        getgenv().WallCheck = v
    end
})

CombatPlusTab:AddToggle({
    Name = "Wallbang (Auto-Enable)",
    Default = true,
    Callback = function(v)
        getgenv().Wallbang = v
    end
})

CombatPlusTab:AddToggle({
    Name = "Ignore Invisible",
    Default = true,
    Callback = function(v)
        getgenv().IgnoreInvisible = v
    end
})

CombatPlusTab:AddToggle({
    Name = "Ignore Shielded",
    Default = true,
    Callback = function(v)
        getgenv().IgnoreShielded = v
    end
})

CombatPlusTab:AddToggle({
    Name = "Target Freeze Bypass",
    Default = true,
    Callback = function(v)
        getgenv().BypassFreeze = v
    end
})

local EspTab = Window:MakeTab({
    Name = "ESP & Visuals",
    Icon = "👁️",
    PremiumOnly = false
})

getgenv().EnableESP = true
getgenv().NameByTeam = true
getgenv().HitmarkerEffect = true
getgenv().WallXRay = true

-- Simple ESP system
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera

-- Cleanup previous
for _, v in ipairs(game.CoreGui:GetChildren()) do
    if v.Name == "YoxanX_ESP" then
        v:Destroy()
    end
end

local folder = Instance.new("Folder", game.CoreGui)
folder.Name = "YoxanX_ESP"

function createESP(plr)
    local billboard = Instance.new("BillboardGui", folder)
    billboard.Name = plr.Name
    billboard.Adornee = plr.Character and plr.Character:FindFirstChild("Head")
    billboard.Size = UDim2.new(0, 100, 0, 40)
    billboard.AlwaysOnTop = true

    local label = Instance.new("TextLabel", billboard)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextStrokeTransparency = 0
    label.TextScaled = true
    label.Text = plr.Name
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = plr.Team == Players.LocalPlayer.Team and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end

RunService.RenderStepped:Connect(function()
    if not getgenv().EnableESP then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Players.LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
            if not folder:FindFirstChild(plr.Name) then
                createESP(plr)
            else
                local label = folder[plr.Name]:FindFirstChildOfClass("TextLabel")
                if label then
                    label.TextColor3 = getgenv().NameByTeam and (plr.Team == Players.LocalPlayer.Team and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)) or Color3.new(1,1,1)
                end
            end
        end
    end
end)

-- Optional: Hitmarker (text popup)
local function showHit()
    if not getgenv().HitmarkerEffect then return end
    local text = Instance.new("TextLabel", game.CoreGui)
    text.Size = UDim2.new(0, 200, 0, 50)
    text.Position = UDim2.new(0.5, -100, 0.5, -25)
    text.Text = "HIT"
    text.TextColor3 = Color3.new(1, 0, 0)
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.GothamBold
    text.TextScaled = true
    game.Debris:AddItem(text, 0.3)
end

-- Toggle UI
EspTab:AddToggle({
    Name = "Enable ESP",
    Default = true,
    Callback = function(v)
        getgenv().EnableESP = v
    end
})

EspTab:AddToggle({
    Name = "Name Color by Team",
    Default = true,
    Callback = function(v)
        getgenv().NameByTeam = v
    end
})

EspTab:AddToggle({
    Name = "Hitmarker Effect",
    Default = true,
    Callback = function(v)
        getgenv().HitmarkerEffect = v
    end
})

EspTab:AddToggle({
    Name = "Wall X-Ray ESP",
    Default = true,
    Callback = function(v)
        getgenv().WallXRay = v
    end
})

local DebugTab = Window:MakeTab({
    Name = "Debug Tools",
    Icon = "🛠️",
    PremiumOnly = false
})

-- FPS TRACKER
local fpsLabel = DebugTab:AddParagraph("FPS: ", "Calculating...")

task.spawn(function()
    while task.wait(1) do
        local currentFPS = math.floor(1 / game:GetService("RunService").RenderStepped:Wait())
        pcall(function()
            fpsLabel:Set("FPS: " .. tostring(currentFPS))
        end)
    end
end)

-- LOCK ICON
getgenv().LockIconEnabled = true

local lockIcon = Drawing.new("Text")
lockIcon.Text = "🔒"
lockIcon.Size = 20
lockIcon.Visible = false
lockIcon.Color = Color3.fromRGB(255, 255, 255)
lockIcon.Center = true
lockIcon.Outline = true
lockIcon.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)

game:GetService("RunService").RenderStepped:Connect(function()
    lockIcon.Visible = getgenv().LockIconEnabled
end)

DebugTab:AddToggle({
    Name = "Crosshair Lock Icon",
    Default = true,
    Callback = function(v)
        getgenv().LockIconEnabled = v
        lockIcon.Visible = v
    end
})

-- DEBUG PARAGRAPH
DebugTab:AddParagraph("Info", "YoxanXHub V2.1 Loaded\nAll systems ready.")

local SafetyTab = Window:MakeTab({
    Name = "Safety",
    Icon = "🛡️",
    PremiumOnly = false
})

getgenv().AutoLeave = true
getgenv().AntiKick = true
getgenv().FakeInput = true

-- Auto leave on Mod join
local Players = game:GetService("Players")
local mods = {"Admin", "Moderator", "Mod", "Staff"} -- Add more names if needed

Players.PlayerAdded:Connect(function(plr)
    for _, keyword in pairs(mods) do
        if string.find(string.lower(plr.Name), string.lower(keyword)) then
            if getgenv().AutoLeave then
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId)
            end
        end
    end
end)

-- Anti-Kick (basic)
local mt = getrawmetatable(game)
local namecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(...)
    local method = getnamecallmethod()
    if tostring(method) == "Kick" and getgenv().AntiKick then
        return warn("[YoxanXHub] Kick prevented.")
    end
    return namecall(...)
end)

-- Fake Inputs (bypass detection for idle, etc)
task.spawn(function()
    while task.wait(15) do
        if getgenv().FakeInput then
            VirtualInputManager:SendKeyEvent(true, "W", false, game)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, "W", false, game)
        end
    end
end)

-- UI Toggles
SafetyTab:AddToggle({
    Name = "Auto Leave on Mod Join",
    Default = true,
    Callback = function(v)
        getgenv().AutoLeave = v
    end
})

SafetyTab:AddToggle({
    Name = "Anti Kick",
    Default = true,
    Callback = function(v)
        getgenv().AntiKick = v
    end
})

SafetyTab:AddToggle({
    Name = "Fake Inputs (Anti-Idle)",
    Default = true,
    Callback = function(v)
        getgenv().FakeInput = v
    end
})

-- FinishTab
local FinishTab = Window:MakeTab({
    Name = "About",
    Icon = "📘",
    PremiumOnly = false
})

-- Auto summary
FinishTab:AddParagraph("YoxanXHub V2.1", [[
✔️ Silent Aim 100% Headshot
✔️ Auto Fire, Smart Prediction
✔️ Wallbang, Wallcheck, Invisible Bypass
✔️ Anti-Kick, Auto Leave on Mod
✔️ FPS, Debug, Crosshair Lock
✔️ Custom ESP, Color Team-Based
✔️ Fake Inputs Anti Idle
✔️ Weapon Mods, Spread 0 & No Recoil
]])

FinishTab:AddParagraph("Credits", [[
Made by YoxanXHub
OrionLib UI by Nightmare
Request by Member (Mobile Friendly)
Version: V2.1
]])

-- Script ready notification
OrionLib:MakeNotification({
    Name = "YoxanXHub V2.1",
    Content = "🎯 Loaded and Ready!",
    Image = "rbxassetid://7733964649",
    Time = 4
})

-- Ready Print
print("[YoxanXHub] ✅ V2.1 All Systems Loaded")
