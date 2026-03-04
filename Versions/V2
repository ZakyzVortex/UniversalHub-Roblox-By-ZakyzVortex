-- Universal Hub Rayfield By ZakyzVortex (Mobile Optimized v2)
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Services (cache local)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Character refs
local Character, Humanoid, HRP
local function BindCharacter(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HRP = char:WaitForChild("HumanoidRootPart")
    Humanoid.UseJumpPower = true
end
BindCharacter(LP.Character or LP.CharacterAdded:Wait())
LP.CharacterAdded:Connect(BindCharacter)

-- UI
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

local TabMove = Window:CreateTab("Player / Movement")
local TabProt = Window:CreateTab("Protection")
local TabPlayers = Window:CreateTab("Players")
local TabWorld = Window:CreateTab("World")
local TabUtil = Window:CreateTab("Utility")

-- ================== ESP COMPLETO (SEM BUGS) ==================
local TabESP = Window:CreateTab("ESP")

-- Estados
local ESP_ENABLED = false
local NAME_ENABLED = true
local DISTANCE_ENABLED = true
local LINE_ENABLED = true
local HEALTH_ENABLED = true
local OUTLINE_ENABLED = true

local ESP_COLOR = Color3.fromRGB(255,0,0)
local LINE_COLOR = Color3.fromRGB(255,255,255)

local ESP_OBJECTS = {}
local TEAM_FILTER = "All"

-- Pool de Drawing objects para reutilização
local DrawingPool = {Lines = {}}

local function getDrawing(type)
    if type == "Line" then
        if #DrawingPool.Lines > 0 then
            return table.remove(DrawingPool.Lines)
        end
        return Drawing.new("Line")
    end
end

local function returnDrawing(drawing)
    if drawing then
        drawing.Visible = false
        table.insert(DrawingPool.Lines, drawing)
    end
end

local function getPlayerTeam(player)
    return player.Team and player.Team.Name or "NoTeam"
end

-- Função para limpar ESP de um jogador específico
local function removeESP(player)
    local espData = ESP_OBJECTS[player]
    if not espData then return end
    
    espData.active = false
    
    -- Remove billboard
    if espData.billboard then
        espData.billboard:Destroy()
        espData.billboard = nil
    end
    
    -- Retorna linha ao pool
    if espData.line then
        returnDrawing(espData.line)
        espData.line = nil
    end
    
    -- Retorna outline ao pool
    if espData.outline then
        for _, l in ipairs(espData.outline) do
            returnDrawing(l)
        end
        espData.outline = nil
    end
    
    ESP_OBJECTS[player] = nil
end

-- Função para criar ESP em um jogador
local function createESP(player)
    if player == LP then return end
    
    -- Remove ESP anterior se existir
    if ESP_OBJECTS[player] then
        removeESP(player)
    end
    
    local char = player.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    -- Filtro de time
    if TEAM_FILTER ~= "All" then
        local myTeam = getPlayerTeam(LP)
        local playerTeam = getPlayerTeam(player)
        if TEAM_FILTER == "MyTeam" and playerTeam ~= myTeam then return end
        if TEAM_FILTER == "EnemyTeam" and playerTeam == myTeam then return end
    end

    local espData = {
        active = true,
        player = player,
        character = char
    }

    -- Billboard (Nome/Distância/Vida)
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

    -- Linha única
    if LINE_ENABLED then
        local line = getDrawing("Line")
        line.Color = LINE_COLOR
        line.Thickness = 2
        line.Transparency = 1
        line.Visible = false
        line.ZIndex = 1
        espData.line = line
    end

    -- Contorno (4 linhas)
    if OUTLINE_ENABLED then
        espData.outline = {}
        for i = 1, 4 do
            local l = getDrawing("Line")
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
    
    -- Cleanup quando morrer
    table.insert(connections, hum.Died:Connect(function()
        task.wait(0.1)
        removeESP(player)
        for _, conn in ipairs(connections) do
            pcall(function() conn:Disconnect() end)
        end
    end))
    
    -- Cleanup quando personagem for removido
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

-- Função para limpar todo o ESP
local function clearAllESP()
    for player, _ in pairs(ESP_OBJECTS) do
        removeESP(player)
    end
    ESP_OBJECTS = {}
end

-- Função para atualizar todo o ESP
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

-- Update loop otimizado (60 FPS)
local lastESPUpdate = 0
local UPDATE_RATE = 1/60 -- 60 FPS

RunService.RenderStepped:Connect(function()
    local now = tick()
    if now - lastESPUpdate < UPDATE_RATE then return end
    lastESPUpdate = now
    
    if not ESP_ENABLED or not HRP then
        -- Esconde todos os drawings quando desativado
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
    local camPos = camCFrame.Position
    local viewportSize = cam.ViewportSize
    local viewportCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y)

    for player, espData in pairs(ESP_OBJECTS) do
        if not espData.active then continue end

        -- Valida personagem
        local char = player.Character
        if not char or char ~= espData.character then
            removeESP(player)
            continue
        end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")

        -- Valida se ainda está vivo
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

        -- Verifica se está na tela (check básico de distância)
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

                -- Calcula os 4 cantos do quadrado
                local corners = {
                    hrpPos + rightVector * width + Vector3.new(0, height, 0),
                    hrpPos - rightVector * width + Vector3.new(0, height, 0),
                    hrpPos - rightVector * width + Vector3.new(0, -height, 0),
                    hrpPos + rightVector * width + Vector3.new(0, -height, 0)
                }

                local screenCorners = {}
                local allVisible = true

                -- Converte todos os cantos para coordenadas de tela
                for i, corner in ipairs(corners) do
                    local pos, visible = cam:WorldToViewportPoint(corner)
                    if not visible or pos.Z <= 0 then
                        allVisible = false
                        break
                    end
                    screenCorners[i] = Vector2.new(pos.X, pos.Y)
                end

                -- Desenha as 4 linhas
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

-- Sistema para jogadores que já estão no jogo
local function initializeExistingPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            if ESP_ENABLED then
                createESP(player)
            end
        end
        
        -- Listener para quando o personagem spawnar
        player.CharacterAdded:Connect(function(char)
            char:WaitForChild("HumanoidRootPart", 5)
            task.wait(0.5) -- Aguarda o personagem carregar completamente
            if ESP_ENABLED then
                createESP(player)
            end
        end)
    end
end

-- Sistema para jogadores NOVOS que entrarem
Players.PlayerAdded:Connect(function(player)
    -- Listener para quando o personagem spawnar pela primeira vez
    player.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart", 5)
        task.wait(0.5) -- Aguarda o personagem carregar completamente
        if ESP_ENABLED then
            createESP(player)
        end
    end)
    
    -- Se o personagem já existe quando o jogador entra
    if player.Character then
        task.wait(0.5)
        if ESP_ENABLED then
            createESP(player)
        end
    end
end)

-- Remove ESP quando jogador sair
Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

-- Inicializa jogadores existentes
initializeExistingPlayers()

-- ================== UI DO ESP ==================
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

-- Cleanup quando o script for descarregado
local function cleanupESP()
    clearAllESP()
    for _, line in ipairs(DrawingPool.Lines) do
        pcall(function() line:Remove() end)
    end
    DrawingPool.Lines = {}
end

-- Registra cleanup
if typeof(getgenv) == "function" then
    getgenv().CleanupESP = cleanupESP
end

-- ================== HIGHLIGHT ESP COMPLETO ==================
local TabHighlight = Window:CreateTab("Highlight ESP")

local HIGHLIGHT_ENABLED = false
local highlightColor = Color3.fromRGB(255, 0, 0)
local highlightCache = {}

-- Função para adicionar highlight em um jogador
local function addHighlight(player)
    if player == LP then return end
    
    local char = player.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Remove highlight anterior se existir
    if highlightCache[player] then
        pcall(function()
            highlightCache[player]:Destroy()
        end)
        highlightCache[player] = nil
    end
    
    -- Verifica se já existe um highlight
    local existingHighlight = hrp:FindFirstChild("Highlight")
    if existingHighlight then
        existingHighlight:Destroy()
    end

    -- Cria novo highlight
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
    
    -- Cleanup quando o personagem morrer
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
    
    -- Cleanup quando o personagem for removido
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

-- Função para remover highlight de um jogador
local function removeHighlight(player)
    if highlightCache[player] then
        pcall(function()
            highlightCache[player]:Destroy()
        end)
        highlightCache[player] = nil
    end
end

-- Função para remover todos os highlights
local function removeAllHighlights()
    for player, highlight in pairs(highlightCache) do
        pcall(function()
            highlight:Destroy()
        end)
    end
    highlightCache = {}
end

-- Função para atualizar todos os highlights
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

-- Sistema para jogadores que já estão no jogo
local function initializeExistingPlayersHighlight()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            -- Se já tem personagem
            if player.Character then
                if HIGHLIGHT_ENABLED then
                    addHighlight(player)
                end
            end
            
            -- Listener para quando o personagem spawnar (inclui respawns)
            player.CharacterAdded:Connect(function(char)
                char:WaitForChild("HumanoidRootPart", 5)
                task.wait(0.3) -- Aguarda o personagem carregar
                if HIGHLIGHT_ENABLED then
                    addHighlight(player)
                end
            end)
        end
    end
end

-- Sistema para jogadores NOVOS que entrarem no servidor
Players.PlayerAdded:Connect(function(player)
    -- Listener para quando o personagem spawnar pela primeira vez
    player.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart", 5)
        task.wait(0.3) -- Aguarda o personagem carregar completamente
        if HIGHLIGHT_ENABLED then
            addHighlight(player)
        end
    end)
    
    -- Se o personagem já existe quando o jogador entra
    if player.Character then
        task.wait(0.3)
        if HIGHLIGHT_ENABLED then
            addHighlight(player)
        end
    end
end)

-- Remove highlight quando jogador sair do servidor
Players.PlayerRemoving:Connect(function(player)
    removeHighlight(player)
end)

-- Inicializa jogadores existentes
initializeExistingPlayersHighlight()

-- Loop de verificação (garante que highlights não sejam removidos acidentalmente)
local lastHighlightCheck = 0
RunService.RenderStepped:Connect(function()
    if not HIGHLIGHT_ENABLED then return end
    
    local now = tick()
    if now - lastHighlightCheck < 2 then return end -- Verifica a cada 2 segundos
    lastHighlightCheck = now
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local char = player.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            
            -- Se o jogador está vivo mas não tem highlight, adiciona
            if hrp and hum and hum.Health > 0 then
                local existingHighlight = hrp:FindFirstChild("Highlight")
                if not existingHighlight and not highlightCache[player] then
                    addHighlight(player)
                end
            end
        end
    end
end)

-- ================== UI DO HIGHLIGHT ESP ==================
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
        -- Atualiza a cor de todos os highlights ativos
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

-- Cleanup quando o script for descarregado
local function cleanupHighlights()
    removeAllHighlights()
end

-- Registra cleanup
if typeof(getgenv) == "function" then
    getgenv().CleanupHighlights = cleanupHighlights
end

-- ================== AIM ASSIST MOBILE (CORRIGIDO) ==================
local TabAim = Window:CreateTab("Aim Assist")

local AIM_ENABLED = false
local AIM_FOV = 100
local AIM_SMOOTH = 0.2
local AIM_TARGET_PART = "Head"
local AIM_WALLCHECK = true
local currentTarget = nil
local lastTargetCheck = 0

-- Raycast params cache
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Blacklist
rayParams.IgnoreWater = true

-- Função para pegar a parte correta do corpo
local function getTargetPart(character, partName)
    -- Tenta encontrar a parte especificada
    local part = character:FindFirstChild(partName)
    if part and part:IsA("BasePart") then
        return part
    end
    
    -- Fallback para partes alternativas
    if partName == "Head" then
        return character:FindFirstChild("Head")
    elseif partName == "HumanoidRootPart" then
        return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    elseif partName == "UpperTorso" then
        return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
    elseif partName == "LowerTorso" then
        return character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
    end
    
    -- Fallback final: HumanoidRootPart
    return character:FindFirstChild("HumanoidRootPart")
end

-- Função para verificar linha de visão (wallcheck)
local function isVisible(targetPart)
    if not AIM_WALLCHECK then return true end
    
    rayParams.FilterDescendantsInstances = {LP.Character, targetPart.Parent}
    
    local origin = Camera.CFrame.Position
    local targetPos = targetPart.Position
    local direction = targetPos - origin
    
    local result = workspace:Raycast(origin, direction, rayParams)
    
    if not result then return true end
    
    local hitPart = result.Instance
    
    -- Ignora partes transparentes
    if hitPart.Transparency >= 0.9 then return true end
    
    -- Verifica se é parte do alvo
    if hitPart:IsDescendantOf(targetPart.Parent) then return true end
    
    return false
end

-- UI Controls
TabAim:CreateToggle({
    Name = "Ativar Aim Assist",
    CurrentValue = false,
    Callback = function(v)
        AIM_ENABLED = v
        currentTarget = nil
    end
})

TabAim:CreateToggle({
    Name = "Wallcheck (Não atravessar paredes)",
    CurrentValue = true,
    Callback = function(v)
        AIM_WALLCHECK = v
        currentTarget = nil
    end
})

TabAim:CreateSlider({
    Name = "FOV (Distância máxima)",
    Range = {10, 500},
    Increment = 10,
    CurrentValue = 100,
    Callback = function(v)
        AIM_FOV = v
    end
})

TabAim:CreateSlider({
    Name = "Suavidade da Mira",
    Range = {0.05, 1},
    Increment = 0.05,
    CurrentValue = 0.2,
    Callback = function(v)
        AIM_SMOOTH = v
    end
})

TabAim:CreateDropdown({
    Name = "Parte do Corpo para Mirar",
    Options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    CurrentOption = "Head",
    Callback = function(option)
        AIM_TARGET_PART = option
        currentTarget = nil -- Reseta o alvo ao trocar a parte
    end
})

TabAim:CreateButton({
    Name = "Resetar Alvo Atual",
    Callback = function()
        currentTarget = nil
        Rayfield:Notify({
            Title = "Aim Assist",
            Content = "Alvo resetado!",
            Duration = 1.5
        })
    end
})

-- Runtime: Sistema de mira automática (CORRIGIDO)
RunService.RenderStepped:Connect(function()
    if not AIM_ENABLED or not HRP or not Character then
        currentTarget = nil
        return
    end

    local now = tick()
    
    -- Valida o alvo atual
    if currentTarget then
        local parent = currentTarget.Parent
        
        -- Verifica se o personagem ainda existe
        if not parent or not parent:FindFirstChild("Humanoid") then
            currentTarget = nil
        else
            local hum = parent:FindFirstChildOfClass("Humanoid")
            
            -- Verifica se ainda está vivo
            if not hum or hum.Health <= 0 then
                currentTarget = nil
            -- Verifica se ainda está dentro do FOV
            elseif (currentTarget.Position - HRP.Position).Magnitude > AIM_FOV then
                currentTarget = nil
            -- Verifica wallcheck
            elseif AIM_WALLCHECK and not isVisible(currentTarget) then
                currentTarget = nil
            -- Verifica se a parte ainda existe (importante!)
            elseif not currentTarget.Parent then
                currentTarget = nil
            end
        end
    end

    -- Busca novo alvo (throttled para melhor performance)
    if not currentTarget and now - lastTargetCheck > 0.1 then
        lastTargetCheck = now
        local closestDist = AIM_FOV
        local bestTarget = nil
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LP and player.Character then
                local char = player.Character
                local hum = char:FindFirstChildOfClass("Humanoid")
                
                -- Verifica se o jogador está vivo
                if hum and hum.Health > 0 then
                    -- Pega a parte correta do corpo
                    local targetPart = getTargetPart(char, AIM_TARGET_PART)
                    
                    if targetPart then
                        local dist = (targetPart.Position - HRP.Position).Magnitude
                        
                        -- Verifica se está dentro do FOV e tem linha de visão
                        if dist < closestDist and isVisible(targetPart) then
                            closestDist = dist
                            bestTarget = targetPart
                        end
                    end
                end
            end
        end
        
        currentTarget = bestTarget
    end

    -- Aplica a mira no alvo atual
    if currentTarget and currentTarget.Parent then
        local cam = Camera
        local targetPos = currentTarget.Position
        local camPos = cam.CFrame.Position
        
        -- Calcula a direção para o alvo
        local direction = (targetPos - camPos).Unit
        
        -- Cria o novo CFrame olhando para o alvo
        local newCFrame = CFrame.lookAt(camPos, camPos + direction)
        
        -- Aplica suavização (lerp)
        cam.CFrame = cam.CFrame:Lerp(newCFrame, AIM_SMOOTH)
    end
end)

-- Sistema de debug (opcional - pode comentar se não quiser)
local lastDebugUpdate = 0
RunService.RenderStepped:Connect(function()
    if not AIM_ENABLED then return end
    
    local now = tick()
    if now - lastDebugUpdate < 1 then return end
    lastDebugUpdate = now
    
    -- Debug info (aparece no output)
    if currentTarget then
        local parent = currentTarget.Parent
        if parent then
            local playerName = Players:GetPlayerFromCharacter(parent)
            if playerName then
                print(string.format("[AIM] Mirando em: %s | Parte: %s | Distância: %.1fm", 
                    playerName.Name, 
                    currentTarget.Name, 
                    (currentTarget.Position - HRP.Position).Magnitude
                ))
            end
        end
    end
end)

-- ================= PLAYER / MOVEMENT =================
local fly, flySpeed, flyUpImpulse = false, 100, 0
local infJump, antiFall = false, false

TabMove:CreateSlider({Name="Velocidade", Range={16,300}, Increment=5, CurrentValue=16, Callback=function(v) if Humanoid then Humanoid.WalkSpeed=v end end})
TabMove:CreateSlider({Name="Pulo", Range={50,300}, Increment=10, CurrentValue=50, Callback=function(v) if Humanoid then Humanoid.JumpPower=v end end})
TabMove:CreateSlider({Name="Fly Speed", Range={50,500}, Increment=10, CurrentValue=100, Callback=function(v) flySpeed=v end})
TabMove:CreateToggle({Name="Fly", Callback=function(v) fly=v if not v and HRP then for _,i in pairs({"FlyVel","FlyGyro"}) do local o=HRP:FindFirstChild(i) if o then o:Destroy() end end end end})
TabMove:CreateToggle({Name="Infinite Jump", Callback=function(v) infJump=v end})
TabMove:CreateToggle({Name="Anti Fall", Callback=function(v) antiFall=v end})

UserInputService.JumpRequest:Connect(function()
    if fly then flyUpImpulse = 0.18 end
    if infJump and Humanoid then Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- ================= PROTECTION =================
local godMode, lockHP, antiKB, antiVoid, noclip = false, false, false, false, false

TabProt:CreateToggle({Name="God Mode", Callback=function(v) godMode=v end})
TabProt:CreateToggle({Name="Lock HP", Callback=function(v) lockHP=v end})
TabProt:CreateToggle({Name="Anti Knockback", Callback=function(v) antiKB=v end})
TabProt:CreateToggle({Name="Anti Void", Callback=function(v) antiVoid=v end})

-- ================= PLAYERS =================
local selectedName = nil
local function getPlayerNames()
    local t = {}
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(t, p.Name) end
    end
    return t
end

local playerDropdown = TabPlayers:CreateDropdown({Name="Selecionar Player", Options=getPlayerNames(), Callback=function(v) selectedName = typeof(v)=="table" and v[1] or v end})
TabPlayers:CreateButton({Name="Atualizar Lista", Callback=function() playerDropdown:Refresh(getPlayerNames()) end})
TabPlayers:CreateButton({Name="TP Player", Callback=function() local t=Players:FindFirstChild(selectedName) if t and t.Character and HRP then HRP.CFrame=t.Character.HumanoidRootPart.CFrame*CFrame.new(0,0,-3) end end})
TabPlayers:CreateButton({Name="Spectate", Callback=function() local t=Players:FindFirstChild(selectedName) if t and t.Character then Camera.CameraSubject=t.Character:FindFirstChildOfClass("Humanoid") end end})
TabPlayers:CreateButton({Name="Voltar Camera", Callback=function() Camera.CameraSubject=Humanoid end})

-- ================= WORLD =================
TabWorld:CreateSlider({Name="Hora", Range={0,24}, Increment=0.5, CurrentValue=14, Callback=function(v) Lighting.ClockTime=v end})
TabWorld:CreateSlider({Name="Gravidade", Range={60,500}, Increment=10, CurrentValue=196, Callback=function(v) workspace.Gravity=v end})
TabWorld:CreateButton({Name="Remover Fog", Callback=function() Lighting.FogEnd=1e6 end})

-- ================= UTILITY =================
TabUtil:CreateToggle({Name="Noclip", Callback=function(v) noclip=v end})
TabUtil:CreateButton({Name="Rejoin", Callback=function() TeleportService:Teleport(game.PlaceId, LP) end})
TabUtil:CreateButton({Name="Server Hop", Callback=function()
    local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
    for _,s in pairs(servers.data) do
        if s.playing < s.maxPlayers then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LP)
            break
        end
    end
end})

-- ================= RUNTIME =================
local lastRuntimeUpdate = 0
RunService.RenderStepped:Connect(function(dt)
    if not Character or not HRP or not Humanoid then return end

    local now = tick()
    if now - lastRuntimeUpdate < 0.033 then return end
    lastRuntimeUpdate = now

    if flyUpImpulse > 0 then flyUpImpulse -= dt end

    if fly then
        if not HRP:FindFirstChild("FlyVel") then
            local bv = Instance.new("BodyVelocity", HRP)
            bv.Name="FlyVel"
            bv.MaxForce=Vector3.new(9e9,9e9,9e9)
            local bg = Instance.new("BodyGyro", HRP)
            bg.Name="FlyGyro"
            bg.MaxTorque=Vector3.new(9e9,9e9,9e9)
        end
        local dir = Humanoid.MoveDirection
        local vel = Vector3.new(dir.X,0,dir.Z)*flySpeed
        if flyUpImpulse>0 then vel+=Vector3.new(0,flySpeed,0) end
        HRP.FlyVel.Velocity = vel
        HRP.FlyGyro.CFrame = Camera.CFrame
    end

    if noclip then
        for _,p in pairs(Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=false end
        end
    end

    if godMode then
        Humanoid.MaxHealth=math.huge
        Humanoid.Health=Humanoid.MaxHealth
    elseif lockHP then
        Humanoid.Health=Humanoid.MaxHealth
    end

    if antiVoid and HRP.Position.Y < -80 then
        HRP.CFrame += Vector3.new(0,200,0)
    end

    if antiKB then
        HRP.Velocity *= Vector3.new(0.8,0.9,0.8)
    end
end)

print("✅ Universal Hub v2 (Wallcheck + ESP Fixes) carregado!")