--[[
    💾 FlyHubV4 - MM2 Mobile Ultra Framework
    💻 Developer: Viros-coder
    📦 Repository: dog
    📜 Script: mscv.lua
    📱 Layer-Flattening Fixed UI for Mobile Executors
--]]

local ESPFramework = {
    Connections = {},
    Cache = {},
    Roles = {},
    Settings = {
        Enabled = true,       
        PlayerESP = true,     
        TeamESP = true,       
        NameESP = true,       
        DistanceESP = true,   
        CoinESP = true,       
        MaxDistance = 1000,
        ThrottlingRate = 2,
        
        AimLockEnabled = false,
        AimWallCheck = true,
        AimSmoothness = 0.15, 
        AimFOV = 180,
        AimPart = "Torso"     
    },
    Colors = {
        Murder = Color3.fromRGB(255, 33, 33),
        Sheriff = Color3.fromRGB(33, 140, 255),
        Innocent = Color3.fromRGB(50, 255, 50),
        GunDrop = Color3.fromRGB(255, 215, 0),
        Coin = Color3.fromRGB(255, 235, 50)
    }
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera

pcall(function()
    if PlayerGui:FindFirstChild("MM2_ESP_GUI") then
        PlayerGui.MM2_ESP_GUI:Destroy()
    end
end)

function ESPFramework:RemovePlayerESP(player)
    if self.Cache[player] then
        if self.Cache[player].Billboard then self.Cache[player].Billboard:Destroy() end
        if self.Cache[player].Highlight then self.Cache[player].Highlight:Destroy() end
        self.Cache[player] = nil
    end
end

function ESPFramework:CheckPlayerRole(player)
    if player == LocalPlayer then return "Innocent" end
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return "Innocent" end
    
    local backpack = player:FindFirstChild("Backpack")
    local tools = {}
    if character then for _, v in ipairs(character:GetChildren()) do if v:IsA("Tool") then table.insert(tools, v) end end end
    if backpack then for _, v in ipairs(backpack:GetChildren()) do if v:IsA("Tool") then table.insert(tools, v) end end end
    
    for _, tool in ipairs(tools) do
        if tool.Name == "Knife" or tool.Name == "Blade" or tool:FindFirstChild("KnifeServer") then
            self.Roles[player] = "Murder"
            return "Murder"
        elseif tool.Name == "Gun" or tool.Name == "Revolver" or tool:FindFirstChild("GunServer") then
            self.Roles[player] = "Sheriff"
            return "Sheriff"
        end
    end
    return self.Roles[player] or "Innocent"
end

function ESPFramework:CreatePlayerESP(player)
    if player == LocalPlayer then return end
    self:RemovePlayerESP(player)
    
    local character = player.Character
    if not character then return end
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end
    
    local cacheData = {}
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_" .. player.Name
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(4.2, 0, 5.5, 0)
    billboard.Adornee = hrp
    billboard.Enabled = false
    billboard.Parent = PlayerGui
    
    local outline = Instance.new("Frame")
    outline.Name = "Outline"
    outline.Size = UDim2.new(1, 0, 1, 0)
    outline.BackgroundTransparency = 1
    outline.BorderSizePixel = 2
    outline.BorderColor3 = self.Colors.Innocent
    outline.Parent = billboard
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "PlayerName"
    nameLabel.Size = UDim2.new(1, 0, 0.15, 0)
    nameLabel.Position = UDim2.new(0, 0, -0.18, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard
    
    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "Distance"
    distLabel.Size = UDim2.new(1, 0, 0.12, 0)
    distLabel.Position = UDim2.new(0, 0, 1.02, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distLabel.TextStrokeTransparency = 0
    distLabel.TextScaled = true
    distLabel.Font = Enum.Font.Gotham
    distLabel.Parent = billboard
    
    cacheData.Billboard = billboard
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "Chams_" .. player.Name
    highlight.Adornee = character
    highlight.FillColor = self.Colors.Innocent
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = self.Colors.Innocent
    highlight.OutlineTransparency = 0
    highlight.Enabled = false
    highlight.Parent = PlayerGui
    
    cacheData.Highlight = highlight
    self.Cache[player] = cacheData
end

function ESPFramework:UpdateWorldItems()
    if not self.Settings.Enabled then return end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name == "GunDrop" or (obj:IsA("Tool") and (obj.Name:match("Gun") or obj.Name:match("Revolver"))) then
            local p = obj:IsA("Tool") and obj:FindFirstChild("Handle") or obj
            if p and not p:FindFirstChild("ItemESP") then
                local b = Instance.new("BillboardGui", p)
                b.Name = "ItemESP"
                b.AlwaysOnTop = true
                b.Size = UDim2.new(4, 0, 1, 0)
                local t = Instance.new("TextLabel", b)
                t.Size = UDim2.new(1,0,1,0)
                t.BackgroundTransparency = 1
                t.Text = "⚠️ GUN DROP"
                t.TextColor3 = self.Colors.GunDrop
                t.Font = Enum.Font.GothamBold
                t.TextSize = 14
                
                local h = Instance.new("Highlight", obj)
                h.FillColor = self.Colors.GunDrop
                h.OutlineColor = Color3.new(1,1,1)
            end
        end
    end

    local coinContainer = Workspace:FindFirstChild("Normal") and Workspace.Normal:FindFirstChild("CoinContainer") or Workspace:FindFirstChild("CoinContainer") or Workspace:FindFirstChild("CoinVisuals")
    if coinContainer and self.Settings.CoinESP then
        for _, coin in ipairs(coinContainer:GetChildren()) do
            if (coin:IsA("BasePart") or coin:IsA("Model")) and not coin:FindFirstChild("CoinESP") then
                local h = Instance.new("Highlight", coin)
                h.Name = "CoinESP"
                h.FillColor = self.Colors.Coin
                h.FillTransparency = 0.4
                h.OutlineTransparency = 0.8
            end
        end
    end
end

function ESPFramework:GetBestAimTarget()
    local myRole = self:CheckPlayerRole(LocalPlayer)
    local bestTarget = nil
    local shortestDistance = self.Settings.AimFOV
    local centerScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local targetPart = char:FindFirstChild(self.Settings.AimPart) or char:FindFirstChild("HumanoidRootPart")
            
            if targetPart then
                local isValidTarget = false
                local targetRole = self:CheckPlayerRole(player)
                
                if myRole == "Sheriff" then
                    isValidTarget = (targetRole == "Murder")
                elseif myRole == "Murder" then
                    isValidTarget = true
                end
                
                if isValidTarget then
                    local screenPoint, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - centerScreen).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            bestTarget = player
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

function ESPFramework:InitLoops()
    local counter = 0
    self.Connections["MainRenderLoop"] = RunService.RenderStepped:Connect(function()
        counter = (counter + 1) % self.Settings.ThrottlingRate
        if counter == 0 then self:UpdateWorldItems() end
        
        local lChar = LocalPlayer.Character
        local lHrp = lChar and lChar:FindFirstChild("HumanoidRootPart")
        
        if self.Settings.AimLockEnabled then
            local myRole = self:CheckPlayerRole(LocalPlayer)
            if myRole == "Sheriff" or myRole == "Murder" then
                local target = self:GetBestAimTarget()
                if target and target.Character then
                    local aimPart = target.Character:FindFirstChild(self.Settings.AimPart) or target.Character:FindFirstChild("HumanoidRootPart")
                    if aimPart then
                        local targetRotation = CFrame.lookAt(Camera.CFrame.Position, aimPart.Position)
                        Camera.CFrame = Camera.CFrame:Lerp(targetRotation, 1 - self.Settings.AimSmoothness)
                    end
                end
            end
        end
        
        for player, cache in pairs(self.Cache) do
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if char and hrp and lHrp and self.Settings.Enabled then
                local distance = (hrp.Position - lHrp.Position).Magnitude
                if distance > self.Settings.MaxDistance then
                    if cache.Billboard then cache.Billboard.Enabled = false end
                    if cache.Highlight then cache.Highlight.Enabled = false end
                else
                    if cache.Highlight then cache.Highlight.Enabled = self.Settings.PlayerESP end
                    if cache.Billboard then
                        cache.Billboard.Enabled = (self.Settings.PlayerESP or self.Settings.NameESP or self.Settings.DistanceESP)
                        local outline = cache.Billboard:FindFirstChild("Outline")
                        local nameLabel = cache.Billboard:FindFirstChild("PlayerName")
                        local distLabel = cache.Billboard:FindFirstChild("Distance")
                        
                        if outline then outline.Visible = self.Settings.PlayerESP end
                        if nameLabel then nameLabel.Visible = self.Settings.NameESP end
                        if distLabel then distLabel.Visible = self.Settings.DistanceESP end
                        if distLabel and self.Settings.DistanceESP then distLabel.Text = math.floor(distance) .. " studs" end
                    end
                    
                    if counter == 0 then
                        local role = self:CheckPlayerRole(player)
                        local color = self.Colors[role]
                        if cache.Billboard then
                            local outline = cache.Billboard:FindFirstChild("Outline")
                            local nameLabel = cache.Billboard:FindFirstChild("PlayerName")
                            if outline then outline.BorderColor3 = color end
                            if nameLabel then
                                nameLabel.Text = self.Settings.TeamESP and player.Name .. " [" .. role .. "]" or player.Name
                                nameLabel.TextColor3 = self.Settings.TeamESP and color or Color3.new(1,1,1)
                            end
                        end
                        if cache.Highlight then
                            cache.Highlight.FillColor = color
                            cache.Highlight.OutlineColor = color
                        end
                    end
                end
            else
                if cache.Billboard then cache.Billboard.Enabled = false end
                if cache.Highlight then cache.Highlight.Enabled = false end
                if not char or not hrp then self:RemovePlayerESP(player) end
            end
        end
    end)
end

function ESPFramework:Start()
    local function setup(player)
        if player == LocalPlayer then return end
        player.CharacterAdded:Connect(function() task.wait(0.5) self:CreatePlayerESP(player) end)
        player.CharacterRemoving:Connect(function() self:RemovePlayerESP(player) end)
        if player.Character then self:CreatePlayerESP(player) end
    end
    Players.PlayerAdded:Connect(setup)
    Players.PlayerRemoving:Connect(function(p) self:RemovePlayerESP(p) end)
    for _, p in ipairs(Players:GetPlayers()) do setup(p) end
    self:InitLoops()
end

--// NEW FLATTENED MOBILE GUI SYSTEM (ANTI-BLACK BOX OVERLAY)
local Gui = Instance.new("ScreenGui")
Gui.Name = "MM2_ESP_GUI"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

-- دالة سحب قوية ومباشرة للجوال
local function EnableDrag(UIFrame, HandlePart)
    local dragging, dragInput, dragStart, startPos
    HandlePart.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = UIFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    HandlePart.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            UIFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- 1. القائمة الرئيسية (تم جعل الخلفية رمادية داكنة جداً صريحة لضمان عدم التحول لأسود معتم)
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 260, 0, 390) 
Main.Position = UDim2.new(0.5, -130, 0.5, -195)
Main.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- لون صريح وليس أسود مطفأ
Main.BorderSizePixel = 0
Main.ZIndex = 1
Main.Visible = true
Main.Parent = Gui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Color3.fromRGB(255, 50, 50)
MainStroke.Width = 2

-- عنوان اللوحة
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Title.BorderSizePixel = 0
Title.Text = "  FlyHubV4 - Mobile Fixed"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 2
Title.Parent = Main

Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)
EnableDrag(Main, Title)

-- زر الإغلاق
local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0, 26, 0, 26)
Close.Position = UDim2.new(1, -34, 0.5, -13)
Close.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
Close.Text = "X"
Close.TextColor3 = Color3.fromRGB(255, 255, 255)
Close.Font = Enum.Font.GothamBold
Close.TextSize = 12
Close.ZIndex = 3
Close.Parent = Title
Instance.new("UICorner", Close).CornerRadius = UDim.new(1, 0)

-- 2. أيقونة الفتح 👺 (متموضعة على اليمين بحجم متوسط أسطوري وقابلة للسحب بنظام طبقة مرتفعة)
local OpenButton = Instance.new("TextButton")
OpenButton.Size = UDim2.new(0, 50, 0, 50) 
OpenButton.Position = UDim2.new(1, -70, 0.5, -25) -- يمين الشاشة تلقائياً بحجم متوسط مريح
OpenButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
OpenButton.BorderSizePixel = 0
OpenButton.Text = "👺"
OpenButton.TextSize = 26
OpenButton.ZIndex = 5
OpenButton.Visible = false 
OpenButton.Parent = Gui

Instance.new("UICorner", OpenButton).CornerRadius = UDim.new(1, 0)
local OpenStroke = Instance.new("UIStroke", OpenButton)
OpenStroke.Color = Color3.fromRGB(255, 50, 50)
OpenStroke.Width = 2

EnableDrag(OpenButton, OpenButton)

-- إنشاء الأزرار المرفوعة فوق طبقة الخلفية (ZIndex = 4) لمنع الاحتجاب خلف المربع الأسود
local function AddMobileButton(Text, Key, Index)
    local YPosition = 50 + ((Index - 1) * 41) 
    
    local Holder = Instance.new("Frame")
    Holder.Size = UDim2.new(1, -16, 0, 35)
    Holder.Position = UDim2.new(0, 8, 0, YPosition)
    Holder.BackgroundColor3 = Color3.fromRGB(20, 20, 20) -- خلفية الأزرار صريحة ومغايرة
    Holder.BorderSizePixel = 0
    Holder.ZIndex = 3
    Holder.Parent = Main
    Instance.new("UICorner", Holder).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.65, 0, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Text
    Label.TextColor3 = Color3.fromRGB(255, 255, 255) -- نص أبيض ناصع
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 4
    Label.Parent = Holder

    local Toggle = Instance.new("TextButton")
    Toggle.Size = UDim2.new(0, 42, 0, 20)
    Toggle.Position = UDim2.new(1, -52, 0.5, -10)
    Toggle.BackgroundColor3 = ESPFramework.Settings[Key] and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(80, 80, 80)
    Toggle.Text = ""
    Toggle.ZIndex = 4
    Toggle.Parent = Holder
    Instance.new("UICorner", Toggle).CornerRadius = UDim.new(1, 0)

    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 14, 0, 14)
    Circle.Position = ESPFramework.Settings[Key] and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Circle.ZIndex = 5
    Circle.Parent = Toggle
    Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)

    Toggle.MouseButton1Click:Connect(function()
        ESPFramework.Settings[Key] = not ESPFramework.Settings[Key]
        local active = ESPFramework.Settings[Key]
        
        Toggle.BackgroundColor3 = active and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(80, 80, 80)
        Circle.Position = active and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    end)
end

-- بناء الأزرار وضمان ظهورها فوق أي سواد
AddMobileButton("Master ESP Engine", "Enabled", 1)
AddMobileButton("Player Boxes & Chams", "PlayerESP", 2)
AddMobileButton("Show Game Roles (Team)", "TeamESP", 3)
AddMobileButton("Show Names", "NameESP", 4)
AddMobileButton("Distance Tracker", "DistanceESP", 5)
AddMobileButton("Coin Radar", "CoinESP", 6)
AddMobileButton("🎯 Mobile Aim Lock", "AimLockEnabled", 7)
AddMobileButton("🔒 Aim Wall Check", "AimWallCheck", 8)

-- أنيميشن وضوابط الفتح والإغلاق الصريحة لـلمس
Close.MouseButton1Click:Connect(function()
    Main.Visible = false
    OpenButton.Visible = true
end)

OpenButton.MouseButton1Click:Connect(function()
    Main.Visible = true
    OpenButton.Visible = false
end)

task.spawn(function()
    ESPFramework:Start()
end)

print("🎯 FlyHubV4 UI Layer-Flattening Applied! Buttons are fully visible now.")
