local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/1nig1htmare1234/SCRIPTS/main/Orion.lua"))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Window = OrionLib:MakeWindow({
    Name = "YoxanXHub | Build A Plane",
    HidePremium = false,
    SaveConfig = false,
    IntroText = "YoxanXHub Loaded!",
    ConfigFolder = "YoxanXHub"
})

--==[ Quick Money Tab ]==--
local MainTab = Window:MakeTab({
    Name = "Main",
    Icon = "rbxassetid://6035078880",
    PremiumOnly = false
})

MainTab:AddButton({
    Name = "Quick Money",
    Callback = function()
        local character = LocalPlayer.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.SeatPart then
            local seat = humanoid.SeatPart
            local forwardVec = seat.CFrame.LookVector
            seat.CFrame = seat.CFrame + forwardVec * 100000
            character:SetPrimaryPartCFrame(seat.CFrame)
        else
            OrionLib:MakeNotification({
                Name = "Warning",
                Content = "You must be seated in a vehicle!",
                Time = 4
            })
        end
    end
})

--==[ Boost / Unboost ]==--
local boostedSeats = {}

MainTab:AddButton({
    Name = "Boost / Unboost",
    Callback = function()
        local character = LocalPlayer.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.SeatPart and humanoid.SeatPart:IsA("VehicleSeat") then
            local seat = humanoid.SeatPart
            if boostedSeats[seat] then
                seat.MaxSpeed = boostedSeats[seat]
                boostedSeats[seat] = nil
                OrionLib:MakeNotification({
                    Name = "Unboosted",
                    Content = "Vehicle speed reset to normal.",
                    Time = 3
                })
            else
                if seat.MaxSpeed then
                    boostedSeats[seat] = seat.MaxSpeed
                    seat.MaxSpeed = 300
                    OrionLib:MakeNotification({
                        Name = "Boosted!",
                        Content = "Vehicle speed set to 300.",
                        Time = 3
                    })
                else
                    OrionLib:MakeNotification({
                        Name = "Error",
                        Content = "Seat does not support MaxSpeed.",
                        Time = 3
                    })
                end
            end
        else
            OrionLib:MakeNotification({
                Name = "Warning",
                Content = "You must be on a VehicleSeat!",
                Time = 4
            })
        end
    end
})

--==[ Auto Farm Toggle ]==--
local isAutoFarm = false
local farmConnection

MainTab:AddToggle({
    Name = "Auto Farm (Experimental)",
    Default = false,
    Callback = function(Value)
        isAutoFarm = Value
        if isAutoFarm then
            farmConnection = LocalPlayer.CharacterAdded:Connect(function(character)
                local humanoid = character:WaitForChild("Humanoid")
                humanoid.Seated:Connect(function(isSeated, seatPart)
                    if isSeated and seatPart then
                        local forwardVec = seatPart.CFrame.LookVector
                        seatPart.CFrame = seatPart.CFrame + forwardVec * 500000
                        character:SetPrimaryPartCFrame(seatPart.CFrame)
                    end
                end)
            end)

            local character = LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.SeatPart then
                    local seat = humanoid.SeatPart
                    local forwardVec = seat.CFrame.LookVector
                    seat.CFrame = seat.CFrame + forwardVec * 500000
                    character:SetPrimaryPartCFrame(seat.CFrame)
                end
            end
        else
            if farmConnection then
                farmConnection:Disconnect()
                farmConnection = nil
            end
        end
    end
})
