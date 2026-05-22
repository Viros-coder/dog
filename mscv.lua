-- ESP System for Murder Mystery 2 (GitHub / Universal Edition)
-- LocalScript

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- الألوان
local COLORS = {
    Murder = Color3.fromRGB(255, 0, 0),      -- أحمر
    Sheriff = Color3.fromRGB(0, 100, 255),   -- أزرق
    Innocent = Color3.fromRGB(0, 255, 0),    -- أخضر
}

local ESPBoxes = {}
local PlayerRoles = {} -- لتخزين أدوار اللاعبين المكتشفة

-- إزالة ESP
local function RemoveESP(player)
    if ESPBoxes[player] then
        ESPBoxes[player]:Destroy()
        ESPBoxes[player] = nil
    end
    PlayerRoles[player] = nil
end

-- إنشاء Box ESP
local function CreateESPBox(player)
    if player == LocalPlayer then return end
    
    local character = player.Character
    if not character then return end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    if ESPBoxes[player] then RemoveESP(player) end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_" .. player.Name
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(4, 0, 5, 0)
    billboard.Adornee = humanoidRootPart
    billboard.Parent = PlayerGui
    
    local outline = Instance.new("Frame")
    outline.Name = "Outline"
    outline.Size = UDim2.new(1, 0, 1, 0)
    outline.BackgroundTransparency = 0.8
    outline.BorderSizePixel = 2
    outline.BorderColor3 = COLORS.Innocent
    outline.BackgroundColor3 = COLORS.Innocent
    outline.Parent = billboard
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "PlayerName"
    nameLabel.Size = UDim2.new(1, 0, 0.15, 0)
    nameLabel.Position = UDim2.new(0, 0, -0.15, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name .. " [Innocent]"
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard
    
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "Distance"
    distanceLabel.Size = UDim2.new(1, 0, 0.12, 0)
    distanceLabel.Position = UDim2.new(0, 0, 1, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.TextScaled = true
    distanceLabel.Font = Enum.Font.Gotham
    distanceLabel.Parent = billboard
    
    ESPBoxes[player] = billboard
end

-- فحص دور اللاعب بناءً على أسلحته (متوافق مع MM2)
local function CheckPlayerRole(player)
    if player == LocalPlayer then return end
    
    local currentRole = PlayerRoles[player] or "Innocent"
    
    -- إذا تم تحديده كمجرم أو شريف سابقاً في نفس الجولة، لا داعي لإعادة الفحص الشامل وتقليل الأداء
    if currentRole == "Murder" or currentRole == "Sheriff" then return end

    local character = player.Character
    local backpack = player:FindFirstChild("Backpack")
    
    -- مصفوفة للبحث عن الأسلحة في الحقيبة أو اليد
    local locations = {}
    if character then table.insert(locations, character) end
    if backpack then table.insert(locations, backpack) end
    
    for _, loc in ipairs(locations) do
        -- فحص السكين (Murderer)
        if loc:FindFirstChild("Knife") or loc:FindFirstChild("Blade") then
            PlayerRoles[player] = "Murder"
            return
        -- فحص المسدس (Sheriff)
        elseif loc:FindFirstChild("Gun") or loc:FindFirstChild("Revolver") then
            PlayerRoles[player] = "Sheriff"
            return
        end
    end
end

-- تحديث الألوان والنصوص بناءً على الدور المكتشف
local function UpdateESPVisuals(player)
    local box = ESPBoxes[player]
    if not box then return end
    
    local role = PlayerRoles[player] or "Innocent"
    
    local outline = box:FindFirstChild("Outline")
    if outline then
        local color = COLORS[role]
        outline.BorderColor3 = color
        outline.BackgroundColor3 = color
    end
    
    local nameLabel = box:FindFirstChild("PlayerName")
    if nameLabel then
        nameLabel.Text = player.Name .. " [" .. role .. "]"
    end
end

-- إعداد اللاعب
local function SetupPlayer(player)
    if player == LocalPlayer then return end
    
    player.CharacterAdded:Connect(function(char)
        task.wait(0.3)
        CreateESPBox(player)
    end)
    
    player.CharacterRemoving:Connect(function()
        RemoveESP(player)
    end)
    
    if player.Character then
        CreateESPBox(player)
    end
end

Players.PlayerAdded:Connect(SetupPlayer)
Players.PlayerRemoving:Connect(RemoveESP)

for _, player in ipairs(Players:GetPlayers()) do
    SetupPlayer(player)
end

-- التحديث المستمر للمسافات والأدوار المكتشفة تلقائياً
RunService.RenderStepped:Connect(function()
    local localCharacter = LocalPlayer.Character
    local localHrp = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
    
    for player, box in pairs(ESPBoxes) do
        if player.Character and localHrp then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local distanceLabel = box:FindFirstChild("Distance")
            
            -- 1. تحديث المسافة
            if hrp and distanceLabel then
                local distance = (hrp.Position - localHrp.Position).Magnitude
                distanceLabel.Text = math.floor(distance) .. "m"
            end
            
            -- 2. كشف الدور تلقائياً وتحديث الألوان
            CheckPlayerRole(player)
            UpdateESPVisuals(player)
        else
            RemoveESP(player)
        end
    end
end)

print("✅ GitHub Universal MM2 ESP Loaded!")
