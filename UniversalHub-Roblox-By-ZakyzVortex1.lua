-- ================== UNIVERSAL HUB - FIXED WALLCHECK & TEAM FILTERS V2 ==================
-- By ZakyzVortex - Correções para Arsenal e outros jogos com times
-- Versão 2: ESP e Aim Assistant com verificações aprimoradas + Sem FOV Circle

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

-- ================== TEAM DETECTION SYSTEM (MELHORADO) ==================
local function isValidPlayer(player)
    if not player then return false end
    if player == LP then return false end
    if not player:IsA("Player") then return false end
    if not Players:FindFirstChild(player.Name) then return false end
    return true
end

local function isCharacterValid(character)
    if not character then return false end
    if not character.Parent then return false end
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    if hum.Health <= 0 then return false end
    return true
end

local function getPlayerTeam(player)
    if not player then return nil end
    return player.Team
end

local function isPlayerOnSameTeam(player)
    if not isValidPlayer(player) then return false end
    local myTeam = getPlayerTeam(LP)
    local theirTeam = getPlayerTeam(player)
    
    -- Se nenhum dos dois tem time, não são do mesmo time
    if not myTeam or not theirTeam then return false end
    
    -- Verifica se são do mesmo time
    return myTeam == theirTeam
end

local function shouldShowPlayer(player, filterMode)
    if not isValidPlayer(player) then return false end
    
    if filterMode == "All" then
        return true
    elseif filterMode == "MyTeam" or filterMode == "Team" then
        -- Só mostra se AMBOS tiverem time E forem do mesmo time
        local myTeam = getPlayerTeam(LP)
        local theirTeam = getPlayerTeam(player)
        if not myTeam or not theirTeam then return false end
        return isPlayerOnSameTeam(player)
    elseif filterMode == "EnemyTeam" or filterMode == "Enemy" then
        local myTeam = getPlayerTeam(LP)
        local theirTeam = getPlayerTeam(player)
        
        -- Se não houver sistema de times, mostra todos (exceto si mesmo)
        if not myTeam or not theirTeam then return true end
        
        -- Se houver times, só mostra se forem de times DIFERENTES
        return not isPlayerOnSameTeam(player)
    end
    
    return true
end

-- ================== WINDOW ==================
local Window = Rayfield:CreateWindow({
    Name = "Universal Hub - Fixed V2",
    LoadingTitle = "Universal Hub V2",
    LoadingSubtitle = "ESP & Aim Assistant Aprimorados",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "UniversalHub",
        FileName = "ConfigFixedV2"
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

local fly, flySpeed, flyUpImpulse = false, 100, 0
local infJump, antiFall = false, false

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

TabMove:CreateToggle({
    Name = "Anti Queda",
    CurrentValue = false,
    Flag = "AntiFall",
    Callback = function(v)
        antiFall = v
    end
})

UserInputService.JumpRequest:Connect(function()
    if fly then flyUpImpulse = 0.18 end
    if infJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ==================================================================================
-- ================================ COMBAT TAB ======================================
-- ==================================================================================

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
    Name = "CPS (Cliques por Segundo)",
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

TabCombat:CreateSection("Hit Range Extender")

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
    Name = "Ativar Hit Range Extender",
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

-- ==================================================================================
-- ================================== ESP TAB (MELHORADO) ===========================
-- ==================================================================================

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

local function removeESP(player)
    local espData = ESP_OBJECTS[player]
    if not espData then return end
    
    espData.active = false
    if espData.billboard then 
        pcall(function() espData.billboard:Destroy() end)
    end
    if espData.line then 
        pcall(function() espData.line:Remove() end)
    end
    if espData.outline then
        for _, l in ipairs(espData.outline) do 
            pcall(function() l:Remove() end)
        end
    end
    if espData.connections then
        for _, conn in ipairs(espData.connections) do
            pcall(function() conn:Disconnect() end)
        end
    end
    ESP_OBJECTS[player] = nil
end

local function createESP(player)
    -- Verificações rigorosas
    if not isValidPlayer(player) then return end
    
    -- FILTRO DE TIME APLICADO COM VERIFICAÇÕES
    if not shouldShowPlayer(player, TEAM_FILTER) then
        removeESP(player)
        return
    end
    
    if ESP_OBJECTS[player] then removeESP(player) end
    
    local char = player.Character
    if not isCharacterValid(char) then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    local espData = {
        active = true,
        player = player,
        character = char
    }

    if NAME_ENABLED or DISTANCE_ENABLED or HEALTH_ENABLED then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESPName"
        billboard.Adornee = hrp
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = 2000

        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.TextColor3 = ESP_COLOR
        txt.TextStrokeTransparency = 0
        txt.TextStrokeColor3 = Color3.new(0, 0, 0)
        txt.TextSize = 16
        txt.Font = Enum.Font.SourceSansBold
        txt.TextXAlignment = Enum.TextXAlignment.Center
        txt.TextYAlignment = Enum.TextYAlignment.Center
        txt.Parent = billboard
        billboard.Parent = hrp

        espData.billboard = billboard
        espData.txt = txt
    end

    if LINE_ENABLED then
        local line = Drawing.new("Line")
        line.Color = LINE_COLOR
        line.Thickness = 2
        line.Transparency = 1
        line.Visible = false
        line.ZIndex = 1
        espData.line = line
    end

    if OUTLINE_ENABLED then
        espData.outline = {}
        for i = 1, 4 do
            local l = Drawing.new("Line")
            l.Color = ESP_COLOR
            l.Thickness = 2
            l.Transparency = 1
            l.Visible = false
            l.ZIndex = 2
            table.insert(espData.outline, l)
        end
    end

    ESP_OBJECTS[player] = espData

    local connections = {}
    table.insert(connections, hum.Died:Connect(function()
        task.wait(0.1)
        removeESP(player)
    end))
    table.insert(connections, char.AncestryChanged:Connect(function(_, parent)
        if not parent then removeESP(player) end
    end))
    espData.connections = connections
end

local function clearAllESP()
    for player, _ in pairs(ESP_OBJECTS) do
        removeESP(player)
    end
    ESP_OBJECTS = {}
end

local function refreshESP()
    clearAllESP()
    if ESP_ENABLED then
        for _, p in ipairs(Players:GetPlayers()) do
            if isValidPlayer(p) then
                task.spawn(createESP, p)
            end
        end
    end
end

local lastESPUpdate = 0
RunService.RenderStepped:Connect(function()
    local now = tick()
    if now - lastESPUpdate < 1/60 then return end
    lastESPUpdate = now
    
    if not ESP_ENABLED or not HRP then
        for _, espData in pairs(ESP_OBJECTS) do
            if espData.line then espData.line.Visible = false end
            if espData.outline then
                for _, l in ipairs(espData.outline) do l.Visible = false end
            end
        end
        return
    end

    local cam = Camera
    local viewportSize = cam.ViewportSize
    local viewportCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y)

    for player, espData in pairs(ESP_OBJECTS) do
        if not espData.active then continue end
        
        -- Verificações rigorosas de validade do player
        if not isValidPlayer(player) then
            removeESP(player)
            continue
        end
        
        -- Verifica filtro de time continuamente
        if not shouldShowPlayer(player, TEAM_FILTER) then
            removeESP(player)
            continue
        end

        local char = player.Character
        if not isCharacterValid(char) or char ~= espData.character then
            removeESP(player)
            continue
        end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")

        if not hrp or not hum or hum.Health <= 0 then
            if espData.line then espData.line.Visible = false end
            if espData.outline then
                for _, l in ipairs(espData.outline) do l.Visible = false end
            end
            continue
        end

        local hrpPos = hrp.Position
        local distance = (hrpPos - HRP.Position).Magnitude
        local screenPos, onScreen = cam:WorldToViewportPoint(hrpPos)
        local inFrontOfCamera = screenPos.Z > 0

        if espData.txt then
            local parts = {}
            if NAME_ENABLED then table.insert(parts, player.Name) end
            if DISTANCE_ENABLED then table.insert(parts, string.format("[%dm]", math.floor(distance))) end
            if HEALTH_ENABLED then table.insert(parts, string.format("HP:%d", math.floor(hum.Health))) end
            espData.txt.Text = table.concat(parts, " | ")
        end

        if espData.line and LINE_ENABLED then
            if onScreen and inFrontOfCamera then
                espData.line.From = viewportCenter
                espData.line.To = Vector2.new(screenPos.X, screenPos.Y)
                espData.line.Visible = true
            else
                espData.line.Visible = false
            end
        elseif espData.line then
            espData.line.Visible = false
        end

        if espData.outline and OUTLINE_ENABLED then
            if onScreen and inFrontOfCamera then
                local height = 2.5
                local width = 1.5
                local rightVector = cam.CFrame.RightVector

                local corners = {
                    hrpPos + rightVector * width + Vector3.new(0, height, 0),
                    hrpPos - rightVector * width + Vector3.new(0, height, 0),
                    hrpPos - rightVector * width + Vector3.new(0, -height, 0),
                    hrpPos + rightVector * width + Vector3.new(0, -height, 0)
                }

                local screenCorners = {}
                local allVisible = true

                for i, corner in ipairs(corners) do
                    local pos, visible = cam:WorldToViewportPoint(corner)
                    if not visible or pos.Z <= 0 then
                        allVisible = false
                        break
                    end
                    screenCorners[i] = Vector2.new(pos.X, pos.Y)
                end

                if allVisible then
                    for i = 1, 4 do
                        local nextIndex = (i % 4) + 1
                        espData.outline[i].From = screenCorners[i]
                        espData.outline[i].To = screenCorners[nextIndex]
                        espData.outline[i].Visible = true
                    end
                else
                    for _, l in ipairs(espData.outline) do l.Visible = false end
                end
            else
                for _, l in ipairs(espData.outline) do l.Visible = false end
            end
        elseif espData.outline then
            for _, l in ipairs(espData.outline) do l.Visible = false end
        end
    end
end)

local function initializeExistingPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        if isValidPlayer(player) then
            if player.Character and ESP_ENABLED then
                createESP(player)
            end
            player.CharacterAdded:Connect(function(char)
                char:WaitForChild("HumanoidRootPart", 5)
                task.wait(0.5)
                if ESP_ENABLED and isValidPlayer(player) then 
                    createESP(player) 
                end
            end)
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart", 5)
        task.wait(0.5)
        if ESP_ENABLED and isValidPlayer(player) then 
            createESP(player) 
        end
    end)
    if player.Character then
        task.wait(0.5)
        if ESP_ENABLED and isValidPlayer(player) then 
            createESP(player) 
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

initializeExistingPlayers()

TabESP:CreateSection("Controles do ESP")

TabESP:CreateToggle({
    Name = "Ativar ESP",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(v)
        ESP_ENABLED = v
        refreshESP()
    end
})

TabESP:CreateToggle({
    Name = "Mostrar Nome",
    CurrentValue = true,
    Flag = "ESPName",
    Callback = function(v)
        NAME_ENABLED = v
    end
})

TabESP:CreateToggle({
    Name = "Mostrar Distância",
    CurrentValue = true,
    Flag = "ESPDistance",
    Callback = function(v)
        DISTANCE_ENABLED = v
    end
})

TabESP:CreateToggle({
    Name = "Mostrar Vida",
    CurrentValue = true,
    Flag = "ESPHealth",
    Callback = function(v)
        HEALTH_ENABLED = v
    end
})

TabESP:CreateToggle({
    Name = "Linha Única",
    CurrentValue = true,
    Flag = "ESPLine",
    Callback = function(v)
        LINE_ENABLED = v
    end
})

TabESP:CreateToggle({
    Name = "Contorno 4 Linhas",
    CurrentValue = true,
    Flag = "ESPOutline",
    Callback = function(v)
        OUTLINE_ENABLED = v
    end
})

TabESP:CreateDropdown({
    Name = "Filtro de Time",
    Options = {"All", "MyTeam", "EnemyTeam"},
    CurrentOption = "All",
    Flag = "ESPTeamFilter",
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
            Content = "ESP recarregado!",
            Duration = 2
        })
    end
})

TabESP:CreateSection("Cores")

TabESP:CreateColorPicker({
    Name = "Cor do ESP",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "ESPColor",
    Callback = function(color)
        ESP_COLOR = color
    end
})

TabESP:CreateColorPicker({
    Name = "Cor da Linha",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "LineColor",
    Callback = function(color)
        LINE_COLOR = color
    end
})

-- ==================================================================================
-- ========================= HIGHLIGHT ESP TAB (MELHORADO) =========================
-- ==================================================================================

local HIGHLIGHT_ENABLED = false
local HIGHLIGHT_TEAM_FILTER = "All"
local teamColor = Color3.fromRGB(0, 255, 0)
local enemyColor = Color3.fromRGB(255, 0, 0)
local highlightCache = {}
local highlightFillTrans = 0.5
local highlightOutlineTrans = 0
local highlightDepthMode = Enum.HighlightDepthMode.AlwaysOnTop

local function addHighlight(player)
    -- Verificações rigorosas
    if not isValidPlayer(player) then return end
    
    -- FILTRO DE TIME APLICADO COM VERIFICAÇÕES
    if not shouldShowPlayer(player, HIGHLIGHT_TEAM_FILTER) then
        if highlightCache[player] then
            pcall(function() highlightCache[player]:Destroy() end)
            highlightCache[player] = nil
        end
        return
    end
    
    local char = player.Character
    if not isCharacterValid(char) then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    if highlightCache[player] then
        pcall(function() highlightCache[player]:Destroy() end)
        highlightCache[player] = nil
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "UniversalHighlight"
    highlight.Adornee = char
    highlight.DepthMode = highlightDepthMode
    
    if isPlayerOnSameTeam(player) then
        highlight.FillColor = teamColor
        highlight.OutlineColor = teamColor
    else
        highlight.FillColor = enemyColor
        highlight.OutlineColor = enemyColor
    end
    
    highlight.FillTransparency = highlightFillTrans
    highlight.OutlineTransparency = highlightOutlineTrans
    highlight.Parent = hrp
    
    highlightCache[player] = highlight
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Died:Connect(function()
            task.wait(0.1)
            if highlightCache[player] then
                pcall(function() highlightCache[player]:Destroy() end)
                highlightCache[player] = nil
            end
        end)
    end
end

local function removeHighlight(player)
    if highlightCache[player] then
        pcall(function() highlightCache[player]:Destroy() end)
        highlightCache[player] = nil
    end
end

local function removeAllHighlights()
    for player, highlight in pairs(highlightCache) do
        pcall(function() highlight:Destroy() end)
    end
    highlightCache = {}
end

local function updateAllHighlights()
    removeAllHighlights()
    if HIGHLIGHT_ENABLED then
        for _, player in ipairs(Players:GetPlayers()) do
            if isValidPlayer(player) and player.Character then
                addHighlight(player)
            end
        end
    end
end

local function initializeExistingPlayersHighlight()
    for _, player in ipairs(Players:GetPlayers()) do
        if isValidPlayer(player) then
            if player.Character and HIGHLIGHT_ENABLED then
                addHighlight(player)
            end
            player.CharacterAdded:Connect(function(char)
                char:WaitForChild("HumanoidRootPart", 5)
                task.wait(0.3)
                if HIGHLIGHT_ENABLED and isValidPlayer(player) then 
                    addHighlight(player) 
                end
            end)
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart", 5)
        task.wait(0.3)
        if HIGHLIGHT_ENABLED and isValidPlayer(player) then 
            addHighlight(player) 
        end
    end)
    if player.Character then
        task.wait(0.3)
        if HIGHLIGHT_ENABLED and isValidPlayer(player) then 
            addHighlight(player) 
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeHighlight(player)
end)

initializeExistingPlayersHighlight()

local lastHighlightCheck = 0
RunService.RenderStepped:Connect(function()
    if not HIGHLIGHT_ENABLED then return end
    
    local now = tick()
    if now - lastHighlightCheck < 2 then return end
    lastHighlightCheck = now
    
    -- Verifica filtros de time e validade continuamente
    for _, player in ipairs(Players:GetPlayers()) do
        if isValidPlayer(player) and player.Character then
            if shouldShowPlayer(player, HIGHLIGHT_TEAM_FILTER) and isCharacterValid(player.Character) then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp and not highlightCache[player] then
                    addHighlight(player)
                end
            else
                removeHighlight(player)
            end
        end
    end
end)

TabHighlight:CreateSection("Controles do Highlight")

TabHighlight:CreateToggle({
    Name = "Ativar Highlight ESP",
    CurrentValue = false,
    Flag = "HighlightESP",
    Callback = function(v)
        HIGHLIGHT_ENABLED = v
        updateAllHighlights()
    end
})

TabHighlight:CreateDropdown({
    Name = "Filtro de Time",
    Options = {"All", "MyTeam", "EnemyTeam"},
    CurrentOption = "All",
    Flag = "HighlightTeamFilter",
    Callback = function(option)
        HIGHLIGHT_TEAM_FILTER = option
        updateAllHighlights()
    end
})

TabHighlight:CreateSection("Cores")

TabHighlight:CreateColorPicker({
    Name = "Cor do Time",
    Color = Color3.fromRGB(0, 255, 0),
    Flag = "TeamColor",
    Callback = function(color)
        teamColor = color
        updateAllHighlights()
    end
})

TabHighlight:CreateColorPicker({
    Name = "Cor dos Inimigos",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "EnemyColor",
    Callback = function(color)
        enemyColor = color
        updateAllHighlights()
    end
})

TabHighlight:CreateSection("Configurações")

TabHighlight:CreateSlider({
    Name = "Transparência do Preenchimento",
    Range = {0, 1},
    Increment = 0.05,
    CurrentValue = 0.5,
    Flag = "HighlightFillTrans",
    Callback = function(v)
        highlightFillTrans = v
        for _, highlight in pairs(highlightCache) do
            if highlight then highlight.FillTransparency = v end
        end
    end
})

TabHighlight:CreateSlider({
    Name = "Transparência do Contorno",
    Range = {0, 1},
    Increment = 0.05,
    CurrentValue = 0,
    Flag = "HighlightOutlineTrans",
    Callback = function(v)
        highlightOutlineTrans = v
        for _, highlight in pairs(highlightCache) do
            if highlight then highlight.OutlineTransparency = v end
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
        for _, highlight in pairs(highlightCache) do
            if highlight then highlight.DepthMode = highlightDepthMode end
        end
    end
})

TabHighlight:CreateButton({
    Name = "Atualizar Highlights",
    Callback = function()
        updateAllHighlights()
        Rayfield:Notify({
            Title = "Highlights Atualizados",
            Content = "Recarregado!",
            Duration = 2
        })
    end
})

-- ==================================================================================
-- ===================== AIM ASSIST TAB (MELHORADO - SEM FOV CIRCLE) ===============
-- ==================================================================================

local AIM_ENABLED = false
local AIM_FOV = 100
local AIM_SMOOTH = 0.2
local AIM_TARGET_PART = "Head"
local AIM_WALLCHECK = true
local AIM_TEAM_FILTER = "EnemyTeam"
local currentTarget = nil

-- WALLCHECK MELHORADO COM MAIS VERIFICAÇÕES
local function isVisible(targetPart)
    if not AIM_WALLCHECK then return true end
    if not Character or not targetPart then return false end
    if not targetPart.Parent then return false end
    
    -- Verifica se o alvo ainda está vivo
    local targetHum = targetPart.Parent:FindFirstChildOfClass("Humanoid")
    if targetHum and targetHum.Health <= 0 then return false end
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    -- Ignora o próprio personagem E o personagem do alvo
    rayParams.FilterDescendantsInstances = {Character, targetPart.Parent}
    rayParams.IgnoreWater = true
    
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    
    local result = workspace:Raycast(origin, direction, rayParams)
    
    -- Se não atingiu nada, está visível
    if not result then return true end
    
    -- Se atingiu algo transparente (vidro, etc), considera visível
    if result.Instance.Transparency >= 0.9 then return true end
    
    -- Se atingiu parte do próprio alvo, está visível
    if result.Instance:IsDescendantOf(targetPart.Parent) then return true end
    
    -- Verifica se é uma parte não sólida
    if not result.Instance.CanCollide then return true end
    
    -- Caso contrário, está atrás de uma parede
    return false
end

local function getTargetPart(character, partName)
    if not character then return nil end
    
    local part = character:FindFirstChild(partName)
    if part and part:IsA("BasePart") then return part end
    
    -- Fallback para Arsenal e jogos similares
    if partName == "Head" then
        local head = character:FindFirstChild("Head")
        if head then return head end
    elseif partName == "HumanoidRootPart" then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then return hrp end
        local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
        if torso then return torso end
    elseif partName == "UpperTorso" then
        local upper = character:FindFirstChild("UpperTorso")
        if upper then return upper end
        local torso = character:FindFirstChild("Torso")
        if torso then return torso end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then return hrp end
    elseif partName == "LowerTorso" then
        local lower = character:FindFirstChild("LowerTorso")
        if lower then return lower end
        local torso = character:FindFirstChild("Torso")
        if torso then return torso end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then return hrp end
    end
    
    -- Último fallback
    return character:FindFirstChild("HumanoidRootPart")
end

TabAim:CreateSection("Controles do Aim Assist")

TabAim:CreateToggle({
    Name = "Ativar Aim Assist",
    CurrentValue = false,
    Flag = "AimAssist",
    Callback = function(v)
        AIM_ENABLED = v
        currentTarget = nil
    end
})

TabAim:CreateDropdown({
    Name = "Filtro de Time",
    Options = {"All", "MyTeam", "EnemyTeam"},
    CurrentOption = "EnemyTeam",
    Flag = "AimTeamFilter",
    Callback = function(option)
        AIM_TEAM_FILTER = option
        currentTarget = nil
    end
})

TabAim:CreateSection("Configurações")

TabAim:CreateToggle({
    Name = "Wallcheck (Não atirar através de paredes)",
    CurrentValue = true,
    Flag = "AimWallcheck",
    Callback = function(v)
        AIM_WALLCHECK = v
        currentTarget = nil
    end
})

TabAim:CreateSlider({
    Name = "FOV (Campo de Visão)",
    Range = {10, 500},
    Increment = 10,
    CurrentValue = 100,
    Flag = "AimFOV",
    Callback = function(v)
        AIM_FOV = v
    end
})

TabAim:CreateSlider({
    Name = "Suavidade",
    Range = {0.05, 1},
    Increment = 0.05,
    CurrentValue = 0.2,
    Flag = "AimSmoothness",
    Callback = function(v)
        AIM_SMOOTH = v
    end
})

TabAim:CreateDropdown({
    Name = "Parte do Corpo",
    Options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    CurrentOption = "Head",
    Flag = "AimTargetPart",
    Callback = function(option)
        AIM_TARGET_PART = option
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

-- Runtime do Aim (MELHORADO com mais verificações)
local lastTargetCheck = 0
RunService.RenderStepped:Connect(function()
    if not AIM_ENABLED or not HRP or not Character then
        return
    end

    local now = tick()
    if now - lastTargetCheck < 0.1 then return end
    lastTargetCheck = now

    local closestTarget = nil
    local closestDistance = AIM_FOV
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        -- Verificações rigorosas
        if not isValidPlayer(player) then continue end
        
        -- FILTRO DE TIME APLICADO COM VERIFICAÇÕES
        if not shouldShowPlayer(player, AIM_TEAM_FILTER) then continue end
        
        local char = player.Character
        if not isCharacterValid(char) then continue end
        
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        
        local targetPart = getTargetPart(char, AIM_TARGET_PART)
        if not targetPart then continue end
        
        -- WALLCHECK APLICADO COM MAIS VERIFICAÇÕES
        if not isVisible(targetPart) then continue end
        
        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen or screenPos.Z <= 0 then continue end
        
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        if dist < closestDistance then
            closestDistance = dist
            closestTarget = targetPart
        end
    end

    -- Valida o alvo antes de atribuir
    if closestTarget and closestTarget.Parent then
        local targetHum = closestTarget.Parent:FindFirstChildOfClass("Humanoid")
        if targetHum and targetHum.Health > 0 then
            currentTarget = closestTarget
        else
            currentTarget = nil
        end
    else
        currentTarget = nil
    end
end)

-- Suavização da câmera (com verificações extras)
RunService.RenderStepped:Connect(function()
    if not AIM_ENABLED then return end
    if not currentTarget or not currentTarget.Parent then 
        currentTarget = nil
        return 
    end
    
    -- Verifica se o alvo ainda está vivo
    local targetHum = currentTarget.Parent:FindFirstChildOfClass("Humanoid")
    if not targetHum or targetHum.Health <= 0 then
        currentTarget = nil
        return
    end
    
    local targetPos = currentTarget.Position
    local camPos = Camera.CFrame.Position
    local direction = (targetPos - camPos).Unit
    local newLook = CFrame.new(camPos, camPos + direction)
    Camera.CFrame = Camera.CFrame:Lerp(newLook, AIM_SMOOTH)
end)

-- ==================================================================================
-- ============================== PROTECTION TAB ====================================
-- ==================================================================================

TabProt:CreateSection("Proteções")

local godMode, lockHP, antiKB, antiVoid = false, false, false, false

TabProt:CreateToggle({
    Name = "God Mode",
    CurrentValue = false,
    Flag = "GodMode",
    Callback = function(v) godMode = v end
})

TabProt:CreateToggle({
    Name = "Lock HP",
    CurrentValue = false,
    Flag = "LockHP",
    Callback = function(v) lockHP = v end
})

TabProt:CreateToggle({
    Name = "Anti Knockback",
    CurrentValue = false,
    Flag = "AntiKB",
    Callback = function(v) antiKB = v end
})

TabProt:CreateToggle({
    Name = "Anti Void",
    CurrentValue = false,
    Flag = "AntiVoid",
    Callback = function(v) antiVoid = v end
})

-- ==================================================================================
-- ================================ PLAYERS TAB =====================================
-- ==================================================================================

TabPlayers:CreateSection("Teleporte e Spectate")

local selectedName = nil

local function getPlayerNames()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(t, p.Name) end
    end
    return t
end

local playerDropdown = TabPlayers:CreateDropdown({
    Name = "Selecionar Player",
    Options = getPlayerNames(),
    CurrentOption = getPlayerNames()[1] or "Nenhum",
    Flag = "SelectedPlayer",
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
            local targetHRP = t.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                HRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, -3)
            end
        end
    end
})

TabPlayers:CreateButton({
    Name = "Spectate Player",
    Callback = function()
        local t = Players:FindFirstChild(selectedName)
        if t and t.Character then
            Camera.CameraSubject = t.Character.Humanoid
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

TabWaypoints:CreateSection("Waypoints")

local waypoints = {}

TabWaypoints:CreateInput({
    Name = "Nome do Waypoint",
    PlaceholderText = "Digite o nome",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        waypoints.currentName = text
    end
})

TabWaypoints:CreateButton({
    Name = "Criar Waypoint",
    Callback = function()
        if HRP and waypoints.currentName then
            waypoints[waypoints.currentName] = HRP.CFrame
            Rayfield:Notify({
                Title = "Waypoint Criado",
                Content = waypoints.currentName,
                Duration = 2
            })
        end
    end
})

local waypointDropdown = TabWaypoints:CreateDropdown({
    Name = "Waypoints Salvos",
    Options = {},
    CurrentOption = "Nenhum",
    Flag = "WaypointSelect",
    Callback = function(v)
        waypoints.selected = v
    end
})

TabWaypoints:CreateButton({
    Name = "TP para Waypoint",
    Callback = function()
        if waypoints.selected and waypoints[waypoints.selected] and HRP then
            HRP.CFrame = waypoints[waypoints.selected]
        end
    end
})

TabWaypoints:CreateButton({
    Name = "Atualizar Lista",
    Callback = function()
        local list = {}
        for k, _ in pairs(waypoints) do
            if k ~= "currentName" and k ~= "selected" then
                table.insert(list, k)
            end
        end
        waypointDropdown:Refresh(list)
    end
})

-- ==================================================================================
-- =============================== VISUALS TAB ======================================
-- ==================================================================================

TabVisuals:CreateSection("Ambiente")

local originalFog, originalBrightness, originalAmbient, originalOutdoorAmbient, originalClock

TabVisuals:CreateToggle({
    Name = "Remover Fog",
    CurrentValue = false,
    Flag = "NoFog",
    Callback = function(v)
        if v then
            originalFog = Lighting.FogEnd
            Lighting.FogEnd = 100000
        else
            Lighting.FogEnd = originalFog or 100000
        end
    end
})

TabVisuals:CreateToggle({
    Name = "Full Bright",
    CurrentValue = false,
    Flag = "FullBright",
    Callback = function(v)
        if v then
            originalBrightness = Lighting.Brightness
            originalAmbient = Lighting.Ambient
            originalOutdoorAmbient = Lighting.OutdoorAmbient
            originalClock = Lighting.ClockTime
            
            Lighting.Brightness = 2
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.ClockTime = 14
        else
            Lighting.Brightness = originalBrightness or 1
            Lighting.Ambient = originalAmbient or Color3.fromRGB(128, 128, 128)
            Lighting.OutdoorAmbient = originalOutdoorAmbient or Color3.fromRGB(128, 128, 128)
            Lighting.ClockTime = originalClock or 14
        end
    end
})

TabVisuals:CreateSlider({
    Name = "FOV (Campo de Visão)",
    Range = {70, 120},
    Increment = 1,
    CurrentValue = 70,
    Flag = "FOV",
    Callback = function(v)
        Camera.FieldOfView = v
    end
})

-- ==================================================================================
-- ================================= WORLD TAB ======================================
-- ==================================================================================

TabWorld:CreateSection("Gravidade")

TabWorld:CreateSlider({
    Name = "Gravidade",
    Range = {0, 196},
    Increment = 1,
    CurrentValue = 196,
    Flag = "Gravity",
    Callback = function(v)
        workspace.Gravity = v
    end
})

TabWorld:CreateButton({
    Name = "Resetar Gravidade",
    Callback = function()
        workspace.Gravity = 196
    end
})

-- ==================================================================================
-- ================================ FPS/STATS TAB ===================================
-- ==================================================================================

TabFPS:CreateSection("Otimização")

local ANTI_LAG_ENABLED = false

local function applyAntiLag()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
        end
    end
end

TabFPS:CreateToggle({
    Name = "Ativar Anti-Lag",
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
    Flag = "AntiAFK",
    Callback = function(v)
        ANTI_AFK_ENABLED = v
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
    Flag = "KeybindESP",
    Callback = function(key)
        keybindESP = key
    end
})

TabConfig:CreateKeybind({
    Name = "Toggle Aim",
    CurrentKeybind = "R",
    HoldToInteract = false,
    Flag = "KeybindAim",
    Callback = function(key)
        keybindAim = key
    end
})

TabConfig:CreateKeybind({
    Name = "Toggle GUI",
    CurrentKeybind = "RightControl",
    HoldToInteract = false,
    Flag = "KeybindGUI",
    Callback = function(key)
        keybindGUI = key
    end
})

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == keybindESP then
        ESP_ENABLED = not ESP_ENABLED
        refreshESP()
        Rayfield:Notify({
            Title = "ESP",
            Content = ESP_ENABLED and "Ativado" or "Desativado",
            Duration = 1
        })
    elseif input.KeyCode == keybindAim then
        AIM_ENABLED = not AIM_ENABLED
        Rayfield:Notify({
            Title = "Aim Assist",
            Content = AIM_ENABLED and "Ativado" or "Desativado",
            Duration = 1
        })
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
    
    if antiFall then
        local ray = Ray.new(HRP.Position, Vector3.new(0, -5, 0))
        local hit = workspace:FindPartOnRay(ray, Character)
        if not hit and HRP.Velocity.Y < 0 then
            HRP.Velocity = Vector3.new(HRP.Velocity.X, 0, HRP.Velocity.Z)
        end
    end
end)

-- ==================================================================================
-- ================================= FINAL LOGS =====================================
-- ==================================================================================

print("✅ Universal Hub V2 - ESP & AIM ASSISTANT APRIMORADOS")
print("🎯 Aimbot: Wallcheck melhorado + Filtros de time + Mais verificações + SEM FOV Circle")
print("📊 ESP: Filtros de time melhorados + Verificações rigorosas de validade")
print("✨ Highlight ESP: Filtros de time melhorados + Verificações rigorosas")
print("🔧 Testado e otimizado para Arsenal e jogos com times")
print("⚡ Todas as funções preservadas + Melhorias implementadas")