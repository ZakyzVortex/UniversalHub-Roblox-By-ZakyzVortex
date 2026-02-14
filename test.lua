-- ================== UNIVERSAL HUB - ORGANIZED VERSION (FIXED) ==================
-- Universal Hub WindUI By ZakyzVortex (Mobile Optimized & Organized)

-- Carrega apenas a biblioteca WindUI (sem o exemplo)
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()

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

-- ================== FUNÇÃO PARA ESCONDER OBJETOS 3D DO JOGO ==================
-- Esconde TUDO do workspace exceto seu personagem (para reduzir lag visual)

local function resetVisuals()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    local hiddenCount = 0
    
    local function hide(obj)
        -- NÃO esconder se for parte do seu personagem
        if LocalPlayer.Character and obj:IsDescendantOf(LocalPlayer.Character) then 
            return 
        end
        
        -- Esconde partes 3D (mantém colisão)
        if obj:IsA("BasePart") then
            obj.Transparency = 1
            hiddenCount = hiddenCount + 1
            
        -- Esconde decals e texturas
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 1
            hiddenCount = hiddenCount + 1
            
        -- Desabilita efeitos de partículas
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
            obj.Enabled = false
            hiddenCount = hiddenCount + 1
            
        -- Desabilita outros efeitos visuais
        elseif obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            obj.Enabled = false
            hiddenCount = hiddenCount + 1
        end
    end
    
    -- Esconde tudo que já existe
    for _, obj in ipairs(workspace:GetDescendants()) do
        hide(obj)
    end
    
    -- Auto-esconde novos objetos que aparecerem
    workspace.DescendantAdded:Connect(hide)
    
    print("✅ " .. hiddenCount .. " objetos 3D escondidos!")
    print("✅ FPS otimizado para AFK farm!")
end

-- ================== TEAM DETECTION SYSTEM (CORRIGIDO) ==================
local function getPlayerTeam(player)
    if not player then return nil end
    return player.Team
end

local function isPlayerOnSameTeam(player)
    if not player or player == LP then return false end
    local myTeam = getPlayerTeam(LP)
    local theirTeam = getPlayerTeam(player)
    
    -- Se nenhum dos dois tem time, não são do mesmo time
    if not myTeam or not theirTeam then return false end
    
    -- Verifica se são do mesmo time
    return myTeam == theirTeam
end

local function shouldShowPlayer(player, filterMode)
    if not player or player == LP then return false end
    
    if filterMode == "All" then
        return true
    elseif filterMode == "MyTeam" or filterMode == "Team" then
        -- Só mostra se AMBOS tiverem time E forem do mesmo time
        local myTeam = getPlayerTeam(LP)
        local theirTeam = getPlayerTeam(player)
        if not myTeam or not theirTeam then return false end
        return myTeam == theirTeam
    elseif filterMode == "EnemyTeam" or filterMode == "Enemy" then
        local myTeam = getPlayerTeam(LP)
        local theirTeam = getPlayerTeam(player)
        
        -- Se não houver sistema de times, mostra todos (exceto si mesmo)
        if not myTeam or not theirTeam then return true end
        
        -- Se houver times, só mostra se forem de times DIFERENTES
        return myTeam ~= theirTeam
    end
    
    return true
end

-- ================== WINDOW ==================
local Window = WindUI:CreateWindow({
    Title = "Universal Hub",
    SubTitle = "By ZakyzVortex",
    TabWidth = 160,
    Size = UDim2.fromOffset(600, 480),
    Acrylic = true,
    Theme = "Dark",
})

-- ================== CREATE TABS ==================
local TabMove     = Window:CreateTab("Movement",    "person-walking")
local TabCombat   = Window:CreateTab("Auto Farm",   "swords")
local TabESP      = Window:CreateTab("ESP",         "eye")
local TabHighlight = Window:CreateTab("Highlight",  "sparkles")
local TabAim      = Window:CreateTab("Aim Assist",  "crosshair")
local TabPlayerAim = Window:CreateTab("Player Aim", "target")
local TabProt     = Window:CreateTab("Protection",  "shield")
local TabPlayers  = Window:CreateTab("Players",     "users")
local TabWaypoints = Window:CreateTab("Waypoints",  "map-pin")
local TabVisuals  = Window:CreateTab("Visuals",     "palette")
local TabWorld    = Window:CreateTab("World",       "globe")
local TabFPS      = Window:CreateTab("FPS/Stats",   "activity")
local TabConfig   = Window:CreateTab("Config",      "settings")
local TabUtil     = Window:CreateTab("Utility",     "wrench")

-- ==================================================================================
-- ============================== MOVEMENT TAB ======================================
-- ==================================================================================

TabMove:CreateSection("Velocidade e Pulo")

-- Estados
local infJump, antiFall = false, false

-- Velocidade
TabMove:CreateSlider({
    Name = "Velocidade de Caminhada",
    Range = {16, 300},
    Increment = 5,
    Default = 16,
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
    Default = 50,
    Callback = function(v)
        if Humanoid then
            Humanoid.UseJumpPower = true
            Humanoid.JumpPower = v
        end
    end
})

TabMove:CreateSection("Fly System")

-- ================== FLY SYSTEM INTEGRADO ==================
local flyEnabled = false
local flySpeed = 1
local tpwalking = false
local ctrl = {f = 0, b = 0, l = 0, r = 0}
local lastctrl = {f = 0, b = 0, l = 0, r = 0}

-- Função para ativar/desativar fly
local function toggleFly(enabled)
    flyEnabled = enabled
    local speaker = LP
    local chr = speaker.Character
    local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
    
    if not chr or not hum then return end
    
    if enabled then
        -- Desabilita animações e estados
        chr.Animate.Disabled = true
        local AnimController = chr:FindFirstChildOfClass("Humanoid") or chr:FindFirstChildOfClass("AnimationController")
        for i,v in next, AnimController:GetPlayingAnimationTracks() do
            v:AdjustSpeed(0)
        end
        
        hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Running, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
        hum:ChangeState(Enum.HumanoidStateType.Swimming)
        
        -- Inicia teleport walking
        for i = 1, flySpeed do
            spawn(function()
                local hb = game:GetService("RunService").Heartbeat
                tpwalking = true
                local chr = LP.Character
                local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
                while tpwalking and hb:Wait() and chr and hum and hum.Parent do
                    if hum.MoveDirection.Magnitude > 0 then
                        chr:TranslateBy(hum.MoveDirection)
                    end
                end
            end)
        end
        
        -- Detecta tipo de rig e aplica BodyGyro/BodyVelocity
        if hum.RigType == Enum.HumanoidRigType.R6 then
            local torso = chr.Torso
            local bg = Instance.new("BodyGyro", torso)
            bg.P = 9e4
            bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
            bg.cframe = torso.CFrame
            local bv = Instance.new("BodyVelocity", torso)
            bv.velocity = Vector3.new(0, 0.1, 0)
            bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
            hum.PlatformStand = true
            
            spawn(function()
                local maxspeed = 50
                local speed = 0
                while flyEnabled and hum.Health > 0 do
                    game:GetService("RunService").RenderStepped:Wait()
                    
                    if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
                        speed = speed + 0.5 + (speed / maxspeed)
                        if speed > maxspeed then
                            speed = maxspeed
                        end
                    elseif not (ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0) and speed ~= 0 then
                        speed = speed - 1
                        if speed < 0 then
                            speed = 0
                        end
                    end
                    
                    if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
                        bv.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (ctrl.f + ctrl.b)) + 
                                      ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(ctrl.l + ctrl.r, (ctrl.f + ctrl.b) * 0.2, 0).p) - 
                                       workspace.CurrentCamera.CoordinateFrame.p)) * speed
                        lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
                    elseif (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and speed ~= 0 then
                        bv.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (lastctrl.f + lastctrl.b)) + 
                                      ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(lastctrl.l + lastctrl.r, (lastctrl.f + lastctrl.b) * 0.2, 0).p) - 
                                       workspace.CurrentCamera.CoordinateFrame.p)) * speed
                    else
                        bv.velocity = Vector3.new(0, 0, 0)
                    end
                    
                    bg.cframe = workspace.CurrentCamera.CoordinateFrame * CFrame.Angles(-math.rad((ctrl.f + ctrl.b) * 50 * speed / maxspeed), 0, 0)
                end
                
                ctrl = {f = 0, b = 0, l = 0, r = 0}
                lastctrl = {f = 0, b = 0, l = 0, r = 0}
                speed = 0
                bg:Destroy()
                bv:Destroy()
                hum.PlatformStand = false
            end)
        else
            local UpperTorso = chr.UpperTorso
            local bg = Instance.new("BodyGyro", UpperTorso)
            bg.P = 9e4
            bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
            bg.cframe = UpperTorso.CFrame
            local bv = Instance.new("BodyVelocity", UpperTorso)
            bv.velocity = Vector3.new(0, 0.1, 0)
            bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
            hum.PlatformStand = true
            
            spawn(function()
                local maxspeed = 50
                local speed = 0
                while flyEnabled and hum.Health > 0 do
                    wait()
                    
                    if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
                        speed = speed + 0.5 + (speed / maxspeed)
                        if speed > maxspeed then
                            speed = maxspeed
                        end
                    elseif not (ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0) and speed ~= 0 then
                        speed = speed - 1
                        if speed < 0 then
                            speed = 0
                        end
                    end
                    
                    if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
                        bv.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (ctrl.f + ctrl.b)) + 
                                      ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(ctrl.l + ctrl.r, (ctrl.f + ctrl.b) * 0.2, 0).p) - 
                                       workspace.CurrentCamera.CoordinateFrame.p)) * speed
                        lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
                    elseif (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and speed ~= 0 then
                        bv.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (lastctrl.f + lastctrl.b)) + 
                                      ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(lastctrl.l + lastctrl.r, (lastctrl.f + lastctrl.b) * 0.2, 0).p) - 
                                       workspace.CurrentCamera.CoordinateFrame.p)) * speed
                    else
                        bv.velocity = Vector3.new(0, 0, 0)
                    end
                    
                    bg.cframe = workspace.CurrentCamera.CoordinateFrame * CFrame.Angles(-math.rad((ctrl.f + ctrl.b) * 50 * speed / maxspeed), 0, 0)
                end
                
                ctrl = {f = 0, b = 0, l = 0, r = 0}
                lastctrl = {f = 0, b = 0, l = 0, r = 0}
                speed = 0
                bg:Destroy()
                bv:Destroy()
                hum.PlatformStand = false
            end)
        end
    else
        -- Desativa fly
        tpwalking = false
        flyEnabled = false
        
        -- Remove BodyGyro e BodyVelocity que causam flutuação
        for _, obj in pairs(chr:GetDescendants()) do
            if obj:IsA("BodyGyro") or obj:IsA("BodyVelocity") then
                obj:Destroy()
            end
        end
        
        -- Reativa todos os estados do humanoid
        hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Flying, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
        
        -- Reseta estado e animações
        hum:ChangeState(Enum.HumanoidStateType.Freefall)
        hum.PlatformStand = false
        chr.Animate.Disabled = false
        
        -- Reativa animações
        local AnimController = chr:FindFirstChildOfClass("Humanoid") or chr:FindFirstChildOfClass("AnimationController")
        if AnimController then
            for i,v in next, AnimController:GetPlayingAnimationTracks() do
                v:AdjustSpeed(1)
            end
        end
    end
end

-- Função para atualizar velocidade do fly
local function updateFlySpeed(newSpeed)
    flySpeed = newSpeed
    if flyEnabled then
        tpwalking = false
        task.wait(0.1)
        for i = 1, flySpeed do
            spawn(function()
                local hb = game:GetService("RunService").Heartbeat
                tpwalking = true
                local chr = LP.Character
                local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
                while tpwalking and hb:Wait() and chr and hum and hum.Parent do
                    if hum.MoveDirection.Magnitude > 0 then
                        chr:TranslateBy(hum.MoveDirection)
                    end
                end
            end)
        end
    end
end

-- Slider de velocidade do fly
TabMove:CreateSlider({
    Name = "Velocidade de Voo",
    Range = {1, 50},
    Increment = 1,
    Default = 1,
    Callback = function(v)
        updateFlySpeed(v)
    end
})

-- Toggle do fly
TabMove:CreateToggle({
    Name = "Ativar Fly",
    Default = false,
    Callback = function(v)
        toggleFly(v)
    end
})

-- Controles WASD para o fly
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.W then
            ctrl.f = 1
        elseif input.KeyCode == Enum.KeyCode.S then
            ctrl.b = -1
        elseif input.KeyCode == Enum.KeyCode.A then
            ctrl.l = -1
        elseif input.KeyCode == Enum.KeyCode.D then
            ctrl.r = 1
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.W then
            ctrl.f = 0
        elseif input.KeyCode == Enum.KeyCode.S then
            ctrl.b = 0
        elseif input.KeyCode == Enum.KeyCode.A then
            ctrl.l = 0
        elseif input.KeyCode == Enum.KeyCode.D then
            ctrl.r = 0
        end
    end
end)

-- Reset ao morrer
LP.CharacterAdded:Connect(function(char)
    wait(0.7)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = false
    end
    char.Animate.Disabled = false
    flyEnabled = false
end)

TabMove:CreateSection("Outros")

-- Infinite Jump
TabMove:CreateToggle({
    Name = "Pulo Infinito",
    Default = false,
    Callback = function(v)
        infJump = v
    end
})

-- Anti Fall
TabMove:CreateToggle({
    Name = "Anti Queda",
    Default = false,
    Callback = function(v)
        antiFall = v
    end
})

-- Jump Request Handler
UserInputService.JumpRequest:Connect(function()
    if infJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ==================================================================================
-- ================================ COMBAT TAB ======================================
-- ==================================================================================

-- SERVIÇOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ProximityPromptService = game:GetService("ProximityPromptService")

local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()

-- ==================================================================================
-- AUTO CLICKER
-- ==================================================================================

TabCombat:CreateSection("Auto Clicker")

local AUTO_CLICKER_ENABLED = false
local AUTO_CLICKER_CPS = 10
local lastClick = 0

local function performClick()
    if not AUTO_CLICKER_ENABLED then return end
    
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(0.01)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

TabCombat:CreateToggle({
    Name = "Ativar Auto Clicker",
    Default = false,
    Callback = function(v)
        AUTO_CLICKER_ENABLED = v
        if v then lastClick = tick() end
    end
})

TabCombat:CreateSlider({
    Name = "CPS (Cliques por Segundo)",
    Range = {1, 50},
    Increment = 1,
    Default = 10,
    Callback = function(v)
        AUTO_CLICKER_CPS = v
    end
})

RunService.Heartbeat:Connect(function()
    if not AUTO_CLICKER_ENABLED then return end
    
    local now = tick()
    local clickInterval = 1 / AUTO_CLICKER_CPS
    
    if now - lastClick >= clickInterval then
        performClick()
        lastClick = now
    end
end)

-- ==================================================================================
-- HIT RANGE EXTENDER
-- ==================================================================================

TabCombat:CreateSection("Hit Range Extender")

local HIT_RANGE_ENABLED = false
local HIT_RANGE_SIZE = 10
local originalSizes = {}
local originalTransparencies = {}

local function extendHitboxes()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            
            if hrp and hrp:IsA("BasePart") then
                if not originalSizes[player.UserId] then
                    originalSizes[player.UserId] = hrp.Size
                    originalTransparencies[player.UserId] = hrp.Transparency
                end
                
                if HIT_RANGE_ENABLED then
                    hrp.Size = Vector3.new(HIT_RANGE_SIZE, HIT_RANGE_SIZE, HIT_RANGE_SIZE)
                    hrp.Transparency = 0.7
                    hrp.CanCollide = false
                    hrp.Massless = true
                else
                    hrp.Size = originalSizes[player.UserId] or Vector3.new(2, 2, 1)
                    hrp.Transparency = originalTransparencies[player.UserId] or 1
                    hrp.CanCollide = false
                    hrp.Massless = false
                end
            end
        end
    end
end

Players.PlayerRemoving:Connect(function(player)
    originalSizes[player.UserId] = nil
    originalTransparencies[player.UserId] = nil
end)

TabCombat:CreateToggle({
    Name = "Ativar Hit Range Extender",
    Default = false,
    Callback = function(v)
        HIT_RANGE_ENABLED = v
        if not v then extendHitboxes() end
    end
})

TabCombat:CreateSlider({
    Name = "Tamanho da Hitbox",
    Range = {5, 30},
    Increment = 1,
    Default = 10,
    Callback = function(v)
        HIT_RANGE_SIZE = v
        if HIT_RANGE_ENABLED then extendHitboxes() end
    end
})

RunService.Heartbeat:Connect(function()
    if HIT_RANGE_ENABLED then
        extendHitboxes()
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if HIT_RANGE_ENABLED then extendHitboxes() end
    end)
end)

-- ==================================================================================
-- AUTO PRESS (PROXIMITY PROMPT)
-- ==================================================================================

TabCombat:CreateSection("Auto Press")

local AUTO_PRESS_ENABLED = false
local AUTO_PRESS_INTERVAL = 0.25
local promptAtual = nil

ProximityPromptService.PromptShown:Connect(function(prompt)
    promptAtual = prompt
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
    if promptAtual == prompt then
        promptAtual = nil
    end
end)

TabCombat:CreateToggle({
    Name = "Ativar Auto Press",
    Default = false,
    Callback = function(v)
        AUTO_PRESS_ENABLED = v
    end
})

TabCombat:CreateSlider({
    Name = "Intervalo (segundos)",
    Range = {0.1, 2},
    Increment = 0.05,
    Default = 0.25,
    Callback = function(v)
        AUTO_PRESS_INTERVAL = v
    end
})

-- Loop Auto Press
task.spawn(function()
    while true do
        if AUTO_PRESS_ENABLED and promptAtual and promptAtual.Enabled then
            pcall(function()
                fireproximityprompt(promptAtual, promptAtual.HoldDuration or 0)
            end)
        end
        task.wait(AUTO_PRESS_INTERVAL)
    end
end)

-- ==================================================================================
-- FIM DO COMBAT TAB
-- ==================================================================================

-- ==================== ESP COM SISTEMA DE TIMES (CORRIGIDO) ====================
local ESP_ENABLED = false
local NAME_ENABLED = true
local DISTANCE_ENABLED = true
local LINE_ENABLED = true
local HEALTH_ENABLED = true
local OUTLINE_ENABLED = true
local ESP_COLOR = Color3.fromRGB(255, 0, 0)
local LINE_COLOR = Color3.fromRGB(255, 255, 255)
local ESP_OBJECTS = {}
local ESP_TEAM_FILTER = "All"  -- All, Team, Enemy

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
    if player == LP then return end
    
    -- FILTRO DE TIME APLICADO
    if not shouldShowPlayer(player, ESP_TEAM_FILTER) then
        removeESP(player)
        return
    end
    
    if ESP_OBJECTS[player] then removeESP(player) end
    
    local char = player.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    if hum.Health <= 0 then return end

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
            if p ~= LP then
                createESP(p)
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
        
        -- Verifica se player ainda existe
        if not player or not Players:FindFirstChild(player.Name) then
            removeESP(player)
            continue
        end
        
        -- Verifica filtro de time continuamente
        if not shouldShowPlayer(player, ESP_TEAM_FILTER) then
            removeESP(player)
            continue
        end

        local char = player.Character
        if not char or char ~= espData.character then
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
        if player ~= LP then
            if player.Character and ESP_ENABLED then
                createESP(player)
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
end

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

TabESP:CreateSection("ESP Settings")

TabESP:CreateToggle({
    Name = "Ativar ESP",
    Default = false,
    Callback = function(v)
        ESP_ENABLED = v
        refreshESP()
    end
})

TabESP:CreateDropdown({
    Name = "Filtro de Time",
    Options = {"All", "Team", "Enemy"},
    Default = "All",
    Multi = false,
    Callback = function(option)
        ESP_TEAM_FILTER = typeof(option) == "table" and option[1] or option
        refreshESP()
    end
})

TabESP:CreateSection("ESP Components")

TabESP:CreateToggle({
    Name = "Nome",
    Default = true,
    Callback = function(v)
        NAME_ENABLED = v
    end
})

TabESP:CreateToggle({
    Name = "Distância",
    Default = true,
    Callback = function(v)
        DISTANCE_ENABLED = v
    end
})

TabESP:CreateToggle({
    Name = "Vida",
    Default = true,
    Callback = function(v)
        HEALTH_ENABLED = v
    end
})

TabESP:CreateToggle({
    Name = "Linha Única",
    Default = true,
    Callback = function(v)
        LINE_ENABLED = v
    end
})

TabESP:CreateToggle({
    Name = "Contorno 4 Linhas",
    Default = true,
    Callback = function(v)
        OUTLINE_ENABLED = v
    end
})

TabESP:CreateSection("Cores")

TabESP:CreateColorPicker({
    Name = "Cor do ESP",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(color)
        ESP_COLOR = color
    end
})

TabESP:CreateColorPicker({
    Name = "Cor da Linha",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        LINE_COLOR = color
    end
})

-- ==================== HIGHLIGHT ESP (CORRIGIDO) ====================
local HIGHLIGHT_ENABLED = false
local HIGHLIGHT_TEAM_FILTER = "All"
local teamColor = Color3.fromRGB(0, 255, 0)
local enemyColor = Color3.fromRGB(255, 0, 0)
local highlightCache = {}
local highlightFillTrans = 0.5
local highlightOutlineTrans = 0
local highlightDepthMode = Enum.HighlightDepthMode.AlwaysOnTop

local function addHighlight(player)
    if player == LP then return end
    
    -- FILTRO DE TIME APLICADO
    if not shouldShowPlayer(player, HIGHLIGHT_TEAM_FILTER) then
        if highlightCache[player] then
            pcall(function() highlightCache[player]:Destroy() end)
            highlightCache[player] = nil
        end
        return
    end
    
    local char = player.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return end
    
    if highlightCache[player] then
        pcall(function() highlightCache[player]:Destroy() end)
        highlightCache[player] = nil
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "UniversalHighlight"
    highlight.Adornee = char
    highlight.DepthMode = highlightDepthMode
    
    -- Determina cor baseada no time
    local myTeam = getPlayerTeam(LP)
    local theirTeam = getPlayerTeam(player)
    
    if myTeam and theirTeam and myTeam == theirTeam then
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
            if player ~= LP and player.Character then
                addHighlight(player)
            end
        end
    end
end

local function initializeExistingPlayersHighlight()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            if player.Character and HIGHLIGHT_ENABLED then
                addHighlight(player)
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

local lastHighlightCheck = 0
RunService.RenderStepped:Connect(function()
    if not HIGHLIGHT_ENABLED then return end
    
    local now = tick()
    if now - lastHighlightCheck < 2 then return end
    lastHighlightCheck = now
    
    -- Verifica filtros de time e validade continuamente
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local char = player.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            
            if shouldShowPlayer(player, HIGHLIGHT_TEAM_FILTER) and hum and hum.Health > 0 then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp and not highlightCache[player] then
                    addHighlight(player)
                end
            else
                removeHighlight(player)
            end
        end
    end
end)

TabHighlight:CreateSection("Highlight ESP")

TabHighlight:CreateToggle({
    Name = "Ativar Highlight ESP",
    Default = false,
    Callback = function(v)
        HIGHLIGHT_ENABLED = v
        updateAllHighlights()
    end
})

TabHighlight:CreateDropdown({
    Name = "Filtro de Time",
    Options = {"All", "Team", "Enemy"},
    Default = "All",
    Multi = false,
    Callback = function(option)
        HIGHLIGHT_TEAM_FILTER = typeof(option) == "table" and option[1] or option
        updateAllHighlights()
    end
})

TabHighlight:CreateSection("Cores")

TabHighlight:CreateColorPicker({
    Name = "Cor do Time",
    Default = Color3.fromRGB(0, 255, 0),
    Callback = function(color)
        teamColor = color
        updateAllHighlights()
    end
})

TabHighlight:CreateColorPicker({
    Name = "Cor dos Inimigos",
    Default = Color3.fromRGB(255, 0, 0),
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
    Default = 0.5,
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
    Default = 0,
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
    Default = "AlwaysOnTop",
    Multi = false,
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
        WindUI:Notify({
            Title = "Highlights Atualizados",
            Content = "Recarregado!",
            Duration = 2
        })
    end
})

-- ==================== AIM ASSIST (CORRIGIDO - SEM FOV CIRCLE) ====================
TabAim:CreateSection("Aim Assist")

local AIM_ENABLED = false
local AIM_FOV = 100
local AIM_SMOOTH = 0.2
local AIM_TARGET_PART = "Head"
local AIM_WALLCHECK = true
local AIM_TEAM_FILTER = "Enemy"
local currentTarget = nil

-- Função para verificar se o jogador está visível
local function isVisible(targetPart)
    if not targetPart or not HRP then return false end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {Character, targetPart.Parent}
    
    local ray = workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position), raycastParams)
    return ray == nil
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

TabAim:CreateToggle({
    Name = "🎯 Ativar Aim Assist",
    Default = false,
    Callback = function(v)
        AIM_ENABLED = v
        currentTarget = nil
        if v then
            WindUI:Notify({
                Title = "Aim Assist Ativado",
                Content = "Mirando apenas em inimigos",
                Duration = 2
            })
        end
    end
})

TabAim:CreateDropdown({
    Name = "Filtro de Time",
    Options = {"All", "MyTeam", "Enemy"},
    Default = "Enemy",
    Multi = false,
    Callback = function(option)
        AIM_TEAM_FILTER = option
        currentTarget = nil
    end
})

TabAim:CreateSection("Configurações")

TabAim:CreateToggle({
    Name = "Wallcheck (Não atirar através de paredes)",
    Default = true,
    Callback = function(v)
        AIM_WALLCHECK = v
        currentTarget = nil
    end
})

TabAim:CreateSlider({
    Name = "FOV (Campo de Visão)",
    Range = {10, 800},
    Increment = 10,
    Default = 100,
    Callback = function(v)
        AIM_FOV = v
    end
})

TabAim:CreateSlider({
    Name = "Suavidade",
    Range = {0.05, 1},
    Increment = 0.05,
    Default = 0.2,
    Callback = function(v)
        AIM_SMOOTH = v
    end
})

TabAim:CreateDropdown({
    Name = "Parte do Corpo",
    Options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    Default = "Head",
    Multi = false,
    Callback = function(option)
        AIM_TARGET_PART = option
        currentTarget = nil
    end
})

TabAim:CreateButton({
    Name = "🔄 Resetar Alvo",
    Callback = function()
        currentTarget = nil
        WindUI:Notify({
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
        -- Verificação básica
        if player == LP then continue end
        
        -- FILTRO DE TIME APLICADO
        if not shouldShowPlayer(player, AIM_TEAM_FILTER) then continue end
        
        local char = player.Character
        if not char then continue end
        
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
-- ============================ PLAYER AIM TAB  ===================
-- ==================================================================================

TabPlayerAim:CreateSection("🎯 Seleção de Jogador")

-- Variáveis do Player Aim
local PlayerAimEnabled = false
local PlayerAimSmoothness = 0.15
local PlayerAimPart = "Head"
local PlayerAimFOVRadius = 100
local PlayerAimPrediction = 0.13
local PlayerAimWallCheck = true
local TargetPlayerName = nil
local PlayerAimList = {}

-- Funções do Player Aim
local function UpdatePlayerAimList()
    PlayerAimList = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP then
            table.insert(PlayerAimList, player.Name)
        end
    end
    return PlayerAimList
end

local function GetTargetPlayer()
    if not TargetPlayerName then return nil end
    local playerName = tostring(TargetPlayerName)
    return Players:FindFirstChild(playerName)
end

local function IsPlayerAimValid(player)
    return player 
        and player ~= LP 
        and player.Character 
        and player.Character:FindFirstChild("Humanoid")
        and player.Character.Humanoid.Health > 0
end

local function GetPlayerAimPart(player)
    if not player or not player.Character then return nil end
    
    if PlayerAimPart == "Head" then
        return player.Character:FindFirstChild("Head")
    elseif PlayerAimPart == "Torso" then
        return player.Character:FindFirstChild("UpperTorso") or player.Character:FindFirstChild("Torso")
    else
        return player.Character:FindFirstChild("HumanoidRootPart")
    end
end

local function CheckPlayerAimFOV(part)
    if PlayerAimFOVRadius <= 0 then return true end
    
    local camera = workspace.CurrentCamera
    local pos, onScreen = camera:WorldToViewportPoint(part.Position)
    
    if not onScreen then return false end
    
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local target = Vector2.new(pos.X, pos.Y)
    
    return (center - target).Magnitude <= PlayerAimFOVRadius
end

local function CheckPlayerAimWall(part)
    if not PlayerAimWallCheck then return true end
    
    local camera = workspace.CurrentCamera
    local origin = camera.CFrame.Position
    local direction = (part.Position - origin)
    
    local ray = RaycastParams.new()
    ray.FilterDescendantsInstances = {LP.Character, part.Parent}
    ray.FilterType = Enum.RaycastFilterType.Exclude
    
    local result = workspace:Raycast(origin, direction, ray)
    return not result or result.Instance:IsDescendantOf(part.Parent)
end

local function GetPartVelocity(part)
    if part.AssemblyLinearVelocity then
        return part.AssemblyLinearVelocity
    elseif part.Velocity then
        return part.Velocity
    elseif part.AssemblyVelocity then
        return part.AssemblyVelocity
    else
        return Vector3.new(0, 0, 0)
    end
end

-- Player Aim Loop (SEM LOGS PESADOS)
RunService.RenderStepped:Connect(function()
    pcall(function()
        if not PlayerAimEnabled then return end
        
        local player = GetTargetPlayer()
        if not player or not IsPlayerAimValid(player) then return end
        
        local part = GetPlayerAimPart(player)
        if not part then return end
        
        if not CheckPlayerAimFOV(part) then return end
        if not CheckPlayerAimWall(part) then return end
        
        local targetPos = part.Position
        if PlayerAimPrediction > 0 then
            local velocity = GetPartVelocity(part)
            targetPos = targetPos + (velocity * PlayerAimPrediction)
        end
        
        local camera = workspace.CurrentCamera
        local lookAt = CFrame.new(camera.CFrame.Position, targetPos)
        camera.CFrame = camera.CFrame:Lerp(lookAt, PlayerAimSmoothness)
    end)
end)

-- Interface do Player Aim
TabPlayerAim:CreateLabel("Selecione um jogador específico para mirar")

local PlayerAimDropdown = TabPlayerAim:CreateDropdown({
    Name = "Escolher Jogador Alvo",
    Options = UpdatePlayerAimList(),
    Default = "",
    Multi = false,
    Callback = function(option)
        if type(option) == "table" then
            TargetPlayerName = option[1] or option
        else
            TargetPlayerName = option
        end
        
        WindUI:Notify({
            Title = "🎯 Alvo Selecionado",
            Content = tostring(TargetPlayerName),
            Duration = 2
        })
    end
})

TabPlayerAim:CreateButton({
    Name = "🔄 Atualizar Lista de Jogadores",
    Callback = function()
        local list = UpdatePlayerAimList()
        PlayerAimDropdown:Refresh(list)
        WindUI:Notify({
            Title = "✅ Lista Atualizada",
            Content = #list .. " jogadores",
            Duration = 2
        })
    end
})

TabPlayerAim:CreateSection("⚙️ Controle")

TabPlayerAim:CreateToggle({
    Name = "🎯 Ativar Aim no Jogador",
    Default = false,
    Callback = function(value)
        if value and not TargetPlayerName then
            WindUI:Notify({
                Title = "⚠️ Aviso",
                Content = "Selecione um jogador primeiro!",
                Duration = 2
            })
            PlayerAimEnabled = false
            return
        end
        
        PlayerAimEnabled = value
        
        WindUI:Notify({
            Title = value and "✅ Aim Ativado" or "⭕ Aim Desativado",
            Content = value and ("Mirando em: " .. tostring(TargetPlayerName)) or "Desativado",
            Duration = 2
        })
    end
})

TabPlayerAim:CreateSection("🎛️ Configurações")

TabPlayerAim:CreateSlider({
    Name = "FOV Radius (pixels)",
    Range = {10, 800},
    Increment = 10,
    Default = 100,
    Callback = function(v)
        PlayerAimFOVRadius = v
    end
})

TabPlayerAim:CreateSlider({
    Name = "Suavidade (menor = mais rápido)",
    Range = {0.01, 1},
    Increment = 0.01,
    Default = 0.15,
    Callback = function(v)
        PlayerAimSmoothness = v
    end
})

TabPlayerAim:CreateDropdown({
    Name = "Parte do Corpo",
    Options = {"Head", "Torso", "HumanoidRootPart"},
    Default = "Head",
    Multi = false,
    Callback = function(v)
        if type(v) == "table" then
            PlayerAimPart = v[1] or v
        else
            PlayerAimPart = v
        end
    end
})

TabPlayerAim:CreateSlider({
    Name = "Predição de Movimento",
    Range = {0, 0.5},
    Increment = 0.01,
    Default = 0,
    Callback = function(v)
        PlayerAimPrediction = v
    end
})

TabPlayerAim:CreateToggle({
    Name = "WallCheck (não mirar através de paredes)",
    Default = true,
    Callback = function(v)
        PlayerAimWallCheck = v
    end
})

TabPlayerAim:CreateSection("📊 Status")

-- Status do Player Aim
local PlayerAimStatus = TabPlayerAim:CreateLabel("Status: Aguardando...")

task.spawn(function()
    while wait(1) do
        pcall(function()
            if PlayerAimEnabled and TargetPlayerName then
                local p = GetTargetPlayer()
                if p and IsPlayerAimValid(p) then
                    PlayerAimStatus:Set("✅ ATIVO - Mirando em " .. tostring(TargetPlayerName))
                else
                    PlayerAimStatus:Set("❌ Alvo inválido ou morto")
                end
            elseif TargetPlayerName then
                PlayerAimStatus:Set("⏸️ Desativado - Alvo: " .. tostring(TargetPlayerName))
            else
                PlayerAimStatus:Set("⚠️ Nenhum jogador selecionado")
            end
        end)
    end
end)

-- Auto-refresh da lista de jogadores a cada 5 segundos
task.spawn(function()
    while wait(5) do
        pcall(function()
            PlayerAimDropdown:Refresh(UpdatePlayerAimList())
        end)
    end
end)

-- ==================================================================================
-- FIM DA ABA PLAYER AIM
-- ==================================================================================

-- ==================================================================================
-- ============================== PROTECTION TAB ====================================
-- ==================================================================================

TabProt:CreateSection("Proteções")

local godMode, lockHP, antiKB, antiVoid, noclip = false, false, false, false, false
local flyUpImpulse = 0

TabProt:CreateToggle({
    Name = "God Mode",
    Default = false,
    Callback = function(v)
        godMode = v
    end
})

TabProt:CreateToggle({
    Name = "Lock HP",
    Default = false,
    Callback = function(v)
        lockHP = v
    end
})

TabProt:CreateToggle({
    Name = "Anti Knockback",
    Default = false,
    Callback = function(v)
        antiKB = v
    end
})

TabProt:CreateToggle({
    Name = "Anti Void",
    Default = false,
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
    Multi = false,
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
local waypointSelected = nil       -- armazena o nome selecionado no dropdown
local waypointNameInput = ""

-- ── helpers ──────────────────────────────────────────────────
local function resolvePosition(pos)
    if type(pos) == "userdata" then return pos end          -- Vector3 nativo
    if type(pos) == "table" then                            -- table do JSON
        return Vector3.new(pos.X or pos[1] or 0, pos.Y or pos[2] or 0, pos.Z or pos[3] or 0)
    end
    return nil
end

local function getWaypointList()
    local list = {}
    for name, _ in pairs(savedWaypoints) do
        table.insert(list, name)
    end
    table.sort(list)
    
    if #list == 0 then
        return {"Nenhum waypoint salvo"}
    end
    
    return list
end

local function saveWaypoint(name)
    if not HRP then return false end
    if not name or name == "" then return false end
    local pos = HRP.CFrame.Position
    -- Garante que cada waypoint é único e armazena corretamente
    savedWaypoints[name] = {
        Position = {X = pos.X, Y = pos.Y, Z = pos.Z},
        Time = os.date("%H:%M:%S")
    }
    return true
end

local function teleportToWaypoint(name)
    if not name or not savedWaypoints[name] then 
        return false 
    end
    if not HRP then 
        return false 
    end
    
    local wpData = savedWaypoints[name]
    local pos = resolvePosition(wpData.Position)
    
    if not pos then 
        return false 
    end
    
    HRP.CFrame = CFrame.new(pos)
    return true
end

local function deleteWaypoint(name)
    if savedWaypoints[name] then
        savedWaypoints[name] = nil
    end
end

-- ── UI ───────────────────────────────────────────────────────
-- Input de nome
TabWaypoints:CreateInput({
    Name = "Nome do Waypoint",
    Placeholder = "Digite o nome...",
    Callback = function(text)
        waypointNameInput = text
    end
})

-- Dropdown criado ANTES dos botões que o usam
local waypointDropdown = TabWaypoints:CreateDropdown({
    Name = "Selecionar Waypoint",
    Options = getWaypointList(),
    Default = getWaypointList()[1],
    Multi = false,
    Callback = function(option)
        -- FIX: Garante que sempre pega a string, não a tabela
        if type(option) == "table" then
            waypointSelected = option[1] or tostring(option)
        else
            waypointSelected = tostring(option)
        end
    end
})

-- Salvar
TabWaypoints:CreateButton({
    Name = "Salvar Posição Atual",
    Callback = function()
        if waypointNameInput == "" or not waypointNameInput then
            WindUI:Notify({ Title = "Erro", Content = "Digite um nome para o waypoint!", Duration = 3 })
            return
        end
        
        local wpName = tostring(waypointNameInput)
        
        if saveWaypoint(wpName) then
            waypointSelected = wpName
            local newList = getWaypointList()
            waypointDropdown:Refresh(newList)
            WindUI:Notify({ Title = "Waypoint Salvo", Content = "'"..wpName.."' foi salvo!", Duration = 3 })
        else
            WindUI:Notify({ Title = "Erro", Content = "Falha ao salvar waypoint!", Duration = 3 })
        end
    end
})

-- Teleportar
TabWaypoints:CreateButton({
    Name = "Teleportar para Waypoint",
    Callback = function()
        -- Converte para string se for tabela
        local targetName = waypointSelected
        if type(targetName) == "table" then
            targetName = targetName[1] or tostring(targetName)
        else
            targetName = tostring(targetName)
        end
        
        if not targetName or targetName == "" or targetName == "Nenhum waypoint salvo" then
            WindUI:Notify({ Title = "Erro", Content = "Selecione um waypoint válido!", Duration = 3 })
            return
        end
        
        if teleportToWaypoint(targetName) then
            WindUI:Notify({ Title = "Teleportado", Content = "Chegou em '"..targetName.."'!", Duration = 2 })
        else
            WindUI:Notify({ Title = "Erro", Content = "Falha ao teleportar. Waypoint pode estar corrompido.", Duration = 3 })
        end
    end
})

-- Deletar
TabWaypoints:CreateButton({
    Name = "Deletar Waypoint",
    Callback = function()
        -- Converte para string se for tabela
        local targetName = waypointSelected
        if type(targetName) == "table" then
            targetName = targetName[1] or tostring(targetName)
        else
            targetName = tostring(targetName)
        end
        
        if not targetName or targetName == "" or targetName == "Nenhum waypoint salvo" then
            WindUI:Notify({ Title = "Erro", Content = "Selecione um waypoint válido!", Duration = 3 })
            return
        end
        
        deleteWaypoint(targetName)
        waypointSelected = nil
        waypointDropdown:Refresh(getWaypointList())
        WindUI:Notify({ Title = "Waypoint Deletado", Content = "Waypoint removido!", Duration = 2 })
    end
})

-- Atualizar lista manualmente (backup)
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
        if not HRP then return end

        -- 1) Tenta encontrar SpawnLocation direta no workspace
        local spawnLocation = workspace:FindFirstChild("SpawnLocation")
            or workspace:FindFirstChildOfClass("SpawnLocation")

        -- 2) Alguns mapas chamam de "Spawn" (um BasePart comum)
        if not spawnLocation then
            spawnLocation = workspace:FindFirstChild("Spawn")
        end

        -- 3) Busca recursiva: pega qualquer SpawnLocation em qualquer lugar do workspace
        if not spawnLocation then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("SpawnLocation") then
                    spawnLocation = obj
                    break
                end
            end
        end

        if spawnLocation then
            HRP.CFrame = spawnLocation.CFrame + Vector3.new(0, 5, 0)
            WindUI:Notify({Title = "Teleportado", Content = "Chegou no Spawn!", Duration = 2})
        else
            -- Fallback: vai para a origem do mapa (0, 5, 0)
            HRP.CFrame = CFrame.new(Vector3.new(0, 5, 0))
            WindUI:Notify({
                Title = "Spawn não encontrado",
                Content = "Foi para a origem do mapa (0, 5, 0).",
                Duration = 3
            })
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
    Range = {70, 180},
    Increment = 1,
    Default = DEFAULT_FOV,
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
    Default = false,
    Callback = function(v)
        FULLBRIGHT_ENABLED = v
        toggleFullbright(v)
    end
})

TabVisuals:CreateSection("Câmera")

local NO_CAMERA_SHAKE = false

TabVisuals:CreateToggle({
    Name = "No Camera Shake",
    Default = false,
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
    Default = 14,
    Callback = function(v)
        Lighting.ClockTime = v
    end
})

TabWorld:CreateSlider({
    Name = "Gravidade",
    Range = {60, 500},
    Increment = 10,
    Default = 196,
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

local DELETE_3D_ENABLED = false
local descendantAddedConnection = nil

-- Advanced Anti-Lag System by RIP#6666
local function setupAdvancedAntiLag()
    if not _G.Ignore then
        _G.Ignore = {}
    end
    if _G.SendNotifications == nil then
        _G.SendNotifications = false -- Disabled notifications for cleaner experience
    end
    if _G.ConsoleLogs == nil then
        _G.ConsoleLogs = false
    end

    if not game:IsLoaded() then
        repeat task.wait() until game:IsLoaded()
    end

    _G.Settings = {
        Players = {
            ["Ignore Me"] = true,
            ["Ignore Others"] = true,
            ["Ignore Tools"] = true
        },
        Meshes = {
            NoMesh = false,
            NoTexture = true,
            Destroy = false
        },
        Images = {
            Invisible = false,
            Destroy = false
        },
        Explosions = {
            Smaller = true,
            Invisible = false,
            Destroy = false
        },
        Particles = {
            Invisible = true,
            Destroy = false
        },
        TextLabels = {
            LowerQuality = true,
            Invisible = false,
            Destroy = false
        },
        MeshParts = {
            LowerQuality = true,
            Invisible = false,
            NoTexture = false,
            NoMesh = false,
            Destroy = false
        },
        Other = {
            ["FPS Cap"] = 60,
            ["No Camera Effects"] = true,
            ["No Clothes"] = false,
            ["Low Water Graphics"] = true,
            ["No Shadows"] = true,
            ["Low Rendering"] = false,
            ["Low Quality Parts"] = true,
            ["Low Quality Models"] = true,
            ["Reset Materials"] = true,
            ["Lower Quality MeshParts"] = true,
            ClearNilInstances = false
        }
    }

    local Players, Lighting, StarterGui, MaterialService = game:GetService("Players"), game:GetService("Lighting"), game:GetService("StarterGui"), game:GetService("MaterialService")
    local ME, CanBeEnabled = Players.LocalPlayer, {"ParticleEmitter", "Trail", "Smoke", "Fire", "Sparkles"}
    
    local function PartOfCharacter(Inst)
        for i, v in pairs(Players:GetPlayers()) do
            if v ~= ME and v.Character and Inst:IsDescendantOf(v.Character) then
                return true
            end
        end
        return false
    end
    
    local function DescendantOfIgnore(Inst)
        for i, v in pairs(_G.Ignore) do
            if Inst:IsDescendantOf(v) then
                return true
            end
        end
        return false
    end
    
    local function CheckIfBad(Inst)
        if not Inst:IsDescendantOf(Players) and (_G.Settings.Players["Ignore Others"] and not PartOfCharacter(Inst) 
        or not _G.Settings.Players["Ignore Others"]) and (_G.Settings.Players["Ignore Me"] and ME.Character and not Inst:IsDescendantOf(ME.Character) 
        or not _G.Settings.Players["Ignore Me"]) and (_G.Settings.Players["Ignore Tools"] and not Inst:IsA("BackpackItem") and not Inst:FindFirstAncestorWhichIsA("BackpackItem") 
        or not _G.Settings.Players["Ignore Tools"]) and (_G.Ignore and not table.find(_G.Ignore, Inst) and not DescendantOfIgnore(Inst) 
        or (not _G.Ignore or type(_G.Ignore) ~= "table" or #_G.Ignore <= 0)) then
            if Inst:IsA("DataModelMesh") then
                if Inst:IsA("SpecialMesh") then
                    if _G.Settings.Meshes.NoMesh then
                        Inst.MeshId = ""
                    end
                    if _G.Settings.Meshes.NoTexture then
                        Inst.TextureId = ""
                    end
                end
                if _G.Settings.Meshes.Destroy then
                    Inst:Destroy()
                end
            elseif Inst:IsA("FaceInstance") then
                if _G.Settings.Images.Invisible then
                    Inst.Transparency = 1
                    Inst.Shiny = 1
                end
                if _G.Settings.Images.Destroy then
                    Inst:Destroy()
                end
            elseif Inst:IsA("ShirtGraphic") then
                if _G.Settings.Images.Invisible then
                    Inst.Graphic = ""
                end
                if _G.Settings.Images.Destroy then
                    Inst:Destroy()
                end
            elseif table.find(CanBeEnabled, Inst.ClassName) then
                if _G.Settings.Particles and _G.Settings.Particles.Invisible then
                    Inst.Enabled = false
                end
                if _G.Settings.Particles and _G.Settings.Particles.Destroy then
                    Inst:Destroy()
                end
            elseif Inst:IsA("PostEffect") and (_G.Settings.Other and _G.Settings.Other["No Camera Effects"]) then
                Inst.Enabled = false
            elseif Inst:IsA("Explosion") then
                if _G.Settings.Explosions and _G.Settings.Explosions.Smaller then
                    Inst.BlastPressure = 1
                    Inst.BlastRadius = 1
                end
                if _G.Settings.Explosions and _G.Settings.Explosions.Invisible then
                    Inst.BlastPressure = 1
                    Inst.BlastRadius = 1
                    Inst.Visible = false
                end
                if _G.Settings.Explosions and _G.Settings.Explosions.Destroy then
                    Inst:Destroy()
                end
            elseif Inst:IsA("Clothing") or Inst:IsA("SurfaceAppearance") or Inst:IsA("BaseWrap") then
                if _G.Settings.Other and _G.Settings.Other["No Clothes"] then
                    Inst:Destroy()
                end
            elseif Inst:IsA("BasePart") and not Inst:IsA("MeshPart") then
                if _G.Settings.Other and _G.Settings.Other["Low Quality Parts"] then
                    Inst.Material = Enum.Material.Plastic
                    Inst.Reflectance = 0
                end
            elseif Inst:IsA("TextLabel") and Inst:IsDescendantOf(workspace) then
                if _G.Settings.TextLabels and _G.Settings.TextLabels.LowerQuality then
                    Inst.Font = Enum.Font.SourceSans
                    Inst.TextScaled = false
                    Inst.RichText = false
                    Inst.TextSize = 14
                end
                if _G.Settings.TextLabels and _G.Settings.TextLabels.Invisible then
                    Inst.Visible = false
                end
                if _G.Settings.TextLabels and _G.Settings.TextLabels.Destroy then
                    Inst:Destroy()
                end
            elseif Inst:IsA("Model") then
                if _G.Settings.Other and _G.Settings.Other["Low Quality Models"] then
                    Inst.LevelOfDetail = 1
                end
            elseif Inst:IsA("MeshPart") then
                if _G.Settings.MeshParts and _G.Settings.MeshParts.LowerQuality then
                    Inst.RenderFidelity = 2
                    Inst.Reflectance = 0
                    Inst.Material = Enum.Material.Plastic
                end
                if _G.Settings.MeshParts and _G.Settings.MeshParts.Invisible then
                    Inst.Transparency = 1
                    Inst.RenderFidelity = 2
                    Inst.Reflectance = 0
                    Inst.Material = Enum.Material.Plastic
                end
                if _G.Settings.MeshParts and _G.Settings.MeshParts.NoTexture then
                    Inst.TextureID = ""
                end
                if _G.Settings.MeshParts and _G.Settings.MeshParts.NoMesh then
                    Inst.MeshId = ""
                end
                if _G.Settings.MeshParts and _G.Settings.MeshParts.Destroy then
                    Inst:Destroy()
                end
            end
        end
    end

    -- Apply terrain settings
    coroutine.wrap(pcall)(function()
        if _G.Settings.Other and _G.Settings.Other["Low Water Graphics"] then
            local terrain = workspace:FindFirstChildOfClass("Terrain")
            if not terrain then
                repeat task.wait() until workspace:FindFirstChildOfClass("Terrain")
                terrain = workspace:FindFirstChildOfClass("Terrain")
            end
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 0
            if sethiddenproperty then
                sethiddenproperty(terrain, "Decoration", false)
            end
        end
    end)

    -- Apply lighting settings
    coroutine.wrap(pcall)(function()
        if _G.Settings.Other and _G.Settings.Other["No Shadows"] then
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.ShadowSoftness = 0
            if sethiddenproperty then
                sethiddenproperty(Lighting, "Technology", 2)
            end
        end
    end)

    -- Apply rendering settings
    coroutine.wrap(pcall)(function()
        if _G.Settings.Other and _G.Settings.Other["Low Rendering"] then
            settings().Rendering.QualityLevel = 1
            settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
        end
    end)

    -- Reset materials
    coroutine.wrap(pcall)(function()
        if _G.Settings.Other and _G.Settings.Other["Reset Materials"] then
            for i, v in pairs(MaterialService:GetChildren()) do
                v:Destroy()
            end
            MaterialService.Use2022Materials = false
        end
    end)

    -- Process existing descendants
    local Descendants = game:GetDescendants()
    for i, v in pairs(Descendants) do
        CheckIfBad(v)
    end

    -- Monitor new descendants
    game.DescendantAdded:Connect(function(value)
        task.wait(_G.LoadedWait or 1)
        CheckIfBad(value)
    end)
end

-- ✅ FUNÇÃO CORRIGIDA: Usa LP em vez de LocalPlayer
local function hide3D(obj)
    pcall(function()
        -- ✅ CORRIGIDO: Usa "LP" em vez de "LocalPlayer"
        if LP.Character and obj:IsDescendantOf(LP.Character) then 
            return 
        end
        
        if obj:IsA("BasePart") then
            obj.Transparency = 1
        elseif obj:IsA("Decal") then
            obj.Transparency = 1
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
            obj.Enabled = false
        elseif obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            obj.Enabled = false
        end
    end)
end

local function apply3DDelete()
    if not DELETE_3D_ENABLED then return end
    
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            hide3D(obj)
        end
    end)
end

TabFPS:CreateToggle({
    Name = "Advanced Anti-Lag (RIP)",
    Default = false,
    Callback = function(v)
        if v then
            setupAdvancedAntiLag()
            WindUI:Notify({
                Title = "Anti-Lag Ativado",
                Content = "Sistema avançado de otimização ativado!",
                Duration = 2
            })
        end
    end
})

TabFPS:CreateToggle({
    Name = "3D Delete (Hide World)",
    Default = false,
    Callback = function(v)
        DELETE_3D_ENABLED = v
        if v then
            apply3DDelete()
            -- Auto-hide new objects
            if descendantAddedConnection then
                descendantAddedConnection:Disconnect()
            end
            descendantAddedConnection = workspace.DescendantAdded:Connect(hide3D)
            
            WindUI:Notify({
                Title = "3D Delete Ativado",
                Content = "Mundo escondido! FPS otimizado.",
                Duration = 2
            })
        else
            -- Disconnect listener when disabled
            if descendantAddedConnection then
                descendantAddedConnection:Disconnect()
                descendantAddedConnection = nil
            end
            
            WindUI:Notify({
                Title = "3D Delete Desativado",
                Content = "Recarregue o jogo para ver o mundo novamente.",
                Duration = 3
            })
        end
    end
})

TabFPS:CreateSlider({
    Name = "FPS Cap",
    Range = {60, 240},
    Increment = 10,
    Default = 60,
    Callback = function(v)
        setfpscap(v)
    end
})

TabFPS:CreateSection("Stats")

local statsLabel   = TabFPS:CreateLabel("Carregando...")
local fpsLabel     = TabFPS:CreateLabel("FPS: 0")
local pingLabel    = TabFPS:CreateLabel("Ping: 0ms")
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
-- ================================ CONFIG TAB ==========================
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
    Default = false,
    Callback = function(v)
        ANTI_AFK_ENABLED = v
        if v then
            WindUI:Notify({
                Title = "Anti AFK Ativado",
                Content = "Você não será kickado por inatividade",
                Duration = 2
            })
        end
    end
})

TabConfig:CreateSection("⌨️ Keybinds Principais")

-- ==================== VARIÁVEIS DE KEYBIND ====================
local keybindESP         = Enum.KeyCode.E
local keybindHighlight   = Enum.KeyCode.H
local keybindAim         = Enum.KeyCode.R
local keybindPlayerAim   = Enum.KeyCode.T
local keybindFly         = Enum.KeyCode.F
local keybindNoclip      = Enum.KeyCode.N
local keybindGodMode     = Enum.KeyCode.G
local keybindInfJump     = Enum.KeyCode.J
local keybindAutoClicker = Enum.KeyCode.C
local keybindFullbright  = Enum.KeyCode.B
local keybindGUI         = Enum.KeyCode.RightControl

-- ==================== ESP KEYBIND ====================
TabConfig:CreateKeybind({
    Name = "Toggle ESP",
    Default = "E",
    Callback = function(key)
        keybindESP = key
    end
})

-- ==================== HIGHLIGHT ESP KEYBIND ====================
TabConfig:CreateKeybind({
    Name = "Toggle Highlight ESP",
    Default = "H",
    Callback = function(key)
        keybindHighlight = key
    end
})

-- ==================== AIM ASSIST KEYBIND ====================
TabConfig:CreateKeybind({
    Name = "Toggle Aim Assist",
    Default = "R",
    Callback = function(key)
        keybindAim = key
    end
})

-- ==================== PLAYER AIM KEYBIND ====================
TabConfig:CreateKeybind({
    Name = "Toggle Player Aim",
    Default = "T",
    Callback = function(key)
        keybindPlayerAim = key
    end
})

TabConfig:CreateSection("⌨️ Keybinds de Movimento")

-- ==================== FLY KEYBIND ====================
TabConfig:CreateKeybind({
    Name = "Toggle Fly",
    Default = "F",
    Callback = function(key)
        keybindFly = key
    end
})

-- ==================== NOCLIP KEYBIND ====================
TabConfig:CreateKeybind({
    Name = "Toggle Noclip",
    Default = "N",
    Callback = function(key)
        keybindNoclip = key
    end
})

-- ==================== INFINITE JUMP KEYBIND ====================
TabConfig:CreateKeybind({
    Name = "Toggle Infinite Jump",
    Default = "J",
    Callback = function(key)
        keybindInfJump = key
    end
})

TabConfig:CreateSection("⌨️ Keybinds de Combat")

-- ==================== AUTO CLICKER KEYBIND ====================
TabConfig:CreateKeybind({
    Name = "Toggle Auto Clicker",
    Default = "C",
    Callback = function(key)
        keybindAutoClicker = key
    end
})

TabConfig:CreateSection("⌨️ Keybinds de Proteção")

-- ==================== GOD MODE KEYBIND ====================
TabConfig:CreateKeybind({
    Name = "Toggle God Mode",
    Default = "G",
    Callback = function(key)
        keybindGodMode = key
    end
})

TabConfig:CreateSection("⌨️ Keybinds Visuais")

-- ==================== FULLBRIGHT KEYBIND ====================
TabConfig:CreateKeybind({
    Name = "Toggle Fullbright",
    Default = "B",
    Callback = function(key)
        keybindFullbright = key
    end
})

TabConfig:CreateSection("⌨️ Keybind da GUI")

-- ==================== GUI TOGGLE KEYBIND ====================
TabConfig:CreateKeybind({
    Name = "Toggle GUI",
    Default = "RightControl",
    Callback = function(key)
        keybindGUI = key
    end
})

-- ==================================================================================
-- ===================== SISTEMA DE DETECÇÃO DE KEYBINDS ===========================
-- ==================================================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- ESP TOGGLE
    if input.KeyCode == keybindESP then
        ESP_ENABLED = not ESP_ENABLED
        refreshESP()
        WindUI:Notify({
            Title = "ESP",
            Content = ESP_ENABLED and "✅ Ativado" or "❌ Desativado",
            Duration = 1.5
        })
    
    -- HIGHLIGHT ESP TOGGLE
    elseif input.KeyCode == keybindHighlight then
        HIGHLIGHT_ENABLED = not HIGHLIGHT_ENABLED
        updateAllHighlights()
        WindUI:Notify({
            Title = "Highlight ESP",
            Content = HIGHLIGHT_ENABLED and "✅ Ativado" or "❌ Desativado",
            Duration = 1.5
        })
    
    -- AIM ASSIST TOGGLE
    elseif input.KeyCode == keybindAim then
        AIM_ENABLED = not AIM_ENABLED
        currentTarget = nil
        WindUI:Notify({
            Title = "Aim Assist",
            Content = AIM_ENABLED and "✅ Ativado" or "❌ Desativado",
            Duration = 1.5
        })
    
    -- PLAYER AIM TOGGLE
    elseif input.KeyCode == keybindPlayerAim then
        if not TargetPlayerName then
            WindUI:Notify({
                Title = "⚠️ Player Aim",
                Content = "Selecione um jogador primeiro!",
                Duration = 2
            })
            return
        end
        
        PlayerAimEnabled = not PlayerAimEnabled
        WindUI:Notify({
            Title = "Player Aim",
            Content = PlayerAimEnabled and ("✅ Mirando em " .. tostring(TargetPlayerName)) or "❌ Desativado",
            Duration = 1.5
        })
    
    -- FLY TOGGLE
    elseif input.KeyCode == keybindFly then
        local newState = not flyEnabled
        toggleFly(newState)
        WindUI:Notify({
            Title = "Fly",
            Content = newState and "✅ Ativado" or "❌ Desativado",
            Duration = 1.5
        })
    
    -- NOCLIP TOGGLE
    elseif input.KeyCode == keybindNoclip then
        noclip = not noclip
        WindUI:Notify({
            Title = "Noclip",
            Content = noclip and "✅ Ativado" or "❌ Desativado",
            Duration = 1.5
        })
    
    -- INFINITE JUMP TOGGLE
    elseif input.KeyCode == keybindInfJump then
        infJump = not infJump
        WindUI:Notify({
            Title = "Infinite Jump",
            Content = infJump and "✅ Ativado" or "❌ Desativado",
            Duration = 1.5
        })
    
    -- AUTO CLICKER TOGGLE
    elseif input.KeyCode == keybindAutoClicker then
        AUTO_CLICKER_ENABLED = not AUTO_CLICKER_ENABLED
        if AUTO_CLICKER_ENABLED then 
            lastClick = tick() 
        end
        WindUI:Notify({
            Title = "Auto Clicker",
            Content = AUTO_CLICKER_ENABLED and "✅ Ativado" or "❌ Desativado",
            Duration = 1.5
        })
    
    -- GOD MODE TOGGLE
    elseif input.KeyCode == keybindGodMode then
        godMode = not godMode
        WindUI:Notify({
            Title = "God Mode",
            Content = godMode and "✅ Ativado" or "❌ Desativado",
            Duration = 1.5
        })
    
    -- FULLBRIGHT TOGGLE
    elseif input.KeyCode == keybindFullbright then
        FULLBRIGHT_ENABLED = not FULLBRIGHT_ENABLED
        toggleFullbright(FULLBRIGHT_ENABLED)
        WindUI:Notify({
            Title = "Fullbright",
            Content = FULLBRIGHT_ENABLED and "✅ Ativado" or "❌ Desativado",
            Duration = 1.5
        })
    
    -- GUI TOGGLE
    elseif input.KeyCode == keybindGUI then
        Window:Toggle()
    end
end)

TabConfig:CreateSection("🗑️ GUI")

TabConfig:CreateButton({
    Name = "Destruir GUI (Irreversível)",
    Callback = function()
        clearAllESP()
        removeAllHighlights()
        WindUI:Notify({
            Title = "⚠️ GUI Destruída",
            Content = "Recarregue o script para usar novamente",
            Duration = 3
        })
        task.wait(1)
        Window:Destroy()
    end
})

TabConfig:CreateSection("📋 Lista de Keybinds")

TabConfig:CreateLabel("ESP: E | Highlight: H")
TabConfig:CreateLabel("Aim: R | Player Aim: T")
TabConfig:CreateLabel("Fly: F | Noclip: N")
TabConfig:CreateLabel("Inf Jump: J | Auto Click: C")
TabConfig:CreateLabel("God Mode: G | Fullbright: B")
TabConfig:CreateLabel("Toggle GUI: RightControl")

-- ==================================================================================
-- FIM DA CONFIG TAB
-- ==================================================================================

-- ==================================================================================
-- =============================== UTILITY TAB ======================================
-- ==================================================================================

TabUtil:CreateSection("Noclip")

TabUtil:CreateToggle({
    Name = "Noclip",
    Default = false,
    Callback = function(v)
        noclip = v
    end
})

-- ================== SHIFT LOCK SYSTEM (COMPLETO - SEM UI) ==================
local shiftLockEnabled = false
local shiftLockRotConnection
local oldAutoRotate

local function lockMouse(enabled)
    if UserInputService.MouseEnabled then
        UserInputService.MouseBehavior = enabled and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
    end
end

local function faceCameraDirection(humanoid, rootPart, enabled)
    -- Desconecta conexão anterior se existir
    if shiftLockRotConnection then
        shiftLockRotConnection:Disconnect()
        shiftLockRotConnection = nil
    end
    
    if enabled then
        -- Salva configuração original
        oldAutoRotate = humanoid.AutoRotate
        humanoid.AutoRotate = false
        
        -- Conecta sistema de rotação
        shiftLockRotConnection = RunService.RenderStepped:Connect(function()
            local camera = Workspace.CurrentCamera
            if not rootPart or not camera then return end
            
            local lookVector = camera.CFrame.LookVector
            local flatVector = Vector3.new(lookVector.X, 0, lookVector.Z)
            
            if flatVector.Magnitude > 0.0001 then
                rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + flatVector.Unit, Vector3.yAxis)
            end
        end)
    else
        -- Restaura configuração original
        if oldAutoRotate ~= nil then
            humanoid.AutoRotate = oldAutoRotate
        end
    end
end

local function applyShiftLock(enabled)
    if not Character or not Humanoid or not HRP then 
        task.wait(0.5)
        if LP.Character then
            BindCharacter(LP.Character)
        end
        return 
    end
    
    shiftLockEnabled = enabled
    lockMouse(enabled)
    faceCameraDirection(Humanoid, HRP, enabled)
end

-- Reaplica shift lock quando o personagem respawna
LP.CharacterAdded:Connect(function()
    task.defer(function()
        task.wait(0.5)
        if shiftLockEnabled then
            applyShiftLock(true)
        end
    end)
end)

-- Reaplica quando a câmera muda
local lastCamera = Workspace.CurrentCamera
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    local currentCamera = Workspace.CurrentCamera
    if currentCamera ~= lastCamera then
        lastCamera = currentCamera
        if shiftLockEnabled then
            task.defer(function()
                applyShiftLock(true)
            end)
        end
    end
end)

TabUtil:CreateToggle({
    Name = "Shift Lock",
    Default = false,
    Callback = function(v)
        applyShiftLock(v)
    end
})

TabUtil:CreateToggle({
    Name = "Insta Interact",
    Default = false,
    Callback = function(v)
        _G.InstaInteract = v
        if _G.InstaInteract then
            _G.InstaInteractConnection = game:GetService("ProximityPromptService").PromptButtonHoldBegan:Connect(function(prompt)
                fireproximityprompt(prompt)
            end)
        else
            if _G.InstaInteractConnection then
                _G.InstaInteractConnection:Disconnect()
            end
        end
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

    if flyEnabled then
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

print("✅ Universal Hub - WindUI Edition!")
print("📊 ESP: Sistema corrigido com filtros de time funcionais")
print("✨ Highlight ESP: Sistema corrigido com cores e filtros funcionais")
print("🎯 Aim Assist: Wallcheck melhorado + SEM FOV Circle + Filtros de time")
print("🔧 Arsenal e jogos com times: Totalmente funcional")