--[[
    💾 FlyHubV4 - Murder Mystery 2 Mobile
    💻 Developer: Viros-coder
    📦 Repository: dog
    📜 Script: mscv.lua
    ⚡ النسخة الأسطورية: Wall Check + Highlight + Distance + Dynamic Themes Fixed
--]]

pcall(function()
    if game:GetService("PlayerGui"):FindFirstChild("FlyHub_MM2_Legend") then 
        game:GetService("PlayerGui").FlyHub_MM2_Legend:Destroy() 
    end
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Settings = {
    ESP_Enabled = true,
    AimLock = false,
    AimFOV = 140,
    AimSmooth = 0.18,
    TeleportHeight = 6
}

local Themes = {
    {Name = "Dark",   Background = Color3.fromRGB(20,20,20),   Accent = Color3.fromRGB(0,170,255),   Button = Color3.fromRGB(35,35,35)},
    {Name = "Purple", Background = Color3.fromRGB(28,15,40),   Accent = Color3.fromRGB(180,60,255), Button = Color3.fromRGB(50,25,70)},
    {Name = "Red",    Background = Color3.fromRGB(30,15,15),   Accent = Color3.fromRGB(255,70,70),  Button = Color3.fromRGB(55,20,20)},
    {Name = "Green",  Background = Color3.fromRGB(15,30,20),   Accent = Color3.fromRGB(60,255,120), Button = Color3.fromRGB(25,50,35)},
    {Name = "Cyan",   Background = Color3.fromRGB(15,25,35),   Accent = Color3.fromRGB(0,255,200),  Button = Color3.fromRGB(25,45,55)}
}

local CurrentTheme = 1

local Colors = {
    Murder = Color3.fromRGB(255, 50, 50),
    Sheriff = Color3.fromRGB(50, 150, 255),
    Innocent = Color3.fromRGB(50, 255, 50),
    GunDrop = Color3.fromRGB(255, 215, 0)
}

local PlayerRoles = {}
local ESP_Objects = {}
local MainContainer = nil
local Hidden = false

-- جداول لتخزين عناصر الواجهة لتحديث ألوانها ديناميكياً
local UI_Buttons = {}
local UI_Fills = {}

local function GetRoot(char)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"))
end

local function GetDistance(part)
    local myRoot = GetRoot(LocalPlayer.Character)
    return myRoot and math.floor((part.Position - myRoot.Position).Magnitude) or 0
end

-- ==================== Wall Check ====================
local function IsVisible(targetPart)
    local character = LocalPlayer.Character
    if not character or not targetPart then return false end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character, game:GetService("PlayerGui")}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true

    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin

    local raycastResult = Workspace:Raycast(origin, direction, raycastParams)

    if raycastResult then
        local hitInstance = raycastResult.Instance
        if hitInstance:IsDescendantOf(targetPart.Parent) then
            return true
        end
        return false
    end
    return true
end

local function UpdateRole(player, role)
    PlayerRoles[player] = role
end

local function CheckTool(player, tool)
    if not tool:IsA("Tool") then return end
    if tool.Name:find("Knife") or tool.Name:find("Blade") then
        UpdateRole(player, "Murder")
    elseif tool.Name:find("Gun") or tool.Name:find("Revolver") then
        UpdateRole(player, "Sheriff")
    end
end

local function MonitorPlayer(player)
    if player == LocalPlayer then return end
    PlayerRoles[player] = "Innocent"

    local function OnCharacterAdded(char)
        char.ChildAdded:Connect(function(t) CheckTool(player, t) end)
        local bp = player:WaitForChild("Backpack", 5)
        if bp then bp.ChildAdded:Connect(function(t) CheckTool(player, t) end) end
    end

    if player.Character then OnCharacterAdded(player.Character) end
    player.CharacterAdded:Connect(OnCharacterAdded)
end

local function RemoveESP(player)
    local data = ESP_Objects[player]
    if data then
        if data.connection then data.connection:Disconnect() end
        pcall(function() data.billboard:Destroy() end)
        pcall(function() data.highlight:Destroy() end)
        ESP_Objects[player] = nil
    end
end

local function ApplyESP(player)
    if player == LocalPlayer then return end
    RemoveESP(player)

    local function OnCharacterAdded(char)
        local root = GetRoot(char)
        if not root then return end

        local billboard = Instance.new("BillboardGui")
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(5.5, 0, 7.5, 0)
        billboard.Adornee = root
        billboard.Parent = game:GetService("PlayerGui")

        local frame = Instance.new("Frame", billboard)
        frame.Size = UDim2.new(1,0,1,0)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 2

        local nameLabel = Instance.new("TextLabel", billboard)
        nameLabel.Size = UDim2.new(1,0,0.38,0)
        nameLabel.Position = UDim2.new(0,0,-0.35,0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextStrokeTransparency = 0.4

        local highlight = Instance.new("Highlight")
        highlight.Adornee = char
        highlight.FillTransparency = 0.6
        highlight.OutlineTransparency = 0
        highlight.OutlineColor = Color3.new(1,1,1)
        highlight.Parent = game:GetService("PlayerGui")

        local connection = RunService.RenderStepped:Connect(function()
            if not char.Parent or not Settings.ESP_Enabled then
                billboard.Enabled = false
                highlight.Enabled = false
                return
            end

            billboard.Enabled = true
            highlight.Enabled = true

            local role = PlayerRoles[player] or "Innocent"
            local col = Colors[role]
            local dist = GetDistance(root)

            frame.BorderColor3 = col
            highlight.FillColor = col
            highlight.OutlineColor = col

            nameLabel.Text = string.format("%s [%s] - %dm", player.Name, role, dist)
            nameLabel.TextColor3 = col
        end)

        ESP_Objects[player] = {billboard = billboard, highlight = highlight, connection = connection}
    end

    if player.Character then task.spawn(OnCharacterAdded, player.Character) end
    player.CharacterAdded:Connect(OnCharacterAdded)
    player.CharacterRemoving:Connect(function() RemoveESP(player) end)
end

-- Item ESP
Workspace.DescendantAdded:Connect(function(obj)
    if obj.Name == "GunDrop" or obj.Name:find("Coin") then
        if obj:FindFirstChild("FlyItemESP") then return end
        local folder = Instance.new("Folder", obj) folder.Name = "FlyItemESP"

        local bg = Instance.new("BillboardGui", obj)
        bg.AlwaysOnTop = true
        bg.Size = UDim2.new(6,0,3,0)

        local txt = Instance.new("TextLabel", bg)
        txt.Size = UDim2.new(1,0,1,0)
        txt.BackgroundTransparency = 1
        txt.TextScaled = true
        txt.Font = Enum.Font.GothamBold

        if obj.Name == "GunDrop" then
            txt.Text = "⚠️ GUN DROP ⚠️"
            txt.TextColor3 = Colors.GunDrop
        else
            txt.Text = "💰 COIN"
            txt.TextColor3 = Color3.fromRGB(255, 220, 0)
        end

        local hl = Instance.new("Highlight", obj)
        hl.FillColor = obj.Name == "GunDrop" and Colors.GunDrop or Color3.fromRGB(255, 220, 0)
        hl.OutlineColor = Color3.new(1,1,1)
        hl.FillTransparency = 0.65
    end
end)

-- Safe Teleport
local function TeleportToTarget()
    local myRole = PlayerRoles[LocalPlayer] or "Innocent"
    local myRoot = GetRoot(LocalPlayer.Character)
    if not myRoot then return end

    local targetRoot, minDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local tRole = PlayerRoles[p] or "Innocent"
            local valid = (myRole == "Sheriff" and tRole == "Murder") or (myRole == "Murder" and (tRole == "Innocent" or tRole == "Sheriff"))
            if valid then
                local root = GetRoot(p.Character)
                if root then
                    local dist = (root.Position - myRoot.Position).Magnitude
                    if dist < minDist then
                        minDist = dist
                        targetRoot = root
                    end
                end
            end
        end
    end

    if targetRoot then
        local targetCFrame = targetRoot.CFrame * CFrame.new(0, Settings.TeleportHeight, 0)
        TweenService:Create(myRoot, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {CFrame = targetCFrame}):Play()
    end
end

-- ==================== Aim Lock مع Wall Check ====================
RunService.RenderStepped:Connect(function()
    if Settings.AimLock then
        local myRole = PlayerRoles[LocalPlayer] or "Innocent"
        local target = nil
        local minDist = Settings.AimFOV
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local tRole = PlayerRoles[p] or "Innocent"
                
                local isTarget = false
                if myRole == "Sheriff" and tRole == "Murder" then
                    isTarget = true
                elseif myRole == "Murder" and (tRole == "Innocent" or tRole == "Sheriff") then
                    isTarget = true
                end

                if isTarget then
                    local root = GetRoot(p.Character)
                    if root then
                        local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                        if onScreen then
                            local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                            if dist < minDist and IsVisible(root) then
                                minDist = dist
                                target = root
                            end
                        end
                    end
                end
            end
        end

        if target then
            local goal = CFrame.lookAt(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(goal, 1 - Settings.AimSmooth)
        end
    end
end)

-- ==================== GUI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FlyHub_MM2_Legend"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("PlayerGui")

MainContainer = Instance.new("Frame")
MainContainer.Size = UDim2.new(0, 190, 0, 480)
MainContainer.Position = UDim2.new(0.02, 0, 0.1, 0)
MainContainer.BackgroundColor3 = Themes[1].Background
MainContainer.Parent = ScreenGui
Instance.new("UICorner", MainContainer).CornerRadius = UDim.new(0, 14)

local MainStroke = Instance.new("UIStroke", MainContainer)
MainStroke.Color = Themes[1].Accent
MainStroke.Thickness = 1.5

local List = Instance.new("UIListLayout", MainContainer)
List.Padding = UDim.new(0, 9)
List.SortOrder = Enum.SortOrder.LayoutOrder

local function CreateButton(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 45)
    btn.BackgroundColor3 = Themes[CurrentTheme].Button
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Parent = MainContainer
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    btn.MouseButton1Click:Connect(callback)
    
    table.insert(UI_Buttons, btn) -- تخزين الزر لتغيير لونه لاحقاً
    return btn
end

CreateButton("⬇️ إخفاء الـ GUI", function() Hidden = not Hidden; MainContainer.Visible = not Hidden end)

CreateButton("🎨 تغيير اللون", function()
    CurrentTheme = CurrentTheme % #Themes + 1
    local theme = Themes[CurrentTheme]
    
    -- تحديث الحاوية الرئيسية
    MainContainer.BackgroundColor3 = theme.Background
    MainStroke.Color = theme.Accent
    
    -- تحديث الأزرار ديناميكياً
    for _, btn in ipairs(UI_Buttons) do
        btn.BackgroundColor3 = theme.Button
    end
    
    -- تحديث السلايدرات ديناميكياً
    for _, fill in ipairs(UI_Fills) do
        fill.BackgroundColor3 = theme.Accent
    end
end)

CreateButton("⚡ Teleport", TeleportToTarget)

local AimBtn = CreateButton("Aim: OFF", function()
    Settings.AimLock = not Settings.AimLock
    AimBtn.Text = "Aim: " .. (Settings.AimLock and "ON" or "OFF")
end)

local EspBtn = CreateButton("ESP: ON", function()
    Settings.ESP_Enabled = not Settings.ESP_Enabled
    EspBtn.Text = "ESP: " .. (Settings.ESP_Enabled and "ON" or "OFF")
end)

-- Sliders
local function CreateSlider(name, minVal, maxVal, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 60)
    frame.BackgroundColor3 = Color3.fromRGB(28,28,28)
    frame.Parent = MainContainer
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1,0,0,25)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. default
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 11

    local bar = Instance.new("Frame", frame)
    bar.Size = UDim2.new(0.9,0,0,8)
    bar.Position = UDim2.new(0.05,0,0.55,0)
    bar.BackgroundColor3 = Color3.fromRGB(45,45,45)
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)

    local fill = Instance.new("Frame", bar)
    fill.BackgroundColor3 = Themes[CurrentTheme].Accent
    fill.Size = UDim2.new((default - minVal) / (maxVal - minVal), 0, 1, 0)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
    
    table.insert(UI_Fills, fill) -- تخزين التعبئة لتغيير لونها لاحقاً

    local dragging = false
    local function UpdateSlider(inp)
        local rel = math.clamp((inp.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(minVal + (maxVal - minVal) * rel)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        label.Text = name .. ": " .. val
        callback(val)
    end

    bar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then dragging = true; UpdateSlider(inp) end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then UpdateSlider(inp) end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

CreateSlider("FOV", 60, 300, Settings.AimFOV, function(v) Settings.AimFOV = v end)
CreateSlider("Smooth", 5, 40, Settings.AimSmooth * 100, function(v) Settings.AimSmooth = v / 100 end)

-- تهيئة اللاعبين
for _, plr in ipairs(Players:GetPlayers()) do
    MonitorPlayer(plr)
    ApplyESP(plr)
end
Players.PlayerAdded:Connect(function(plr)
    MonitorPlayer(plr)
    ApplyESP(plr)
end)

print("🔥 FlyHubV4 | mscv.lua Loaded Successfully!")
