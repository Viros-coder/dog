--[[
    💾 FlyHubV4 - MM2 Mobile Ultra Framework
    💻 Developer: Viros-coder
    📦 Repository: dog
    📜 Script: mscv.lua
    📱 Fix: Absolute Floating Elements (No Container Overlay Bug)
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
        GunESP = true,
        MaxDistance = 1500,
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
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera

-- تنظيف شامل وصارم لأي محاولة واجهة قديمة
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

--// 🖥️ بناء الواجهة الحرّة المستقلة (ABSOLUTE FLOATING SYSTEM - NO CONTAINERS)
local Gui = Instance.new("ScreenGui")
Gui.Name = "MM2_ESP_GUI"
Gui.ResetOnSpawn = false
Gui.Parent = PlayerGui

-- جدول داخلي لمراقبة جميع العناصر معاً لتسهيل الإخفاء والإظهار والسحب الجماعي
local UI_Elements = {}
local BaseX, BaseY = 160, 100 -- نقطة الارتكاز المركزية على شاشة الهاتف للأزرار

-- شريط العنوان العلوي (مستقل)
local Header = Instance.new("Frame")
Header.Size = UDim2.new(0, 450, 0, 30)
Header.Position = UDim2.new(0, BaseX, 0, BaseY)
Header.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Header.Parent = Gui
local HeaderStroke = Instance.new("UIStroke", Header)
HeaderStroke.Color = Color3.fromRGB(255, 50, 50)
table.insert(UI_Elements, Header)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.8, 0, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "FlyHubV4 - Grid Mobile Fixed"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local HideBtn = Instance.new("TextButton")
HideBtn.Size = UDim2.new(0, 50, 0, 22)
HideBtn.Position = UDim2.new(1, -55, 0.5, -11)
HideBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
HideBtn.Text = "Hide"
HideBtn.TextColor3 = Color3.new(1, 1, 1)
HideBtn.Font = Enum.Font.GothamBold
HideBtn.TextSize = 11
HideBtn.Parent = Header
Instance.new("UICorner", HideBtn).CornerRadius = UDim.new(0, 4)

-- أيقونة الاستعادة الطافية 👺 (مستقلة بالكامل على اليمين)
local ToggleOn = Instance.new("TextButton")
ToggleOn.Size = UDim2.new(0, 55, 0, 55)
ToggleOn.Position = UDim2.new(1, -75, 0.4, 0) -- يمين الشاشة بحجم متوسط ممتاز ومثالي للمس
ToggleOn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleOn.Text = "👺"
ToggleOn.TextSize = 26
ToggleOn.Visible = false
ToggleOn.Parent = Gui
Instance.new("UICorner", ToggleOn).CornerRadius = UDim.new(1, 0)
local ToggleOnStroke = Instance.new("UIStroke", ToggleOn)
ToggleOnStroke.Color = Color3.fromRGB(255, 50, 50)
ToggleOnStroke.Width = 2

-- دالة السحب الذكي المباشر التي تحرك كافة الأزرار مع الشريط يدوياً بدون حاوية
local function EnableGroupDrag(Handle)
    local dragging, dragInput, dragStart, startPositions = false, nil, nil, {}
    
    Handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            table.clear(startPositions)
            for _, element in ipairs(UI_Elements) do
                startPositions[element] = element.Position
            end
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    
    Handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            for element, startPos in pairs(startPositions) do
                element.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)
end

EnableGroupDrag(Header)
EnableGroupDrag(ToggleOn) -- جعل الأيقونة قابلة للسحب لوحدها أيضاً بحرية

HideBtn.MouseButton1Click:Connect(function()
    for _, el in ipairs(UI_Elements) do el.Visible = false end
    ToggleOn.Visible = true
end)

ToggleOn.MouseButton1Click:Connect(function()
    for _, el in ipairs(UI_Elements) do el.Visible = true end
    ToggleOn.Visible = false
end)

-- دالة بناء خلايا مستقلة تماماً (Absolute Grid Positioning) لتفادي المربع الأسود المزعج
local function CreateAbsoluteButton(LabelText, SettingKey, ColumnX, RowY)
    local ColWidth = 145  -- عرض ثابت ومحكم لكل زر
    local RowHeight = 36 -- ارتفاع ثابت ومريح للضغط
    
    local OffsetX = (ColumnX - 1) * (ColWidth + 7)
    local OffsetY = 35 + ((RowY - 1) * (RowHeight + 5))
    
    local BtnFrame = Instance.new("Frame")
    BtnFrame.Size = UDim2.new(0, ColWidth, 0, RowHeight)
    BtnFrame.Position = UDim2.new(0, BaseX + OffsetX, 0, BaseY + OffsetY)
    BtnFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    BtnFrame.Parent = Gui
    Instance.new("UICorner", BtnFrame).CornerRadius = UDim.new(0, 5)
    
    local Stroke = Instance.new("UIStroke", BtnFrame)
    Stroke.Color = ESPFramework.Settings[SettingKey] and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(75, 75, 75)
    Stroke.Width = 1.5

    local Clicker = Instance.new("TextButton")
    Clicker.Size = UDim2.new(1, 0, 1, 0)
    Clicker.BackgroundTransparency = 1
    Clicker.Text = "  " .. LabelText
    Clicker.TextColor3 = ESPFramework.Settings[SettingKey] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(170, 170, 170)
    Clicker.Font = Enum.Font.GothamBold
    Clicker.TextSize = 11
    Clicker.TextXAlignment = Enum.TextXAlignment.Left
    Clicker.Parent = BtnFrame

    Clicker.MouseButton1Click:Connect(function()
        ESPFramework.Settings[SettingKey] = not ESPFramework.Settings[SettingKey]
        local active = ESPFramework.Settings[SettingKey]
        Stroke.Color = active and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(75, 75, 75)
        Clicker.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(170, 170, 170)
    end)
    
    table.insert(UI_Elements, BtnFrame)
end

-- 📌 رص الأعمدة الحرة الثلاثة (أزرار مستقلة بدون مربع أسود خلفي)
-- العمود 1: الـ ESP
CreateAbsoluteButton("ESP ⭕️ (Master)", "Enabled", 1, 1)
CreateAbsoluteButton("Player Boxes", "PlayerESP", 1, 2)
CreateAbsoluteButton("Distance Tracker", "DistanceESP", 1, 3)
CreateAbsoluteButton("Show Team/Roles", "TeamESP", 1, 4)
CreateAbsoluteButton("Show Names", "NameESP", 1, 5)

-- العمود 2: الرادارات
CreateAbsoluteButton("Coin Radar", "CoinESP", 2, 1)
CreateAbsoluteButton("Gun Drop Finder", "GunESP", 2, 2)

-- العمود 3: الـ Aim Lock والـ FOV القابل للكتابة يدوياً
CreateAbsoluteButton("Aim Lock Engine", "AimLockEnabled", 3, 1)
CreateAbsoluteButton("Aim Wall Check", "AimWallCheck", 3, 2)

-- ✍️ بناء صندوق النص الحُر المستقل لإدخال قيمة الـ FOV يدوياً
local FovWidth = 145
local FovOffsetX = (3 - 1) * (FovWidth + 7)
local FovOffsetY = 35 + ((3 - 1) * (36 + 5))

local FovContainer = Instance.new("Frame")
FovContainer.Size = UDim2.new(0, FovWidth, 0, 36)
FovContainer.Position = UDim2.new(0, BaseX + FovOffsetX, 0, BaseY + FovOffsetY)
FovContainer.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
FovContainer.Parent = Gui
Instance.new("UICorner", FovContainer).CornerRadius = UDim.new(0, 5)

local FovStroke = Instance.new("UIStroke", FovContainer)
FovStroke.Color = Color3.fromRGB(255, 50, 50)
FovStroke.Width = 1.5

local FovLabel = Instance.new("TextLabel")
FovLabel.Size = UDim2.new(0.5, 0, 1, 0)
FovLabel.Position = UDim2.new(0, 8, 0, 0)
FovLabel.BackgroundTransparency = 1
FovLabel.Text = "Aim FOV:"
FovLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FovLabel.Font = Enum.Font.GothamBold
FovLabel.TextSize = 11
FovLabel.TextXAlignment = Enum.TextXAlignment.Left
FovLabel.Parent = FovContainer

local FovInput = Instance.new("TextBox")
FovInput.Size = UDim2.new(0.4, 0, 0.7, 0)
FovInput.Position = UDim2.new(0.55, 0, 0.15, 0)
FovInput.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
FovInput.Text = tostring(ESPFramework.Settings.AimFOV)
FovInput.TextColor3 = Color3.fromRGB(255, 255, 255)
FovInput.Font = Enum.Font.Code
FovInput.TextSize = 12
FovInput.ClearTextOnFocus = true
FovInput.Parent = FovContainer
Instance.new("UICorner", FovInput).CornerRadius = UDim.new(0, 4)

FovInput.FocusLost:Connect(function()
    local num = tonumber(FovInput.Text)
    if num then ESPFramework.Settings.AimFOV = num else FovInput.Text = tostring(ESPFramework.Settings.AimFOV) end
end)

table.insert(UI_Elements, FovContainer)

-- تشغيل المحرك الرئيسي في الخلفية بثبات كامل
task.spawn(function()
    ESPFramework:Start()
end)

print("🎯 FlyHubV4 Fixed Ultimate Layout: Floating elements fully initialized without overlay blocks!")
