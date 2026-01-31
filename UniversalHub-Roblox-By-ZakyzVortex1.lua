-- ================== UNIVERSAL HUB - ORGANIZED VERSION (FIXED) ==================
-- Universal Hub Rayfield By ZakyzVortex (Mobile Optimized & Organized)

-- Verificar se o jogo possui as capacidades necessárias
if not game:GetService("HttpService").HttpEnabled then
    warn("HttpService não está habilitado!")
end

-- Carregar Rayfield com proteção de erro
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)

if not success or not Rayfield then
    error("❌ Falha ao carregar Rayfield! Verifique sua conexão ou o link.")
    return
end

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
    if not char then return end
    Character = char
    Humanoid = char:WaitForChild("Humanoid", 5)
    HRP = char:WaitForChild("HumanoidRootPart", 5)
    if Humanoid then
        Humanoid.UseJumpPower = true
    end
end

-- Esperar personagem com proteção
local function waitForCharacter()
    if LP.Character then
        BindCharacter(LP.Character)
    else
        local char = LP.CharacterAdded:Wait()
        BindCharacter(char)
    end
end

waitForCharacter()
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
local noclip = false

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

-- Função de clique com proteção
local function performClick()
    if not AUTO_CLICKER_ENABLED then return end
    local success = pcall(function()
        mouse1click()
    end)
    if not success then
        warn("mouse1click() não está disponível neste executor")
    end
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
local TEAM_FILTER = "All"

-- Funções auxiliares
local function getPlayerTeam(player)
    return player.Team and player.Team.Name or "NoTeam"
end

-- Função para remover ESP de um jogador
local function removeESP(player)
    local espData = ESP_OBJECTS[player]
    if not espData then return end
    
    espData.active = false
    
    pcall(function()
        if espData.nameLabel then espData.nameLabel:Destroy() end
        if espData.distanceLabel then espData.distanceLabel:Destroy() end
        if espData.healthLabel then espData.healthLabel:Destroy() end
        if espData.line then espData.line:Destroy() end
        if espData.box then espData.box:Destroy() end
    end)
    
    ESP_OBJECTS[player] = nil
end

-- Função para criar ESP para um jogador
local function createESP(player)
    if not player.Character then return end
    if player == LP then return end
    if TEAM_FILTER ~= "All" and getPlayerTeam(player) == getPlayerTeam(LP) then return end
    
    removeESP(player)
    
    local espData = {
        active = true,
        player = player
    }
    
    -- Criar labels e elementos ESP
    if NAME_ENABLED then
        local nameLabel = Drawing.new("Text")
        nameLabel.Text = player.Name
        nameLabel.Color = ESP_COLOR
        nameLabel.Size = 16
        nameLabel.Center = true
        nameLabel.Outline = OUTLINE_ENABLED
        nameLabel.Visible = false
        espData.nameLabel = nameLabel
    end
    
    if DISTANCE_ENABLED then
        local distanceLabel = Drawing.new("Text")
        distanceLabel.Text = ""
        distanceLabel.Color = ESP_COLOR
        distanceLabel.Size = 14
        distanceLabel.Center = true
        distanceLabel.Outline = OUTLINE_ENABLED
        distanceLabel.Visible = false
        espData.distanceLabel = distanceLabel
    end
    
    if HEALTH_ENABLED then
        local healthLabel = Drawing.new("Text")
        healthLabel.Text = ""
        healthLabel.Color = Color3.fromRGB(0, 255, 0)
        healthLabel.Size = 14
        healthLabel.Center = true
        healthLabel.Outline = OUTLINE_ENABLED
        healthLabel.Visible = false
        espData.healthLabel = healthLabel
    end
    
    if LINE_ENABLED then
        local line = Drawing.new("Line")
        line.Color = LINE_COLOR
        line.Thickness = 1
        line.Visible = false
        espData.line = line
    end
    
    ESP_OBJECTS[player] = espData
end

-- Função para atualizar ESP
local function updateESP()
    if not ESP_ENABLED then return end
    
    for player, espData in pairs(ESP_OBJECTS) do
        if not espData.active then continue end
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            removeESP(player)
            continue
        end
        
        local hrp = player.Character.HumanoidRootPart
        local humanoid = player.Character:FindFirstChild("Humanoid")
        
        local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        
        if onScreen and ESP_ENABLED then
            local distance = (HRP.Position - hrp.Position).Magnitude
            
            -- Atualizar nome
            if espData.nameLabel then
                espData.nameLabel.Position = Vector2.new(screenPos.X, screenPos.Y - 40)
                espData.nameLabel.Visible = true
            end
            
            -- Atualizar distância
            if espData.distanceLabel then
                espData.distanceLabel.Text = string.format("%.0f studs", distance)
                espData.distanceLabel.Position = Vector2.new(screenPos.X, screenPos.Y - 25)
                espData.distanceLabel.Visible = true
            end
            
            -- Atualizar saúde
            if espData.healthLabel and humanoid then
                local healthPercent = (humanoid.Health / humanoid.MaxHealth) * 100
                espData.healthLabel.Text = string.format("HP: %.0f%%", healthPercent)
                espData.healthLabel.Position = Vector2.new(screenPos.X, screenPos.Y - 10)
                espData.healthLabel.Color = Color3.fromRGB(
                    255 * (1 - healthPercent / 100),
                    255 * (healthPercent / 100),
                    0
                )
                espData.healthLabel.Visible = true
            end
            
            -- Atualizar linha
            if espData.line then
                local screenSize = Camera.ViewportSize
                espData.line.From = Vector2.new(screenSize.X / 2, screenSize.Y)
                espData.line.To = Vector2.new(screenPos.X, screenPos.Y)
                espData.line.Visible = true
            end
        else
            -- Esconder se fora da tela
            if espData.nameLabel then espData.nameLabel.Visible = false end
            if espData.distanceLabel then espData.distanceLabel.Visible = false end
            if espData.healthLabel then espData.healthLabel.Visible = false end
            if espData.line then espData.line.Visible = false end
        end
    end
end

-- Função para limpar todo ESP
local function clearAllESP()
    for player, _ in pairs(ESP_OBJECTS) do
        removeESP(player)
    end
end

-- Função para atualizar todos ESP
local function refreshESP()
    clearAllESP()
    if ESP_ENABLED then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LP then
                createESP(player)
            end
        end
    end
end

-- Toggle principal do ESP
TabESP:CreateToggle({
    Name = "Ativar ESP",
    CurrentValue = false,
    Callback = function(v)
        ESP_ENABLED = v
        refreshESP()
    end
})

-- Configurações do ESP
TabESP:CreateSection("Opções ESP")

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
    Name = "Mostrar Saúde",
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
    Name = "Contorno",
    CurrentValue = true,
    Callback = function(v)
        OUTLINE_ENABLED = v
        refreshESP()
    end
})

-- Filtro de equipe
TabESP:CreateDropdown({
    Name = "Filtro de Equipe",
    Options = {"All", "Enemy", "Team"},
    CurrentOption = "All",
    Callback = function(option)
        TEAM_FILTER = option
        refreshESP()
    end
})

-- Loop de atualização ESP
RunService.RenderStepped:Connect(updateESP)

-- Eventos de jogadores
Players.PlayerAdded:Connect(function(player)
    if ESP_ENABLED then
        task.wait(1)
        createESP(player)
    end
end)

Players.PlayerRemoving:Connect(removeESP)

-- ==================================================================================
-- ============================ HIGHLIGHT ESP TAB ===================================
-- ==================================================================================

local HIGHLIGHT_ENABLED = false
local HIGHLIGHT_COLOR = Color3.fromRGB(255, 0, 0)
local HIGHLIGHT_FILL_TRANSPARENCY = 0.5
local HIGHLIGHT_OUTLINE_TRANSPARENCY = 0

local highlightObjects = {}

-- Função para criar highlight
local function createHighlight(player)
    if not player.Character then return end
    if player == LP then return end
    
    local char = player.Character
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight"
    highlight.FillColor = HIGHLIGHT_COLOR
    highlight.OutlineColor = HIGHLIGHT_COLOR
    highlight.FillTransparency = HIGHLIGHT_FILL_TRANSPARENCY
    highlight.OutlineTransparency = HIGHLIGHT_OUTLINE_TRANSPARENCY
    highlight.Parent = char
    
    highlightObjects[player] = highlight
end

-- Função para remover highlight
local function removeHighlight(player)
    if highlightObjects[player] then
        pcall(function()
            highlightObjects[player]:Destroy()
        end)
        highlightObjects[player] = nil
    end
end

-- Função para remover todos highlights
local function removeAllHighlights()
    for player, _ in pairs(highlightObjects) do
        removeHighlight(player)
    end
end

-- Função para atualizar highlights
local function refreshHighlights()
    removeAllHighlights()
    if HIGHLIGHT_ENABLED then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LP then
                createHighlight(player)
            end
        end
    end
end

-- Toggle Highlight
TabHighlight:CreateToggle({
    Name = "Ativar Highlight ESP",
    CurrentValue = false,
    Callback = function(v)
        HIGHLIGHT_ENABLED = v
        refreshHighlights()
    end
})

TabHighlight:CreateSection("Configurações")

-- Transparência do preenchimento
TabHighlight:CreateSlider({
    Name = "Transparência Preenchimento",
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = 0.5,
    Callback = function(v)
        HIGHLIGHT_FILL_TRANSPARENCY = v
        for _, highlight in pairs(highlightObjects) do
            highlight.FillTransparency = v
        end
    end
})

-- Transparência da borda
TabHighlight:CreateSlider({
    Name = "Transparência Borda",
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = 0,
    Callback = function(v)
        HIGHLIGHT_OUTLINE_TRANSPARENCY = v
        for _, highlight in pairs(highlightObjects) do
            highlight.OutlineTransparency = v
        end
    end
})

-- Eventos
Players.PlayerAdded:Connect(function(player)
    if HIGHLIGHT_ENABLED then
        player.CharacterAdded:Wait()
        createHighlight(player)
    end
end)

Players.PlayerRemoving:Connect(removeHighlight)

-- ==================================================================================
-- ============================== AIM ASSIST TAB ====================================
-- ==================================================================================

local AIM_ENABLED = false
local AIM_FOV = 200
local AIM_SMOOTHNESS = 5
local AIM_PART = "Head"
local SHOW_FOV_CIRCLE = true

-- Círculo FOV
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.NumSides = 50
fovCircle.Radius = AIM_FOV
fovCircle.Filled = false
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Visible = false

-- Função para obter o alvo mais próximo
local function getClosestPlayer()
    local closestPlayer, closestDistance = nil, math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local aimPart = player.Character:FindFirstChild(AIM_PART)
            if aimPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if distance < AIM_FOV and distance < closestDistance then
                        closestPlayer = player
                        closestDistance = distance
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

-- Função de aim
local function performAim()
    if not AIM_ENABLED then return end
    
    local target = getClosestPlayer()
    if not target or not target.Character then return end
    
    local aimPart = target.Character:FindFirstChild(AIM_PART)
    if not aimPart then return end
    
    local targetPos = aimPart.Position
    local currentCFrame = Camera.CFrame
    local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
    
    Camera.CFrame = currentCFrame:Lerp(targetCFrame, 1 / AIM_SMOOTHNESS)
end

-- Toggle Aim
TabAim:CreateToggle({
    Name = "Ativar Aim Assist",
    CurrentValue = false,
    Callback = function(v)
        AIM_ENABLED = v
    end
})

TabAim:CreateSection("Configurações")

-- FOV Slider
TabAim:CreateSlider({
    Name = "FOV (Campo de Visão)",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = 200,
    Callback = function(v)
        AIM_FOV = v
        fovCircle.Radius = v
    end
})

-- Smoothness Slider
TabAim:CreateSlider({
    Name = "Suavidade",
    Range = {1, 20},
    Increment = 1,
    CurrentValue = 5,
    Callback = function(v)
        AIM_SMOOTHNESS = v
    end
})

-- Parte do corpo
TabAim:CreateDropdown({
    Name = "Parte do Corpo",
    Options = {"Head", "Torso", "HumanoidRootPart"},
    CurrentOption = "Head",
    Callback = function(option)
        AIM_PART = option
    end
})

-- Mostrar círculo FOV
TabAim:CreateToggle({
    Name = "Mostrar Círculo FOV",
    CurrentValue = true,
    Callback = function(v)
        SHOW_FOV_CIRCLE = v
    end
})

-- Loop de aim
RunService.RenderStepped:Connect(function()
    performAim()
    
    -- Atualizar círculo FOV
    if SHOW_FOV_CIRCLE then
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        fovCircle.Visible = true
    else
        fovCircle.Visible = false
    end
end)

-- ==================================================================================
-- ============================ PROTECTION TAB ======================================
-- ==================================================================================

local godMode = false
local lockHP = false
local antiVoid = false
local antiKB = false

TabProt:CreateSection("Saúde")

TabProt:CreateToggle({
    Name = "God Mode",
    CurrentValue = false,
    Callback = function(v)
        godMode = v
    end
})

TabProt:CreateToggle({
    Name = "Lock HP (Travar Vida)",
    CurrentValue = false,
    Callback = function(v)
        lockHP = v
    end
})

TabProt:CreateSection("Anti")

TabProt:CreateToggle({
    Name = "Anti Void (Anti Queda no Vazio)",
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
-- ============================== PLAYERS TAB =======================================
-- ==================================================================================

TabPlayers:CreateSection("Jogadores Online")

local selectedPlayer = nil
local playerDropdown

-- Função para obter lista de jogadores
local function getPlayerList()
    local playerList = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            table.insert(playerList, player.Name)
        end
    end
    return playerList
end

-- Dropdown de jogadores
playerDropdown = TabPlayers:CreateDropdown({
    Name = "Selecionar Jogador",
    Options = getPlayerList(),
    CurrentOption = "",
    Callback = function(playerName)
        selectedPlayer = Players:FindFirstChild(playerName)
    end
})

TabPlayers:CreateButton({
    Name = "Atualizar Lista",
    Callback = function()
        playerDropdown:Refresh(getPlayerList(), true)
    end
})

TabPlayers:CreateSection("Ações")

TabPlayers:CreateButton({
    Name = "Teleportar para Jogador",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character and HRP then
            local targetHRP = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                HRP.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end
})

TabPlayers:CreateButton({
    Name = "Spectate (Observar)",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character then
            Camera.CameraSubject = selectedPlayer.Character.Humanoid
        end
    end
})

TabPlayers:CreateButton({
    Name = "Voltar Camera para Você",
    Callback = function()
        if Character and Humanoid then
            Camera.CameraSubject = Humanoid
        end
    end
})

-- ==================================================================================
-- ============================ WAYPOINTS TAB =======================================
-- ==================================================================================

TabWaypoints:CreateSection("Waypoints Salvos")

local savedWaypoints = {}
local waypointName = "Waypoint"

TabWaypoints:CreateInput({
    Name = "Nome do Waypoint",
    PlaceholderText = "Digite o nome",
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
                Content = "Posição salva como: " .. waypointName,
                Duration = 2
            })
        end
    end
})

TabWaypoints:CreateSection("Teleportar")

local waypointDropdown = TabWaypoints:CreateDropdown({
    Name = "Selecionar Waypoint",
    Options = {},
    CurrentOption = "",
    Callback = function(name)
        waypointName = name
    end
})

TabWaypoints:CreateButton({
    Name = "Teleportar para Waypoint",
    Callback = function()
        if HRP and savedWaypoints[waypointName] then
            HRP.CFrame = savedWaypoints[waypointName]
        end
    end
})

TabWaypoints:CreateButton({
    Name = "Deletar Waypoint",
    Callback = function()
        if savedWaypoints[waypointName] then
            savedWaypoints[waypointName] = nil
            Rayfield:Notify({
                Title = "Waypoint Deletado",
                Content = "Waypoint removido: " .. waypointName,
                Duration = 2
            })
        end
    end
})

-- ==================================================================================
-- ============================== VISUALS TAB =======================================
-- ==================================================================================

TabVisuals:CreateSection("Câmera")

TabVisuals:CreateSlider({
    Name = "Campo de Visão (FOV)",
    Range = {70, 120},
    Increment = 1,
    CurrentValue = 70,
    Callback = function(v)
        Camera.FieldOfView = v
    end
})

TabVisuals:CreateSection("Ambiente")

local originalAmbient = Lighting.Ambient
local originalBrightness = Lighting.Brightness

TabVisuals:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Callback = function(v)
        if v then
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.Brightness = 2
        else
            Lighting.Ambient = originalAmbient
            Lighting.Brightness = originalBrightness
        end
    end
})

-- ==================================================================================
-- =============================== WORLD TAB ========================================
-- ==================================================================================

TabWorld:CreateSection("Tempo")

TabWorld:CreateSlider({
    Name = "Hora do Dia",
    Range = {0, 24},
    Increment = 0.5,
    CurrentValue = 12,
    Callback = function(v)
        Lighting.ClockTime = v
    end
})

TabWorld:CreateSection("Efeitos")

TabWorld:CreateButton({
    Name = "Remover Fog",
    Callback = function()
        pcall(function()
            Lighting.FogEnd = 1e6
        end)
    end
})

-- ==================================================================================
-- ============================== FPS/STATS TAB =====================================
-- ==================================================================================

TabFPS:CreateSection("Otimização")

local ANTI_LAG_ENABLED = false

local function applyAntiLag()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v.Parent:FindFirstChildOfClass("Humanoid") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
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
        pcall(function()
            setfpscap(v)
        end)
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
            pcall(function()
                statsLabel:Set(string.format("HP: %d/%d | Speed: %d | Jump: %d",
                    math.floor(Humanoid.Health),
                    math.floor(Humanoid.MaxHealth),
                    math.floor(Humanoid.WalkSpeed),
                    math.floor(Humanoid.JumpPower)
                ))
            end)
        end
    end
end)

local fpsCounter = 0
local lastFPSUpdate = tick()

RunService.RenderStepped:Connect(function()
    fpsCounter = fpsCounter + 1
    if tick() - lastFPSUpdate >= 1 then
        pcall(function()
            fpsLabel:Set("FPS: " .. fpsCounter)
        end)
        fpsCounter = 0
        lastFPSUpdate = tick()
    end
end)

task.spawn(function()
    while task.wait(2) do
        pcall(function()
            local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
            pingLabel:Set(string.format("Ping: %.0f ms", ping))
        end)
    end
end)

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            playersLabel:Set(string.format("Players: %d/%d", #Players:GetPlayers(), Players.MaxPlayers))
        end)
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
        pcall(function()
            local config = {
                WalkSpeed = Humanoid and Humanoid.WalkSpeed or 16,
                JumpPower = Humanoid and Humanoid.JumpPower or 50,
                savedWaypoints = savedWaypoints
            }
            writefile("UniversalHub_"..configName..".json", HttpService:JSONEncode(config))
            Rayfield:Notify({Title = "Config Salva", Content = "Config salva!", Duration = 2})
        end)
    end
})

TabConfig:CreateButton({
    Name = "Carregar Config",
    Callback = function()
        local success, result = pcall(function()
            return readfile("UniversalHub_"..configName..".json")
        end)
        
        if success then
            pcall(function()
                local config = HttpService:JSONDecode(result)
                if Humanoid then
                    Humanoid.WalkSpeed = config.WalkSpeed or 16
                    Humanoid.JumpPower = config.JumpPower or 50
                end
                if config.savedWaypoints then
                    savedWaypoints = config.savedWaypoints
                end
                Rayfield:Notify({Title = "Config Carregada", Content = "Config carregada!", Duration = 2})
            end)
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
    
    pcall(function()
        if input.KeyCode == keybindESP then
            ESP_ENABLED = not ESP_ENABLED
            refreshESP()
        elseif input.KeyCode == keybindAim then
            AIM_ENABLED = not AIM_ENABLED
        elseif input.KeyCode == keybindGUI then
            Rayfield:Toggle()
        end
    end)
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
        pcall(function()
            local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
            for _, s in pairs(servers.data) do
                if s.playing < s.maxPlayers then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LP)
                    break
                end
            end
        end)
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

print("✅ Universal Hub - Versão Corrigida e Otimizada!")
Rayfield:Notify({
    Title = "Universal Hub",
    Content = "Script carregado com sucesso!",
    Duration = 3
})