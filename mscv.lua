--[[
    💾 FlyHubV4 - MM2 Mobile Ultra Framework (GUI-LESS HARDWARE EDITION)
    💻 Developer: Viros-coder
    📦 Repository: dog
    📜 Script: mscv.lua
    📱 Control: Volume Up Button to Toggle AimLock (No GUI Elements)
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
        MaxDistance = 2000,
        ThrottlingRate = 2,
        
        AimLockEnabled = false, -- يتم تبديله بزر رفع الصوت
        AimWallCheck = true,
        AimSmoothness = 0.12, 
        AimFOV = 250,
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
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

-- إبادة وتدمير نهائي لأي عناصر واجهة قديمة مسببة للمربعات السوداء
pcall(function()
    if PlayerGui:FindFirstChild("MM2_ESP_GUI") then PlayerGui.MM2_ESP_GUI:Destroy() end
    if game:GetService("CoreGui"):FindFirstChild("MM2_ESP_GUI") then game:GetService("CoreGui").MM2_ESP_GUI:Destroy() end
end)

-- نظام إشعارات اللعبة الرسمي (نظيف ولا يتأثر بمشاكل المشغل)
local function SendSystemNotice(title, text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 3
        })
    end)
end

SendSystemNotice("FlyHubV4 Activated", "ESP Running! Press VOLUME UP to toggle Aim Lock.")

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
    
    -- استخدام اللوحات ثلاثية الأبعاد المرتبطة بالشخصيات (لا تتأثر بالمربعات السوداء للـ GUI)
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
    nameLabel.Position = UDim2.new(0, 0, -0.2, 0)
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
    distLabel.Position = UDim2.new(0, 0, 1.05, 0)
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
    
    -- 📱 ربط زر رفع الصوت الفعلي للهاتف لفتح وقفل الـ Aim Lock تلقائياً دون لمس الشاشة!
    UserInputService.InputBegan:Connect(function(input, processed)
        if input.KeyCode == Enum.KeyCode.VolumeUp then
            self.Settings.AimLockEnabled = not self.Settings.AimLockEnabled
            if self.Settings.AimLockEnabled then
                SendSystemNotice("FlyHubV4", "🎯 Aim Lock: ACTIVATED")
            else
                SendSystemNotice("FlyHubV4", "🔒 Aim Lock: DEACTIVATED")
            end
        end
    end)
    
    self:InitLoops()
end

task.spawn(function()
    ESPFramework:Start()
end)

print("🎯 Background Script successfully loaded! Your screen is 100% clean and free of boxes.")
