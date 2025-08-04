local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
    Name = "YoxanXHub | Build A Plane",
    LoadingTitle = "YoxanXHub",
    LoadingSubtitle = "By yoxanx",
    ConfigurationSaving = {
        Enabled = false
    },
    Discord = {
        Enabled = false
    },
    KeySystem = false
})

-- Quick Money
Rayfield:CreateButton({
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
            Rayfield:Notify({
                Title = "Warning",
                Content = "You must sit in the vehicle first!",
                Duration = 4
            })
        end
    end
})

-- Boost / Unboost
local boostedSeats = {}

Rayfield:CreateButton({
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
                Rayfield:Notify({
                    Title = "Unboosted",
                    Content = "Vehicle returned to normal speed.",
                    Duration = 3
                })
            else
                if seat.MaxSpeed then
                    boostedSeats[seat] = seat.MaxSpeed
                    seat.MaxSpeed = 300
                    Rayfield:Notify({
                        Title = "Boosted",
                        Content = "Vehicle speed set to 300!",
                        Duration = 3
                    })
                else
                    Rayfield:Notify({
                        Title = "Error",
                        Content = "MaxSpeed not found on this seat.",
                        Duration = 3
                    })
                end
            end
        else
            Rayfield:Notify({
                Title = "Warning",
                Content = "You must sit on a VehicleSeat!",
                Duration = 4
            })
        end
    end
})

-- Auto Farm (Experimental)
local isAutoFarm = false
local farmConnection

Rayfield:CreateToggle({
    Name = "Auto Farm (Experimental)",
    CurrentValue = false,
    Callback = function(state)
        isAutoFarm = state
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
