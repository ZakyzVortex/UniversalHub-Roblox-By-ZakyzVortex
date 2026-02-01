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


-- ================== TEAM DETECTION ==================
local function isPlayerOnSameTeam(player)
    -- Se não houver sistema de times, retorna false (considera todos como inimigos)
    if not LP.Team or not player.Team then return false end
    -- Verifica se estão no mesmo time
    return player.Team == LP.Team
end

local function shouldShowPlayer(player, filterMode)
    if filterMode == "All" then
        return true
    elseif filterMode == "Team" or filterMode == "MyTeam" then
        -- Só mostra se estiver NO MESMO TIME
        -- Se não há times no jogo, não mostra ninguém
        if not LP.Team or not player.Team then return false end
        return isPlayerOnSameTeam(player)
    elseif filterMode == "Enemy" or filterMode == "EnemyTeam" then
        -- Se não há times, todos são considerados inimigos
        if not LP.Team or not player.Team then return true end
        -- Se há times, só mostra se NÃO estiver no mesmo time
        return not isPlayerOnSameTeam(player)
    end
    return true
end

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
local TEAM_FILTER = "All"

-- Funções auxiliares
local function getPlayerTeam(player)
    return player.Team and player.Team.Name or "NoTeam"
end

-- Função para remover ESP de um jogador
local function removeESP(player)
    local espData = ESP_OBJECTS[player]
-- ================================== ESP TAB =======================================
-- ==================================================================================

-- ==================== ESP COM SISTEMA DE TIMES (FIXED + EXTRAS DO OFICIAL) ====================
local ESP_ENABLED = false
local NAME_ENABLED = true
local DISTANCE_ENABLED = true
local LINE_ENABLED = true
local HEALTH_ENABLED = true
local OUTLINE_ENABLED = true
local ESP_COLOR = Color3.fromRGB(255, 0, 0)
local LINE_COLOR = Color3.fromRGB(255, 255, 255)
local ESP_OBJECTS = {}
local ESP_TEAM_FILTER = "All"  -- All, MyTeam, EnemyTeam

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
        tracerLine.Thickness = 2
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

-- Sistema para jogadores existentes
local function initializeExistingPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            if ESP_ENABLED then
                createESP(player)
            end
        end
        
        player.CharacterAdded:Connect(function(char)
            char:WaitForChild("HumanoidRootPart", 5)
            task.wait(0.5)
            if ESP_ENABLED then
                createESP(player)
            end
        end)
    end
end

-- Sistema para jogadores novos
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart", 5)
        task.wait(0.5)
        if ESP_ENABLED then
            createESP(player)
        end
    end)
    
    if player.Character then
        task.wait(0.5)
        if ESP_ENABLED then
            createESP(player)
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

initializeExistingPlayers()

-- UI do ESP (COMBINANDO FIXED + OFICIAL)
TabESP:CreateSection("Controles do ESP")

TabESP:CreateToggle({
    Name = "Ativar ESP",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(v)
        ESP_ENABLED = v
        if v then refreshESP() else clearAllESP() end
    end
})

TabESP:CreateSection("Filtros")

TabESP:CreateDropdown({
    Name = "Filtro de Time",
    Options = {"All", "MyTeam", "EnemyTeam"},
    CurrentOption = "All",
    Flag = "ESPTeamFilter",
    Callback = function(option)
        ESP_TEAM_FILTER = option
        refreshESP()
    end
})

TabESP:CreateSection("Componentes do ESP")

TabESP:CreateToggle({
    Name = "Mostrar Nome",
    CurrentValue = true,
    Flag = "ESPName",
    Callback = function(v)
        NAME_ENABLED = v
        refreshESP()
    end
})

TabESP:CreateToggle({
    Name = "Mostrar Distância",
    CurrentValue = true,
    Flag = "ESPDistance",
    Callback = function(v)
        DISTANCE_ENABLED = v
        refreshESP()
    end
})

TabESP:CreateToggle({
    Name = "Mostrar Vida",
    CurrentValue = true,
    Flag = "ESPHealth",
    Callback = function(v)
        HEALTH_ENABLED = v
        refreshESP()
    end
})

TabESP:CreateToggle({
    Name = "Linha Única",
    CurrentValue = true,
    Flag = "ESPLine",
    Callback = function(v)
        LINE_ENABLED = v
        refreshESP()
    end
})

TabESP:CreateToggle({
    Name = "Contorno (Box)",
    CurrentValue = true,
    Flag = "ESPOutline",
    Callback = function(v)
        OUTLINE_ENABLED = v
        refreshESP()
    end
})

TabESP:CreateSection("Personalização")

TabESP:CreateColorPicker({
    Name = "Cor do ESP",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "ESPColor",
    Callback = function(color)
        ESP_COLOR = color
        for player, espData in pairs(ESP_OBJECTS) do
            if espData.nameLabel then espData.nameLabel.Color = color end
            if espData.boxOutline then espData.boxOutline.Color = color end
        end
    end
})

TabESP:CreateColorPicker({
    Name = "Cor da Linha",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "ESPLineColor",
    Callback = function(color)
        LINE_COLOR = color
        for player, espData in pairs(ESP_OBJECTS) do
            if espData.tracerLine then espData.tracerLine.Color = color end
            if espData.distLabel then espData.distLabel.Color = color end
        end
    end
})

TabESP:CreateSection("Ações")

TabESP:CreateButton({
    Name = "Atualizar ESP",
    Callback = function()
        refreshESP()
        Rayfield:Notify({
            Title = "ESP Atualizado",
            Content = "ESP foi recarregado com sucesso!",
            Duration = 2
        })
    end
})

RunService.RenderStepped:Connect(updateESP)

-- ==================================================================================
-- ============================ HIGHLIGHT ESP TAB ===================================
-- ==================================================================================

-- ==================== HIGHLIGHT ESP COM SISTEMA DE TIMES (FIXED + EXTRAS DO OFICIAL) ====================
local HIGHLIGHT_ENABLED = false
local HIGHLIGHT_TEAM_FILTER = "All"  -- All, MyTeam, EnemyTeam
local highlightColor = Color3.fromRGB(255, 0, 0)
local highlightObjects = {}
local highlightFillTransparency = 0.5
local highlightOutlineTransparency = 0
local highlightDepthMode = Enum.HighlightDepthMode.AlwaysOnTop

local function removeAllHighlights()
    for player, highlight in pairs(highlightObjects) do
        if highlight then 
            pcall(function()
                highlight:Destroy()
            end)
        end
    end
    highlightObjects = {}
end

local function createHighlight(player)
    if player == LP then return end
    if not player.Character then return end
    if not shouldShowPlayer(player, HIGHLIGHT_TEAM_FILTER) then return end
    
    if highlightObjects[player] then
        pcall(function()
            highlightObjects[player]:Destroy()
        end)
        highlightObjects[player] = nil
    end
    
    local existingHighlight = player.Character:FindFirstChild("Highlight")
    if existingHighlight then
        existingHighlight:Destroy()
    end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "Highlight"
    highlight.Adornee = player.Character
    highlight.FillColor = isPlayerOnSameTeam(player) and Color3.fromRGB(0, 255, 0) or highlightColor
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = highlightFillTransparency
    highlight.OutlineTransparency = highlightOutlineTransparency
    highlight.DepthMode = highlightDepthMode
    highlight.Parent = player.Character
    
    highlightObjects[player] = highlight
    
    -- Conexões de cleanup
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        local deathConnection
        deathConnection = hum.Died:Connect(function()
            task.wait(0.1)
            if highlightObjects[player] then
                pcall(function()
                    highlightObjects[player]:Destroy()
                end)
                highlightObjects[player] = nil
            end
            if deathConnection then
                deathConnection:Disconnect()
            end
        end)
    end
    
    local ancestryConnection
    ancestryConnection = player.Character.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if highlightObjects[player] then
                pcall(function()
                    highlightObjects[player]:Destroy()
                end)
                highlightObjects[player] = nil
            end
            if ancestryConnection then
                ancestryConnection:Disconnect()
            end
        end
    end)
end

local function updateAllHighlights()
    if HIGHLIGHT_ENABLED then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LP and player.Character then
                createHighlight(player)
            end
        end
    else
        removeAllHighlights()
    end
end

local function refreshHighlights()
    removeAllHighlights()
    if HIGHLIGHT_ENABLED then
        for _, player in ipairs(Players:GetPlayers()) do
            createHighlight(player)
        end
    end
end

-- Sistema para jogadores existentes e novos
local function initializeExistingPlayersHighlight()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            if player.Character then
                if HIGHLIGHT_ENABLED then
                    createHighlight(player)
                end
            end
            
            player.CharacterAdded:Connect(function(char)
                char:WaitForChild("HumanoidRootPart", 5)
                task.wait(0.3)
                if HIGHLIGHT_ENABLED then
                    createHighlight(player)
                end
            end)
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart", 5)
        task.wait(0.3)
        if HIGHLIGHT_ENABLED then 
            createHighlight(player) 
        end
    end)
    
    if player.Character then
        task.wait(0.3)
        if HIGHLIGHT_ENABLED then
            createHighlight(player)
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if highlightObjects[player] then
        pcall(function()
            highlightObjects[player]:Destroy()
        end)
        highlightObjects[player] = nil
    end
end)

-- Loop de verificação
local lastHighlightCheck = 0
RunService.RenderStepped:Connect(function()
    if not HIGHLIGHT_ENABLED then return end
    
    local now = tick()
    if now - lastHighlightCheck < 2 then return end
    lastHighlightCheck = now
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local char = player.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            
            if hrp and hum and hum.Health > 0 then
                if not highlightObjects[player] or not highlightObjects[player].Parent then
                    createHighlight(player)
                end
            end
        end
    end
end)

initializeExistingPlayersHighlight()

-- UI do Highlight ESP (COMBINANDO FIXED + OFICIAL)
TabHighlight:CreateSection("Controles do Highlight")

TabHighlight:CreateToggle({
    Name = "Ativar Highlight ESP",
    CurrentValue = false,
    Flag = "Highlight",
    Callback = function(v)
        HIGHLIGHT_ENABLED = v
        updateAllHighlights()
    end
})

TabHighlight:CreateSection("Filtros")

TabHighlight:CreateDropdown({
    Name = "Filtro de Time",
    Options = {"All", "MyTeam", "EnemyTeam"},
    CurrentOption = "All",
    Flag = "HighlightTeamFilter",
    Callback = function(option)
        HIGHLIGHT_TEAM_FILTER = option
        refreshHighlights()
    end
})

TabHighlight:CreateSection("Personalização")

TabHighlight:CreateColorPicker({
    Name = "Cor do Highlight",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "HighlightColor",
    Callback = function(color)
        highlightColor = color
        for player, highlight in pairs(highlightObjects) do
            if highlight and highlight.Parent and not isPlayerOnSameTeam(player) then
                highlight.FillColor = color
            end
        end
    end
})

TabHighlight:CreateSlider({
    Name = "Transparência do Preenchimento",
    Range = {0, 1},
    Increment = 0.05,
    CurrentValue = 0.5,
    Flag = "HighlightFillTransparency",
    Callback = function(v)
        highlightFillTransparency = v
        for player, highlight in pairs(highlightObjects) do
            if highlight and highlight.Parent then
                highlight.FillTransparency = v
            end
        end
    end
})

TabHighlight:CreateSlider({
    Name = "Transparência do Contorno",
    Range = {0, 1},
    Increment = 0.05,
    CurrentValue = 0,
    Flag = "HighlightOutlineTransparency",
    Callback = function(v)
        highlightOutlineTransparency = v
        for player, highlight in pairs(highlightObjects) do
            if highlight and highlight.Parent then
                highlight.OutlineTransparency = v
            end
        end
    end
})

TabHighlight:CreateDropdown({
    Name = "Modo de Profundidade",
    Options = {"AlwaysOnTop", "Occluded"},
    CurrentOption = "AlwaysOnTop",
    Flag = "HighlightDepthMode",
    Callback = function(option)
        highlightDepthMode = option == "AlwaysOnTop" and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        for player, highlight in pairs(highlightObjects) do
            if highlight and highlight.Parent then
                highlight.DepthMode = highlightDepthMode
            end
        end
    end
})

TabHighlight:CreateSection("Ações")

TabHighlight:CreateButton({
    Name = "Atualizar Highlights",
    Callback = function()
        updateAllHighlights()
        Rayfield:Notify({
            Title = "Highlight ESP Atualizado",
            Content = "Todos os highlights foram recarregados!",
            Duration = 2
        })
    end
})

TabHighlight:CreateButton({
    Name = "Remover Todos os Highlights",
    Callback = function()
        removeAllHighlights()
        Rayfield:Notify({
            Title = "Highlights Removidos",
            Content = "Todos os highlights foram removidos!",
            Duration = 2
        })
    end
})

-- ==================================================================================
-- ============================== AIM ASSIST TAB ====================================
-- ==================================================================================

-- ==================== AIM ASSIST (FIXED + EXTRAS DO OFICIAL) ====================
TabAim:CreateSection("Aim Assist")

local AIM_ENABLED = false
local AIM_SMOOTHNESS = 0.5
local AIM_PART = "Head"
local AIM_VISIBLE_CHECK = true
local AIM_MAX_DISTANCE = 1000
local AIM_FOV_RADIUS = 200
local AIM_TEAM_FILTER = "EnemyTeam"  -- EnemyTeam ou All
local currentTarget = nil
local lastTargetUpdate = 0

-- Raycast params para wallcheck
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Blacklist
rayParams.IgnoreWater = true

-- Função para verificar se o jogador está visível (wallcheck)
local function isVisible(targetPart)
    if not targetPart or not HRP then return false end
    if not AIM_VISIBLE_CHECK then return true end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {Character, targetPart.Parent}
    raycastParams.IgnoreWater = true
    
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    
    local result = workspace:Raycast(origin, direction, raycastParams)
    
    -- Se não acertou nada, está visível
    if not result then return true end
    
    local hitPart = result.Instance
    
    -- Se acertou uma parte do próprio alvo, está visível
    if hitPart:IsDescendantOf(targetPart.Parent) then return true end
    
    -- Se acertou algo transparente (>90%), considera visível
    if hitPart.Transparency >= 0.9 then return true end
    
    -- Se chegou aqui, há algo bloqueando
    return false
end

-- Função para obter a parte do alvo (suporta todas as opções do oficial + fixed)
local function getTargetPart(character, partName)
    if not character then return nil end
    
    local part = character:FindFirstChild(partName)
    if part and part:IsA("BasePart") then
        return part
    end
    
    if partName == "Head" then
        return character:FindFirstChild("Head")
    elseif partName == "Torso" or partName == "HumanoidRootPart" then
        return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    elseif partName == "UpperTorso" then
        return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
    elseif partName == "LowerTorso" then
        return character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
    elseif partName == "Random" then
        local parts = {"Head", "HumanoidRootPart"}
        local randomPart = parts[math.random(1, #parts)]
        return character:FindFirstChild(randomPart)
    end
    
    return character:FindFirstChild("Head")
end

-- Função para verificar se o jogador é válido como alvo
local function isValidTarget(player)
    if not player or player == LP then return false end
    if not player.Character then return false end
    
    local targetPart = getTargetPart(player.Character, AIM_PART)
    if not targetPart then return false end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    -- VERIFICAÇÃO DE TIME: usa o filtro configurado
    if not shouldShowPlayer(player, AIM_TEAM_FILTER) then
        return false
    end
    
    -- Verificação de distância
    local distance = (HRP.Position - targetPart.Position).Magnitude
    if distance > AIM_MAX_DISTANCE then return false end
    
    -- Verificação de FOV
    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
    if not onScreen or screenPos.Z <= 0 then return false end
    
    local centerScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local targetScreen = Vector2.new(screenPos.X, screenPos.Y)
    local distanceFromCenter = (centerScreen - targetScreen).Magnitude
    
    if distanceFromCenter > AIM_FOV_RADIUS then return false end
    
    -- Verificação de visibilidade
    if not isVisible(targetPart) then
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
            local targetPart = getTargetPart(player.Character, AIM_PART)
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
    
    -- Atualizar alvo a cada 0.1 segundos (do fixed)
    if now - lastTargetUpdate < 0.1 then return end
    lastTargetUpdate = now
    
    -- SEMPRE verificar se o alvo atual é válido com o filtro atual
    if currentTarget and not isValidTarget(currentTarget) then
        currentTarget = nil
    end
    
    -- Se não há alvo, buscar novo alvo
    if not currentTarget then
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
    
    local targetPart = getTargetPart(currentTarget.Character, AIM_PART)
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

-- UI do Aim Assist (COMBINANDO FIXED + OFICIAL)
TabAim:CreateSection("Controles do Aim Assist")

TabAim:CreateToggle({
    Name = "🎯 Ativar Aim Assist",
    CurrentValue = false,
    Flag = "AimEnabled",
    Callback = function(v)
        AIM_ENABLED = v
        if not v then
            currentTarget = nil
        end
        
        -- Mostrar notificação ao ativar/desativar
        if v then
            local filterText = AIM_TEAM_FILTER == "All" and "todos os jogadores" or "apenas inimigos"
            Rayfield:Notify({
                Title = "Aim Assist Ativado",
                Content = "Alvo: " .. filterText,
                Duration = 2
            })
        end
    end
})

TabAim:CreateToggle({
    Name = "Wallcheck",
    CurrentValue = true,
    Flag = "AimWallcheck",
    Callback = function(v)
        AIM_VISIBLE_CHECK = v
        currentTarget = nil
    end
})

TabAim:CreateSection("Configurações de Alvo")

TabAim:CreateDropdown({
    Name = "Filtro de Alvo",
    Options = {"EnemyTeam", "All"},
    CurrentOption = "EnemyTeam",
    Flag = "AimTeamFilter",
    Callback = function(option)
        AIM_TEAM_FILTER = option
        currentTarget = nil
        Rayfield:Notify({
            Title = "Filtro Alterado",
            Content = option == "EnemyTeam" and "Mirando apenas inimigos" or "Mirando em todos",
            Duration = 2
        })
    end
})

TabAim:CreateSlider({
    Name = "FOV (Raio)",
    Range = {10, 500},
    Increment = 10,
    CurrentValue = 200,
    Flag = "AimFOV",
    Callback = function(v)
        AIM_FOV_RADIUS = v
    end
})

TabAim:CreateSlider({
    Name = "Suavidade",
    Range = {0.05, 1},
    Increment = 0.05,
    CurrentValue = 0.5,
    Flag = "AimSmoothness",
    Callback = function(v)
        AIM_SMOOTHNESS = v
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

TabAim:CreateSection("Parte do Corpo")

TabAim:CreateDropdown({
    Name = "Parte do Alvo",
    Options = {"Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso", "Random"},
    CurrentOption = "Head",
    Flag = "AimPart",
    Callback = function(option)
        AIM_PART = option
        currentTarget = nil
    end
})

TabAim:CreateSection("Controle de Alvo")

-- Função para resetar o alvo atual do aim assist
local function resetAimTarget()
    currentTarget = nil
    lastTargetUpdate = 0 -- Força re-busca imediata no próximo frame
end

TabAim:CreateButton({
    Name = "🔄 Resetar Alvo",
    Callback = function()
        local hadTarget = currentTarget ~= nil
        resetAimTarget()
        Rayfield:Notify({
            Title = "Alvo Resetado",
            Content = hadTarget and "Alvo anterior removido. Buscando novo alvo..." or "Nenhum alvo ativo.",
            Duration = 2
        })
    end
})

-- Executar aim assist no RenderStepped
RunService.RenderStepped:Connect(aimAssist)

    CurrentValue = false,
    Callback = function(v)
        antiKB = v
    end
})

TabProt:CreateToggle({
    Name = "Anti Void",
    CurrentValue = false,
    Callback = function(v)
        antiVoid = v
    end
})

-- ==================================================================================
-- ================================ PLAYERS TAB =====================================
-- ==================================================================================

TabPlayers:CreateSection("Teleporte e Spectate")

local selectedName = nil

local function getPlayerNames()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            table.insert(t, p.Name)
        end
    end
    return t
end

local playerDropdown = TabPlayers:CreateDropdown({
    Name = "Selecionar Player",
    Options = getPlayerNames(),
    Callback = function(v)
        selectedName = typeof(v) == "table" and v[1] or v
    end
})

TabPlayers:CreateButton({
    Name = "Atualizar Lista",
    Callback = function()
        playerDropdown:Refresh(getPlayerNames())
    end
})

TabPlayers:CreateButton({
    Name = "TP para Player",
    Callback = function()
        local t = Players:FindFirstChild(selectedName)
        if t and t.Character and HRP then
            HRP.CFrame = t.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
        end
    end
})

TabPlayers:CreateButton({
    Name = "Spectate",
    Callback = function()
        local t = Players:FindFirstChild(selectedName)
        if t and t.Character then
            Camera.CameraSubject = t.Character:FindFirstChildOfClass("Humanoid")
        end
    end
})

TabPlayers:CreateButton({
    Name = "Voltar Camera",
    Callback = function()
        Camera.CameraSubject = Humanoid
    end
})

-- ==================================================================================
-- ============================== WAYPOINTS TAB =====================================
-- ==================================================================================

TabWaypoints:CreateSection("Sistema de Waypoints")

local savedWaypoints = {}
local waypointToDelete = nil

local function saveWaypoint(name)
    if not HRP then return false end
    
    savedWaypoints[name] = {
        Position = HRP.CFrame.Position,
        Time = os.date("%H:%M:%S")
    }
    
    return true
end

local function teleportToWaypoint(name)
    if not savedWaypoints[name] or not HRP then return false end
    
    HRP.CFrame = CFrame.new(savedWaypoints[name].Position)
    return true
end

local function deleteWaypoint(name)
    savedWaypoints[name] = nil
end

local function getWaypointList()
    local list = {}
    for name, _ in pairs(savedWaypoints) do
        table.insert(list, name)
    end
    return #list > 0 and list or {"Nenhum waypoint salvo"}
end

local waypointNameInput = ""

TabWaypoints:CreateInput({
    Name = "Nome do Waypoint",
    PlaceholderText = "Digite o nome...",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        waypointNameInput = text
    end
})

TabWaypoints:CreateButton({
    Name = "Salvar Posição Atual",
    Callback = function()
        if waypointNameInput == "" then
            Rayfield:Notify({
                Title = "Erro",
                Content = "Digite um nome para o waypoint!",
                Duration = 3
            })
            return
        end
        
        if saveWaypoint(waypointNameInput) then
            Rayfield:Notify({
                Title = "Waypoint Salvo",
                Content = "'"..waypointNameInput.."' foi salvo!",
                Duration = 3
            })
        end
    end
})

local waypointDropdown = TabWaypoints:CreateDropdown({
    Name = "Selecionar Waypoint",
    Options = getWaypointList(),
    CurrentOption = getWaypointList()[1],
    Callback = function(option)
        waypointToDelete = option
    end
})

TabWaypoints:CreateButton({
    Name = "Teleportar para Waypoint",
    Callback = function()
        if not waypointToDelete or waypointToDelete == "Nenhum waypoint salvo" then
            Rayfield:Notify({
                Title = "Erro",
                Content = "Selecione um waypoint válido!",
                Duration = 3
            })
            return
        end
        
        if teleportToWaypoint(waypointToDelete) then
            Rayfield:Notify({
                Title = "Teleportado",
                Content = "Você foi teleportado!",
                Duration = 2
            })
        end
    end
})

TabWaypoints:CreateButton({
    Name = "Deletar Waypoint",
    Callback = function()
        if not waypointToDelete or waypointToDelete == "Nenhum waypoint salvo" then
            Rayfield:Notify({
                Title = "Erro",
                Content = "Selecione um waypoint válido!",
                Duration = 3
            })
            return
        end
        
        deleteWaypoint(waypointToDelete)
        waypointDropdown:Refresh(getWaypointList())
        
        Rayfield:Notify({
            Title = "Waypoint Deletado",
            Content = "Waypoint removido!",
            Duration = 2
        })
    end
})

TabWaypoints:CreateButton({
    Name = "Atualizar Lista",
    Callback = function()
        waypointDropdown:Refresh(getWaypointList())
    end
})

TabWaypoints:CreateSection("Teleporte Rápido")

TabWaypoints:CreateButton({
    Name = "TP para Spawn",
    Callback = function()
        if HRP then
            local spawnLocation = workspace:FindFirstChild("SpawnLocation") or workspace:FindFirstChildOfClass("SpawnLocation")
            if spawnLocation then
                HRP.CFrame = spawnLocation.CFrame + Vector3.new(0, 5, 0)
            end
        end
    end
})

-- ==================================================================================
-- =============================== VISUALS TAB ======================================
-- ==================================================================================

TabVisuals:CreateSection("Campo de Visão")

local DEFAULT_FOV = Camera.FieldOfView

TabVisuals:CreateSlider({
    Name = "FOV",
    Range = {70, 120},
    Increment = 1,
    CurrentValue = DEFAULT_FOV,
    Callback = function(v)
        Camera.FieldOfView = v
    end
})

TabVisuals:CreateButton({
    Name = "Resetar FOV",
    Callback = function()
        Camera.FieldOfView = DEFAULT_FOV
    end
})

TabVisuals:CreateSection("Iluminação")

local FULLBRIGHT_ENABLED = false

local function toggleFullbright(enabled)
    if enabled then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    else
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
    end
end

TabVisuals:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Callback = function(v)
        FULLBRIGHT_ENABLED = v
        toggleFullbright(v)
    end
})

TabVisuals:CreateSection("Câmera")

local NO_CAMERA_SHAKE = false

TabVisuals:CreateToggle({
    Name = "No Camera Shake",
    CurrentValue = false,
    Callback = function(v)
        NO_CAMERA_SHAKE = v
    end
})

RunService.RenderStepped:Connect(function()
    if NO_CAMERA_SHAKE then
        local humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.CameraOffset = Vector3.new(0, 0, 0)
        end
    end
end)

-- ==================================================================================
-- ================================= WORLD TAB ======================================
-- ==================================================================================

TabWorld:CreateSection("Tempo e Ambiente")

TabWorld:CreateSlider({
    Name = "Hora do Dia",
    Range = {0, 24},
    Increment = 0.5,
    CurrentValue = 14,
    Callback = function(v)
        Lighting.ClockTime = v
    end
})

TabWorld:CreateSlider({
    Name = "Gravidade",
    Range = {60, 500},
    Increment = 10,
    CurrentValue = 196,
    Callback = function(v)
        workspace.Gravity = v
    end
})

TabWorld:CreateButton({
    Name = "Remover Fog",
    Callback = function()
        Lighting.FogEnd = 1e6
    end
})

-- ==================================================================================
-- =============================== FPS/STATS TAB ====================================
-- ==================================================================================

TabFPS:CreateSection("Anti-Lag")

local ANTI_LAG_ENABLED = false

local function applyAntiLag()
    if not ANTI_LAG_ENABLED then return end
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
            obj.Enabled = false
        end
    end
    
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") then
            effect.Enabled = false
        end
    end
    
    for _, effect in pairs(Camera:GetChildren()) do
        if effect:IsA("PostEffect") then
            effect.Enabled = false
        end
    end
    
    Lighting.GlobalShadows = false
    
    workspace.Terrain.WaterWaveSize = 0
    workspace.Terrain.WaterWaveSpeed = 0
    workspace.Terrain.WaterReflectance = 0
    workspace.Terrain.WaterTransparency = 0
    
    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") then
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

print("✅ Universal Hub - Organizado e 100% Funcional!")