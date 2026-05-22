--[[
    💾 FlyHubV4 - Murder Mystery 2 Mobile Ultra Framework
    💻 Developer: Viros-coder
    📦 Repository: dog
    📜 Script: mscv.lua
    ⚡ Fixes: Zero-Lag Events + Dynamic Wall Check + GitHub/Delta Safe Architecture
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
    TeleportHeight = 7
}

local Colors = {
    Murder = Color3.fromRGB(255, 50, 50),
    Sheriff = Color3.fromRGB(50, 150, 255),
    Innocent = Color3.fromRGB(50, 255, 50),
    GunDrop = Color3.fromRGB(255, 215, 0)
}

local PlayerRoles = {}
local ESP_Objects = {}

local function GetRoot(char)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
end

local function GetDistance(part)
    local myRoot = GetRoot(LocalPlayer.Character)
    return myRoot and math.floor((part.Position - myRoot.Position).Magnitude) or 0
end

-- ==================== 👁️ فحص الجدران الذكي (Wall Check Optimization) ====================
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
        return raycastResult.Instance:IsDescendantOf(targetPart.Parent)
    end
    return true
end

local function CheckTool(player, tool)
    if not tool:IsA("Tool") then return end
    if tool.Name:find("Knife") or tool.Name:find("Blade") or tool:FindFirstChild("KnifeServer") then
        PlayerRoles[player] = "Murder"
    elseif tool.Name:find("Gun") or tool.Name:find("Revolver") or tool:FindFirstChild("GunServer") then
        PlayerRoles[player] = "Sheriff"
    end
end

local function MonitorPlayer(player)
    if player == LocalPlayer then return end
    PlayerRoles[player] = "Innocent"

    local function OnCharacterAdded(char)
        char.ChildAdded:Connect(function(t) CheckTool(player, t) end)
        for _, t in ipairs(char:GetChildren()) do CheckTool(player, t) end
        
        local bp = player:WaitForChild("Backpack", 4)
        if bp then 
            bp.ChildAdded:Connect(function(t) CheckTool(player, t) end)
            for _, t in ipairs(bp:GetChildren()) do CheckTool(player, t) end
        end
    end

    if player.Character then OnCharacterAdded(player.Character) end
    player.CharacterAdded:Connect(OnCharacterAdded)
end

local function RemoveESP(player)
    if ESP_Objects[player] then
        if ESP_Objects[player].connection then ESP_Objects[player].connection:Disconnect() end
        pcall(function() ESP_Objects[player].billboard:Destroy() end)
        pcall(function() ESP_Objects[player].highlight:Destroy() end)
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
        billboard.Name = "Delta_BGui"
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(4.5, 0, 5.5, 0)
        billboard.Adornee = root
        billboard.Parent = game:GetService("PlayerGui")

        local frame = Instance.new("Frame", billboard)
        frame.Size = UDim2.new(1,0,1,0)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 2
        frame.BorderColor3 = Colors.Innocent

        local nameLabel = Instance.new("TextLabel", billboard)
        nameLabel.Size = UDim2.new(1,0,0.22,0)
        nameLabel.Position = UDim2.new(0,0,-0.28,0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextStrokeTransparency = 0.3
        nameLabel.TextColor3 = Colors.Innocent

        local highlight = Instance.new("Highlight", game:GetService("PlayerGui"))
        highlight.Adornee = char
        highlight.FillTransparency = 0.6
        highlight.OutlineTransparency = 0
        highlight.FillColor = Colors.Innocent
        highlight.OutlineColor = Colors.Innocent

        local data = {billboard = billboard, highlight = highlight}
        ESP_Objects[player] = data

        data.connection = RunService.RenderStepped:Connect(function()
            if not char or not char.Parent or not root or not billboard.Parent then
                RemoveESP(player)
                return
            end

            if not Settings.ESP_Enabled then
                frame.Visible = false
                nameLabel.Visible = false
                highlight.Enabled = false
                return
            end

            frame.Visible = true
            nameLabel.Visible = true
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
    end

    if player.Character then task.spawn(OnCharacterAdded, player.Character) end
    player.CharacterAdded:Connect(OnCharacterAdded)
end

-- 🔄 معالجة التحديث التلقائي الفوري لمسح الذاكرة عند الجولات الجديدة لمنع تداخل الألوان
Workspace.ChildAdded:Connect(function(child)
    if child.Name == "Normal" or child.Name == "CoinContainer" or child.Name == "CoinVisuals" then
        table.clear(PlayerRoles)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then PlayerRoles[p] = "Innocent" end
        end
    end
end)

-- ==================== ⚡ نظام النقل الآمن (Safe Teleport Fix) ====================
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
        myRoot.CFrame = targetCFrame -- استخدام النقل المباشر والسريع ليتناسب مع أجهزة الهواتف لتفادي الـ Kick
    end
end

-- ==================== 🎯 محرك التصويب الذكي الخفيف ====================
local function GetBestAimTarget()
    local myRole = PlayerRoles[LocalPlayer] or "Innocent"
    local bestTarget = nil
    local shortestDistance = Settings.AimFOV
    local centerScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local tRole = PlayerRoles[player] or "Innocent"
            local isValid = (myRole == "Sheriff" and tRole == "Murder") or (myRole == "Murder")
            
            if isValid then
                local root = GetRoot(player.Character)
                if root and IsVisible(root) then
                    local screenPoint, onScreen = Camera:WorldToViewportPoint(root.Position)
                    if onScreen then
                        local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - centerScreen).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            bestTarget = root
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

RunService.RenderStepped:Connect(function()
    if Settings.AimLock then
        local targetRoot = GetBestAimTarget()
        if targetRoot then
            local targetRotation = CFrame.lookAt(Camera.CFrame.Position, targetRoot.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetRotation, 1 - Settings.AimSmooth)
        end
    end
end)

-- ==================== 📱 الواجهة المستقلة والمحصنة ضد أخطاء Delta ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FlyHub_MM2_Legend"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("PlayerGui")

local Container = Instance.new("Frame")
Container.Size = UDim2.new(0, 115, 0, 210)
Container.Position = UDim2.new(0.02, 0, 0.35, 0)
Container.BackgroundTransparency = 1
Container.Parent = ScreenGui

local UIList = Instance.new("UIListLayout", Container)
UIList.Padding = UDim.new(0, 6)
UIList.SortOrder = Enum.SortOrder.LayoutOrder

local function CreateDeltaButton(text, color, layoutOrder, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.LayoutOrder = layoutOrder
    btn.Parent = Container
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(255,255,255)
    stroke.Transparency = 0.85

    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- 1. زر الانتقال
CreateDeltaButton("⚡ Teleport Target", Color3.fromRGB(210, 50, 50), 1, TeleportToTarget)

-- 2. زر التصويب
local AimBtn
AimBtn = CreateDeltaButton("AimLock: OFF", Color3.fromRGB(40, 40, 40), 2, function()
    Settings.AimLock = not Settings.AimLock
    if Settings.AimLock then
        AimBtn.Text = "AimLock: ON"
        AimBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
    else
        AimBtn.Text = "AimLock: OFF"
        AimBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end
end)

-- 3. زر الـ ESP
local EspBtn
EspBtn = CreateDeltaButton("ESP: ON", Color3.fromRGB(50, 180, 50), 3, function()
    Settings.ESP_Enabled = not Settings.ESP_Enabled
    if Settings.ESP_Enabled then
        EspBtn.Text = "ESP: ON"
        EspBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
    else
        EspBtn.Text = "ESP: OFF"
        EspBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end
end)

-- 4. المنزلقات البرمجية الآمنة لـ Delta (Isolated Sliders)
local function CreateDeltaSlider(name, minVal, maxVal, currentVal, layoutOrder, callback)
    local base = Instance.new("Frame")
    base.Size = UDim2.new(1, 0, 0, 40)
    base.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    base.LayoutOrder = layoutOrder
    base.Parent = Container
    Instance.new("UICorner", base).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", base)
    lbl.Size = UDim2.new(1, 0, 0, 16)
    lbl.BackgroundTransparency = 1
    lbl.Text = name .. ": " .. math.floor(currentVal)
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 9

    local sliderBar = Instance.new("Frame", base)
    sliderBar.Size = UDim2.new(0.9, 0, 0, 6)
    sliderBar.Position = UDim2.new(0.05, 0, 0.55, 0)
    sliderBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    Instance.new("UICorner", sliderBar).CornerRadius = UDim.new(0, 3)

    local fill = Instance.new("Frame", sliderBar)
    fill.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
    fill.Size = UDim2.new((currentVal - minVal) / (maxVal - minVal), 0, 1, 0)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)

    local active = false

    local function RefreshSlider(input)
        local ratio = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
        local value = minVal + (maxVal - minVal) * ratio
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        lbl.Text = name .. ": " .. math.floor(value)
        callback(value)
    end

    sliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            active = true; RefreshSlider(input)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if active and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            RefreshSlider(input)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then active = false end
    end)
end

CreateDeltaSlider("FOV Range", 60, 300, Settings.AimFOV, 4, function(v) Settings.AimFOV = v end)
CreateDeltaSlider("Smooth", 5, 40, Settings.AimSmooth * 100, 5, function(v) Settings.AimSmooth = v / 100 end)

-- تشغيل النظام وضخ بيئة اللاعبين
for _, plr in ipairs(Players:GetPlayers()) do
    MonitorPlayer(plr)
    ApplyESP(plr)
end
Players.PlayerAdded:Connect(function(plr)
    MonitorPlayer(plr)
    ApplyESP(plr)
end)

print("🚀 FlyHubV4 Injected & Ready on GitHub for Delta execution!")
