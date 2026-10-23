
--[[
    CLIENT ADMIN PANEL
    Place in StarterPlayer > StarterPlayerScripts

    Client-side utilities for your own Roblox experience.
    Does not grant server-side administrator permissions.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS
--==================================================

local settings = {
    WalkSpeed = 16,
    JumpPower = 50,
    HipHeight = 0,
    FlySpeed = 60,
    FOV = 70,
}

local state = {
    Flying = false,
    Noclip = false,
    InfiniteJump = false,
    Fullbright = false,
    Combined = false,
}

local character, humanoid, rootPart
local flyConnection
local flyVelocity, flyGyro
local originalCollisions = {}
local originalLighting = {}
local originalFOV = 70

--==================================================
-- CHARACTER
--==================================================

local function bindCharacter(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    rootPart = char:WaitForChild("HumanoidRootPart")

    humanoid.WalkSpeed = settings.WalkSpeed
    humanoid.UseJumpPower = true
    humanoid.JumpPower = settings.JumpPower
    humanoid.HipHeight = settings.HipHeight
end

if player.Character then
    bindCharacter(player.Character)
end

player.CharacterAdded:Connect(function(char)
    if state.Flying then
        state.Flying = false
    end

    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end

    if flyVelocity then flyVelocity:Destroy() flyVelocity = nil end
    if flyGyro then flyGyro:Destroy() flyGyro = nil end

    state.Noclip = false
    state.Combined = false
    originalCollisions = {}

    bindCharacter(char)
end)

--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "ClientAdminPanel"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 20
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(360, 490)
main.Position = UDim2.new(0.5, -180, 0.5, -245)
main.BackgroundColor3 = Color3.fromRGB(20, 23, 32)
main.BorderSizePixel = 0
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(65, 100, 180)
stroke.Thickness = 1.2
stroke.Parent = main

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 48)
header.BackgroundColor3 = Color3.fromRGB(32, 39, 57)
header.BorderSizePixel = 0
header.Parent = main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -100, 1, 0)
title.Position = UDim2.fromOffset(15, 0)
title.BackgroundTransparency = 1
title.Text = "CLIENT ADMIN"
title.TextColor3 = Color3.fromRGB(235, 240, 255)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(34, 30)
minimize.Position = UDim2.new(1, -76, 0, 9)
minimize.Text = "_"
minimize.TextSize = 20
minimize.Font = Enum.Font.GothamBold
minimize.BackgroundColor3 = Color3.fromRGB(53, 65, 91)
minimize.TextColor3 = Color3.new(1, 1, 1)
minimize.Parent = header
Instance.new("UICorner", minimize).CornerRadius = UDim.new(0, 7)

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(30, 30)
close.Position = UDim2.new(1, -36, 0, 9)
close.Text = "X"
close.TextSize = 14
close.Font = Enum.Font.GothamBold
close.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
close.TextColor3 = Color3.new(1, 1, 1)
close.Parent = header
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 7)

local content = Instance.new("ScrollingFrame")
content.Position = UDim2.fromOffset(12, 58)
content.Size = UDim2.new(1, -24, 1, -70)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 4
content.ScrollBarImageColor3 = Color3.fromRGB(100, 130, 200)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.new()
content.Parent = main

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 7)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = content

local function section(text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -4, 0, 26)
    label.BackgroundTransparency = 1
    label.Text = "  " .. text
    label.TextColor3 = Color3.fromRGB(110, 160, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = content
    return label
end

local function makeButton(text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -4, 0, 36)
    button.BackgroundColor3 = Color3.fromRGB(39, 46, 64)
    button.TextColor3 = Color3.fromRGB(235, 240, 255)
    button.TextSize = 13
    button.Font = Enum.Font.GothamMedium
    button.Text = text
    button.AutoButtonColor = true
    button.Parent = content
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 7)

    button.Activated:Connect(callback)

    return button
end

local function makeInput(labelText, initialValue, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 38)
    row.BackgroundColor3 = Color3.fromRGB(29, 34, 48)
    row.Parent = content
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.58, 0, 1, 0)
    label.Position = UDim2.fromOffset(10, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(220, 225, 240)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0.34, -4, 0, 28)
    input.Position = UDim2.new(0.64, 0, 0.5, -14)
    input.BackgroundColor3 = Color3.fromRGB(47, 56, 77)
    input.TextColor3 = Color3.new(1, 1, 1)
    input.PlaceholderColor3 = Color3.fromRGB(160, 165, 180)
    input.Font = Enum.Font.GothamMedium
    input.TextSize = 13
    input.Text = tostring(initialValue)
    input.ClearTextOnFocus = false
    input.Parent = row
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 5)

    input.FocusLost:Connect(function(enterPressed)
        local value = tonumber(input.Text)
        if value then
            callback(value)
        else
            input.Text = tostring(initialValue)
        end
    end)

    return input
end

--==================================================
-- MOVEMENT CONTROLS
--==================================================

section("MOVEMENT")

makeInput("WalkSpeed", settings.WalkSpeed, function(value)
    settings.WalkSpeed = math.clamp(value, 0, 300)
    if humanoid then
        humanoid.WalkSpeed = settings.WalkSpeed
    end
end)

makeInput("Jump Power", settings.JumpPower, function(value)
    settings.JumpPower = math.clamp(value, 0, 300)
    if humanoid then
        humanoid.UseJumpPower = true
        humanoid.JumpPower = settings.JumpPower
    end
end)

makeInput("Hip Height", settings.HipHeight, function(value)
    settings.HipHeight = math.clamp(value, -10, 50)
    if humanoid then
        humanoid.HipHeight = settings.HipHeight
    end
end)

makeInput("Flight Speed", settings.FlySpeed, function(value)
    settings.FlySpeed = math.clamp(value, 1, 300)
end)

makeInput("Camera FOV", settings.FOV, function(value)
    settings.FOV = math.clamp(value, 40, 120)
    local camera = workspace.CurrentCamera
    if camera then
        camera.FieldOfView = settings.FOV
    end
end)

--==================================================
-- FLIGHT
--==================================================

local function stopFlying()
    state.Flying = false

    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end

    if flyVelocity then
        flyVelocity:Destroy()
        flyVelocity = nil
    end

    if flyGyro then
        flyGyro:Destroy()
        flyGyro = nil
    end

    if humanoid then
        humanoid.PlatformStand = false
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

local function startFlying()
    if not character or not humanoid or not rootPart then return end
    if state.Flying then return end

    state.Flying = true
    humanoid.PlatformStand = true

    flyVelocity = Instance.new("BodyVelocity")
    flyVelocity.Name = "LocalFlightVelocity"
    flyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    flyVelocity.P = 1e4
    flyVelocity.Velocity = Vector3.zero
    flyVelocity.Parent = rootPart

    flyGyro = Instance.new("BodyGyro")
    flyGyro.Name = "LocalFlightGyro"
    flyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    flyGyro.P = 1e4
    flyGyro.CFrame = rootPart.CFrame
    flyGyro.Parent = rootPart

    flyConnection = RunService.RenderStepped:Connect(function()
        if not state.Flying or not rootPart or not rootPart.Parent then
            stopFlying()
            return
        end

        local camera = workspace.CurrentCamera
        if not camera then return end

        local direction = Vector3.zero
        local cf = camera.CFrame

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            direction += cf.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            direction -= cf.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            direction += cf.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            direction -= cf.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            direction += Vector3.yAxis
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            direction -= Vector3.yAxis
        end

        if direction.Magnitude > 0 then
            direction = direction.Unit * settings.FlySpeed
        end

        flyVelocity.Velocity = direction
        flyGyro.CFrame = cf
    end)
end

local flyButton = makeButton("FLY: OFF", function()
    if state.Flying then
        stopFlying()
    else
        startFlying()
    end
end)

--==================================================
-- NOCLIP
--==================================================

local function setNoclip(enabled)
    state.Noclip = enabled

    if not enabled then
        for part, oldValue in pairs(originalCollisions) do
            if part and part.Parent then
                part.CanCollide = oldValue
            end
        end
        table.clear(originalCollisions)
    end
end

RunService.Stepped:Connect(function()
    if not state.Noclip or not character then return end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if originalCollisions[part] == nil then
                originalCollisions[part] = part.CanCollide
            end
            part.CanCollide = false
        end
    end
end)

local noclipButton = makeButton("NOCLIP: OFF", function()
    setNoclip(not state.Noclip)
end)

local combinedButton = makeButton("FLY + NOCLIP: OFF", function()
    state.Combined = not state.Combined

    if state.Combined then
        setNoclip(true)
        startFlying()
    else
        setNoclip(false)
        stopFlying()
    end
end)

--==================================================
-- EXTRA CLIENT UTILITIES
--==================================================

section("EXTRA UTILITIES")

makeButton("Infinite Jump: OFF", function()
    state.InfiniteJump = not state.InfiniteJump
end)

UserInputService.JumpRequest:Connect(function()
    if state.InfiniteJump and humanoid and humanoid.Health > 0 then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

local function setFullbright(enabled)
    state.Fullbright = enabled

    if enabled then
        originalLighting.Brightness = Lighting.Brightness
        originalLighting.ClockTime = Lighting.ClockTime
        originalLighting.GlobalShadows = Lighting.GlobalShadows
        originalLighting.Ambient = Lighting.Ambient
        originalLighting.OutdoorAmbient = Lighting.OutdoorAmbient

        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    else
        for property, value in pairs(originalLighting) do
            Lighting[property] = value
        end
        table.clear(originalLighting)
    end
end

makeButton("Fullbright: OFF", function()
    setFullbright(not state.Fullbright)
end)

makeButton("Reset Movement", function()
    settings.WalkSpeed = 16
    settings.JumpPower = 50
    settings.HipHeight = 0

    if humanoid then
        humanoid.WalkSpeed = 16
        humanoid.UseJumpPower = true
        humanoid.JumpPower = 50
        humanoid.HipHeight = 0
    end
end)

makeButton("Reset Camera FOV", function()
    settings.FOV = 70
    local camera = workspace.CurrentCamera
    if camera then camera.FieldOfView = 70 end
end)

makeButton("Stop All Movement Modes", function()
    stopFlying()
    setNoclip(false)
    state.Combined = false
    state.InfiniteJump = false
end)

makeButton("Respawn Character", function()
    if humanoid then
        humanoid.Health = 0
    end
end)

--==================================================
-- LIVE BUTTON STATUS
--==================================================

local function updateButton(button, label, enabled)
    button.Text = label .. ": " .. (enabled and "ON" or "OFF")
    button.BackgroundColor3 = enabled
        and Color3.fromRGB(38, 115, 83)
        or Color3.fromRGB(39, 46, 64)
end

RunService.Heartbeat:Connect(function()
    updateButton(flyButton, "FLY", state.Flying)
    updateButton(noclipButton, "NOCLIP", state.Noclip)
    updateButton(combinedButton, "FLY + NOCLIP", state.Combined)
end)

--==================================================
-- DRAG WINDOW
--==================================================

local dragging = false
local dragStart
local startPosition

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

--==================================================
-- MINIMIZE / CLOSE / REOPEN
--==================================================

local minimized = false

minimize.Activated:Connect(function()
    minimized = not minimized
    content.Visible = not minimized
    main.Size = minimized
        and UDim2.fromOffset(360, 48)
        or UDim2.fromOffset(360, 490)
    minimize.Text = minimized and "+" or "_"
end)

local reopen = Instance.new("TextButton")
reopen.Size = UDim2.fromOffset(110, 38)
reopen.Position = UDim2.new(0, 15, 0.5, -19)
reopen.BackgroundColor3 = Color3.fromRGB(32, 39, 57)
reopen.TextColor3 = Color3.new(1, 1, 1)
reopen.Font = Enum.Font.GothamBold
reopen.TextSize = 12
reopen.Text = "OPEN PANEL"
reopen.Visible = false
reopen.Parent = gui
Instance.new("UICorner", reopen).CornerRadius = UDim.new(0, 8)

close.Activated:Connect(function()
    main.Visible = false
    reopen.Visible = true
end)

reopen.Activated:Connect(function()
    main.Visible = true
    reopen.Visible = false
end)

-- Press RightShift to hide/show the panel.
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.RightShift then
        main.Visible = not main.Visible
        reopen.Visible = false
    end
end)

-- Capture the camera FOV when the script starts.
if workspace.CurrentCamera then
    originalFOV = workspace.CurrentCamera.FieldOfView
    settings.FOV = originalFOV
end

print("Client Admin Panel loaded successfully!")
