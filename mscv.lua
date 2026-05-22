--[[
    💾 FlyHubV4 - MM2 ESP Framework & GUI (GitHub Universal Edition)
    🚀 Optimized for Mobile (Delta/Touch) & PC Performance
    ✨ Integration: Professional UI + Predictive Role Scanner + World Items ESP
--]]

local ESPFramework = {
    Connections = {},
    Cache = {},
    Roles = {},
    Settings = {
        Enabled = false,       -- مرتبطة بزر "ESP"
        PlayerESP = false,     -- مرتبطة بزر "ESP Player" (الـ Boxes والـ Chams)
        TeamESP = false,       -- مرتبطة بزر "ESP Team" (إظهار دور اللاعب مثل Murder/Sheriff)
        NameESP = false,       -- مرتبطة بزر "ESP Name"
        DistanceESP = false,   -- مرتبطة بزر "ESP Distance"
        CoinESP = false,       -- مرتبطة بزر "ESP Coin"
        GunDropEnabled = true,  -- كشف السلاح الساقط تلقائياً
        MaxDistance = 600,
        ThrottlingRate = 3
    },
    Colors = {
        Murder = Color3.fromRGB(255, 30, 30),
        Sheriff = Color3.fromRGB(0, 120, 255),
        Innocent = Color3.fromRGB(40, 255, 40),
        GunDrop = Color3.fromRGB(255, 215, 0),
        Coin = Color3.fromRGB(255, 255, 0)
    }
}

-- الخدمات الأساسية
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// CLEANUP SYSTEM (منع التكرار والـ Lag)
pcall(function()
    if PlayerGui:FindFirstChild("MM2_ESP_GUI") then
        PlayerGui.MM2_ESP_GUI:Destroy()
    end
end)

function ESPFramework:Disconnect(name)
    if self.Connections[name] then
        if typeof(self.Connections[name]) == "RBXScriptConnection" then
            self.Connections[name]:Disconnect()
        elseif type(self.Connections[name]) == "table" then
            for _, conn in ipairs(self.Connections[name]) do
                if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
            end
        end
        self.Connections[name] = nil
    end
end

function ESPFramework:RemovePlayerESP(player)
    if self.Cache[player] then
        if self.Cache[player].Billboard then self.Cache[player].Billboard:Destroy() end
        if self.Cache[player].Highlight then self.Cache[player].Highlight:Destroy() end
        self.Cache[player] = nil
    end
end

--// PREDICTIVE ROLE DETECTION
function ESPFramework:CheckPlayerRole(player)
    if player == LocalPlayer then return "Innocent" end
    if self.Roles[player] == "Murder" or self.Roles[player] == "Sheriff" then 
        return self.Roles[player] 
    end

    local character = player.Character
    local backpack = player:FindFirstChild("Backpack")
    local locations = {}
    
    if character then table.insert(locations, character) end
    if backpack then table.insert(locations, backpack) end
    
    for _, loc in ipairs(locations) do
        if loc:FindFirstChild("Knife") or loc:FindFirstChild("Blade") then
            self.Roles[player] = "Murder"
            return "Murder"
        elseif loc:FindFirstChild("Gun") or loc:FindFirstChild("Revolver") then
            self.Roles[player] = "Sheriff"
            return "Sheriff"
        end
    end
    
    return self.Roles[player] or "Innocent"
end

--// ESP ENGINE CREATION
function ESPFramework:CreatePlayerESP(player)
    if player == LocalPlayer then return end
    
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    self:RemovePlayerESP(player)
    
    local cacheData = {}
    
    -- Billboard UI (Box, Name, Distance)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_" .. player.Name
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(4.5, 0, 5.5, 0)
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
    distLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    distLabel.TextStrokeTransparency = 0
    distLabel.TextScaled = true
    distLabel.Font = Enum.Font.Gotham
    distLabel.Parent = billboard
    
    cacheData.Billboard = billboard
    
    -- Highlight Chams
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

--// WORLD ITEMS ESP
function ESPFramework:UpdateWorldESPItems()
    -- Gun Drop Checking
    for _, child in ipairs(Workspace:GetChildren()) do
        if child.Name == "GunDrop" or (child:IsA("Tool") and child.Name:match("Gun")) then
            local hl = child:FindFirstChild("ESP_Highlight")
            if self.Settings.Enabled then
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "ESP_Highlight"
                    hl.FillColor = self.Colors.GunDrop
                    hl.OutlineColor = Color3.new(1, 1, 1)
                    hl.Parent = child
                end
                hl.Enabled = true
            elseif hl then
                hl.Enabled = false
            end
        end
    end

    -- Coins Checking
    local coinContainer = Workspace:FindFirstChild("Normal") and Workspace.Normal:FindFirstChild("CoinContainer")
    if coinContainer then
        for _, coin in ipairs(coinContainer:GetChildren()) do
            if coin:IsA("BasePart") then
                local hl = coin:FindFirstChild("ESP_Highlight")
                if self.Settings.Enabled and self.Settings.CoinESP then
                    if not hl then
                        hl = Instance.new("Highlight")
                        hl.Name = "ESP_Highlight"
                        hl.FillColor = self.Colors.Coin
                        hl.FillTransparency = 0.4
                        hl.OutlineTransparency = 1
                        hl.Parent = coin
                    end
                    hl.Enabled = true
                elseif hl then
                    hl.Enabled = false
                end
            end
        end
    end
end

function ESPFramework:SetupWorldListeners()
    self:Disconnect("WorkspaceItems")
    self.Connections["WorkspaceItems"] = Workspace.ChildAdded:Connect(function()
        self:UpdateWorldESPItems()
    end)

    local coinContainer = Workspace:FindFirstChild("Normal") and Workspace.Normal:FindFirstChild("CoinContainer")
    if coinContainer then
        self:Disconnect("CoinItems")
        self.Connections["CoinItems"] = coinContainer.ChildAdded:Connect(function()
            self:UpdateWorldESPItems()
        end)
    end
end

--// SMART RENDER LOOP
function ESPFramework:InitLoops()
    local frameCounter = 0
    
    self.Connections["MainLoop"] = RunService.RenderStepped:Connect(function()
        -- فحص تحديث عناصر الماب الساقطة والعملات
        frameCounter = (frameCounter + 1) % self.Settings.ThrottlingRate
        local runHeavyChecks = (frameCounter == 0)
        
        if runHeavyChecks then
            self:UpdateWorldESPItems()
        end

        local localChar = LocalPlayer.Character
        local localHrp = localChar and localChar:FindFirstChild("HumanoidRootPart")
        
        for player, cache in pairs(self.Cache) do
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if char and hrp and localHrp and self.Settings.Enabled then
                local distance = (hrp.Position - localHrp.Position).Magnitude
                
                if distance > self.Settings.MaxDistance then
                    if cache.Billboard then cache.Billboard.Enabled = false end
                    if cache.Highlight then cache.Highlight.Enabled = false end
                else
                    -- التحكم بالرؤية بناء على الأزرار المفعّلة
                    if cache.Highlight then 
                        cache.Highlight.Enabled = self.Settings.PlayerESP 
                    end
                    
                    if cache.Billboard then
                        cache.Billboard.Enabled = (self.Settings.PlayerESP or self.Settings.NameESP or self.Settings.DistanceESP)
                        
                        local outline = cache.Billboard:FindFirstChild("Outline")
                        local nameLabel = cache.Billboard:FindFirstChild("PlayerName")
                        local distLabel = cache.Billboard:FindFirstChild("Distance")
                        
                        if outline then outline.Visible = self.Settings.PlayerESP end
                        if nameLabel then nameLabel.Visible = self.Settings.NameESP end
                        if distLabel then distLabel.Visible = self.Settings.DistanceESP end
                        
                        if distLabel and self.Settings.DistanceESP then 
                            distLabel.Text = math.floor(distance) .. "m" 
                        end
                    end
                    
                    -- تحديث الألوان والأدوار تلقائياً
                    if runHeavyChecks then
                        local role = self:CheckPlayerRole(player)
                        local color = self.Colors[role]
                        
                        if cache.Billboard then
                            local outline = cache.Billboard:FindFirstChild("Outline")
                            local nameLabel = cache.Billboard:FindFirstChild("PlayerName")
                            
                            if outline then outline.BorderColor3 = color end
                            if nameLabel then 
                                if self.Settings.TeamESP then
                                    nameLabel.Text = player.Name .. " [" .. role .. "]"
                                else
                                    nameLabel.Text = player.Name
                                end
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
    local function setupPlayer(player)
        if player == LocalPlayer then return end
        player.CharacterAdded:Connect(function()
            task.wait(0.3)
            self:CreatePlayerESP(player)
        end)
        player.CharacterRemoving:Connect(function()
            self:RemovePlayerESP(player)
        end)
        if player.Character then self:CreatePlayerESP(player) end
    end
    
    Players.PlayerAdded:Connect(setupPlayer)
    Players.PlayerRemoving:Connect(function(player) self:RemovePlayerESP(player) end)
    
    for _, player in ipairs(Players:GetPlayers()) do setupPlayer(player) end
    
    self:SetupWorldListeners()
    self:InitLoops()
end

--// GUI ENGINE CREATION
local Gui = Instance.new("ScreenGui")
Gui.Name = "MM2_ESP_GUI"
Gui.ResetOnSpawn = false
Gui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0,320,0,340)
Main.Position = UDim2.new(0.5,-160,0.5,-170)
Main.BackgroundColor3 = Color3.fromRGB(20,20,20)
Main.BorderSizePixel = 0
Main.Parent = Gui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0,14)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,50)
Title.BackgroundColor3 = Color3.fromRGB(28,28,28)
Title.BorderSizePixel = 0
Title.Text = "MM2 ESP PANEL"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.Parent = Main

Instance.new("UICorner", Title).CornerRadius = UDim.new(0,14)

local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0,30,0,30)
Close.Position = UDim2.new(1,-40,0,10)
Close.BackgroundColor3 = Color3.fromRGB(255,60,60)
Close.Text = "X"
Close.TextColor3 = Color3.new(1,1,1)
Close.Font = Enum.Font.GothamBold
Close.TextSize = 16
Close.Parent = Title

Instance.new("UICorner", Close).CornerRadius = UDim.new(1,0)

local OpenButton = Instance.new("TextButton")
OpenButton.Size = UDim2.new(0,55,0,55)
OpenButton.Position = UDim2.new(0,20,0.5,-27)
OpenButton.BackgroundColor3 = Color3.fromRGB(0,170,255)
OpenButton.Text = "OPEN"
OpenButton.TextColor3 = Color3.new(1,1,1)
OpenButton.Font = Enum.Font.GothamBold
OpenButton.TextSize = 14
OpenButton.Visible = false
OpenButton.Parent = Gui

Instance.new("UICorner", OpenButton).CornerRadius = UDim.new(1,0)

local Container = Instance.new("Frame")
Container.Size = UDim2.new(1,-20,1,-70)
Container.Position = UDim2.new(0,10,0,60)
Container.BackgroundTransparency = 1
Container.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0,10)
Layout.Parent = Container

local function CreateToggle(Name, Key)
    local Holder = Instance.new("Frame")
    Holder.Size = UDim2.new(1,0,0,42)
    Holder.BackgroundColor3 = Color3.fromRGB(32,32,32)
    Holder.BorderSizePixel = 0
    Holder.Parent = Container

    Instance.new("UICorner", Holder).CornerRadius = UDim.new(0,10)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.7,0,1,0)
    Label.Position = UDim2.new(0,15,0,0)
    Label.BackgroundTransparency = 1
    Label.Text = Name
    Label.TextColor3 = Color3.new(1,1,1)
    Label.Font = Enum.Font.GothamSemibold
    Label.TextSize = 15
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Holder

    local Toggle = Instance.new("TextButton")
    Toggle.Size = UDim2.new(0,55,0,24)
    Toggle.Position = UDim2.new(1,-70,0.5,-12)
    Toggle.BackgroundColor3 = Color3.fromRGB(50,50,50)
    Toggle.Text = ""
    Toggle.Parent = Holder

    Instance.new("UICorner", Toggle).CornerRadius = UDim.new(1,0)

    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0,20,0,20)
    Circle.Position = UDim2.new(0,2,0.5,-10)
    Circle.BackgroundColor3 = Color3.new(1,1,1)
    Circle.Parent = Toggle

    Instance.new("UICorner", Circle).CornerRadius = UDim.new(1,0)

    Toggle.MouseButton1Click:Connect(function()
        ESPFramework.Settings[Key] = not ESPFramework.Settings[Key]
        local isEnabled = ESPFramework.Settings[Key]

        TweenService:Create(Toggle, TweenInfo.new(0.2), {
            BackgroundColor3 = isEnabled and Color3.fromRGB(0,170,255) or Color3.fromRGB(50,50,50)
        }):Play()

        TweenService:Create(Circle, TweenInfo.new(0.2), {
            Position = isEnabled and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10)
        }):Play()
    end)
end

-- بناء الأزرار وربطها بالمحرك
CreateToggle("ESP Master", "Enabled")
CreateToggle("ESP Player (Chams/Box)", "PlayerESP")
CreateToggle("ESP Team (Roles)", "TeamESP")
CreateToggle("ESP Name", "NameESP")
CreateToggle("ESP Distance", "DistanceESP")
CreateToggle("ESP Coin", "CoinESP")

-- DRAG SYSTEM (Mobile & PC Friendly)
local dragging, dragInput, dragStart, startPos
Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
Title.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- CLOSE & OPEN TWEENS
Close.MouseButton1Click:Connect(function()
    TweenService:Create(Main, TweenInfo.new(0.25), {Size = UDim2.new(0,0,0,0)}):Play()
    task.wait(0.25)
    Main.Visible = false
    OpenButton.Visible = true
end)

OpenButton.MouseButton1Click:Connect(function()
    Main.Visible = true
    OpenButton.Visible = false
    Main.Size = UDim2.new(0,0,0,0)
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.new(0,320,0,340)}):Play()
end)

-- تشغيل المحرك
task.spawn(function()
    ESPFramework:Start()
end)

print("✅ FlyHubV4 - GUI & ESP Engine Loaded!")
