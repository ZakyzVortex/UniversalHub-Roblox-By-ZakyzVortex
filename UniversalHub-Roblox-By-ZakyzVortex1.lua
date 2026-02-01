-- ================== UNIVERSAL HUB - COMPLETE EDITION ==================
-- Universal Hub By ZakyzVortex - Sistema de Times + Todas as Funções
-- Fixed + Official Combined - Ordem Oficial Mantida

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

-- ================== TEAM DETECTION SYSTEM (FROM FIXED) ==================
local function isPlayerOnSameTeam(player)
    if not LP.Team or not player.Team then return false end
    return player.Team == LP.Team
end

local function shouldShowPlayer(player, filterMode)
    if filterMode == "All" then
        return true
    elseif filterMode == "MyTeam" then
        if not LP.Team or not player.Team then return false end
        return isPlayerOnSameTeam(player)
    elseif filterMode == "EnemyTeam" then
        if not LP.Team or not player.Team then return true end
        return not isPlayerOnSameTeam(player)
    end
    return true
end

-- ================== WINDOW ==================
local Window = Rayfield:CreateWindow({
    Name = "Universal Hub - Complete Edition",
    LoadingTitle = "Universal Hub",
    LoadingSubtitle = "By ZakyzVortex - Team System Integrated",
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

local ESP_OBJECTS = {}
local TEAM_FILTER = "All"

-- Função para remover ESP de um jogador
local function removeESP(player)
    local espData = ESP_OBJECTS[player]
    if not espData then return end
    
    espData.active = false
    
    if espData.billboard then
        espData.billboard:Destroy()
        espData.billboard = nil
    end
    
    if espData.line then
        espData.line:Remove()
        espData.line = nil
    end
    
    if espData.outline then
        for _, l in ipairs(espData.outline) do
            l:Remove()
        end
        espData.outline = nil
    end
    
    ESP_OBJECTS[player] = nil
end

-- Função para criar ESP
local function createESP(player)
    if player == LP then return end
    
    if ESP_OBJECTS[player] then
        removeESP(player)
    end
    
    local char = player.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    -- Filtro de time usando shouldShowPlayer
    if not shouldShowPlayer(player, TEAM_FILTER) then return end

    local espData = {
        active = true,
        player = player,
        character = char
    }

    -- Billboard
    if NAME_ENABLED or DISTANCE_ENABLED or HEALTH_ENABLED then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESPName"
        billboard.Adornee = hrp
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = hrp
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.TextStrokeTransparency = 0
        textLabel.TextSize = 14
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.Parent = billboard
        
        espData.billboard = billboard
        espData.textLabel = textLabel
    end
    
    -- Linha de traçado
    if LINE_ENABLED then
        local line = Drawing.new("Line")
        line.Visible = true
        line.Color = Color3.fromRGB(255, 255, 255)
        line.Thickness = 1
        espData.line = line
    end
    
    -- Contorno 4 linhas
    if OUTLINE_ENABLED then
        local outline = {}
        for i = 1, 4 do
            local line = Drawing.new("Line")
            line.Visible = true
            line.Color = Color3.fromRGB(255, 0, 0)
            line.Thickness = 2
            table.insert(outline, line)
        end
        espData.outline = outline
    end
    
    ESP_OBJECTS[player] = espData
end

-- Função para atualizar ESP
local function updateESP()
    for player, espData in pairs(ESP_OBJECTS) do
        if not player or not player.Parent or not espData.active then
            removeESP(player)
            continue
        end
        
        -- Verifica filtro de time
        if not shouldShowPlayer(player, TEAM_FILTER) then
            removeESP(player)
            continue
        end
        
        local char = player.Character
        if not char then
            removeESP(player)
            continue
        end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        
        if not hrp or not hum or hum.Health <= 0 then
            removeESP(player)
            continue
        end
        
        -- Atualizar Billboard
        if espData.textLabel then
            local text = ""
            
            if NAME_ENABLED then
                text = player.Name
            end
            
            if DISTANCE_ENABLED and HRP then
                local dist = (HRP.Position - hrp.Position).Magnitude
                text = text .. (text ~= "" and "\n" or "") .. string.format("%.0f studs", dist)
            end
            
            if HEALTH_ENABLED then
                text = text .. (text ~= "" and "\n" or "") .. string.format("HP: %d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth))
                
                local healthPercent = hum.Health / hum.MaxHealth
                if healthPercent > 0.5 then
                    espData.textLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                elseif healthPercent > 0.25 then
                    espData.textLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                else
                    espData.textLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                end
            end
            
            espData.textLabel.Text = text
        end
        
        -- Atualizar Linha
        if espData.line then
            local hrpPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            espData.line.Visible = onScreen and ESP_ENABLED
            espData.line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            espData.line.To = Vector2.new(hrpPos.X, hrpPos.Y)
        end
        
        -- Atualizar Contorno
        if espData.outline then
            local corners = {}
            local size = hrp.Size
            local cf = hrp.CFrame
            
            local offsets = {
                Vector3.new(-size.X/2, size.Y/2, 0),
                Vector3.new(size.X/2, size.Y/2, 0),
                Vector3.new(size.X/2, -size.Y/2, 0),
                Vector3.new(-size.X/2, -size.Y/2, 0)
            }
            
            for _, offset in ipairs(offsets) do
                local worldPos = cf * offset
                local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
                table.insert(corners, {pos = Vector2.new(screenPos.X, screenPos.Y), onScreen = onScreen})
            end
            
            local allOnScreen = true
            for _, corner in ipairs(corners) do
                if not corner.onScreen then
                    allOnScreen = false
                    break
                end
            end
            
            for i, line in ipairs(espData.outline) do
                line.Visible = allOnScreen and ESP_ENABLED
                if allOnScreen then
                    local nextIndex = (i % 4) + 1
                    line.From = corners[i].pos
                    line.To = corners[nextIndex].pos
                end
            end
        end
    end
end

-- Função para atualizar todos
local function refreshESP()
    for _, player in ipairs(Players:GetPlayers()) do
        removeESP(player)
    end
    
    if ESP_ENABLED then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LP then
                createESP(player)
            end
        end
    end
end

-- Função para limpar tudo
local function clearAllESP()
    for player, _ in pairs(ESP_OBJECTS) do
        removeESP(player)
    end
end

-- Eventos de jogadores
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
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

-- Loop de atualização
local lastESPUpdate = 0
RunService.RenderStepped:Connect(function()
    if not ESP_ENABLED then return end
    
    local now = tick()
    if now - lastESPUpdate < 0.033 then return end
    lastESPUpdate = now
    
    updateESP()
end)

-- Inicializar jogadores existentes
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LP and player.Character then
        createESP(player)
    end
end

-- UI do ESP
TabESP:CreateSection("Controles do ESP")

TabESP:CreateToggle({
    Name = "Ativar ESP",
    CurrentValue = false,
    Callback = function(v)
        ESP_ENABLED = v
        refreshESP()
    end
})

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
    Name = "Mostrar Vida",
    CurrentValue = true,
    Callback = function(v)
        HEALTH_ENABLED = v
        refreshESP()
    end
})

TabESP:CreateToggle({
    Name = "Linha Única",
    CurrentValue = true,
    Callback = function(v)
        LINE_ENABLED = v
        refreshESP()
    end
})

TabESP:CreateToggle({
    Name = "Contorno 4 Linhas",
    CurrentValue = true,
    Callback = function(v)
        OUTLINE_ENABLED = v
        refreshESP()
    end
})

TabESP:CreateDropdown({
    Name = "Filtro de Time",
    Options = {"All", "MyTeam", "EnemyTeam"},
    CurrentOption = "All",
    Callback = function(option)
        TEAM_FILTER = option
        refreshESP()
    end
})

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

-- ==================================================================================
-- ============================ HIGHLIGHT ESP TAB ===================================
-- ==================================================================================

-- Estados
local HIGHLIGHT_ENABLED = false
local HIGHLIGHT_TEAM_FILTER = "All"
local highlightColor = Color3.fromRGB(255, 0, 0)
local highlightCache = {}

-- Função para adicionar highlight
local function addHighlight(player)
    if player == LP then return end
    
    -- Filtro de time usando shouldShowPlayer
    if not shouldShowPlayer(player, HIGHLIGHT_TEAM_FILTER) then return end
    
    local char = player.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    if highlightCache[player] then
        pcall(function()
            highlightCache[player]:Destroy()
        end)
        highlightCache[player] = nil
    end
    
    local existingHighlight = hrp:FindFirstChild("Highlight")
    if existingHighlight then
        existingHighlight:Destroy()
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "Highlight"
    highlight.Adornee = char
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = highlightColor
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = hrp
    
    highlightCache[player] = highlight
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        local deathConnection
        deathConnection = hum.Died:Connect(function()
            task.wait(0.1)
            if highlightCache[player] then
                pcall(function()
                    highlightCache[player]:Destroy()
                end)
                highlightCache[player] = nil
            end
            if deathConnection then
                deathConnection:Disconnect()
            end
        end)
    end
    
    local ancestryConnection
    ancestryConnection = char.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if highlightCache[player] then
                pcall(function()
                    highlightCache[player]:Destroy()
                end)
                highlightCache[player] = nil
            end
            if ancestryConnection then
                ancestryConnection:Disconnect()
            end
        end
    end)
end

-- Função para remover highlight
local function removeHighlight(player)
    if highlightCache[player] then
        pcall(function()
            highlightCache[player]:Destroy()
        end)
        highlightCache[player] = nil
    end
end

-- Função para remover todos
local function removeAllHighlights()
    for player, highlight in pairs(highlightCache) do
        pcall(function()
            highlight:Destroy()
        end)
    end
    highlightCache = {}
end

-- Função para atualizar todos
local function updateAllHighlights()
    if HIGHLIGHT_ENABLED then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LP and player.Character then
                addHighlight(player)
            end
        end
    else
        removeAllHighlights()
    end
end

-- Sistema para jogadores existentes
local function initializeExistingPlayersHighlight()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            if player.Character then
                if HIGHLIGHT_ENABLED then
                    addHighlight(player)
                end
            end
            
            player.CharacterAdded:Connect(function(char)
                char:WaitForChild("HumanoidRootPart", 5)
                task.wait(0.3)
                if HIGHLIGHT_ENABLED then
                    addHighlight(player)
                end
            end)
        end
    end
end

-- Sistema para jogadores novos
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart", 5)
        task.wait(0.3)
        if HIGHLIGHT_ENABLED then
            addHighlight(player)
        end
    end)
    
    if player.Character then
        task.wait(0.3)
        if HIGHLIGHT_ENABLED then
            addHighlight(player)
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeHighlight(player)
end)

initializeExistingPlayersHighlight()

-- Loop de verificação
local lastHighlightCheck = 0
RunService.RenderStepped:Connect(function()
    if not HIGHLIGHT_ENABLED then return end
    
    local now = tick()
    if now - lastHighlightCheck < 2 then return end
    lastHighlightCheck = now
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character and shouldShowPlayer(player, HIGHLIGHT_TEAM_FILTER) then
            local char = player.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            
            if hrp and hum and hum.Health > 0 then
                local existingHighlight = hrp:FindFirstChild("Highlight")
                if not existingHighlight and not highlightCache[player] then
                    addHighlight(player)
                end
            end
        end
    end
end)

-- UI do Highlight ESP
TabHighlight:CreateSection("Controles do Highlight")

TabHighlight:CreateToggle({
    Name = "Ativar Highlight ESP",
    CurrentValue = false,
    Callback = function(v)
        HIGHLIGHT_ENABLED = v
        updateAllHighlights()
    end
})

TabHighlight:CreateColorPicker({
    Name = "Cor do Highlight",
    Color = Color3.fromRGB(255, 0, 0),
    Callback = function(color)
        highlightColor = color
        for player, highlight in pairs(highlightCache) do
            if highlight and highlight.Parent then
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
    Callback = function(v)
        for player, highlight in pairs(highlightCache) do
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
    Callback = function(v)
        for player, highlight in pairs(highlightCache) do
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
    Callback = function(option)
        local depthMode = option == "AlwaysOnTop" and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        for player, highlight in pairs(highlightCache) do
            if highlight and highlight.Parent then
                highlight.DepthMode = depthMode
            end
        end
    end
})

TabHighlight:CreateDropdown({
    Name = "Filtro de Time",
    Options = {"All", "MyTeam", "EnemyTeam"},
    CurrentOption = "All",
    Callback = function(option)
        HIGHLIGHT_TEAM_FILTER = option
        updateAllHighlights()
    end
})

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

-- Estados
local AIM_ENABLED = false
local AIM_FOV = 100
local AIM_SMOOTH = 0.2
local AIM_TARGET_PART = "Head"
local AIM_WALLCHECK = true
local AIM_TEAM_FILTER = "All"
local currentTarget = nil
local lastTargetCheck = 0

-- Raycast params
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Blacklist
rayParams.IgnoreWater = true

-- Função para pegar parte do corpo
local function getTargetPart(character, partName)
    local part = character:FindFirstChild(partName)
    if part and part:IsA("BasePart") then
        return part
    end
    
    if partName == "Head" then
        return character:FindFirstChild("Head")
    elseif partName == "HumanoidRootPart" then
        return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    elseif partName == "UpperTorso" then
        return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
    elseif partName == "LowerTorso" then
        return character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
    end
    
    return character:FindFirstChild("HumanoidRootPart")
end

-- Função de wallcheck
local function isVisible(targetPart)
    if not AIM_WALLCHECK then return true end
    
    rayParams.FilterDescendantsInstances = {LP.Character, targetPart.Parent}
    
    local origin = Camera.CFrame.Position
    local targetPos = targetPart.Position
    local direction = targetPos - origin
    
    local result = workspace:Raycast(origin, direction, rayParams)
    
    if not result then return true end
    
    local hitPart = result.Instance
    
    if hitPart.Transparency >= 0.9 then return true end
    
    if hitPart:IsDescendantOf(targetPart.Parent) then return true end
    
    return false
end

-- UI do Aim Assist
TabAim:CreateSection("Controles do Aim Assist")

TabAim:CreateToggle({
    Name = "Ativar Aim Assist",
    CurrentValue = false,
    Callback = function(v)
        AIM_ENABLED = v
        currentTarget = nil
    end
})

TabAim:CreateToggle({
    Name = "Wallcheck",
    CurrentValue = true,
    Callback = function(v)
        AIM_WALLCHECK = v
        currentTarget = nil
    end
})

TabAim:CreateSlider({
    Name = "FOV",
    Range = {10, 500},
    Increment = 10,
    CurrentValue = 100,
    Callback = function(v)
        AIM_FOV = v
    end
})

TabAim:CreateSlider({
    Name = "Suavidade",
    Range = {0.05, 1},
    Increment = 0.05,
    CurrentValue = 0.2,
    Callback = function(v)
        AIM_SMOOTH = v
    end
})

TabAim:CreateDropdown({
    Name = "Parte do Corpo",
    Options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    CurrentOption = "Head",
    Callback = function(option)
        AIM_TARGET_PART = option
        currentTarget = nil
    end
})

TabAim:CreateDropdown({
    Name = "Filtro de Time",
    Options = {"All", "MyTeam", "EnemyTeam"},
    CurrentOption = "All",
    Callback = function(option)
        AIM_TEAM_FILTER = option
        currentTarget = nil
    end
})

TabAim:CreateButton({
    Name = "Resetar Alvo",
    Callback = function()
        currentTarget = nil
        Rayfield:Notify({
            Title = "Aim Assist",
            Content = "Alvo resetado!",
            Duration = 1.5
        })
    end
})

-- Runtime do Aim Assist
RunService.RenderStepped:Connect(function()
    if not AIM_ENABLED or not HRP then return end

    local now = tick()
    if now - lastTargetCheck < 0.2 then return end
    lastTargetCheck = now

    local closestTarget = nil
    local closestDistance = AIM_FOV

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character and shouldShowPlayer(player, AIM_TEAM_FILTER) then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local targetPart = getTargetPart(player.Character, AIM_TARGET_PART)
                if targetPart and isVisible(targetPart) then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen and screenPos.Z > 0 then
                        local mousePos = UserInputService:GetMouseLocation()
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if dist < closestDistance then
                            closestDistance = dist
                            closestTarget = targetPart
                        end
                    end
                end
            end
        end
    end

    currentTarget = closestTarget
end)

-- Suavização do movimento da câmera
RunService.RenderStepped:Connect(function()
    if AIM_ENABLED and currentTarget then
        local targetPos = currentTarget.Position
        local camPos = Camera.CFrame.Position
        local direction = (targetPos - camPos).Unit
        local newLook = CFrame.new(camPos, camPos + direction)
        Camera.CFrame = Camera.CFrame:Lerp(newLook, AIM_SMOOTH)
    end
end)

-- ==================================================================================
-- ============================ PROTECTION TAB ======================================
-- ==================================================================================

TabProt:CreateSection("Proteções")

local godMode = false
local lockHP = false
local antiVoid = false
local antiKB = false

-- God Mode
TabProt:CreateToggle({
    Name = "God Mode",
    CurrentValue = false,
    Callback = function(v)
        godMode = v
    end
})

-- Lock HP
TabProt:CreateToggle({
    Name = "Travar HP no Máximo",
    CurrentValue = false,
    Callback = function(v)
        lockHP = v
    end
})

-- Anti Void
TabProt:CreateToggle({
    Name = "Anti Void",
    CurrentValue = false,
    Callback = function(v)
        antiVoid = v
    end
})

-- Anti Knockback
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

local originalBrightness = Lighting.Brightness
local originalClockTime = Lighting.ClockTime
local originalFogEnd = Lighting.FogEnd
local originalGlobalShadows = Lighting.GlobalShadows

TabVisuals:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Callback = function(v)
        if v then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
        else
            Lighting.Brightness = originalBrightness
            Lighting.ClockTime = originalClockTime
            Lighting.FogEnd = originalFogEnd
            Lighting.GlobalShadows = originalGlobalShadows
        end
    end
})

TabVisuals:CreateSection("Câmera")

TabVisuals:CreateToggle({
    Name = "Remover Zoom Máximo",
    CurrentValue = false,
    Callback = function(v)
        if v then
            LP.CameraMaxZoomDistance = math.huge
        else
            LP.CameraMaxZoomDistance = 128
        end
    end
})

-- ==================================================================================
-- ================================ WORLD TAB =======================================
-- ==================================================================================

TabWorld:CreateSection("Tempo e Ambiente")

TabWorld:CreateSlider({
    Name = "Hora do Dia",
    Range = {0, 24},
    Increment = 0.5,
    CurrentValue = 12,
    Callback = function(v)
        Lighting.ClockTime = v
    end
})

TabWorld:CreateSlider({
    Name = "Final da Névoa",
    Range = {100, 100000},
    Increment = 100,
    CurrentValue = 1000,
    Callback = function(v)
        Lighting.FogEnd = v
    end
})

TabWorld:CreateButton({
    Name = "Remover Completamente a Névoa",
    Callback = function()
        Lighting.FogEnd = 100000
    end
})

-- ==================================================================================
-- ================================ FPS/STATS TAB ===================================
-- ==================================================================================

TabFPS:CreateSection("Anti-Lag")

local ANTI_LAG_ENABLED = false

local function applyAntiLag()
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

local noclip = false

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
    
    if antiFall and HRP.Velocity.Y < -50 then
        HRP.Velocity = Vector3.new(HRP.Velocity.X, 0, HRP.Velocity.Z)
    end
end)

print("✅ Universal Hub - Complete Edition - 100% Funcional!")
print("🎯 Sistema de Times Integrado em ESP, Highlight e Aim Assist!")
print("📊 Filtros: All / MyTeam / EnemyTeam")
print("⚡ Todas as funcionalidades do oficial + sistema de times do fixed!")
print("🔥 By ZakyzVortex - Organizado na ordem oficial!")