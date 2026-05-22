--[[
    💾 FlyHubV4 - MM2 Mobile Ultra Framework
    💻 Developer: Viros-coder
    📦 Repository: dog
    📜 Script: mscv.lua
    📱 Fix: Roblox Native UIListLayout Auto-Railing System (Anti-Stack Bug)
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

-- إبادة أي بقايا للواجهات المسببة للأخطاء
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

--// 🖥️ بناء القائمة المقاومة للانضغاط (NATIVE AUTO-ALIGN SYSTEM)
local Gui = Instance.new("ScreenGui")
Gui.Name = "MM2_ESP_GUI"
Gui.ResetOnSpawn = false
Gui.Parent = PlayerGui

-- اللوحة الأساسية (الخلفية بلون رمادي واضح وصريح لمنع السواد المتفحم)
local BaseFrame = Instance.new("Frame")
BaseFrame.Size = UDim2.new(0, 180, 0, 360) -- لوحة طولية ذكية لا تأخذ مساحة كبيرة
BaseFrame.Position = UDim2.new(0.05, 0, 0.25, 0) -- متمركزة على اليسار بشكل أنيق جداً وجاهزة للضغط
BaseFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
BaseFrame.BorderSizePixel = 0
BaseFrame.Active = true
BaseFrame.Draggable = true -- تفعيل السحب الأصلي المدعوم من النظام مباشرة
BaseFrame.Parent = Gui

local BaseStroke = Instance.new("UIStroke", BaseFrame)
BaseStroke.Color = Color3.fromRGB(255, 50, 50)
BaseStroke.Width = 2
Instance.new("UICorner", BaseFrame).CornerRadius = UDim.new(0, 8)

-- شريط العنوان العلوي
local TopHeader = Instance.new("Frame")
TopHeader.Size = UDim2.new(1, 0, 0, 32)
TopHeader.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TopHeader.BorderSizePixel = 0
TopHeader.Parent = BaseFrame
Instance.new("UICorner", TopHeader).CornerRadius = UDim.new(0, 8)

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(0.7, 0, 1, 0)
TitleText.Position = UDim2.new(0, 8, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "FlyHubV4 Menu"
TitleText.TextColor3 = Color3.new(1, 1, 1)
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 12
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TopHeader

local HideButton = Instance.new("TextButton")
HideButton.Size = UDim2.new(0, 42, 0, 20)
HideButton.Position = UDim2.new(1, -48, 0.5, -10)
HideButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
HideButton.Text = "Hide"
HideButton.TextColor3 = Color3.new(1, 1, 1)
HideButton.Font = Enum.Font.GothamBold
HideButton.TextSize = 11
HideButton.Parent = TopHeader
Instance.new("UICorner", HideButton).CornerRadius = UDim.new(0, 4)

-- 🤖 الأيقونة الطافية للاستعادة 👺
local RecoverButton = Instance.new("TextButton")
RecoverButton.Size = UDim2.new(0, 50, 0, 50)
RecoverButton.Position = UDim2.new(1, -65, 0.5, -25) -- يمين الشاشة تلقائياً بحجم ممتاز للمس
RecoverButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
RecoverButton.Text = "👺"
RecoverButton.TextSize = 24
RecoverButton.Visible = false
RecoverButton.Draggable = true
RecoverButton.Parent = Gui
Instance.new("UICorner", RecoverButton).CornerRadius = UDim.new(1, 0)
local RecStroke = Instance.new("UIStroke", RecoverButton)
RecStroke.Color = Color3.fromRGB(255, 50, 50)
RecStroke.Width = 2

HideButton.MouseButton1Click:Connect(function() BaseFrame.Visible = false; RecoverButton.Visible = true end)
RecoverButton.MouseButton1Click:Connect(function() BaseFrame.Visible = true; RecoverButton.Visible = false end)

-- 📦 حاوية الأزرار السفلية
local ListContainer = Instance.new("Frame")
ListContainer.Size = UDim2.new(1, -12, 1, -42)
ListContainer.Position = UDim2.new(0, 6, 0, 38)
ListContainer.BackgroundTransparency = 1
ListContainer.Parent = BaseFrame

-- 🔥 المنقذ البرمجي: الترتيب التلقائي الإجباري الذي يمنع التكديس ويجبر الأزرار على الظهور
local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 5)
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Parent = ListContainer

-- دالة بناء الأزرار وضخها في القائمة الحديدية
local function CreateScrollingButton(LabelText, SettingKey)
    local ButtonFrame = Instance.new("Frame")
    ButtonFrame.Size = UDim2.new(1, 0, 0, 30) -- حجم مخصص ثابت لكل زر يمنع الانكماش
    ButtonFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    ButtonFrame.Parent = ListContainer
    Instance.new("UICorner", ButtonFrame).CornerRadius = UDim.new(0, 4)
    
    local ButtonStroke = Instance.new("UIStroke", ButtonFrame)
    ButtonStroke.Color = ESPFramework.Settings[SettingKey] and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(65, 65, 65)

    local Clicker = Instance.new("TextButton")
    Clicker.Size = UDim2.new(1, 0, 1, 0)
    Clicker.BackgroundTransparency = 1
    Clicker.Text = "  " .. LabelText
    Clicker.TextColor3 = ESPFramework.Settings[SettingKey] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 160, 160)
    Clicker.Font = Enum.Font.GothamBold
    Clicker.TextSize = 10
    Clicker.TextXAlignment = Enum.TextXAlignment.Left
    Clicker.Parent = ButtonFrame

    Clicker.MouseButton1Click:Connect(function()
        ESPFramework.Settings[SettingKey] = not ESPFramework.Settings[SettingKey]
        local state = ESPFramework.Settings[SettingKey]
        ButtonStroke.Color = state and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(65, 65, 65)
        Clicker.TextColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 160, 160)
    end)
end

-- ضخ الأزرار في محرك الرص التلقائي بنجاح
CreateScrollingButton("ESP Master Engine", "Enabled")
CreateScrollingButton("Player Boxes", "PlayerESP")
CreateScrollingButton("Distance Tracker", "DistanceESP")
CreateScrollingButton("Show Team Roles", "TeamESP")
CreateScrollingButton("Show Player Names", "NameESP")
CreateScrollingButton("Coin Radar Finder", "CoinESP")
CreateScrollingButton("Gun Drop Tracker", "GunESP")
CreateScrollingButton("Aim Lock Engine", "AimLockEnabled")
CreateScrollingButton("Aim Wall Check", "AimWallCheck")

-- ✍️ خانة مدخل الـ FOV المدمجة ذاتياً تلقائياً تحت الأزرار
local FovBoxFrame = Instance.new("Frame")
FovBoxFrame.Size = UDim2.new(1, 0, 0, 30)
FovBoxFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
FovBoxFrame.Parent = ListContainer
Instance.new("UICorner", FovBoxFrame).CornerRadius = UDim.new(0, 4)
local FovBoxStroke = Instance.new("UIStroke", FovBoxFrame)
FovBoxStroke.Color = Color3.fromRGB(255, 50, 50)

local FovLabelText = Instance.new("TextLabel")
FovLabelText.Size = UDim2.new(0.5, 0, 1, 0)
FovLabelText.Position = UDim2.new(0, 8, 0, 0)
FovLabelText.BackgroundTransparency = 1
FovLabelText.Text = "Aim FOV:"
FovLabelText.TextColor3 = Color3.fromRGB(255, 255, 255)
FovLabelText.Font = Enum.Font.GothamBold
FovLabelText.TextSize = 10
FovLabelText.TextXAlignment = Enum.TextXAlignment.Left
FovLabelText.Parent = FovBoxFrame

local FovTextInput = Instance.new("TextBox")
FovTextInput.Size = UDim2.new(0.4, 0, 0.7, 0)
FovTextInput.Position = UDim2.new(0.55, 0, 0.15, 0)
FovTextInput.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
FovTextInput.Text = tostring(ESPFramework.Settings.AimFOV)
FovTextInput.TextColor3 = Color3.fromRGB(255, 255, 255)
FovTextInput.Font = Enum.Font.Code
FovTextInput.TextSize = 11
FovTextInput.ClearTextOnFocus = true
FovTextInput.Parent = FovBoxFrame
Instance.new("UICorner", FovTextInput).CornerRadius = UDim.new(0, 3)

FovTextInput.FocusLost:Connect(function()
    local num = tonumber(FovTextInput.Text)
    if num then ESPFramework.Settings.AimFOV = num else FovTextInput.Text = tostring(ESPFramework.Settings.AimFOV) end
end)

-- تفعيل المنظومة الخلفية
task.spawn(function()
    ESPFramework:Start()
end)

print("🚀 FlyHubV4 Safe Rail-Layout completely setup! Stack bug fully averted.")
