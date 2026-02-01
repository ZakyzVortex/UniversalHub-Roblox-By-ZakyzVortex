-- ================== UNIVERSAL HUB - MERGED ==================
-- Universal Hub Rayfield By ZakyzVortex (Mobile Optimized & Organized)
-- Versão: Official + Team Checker no Highlight ESP, ESP e Aim Assist

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

-- ================== TEAM DETECTION (da versão fixed) ==================
local function isPlayerOnSameTeam(player)
    if not LP.Team or not player.Team then return false end
    return player.Team == LP.Team
end

local function shouldShowPlayer(player, filterMode)
    if filterMode == "All" then
        return true
    elseif filterMode == "MyTeam" or filterMode == "Team" then
        if not LP.Team or not player.Team then return false end
        return isPlayerOnSameTeam(player)
    elseif filterMode == "EnemyTeam" or filterMode == "Enemy" then
        if not LP.Team or not player.Team then return true end
        return not isPlayerOnSameTeam(player)
    end
    return true
end

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
local TEAM_FILTER = "All"  -- All, MyTeam, EnemyTeam

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

    -- ===== TEAM CHECKER (da versão fixed) =====
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

    -- Linha
    if LINE_ENABLED then
        local line = Drawing.new("Line")
        line.Color = LINE_COLOR
        line.Thickness = 2
        line.Transparency = 1
        line.Visible = false
        line.ZIndex = 1
        espData.line = line
    end

    -- Contorno
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

    -- Conexões de cleanup
    local connections = {}
    
    table.insert(connections, hum.Died:Connect(function()
        task.wait(0.1)
        removeESP(player)
        for _, conn in ipairs(connections) do
            pcall(function() conn:Disconnect() end)
        end
    end))
    
    table.insert(connections, char.AncestryChanged:Connect(function(_, parent)
        if not parent then
            removeESP(player)
            for _, conn in ipairs(connections) do
                pcall(function() conn:Disconnect() end)
            end
        end
    end))
    
    espData.connections = connections
end

-- Função para limpar todo ESP
local function clearAllESP()
    for player, _ in pairs(ESP_OBJECTS) do
        removeESP(player)
    end
    ESP_OBJECTS = {}
end

-- Função para atualizar ESP
local function refreshESP()
    clearAllESP()
    if ESP_ENABLED then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                task.spawn(createESP, p)
            end
        end
    end
end

-- Update loop
local lastESPUpdate = 0
local UPDATE_RATE = 1/60

RunService.RenderStepped:Connect(function()
    local now = tick()
    if now - lastESPUpdate < UPDATE_RATE then return end
    lastESPUpdate = now
    
    if not ESP_ENABLED or not HRP then
        for _, espData in pairs(ESP_OBJECTS) do
            if espData.line then espData.line.Visible = false end
            if espData.outline then
                for _, l in ipairs(espData.outline) do
                    l.Visible = false
                end
            end
        end
        return
    end

    local cam = Camera
    local camCFrame = cam.CFrame
    local viewportSize = cam.ViewportSize
    local viewportCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y)

    for player, espData in pairs(ESP_OBJECTS) do
        if not espData.active then continue end

        local char = player.Character
        if not char or char ~= espData.character then
            removeESP(player)
            continue
        end

        -- ===== TEAM CHECKER no update loop =====
        if not shouldShowPlayer(player, TEAM_FILTER) then
            removeESP(player)
            continue
        end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")

        if not hrp or not hrp.Parent or not hum or hum.Health <= 0 then
            if espData.line then espData.line.Visible = false end
            if espData.outline then
                for _, l in ipairs(espData.outline) do
                    l.Visible = false
                end
            end
            continue
        end

        local hrpPos = hrp.Position
        local toTarget = hrpPos - HRP.Position
        local distance = toTarget.Magnitude

        local screenPos, onScreen = cam:WorldToViewportPoint(hrpPos)
        local inFrontOfCamera = screenPos.Z > 0

        -- Atualiza texto
        if espData.txt then
            local parts = {}
            if NAME_ENABLED then
                table.insert(parts, player.Name)
            end
            if DISTANCE_ENABLED then
                table.insert(parts, string.format("[%dm]", math.floor(distance)))
            end
            if HEALTH_ENABLED then
                table.insert(parts, string.format("HP:%d", math.floor(hum.Health)))
            end
            espData.txt.Text = table.concat(parts, " | ")
        end

        -- Atualiza linha
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

        -- Atualiza contorno
        if espData.outline and OUTLINE_ENABLED then
            if onScreen and inFrontOfCamera then
                local height = 2.5
                local width = 1.5
                local rightVector = camCFrame.RightVector

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
                    for _, l in ipairs(espData.outline) do
                        l.Visible = false
                    end
                end
            else
                for _, l in ipairs(espData.outline) do
                    l.Visible = false
                end
            end
        elseif espData.outline then
            for _, l in ipairs(espData.outline) do
                l.Visible = false
            end
        end
    end
end)

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

-- ===== TEAM FILTER DROPDOWN NO ESP (usa shouldShowPlayer) =====
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
local highlightColor = Color3.fromRGB(255, 0, 0)
local highlightCache = {}
local HIGHLIGHT_TEAM_FILTER = "All"  -- All, MyTeam, EnemyTeam

-- Função para adicionar highlight
local function addHighlight(player)
    if player == LP then return end
    
    local char = player.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- ===== TEAM CHECKER no Highlight =====
    if not shouldShowPlayer(player, HIGHLIGHT_TEAM_FILTER) then return end
    
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
    removeAllHighlights()
    if HIGHLIGHT_ENABLED then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LP and player.Character then
                addHighlight(player)
            end
        end
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

-- Loop de verificação (também re-verifica team filter)
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
                -- Se não passa no filtro de time, remover highlight se existir
                if not shouldShowPlayer(player, HIGHLIGHT_TEAM_FILTER) then
                    removeHighlight(player)
                else
                    local existingHighlight = hrp:FindFirstChild("Highlight")
                    if not existingHighlight and not highlightCache[player] then
                        addHighlight(player)
                    end
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

-- ===== TEAM FILTER DROPDOWN NO HIGHLIGHT =====
TabHighlight:CreateDropdown({
    Name = "Filtro de Time",
    Options = {"All", "MyTeam", "EnemyTeam"},
    CurrentOption = "All",
    Callback = function(option)
        HIGHLIGHT_TEAM_FILTER = option
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
local AIM_MAX_DISTANCE = 1000
local AIM_TEAM_FILTER = "EnemyTeam"  -- Aim mira apenas em inimigos por padrão
local currentTarget = nil
local lastTargetCheck = 0

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

-- Função de wallcheck (versão fixed)
local function isVisible(targetPart)
    if not AIM_WALLCHECK then return true end
    if not targetPart or not HRP then return false end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {Character, targetPart.Parent}
    
    local ray = workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position), raycastParams)
    return ray == nil
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

TabAim:CreateSlider({
    Name = "Distância Máxima",
    Range = {100, 5000},
    Increment = 100,
    CurrentValue = 1000,
    Callback = function(v)
        AIM_MAX_DISTANCE = v
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

-- Runtime do Aim Assist (com team checker integrado)
RunService.RenderStepped:Connect(function()
    if not AIM_ENABLED or not HRP then return end

    local now = tick()
    if now - lastTargetCheck < 0.2 then return end
    lastTargetCheck = now

    -- Verificar se o alvo atual ainda é válido pelo filtro de time
    if currentTarget then
        if not currentTarget.Character then
            currentTarget = nil
        else
            local hum = currentTarget.Character:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then
                currentTarget = nil
            elseif not shouldShowPlayer(currentTarget, AIM_TEAM_FILTER) then
                currentTarget = nil
            end
        end
    end

    local closestTarget = nil
    local closestDistance = AIM_FOV

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            -- ===== TEAM CHECKER no Aim =====
            if not shouldShowPlayer(player, AIM_TEAM_FILTER) then continue end

            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local targetPart = getTargetPart(player.Character, AIM_TARGET_PART)
                if targetPart then
                    -- Verificar distância máxima
                    local worldDist = (HRP.Position - targetPart.Position).Magnitude
                    if worldDist <= AIM_MAX_DISTANCE then
                        if isVisible(targetPart) then
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
-- ============================== PROTECTION TAB ====================================
-- ==================================================================================

TabProt:CreateSection("Proteções")

local godMode, lockHP, antiKB, antiVoid, noclip = false, false, false, false, false

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

TabProt:CreateToggle({
    Name = "Anti Knockback",
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

print("✅ Universal Hub - Merged - Tudo Funcionando!")
print("🎯 Aim Assist com Team Checker (All / MyTeam / EnemyTeam)")
print("📊 ESP com Team Checker (All / MyTeam / EnemyTeam)")
print("✨ Highlight ESP com Team Checker (All / MyTeam / EnemyTeam)")