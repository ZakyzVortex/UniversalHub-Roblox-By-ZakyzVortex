-- ================== UNIVERSAL HUB - TEAM SYSTEM FIXED ==================
-- By ZakyzVortex - Sistema de Times Funcionando + Aim Assist Corrigido

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Character References
local Character, Humanoid, HRP
local function BindCharacter(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HRP = char:WaitForChild("HumanoidRootPart")
    Humanoid.UseJumpPower = true
end

if LP.Character then
    BindCharacter(LP.Character)
else
    LP.CharacterAdded:Wait()
    BindCharacter(LP.Character)
end
LP.CharacterAdded:Connect(BindCharacter)

-- ================== TEAM DETECTION ==================
local function isPlayerOnSameTeam(player)
    if not LP.Team or not player.Team then return false end
    return player.Team == LP.Team
end

local function shouldShowPlayer(player, filterMode)
    if filterMode == "All" then
        return true
    elseif filterMode == "Team" then
        return isPlayerOnSameTeam(player)
    elseif filterMode == "Enemy" then
        return not isPlayerOnSameTeam(player)
    end
    return true
end

-- Window
local Window = Rayfield:CreateWindow({
    Name = "Universal Hub - Team System",
    LoadingTitle = "Universal Hub",
    LoadingSubtitle = "By ZakyzVortex",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "UniversalHub",
        FileName = "Config"
    }
})

-- Tabs
local TabMove = Window:CreateTab("Movement")
local TabCombat = Window:CreateTab("Combat")
local TabESP = Window:CreateTab("ESP")
local TabHighlight = Window:CreateTab("Highlight ESP")
local TabAim = Window:CreateTab("Aim Assist")
local TabProt = Window:CreateTab("Protection")
local TabPlayers = Window:CreateTab("Players")
local TabWaypoints = Window:CreateTab("Waypoints")
local TabVisuals = Window:CreateTab("Visuals")
local TabWorld = Window:CreateTab("World")
local TabFPS = Window:CreateTab("FPS/Stats")
local TabConfig = Window:CreateTab("Config")
local TabUtil = Window:CreateTab("Utility")

-- ==================== MOVEMENT ====================
TabMove:CreateSection("Velocidade e Pulo")

local fly, flySpeed, flyUpImpulse = false, 100, 0
local infJump = false

TabMove:CreateSlider({
    Name = "Velocidade de Caminhada",
    Range = {16, 300},
    Increment = 5,
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(v)
        if Humanoid then Humanoid.WalkSpeed = v end
    end
})

TabMove:CreateSlider({
    Name = "Poder de Pulo",
    Range = {50, 300},
    Increment = 10,
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(v)
        if Humanoid then
            Humanoid.UseJumpPower = true
            Humanoid.JumpPower = v
        end
    end
})

TabMove:CreateSection("Fly System")

TabMove:CreateSlider({
    Name = "Velocidade de Voo",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = 100,
    Flag = "FlySpeed",
    Callback = function(v)
        flySpeed = v
    end
})

TabMove:CreateToggle({
    Name = "Ativar Fly",
    CurrentValue = false,
    Flag = "FlyEnabled",
    Callback = function(v)
        fly = v
        if not v and HRP then
            for _, i in pairs({"FlyVel", "FlyGyro"}) do
                local o = HRP:FindFirstChild(i)
                if o then o:Destroy() end
            end
        end
    end
})

TabMove:CreateSection("Outros")

TabMove:CreateToggle({
    Name = "Pulo Infinito",
    CurrentValue = false,
    Flag = "InfJump",
    Callback = function(v)
        infJump = v
    end
})

UserInputService.JumpRequest:Connect(function()
    if fly then flyUpImpulse = 0.18 end
    if infJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ==================== COMBAT ====================
TabCombat:CreateSection("Auto Clicker")

local AUTO_CLICKER_ENABLED = false
local AUTO_CLICKER_CPS = 10
local lastClick = 0

TabCombat:CreateToggle({
    Name = "Ativar Auto Clicker",
    CurrentValue = false,
    Flag = "AutoClicker",
    Callback = function(v)
        AUTO_CLICKER_ENABLED = v
    end
})

TabCombat:CreateSlider({
    Name = "CPS",
    Range = {1, 50},
    Increment = 1,
    CurrentValue = 10,
    Flag = "AutoClickerCPS",
    Callback = function(v)
        AUTO_CLICKER_CPS = v
    end
})

RunService.RenderStepped:Connect(function()
    if not AUTO_CLICKER_ENABLED then return end
    local now = tick()
    if now - lastClick >= 1 / AUTO_CLICKER_CPS then
        mouse1click()
        lastClick = now
    end
end)

TabCombat:CreateSection("Hit Range")

local HIT_RANGE_ENABLED = false
local HIT_RANGE_SIZE = 10
local originalSizes = {}

local function extendHitboxes()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                if not originalSizes[player] then
                    originalSizes[player] = hrp.Size
                end
                if HIT_RANGE_ENABLED then
                    hrp.Size = Vector3.new(HIT_RANGE_SIZE, HIT_RANGE_SIZE, HIT_RANGE_SIZE)
                    hrp.Transparency = 0.7
                    hrp.CanCollide = false
                else
                    hrp.Size = originalSizes[player]
                    hrp.Transparency = 1
                end
            end
        end
    end
end

TabCombat:CreateToggle({
    Name = "Hit Range Extender",
    CurrentValue = false,
    Flag = "HitRange",
    Callback = function(v)
        HIT_RANGE_ENABLED = v
        extendHitboxes()
    end
})

TabCombat:CreateSlider({
    Name = "Tamanho da Hitbox",
    Range = {5, 30},
    Increment = 1,
    CurrentValue = 10,
    Flag = "HitboxSize",
    Callback = function(v)
        HIT_RANGE_SIZE = v
        extendHitboxes()
    end
})

RunService.Heartbeat:Connect(function()
    if HIT_RANGE_ENABLED then extendHitboxes() end
end)

-- ==================== ESP COM SISTEMA DE TIMES ====================
local ESP_ENABLED = false
local NAME_ENABLED = true
local DISTANCE_ENABLED = true
local LINE_ENABLED = true
local HEALTH_ENABLED = true
local OUTLINE_ENABLED = true
local ESP_COLOR = Color3.fromRGB(255, 0, 0)
local LINE_COLOR = Color3.fromRGB(255, 255, 255)
local ESP_OBJECTS = {}
local ESP_TEAM_FILTER = "All"

local function removeESP(player)
    local espData = ESP_OBJECTS[player]
    if not espData then return end
    espData.active = false
    if espData.nameLabel then espData.nameLabel:Remove() end
    if espData.distLabel then espData.distLabel:Remove() end
    if espData.healthLabel then espData.healthLabel:Remove() end
    if espData.tracerLine then espData.tracerLine:Remove() end
    if espData.boxOutline then espData.boxOutline:Remove() end
    ESP_OBJECTS[player] = nil
end

local function createESP(player)
    if player == LP then return end
    if not player.Character then return end
    if not shouldShowPlayer(player, ESP_TEAM_FILTER) then return end
    
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    local head = player.Character:FindFirstChild("Head")
    local hum = player.Character:FindFirstChild("Humanoid")
    if not hrp or not head then return end
    
    local espData = { active = true, player = player }
    
    if NAME_ENABLED then
        local nameLabel = Drawing.new("Text")
        nameLabel.Visible = true
        nameLabel.Center = true
        nameLabel.Outline = true
        nameLabel.Color = ESP_COLOR
        nameLabel.Size = 16
        nameLabel.Text = player.Name
        espData.nameLabel = nameLabel
    end
    
    if DISTANCE_ENABLED then
        local distLabel = Drawing.new("Text")
        distLabel.Visible = true
        distLabel.Center = true
        distLabel.Outline = true
        distLabel.Color = Color3.fromRGB(255, 255, 255)
        distLabel.Size = 14
        espData.distLabel = distLabel
    end
    
    if HEALTH_ENABLED and hum then
        local healthLabel = Drawing.new("Text")
        healthLabel.Visible = true
        healthLabel.Center = true
        healthLabel.Outline = true
        healthLabel.Size = 14
        espData.healthLabel = healthLabel
    end
    
    if LINE_ENABLED then
        local tracerLine = Drawing.new("Line")
        tracerLine.Visible = true
        tracerLine.Color = LINE_COLOR
        tracerLine.Thickness = 1
        espData.tracerLine = tracerLine
    end
    
    if OUTLINE_ENABLED then
        local boxOutline = Drawing.new("Square")
        boxOutline.Visible = true
        boxOutline.Color = ESP_COLOR
        boxOutline.Thickness = 2
        boxOutline.Filled = false
        espData.boxOutline = boxOutline
    end
    
    ESP_OBJECTS[player] = espData
end

local function updateESP()
    if not ESP_ENABLED then return end
    
    for player, espData in pairs(ESP_OBJECTS) do
        if not espData.active then continue end
        if not player.Character then removeESP(player) continue end
        if not shouldShowPlayer(player, ESP_TEAM_FILTER) then removeESP(player) continue end
        
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        local head = player.Character:FindFirstChild("Head")
        local hum = player.Character:FindFirstChild("Humanoid")
        
        if not hrp or not head then removeESP(player) continue end
        
        local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        local headPos = Camera:WorldToViewportPoint(head.Position)
        local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
        
        if onScreen then
            local dist = (HRP.Position - hrp.Position).Magnitude
            
            if espData.nameLabel then
                espData.nameLabel.Position = Vector2.new(headPos.X, headPos.Y - 30)
                espData.nameLabel.Visible = true
            end
            
            if espData.distLabel then
                espData.distLabel.Text = string.format("[%d studs]", math.floor(dist))
                espData.distLabel.Position = Vector2.new(headPos.X, headPos.Y - 15)
                espData.distLabel.Visible = true
            end
            
            if espData.healthLabel and hum then
                local healthPercent = math.floor((hum.Health / hum.MaxHealth) * 100)
                local healthColor = Color3.fromRGB(255 - (healthPercent * 2.55), healthPercent * 2.55, 0)
                espData.healthLabel.Text = string.format("HP: %d%%", healthPercent)
                espData.healthLabel.Color = healthColor
                espData.healthLabel.Position = Vector2.new(vector.X, vector.Y)
                espData.healthLabel.Visible = true
            end
            
            if espData.tracerLine then
                espData.tracerLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                espData.tracerLine.To = Vector2.new(vector.X, vector.Y)
                espData.tracerLine.Visible = true
            end
            
            if espData.boxOutline then
                local height = math.abs(headPos.Y - legPos.Y)
                local width = height / 2
                espData.boxOutline.Size = Vector2.new(width, height)
                espData.boxOutline.Position = Vector2.new(vector.X - width / 2, headPos.Y)
                espData.boxOutline.Visible = true
            end
        else
            if espData.nameLabel then espData.nameLabel.Visible = false end
            if espData.distLabel then espData.distLabel.Visible = false end
            if espData.healthLabel then espData.healthLabel.Visible = false end
            if espData.tracerLine then espData.tracerLine.Visible = false end
            if espData.boxOutline then espData.boxOutline.Visible = false end
        end
    end
end

local function refreshESP()
    for _, player in ipairs(Players:GetPlayers()) do
        removeESP(player)
        if ESP_ENABLED then createESP(player) end
    end
end

local function clearAllESP()
    for player, _ in pairs(ESP_OBJECTS) do
        removeESP(player)
    end
end

TabESP:CreateSection("ESP Settings")

TabESP:CreateToggle({
    Name = "Ativar ESP",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(v)
        ESP_ENABLED = v
        if v then refreshESP() else clearAllESP() end
    end
})

TabESP:CreateDropdown({
    Name = "Filtro de Time",
    Options = {"All", "Team", "Enemy"},
    CurrentOption = "All",
    Flag = "ESPTeamFilter",
    Callback = function(v)
        ESP_TEAM_FILTER = v
        refreshESP()
    end
})

TabESP:CreateSection("ESP Components")

TabESP:CreateToggle({
    Name = "Nome",
    CurrentValue = true,
    Flag = "ESPName",
    Callback = function(v)
        NAME_ENABLED = v
        refreshESP()
    end
})

TabESP:CreateToggle({
    Name = "Distância",
    CurrentValue = true,
    Flag = "ESPDistance",
    Callback = function(v)
        DISTANCE_ENABLED = v
        refreshESP()
    end
})

TabESP:CreateToggle({
    Name = "Vida",
    CurrentValue = true,
    Flag = "ESPHealth",
    Callback = function(v)
        HEALTH_ENABLED = v
        refreshESP()
    end
})

TabESP:CreateToggle({
    Name = "Tracer Line",
    CurrentValue = true,
    Flag = "ESPLine",
    Callback = function(v)
        LINE_ENABLED = v
        refreshESP()
    end
})

TabESP:CreateToggle({
    Name = "Box Outline",
    CurrentValue = true,
    Flag = "ESPOutline",
    Callback = function(v)
        OUTLINE_ENABLED = v
        refreshESP()
    end
})

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if ESP_ENABLED then createESP(player) end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

RunService.RenderStepped:Connect(updateESP)

-- ==================== HIGHLIGHT ESP ====================
local HIGHLIGHT_ENABLED = false
local HIGHLIGHT_TEAM_FILTER = "All"
local highlightObjects = {}

local function removeAllHighlights()
    for player, highlight in pairs(highlightObjects) do
        if highlight then highlight:Destroy() end
    end
    highlightObjects = {}
end

local function createHighlight(player)
    if player == LP then return end
    if not player.Character then return end
    if not shouldShowPlayer(player, HIGHLIGHT_TEAM_FILTER) then return end
    
    if highlightObjects[player] then
        highlightObjects[player]:Destroy()
    end
    
    local highlight = Instance.new("Highlight")
    highlight.Parent = player.Character
    highlight.FillColor = isPlayerOnSameTeam(player) and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlightObjects[player] = highlight
end

local function refreshHighlights()
    removeAllHighlights()
    if HIGHLIGHT_ENABLED then
        for _, player in ipairs(Players:GetPlayers()) do
            createHighlight(player)
        end
    end
end

TabHighlight:CreateSection("Highlight ESP")

TabHighlight:CreateToggle({
    Name = "Ativar Highlight",
    CurrentValue = false,
    Flag = "Highlight",
    Callback = function(v)
        HIGHLIGHT_ENABLED = v
        refreshHighlights()
    end
})

TabHighlight:CreateDropdown({
    Name = "Filtro de Time",
    Options = {"All", "Team", "Enemy"},
    CurrentOption = "All",
    Flag = "HighlightTeamFilter",
    Callback = function(v)
        HIGHLIGHT_TEAM_FILTER = v
        refreshHighlights()
    end
})

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if HIGHLIGHT_ENABLED then createHighlight(player) end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    if highlightObjects[player] then
        highlightObjects[player]:Destroy()
        highlightObjects[player] = nil
    end
end)

-- ==================== AIM ASSIST - CORRIGIDO ====================
TabAim:CreateSection("Aim Assist")

local AIM_ENABLED = false
local AIM_SMOOTHNESS = 0.5
local AIM_PART = "Head"
local AIM_TEAM_FILTER = "Enemy"  -- All, Team, Enemy
local AIM_VISIBLE_CHECK = true
local AIM_MAX_DISTANCE = 1000
local AIM_FOV_RADIUS = 200
local currentTarget = nil
local lastTargetUpdate = 0

-- Função para verificar se o jogador está visível
local function isVisible(targetPart)
    if not targetPart or not HRP then return false end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {Character, targetPart.Parent}
    
    local ray = workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position), raycastParams)
    return ray == nil
end

-- Função para obter a parte do alvo
local function getTargetPart(player)
    if not player.Character then return nil end
    
    if AIM_PART == "Head" then
        return player.Character:FindFirstChild("Head")
    elseif AIM_PART == "Torso" then
        return player.Character:FindFirstChild("HumanoidRootPart")
    elseif AIM_PART == "Random" then
        local parts = {"Head", "HumanoidRootPart"}
        local randomPart = parts[math.random(1, #parts)]
        return player.Character:FindFirstChild(randomPart)
    end
    
    return player.Character:FindFirstChild("Head")
end

-- Função para verificar se o jogador é válido como alvo (COM FILTRO DE TIME CORRIGIDO)
local function isValidTarget(player)
    if not player or player == LP then return false end
    if not player.Character then return false end
    
    local targetPart = getTargetPart(player)
    if not targetPart then return false end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    -- FILTRO DE TIME CORRIGIDO
    if not shouldShowPlayer(player, AIM_TEAM_FILTER) then
        return false
    end
    
    -- Verificação de distância
    local distance = (HRP.Position - targetPart.Position).Magnitude
    if distance > AIM_MAX_DISTANCE then return false end
    
    -- Verificação de FOV
    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
    if not onScreen then return false end
    
    local centerScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local targetScreen = Vector2.new(screenPos.X, screenPos.Y)
    local distanceFromCenter = (centerScreen - targetScreen).Magnitude
    
    if distanceFromCenter > AIM_FOV_RADIUS then return false end
    
    -- Verificação de visibilidade
    if AIM_VISIBLE_CHECK and not isVisible(targetPart) then
        return false
    end
    
    return true
end

-- Função para encontrar o melhor alvo (mais próximo do centro da tela)
local function findBestTarget()
    local bestTarget = nil
    local shortestDistance = math.huge
    local centerScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local targetPart = getTargetPart(player)
            if targetPart then
                local screenPos = Camera:WorldToViewportPoint(targetPart.Position)
                local targetScreen = Vector2.new(screenPos.X, screenPos.Y)
                local distanceFromCenter = (centerScreen - targetScreen).Magnitude
                
                if distanceFromCenter < shortestDistance then
                    shortestDistance = distanceFromCenter
                    bestTarget = player
                end
            end
        end
    end
    
    return bestTarget
end

-- Função para atualizar o alvo automaticamente
local function updateTarget()
    local now = tick()
    
    -- Atualizar alvo a cada 0.1 segundos
    if now - lastTargetUpdate < 0.1 then return end
    lastTargetUpdate = now
    
    -- Se não há alvo ou o alvo atual não é mais válido, buscar novo alvo
    if not currentTarget or not isValidTarget(currentTarget) then
        currentTarget = findBestTarget()
    end
end

-- Função principal do aim assist
local function aimAssist()
    if not AIM_ENABLED then return end
    if not Character or not HRP then return end
    
    -- Atualizar alvo
    updateTarget()
    
    if not currentTarget then return end
    
    local targetPart = getTargetPart(currentTarget)
    if not targetPart then
        currentTarget = nil
        return
    end
    
    -- Calcular a posição para mirar
    local targetPosition = targetPart.Position
    
    -- Predição de movimento (básica)
    local targetHRP = currentTarget.Character:FindFirstChild("HumanoidRootPart")
    if targetHRP then
        local velocity = targetHRP.AssemblyLinearVelocity
        local distance = (HRP.Position - targetPosition).Magnitude
        local timeToHit = distance / 500 -- Velocidade estimada de projétil
        targetPosition = targetPosition + (velocity * timeToHit * 0.5)
    end
    
    -- Calcular nova rotação da câmera
    local lookVector = (targetPosition - Camera.CFrame.Position).Unit
    local newCFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + lookVector)
    
    -- Aplicar suavização
    Camera.CFrame = Camera.CFrame:Lerp(newCFrame, AIM_SMOOTHNESS)
end

-- Interface do Aim Assist
TabAim:CreateToggle({
    Name = "Ativar Aim Assist",
    CurrentValue = false,
    Flag = "AimEnabled",
    Callback = function(v)
        AIM_ENABLED = v
        if not v then
            currentTarget = nil
        end
    end
})

TabAim:CreateSlider({
    Name = "Suavização",
    Range = {0.1, 1},
    Increment = 0.05,
    CurrentValue = 0.5,
    Flag = "AimSmoothness",
    Callback = function(v)
        AIM_SMOOTHNESS = v
    end
})

TabAim:CreateSlider({
    Name = "Raio FOV",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = 200,
    Flag = "AimFOV",
    Callback = function(v)
        AIM_FOV_RADIUS = v
    end
})

TabAim:CreateSlider({
    Name = "Distância Máxima",
    Range = {100, 5000},
    Increment = 100,
    CurrentValue = 1000,
    Flag = "AimDistance",
    Callback = function(v)
        AIM_MAX_DISTANCE = v
    end
})

TabAim:CreateSection("Configurações")

TabAim:CreateDropdown({
    Name = "Filtro de Time",
    Options = {"All", "Team", "Enemy"},
    CurrentOption = "Enemy",
    Flag = "AimTeamFilter",
    Callback = function(v)
        AIM_TEAM_FILTER = v
        currentTarget = nil  -- Resetar alvo ao mudar filtro
    end
})

TabAim:CreateDropdown({
    Name = "Parte do Alvo",
    Options = {"Head", "Torso", "Random"},
    CurrentOption = "Head",
    Flag = "AimPart",
    Callback = function(v)
        AIM_PART = v
    end
})

TabAim:CreateToggle({
    Name = "Verificar Visibilidade",
    CurrentValue = true,
    Flag = "AimVisibleCheck",
    Callback = function(v)
        AIM_VISIBLE_CHECK = v
    end
})

-- Executar aim assist no RenderStepped
RunService.RenderStepped:Connect(aimAssist)

-- ==================== PROTECTION ====================
local godMode = false
local lockHP = false
local antiVoid = false
local antiKB = false

TabProt:CreateSection("Proteções")

TabProt:CreateToggle({
    Name = "God Mode",
    CurrentValue = false,
    Flag = "GodMode",
    Callback = function(v)
        godMode = v
        if not v and Humanoid then
            Humanoid.MaxHealth = 100
            Humanoid.Health = 100
        end
    end
})

TabProt:CreateToggle({
    Name = "Lock HP",
    CurrentValue = false,
    Flag = "LockHP",
    Callback = function(v)
        lockHP = v
    end
})

TabProt:CreateToggle({
    Name = "Anti Void",
    CurrentValue = false,
    Flag = "AntiVoid",
    Callback = function(v)
        antiVoid = v
    end
})

TabProt:CreateToggle({
    Name = "Anti Knockback",
    CurrentValue = false,
    Flag = "AntiKB",
    Callback = function(v)
        antiKB = v
    end
})

-- ==================== PLAYERS ====================
local selectedPlayer = nil
local teleportBehind = false

TabPlayers:CreateSection("Player Selection")

local playerList = {}
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LP then
        table.insert(playerList, player.Name)
    end
end

local playerDropdown = TabPlayers:CreateDropdown({
    Name = "Selecionar Jogador",
    Options = playerList,
    CurrentOption = playerList[1] or "None",
    Flag = "SelectedPlayer",
    Callback = function(v)
        selectedPlayer = Players:FindFirstChild(v)
    end
})

Players.PlayerAdded:Connect(function(player)
    task.wait(0.5)
    playerDropdown:Refresh(Players:GetPlayers())
end)

Players.PlayerRemoving:Connect(function(player)
    playerDropdown:Refresh(Players:GetPlayers())
end)

TabPlayers:CreateSection("Actions")

TabPlayers:CreateButton({
    Name = "Teleportar para Jogador",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character and HRP then
            local targetHRP = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                if teleportBehind then
                    local behindPos = targetHRP.CFrame * CFrame.new(0, 0, 3)
                    HRP.CFrame = behindPos
                else
                    HRP.CFrame = targetHRP.CFrame
                end
            end
        end
    end
})

TabPlayers:CreateToggle({
    Name = "Teleportar Atrás",
    CurrentValue = false,
    Flag = "TeleportBehind",
    Callback = function(v)
        teleportBehind = v
    end
})

TabPlayers:CreateButton({
    Name = "Spectate",
    Callback = function()
        if selectedPlayer then
            Camera.CameraSubject = selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("Humanoid")
        end
    end
})

TabPlayers:CreateButton({
    Name = "Unspectate",
    Callback = function()
        Camera.CameraSubject = Humanoid
    end
})

-- ==================== WAYPOINTS ====================
local savedWaypoints = {}
local waypointName = "Waypoint1"

TabWaypoints:CreateSection("Waypoints")

TabWaypoints:CreateInput({
    Name = "Nome do Waypoint",
    PlaceholderText = "Waypoint1",
    RemoveTextAfterFocusLost = false,
    Flag = "WaypointName",
    Callback = function(text)
        waypointName = text
    end
})

TabWaypoints:CreateButton({
    Name = "Salvar Posição",
    Callback = function()
        if HRP then
            savedWaypoints[waypointName] = HRP.CFrame
            Rayfield:Notify({
                Title = "Waypoint Salvo",
                Content = waypointName .. " foi salvo!",
                Duration = 2
            })
        end
    end
})

TabWaypoints:CreateButton({
    Name = "Teleportar",
    Callback = function()
        if savedWaypoints[waypointName] and HRP then
            HRP.CFrame = savedWaypoints[waypointName]
        end
    end
})

TabWaypoints:CreateButton({
    Name = "Deletar",
    Callback = function()
        savedWaypoints[waypointName] = nil
    end
})

-- ==================== VISUALS ====================
TabVisuals:CreateSection("Lighting")

TabVisuals:CreateSlider({
    Name = "Brightness",
    Range = {0, 5},
    Increment = 0.1,
    CurrentValue = 1,
    Flag = "Brightness",
    Callback = function(v)
        Lighting.Brightness = v
    end
})

TabVisuals:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Flag = "Fullbright",
    Callback = function(v)
        if v then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
        else
            Lighting.Brightness = 1
            Lighting.ClockTime = 12
            Lighting.GlobalShadows = true
        end
    end
})

TabVisuals:CreateSection("FOV")

TabVisuals:CreateSlider({
    Name = "Field of View",
    Range = {70, 120},
    Increment = 1,
    CurrentValue = 70,
    Flag = "FOV",
    Callback = function(v)
        Camera.FieldOfView = v
    end
})

-- ==================== WORLD ====================
TabWorld:CreateSection("Time")

TabWorld:CreateSlider({
    Name = "Hora do Dia",
    Range = {0, 24},
    Increment = 0.5,
    CurrentValue = 12,
    Flag = "TimeOfDay",
    Callback = function(v)
        Lighting.ClockTime = v
    end
})

TabWorld:CreateSection("Weather")

TabWorld:CreateButton({
    Name = "Remover Névoa",
    Callback = function()
        Lighting.FogEnd = 100000
    end
})

-- ==================== FPS/STATS ====================
local ANTI_LAG_ENABLED = false
local noclip = false

TabFPS:CreateSection("Performance")

local function applyAntiLag()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.Material = Enum.Material.Plastic
            obj.Reflectance = 0
        end
    end
end

TabFPS:CreateToggle({
    Name = "Anti-Lag",
    CurrentValue = false,
    Flag = "AntiLag",
    Callback = function(v)
        ANTI_LAG_ENABLED = v
        if v then applyAntiLag() end
    end
})

TabFPS:CreateSlider({
    Name = "FPS Cap",
    Range = {60, 240},
    Increment = 10,
    CurrentValue = 60,
    Flag = "FPSCap",
    Callback = function(v)
        setfpscap(v)
    end
})

TabFPS:CreateSection("Stats")

local statsLabel = TabFPS:CreateLabel("HP: 0/0 | Speed: 0 | Jump: 0")
local fpsLabel = TabFPS:CreateLabel("FPS: 0")
local pingLabel = TabFPS:CreateLabel("Ping: 0ms")

task.spawn(function()
    while task.wait(0.5) do
        if Character and Humanoid and HRP then
            statsLabel:Set(string.format("HP: %d/%d | Speed: %d | Jump: %d",
                math.floor(Humanoid.Health),
                math.floor(Humanoid.MaxHealth),
                math.floor(Humanoid.WalkSpeed),
                math.floor(Humanoid.JumpPower)
            ))
        end
    end
end)

local fpsCounter = 0
local lastFPSUpdate = tick()

RunService.RenderStepped:Connect(function()
    fpsCounter = fpsCounter + 1
    if tick() - lastFPSUpdate >= 1 then
        fpsLabel:Set("FPS: " .. fpsCounter)
        fpsCounter = 0
        lastFPSUpdate = tick()
    end
end)

task.spawn(function()
    while task.wait(2) do
        local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
        pingLabel:Set(string.format("Ping: %.0f ms", ping))
    end
end)

-- ==================== CONFIG ====================
TabConfig:CreateSection("Anti AFK")

local ANTI_AFK_ENABLED = false

local VirtualUser = game:GetService("VirtualUser")
LP.Idled:Connect(function()
    if ANTI_AFK_ENABLED then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

TabConfig:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(v)
        ANTI_AFK_ENABLED = v
    end
})

TabConfig:CreateSection("GUI")

TabConfig:CreateButton({
    Name = "Destruir GUI",
    Callback = function()
        clearAllESP()
        removeAllHighlights()
        Rayfield:Destroy()
    end
})

-- ==================== UTILITY ====================
TabUtil:CreateSection("Noclip")

TabUtil:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(v)
        noclip = v
    end
})

TabUtil:CreateSection("Server")

TabUtil:CreateButton({
    Name = "Rejoin",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LP)
    end
})

TabUtil:CreateButton({
    Name = "Server Hop",
    Callback = function()
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
        for _, s in pairs(servers.data) do
            if s.playing < s.maxPlayers then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LP)
                break
            end
        end
    end
})

-- ==================== RUNTIME LOOP ====================
local lastRuntimeUpdate = 0
RunService.RenderStepped:Connect(function(dt)
    if not Character or not HRP or not Humanoid then return end

    local now = tick()
    if now - lastRuntimeUpdate < 0.033 then return end
    lastRuntimeUpdate = now

    if flyUpImpulse > 0 then
        flyUpImpulse = flyUpImpulse - dt
    end

    if fly then
        if not HRP:FindFirstChild("FlyVel") then
            local bv = Instance.new("BodyVelocity", HRP)
            bv.Name = "FlyVel"
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            local bg = Instance.new("BodyGyro", HRP)
            bg.Name = "FlyGyro"
            bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        end
        local dir = Humanoid.MoveDirection
        local vel = Vector3.new(dir.X, 0, dir.Z) * flySpeed
        if flyUpImpulse > 0 then
            vel = vel + Vector3.new(0, flySpeed, 0)
        end
        HRP.FlyVel.Velocity = vel
        HRP.FlyGyro.CFrame = Camera.CFrame
    end

    if noclip then
        for _, p in pairs(Character:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
            end
        end
    end

    if godMode then
        Humanoid.MaxHealth = math.huge
        Humanoid.Health = Humanoid.MaxHealth
    elseif lockHP then
        Humanoid.Health = Humanoid.MaxHealth
    end

    if antiVoid and HRP.Position.Y < -80 then
        HRP.CFrame = HRP.CFrame + Vector3.new(0, 200, 0)
    end

    if antiKB then
        HRP.Velocity = HRP.Velocity * Vector3.new(0.8, 0.9, 0.8)
    end
end)

print("✅ Universal Hub - Sistema Completo e Funcional!")
print("🎯 Aim Assist com filtro de times CORRIGIDO!")
print("📋 Filtros disponíveis: All, Team, Enemy")
