-- Настройки
local ESP_SETTINGS = {
    BoxColor = Color3.fromRGB(255, 255, 255),
    HPColor = Color3.fromRGB(0, 255, 0),
    SkeletonColor = Color3.fromRGB(255, 105, 180),
    BoxThickness = 3,                         
    SkeletonThickness = 10,
    BoxScale = 8,                           
    ShowNames = true,
    ShowDistance = true,
    ShowHealth = true,
    ShowSkeleton = true,
    MaxDistance = 1000                         
}

-- S
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- C
local ESP_Cache = {}

-- L
local BONE_CONNECTIONS = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LowerTorso", "RightUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"}
}

local function CreateESP(player)
    if player == LocalPlayer then return end
    
    local drawings = {
        Box = {
            Top = Drawing.new("Line"),
            Bottom = Drawing.new("Line"),
            Left = Drawing.new("Line"),
            Right = Drawing.new("Line")
        },
        Text = {
            Name = Drawing.new("Text"),
            Distance = Drawing.new("Text")
        },
        HealthBar = {
            Outline = Drawing.new("Line"),
            Fill = Drawing.new("Line")
        },
        Skeleton = {}
    }
    
    -- Настройка гигантского бокса
    for _, line in pairs(drawings.Box) do
        line.Color = ESP_SETTINGS.BoxColor
        line.Thickness = ESP_SETTINGS.BoxThickness -- Толстые линии
        line.Visible = false
    end

    -- Настройка HP-бара
    drawings.HealthBar.Outline.Color = Color3.new(0, 0, 0)
    drawings.HealthBar.Outline.Thickness = ESP_SETTINGS.BoxThickness + 2
    drawings.HealthBar.Fill.Color = ESP_SETTINGS.HPColor
    drawings.HealthBar.Fill.Thickness = ESP_SETTINGS.BoxThickness + 1

    -- Настройка текста
    drawings.Text.Name.Size = 18 -- Увеличенный текст
    drawings.Text.Name.Outline = true
    drawings.Text.Name.Center = true
    drawings.Text.Distance.Size = 16
    drawings.Text.Distance.Outline = true
    drawings.Text.Distance.Center = true

    -- Создание линий скелетона
    for _ = 1, #BONE_CONNECTIONS do
        local boneLine = Drawing.new("Line")
        boneLine.Color = ESP_SETTINGS.SkeletonColor
        boneLine.Thickness = ESP_SETTINGS.SkeletonThickness
        boneLine.Visible = false
        table.insert(drawings.Skeleton, boneLine)
    end
    
    ESP_Cache[player] = drawings
end

local function UpdateESP()
    for player, drawings in pairs(ESP_Cache) do
        if player and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            
            if humanoid and humanoid.Health > 0 and rootPart then
                local rootPos, rootVis = Camera:WorldToViewportPoint(rootPart.Position)
                local dist = (Camera.CFrame.Position - rootPart.Position).Magnitude
                
                if rootVis and dist <= ESP_SETTINGS.MaxDistance then
                    -- Размеры гигантского бокса (25x)
                    local height = 6 * ESP_SETTINGS.BoxScale  -- ~150 studs
                    local width = 3 * ESP_SETTINGS.BoxScale   -- ~75 studs
                    
                    -- Центрирование по rootPart
                    local topLeft = Vector2.new(rootPos.X - width/2, rootPos.Y - height/2)
                    local bottomRight = Vector2.new(rootPos.X + width/2, rootPos.Y + height/2)
                    
                    -- Отрисовка мега-бокса
                    drawings.Box.Top.From = topLeft
                    drawings.Box.Top.To = Vector2.new(bottomRight.X, topLeft.Y)
                    drawings.Box.Bottom.From = Vector2.new(topLeft.X, bottomRight.Y)
                    drawings.Box.Bottom.To = bottomRight
                    drawings.Box.Left.From = topLeft
                    drawings.Box.Left.To = Vector2.new(topLeft.X, bottomRight.Y)
                    drawings.Box.Right.From = Vector2.new(bottomRight.X, topLeft.Y)
                    drawings.Box.Right.To = bottomRight
                    
                    -- HP-бар (масштабированный)
                    if ESP_SETTINGS.ShowHealth then
                        local healthY = bottomRight.Y - (height * (humanoid.Health/humanoid.MaxHealth))
                        drawings.HealthBar.Outline.From = Vector2.new(topLeft.X - 10, topLeft.Y)
                        drawings.HealthBar.Outline.To = Vector2.new(topLeft.X - 10, bottomRight.Y)
                        drawings.HealthBar.Fill.From = Vector2.new(topLeft.X - 10, healthY)
                        drawings.HealthBar.Fill.To = Vector2.new(topLeft.X - 10, bottomRight.Y)
                    end
                    
                    -- Скелетон (остается нормального размера)
                    if ESP_SETTINGS.ShowSkeleton then
                        for i, bones in ipairs(BONE_CONNECTIONS) do
                            local part0 = player.Character:FindFirstChild(bones[1])
                            local part1 = player.Character:FindFirstChild(bones[2])
                            
                            if part0 and part1 then
                                local pos0 = Camera:WorldToViewportPoint(part0.Position)
                                local pos1 = Camera:WorldToViewportPoint(part1.Position)
                                
                                if pos0 and pos1 then
                                    drawings.Skeleton[i].From = Vector2.new(pos0.X, pos0.Y)
                                    drawings.Skeleton[i].To = Vector2.new(pos1.X, pos1.Y)
                                    drawings.Skeleton[i].Visible = true
                                end
                            end
                        end
                    end
                    
                    -- Текст (масштабированный)
                    if ESP_SETTINGS.ShowNames then
                        drawings.Text.Name.Position = Vector2.new(rootPos.X, topLeft.Y - 25)
                        drawings.Text.Name.Text = player.Name
                    end
                    
                    if ESP_SETTINGS.ShowDistance then
                        drawings.Text.Distance.Position = Vector2.new(rootPos.X, bottomRight.Y + 15)
                        drawings.Text.Distance.Text = math.floor(dist) .. "m"
                    end
                    
                    -- Включение видимости
                    for _, element in pairs(drawings.Box) do element.Visible = true end
                    if drawings.HealthBar then
                        drawings.HealthBar.Outline.Visible = true
                        drawings.HealthBar.Fill.Visible = true
                    end
                    if drawings.Skeleton then
                        for _, bone in pairs(drawings.Skeleton) do bone.Visible = true end
                    end
                    if drawings.Text then
                        drawings.Text.Name.Visible = true
                        drawings.Text.Distance.Visible = true
                    end
                else
                    -- Выключение при выходе за пределы
                    for _, element in pairs(drawings.Box) do element.Visible = false end
                    if drawings.HealthBar then
                        drawings.HealthBar.Outline.Visible = false
                        drawings.HealthBar.Fill.Visible = false
                    end
                    if drawings.Skeleton then
                        for _, bone in pairs(drawings.Skeleton) do bone.Visible = false end
                    end
                    if drawings.Text then
                        drawings.Text.Name.Visible = false
                        drawings.Text.Distance.Visible = false
                    end
                end
            end
        end
    end
end

-- i
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if ESP_Cache[player] then
        for _, drawing in pairs(ESP_Cache[player].Box) do drawing:Remove() end
        if ESP_Cache[player].HealthBar then
            ESP_Cache[player].HealthBar.Outline:Remove()
            ESP_Cache[player].HealthBar.Fill:Remove()
        end
        if ESP_Cache[player].Skeleton then
            for _, bone in pairs(ESP_Cache[player].Skeleton) do bone:Remove() end
        end
        if ESP_Cache[player].Text then
            ESP_Cache[player].Text.Name:Remove()
            ESP_Cache[player].Text.Distance:Remove()
        end
        ESP_Cache[player] = nil
    end
end)

-- Основной цикл
RunService.RenderStepped:Connect(UpdateESP)
