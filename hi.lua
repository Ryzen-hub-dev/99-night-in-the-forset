--[[

	Ryzen Hub Interface Suite
	by Ryzen Team

	shlex  | Designing + Programming
	iRay   | Programming
	Max    | Programming
	Damian | Programming

]]

if debugX then
	warn('Initialising Ryzen Hub')
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- Wait for character and camera
repeat task.wait(0.1) until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
local camera = workspace.CurrentCamera
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Variables
local teleportTargets = {
    "Alien", "Alien Chest", "Alien Shelf", "Alpha Wolf", "Alpha Wolf Pelt", "Anvil Base", "Apple", "Bandage", "Bear", "Berry",
    "Bolt", "Broken Fan", "Broken Microwave", "Bunny", "Bunny Foot", "Cake", "Carrot", "Chair Set", "Chest", "Chilli",
    "Coal", "Coin Stack", "Crossbow Cultist", "Cultist", "Cultist Gem", "Deer", "Fuel Canister", "Giant Sack", "Good Axe", "Iron Body",
    "Item Chest", "Item Chest2", "Item Chest3", "Item Chest4", "Item Chest6", "Laser Fence Blueprint", "Laser Sword", "Leather Body", "Log", "Lost Child",
    "Lost Child2", "Lost Child3", "Lost Child4", "Medkit", "Meat? Sandwich", "Morsel", "Old Car Engine", "Old Flashlight", "Old Radio", "Oil Barrel",
    "Raygun", "Revolver", "Revolver Ammo", "Rifle", "Rifle Ammo", "Riot Shield", "Sapling", "Seed Box", "Sheet Metal", "Spear",
    "Steak", "Stronghold Diamond Chest", "Tyre", "UFO Component", "UFO Junk", "Washing Machine", "Wolf", "Wolf Corpse", "Wolf Pelt"
}
local AimbotTargets = {"Alien", "Alpha Wolf", "Wolf", "Crossbow Cultist", "Cultist", "Bunny", "Bear", "Polar Bear"}
local espEnabled = false
local npcESPEnabled = false
local ignoreDistanceFrom = Vector3.new(0, 0, 0)
local minDistance = 50
local AutoTreeFarmEnabled = false
local AimbotEnabled = false
local FOVRadius = 100
local flying = false
local flyConnection = nil
local speed = 60
local npcBoxes = {}
local badTrees = {}

-- UI Setup (Wind Style)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RyzenHubUI"
screenGui.Parent = gethui or syn.protect_gui and CoreGui or playerGui
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 450, 0, 550)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -275)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(0, 255, 150)
mainStroke.Thickness = 2
mainStroke.Transparency = 0.5
mainStroke.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 50)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Ryzen Hub : 99 Night In The Forset"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 10)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.Font = Enum.Font.Gotham
closeButton.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -80)
scrollFrame.Position = UDim2.new(0, 10, 0, 60)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 150)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 1000)
scrollFrame.Parent = mainFrame

-- Home Section
local homeSection = Instance.new("Frame")
homeSection.Size = UDim2.new(1, -20, 0, 350)
homeSection.Position = UDim2.new(0, 10, 0, 10)
homeSection.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
homeSection.BackgroundTransparency = 0.2
homeSection.Parent = scrollFrame

local homeCorner = Instance.new("UICorner")
homeCorner.CornerRadius = UDim.new(0, 8)
homeCorner.Parent = homeSection

local homeTitle = Instance.new("TextLabel")
homeTitle.Size = UDim2.new(1, 0, 0, 30)
homeTitle.Position = UDim2.new(0, 10, 0, 5)
homeTitle.BackgroundTransparency = 1
homeTitle.Text = "🏠 Home"
homeTitle.TextColor3 = Color3.fromRGB(0, 255, 150)
homeTitle.TextScaled = true
homeTitle.Font = Enum.Font.GothamSemibold
homeTitle.Parent = homeSection

local btnTeleportCampfire = Instance.new("TextButton")
btnTeleportCampfire.Size = UDim2.new(1, -20, 0, 35)
btnTeleportCampfire.Position = UDim2.new(0, 10, 0, 40)
btnTeleportCampfire.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
btnTeleportCampfire.Text = "Teleport to Campfire"
btnTeleportCampfire.TextColor3 = Color3.fromRGB(255, 255, 255)
btnTeleportCampfire.Font = Enum.Font.Gotham
btnTeleportCampfire.Parent = homeSection
btnTeleportCampfire.MouseButton1Click:Connect(function() LocalPlayer.Character:PivotTo(CFrame.new(0, 10, 0)) end)

local btnTeleportGrinder = Instance.new("TextButton")
btnTeleportGrinder.Size = UDim2.new(1, -20, 0, 35)
btnTeleportGrinder.Position = UDim2.new(0, 10, 0, 80)
btnTeleportGrinder.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
btnTeleportGrinder.Text = "Teleport to Grinder"
btnTeleportGrinder.TextColor3 = Color3.fromRGB(255, 255, 255)
btnTeleportGrinder.Font = Enum.Font.Gotham
btnTeleportGrinder.Parent = homeSection
btnTeleportGrinder.MouseButton1Click:Connect(function() LocalPlayer.Character:PivotTo(CFrame.new(16.1, 4, -4.6)) end)

local toggleItemESP = Instance.new("TextButton")
toggleItemESP.Size = UDim2.new(1, -20, 0, 35)
toggleItemESP.Position = UDim2.new(0, 10, 0, 120)
toggleItemESP.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
toggleItemESP.Text = "Item ESP: OFF"
toggleItemESP.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleItemESP.Font = Enum.Font.Gotham
toggleItemESP.Parent = homeSection

local toggleNPESP = Instance.new("TextButton")
toggleNPESP.Size = UDim2.new(1, -20, 0, 35)
toggleNPESP.Position = UDim2.new(0, 10, 0, 160)
toggleNPESP.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
toggleNPESP.Text = "NPC ESP: OFF"
toggleNPESP.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleNPESP.Font = Enum.Font.Gotham
toggleNPESP.Parent = homeSection

local toggleAutoTree = Instance.new("TextButton")
toggleAutoTree.Size = UDim2.new(1, -20, 0, 35)
toggleAutoTree.Position = UDim2.new(0, 10, 0, 200)
toggleAutoTree.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
toggleAutoTree.Text = "Auto Tree Farm: OFF"
toggleAutoTree.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleAutoTree.Font = Enum.Font.Gotham
toggleAutoTree.Parent = homeSection

local toggleAimbot = Instance.new("TextButton")
toggleAimbot.Size = UDim2.new(1, -20, 0, 35)
toggleAimbot.Position = UDim2.new(0, 10, 0, 240)
toggleAimbot.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
toggleAimbot.Text = "Aimbot: OFF"
toggleAimbot.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleAimbot.Font = Enum.Font.Gotham
toggleAimbot.Parent = homeSection

local toggleFly = Instance.new("TextButton")
toggleFly.Size = UDim2.new(1, -20, 0, 35)
toggleFly.Position = UDim2.new(0, 10, 0, 280)
toggleFly.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
toggleFly.Text = "Fly: OFF"
toggleFly.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleFly.Font = Enum.Font.Gotham
toggleFly.Parent = homeSection

-- Teleport Section
local teleSection = Instance.new("Frame")
teleSection.Size = UDim2.new(1, -20, 0, 600)
teleSection.Position = UDim2.new(0, 10, 0, 370)
teleSection.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
teleSection.BackgroundTransparency = 0.2
teleSection.Parent = scrollFrame

local teleCorner = Instance.new("UICorner")
teleCorner.CornerRadius = UDim.new(0, 8)
teleCorner.Parent = teleSection

local teleTitle = Instance.new("TextLabel")
teleTitle.Size = UDim2.new(1, 0, 0, 30)
teleTitle.Position = UDim2.new(0, 10, 0, 5)
teleTitle.BackgroundTransparency = 1
teleTitle.Text = "🧲 Teleport"
teleTitle.TextColor3 = Color3.fromRGB(0, 255, 150)
teleTitle.TextScaled = true
teleTitle.Font = Enum.Font.GothamSemibold
teleTitle.Parent = teleSection

local teleLayout = Instance.new("UIListLayout")
teleLayout.FillDirection = Enum.FillDirection.Vertical
teleLayout.Padding = UDim.new(0, 5)
teleLayout.Parent = teleSection

-- Dynamic Teleport Buttons
for _, itemName in ipairs(teleportTargets) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 25)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    btn.Text = "Teleport to " .. itemName
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextScaled = true
    btn.Parent = teleSection
    btn.MouseButton1Click:Connect(function()
        local closest, shortest = nil, math.huge
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name == itemName and obj:IsA("Model") then
                local cf = nil
                pcall(function() cf = obj:GetPivot() end)
                if not cf then
                    local part = obj:FindFirstChildWhichIsA("BasePart")
                    if part then cf = part.CFrame end
                end
                if cf then
                    local dist = (cf.Position - ignoreDistanceFrom).Magnitude
                    if dist >= minDistance and dist < shortest then
                        closest = obj
                        shortest = dist
                    end
                end
            end
        end
        if closest then
            local cf = nil
            pcall(function() cf = closest:GetPivot() end)
            if not cf then
                local part = closest:FindFirstChildWhichIsA("BasePart")
                if part then cf = part.CFrame end
            end
            if cf then
                LocalPlayer.Character:PivotTo(cf + Vector3.new(0, 5, 0))
            end
        end
    end)
end

teleLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    teleSection.Size = UDim2.new(1, 0, 0, teleLayout.AbsoluteContentSize.Y + 10)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, homeSection.AbsoluteSize.Y + teleSection.AbsoluteSize.Y + 20)
end)

-- Toggle Function
local function toggleSwitch(button, stateVar, func)
    pcall(function()
        if _G[stateVar] then
            button.Text = button.Text:gsub("ON", "OFF")
            button.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            _G[stateVar] = false
            pcall(func, false)
        else
            button.Text = button.Text:gsub("OFF", "ON")
            button.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
            _G[stateVar] = true
            pcall(func, true)
        end
    end)
end

-- Connect Toggles
toggleItemESP.MouseButton1Click:Connect(function() toggleSwitch(toggleItemESP, "espEnabled", toggleESP) end)
toggleNPESP.MouseButton1Click:Connect(function() toggleSwitch(toggleNPESP, "npcESPEnabled", toggleNPCESP) end)
toggleAutoTree.MouseButton1Click:Connect(function() toggleSwitch(toggleAutoTree, "AutoTreeFarmEnabled", function(v) AutoTreeFarmEnabled = v end) end)
toggleAimbot.MouseButton1Click:Connect(function() toggleSwitch(toggleAimbot, "AimbotEnabled", function(v) AimbotEnabled = v end) end)
toggleFly.MouseButton1Click:Connect(function() toggleSwitch(toggleFly, "flying", toggleFly) end)

-- Animation
local openTween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {BackgroundTransparency = 0})
local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {BackgroundTransparency = 1})

mainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
    if mainFrame.Visible then
        openTween:Play()
    else
        closeTween:Play()
    end
end)

closeButton.MouseButton1Click:Connect(function() mainFrame.Visible = false end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        mainFrame.Visible = not mainFrame.Visible
        print("UI Toggled:", mainFrame.Visible)
    end
end)

-- Core Logic
function mouse1click()
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
end

local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(128, 255, 0)
FOVCircle.Thickness = 1
FOVCircle.Radius = FOVRadius
FOVCircle.Transparency = 0.5
FOVCircle.Filled = false
FOVCircle.Visible = false

RunService.RenderStepped:Connect(function()
    pcall(function()
        if AimbotEnabled then
            local mousePos = UserInputService:GetMouseLocation()
            FOVCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
            FOVCircle.Visible = true
        else
            FOVCircle.Visible = false
        end
    end)
end)

function createESP(item)
    pcall(function()
        local adorneePart
        if item:IsA("Model") then
            if item:FindFirstChildWhichIsA("Humanoid") then return end
            adorneePart = item:FindFirstChildWhichIsA("BasePart")
        elseif item:IsA("BasePart") then
            adorneePart = item
        else
            return
        end

        if not adorneePart then return end

        local distance = (adorneePart.Position - ignoreDistanceFrom).Magnitude
        if distance < minDistance then return end

        if not item:FindFirstChild("ESP_Billboard") then
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "ESP_Billboard"
            billboard.Adornee = adorneePart
            billboard.Size = UDim2.new(0, 50, 0, 20)
            billboard.AlwaysOnTop = true
            billboard.StudsOffset = Vector3.new(0, 2, 0)

            local label = Instance.new("TextLabel", billboard)
            label.Size = UDim2.new(1, 0, 1, 0)
            label.Text = item.Name
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.TextStrokeTransparency = 0
            label.TextScaled = true
            billboard.Parent = item
        end

        if not item:FindFirstChild("ESP_Highlight") then
            local highlight = Instance.new("Highlight")
            highlight.Name = "ESP_Highlight"
            highlight.FillColor = Color3.fromRGB(255, 85, 0)
            highlight.OutlineColor = Color3.fromRGB(0, 100, 0)
            highlight.FillTransparency = 0.25
            highlight.OutlineTransparency = 0
            highlight.Adornee = item:IsA("Model") and item or adorneePart
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = item
        end
    end)
end

function toggleESP(state)
    pcall(function()
        espEnabled = state
        for _, item in pairs(workspace:GetDescendants()) do
            if table.find(teleportTargets, item.Name) then
                if espEnabled then
                    createESP(item)
                else
                    if item:FindFirstChild("ESP_Billboard") then item.ESP_Billboard:Destroy() end
                    if item:FindFirstChild("ESP_Highlight") then item.ESP_Highlight:Destroy() end
                end
            end
        end
    end)
end

workspace.DescendantAdded:Connect(function(desc)
    pcall(function()
        if espEnabled and table.find(teleportTargets, desc.Name) then
            task.wait(0.1)
            createESP(desc)
        end
    end)
end)

function createNPCESP(npc)
    pcall(function()
        if not npc:IsA("Model") or npc:FindFirstChild("HumanoidRootPart") == nil then return end

        local root = npc:FindFirstChild("HumanoidRootPart")
        if npcBoxes[npc] then return end

        local box = Drawing.new("Square")
        box.Thickness = 2
        box.Transparency = 1
        box.Color = Color3.fromRGB(255, 85, 0)
        box.Filled = false
        box.Visible = true

        local nameText = Drawing.new("Text")
        nameText.Text = npc.Name
        nameText.Color = Color3.fromRGB(255, 255, 255)
        nameText.Size = 16
        nameText.Center = true
        nameText.Outline = true
        nameText.Visible = true

        npcBoxes[npc] = {box = box, name = nameText}

        npc.AncestryChanged:Connect(function(_, parent)
            if not parent and npcBoxes[npc] then
                npcBoxes[npc].box:Remove()
                npcBoxes[npc].name:Remove()
                npcBoxes[npc] = nil
            end
        end)
    end)
end

function toggleNPCESP(state)
    pcall(function()
        npcESPEnabled = state
        if not state then
            for npc, visuals in pairs(npcBoxes) do
                if visuals.box then visuals.box:Remove() end
                if visuals.name then visuals.name:Remove() end
            end
            npcBoxes = {}
        else
            for _, obj in ipairs(workspace:GetDescendants()) do
                if table.find(AimbotTargets, obj.Name) and obj:IsA("Model") then
                    createNPCESP(obj)
                end
            end
        end
    end)
end

workspace.DescendantAdded:Connect(function(desc)
    pcall(function()
        if table.find(AimbotTargets, desc.Name) and desc:IsA("Model") then
            task.wait(0.1)
            if npcESPEnabled then
                createNPCESP(desc)
            end
        end
    end)
end)

task.spawn(function()
    while true do
        pcall(function()
            if AutoTreeFarmEnabled then
                local trees = {}
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj.Name == "Trunk" and obj.Parent and obj.Parent.Name == "Small Tree" then
                        local distance = (obj.Position - ignoreDistanceFrom).Magnitude
                        if distance > minDistance and not badTrees[obj:GetFullName()] then
                            table.insert(trees, obj)
                        end
                    end
                end

                table.sort(trees, function(a, b)
                    return (a.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <
                           (b.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                end)

                for _, trunk in ipairs(trees) do
                    if not AutoTreeFarmEnabled then break end
                    LocalPlayer.Character:PivotTo(trunk.CFrame + Vector3.new(0, 3, 0))
                    task.wait(0.2)
                    local startTime = tick()
                    while AutoTreeFarmEnabled and trunk and trunk.Parent and trunk.Parent.Name == "Small Tree" do
                        mouse1click()
                        task.wait(0.2)
                        if tick() - startTime > 12 then
                            badTrees[trunk:GetFullName()] = true
                            break
                        end
                    end
                    task.wait(0.3)
                end
            end
        end)
        task.wait(1.5)
    end
end)

local lastAimbotCheck = 0
local aimbotCheckInterval = 0.02
local smoothness = 0.2

RunService.RenderStepped:Connect(function()
    pcall(function()
        if not AimbotEnabled or not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            FOVCircle.Visible = false
            return
        end

        local currentTime = tick()
        if currentTime - lastAimbotCheck < aimbotCheckInterval then return end
        lastAimbotCheck = currentTime

        local mousePos = UserInputService:GetMouseLocation()
        local closestTarget, shortestDistance = nil, math.huge

        for _, obj in ipairs(workspace:GetDescendants()) do
            if table.find(AimbotTargets, obj.Name) and obj:IsA("Model") then
                local head = obj:FindFirstChild("Head")
                if head then
                    local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if dist < shortestDistance and dist <= FOVRadius then
                            shortestDistance = dist
                            closestTarget = head
                        end
                    end
                end
            end
        end

        if closestTarget then
            local currentCF = camera.CFrame
            local targetCF = CFrame.new(camera.CFrame.Position, closestTarget.Position)
            camera.CFrame = currentCF:Lerp(targetCF, smoothness)
            FOVCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
            FOVCircle.Visible = true
        else
            FOVCircle.Visible = false
        end
    end)
end)

function startFlying()
    pcall(function()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local bodyGyro = Instance.new("BodyGyro", hrp)
        local bodyVelocity = Instance.new("BodyVelocity", hrp)
        bodyGyro.P = 9e4
        bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bodyGyro.CFrame = hrp.CFrame
        bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)

        flyConnection = RunService.RenderStepped:Connect(function()
            pcall(function()
                local moveVec = Vector3.zero
                local camCF = camera.CFrame
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec += camCF.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec -= camCF.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec -= camCF.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec += camCF.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVec += camCF.UpVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveVec -= camCF.UpVector end
                bodyVelocity.Velocity = moveVec.Magnitude > 0 and moveVec.Unit * speed or Vector3.zero
                bodyGyro.CFrame = camCF
            end)
        end)
    end)
end

function stopFlying()
    pcall(function()
        if flyConnection then flyConnection:Disconnect() end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, v in pairs(hrp:GetChildren()) do
                if v:IsA("BodyGyro") or v:IsA("BodyVelocity") then v:Destroy() end
            end
        end
    end)
end

function toggleFly(state)
    pcall(function()
        flying = state
        if flying then startFlying() else stopFlying() end
    end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Q then
        toggleFly(not flying)
    end
end)

RunService.RenderStepped:Connect(function()
    pcall(function()
        for npc, visuals in pairs(npcBoxes) do
            local box = visuals.box
            local name = visuals.name

            if npc and npc:FindFirstChild("HumanoidRootPart") then
                local hrp = npc.HumanoidRootPart
                local size = Vector2.new(60, 80)
                local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)

                if onScreen then
                    box.Position = Vector2.new(screenPos.X - size.X / 2, screenPos.Y - size.Y / 2)
                    box.Size = size
                    box.Visible = true

                    name.Position = Vector2.new(screenPos.X, screenPos.Y - size.Y / 2 - 15)
                    name.Visible = true
                else
                    box.Visible = false
                    name.Visible = false
                end
            else
                box:Remove()
                name:Remove()
                npcBoxes[npc] = nil
            end
        end
    end)
end)

-- Initialize globals
_G.espEnabled = false
_G.npcESPEnabled = false
_G.AutoTreeFarmEnabled = false
_G.AimbotEnabled = false
_G.flying = false

print("Ryzen Hub : 99 Night In The Forset loaded successfully! Press Insert to toggle UI.")
