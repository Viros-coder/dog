--[[
    💾 FlyHubV4 - MM2 Ultimate Combat Framework (ESP & Mobile Aim Lock)
    💻 Developer: Viros-coder
    📦 Repository: dog
    📜 Script: mscv.lua
    🚀 Ultimate Mobile (Delta/Touch) & PC Optimization
--]]

local ESPFramework = {
    Connections = {},
    Cache = {},
    Roles = {},
    Settings = {
        -- إعدادات الـ ESP
        Enabled = true,       
        PlayerESP = true,     
        TeamESP = true,       
        NameESP = true,       
        DistanceESP = true,   
        CoinESP = true,       
        MaxDistance = 1000,
        ThrottlingRate = 2,
        
        -- إعدادات الـ Aim Lock الجديدة (تدعم الجوال والـ PC)
        AimLockEnabled = false,
        AimWallCheck = true,
        AimSmoothness = 0.15, -- من 0 إلى 1 (كل ما قل كان التصويب أسرع وأقوى)
        AimFOV = 180,
        AimPart = "Torso"     -- التصويب على الجذع بناءً على طلبك
    },
    Colors = {
        Murder = Color3.fromRGB(255, 33, 33),
        Sheriff = Color3.fromRGB(33, 140, 255),
        Innocent = Color3.fromRGB(50, 255, 50),
        GunDrop = Color3.fromRGB(255, 215, 0),
        Coin = Color3.fromRGB(255, 235, 50)
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
local Camera = Workspace.CurrentCamera

-- تنظيف النسخ السابقة لتفادي تداخل الكود
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

--// نظام تتبع الأدوار وفحص انتهاء الجولة
function ESPFramework:CheckPlayerRole(player)
    if player == LocalPlayer then return "Innocent" end
    
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then 
        self.Roles[player] = "Innocent"
        return "Innocent" 
    end
    
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

function ESPFramework:ResetAllRoles()
    table.clear(self.Roles)
    for player, _ in pairs(self.Cache) do
        self.Roles[player] = "Innocent"
    end
end

--// إنشاء الـ ESP للاعبين
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

--// محرك فحص الماب (الأسلحة والعملات الساقطة)
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

    local coinContainer = Workspace:FindFirstChild("Normal") and Workspace.Normal:FindFirstChild("CoinContainer") 
        or Workspace:FindFirstChild("CoinContainer") 
        or Workspace:FindFirstChild("CoinVisuals")
        
    if coinContainer and self.Settings.CoinESP then
        for _, coin in ipairs(coinContainer:GetChildren()) do
            if (coin:IsA("BasePart") or coin:IsA("Model")) and not coin:FindFirstChild("CoinESP") then
                local targetPart = coin:IsA("Model") and coin:FindFirstChildWhichIsA("BasePart") or coin
                if targetPart then
                    local h = Instance.new("Highlight", coin)
                    h.Name = "CoinESP"
                    h.FillColor = self.Colors.Coin
                    h.FillTransparency = 0.4
                    h.OutlineTransparency = 0.8
                end
            end
        end
    end
end

--// ميزة الـ Wall Check المتقدمة المتوافقة مع الجوال
function ESPFramework:IsPlayerVisible(targetPlayer)
    if not self.Settings.AimWallCheck then return true end
    local myChar = LocalPlayer.Character
    local targetChar = targetPlayer.Character
    if not myChar or not targetChar then return false end
    
    local origin = myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Head")
    local targetPart = targetChar:FindFirstChild(self.Settings.AimPart) or targetChar:FindFirstChild("HumanoidRootPart")
    if not origin or not targetPart then return false end
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {myChar, targetChar, Camera}
    params.IgnoreWater = true
    
    local direction = targetPart.Position - origin.Position
    local result = Workspace:Raycast(origin.Position, direction, params)
    
    if direction.Magnitude < 6 then return true end -- إذا كان قريب جداً اصطدم به تلقائياً
    return result == nil
end

--// البحث عن أفضل هدف للـ Aim Lock متوافق مع شاشات اللمس
function ESPFramework:GetBestAimTarget()
    local myRole = self:CheckPlayerRole(LocalPlayer)
    local bestTarget = nil
    local shortestDistance = self.Settings.AimFOV
    local centerScreen = UIS:GetMouseLocation() -- يعمل على الجوال والـ PC بالتساوي
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local targetPart = char:FindFirstChild(self.Settings.AimPart) or char:FindFirstChild("HumanoidRootPart")
            
            if targetPart then
                local isValidTarget = false
                local targetRole = self:CheckPlayerRole(player)
                
                if myRole == "Sheriff" then
                    isValidTarget = (targetRole == "Murder") -- الشريف يصوب على القاتل فقط
                elseif myRole == "Murder" then
                    isValidTarget = true -- القاتل يصوب على الكل
                end
                
                if isValidTarget then
                    local screenPoint, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - centerScreen).Magnitude
                        if distance < shortestDistance and self:IsPlayerVisible(player) then
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

--// حلقة الرندرة الموحدة (ESP + Mobile Aim Lock)
function ESPFramework:InitLoops()
    local counter = 0
    self.Connections["MainRenderLoop"] = RunService.RenderStepped:Connect(function()
        counter = (counter + 1) % self.Settings.ThrottlingRate
        local heavyCheck = (counter == 0)
        
        if heavyCheck then
            self:UpdateWorldItems()
        end
        
        local lChar = LocalPlayer.Character
        local lHrp = lChar and lChar:FindFirstChild("HumanoidRootPart")
        
        -- تصفير الأدوار عند نهاية الجيم وفراغ الماب
        if heavyCheck and (not Workspace:FindFirstChild("Normal") or #Workspace.Normal:GetChildren() == 0) then
            self:ResetAllRoles()
        end
        
        -- تشغيل الـ Aim Lock المطور للجوال والـ PC (تعديل الـ CFrame مباشرة)
        if self.Settings.AimLockEnabled then
            local myRole = self:CheckPlayerRole(LocalPlayer)
            if myRole == "Sheriff" or myRole == "Murder" then
                local target = self:GetBestAimTarget()
                if target and target.Character then
                    local aimPart = target.Character:FindFirstChild(self.Settings.AimPart) or target.Character:FindFirstChild("HumanoidRootPart")
                    if aimPart then
                        -- تصويب الكاميرا بسلاسة (Smooth Camera Manipulation)
                        local targetRotation = CFrame.lookAt(Camera.CFrame.Position, aimPart.Position)
                        Camera.CFrame = Camera.CFrame:Lerp(targetRotation, 1 - self.Settings.AimSmoothness)
                    end
                end
            end
        end
        
        -- تحديث الـ ESP للاعبين
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
                        
                        if distLabel and self.Settings.DistanceESP then
                            distLabel.Text = math.floor(distance) .. " studs"
                        end
                    end
                    
                    if heavyCheck then
                        local role = self:CheckPlayerRole(player)
                        local color = self.Colors[role]
                        
                        if cache.Billboard then
                            local outline = cache.Billboard:FindFirstChild("Outline")
                            local nameLabel = cache.Billboard:FindFirstChild("PlayerName")
                            if outline then outline.BorderColor3 = color end
                            if nameLabel then
                                if self.Settings.TeamESP then
                                    nameLabel.Text = player.Name .. " [" .. role .. "]"
                                    nameLabel.TextColor3 = color
                                else
                                    nameLabel.Text = player.Name
                                    nameLabel.TextColor3 = Color3.new(1,1,1)
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
    local function setup(player)
        if player == LocalPlayer then return end
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            self:CreatePlayerESP(player)
        end)
        player.CharacterRemoving:Connect(function()
            self:RemovePlayerESP(player)
        end)
        if player.Character then self:CreatePlayerESP(player) end
    end
    
    Players.PlayerAdded:Connect(setup)
    Players.PlayerRemoving:Connect(function(p) self:RemovePlayerESP(p) end)
    for _, p in ipairs(Players:GetPlayers()) do setup(p) end
    
    self:InitLoops()
end

--// بناء الواجهة الرأسية الاحترافية القابلة للسحب (👺)
local Gui = Instance.new("ScreenGui")
Gui.Name = "MM2_ESP_GUI"
Gui.ResetOnSpawn = false
Gui.Parent = PlayerGui

local function MakeDraggable(UIFrame, HandleFrame)
    local dragging, dragInput, dragStart, startPos
    HandleFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = UIFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    HandleFrame.InputChanged:Connect(function(input)
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

-- القائمة الرئيسية (تم توسيع الارتفاع ليستوعب ميزات الـ Aim Lock الجديدة رأساً)
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 310, 0, 420)
Main.Position = UDim2.new(0.5, -155, 0.4, -210)
Main.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
Main.BorderSizePixel = 0
Main.Parent = Gui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 45)
Title.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
Title.BorderSizePixel = 0
Title.Text = "FlyHubV4 - COMBAT PANEL"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = Main

Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 14)
MakeDraggable(Main, Title)

local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0, 28, 0, 28)
Close.Position = UDim2.new(1, -38, 0.5, -14)
Close.BackgroundColor3 = Color3.fromRGB(240, 50, 50)
Close.Text = "X"
Close.TextColor3 = Color3.new(1, 1, 1)
Close.Font = Enum.Font.GothamBold
Close.TextSize = 12
Close.Parent = Title

Instance.new("UICorner", Close).CornerRadius = UDim.new(1, 0)

-- أيقونة الفتح الجانبية الأسطورية 👺 القابلة للسحب
local OpenButton = Instance.new("TextButton")
OpenButton.Size = UDim2.new(0, 60, 0, 60)
OpenButton.Position = UDim2.new(0, 15, 0.5, -30)
OpenButton.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
OpenButton.BorderSizePixel = 0
OpenButton.Text = "👺"
OpenButton.TextSize = 32
OpenButton.Parent = Gui

local OpenStroke = Instance.new("UIStroke", OpenButton)
OpenStroke.Color = Color3.fromRGB(240, 50, 50)
OpenStroke.Width = 2

Instance.new("UICorner", OpenButton).CornerRadius = UDim.new(1, 0)
MakeDraggable(OpenButton, OpenButton)

-- حاوية الأزرار التي ترتب العناصر بشكل رأسي
local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Size = UDim2.new(1, -20, 1, -60)
ScrollingFrame.Position = UDim2.new(0, 10, 0, 55)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.BorderSizePixel = 0
ScrollingFrame.ScrollBarThickness = 3
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 430) -- مساحة كافية للتمرير العمودي سحب
ScrollingFrame.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 7)
Layout.Parent = ScrollingFrame

local function CreateToggle(Name, Key)
    local Holder = Instance.new("Frame")
    Holder.Size = UDim2.new(1, -5, 0, 36)
    Holder.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
    Holder.BorderSizePixel = 0
    Holder.Parent = ScrollingFrame

    Instance.new("UICorner", Holder).CornerRadius = UDim.new(0, 8)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.7, 0, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Name
    Label.TextColor3 = Color3.fromRGB(230, 230, 230)
    Label.Font = Enum.Font.GothamSemibold
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Holder

    local Toggle = Instance.new("TextButton")
    Toggle.Size = UDim2.new(0, 46, 0, 20)
    Toggle.Position = UDim2.new(1, -56, 0.5, -10)
    Toggle.BackgroundColor3 = ESPFramework.Settings[Key] and Color3.fromRGB(240, 50, 50) or Color3.fromRGB(55, 55, 55)
    Toggle.Text = ""
    Toggle.Parent = Holder

    Instance.new("UICorner", Toggle).CornerRadius = UDim.new(1, 0)

    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 16, 0, 16)
    Circle.Position = ESPFramework.Settings[Key] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    Circle.BackgroundColor3 = Color3.new(1, 1, 1)
    Circle.Parent = Toggle

    Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)

    Toggle.MouseButton1Click:Connect(function()
        ESPFramework.Settings[Key] = not ESPFramework.Settings[Key]
        local active = ESPFramework.Settings[Key]

        TweenService:Create(Toggle, TweenInfo.new(0.18), {
            BackgroundColor3 = active and Color3.fromRGB(240, 50, 50) or Color3.fromRGB(55, 55, 55)
        }):Play()

        TweenService:Create(Circle, TweenInfo.new(0.18), {
            Position = active and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        }):Play()
    end)
end

-- قواطع وعناصر واجهة التحكم الفعّالة (رأسية بالكامل وممتازة للسحب والتمرير)
CreateToggle("Master ESP Engine", "Enabled")
CreateToggle("Player Boxes & Chams", "PlayerESP")
CreateToggle("Show Game Roles (Team)", "TeamESP")
CreateToggle("Show Names", "NameESP")
CreateToggle("Distance Tracker", "DistanceESP")
CreateToggle("Coin Radar", "CoinESP")
-- أزرار تحكم الـ Aim Lock الجديدة المدمجة للجوال
CreateToggle("🎯 Mobile Aim Lock", "AimLockEnabled")
CreateToggle("🔒 Aim Wall Check", "AimWallCheck")

-- تفاعل الفتح والإغلاق بأنيميشن مطور وسلس
Close.MouseButton1Click:Connect(function()
    TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = OpenButton.Position
    }):Play()
    task.wait(0.2)
    Main.Visible = false
    OpenButton.Visible = true
end)

OpenButton.MouseButton1Click:Connect(function()
    if dragging then return end
    Main.Visible = true
    OpenButton.Visible = false
    Main.Size = UDim2.new(0, 0, 0, 0)
    Main.Position = OpenButton.Position
    TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 310, 0, 420),
        Position = UDim2.new(0.5, -155, 0.4, -210)
    }):Play()
end)

-- بدء تشغيل السكربت الموحد
task.spawn(function()
    ESPFramework:Start()
end)

print("🎯 FlyHubV4: Aim Lock successfully integrated with Mobile Touch Support!")
