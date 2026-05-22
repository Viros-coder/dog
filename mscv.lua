--[[
    💾 FlyHubV4 - MM2 Mobile Ultra Framework
    💻 Developer: Viros-coder
    📦 Repository: dog
    📜 Script: mscv.lua
    📱 Layout: 3-Column Zero-Background Transparent Grid System
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
        GunESP = true, -- ميزة مخصصة للـ Gun الملقاة
        MaxDistance = 1500,
        ThrottlingRate = 2,
        
        AimLockEnabled = false,
        AimWallCheck = true,
        AimSmoothness = 0.15, 
        AimFOV = 180, -- القيمة الافتراضية للـ FOV
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
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera

-- تنظيف تام للواجهات القديمة
pcall(function()
    if PlayerGui:FindFirstChild("MM2_ESP_GUI") then PlayerGui.MM2_ESP_GUI:Destroy() end
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
    
    if self.Settings.GunESP then
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

--// 🖥️ نظام الواجهة الشفافة الثلاثي الذكي للجوال (ANTI-BLACK BOX OVERLAY)
local Gui = Instance.new("ScreenGui")
Gui.Name = "MM2_ESP_GUI"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

-- الحاوية الرئيسية الشفافة بالكامل (حجم عريض ومثالي للجوال)
local MainContainer = Instance.new("Frame")
MainContainer.Size = UDim2.new(0, 480, 0, 240)
MainContainer.Position = UDim2.new(0.5, -240, 0.4, -120)
MainContainer.BackgroundTransparency = 1 -- شفافة تماماً لمنع حدوث المربع الأسود!
MainContainer.Visible = true
MainContainer.Parent = Gui

-- دالة تحريك مخصصة للمس
local function MakeDraggable(Frame, Handle)
    local dragging, dragInput, dragStart, startPos
    Handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Frame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    Handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- شريط علوي صغير مخصص للجر والإغلاق
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 30)
Header.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Header.ZIndex = 2
Header.Parent = MainContainer
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 5)
local HeaderStroke = Instance.new("UIStroke", Header)
HeaderStroke.Color = Color3.fromRGB(255, 50, 50)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.8, 0, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "FlyHubV4 - Grid Overlay"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 3
Title.Parent = Header

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.new(0, 40, 0, 22)
Minimize.Position = UDim2.new(1, -45, 0.5, -11)
Minimize.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
Minimize.Text = "Hide"
Minimize.TextColor3 = Color3.new(1,1,1)
Minimize.Font = Enum.Font.GothamBold
Minimize.TextSize = 11
Minimize.ZIndex = 4
Minimize.Parent = Header
Instance.new("UICorner", Minimize).CornerRadius = UDim.new(0, 4)

MakeDraggable(MainContainer, Header)

-- أيقونة الاستعادة الطافية
local ToggleOn = Instance.new("TextButton")
ToggleOn.Size = UDim2.new(0, 45, 0, 45)
ToggleOn.Position = UDim2.new(1, -60, 0.2, 0)
ToggleOn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
ToggleOn.Text = "👹"
ToggleOn.TextSize = 22
ToggleOn.Visible = false
ToggleOn.ZIndex = 10
ToggleOn.Parent = Gui
Instance.new("UICorner", ToggleOn).CornerRadius = UDim.new(1, 0)
local ToggleStroke = Instance.new("UIStroke", ToggleOn)
ToggleStroke.Color = Color3.fromRGB(255, 50, 50)
MakeDraggable(ToggleOn, ToggleOn)

Minimize.MouseButton1Click:Connect(function() MainContainer.Visible = false; ToggleOn.Visible = true end)
ToggleOn.MouseButton1Click:Connect(function() MainContainer.Visible = true; ToggleOn.Visible = false end)

-- دالة لإنشاء خلايا الأزرار المنفصلة (تطفو بدون خلفية تجمعها)
local function CreateGridButton(LabelText, SettingKey, ColumnX, RowY, TotalCols)
    local Width = (480 / TotalCols) - 10
    local BtnFrame = Instance.new("Frame")
    BtnFrame.Size = UDim2.new(0, Width, 0, 32)
    BtnFrame.Position = UDim2.new(0, (ColumnX - 1) * (Width + 10), 0, 45 + (RowY - 1) * 38)
    BtnFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    BtnFrame.ZIndex = 3
    BtnFrame.Parent = MainContainer
    Instance.new("UICorner", BtnFrame).CornerRadius = UDim.new(0, 5)
    
    local Stroke = Instance.new("UIStroke", BtnFrame)
    Stroke.Color = ESPFramework.Settings[SettingKey] and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(70, 70, 70)
    Stroke.Width = 1.5

    local Clicker = Instance.new("TextButton")
    Clicker.Size = UDim2.new(1, 0, 1, 0)
    Clicker.BackgroundTransparency = 1
    Clicker.Text = "  " .. LabelText
    Clicker.TextColor3 = ESPFramework.Settings[SettingKey] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
    Clicker.Font = Enum.Font.GothamBold
    Clicker.TextSize = 11
    Clicker.TextXAlignment = Enum.TextXAlignment.Left
    Clicker.ZIndex = 4
    Clicker.Parent = BtnFrame

    Clicker.MouseButton1Click:Connect(function()
        ESPFramework.Settings[SettingKey] = not ESPFramework.Settings[SettingKey]
        local isEnabled = ESPFramework.Settings[SettingKey]
        Stroke.Color = isEnabled and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(70, 70, 70)
        Clicker.TextColor3 = isEnabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
    end)
end

-- 📌 العمود الأول: نظام الـ ESP وعناصره الرئيسية
CreateGridButton("ESP ⭕️ (Master)", "Enabled", 1, 1, 3)
CreateGridButton("Player Boxes", "PlayerESP", 1, 2, 3)
CreateGridButton("Distance Tracker", "DistanceESP", 1, 3, 3)
CreateGridButton("Show Team/Roles", "TeamESP", 1, 4, 3)
CreateGridButton("Show Names", "NameESP", 1, 5, 3)

-- 📌 العمود الثاني: الرادارات والعناصر المحيطية
CreateGridButton("Coin Radar", "CoinESP", 2, 1, 3)
CreateGridButton("Gun Drop Finder", "GunESP", 2, 2, 3)

-- 📌 العمود الثالث: محرك الـ Aim والتخصيص المباشر
CreateGridButton("Aim Lock Engine", "AimLockEnabled", 3, 1, 3)
CreateGridButton("Aim Wall Check", "AimWallCheck", 3, 2, 3)

-- ✍️ منطقة إدخال الـ FOV المخصصة للكتابة يدوياً (مدرجة بالعمود الثالث)
local FovContainer = Instance.new("Frame")
FovContainer.Size = UDim2.new(0, (480 / 3) - 10, 0, 32)
FovContainer.Position = UDim2.new(0, 2 * ((480 / 3) + 5), 0, 45 + (3 - 1) * 38)
FovContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
FovContainer.ZIndex = 3
FovContainer.Parent = MainContainer
Instance.new("UICorner", FovContainer).CornerRadius = UDim.new(0, 5)

local FovStroke = Instance.new("UIStroke", FovContainer)
FovStroke.Color = Color3.fromRGB(255, 50, 50)
FovStroke.Width = 1.5

local FovLabel = Instance.new("TextLabel")
FovLabel.Size = UDim2.new(0.5, 0, 1, 0)
FovLabel.BackgroundTransparency = 1
FovLabel.Text = "  Aim FOV:"
FovLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FovLabel.Font = Enum.Font.GothamBold
FovLabel.TextSize = 11
FovLabel.TextXAlignment = Enum.TextXAlignment.Left
FovLabel.ZIndex = 4
FovLabel.Parent = FovContainer

-- صندوق النص البرمجي الحقيقي القابل للكتابة واللمس على الجوال
local FovInput = Instance.new("TextBox")
FovInput.Size = UDim2.new(0.45, 0, 0.7, 0)
FovInput.Position = UDim2.new(0.5, 0, 0.15, 0)
FovInput.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
FovInput.Text = tostring(ESPFramework.Settings.AimFOV)
FovInput.TextColor3 = Color3.fromRGB(255, 255, 255)
FovInput.Font = Enum.Font.Code
FovInput.TextSize = 12
FovInput.ZIndex = 5
FovInput.ClearTextOnFocus = true
FovInput.Parent = FovContainer
Instance.new("UICorner", FovInput).CornerRadius = UDim.new(0, 4)

-- معالجة المدخلات يدوياً فور تغيير النص
FovInput.FocusLost:Connect(function(enterPressed)
    local num = tonumber(FovInput.Text)
    if num then
        ESPFramework.Settings.AimFOV = num
    else
        FovInput.Text = tostring(ESPFramework.Settings.AimFOV) -- استعادة القيمة السابقة إذا تم إدخال رمز خاطئ
    end
end)

-- بدء عمل المحرك الخلفي بنجاح
task.spawn(function()
    ESPFramework:Start()
end)

print("🎯 FlyHubV4 Three-Column Split Overlay Loaded Successfully!")
