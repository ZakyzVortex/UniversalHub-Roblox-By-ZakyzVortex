-- ================== UNIVERSAL HUB - ORGANIZED VERSION (FIXED) ==================
-- Universal Hub Rayfield By ZakyzVortex (Mobile Optimized & Organized)

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- ================== SERVICES ==================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ================== CHARACTER REFS ==================
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

-- ================== WINDOW ==================
local Window = Rayfield:CreateWindow({
    Name = "Universal Hub",
    LoadingTitle = "Universal Hub",
    LoadingSubtitle = "By ZakyzVortex",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "UniversalHub",
        FileName = "Config"
    }
})

-- ================== CREATE TABS ==================
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

-- ==================================================================================
-- ============================== MOVEMENT TAB ======================================
-- ==================================================================================

TabMove:CreateSection("Velocidade e Pulo")

-- Estados
local fly, flySpeed, flyUpImpulse = false, 100, 0
local infJump, antiFall = false, false

-- Velocidade
TabMove:CreateSlider({
    Name = "Velocidade de Caminhada",
    Range = {16, 300},
    Increment = 5,
    CurrentValue = 16,
    Callback = function(v)
        if Humanoid then
            Humanoid.WalkSpeed = v
        end
    end
})

-- Pulo
TabMove:CreateSlider({
    Name = "Poder de Pulo",
    Range = {50, 300},
    Increment = 10,
    CurrentValue = 50,
    Callback = function(v)
        if Humanoid then
            Humanoid.UseJumpPower = true
            Humanoid.JumpPower = v
        end
    end
})

TabMove:CreateSection("Fly System")

-- Fly Speed
TabMove:CreateSlider({
    Name = "Velocidade de Voo",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = 100,
    Callback = function(v)
        flySpeed = v
    end
})

-- Fly Toggle
TabMove:CreateToggle({
    Name = "Ativar Fly",
    CurrentValue = false,
    Callback = function(v)
        fly = v
        if not v and HRP then
            for _, i in pairs({"FlyVel", "FlyGyro"}) do
                local o = HRP:FindFirstChild(i)
                if o then
                    o:Destroy()
                end
            end
        end
    end
})

TabMove:CreateSection("Outros")

-- Infinite Jump
TabMove:CreateToggle({
    Name = "Pulo Infinito",
    CurrentValue = false,
    Callback = function(v)
        infJump = v
    end
})

-- Anti Fall
TabMove:CreateToggle({
    Name = "Anti Queda",
    CurrentValue = false,
    Callback = function(v)
        antiFall = v
    end
})

-- Jump Request Handler
UserInputService.JumpRequest:Connect(function()
    if fly then
        flyUpImpulse = 0.18
    end
    if infJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ==================================================================================
-- ================================ COMBAT TAB ======================================
-- ==================================================================================

TabCombat:CreateSection("Auto Clicker")

-- Estados
local AUTO_CLICKER_ENABLED = false
local AUTO_CLICKER_CPS = 10
local lastClick = 0

-- Função de clique
local function performClick()
    if not AUTO_CLICKER_ENABLED then return end
    mouse1click()
end

-- Toggle Auto Clicker
TabCombat:CreateToggle({
    Name = "Ativar Auto Clicker",
    CurrentValue = false,
    Callback = function(v)
        AUTO_CLICKER_ENABLED = v
    end
})

-- CPS Slider
TabCombat:CreateSlider({
    Name = "CPS (Cliques por Segundo)",
    Range = {1, 50},
    Increment = 1,
    CurrentValue = 10,
    Callback = function(v)
        AUTO_CLICKER_CPS = v
    end
})

-- Auto Clicker Loop
RunService.RenderStepped:Connect(function()
    if not AUTO_CLICKER_ENABLED then return end
    
    local now = tick()
    local clickInterval = 1 / AUTO_CLICKER_CPS
    
    if now - lastClick >= clickInterval then
        performClick()
        lastClick = now
    end
end)

TabCombat:CreateSection("Hit Range Extender")

-- Estados
local HIT_RANGE_ENABLED = false
local HIT_RANGE_SIZE = 10
local originalSizes = {}

-- Função para estender hitboxes
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

-- Toggle Hit Range
TabCombat:CreateToggle({
    Name = "Ativar Hit Range Extender",
    CurrentValue = false,
    Callback = function(v)
        HIT_RANGE_ENABLED = v
        extendHitboxes()
    end
})

-- Size Slider
TabCombat:CreateSlider({
    Name = "Tamanho da Hitbox",
    Range = {5, 30},
    Increment = 1,
    CurrentValue = 10,
    Callback = function(v)
        HIT_RANGE_SIZE = v
        extendHitboxes()
    end
})

-- Loop contínuo para hitboxes
RunService.Heartbeat:Connect(function()
    if HIT_RANGE_ENABLED then
        extendHitboxes()
    end
end)

-- ==================================================================================
-- ================================== ESP TAB =======================================
-- ==================================================================================

-- Estados
local ESP_ENABLED = false
local NAME_ENABLED = true
local DISTANCE_ENABLED = true
local LINE_ENABLED = true
local HEALTH_ENABLED = true
local OUTLINE_ENABLED = true

local ESP_COLOR = Color3.fromRGB(255, 0, 0)
local LINE_COLOR = Color3.fromRGB(255, 255, 255)

local ESP_OBJECTS = {}
local TEAM_FILTER = "All"  -- All, Team, Enemy

-- Funções auxiliares
local function getPlayerTeam(player)
    return player.Team and player.Team.Name or "NoTeam"
end

local function isPlayerOnSameTeam(player)
    if not LP.Team then return false end
    return player.Team == LP.Team
end

local function shouldShowESPForPlayer(player)
    if TEAM_FILTER == "All" then
        return true
    elseif TEAM_FILTER == "Team" then
        return isPlayerOnSameTeam(player)
    elseif TEAM_FILTER == "Enemy" then
        return not isPlayerOnSameTeam(player)
    end
    return true
end

-- Função para remover ESP de um jogador
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

-- Função para criar ESP para um jogador
local function createESP(player)
    if player == LP then return end
    if not player.Character then return end
    if not shouldShowESPForPlayer(player) then return end
    
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    local head = player.Character:FindFirstChild("Head")
    local hum = player.Character:FindFirstChild("Humanoid")
    
    if not hrp or not head then return end
    
    local espData = {
        active = true,
        player = player,
        nameLabel = nil,
        distLabel = nil,
        healthLabel = nil,
        tracerLine = nil,
        boxOutline = nil
    }
    
    -- Nome
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
    
    -- Distância
    if DISTANCE_ENABLED then
        local distLabel = Drawing.new("Text")
        distLabel.Visible = true
        distLabel.Center = true
        distLabel.Outline = true
        distLabel.Color = Color3.fromRGB(255, 255, 255)
        distLabel.Size = 14
        distLabel.Text = "0m"
        espData.distLabel = distLabel
    end
    
    -- Health
    if HEALTH_ENABLED and hum then
        local healthLabel = Drawing.new("Text")
        healthLabel.Visible = true
        healthLabel.Center = true
        healthLabel.Outline = true
        healthLabel.Color = Color3.fromRGB(0, 255, 0)
        healthLabel.Size = 14
        healthLabel.Text = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
        espData.healthLabel = healthLabel
    end
    
    -- Linha (Tracer)
    if LINE_ENABLED then
        local tracerLine = Drawing.new("Line")
        tracerLine.Visible = true
        tracerLine.Color = LINE_COLOR
        tracerLine.Thickness = 1
        espData.tracerLine = tracerLine
    end
    
    -- Box Outline
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

-- Função para atualizar ESP
local function updateESP(player)
    local espData = ESP_OBJECTS[player]
    if not espData or not espData.active then return end
    if not player.Character then return end
    if not shouldShowESPForPlayer(player) then
        removeESP(player)
        return
    end
    
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    local head = player.Character:FindFirstChild("Head")
    local hum = player.Character:FindFirstChild("Humanoid")
    
    if not hrp or not head then
        removeESP(player)
        return
    end
    
    -- Posições 2D
    local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
    local hrpPos = Camera:WorldToViewportPoint(hrp.Position)
    
    if not onScreen then
        if espData.nameLabel then espData.nameLabel.Visible = false end
        if espData.distLabel then espData.distLabel.Visible = false end
        if espData.healthLabel then espData.healthLabel.Visible = false end
        if espData.tracerLine then espData.tracerLine.Visible = false end
        if espData.boxOutline then espData.boxOutline.Visible = false end
        return
    end
    
    -- Distância
    local distance = (HRP.Position - hrp.Position).Magnitude
    
    -- Nome
    if espData.nameLabel then
        espData.nameLabel.Position = Vector2.new(headPos.X, headPos.Y - 30)
        espData.nameLabel.Visible = true
    end
    
    -- Distância
    if espData.distLabel then
        espData.distLabel.Position = Vector2.new(headPos.X, headPos.Y - 15)
        espData.distLabel.Text = math.floor(distance) .. "m"
        espData.distLabel.Visible = true
    end
    
    -- Health
    if espData.healthLabel and hum then
        espData.healthLabel.Position = Vector2.new(headPos.X, headPos.Y)
        espData.healthLabel.Text = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
        espData.healthLabel.Visible = true
    end
    
    -- Linha
    if espData.tracerLine then
        espData.tracerLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        espData.tracerLine.To = Vector2.new(hrpPos.X, hrpPos.Y)
        espData.tracerLine.Visible = true
    end
    
    -- Box
    if espData.boxOutline then
        local size = (Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0)).Y - Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.5, 0)).Y)
        espData.boxOutline.Size = Vector2.new(size * 1.5, size)
        espData.boxOutline.Position = Vector2.new(hrpPos.X - size * 0.75, hrpPos.Y - size * 0.5)
        espData.boxOutline.Visible = true
    end
end

-- Função para limpar todo ESP
local function clearAllESP()
    for player, _ in pairs(ESP_OBJECTS) do
        removeESP(player)
    end
    ESP_OBJECTS = {}
end

-- Função para atualizar ESP de todos os jogadores
local function refreshESP()
    clearAllESP()
    if not ESP_ENABLED then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            createESP(player)
        end
    end
end

-- Loop de atualização
RunService.RenderStepped:Connect(function()
    if not ESP_ENABLED then return end
    
    for player, espData in pairs(ESP_OBJECTS) do
        if player and player.Parent and player.Character then
            updateESP(player)
        else
            removeESP(player)
        end
    end
end)

-- Eventos de jogadores
Players.PlayerAdded:Connect(function(player)
    if ESP_ENABLED and player ~= LP then
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            createESP(player)
        end)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

-- UI do ESP
TabESP:CreateSection("ESP Configuration")

TabESP:CreateToggle({
    Name = "Ativar ESP",
    CurrentValue = false,
    Callback = function(v)
        ESP_ENABLED = v
        refreshESP()
    end
})

-- NOVO: Dropdown para seleção de time
TabESP:CreateDropdown({
    Name = "Filtro de Time",
    Options = {"All", "Team", "Enemy"},
    CurrentOption = "All",
    Callback = function(option)
        TEAM_FILTER = option
        refreshESP()
    end
})

TabESP:CreateSection("ESP Elements")

TabESP:CreateToggle({
    Name = "Mostrar Nome",
    CurrentValue = true,
    Callback = function(v)
        NAME_ENABLED = v
        refreshESP()
    end
})

TabESP:CreateToggle({
    Name = "Mostrar Distância",
    CurrentValue = true,
    Callback = function(v)
        DISTANCE_ENABLED = v
        refreshESP()
    end
})

TabESP:CreateToggle({
    Name = "Mostrar Health",
    CurrentValue = true,
    Callback = function(v)
        HEALTH_ENABLED = v
        refreshESP()
    end
})

TabESP:CreateToggle({
    Name = "Mostrar Linha",
    CurrentValue = true,
    Callback = function(v)
        LINE_ENABLED = v
        refreshESP()
    end
})

TabESP:CreateToggle({
    Name = "Mostrar Box",
    CurrentValue = true,
    Callback = function(v)
        OUTLINE_ENABLED = v
        refreshESP()
    end
})

TabESP:CreateSection("Colors")

TabESP:CreateColorPicker({
    Name = "Cor do ESP",
    Color = Color3.fromRGB(255, 0, 0),
    Callback = function(color)
        ESP_COLOR = color
        refreshESP()
    end
})

TabESP:CreateColorPicker({
    Name = "Cor da Linha",
    Color = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        LINE_COLOR = color
        refreshESP()
    end
})

-- ==================================================================================
-- ============================== HIGHLIGHT ESP TAB =================================
-- ==================================================================================

local HIGHLIGHT_ENABLED = false
local HIGHLIGHT_FILL_COLOR = Color3.fromRGB(255, 0, 0)
local HIGHLIGHT_OUTLINE_COLOR = Color3.fromRGB(255, 255, 255)
local HIGHLIGHT_FILL_TRANSPARENCY = 0.5
local HIGHLIGHT_OUTLINE_TRANSPARENCY = 0
local HIGHLIGHT_TEAM_FILTER = "All"  -- All, Team, Enemy

local HIGHLIGHT_OBJECTS = {}

local function shouldShowHighlightForPlayer(player)
    if HIGHLIGHT_TEAM_FILTER == "All" then
        return true
    elseif HIGHLIGHT_TEAM_FILTER == "Team" then
        return isPlayerOnSameTeam(player)
    elseif HIGHLIGHT_TEAM_FILTER == "Enemy" then
        return not isPlayerOnSameTeam(player)
    end
    return true
end

local function removeHighlight(player)
    if HIGHLIGHT_OBJECTS[player] then
        HIGHLIGHT_OBJECTS[player]:Destroy()
        HIGHLIGHT_OBJECTS[player] = nil
    end
end

local function createHighlight(player)
    if player == LP then return end
    if not player.Character then return end
    if not shouldShowHighlightForPlayer(player) then return end
    
    removeHighlight(player)
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight"
    highlight.FillColor = HIGHLIGHT_FILL_COLOR
    highlight.OutlineColor = HIGHLIGHT_OUTLINE_COLOR
    highlight.FillTransparency = HIGHLIGHT_FILL_TRANSPARENCY
    highlight.OutlineTransparency = HIGHLIGHT_OUTLINE_TRANSPARENCY
    highlight.Adornee = player.Character
    highlight.Parent = player.Character
    
    HIGHLIGHT_OBJECTS[player] = highlight
end

local function updateHighlightColors()
    for player, highlight in pairs(HIGHLIGHT_OBJECTS) do
        if highlight and highlight.Parent then
            highlight.FillColor = HIGHLIGHT_FILL_COLOR
            highlight.OutlineColor = HIGHLIGHT_OUTLINE_COLOR
            highlight.FillTransparency = HIGHLIGHT_FILL_TRANSPARENCY
            highlight.OutlineTransparency = HIGHLIGHT_OUTLINE_TRANSPARENCY
        end
    end
end

local function removeAllHighlights()
    for player, _ in pairs(HIGHLIGHT_OBJECTS) do
        removeHighlight(player)
    end
    HIGHLIGHT_OBJECTS = {}
end

local function refreshHighlights()
    removeAllHighlights()
    if not HIGHLIGHT_ENABLED then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            createHighlight(player)
        end
    end
end

-- Monitorar mudanças nos jogadores
Players.PlayerAdded:Connect(function(player)
    if HIGHLIGHT_ENABLED and player ~= LP then
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            createHighlight(player)
        end)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeHighlight(player)
end)

-- Loop de verificação
RunService.Heartbeat:Connect(function()
    if not HIGHLIGHT_ENABLED then return end
    
    for player, highlight in pairs(HIGHLIGHT_OBJECTS) do
        if not player or not player.Parent or not player.Character or not shouldShowHighlightForPlayer(player) then
            removeHighlight(player)
        elseif not highlight or not highlight.Parent then
            createHighlight(player)
        end
    end
end)

-- UI do Highlight ESP
TabHighlight:CreateSection("Highlight ESP Configuration")

TabHighlight:CreateToggle({
    Name = "Ativar Highlight ESP",
    CurrentValue = false,
    Callback = function(v)
        HIGHLIGHT_ENABLED = v
        refreshHighlights()
    end
})

-- NOVO: Dropdown para seleção de time no Highlight
TabHighlight:CreateDropdown({
    Name = "Filtro de Time",
    Options = {"All", "Team", "Enemy"},
    CurrentOption = "All",
    Callback = function(option)
        HIGHLIGHT_TEAM_FILTER = option
        refreshHighlights()
    end
})

TabHighlight:CreateSection("Colors")

TabHighlight:CreateColorPicker({
    Name = "Cor de Preenchimento",
    Color = Color3.fromRGB(255, 0, 0),
    Callback = function(color)
        HIGHLIGHT_FILL_COLOR = color
        updateHighlightColors()
    end
})

TabHighlight:CreateColorPicker({
    Name = "Cor do Contorno",
    Color = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        HIGHLIGHT_OUTLINE_COLOR = color
        updateHighlightColors()
    end
})

TabHighlight:CreateSection("Transparency")

TabHighlight:CreateSlider({
    Name = "Transparência do Preenchimento",
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = 0.5,
    Callback = function(v)
        HIGHLIGHT_FILL_TRANSPARENCY = v
        updateHighlightColors()
    end
})

TabHighlight:CreateSlider({
    Name = "Transparência do Contorno",
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = 0,
    Callback = function(v)
        HIGHLIGHT_OUTLINE_TRANSPARENCY = v
        updateHighlightColors()
    end
})

-- ==================================================================================
-- ============================== AIM ASSIST TAB ====================================
-- ==================================================================================

local AIM_ENABLED = false
local AIM_SMOOTHNESS = 0.15
local AIM_FOV = 150
local AIM_SHOW_FOV = true
local AIM_PART = "Head"
local AIM_TEAM_FILTER = "All"  -- All, Team, Enemy

local fovCircle

local function shouldAimAtPlayer(player)
    if AIM_TEAM_FILTER == "All" then
        return true
    elseif AIM_TEAM_FILTER == "Team" then
        return isPlayerOnSameTeam(player)
    elseif AIM_TEAM_FILTER == "Enemy" then
        return not isPlayerOnSameTeam(player)
    end
    return true
end

local function getClosestPlayerInFOV()
    local closestPlayer = nil
    local shortestDistance = AIM_FOV
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character and shouldAimAtPlayer(player) then
            local targetPart = player.Character:FindFirstChild(AIM_PART)
            if targetPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    
                    if distance < shortestDistance then
                        closestPlayer = player
                        shortestDistance = distance
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

local function aimAtPlayer(player)
    if not player or not player.Character then return end
    
    local targetPart = player.Character:FindFirstChild(AIM_PART)
    if not targetPart then return end
    
    local targetPos = Camera:WorldToViewportPoint(targetPart.Position)
    local mousePos = UserInputService:GetMouseLocation()
    
    local deltaX = (targetPos.X - mousePos.X) * AIM_SMOOTHNESS
    local deltaY = (targetPos.Y - mousePos.Y) * AIM_SMOOTHNESS
    
    mousemoverel(deltaX, deltaY)
end

-- FOV Circle
local function createFOVCircle()
    if fovCircle then fovCircle:Remove() end
    
    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 2
    fovCircle.NumSides = 50
    fovCircle.Radius = AIM_FOV
    fovCircle.Filled = false
    fovCircle.Color = Color3.fromRGB(255, 255, 255)
    fovCircle.Transparency = 1
    fovCircle.Visible = AIM_SHOW_FOV
end

createFOVCircle()

-- Aim Loop
RunService.RenderStepped:Connect(function()
    if fovCircle then
        local mousePos = UserInputService:GetMouseLocation()
        fovCircle.Position = mousePos
        fovCircle.Radius = AIM_FOV
        fovCircle.Visible = AIM_SHOW_FOV and AIM_ENABLED
    end
    
    if not AIM_ENABLED then return end
    
    local target = getClosestPlayerInFOV()
    if target then
        aimAtPlayer(target)
    end
end)

-- UI do Aim Assist
TabAim:CreateSection("Aim Assist Configuration")

TabAim:CreateToggle({
    Name = "Ativar Aim Assist",
    CurrentValue = false,
    Callback = function(v)
        AIM_ENABLED = v
    end
})

-- NOVO: Dropdown para seleção de time no Aim
TabAim:CreateDropdown({
    Name = "Filtro de Time",
    Options = {"All", "Team", "Enemy"},
    CurrentOption = "All",
    Callback = function(option)
        AIM_TEAM_FILTER = option
    end
})

TabAim:CreateSection("Settings")

TabAim:CreateSlider({
    Name = "Suavidade",
    Range = {0.01, 1},
    Increment = 0.01,
    CurrentValue = 0.15,
    Callback = function(v)
        AIM_SMOOTHNESS = v
    end
})

TabAim:CreateSlider({
    Name = "FOV (Raio)",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = 150,
    Callback = function(v)
        AIM_FOV = v
    end
})

TabAim:CreateToggle({
    Name = "Mostrar FOV Circle",
    CurrentValue = true,
    Callback = function(v)
        AIM_SHOW_FOV = v
    end
})

TabAim:CreateDropdown({
    Name = "Parte do Corpo",
    Options = {"Head", "Torso", "HumanoidRootPart"},
    CurrentOption = "Head",
    Callback = function(option)
        AIM_PART = option
    end
})

-- ==================================================================================
-- ============================== PROTECTION TAB ====================================
-- ==================================================================================

local godMode = false
local lockHP = false
local antiVoid = false
local antiKB = false

TabProt:CreateSection("Health Protection")

TabProt:CreateToggle({
    Name = "God Mode",
    CurrentValue = false,
    Callback = function(v)
        godMode = v
    end
})

TabProt:CreateToggle({
    Name = "Lock HP",
    CurrentValue = false,
    Callback = function(v)
        lockHP = v
    end
})

TabProt:CreateSection("Movement Protection")

TabProt:CreateToggle({
    Name = "Anti Void",
    CurrentValue = false,
    Callback = function(v)
        antiVoid = v
    end
})

TabProt:CreateToggle({
    Name = "Anti Knockback",
    CurrentValue = false,
    Callback = function(v)
        antiKB = v
    end
})

-- ==================================================================================
-- ================================ PLAYERS TAB =====================================
-- ==================================================================================

TabPlayers:CreateSection("Player List")

local selectedPlayer = nil

local playerNames = {}
local function updatePlayerList()
    playerNames = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            table.insert(playerNames, p.Name)
        end
    end
    return playerNames
end

local playerDropdown = TabPlayers:CreateDropdown({
    Name = "Selecionar Jogador",
    Options = updatePlayerList(),
    CurrentOption = "",
    Callback = function(option)
        selectedPlayer = Players:FindFirstChild(option)
    end
})

Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    playerDropdown:Refresh(updatePlayerList())
end)

Players.PlayerRemoving:Connect(function()
    task.wait(0.5)
    playerDropdown:Refresh(updatePlayerList())
end)

TabPlayers:CreateSection("Player Actions")

TabPlayers:CreateButton({
    Name = "Teleportar para Jogador",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character and HRP then
            local targetHRP = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                HRP.CFrame = targetHRP.CFrame
            end
        end
    end
})

TabPlayers:CreateButton({
    Name = "Trazer Jogador",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character and HRP then
            local targetHRP = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                targetHRP.CFrame = HRP.CFrame
            end
        end
    end
})

TabPlayers:CreateButton({
    Name = "Espiar Jogador",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character then
            Camera.CameraSubject = selectedPlayer.Character:FindFirstChild("Humanoid")
        end
    end
})

TabPlayers:CreateButton({
    Name = "Voltar para Si Mesmo",
    Callback = function()
        if Humanoid then
            Camera.CameraSubject = Humanoid
        end
    end
})

-- ==================================================================================
-- ============================== WAYPOINTS TAB =====================================
-- ==================================================================================

local savedWaypoints = {}

TabWaypoints:CreateSection("Waypoint Management")

local waypointName = "Waypoint1"

TabWaypoints:CreateInput({
    Name = "Nome do Waypoint",
    PlaceholderText = "Waypoint1",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        waypointName = text
    end
})

TabWaypoints:CreateButton({
    Name = "Salvar Posição Atual",
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
    Name = "Teleportar para Waypoint",
    Callback = function()
        if savedWaypoints[waypointName] and HRP then
            HRP.CFrame = savedWaypoints[waypointName]
            Rayfield:Notify({
                Title = "Teleportado",
                Content = "Teleportado para " .. waypointName,
                Duration = 2
            })
        else
            Rayfield:Notify({
                Title = "Erro",
                Content = "Waypoint não encontrado!",
                Duration = 3
            })
        end
    end
})

TabWaypoints:CreateButton({
    Name = "Deletar Waypoint",
    Callback = function()
        if savedWaypoints[waypointName] then
            savedWaypoints[waypointName] = nil
            Rayfield:Notify({
                Title = "Deletado",
                Content = waypointName .. " foi deletado!",
                Duration = 2
            })
        end
    end
})

TabWaypoints:CreateSection("Quick Waypoints")

local waypointList = {}
local function updateWaypointList()
    waypointList = {}
    for name, _ in pairs(savedWaypoints) do
        table.insert(waypointList, name)
    end
    return waypointList
end

local waypointDropdown = TabWaypoints:CreateDropdown({
    Name = "Waypoints Salvos",
    Options = updateWaypointList(),
    CurrentOption = "",
    Callback = function(option)
        waypointName = option
    end
})

-- ==================================================================================
-- ================================ VISUALS TAB =====================================
-- ==================================================================================

TabVisuals:CreateSection("Lighting")

TabVisuals:CreateSlider({
    Name = "Brightness",
    Range = {0, 5},
    Increment = 0.1,
    CurrentValue = 1,
    Callback = function(v)
        Lighting.Brightness = v
    end
})

TabVisuals:CreateSlider({
    Name = "Ambient",
    Range = {0, 255},
    Increment = 1,
    CurrentValue = 127,
    Callback = function(v)
        Lighting.Ambient = Color3.fromRGB(v, v, v)
    end
})

TabVisuals:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Callback = function(v)
        if v then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        else
            Lighting.Brightness = 1
            Lighting.ClockTime = 12
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = true
            Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)
        end
    end
})

TabVisuals:CreateSection("FOV")

TabVisuals:CreateSlider({
    Name = "Field of View",
    Range = {70, 120},
    Increment = 1,
    CurrentValue = 70,
    Callback = function(v)
        Camera.FieldOfView = v
    end
})

-- ==================================================================================
-- ================================== WORLD TAB =====================================
-- ==================================================================================

TabWorld:CreateSection("Time")

TabWorld:CreateSlider({
    Name = "Hora do Dia",
    Range = {0, 24},
    Increment = 0.5,
    CurrentValue = 12,
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

TabWorld:CreateButton({
    Name = "Remover Chuva/Neve",
    Callback = function()
        for _, effect in pairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") then
                effect.Enabled = false
            end
        end
    end
})

-- ==================================================================================
-- ================================ FPS/STATS TAB ===================================
-- ==================================================================================

local ANTI_LAG_ENABLED = false
local noclip = false

TabFPS:CreateSection("Performance")

local function applyAntiLag()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local part = obj
            part.Material = Enum.Material.Plastic
            part.Reflectance = 0
        end
    end
end

TabFPS:CreateToggle({
    Name = "Ativar Anti-Lag",
    CurrentValue = false,
    Callback = function(v)
        ANTI_LAG_ENABLED = v
        if v then
            applyAntiLag()
        end
    end
})

TabFPS:CreateSlider({
    Name = "FPS Cap",
    Range = {60, 240},
    Increment = 10,
    CurrentValue = 60,
    Callback = function(v)
        setfpscap(v)
    end
})

TabFPS:CreateSection("Stats")

local statsLabel = TabFPS:CreateLabel("Carregando...")
local fpsLabel = TabFPS:CreateLabel("FPS: 0")
local pingLabel = TabFPS:CreateLabel("Ping: 0ms")
local playersLabel = TabFPS:CreateLabel("Players: 0")

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

task.spawn(function()
    while task.wait(1) do
        playersLabel:Set(string.format("Players: %d/%d", #Players:GetPlayers(), Players.MaxPlayers))
    end
end)

-- ==================================================================================
-- ================================ CONFIG TAB ======================================
-- ==================================================================================

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
    Callback = function(v)
        ANTI_AFK_ENABLED = v
    end
})

TabConfig:CreateSection("Configs")

local configName = "default"

TabConfig:CreateInput({
    Name = "Nome da Config",
    PlaceholderText = "default",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        configName = text
    end
})

TabConfig:CreateButton({
    Name = "Salvar Config",
    Callback = function()
        local config = {
            WalkSpeed = Humanoid and Humanoid.WalkSpeed or 16,
            JumpPower = Humanoid and Humanoid.JumpPower or 50,
            savedWaypoints = savedWaypoints
        }
        writefile("UniversalHub_"..configName..".json", HttpService:JSONEncode(config))
        Rayfield:Notify({Title = "Config Salva", Content = "Config salva!", Duration = 2})
    end
})

TabConfig:CreateButton({
    Name = "Carregar Config",
    Callback = function()
        local success, result = pcall(function()
            return readfile("UniversalHub_"..configName..".json")
        end)
        
        if success then
            local config = HttpService:JSONDecode(result)
            if Humanoid then
                Humanoid.WalkSpeed = config.WalkSpeed or 16
                Humanoid.JumpPower = config.JumpPower or 50
            end
            if config.savedWaypoints then
                savedWaypoints = config.savedWaypoints
            end
            Rayfield:Notify({Title = "Config Carregada", Content = "Config carregada!", Duration = 2})
        else
            Rayfield:Notify({Title = "Erro", Content = "Config não encontrada!", Duration = 3})
        end
    end
})

TabConfig:CreateSection("Keybinds")

local keybindESP = Enum.KeyCode.E
local keybindAim = Enum.KeyCode.R
local keybindGUI = Enum.KeyCode.RightControl

TabConfig:CreateKeybind({
    Name = "Toggle ESP",
    CurrentKeybind = "E",
    HoldToInteract = false,
    Callback = function(key)
        keybindESP = key
    end
})

TabConfig:CreateKeybind({
    Name = "Toggle Aim",
    CurrentKeybind = "R",
    HoldToInteract = false,
    Callback = function(key)
        keybindAim = key
    end
})

TabConfig:CreateKeybind({
    Name = "Toggle GUI",
    CurrentKeybind = "RightControl",
    HoldToInteract = false,
    Callback = function(key)
        keybindGUI = key
    end
})

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == keybindESP then
        ESP_ENABLED = not ESP_ENABLED
        refreshESP()
    elseif input.KeyCode == keybindAim then
        AIM_ENABLED = not AIM_ENABLED
    elseif input.KeyCode == keybindGUI then
        Rayfield:Toggle()
    end
end)

TabConfig:CreateSection("GUI")

TabConfig:CreateButton({
    Name = "Destruir GUI",
    Callback = function()
        clearAllESP()
        removeAllHighlights()
        Rayfield:Destroy()
    end
})

-- ==================================================================================
-- =============================== UTILITY TAB ======================================
-- ==================================================================================

TabUtil:CreateSection("Noclip")

TabUtil:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
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

-- ==================================================================================
-- ============================== RUNTIME LOOP ======================================
-- ==================================================================================

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

print("✅ Universal Hub - Organizado e 100% Funcional com Sistema de Times!")
