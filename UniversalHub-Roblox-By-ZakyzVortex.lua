-- ================== UNIVERSAL HUB - WINDUI VERSION ==================
-- Universal Hub WindUI By ZakyzVortex (Mobile Optimized & Organized)

-- ================== SERVICES ==================
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local Lighting        = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local UserInputService= game:GetService("UserInputService")
local HttpService     = game:GetService("HttpService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ================== CARREGAR WINDUI ==================
local success, WindUI = pcall(function()
    return loadstring(game:HttpGet(
        "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
    ))()
end)

if not success then
    warn("❌ Falha ao carregar WindUI: " .. tostring(WindUI))
    return
end

-- ================== NOTIFY OVERRIDE ==================
WindUI._notifDisabled = false
local _originalNotify = WindUI.Notify
WindUI.Notify = function(self, data)
    if WindUI._notifDisabled then return end
    return _originalNotify(self, data)
end

local Character, Humanoid, HRP
local function BindCharacter(char)
    Character = char
    Humanoid  = char:WaitForChild("Humanoid")
    HRP       = char:WaitForChild("HumanoidRootPart")
    pcall(function() Humanoid.UseJumpPower = true end)
end

if LP.Character then
    BindCharacter(LP.Character)
else
    LP.CharacterAdded:Wait()
    BindCharacter(LP.Character)
end
LP.CharacterAdded:Connect(BindCharacter)

-- ================== TEAM DETECTION ==================
local function getPlayerTeam(player)
    if not player then return nil end
    return player.Team
end

-- Helper para normalizar valor que vem do Dropdown WindUI
-- Multi=false → retorna string direta
-- Multi=true  → retorna tabela { [1] = "val", ... }
local function parseDropdownValue(opt)
    if type(opt) == "table" then
        -- Multi=true: pega o primeiro valor selecionado
        for k, v in pairs(opt) do
            return tostring(k)   -- WindUI Multi retorna {["Key"] = true}
        end
        return ""
    end
    return tostring(opt or "")
end

local function shouldShowPlayer(player, filterMode)
    if not player or player == LP then return false end
    -- Normaliza: minúsculas, remove espaços e hífens
    local mode = filterMode and filterMode:lower():gsub("[%s%-]+", "") or "all"
    if mode == "all" then
        return true
    elseif mode == "myteam" or mode == "team" then
        local myTeam    = getPlayerTeam(LP)
        local theirTeam = getPlayerTeam(player)
        if not myTeam or not theirTeam then return false end
        return myTeam == theirTeam
    elseif mode == "enemyteam" or mode == "enemy" or mode == "enemies" then
        local myTeam    = getPlayerTeam(LP)
        local theirTeam = getPlayerTeam(player)
        -- Jogo sem times → mostra todos
        if not myTeam or not theirTeam then return true end
        return myTeam ~= theirTeam
    end
    return true
end

-- ================== WINDOW ==================
local Window = WindUI:CreateWindow({
    Title          = "Universal Hub",
    Icon           = "earth",
    IconThemed = true,
    Author         = "By ZakyzVortex",
    Folder         = "UniversalHub",
    Size           = UDim2.fromOffset(580, 460),
    Transparent    = false,
    HasPadding     = true,
    HideSearchBar  = false,
    Resizable      = true,
    SideBarWidth   = 200,

    -- Foto do personagem anônima no topbar
    User = {
        Enabled   = true,
        Anonymous = false,
        Callback  = function() end,
    },
})

-- ================== CONFIG MANAGER ==================
local ConfigManager = Window.ConfigManager
local hubConfig     = ConfigManager:CreateConfig("HubConfig")

-- Open Button: ícone "earth", contorno verde claro
Window:EditOpenButton({
    Title           = "Universal Hub",
    Icon            = "earth",
    CornerRadius    = UDim.new(0, 16),
    StrokeThickness = 2,
    Color           = ColorSequence.new(
        Color3.fromHex("#ffffff"),
        Color3.fromHex("#2b2b2b")
    ),
    OnlyMobile = false,
    Enabled    = true,
    Draggable  = true,
})

-- ================== TABS ==================
local TabMove      = Window:Tab({ Title = "Movement",   Icon = "footprints"     })
local TabCombat    = Window:Tab({ Title = "Combat",     Icon = "sword"          })
local TabESP       = Window:Tab({ Title = "ESP",        Icon = "eye"            })
local TabHighlight = Window:Tab({ Title = "Highlight",  Icon = "sparkles"       })
local TabAim       = Window:Tab({ Title = "Aim Assist", Icon = "crosshair"      })
local TabPlayerAim = Window:Tab({ Title = "Player Aim", Icon = "target"         })
local TabProt      = Window:Tab({ Title = "Protection", Icon = "shield"         })
local TabPlayers   = Window:Tab({ Title = "Players",    Icon = "users"          })
local TabWaypoints = Window:Tab({ Title = "Waypoints",  Icon = "map-pin"        })
local TabVisuals   = Window:Tab({ Title = "Visuals",    Icon = "sun"            })
local TabWorld     = Window:Tab({ Title = "World",      Icon = "globe"          })
local TabFPS       = Window:Tab({ Title = "FPS/Stats",  Icon = "activity"       })
local TabConfig    = Window:Tab({ Title = "Config",     Icon = "settings"       })
local TabUtil      = Window:Tab({ Title = "Utility",    Icon = "wrench"         })

-- ==================================================================================
-- ============================== MOVEMENT TAB ======================================
-- ==================================================================================

TabMove:Section({ Title = "Velocidade e Pulo" })

local infJump = false
local antiFall = false

TabMove:Slider({
    Title = "Velocidade de Caminhada",
    Flag     = "WalkSpeed",
    Step  = 5,
    Value = { Min = 16, Max = 300, Default = 16 },
    Callback = function(v)
        if Humanoid then Humanoid.WalkSpeed = v end
    end
})

TabMove:Slider({
    Title = "Poder de Pulo",
    Flag     = "JumpPower",
    Step  = 10,
    Value = { Min = 50, Max = 300, Default = 50 },
    Callback = function(v)
        if Humanoid then
            Humanoid.UseJumpPower = true
            Humanoid.JumpPower = v
        end
    end
})

TabMove:Section({ Title = "Fly System" })

-- ================== FLY SYSTEM ==================
local flyEnabled = false
local flySpeed   = 1
local tpwalking  = false
local ctrl       = { f = 0, b = 0, l = 0, r = 0 }
local lastctrl   = { f = 0, b = 0, l = 0, r = 0 }

local function toggleFly(enabled)
    flyEnabled = enabled
    local chr = LP.Character
    local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
    if not chr or not hum then return end

    if enabled then
        pcall(function() chr.Animate.Disabled = true end)
        pcall(function()
            for _, v in next, hum:GetPlayingAnimationTracks() do v:AdjustSpeed(0) end
        end)
        local states = {
            Enum.HumanoidStateType.Climbing, Enum.HumanoidStateType.FallingDown,
            Enum.HumanoidStateType.Flying,   Enum.HumanoidStateType.Freefall,
            Enum.HumanoidStateType.GettingUp,Enum.HumanoidStateType.Jumping,
            Enum.HumanoidStateType.Landed,   Enum.HumanoidStateType.Physics,
            Enum.HumanoidStateType.PlatformStanding, Enum.HumanoidStateType.Ragdoll,
            Enum.HumanoidStateType.Running,  Enum.HumanoidStateType.RunningNoPhysics,
            Enum.HumanoidStateType.Seated,   Enum.HumanoidStateType.StrafingNoPhysics,
            Enum.HumanoidStateType.Swimming,
        }
        for _, s in ipairs(states) do hum:SetStateEnabled(s, false) end
        hum:ChangeState(Enum.HumanoidStateType.Swimming)

        for i = 1, flySpeed do
            spawn(function()
                local hb = RunService.Heartbeat
                tpwalking = true
                local c = LP.Character
                local h = c and c:FindFirstChildWhichIsA("Humanoid")
                while tpwalking and hb:Wait() and c and h and h.Parent do
                    if h.MoveDirection.Magnitude > 0 then c:TranslateBy(h.MoveDirection) end
                end
            end)
        end

        local part = hum.RigType == Enum.HumanoidRigType.R6
            and chr:FindFirstChild("Torso")
            or  chr:FindFirstChild("UpperTorso")
        if part then
            local bg = Instance.new("BodyGyro", part)
            bg.P = 9e4; bg.maxTorque = Vector3.new(9e9,9e9,9e9); bg.cframe = part.CFrame
            local bv = Instance.new("BodyVelocity", part)
            bv.velocity = Vector3.new(0,0.1,0); bv.maxForce = Vector3.new(9e9,9e9,9e9)
            hum.PlatformStand = true

            spawn(function()
                local maxspeed, speed = 50, 0
                while flyEnabled and hum.Health > 0 do
                    task.wait()
                    if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
                        speed = math.min(speed + 0.5 + speed / maxspeed, maxspeed)
                    elseif speed ~= 0 then
                        speed = math.max(speed - 1, 0)
                    end
                    local cam = workspace.CurrentCamera
                    if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
                        bv.velocity = (cam.CoordinateFrame.lookVector * (ctrl.f+ctrl.b) +
                            ((cam.CoordinateFrame * CFrame.new(ctrl.l+ctrl.r,(ctrl.f+ctrl.b)*0.2,0).p) - cam.CoordinateFrame.p)) * speed
                        lastctrl = { f=ctrl.f, b=ctrl.b, l=ctrl.l, r=ctrl.r }
                    elseif speed ~= 0 then
                        bv.velocity = (cam.CoordinateFrame.lookVector * (lastctrl.f+lastctrl.b) +
                            ((cam.CoordinateFrame * CFrame.new(lastctrl.l+lastctrl.r,(lastctrl.f+lastctrl.b)*0.2,0).p) - cam.CoordinateFrame.p)) * speed
                    else
                        bv.velocity = Vector3.new(0,0,0)
                    end
                    bg.cframe = cam.CoordinateFrame * CFrame.Angles(-math.rad((ctrl.f+ctrl.b)*50*speed/maxspeed),0,0)
                end
                ctrl = {f=0,b=0,l=0,r=0}; lastctrl = {f=0,b=0,l=0,r=0}; speed = 0
                bg:Destroy(); bv:Destroy(); hum.PlatformStand = false
            end)
        end
    else
        tpwalking = false; flyEnabled = false
        for _, obj in pairs(chr:GetDescendants()) do
            if obj:IsA("BodyGyro") or obj:IsA("BodyVelocity") then obj:Destroy() end
        end
        local states = {
            Enum.HumanoidStateType.Climbing, Enum.HumanoidStateType.FallingDown,
            Enum.HumanoidStateType.Flying,   Enum.HumanoidStateType.Freefall,
            Enum.HumanoidStateType.GettingUp,Enum.HumanoidStateType.Jumping,
            Enum.HumanoidStateType.Landed,   Enum.HumanoidStateType.Physics,
            Enum.HumanoidStateType.PlatformStanding, Enum.HumanoidStateType.Ragdoll,
            Enum.HumanoidStateType.Running,  Enum.HumanoidStateType.RunningNoPhysics,
            Enum.HumanoidStateType.Seated,   Enum.HumanoidStateType.StrafingNoPhysics,
            Enum.HumanoidStateType.Swimming,
        }
        for _, s in ipairs(states) do hum:SetStateEnabled(s, true) end
        hum:ChangeState(Enum.HumanoidStateType.Freefall)
        hum.PlatformStand = false
        pcall(function() chr.Animate.Disabled = false end)
        pcall(function()
            for _, v in next, hum:GetPlayingAnimationTracks() do v:AdjustSpeed(1) end
        end)
    end
end

TabMove:Slider({
    Title = "Velocidade de Voo",
    Flag     = "FlySpeed",
    Step  = 1,
    Value = { Min = 1, Max = 50, Default = 1 },
    Callback = function(v)
        flySpeed = v
        if flyEnabled then
            tpwalking = false
            task.wait(0.1)
            for i = 1, flySpeed do
                spawn(function()
                    local hb = RunService.Heartbeat
                    tpwalking = true
                    local c = LP.Character
                    local h = c and c:FindFirstChildWhichIsA("Humanoid")
                    while tpwalking and hb:Wait() and c and h and h.Parent do
                        if h.MoveDirection.Magnitude > 0 then c:TranslateBy(h.MoveDirection) end
                    end
                end)
            end
        end
    end
})

TabMove:Toggle({
    Title = "Ativar Fly",
    Flag     = "FlyEnabled",
    Value = false,
    Callback = function(v) toggleFly(v) end
})

-- WASD fly controls
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if     input.KeyCode == Enum.KeyCode.W then ctrl.f =  1
        elseif input.KeyCode == Enum.KeyCode.S then ctrl.b = -1
        elseif input.KeyCode == Enum.KeyCode.A then ctrl.l = -1
        elseif input.KeyCode == Enum.KeyCode.D then ctrl.r =  1 end
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if     input.KeyCode == Enum.KeyCode.W then ctrl.f = 0
        elseif input.KeyCode == Enum.KeyCode.S then ctrl.b = 0
        elseif input.KeyCode == Enum.KeyCode.A then ctrl.l = 0
        elseif input.KeyCode == Enum.KeyCode.D then ctrl.r = 0 end
    end
end)

-- Reset ao morrer/respawn
LP.CharacterAdded:Connect(function(char)
    task.wait(0.7)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
    pcall(function() char.Animate.Disabled = false end)
    flyEnabled = false
end)

TabMove:Section({ Title = "Outros" })

TabMove:Toggle({
    Title = "Pulo Infinito",
    Flag     = "InfJump",
    Value = false,
    Callback = function(v) infJump = v end
})

TabMove:Toggle({
    Title = "Anti Queda",
    Flag     = "AntiFall",
    Value = false,
    Callback = function(v) antiFall = v end
})

UserInputService.JumpRequest:Connect(function()
    if infJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ==================================================================================
-- ============================== COMBAT TAB ========================================
-- ==================================================================================

TabCombat:Section({ Title = "Auto Clicker" })

local AUTO_CLICKER_ENABLED = false
local AUTO_CLICKER_CPS     = 10
local lastClick            = 0

local VirtualInputManager = game:GetService("VirtualInputManager")

local function performClick()
    if not AUTO_CLICKER_ENABLED then return end
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true,  game, 0)
    task.wait(0.01)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

TabCombat:Toggle({
    Title = "Ativar Auto Clicker",
    Flag     = "AutoClicker",
    Value = false,
    Callback = function(v)
        AUTO_CLICKER_ENABLED = v
        if v then lastClick = tick() end
    end
})

TabCombat:Slider({
    Title = "CPS (Cliques por Segundo)",
    Flag     = "AutoClickerCPS",
    Step  = 1,
    Value = { Min = 1, Max = 50, Default = 10 },
    Callback = function(v) AUTO_CLICKER_CPS = v end
})

RunService.Heartbeat:Connect(function()
    if not AUTO_CLICKER_ENABLED then return end
    local now = tick()
    if now - lastClick >= (1 / AUTO_CLICKER_CPS) then
        performClick()
        lastClick = now
    end
end)

TabCombat:Section({ Title = "Auto Clicker Alt" })

TabCombat:Button({
    Title = "Ativar Auto Clicker Alt",
    Callback = function()
        pcall(function()
            getgenv().key = "Hostile"
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Hosvile/The-telligence/main/MC%20KSystem%202"))()
        end)
        WindUI:Notify({ Title = "Auto Clicker Alt", Content = "Script carregado!", Duration = 2 })
    end
})

TabCombat:Section({ Title = "Kill Aura" })

do -- Kill Aura
    local KA_ENABLED    = false
    local KA_SIZE       = 10
    local KA_DEATHCHECK = true

    local function startKillAura()
        -- Limpa instância anterior se existir
        local prev = getgenv().configs
        if prev then
            local conns   = prev.connection
            local disable = prev.Disable
            if conns then for _, c in conns do pcall(function() c:Disconnect() end) end end
            if disable then pcall(function() disable:Fire() disable:Destroy() end) end
            table.clear(prev)
        end

        local Disable = Instance.new("BindableEvent")
        getgenv().configs = {
            connection   = {},
            Disable      = Disable,
            Size         = Vector3.new(KA_SIZE, KA_SIZE, KA_SIZE),
            DeathCheck   = KA_DEATHCHECK,
        }

        local _Players    = cloneref(game:GetService("Players"))
        local _RunService = cloneref(game:GetService("RunService"))
        local lp          = _Players.LocalPlayer
        local Run         = true
        local Ignorelist  = OverlapParams.new()
        Ignorelist.FilterType = Enum.RaycastFilterType.Include

        local function getchar(plr) return (plr or lp).Character end
        local function gethumanoid(plrOrChar)
            local char = plrOrChar:IsA("Model") and plrOrChar or getchar(plrOrChar)
            return char and char:FindFirstChildWhichIsA("Humanoid")
        end
        local function IsAlive(hum) return hum and hum.Health > 0 end
        local function GetTouchInterest(tool)
            return tool and tool:FindFirstChildWhichIsA("TouchTransmitter", true)
        end
        local function GetCharacters(localChar)
            local chars = {}
            for _, p in _Players:GetPlayers() do table.insert(chars, getchar(p)) end
            local idx = table.find(chars, localChar)
            if idx then table.remove(chars, idx) end
            return chars
        end
        local function Attack(tool, touchPart, toTouch)
            if tool:IsDescendantOf(workspace) then
                tool:Activate()
                firetouchinterest(touchPart, toTouch, 1)
                firetouchinterest(touchPart, toTouch, 0)
            end
        end

        table.insert(getgenv().configs.connection, Disable.Event:Connect(function()
            Run = false
        end))

        task.spawn(function()
            while Run do
                local char = getchar()
                if IsAlive(gethumanoid(char)) then
                    local tool        = char and char:FindFirstChildWhichIsA("Tool")
                    local touchInter  = tool and GetTouchInterest(tool)
                    if touchInter then
                        local touchPart = touchInter.Parent
                        local chars     = GetCharacters(char)
                        Ignorelist.FilterDescendantsInstances = chars
                        local inBox = workspace:GetPartBoundsInBox(
                            touchPart.CFrame,
                            touchPart.Size + getgenv().configs.Size,
                            Ignorelist
                        )
                        for _, v in inBox do
                            local Character = v:FindFirstAncestorWhichIsA("Model")
                            if table.find(chars, Character) then
                                if getgenv().configs.DeathCheck then
                                    if IsAlive(gethumanoid(Character)) then
                                        Attack(tool, touchPart, v)
                                    end
                                else
                                    Attack(tool, touchPart, v)
                                end
                            end
                        end
                    end
                end
                _RunService.Heartbeat:Wait()
            end
        end)
    end

    local function stopKillAura()
        local cfg = getgenv().configs
        if cfg then
            local conns   = cfg.connection
            local disable = cfg.Disable
            if conns then for _, c in conns do pcall(function() c:Disconnect() end) end end
            if disable then pcall(function() disable:Fire() disable:Destroy() end) end
            table.clear(cfg)
            getgenv().configs = nil
        end
    end

    TabCombat:Toggle({
        Title    = "Ativar Kill Aura",
        Flag     = "KillAura",
        Value    = false,
        Callback = function(v)
            KA_ENABLED = v
            if v then startKillAura()
            else stopKillAura() end
        end
    })

    TabCombat:Slider({
        Title = "Tamanho do Aura",
        Flag  = "KillAuraSize",
        Step  = 1,
        Value = { Min = 1, Max = 200, Default = 10 },
        Callback = function(v)
            KA_SIZE = v
            if getgenv().configs then
                getgenv().configs.Size = Vector3.new(v, v, v)
            end
        end
    })

    TabCombat:Toggle({
        Title    = "Death Check (não atacar mortos)",
        Flag     = "KillAuraDeathCheck",
        Value    = true,
        Callback = function(v)
            KA_DEATHCHECK = v
            if getgenv().configs then
                getgenv().configs.DeathCheck = v
            end
        end
    })
end -- Kill Aura

TabCombat:Section({ Title = "Enemy Hitbox Extender" })

local HIT_RANGE_ENABLED  = false
local HIT_RANGE_SIZE     = 10
local HIT_RANGE_FILTER   = "Enemy"  -- "Enemy" | "My Team" | "All"
local ENEMY_CIRCLE_SHOW  = true
local ENEMY_CIRCLE_COLOR = Color3.fromRGB(255, 255, 255)
local ENEMY_ALPHA        = 0.5
local originalHRPData    = {}
local enemyCircles       = {}  -- [UserId] = { lines = {Line,...} }

local _SEGS = 4  -- quadrado = 4 vértices

-- Pré-calcula os 4 cantos do quadrado unitário no plano XZ
local _unitSquare = {
    { x =  1, z =  1 },
    { x = -1, z =  1 },
    { x = -1, z = -1 },
    { x =  1, z = -1 },
}

local function _makeRing(color)
    local lines = {}
    for i = 1, _SEGS do
        local l = Drawing.new("Line")
        l.Thickness    = 5
        l.Transparency = 0
        l.Color        = color
        l.Visible      = false
        lines[i]       = l
    end
    return lines
end

local function _hideRing(lines)
    for _, l in ipairs(lines) do l.Visible = false end
end

local function _removeRing(lines)
    for _, l in ipairs(lines) do pcall(function() l:Remove() end) end
end

local function _renderRing(lines, centerPos, radiusStuds, color, show, alpha)
    if not show then _hideRing(lines); return end
    local cam   = Camera
    local camCF = cam.CFrame
    local cx, cy, cz = centerPos.X, centerPos.Y, centerPos.Z
    local trans = 1 - (alpha or 1)
    local NEAR  = -0.1  -- plano near em camera space (Z negativo = frente)

    for i = 1, _SEGS do
        local n  = (i % _SEGS) + 1
        local u1 = _unitSquare[i]
        local u2 = _unitSquare[n]
        local p1 = Vector3.new(cx + u1.x * radiusStuds, cy, cz + u1.z * radiusStuds)
        local p2 = Vector3.new(cx + u2.x * radiusStuds, cy, cz + u2.z * radiusStuds)

        -- Converte para camera space (Z negativo = na frente)
        local c1 = camCF:PointToObjectSpace(p1)
        local c2 = camCF:PointToObjectSpace(p2)
        local in1 = c1.Z < NEAR
        local in2 = c2.Z < NEAR

        local from2, to2
        local l = lines[i]

        if not in1 and not in2 then
            -- Ambos atrás: esconde
            l.Visible = false
            continue
        elseif in1 and in2 then
            -- Ambos na frente: projeta normalmente
            local s1 = cam:WorldToViewportPoint(p1)
            local s2 = cam:WorldToViewportPoint(p2)
            from2 = Vector2.new(s1.X, s1.Y)
            to2   = Vector2.new(s2.X, s2.Y)
        else
            -- Um na frente, outro atrás: clippa no near plane
            local t    = (NEAR - c1.Z) / (c2.Z - c1.Z)
            local clip = p1 + t * (p2 - p1)
            local sc   = cam:WorldToViewportPoint(clip)
            if in1 then
                local s1 = cam:WorldToViewportPoint(p1)
                from2 = Vector2.new(s1.X, s1.Y)
                to2   = Vector2.new(sc.X,  sc.Y)
            else
                local s2 = cam:WorldToViewportPoint(p2)
                from2 = Vector2.new(sc.X,  sc.Y)
                to2   = Vector2.new(s2.X,  s2.Y)
            end
        end

        l.From         = from2
        l.To           = to2
        l.Color        = color
        l.Transparency = trans
        l.Visible      = true
    end
end

local function _removeEnemyCircle(uid)
    if enemyCircles[uid] then
        _removeRing(enemyCircles[uid])
        enemyCircles[uid] = nil
    end
end

local function extendHitboxes()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LP then continue end
        local uid = player.UserId
        if shouldShowPlayer(player, HIT_RANGE_FILTER) then
            -- Jogador passa no filtro: expande hitbox
            if player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp and hrp:IsA("BasePart") then
                    if not originalHRPData[uid] then
                        originalHRPData[uid] = {
                            Size         = hrp.Size,
                            Transparency = hrp.Transparency,
                            CanCollide   = hrp.CanCollide,
                        }
                    end
                    local origY = originalHRPData[uid].Size.Y
                    hrp.Size         = Vector3.new(HIT_RANGE_SIZE, origY, HIT_RANGE_SIZE)
                    hrp.Transparency = 1
                    hrp.CanCollide   = false
                    if not enemyCircles[uid] then
                        enemyCircles[uid] = _makeRing(ENEMY_CIRCLE_COLOR)
                    end
                end
            end
        else
            -- Jogador fora do filtro: restaura hitbox original e remove círculo
            if player.Character then
                local hrp  = player.Character:FindFirstChild("HumanoidRootPart")
                local data = originalHRPData[uid]
                if hrp and data then
                    hrp.Size         = data.Size
                    hrp.Transparency = data.Transparency
                    hrp.CanCollide   = data.CanCollide
                end
            end
            originalHRPData[uid] = nil
            _removeEnemyCircle(uid)
        end
    end
end

local function restoreHitboxes()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local hrp  = player.Character:FindFirstChild("HumanoidRootPart")
            local data = originalHRPData[player.UserId]
            if hrp and data then
                hrp.Size         = data.Size
                hrp.Transparency = data.Transparency
                hrp.CanCollide   = data.CanCollide
            end
        end
        _removeEnemyCircle(player.UserId)
    end
    originalHRPData = {}
end

Players.PlayerRemoving:Connect(function(player)
    originalHRPData[player.UserId] = nil
    _removeEnemyCircle(player.UserId)
end)

TabCombat:Toggle({
    Title    = "Ativar Enemy Hitbox Extender",
    Flag     = "HitRange",
    Value    = false,
    Callback = function(v)
        HIT_RANGE_ENABLED = v
        if v then extendHitboxes() else restoreHitboxes() end
    end
})

TabCombat:Dropdown({
    Title    = "Filtro de Time (Hitbox)",
    Flag     = "HitboxTeamFilter",
    Values   = {"Enemy", "My Team", "All"},
    Value    = "Enemy",
    Multi    = false,
    Callback = function(v)
        HIT_RANGE_FILTER = parseDropdownValue(v)
        if HIT_RANGE_ENABLED then extendHitboxes() end
    end,
})

TabCombat:Slider({
    Title = "Tamanho da Hitbox",
    Flag  = "HitboxSize",
    Step  = 1,
    Value = { Min = 5, Max = 300, Default = 10 },
    Callback = function(v)
        HIT_RANGE_SIZE = v
        if HIT_RANGE_ENABLED then extendHitboxes() end
    end
})

TabCombat:Toggle({
    Title    = "Mostrar Quadrado da Hitbox",
    Flag     = "EnemyCircleShow",
    Value    = true,
    Callback = function(v)
        ENEMY_CIRCLE_SHOW = v
        if not v then
            for _, lines in pairs(enemyCircles) do _hideRing(lines) end
        end
    end
})

TabCombat:Colorpicker({
    Title    = "Cor do Quadrado (Enemy)",
    Flag     = "EnemyCircleColor",
    Color    = Color3.fromRGB(255, 255, 255),
    Callback = function(col)
        ENEMY_CIRCLE_COLOR = col
        for _, lines in pairs(enemyCircles) do
            for _, l in ipairs(lines) do l.Color = col end
        end
    end
})

TabCombat:Slider({
    Title = "Transparência (Enemy)",
    Flag  = "EnemyAlpha",
    Step  = 0.05,
    Value = { Min = 0, Max = 1, Default = 0.5 },
    Callback = function(v)
        ENEMY_ALPHA = v
    end
})

local _lastHitboxUpdate = 0
RunService.RenderStepped:Connect(function()
    if not HIT_RANGE_ENABLED then
        for _, lines in pairs(enemyCircles) do _hideRing(lines) end
        return
    end
    local now = tick()
    if now - _lastHitboxUpdate >= 0.1 then
        _lastHitboxUpdate = now
        extendHitboxes()
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LP then continue end
        local lines = enemyCircles[player.UserId]
        if not lines then continue end
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then _hideRing(lines); continue end
        local origData = originalHRPData[player.UserId]
        _renderRing(lines, hrp.Position, HIT_RANGE_SIZE / 2, ENEMY_CIRCLE_COLOR, ENEMY_CIRCLE_SHOW, ENEMY_ALPHA)
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if HIT_RANGE_ENABLED then extendHitboxes() end
    end)
end)

-- ================== NPC HITBOX EXTENDER ==================
do
    local NPC_HIT_ENABLED  = false
    local NPC_HIT_SIZE     = 10
    local NPC_CIRCLE_SHOW  = true
    local NPC_CIRCLE_COLOR = Color3.fromRGB(255, 255, 255)
    local NPC_ALPHA        = 0.5
    local originalNPCData  = {}
    local npcCircles       = {}  -- [id] = { lines }

    local function _removeNPCCircle(id)
        if npcCircles[id] then
            _removeRing(npcCircles[id])
            npcCircles[id] = nil
        end
    end

    local function extendNPCHitboxes()
        local playerChars = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then playerChars[p.Character] = true end
        end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and not playerChars[obj] and obj:FindFirstChildWhichIsA("Humanoid") then
                local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
                if hrp and hrp:IsA("BasePart") then
                    local id = tostring(hrp)
                    if not originalNPCData[id] then
                        originalNPCData[id] = {
                            hrpRef       = hrp,
                            Size         = hrp.Size,
                            Transparency = hrp.Transparency,
                            CanCollide   = hrp.CanCollide,
                        }
                    end
                    local origY = originalNPCData[id].Size.Y
                    hrp.Size         = Vector3.new(NPC_HIT_SIZE, origY, NPC_HIT_SIZE)
                    hrp.Transparency = 1
                    hrp.CanCollide   = false
                    if not npcCircles[id] then
                        npcCircles[id] = _makeRing(NPC_CIRCLE_COLOR)
                    end
                end
            end
        end
    end

    local function restoreNPCHitboxes()
        for id, data in pairs(originalNPCData) do
            pcall(function()
                if data.hrpRef and data.hrpRef.Parent then
                    data.hrpRef.Size         = data.Size
                    data.hrpRef.Transparency = data.Transparency
                    data.hrpRef.CanCollide   = data.CanCollide
                end
            end)
            _removeNPCCircle(id)
        end
        originalNPCData = {}
    end

    TabCombat:Section({ Title = "NPC Hitbox Extender" })

    TabCombat:Toggle({
        Title    = "Ativar NPC Hitbox Extender",
        Flag     = "NPCHitRange",
        Value    = false,
        Callback = function(v)
            NPC_HIT_ENABLED = v
            if v then extendNPCHitboxes() else restoreNPCHitboxes() end
        end
    })

    TabCombat:Slider({
        Title = "Tamanho da Hitbox NPC",
        Flag  = "NPCHitboxSize",
        Step  = 1,
        Value = { Min = 5, Max = 300, Default = 10 },
        Callback = function(v)
            NPC_HIT_SIZE = v
            if NPC_HIT_ENABLED then extendNPCHitboxes() end
        end
    })

    TabCombat:Toggle({
        Title    = "Mostrar Quadrado da Hitbox",
        Flag     = "NPCCircleShow",
        Value    = true,
        Callback = function(v)
            NPC_CIRCLE_SHOW = v
            if not v then
                for _, lines in pairs(npcCircles) do _hideRing(lines) end
            end
        end
    })

    TabCombat:Colorpicker({
        Title    = "Cor do Quadrado (NPC)",
        Flag     = "NPCCircleColor",
        Color    = Color3.fromRGB(255, 255, 255),
        Callback = function(col)
            NPC_CIRCLE_COLOR = col
            for _, lines in pairs(npcCircles) do
                for _, l in ipairs(lines) do l.Color = col end
            end
        end
    })

    TabCombat:Slider({
        Title = "Transparência (NPC)",
        Flag  = "NPCAlpha",
        Step  = 0.05,
        Value = { Min = 0, Max = 1, Default = 0.5 },
        Callback = function(v) NPC_ALPHA = v end
    })

    local _lastNPCTick = 0
    RunService.RenderStepped:Connect(function()
        if not NPC_HIT_ENABLED then
            for _, lines in pairs(npcCircles) do _hideRing(lines) end
            return
        end
        local n = tick()
        if n - _lastNPCTick >= 0.1 then
            _lastNPCTick = n
            extendNPCHitboxes()
        end
        for id, data in pairs(originalNPCData) do
            local lines = npcCircles[id]
            if not lines then continue end
            local hrp = data.hrpRef
            if not hrp or not hrp.Parent then _hideRing(lines); continue end
            _renderRing(lines, hrp.Position, NPC_HIT_SIZE / 2, NPC_CIRCLE_COLOR, NPC_CIRCLE_SHOW, NPC_ALPHA)
        end
    end)
end

-- ================== PLAYER HITBOX EXTENDER (próprio jogador) ==================
do
    local PLAYER_HIT_ENABLED    = false
    local PLAYER_HIT_SIZE       = 10
    local PLAYER_CIRCLE_SHOW    = true
    local PLAYER_CIRCLE_COLOR   = Color3.fromRGB(255, 255, 255)
    local PLAYER_ALPHA          = 0.5
    local originalPlayerHRPData = nil
    local selfLines             = nil  -- table of Drawing.Line

    local function getLPHRP()
        return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    end

    local function _ensureSelfLines()
        if not selfLines then
            selfLines = _makeRing(PLAYER_CIRCLE_COLOR)
        end
    end

    local function expandMyHitbox()
        local hrp = getLPHRP()
        if not hrp then return end
        if not originalPlayerHRPData then
            originalPlayerHRPData = {
                Size         = hrp.Size,
                Transparency = hrp.Transparency,
                CanCollide   = hrp.CanCollide,
            }
        end
        local origY = originalPlayerHRPData.Size.Y
        hrp.Size         = Vector3.new(PLAYER_HIT_SIZE, origY, PLAYER_HIT_SIZE)
        hrp.Transparency = 1
        hrp.CanCollide   = false
        _ensureSelfLines()
    end

    local function restoreMyHitbox()
        local hrp = getLPHRP()
        if hrp and originalPlayerHRPData then
            pcall(function()
                hrp.Size         = originalPlayerHRPData.Size
                hrp.Transparency = originalPlayerHRPData.Transparency
                hrp.CanCollide   = originalPlayerHRPData.CanCollide
            end)
        end
        originalPlayerHRPData = nil
        if selfLines then _hideRing(selfLines) end
    end

    LP.CharacterAdded:Connect(function()
        originalPlayerHRPData = nil
        task.wait(0.5)
        if PLAYER_HIT_ENABLED then expandMyHitbox() end
    end)

    TabCombat:Section({ Title = "Player Hitbox Extender" })

    TabCombat:Toggle({
        Title    = "Ativar Player Hitbox Extender",
        Flag     = "PlayerHitRange",
        Value    = false,
        Callback = function(v)
            PLAYER_HIT_ENABLED = v
            if v then expandMyHitbox() else restoreMyHitbox() end
        end
    })

    TabCombat:Slider({
        Title = "Tamanho da Hitbox (meu jogador)",
        Flag  = "PlayerHitboxSize",
        Step  = 1,
        Value = { Min = 5, Max = 300, Default = 10 },
        Callback = function(v)
            PLAYER_HIT_SIZE = v
            if PLAYER_HIT_ENABLED then
                originalPlayerHRPData = nil
                expandMyHitbox()
            end
        end
    })

    TabCombat:Toggle({
        Title    = "Mostrar Quadrado da Hitbox",
        Flag     = "PlayerCircleShow",
        Value    = true,
        Callback = function(v)
            PLAYER_CIRCLE_SHOW = v
            if not v and selfLines then _hideRing(selfLines) end
        end
    })

    TabCombat:Colorpicker({
        Title    = "Cor do Quadrado (Player)",
        Flag     = "PlayerCircleColor",
        Color    = Color3.fromRGB(255, 255, 255),
        Callback = function(col)
            PLAYER_CIRCLE_COLOR = col
            if selfLines then
                for _, l in ipairs(selfLines) do l.Color = col end
            end
        end
    })

    TabCombat:Slider({
        Title = "Transparência (Player)",
        Flag  = "PlayerAlpha",
        Step  = 0.05,
        Value = { Min = 0, Max = 1, Default = 0.5 },
        Callback = function(v) PLAYER_ALPHA = v end
    })

    local _lastPHitTick = 0
    RunService.RenderStepped:Connect(function()
        if not PLAYER_HIT_ENABLED then
            if selfLines then _hideRing(selfLines) end
            return
        end
        local n = tick()
        if n - _lastPHitTick >= 0.1 then
            _lastPHitTick = n
            expandMyHitbox()
        end
        if selfLines then
            local hrp = getLPHRP()
            if hrp and originalPlayerHRPData then
                _renderRing(selfLines, hrp.Position, PLAYER_HIT_SIZE / 2, PLAYER_CIRCLE_COLOR, PLAYER_CIRCLE_SHOW, PLAYER_ALPHA)
            else
                _hideRing(selfLines)
            end
        end
    end)
end

TabCombat:Section({ Title = "Auto Press" })

local AUTO_PRESS_ENABLED  = false
local AUTO_PRESS_INTERVAL = 0.25
local promptAtual         = nil

ProximityPromptService.PromptShown:Connect(function(p)  promptAtual = p end)
ProximityPromptService.PromptHidden:Connect(function(p) if promptAtual == p then promptAtual = nil end end)

TabCombat:Toggle({
    Title = "Ativar Auto Press",
    Flag     = "AutoPress",
    Value = false,
    Callback = function(v) AUTO_PRESS_ENABLED = v end
})

TabCombat:Slider({
    Title = "Intervalo (segundos)",
    Flag     = "AutoPressInterval",
    Step  = 0.05,
    Value = { Min = 0.1, Max = 2, Default = 0.25 },
    Callback = function(v) AUTO_PRESS_INTERVAL = v end
})

task.spawn(function()
    while true do
        if AUTO_PRESS_ENABLED and promptAtual and promptAtual.Enabled then
            pcall(function() fireproximityprompt(promptAtual, promptAtual.HoldDuration or 0) end)
        end
        task.wait(AUTO_PRESS_INTERVAL)
    end
end)

-- ==================================================================================
-- ============================== ESP TAB ===========================================
-- ==================================================================================

local ESP_ENABLED        = false
local NAME_ENABLED       = true
local DISTANCE_ENABLED   = true
local LINE_ENABLED       = true
local HEALTH_ENABLED     = true
local OUTLINE_ENABLED    = true
local ESP_COLOR          = Color3.fromRGB(255, 255, 255)
local LINE_COLOR         = Color3.fromRGB(255, 255, 255)
local ESP_OBJECTS        = {}
local ESP_TEAM_FILTER    = "All"

local function removeESP(player)
    local espData = ESP_OBJECTS[player]
    if not espData then return end
    espData.active = false
    if espData.billboard then pcall(function() espData.billboard:Destroy() end) end
    if espData.line      then pcall(function() espData.line:Remove()      end) end
    if espData.outline   then
        for _, l in ipairs(espData.outline) do pcall(function() l:Remove() end) end
    end
    if espData.connections then
        for _, conn in ipairs(espData.connections) do pcall(function() conn:Disconnect() end) end
    end
    ESP_OBJECTS[player] = nil
end

local function createESP(player)
    if player == LP then return end
    if not shouldShowPlayer(player, ESP_TEAM_FILTER) then removeESP(player) return end
    if ESP_OBJECTS[player] then removeESP(player) end

    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    local espData = { active = true, player = player, character = char }

    if NAME_ENABLED or DISTANCE_ENABLED or HEALTH_ENABLED then
        local billboard = Instance.new("BillboardGui")
        billboard.Adornee    = hrp
        billboard.Size       = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = 2000
        local txt = Instance.new("TextLabel")
        txt.Size                 = UDim2.new(1,0,1,0)
        txt.BackgroundTransparency = 1
        txt.TextColor3           = ESP_COLOR
        txt.TextStrokeTransparency = 0
        txt.TextStrokeColor3     = Color3.new(0,0,0)
        txt.TextSize             = 16
        txt.Font                 = Enum.Font.SourceSansBold
        txt.Parent               = billboard
        billboard.Parent         = hrp
        espData.billboard        = billboard
        espData.txt              = txt
    end

    if LINE_ENABLED then
        local line        = Drawing.new("Line")
        line.Color        = LINE_COLOR
        line.Thickness    = 2
        line.Transparency = 1
        line.Visible      = false
        espData.line      = line
    end

    if OUTLINE_ENABLED then
        espData.outline = {}
        for i = 1, 4 do
            local l        = Drawing.new("Line")
            l.Color        = ESP_COLOR
            l.Thickness    = 2
            l.Transparency = 1
            l.Visible      = false
            table.insert(espData.outline, l)
        end
    end

    ESP_OBJECTS[player] = espData

    local connections = {}
    table.insert(connections, hum.Died:Connect(function()
        task.wait(0.1); removeESP(player)
    end))
    table.insert(connections, char.AncestryChanged:Connect(function(_, parent)
        if not parent then removeESP(player) end
    end))
    espData.connections = connections
end

local function clearAllESP()
    for player, _ in pairs(ESP_OBJECTS) do removeESP(player) end
    ESP_OBJECTS = {}
end

local function refreshESP()
    clearAllESP()
    if ESP_ENABLED then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then createESP(p) end
        end
    end
end

-- ESP render loop
local lastESPUpdate = 0
-- Variáveis reutilizáveis para evitar alocações de Vector2 a cada frame
local _espScreenPos = Vector2.new(0, 0)
local _espViewCenter = Vector2.new(0, 0)
RunService.RenderStepped:Connect(function()
    local now = tick()
    if now - lastESPUpdate < 1/60 then return end
    lastESPUpdate = now

    if not ESP_ENABLED or not HRP then
        for _, espData in pairs(ESP_OBJECTS) do
            if espData.line then espData.line.Visible = false end
            if espData.outline then for _, l in ipairs(espData.outline) do l.Visible = false end end
        end
        return
    end

    local cam = Camera
    local viewportSize   = cam.ViewportSize
    _espViewCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y)

    for player, espData in pairs(ESP_OBJECTS) do
        if not espData.active then continue end
        if not player or not Players:FindFirstChild(player.Name) then removeESP(player) continue end
        if not shouldShowPlayer(player, ESP_TEAM_FILTER) then removeESP(player) continue end

        local char = player.Character
        if not char or char ~= espData.character then removeESP(player) continue end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then
            if espData.line then espData.line.Visible = false end
            if espData.outline then for _, l in ipairs(espData.outline) do l.Visible = false end end
            continue
        end

        local hrpPos     = hrp.Position
        local distance   = (hrpPos - HRP.Position).Magnitude
        local sp, onScreen = cam:WorldToViewportPoint(hrpPos)

        -- Atualiza cor do ESP em tempo real
        if espData.txt     then espData.txt.TextColor3 = ESP_COLOR end
        if espData.outline then for _, l in ipairs(espData.outline) do l.Color = ESP_COLOR end end
        if espData.line    then espData.line.Color = LINE_COLOR end

        if espData.txt then
            local parts = {}
            if NAME_ENABLED     then table.insert(parts, player.Name) end
            if DISTANCE_ENABLED then table.insert(parts, string.format("[%dm]", math.floor(distance))) end
            if HEALTH_ENABLED   then table.insert(parts, string.format("HP:%d", math.floor(hum.Health))) end
            espData.txt.Text = table.concat(parts, " | ")
        end

        if espData.line and LINE_ENABLED then
            if onScreen and sp.Z > 0 then
                _espScreenPos = Vector2.new(sp.X, sp.Y)
                espData.line.From    = _espViewCenter
                espData.line.To      = _espScreenPos
                espData.line.Visible = true
            else
                espData.line.Visible = false
            end
        elseif espData.line then
            espData.line.Visible = false
        end

        if espData.outline and OUTLINE_ENABLED and onScreen and sp.Z > 0 then
            local height, width = 2.5, 1.5
            local rightVector   = cam.CFrame.RightVector
            local corners = {
                hrpPos + rightVector * width + Vector3.new(0,  height, 0),
                hrpPos - rightVector * width + Vector3.new(0,  height, 0),
                hrpPos - rightVector * width + Vector3.new(0, -height, 0),
                hrpPos + rightVector * width + Vector3.new(0, -height, 0),
            }
            local screenCorners, allVisible = {}, true
            for i, corner in ipairs(corners) do
                local pos, visible = cam:WorldToViewportPoint(corner)
                if not visible or pos.Z <= 0 then allVisible = false break end
                screenCorners[i] = Vector2.new(pos.X, pos.Y)
            end
            if allVisible then
                for i = 1, 4 do
                    local ni = (i % 4) + 1
                    espData.outline[i].From    = screenCorners[i]
                    espData.outline[i].To      = screenCorners[ni]
                    espData.outline[i].Visible = true
                end
            else
                for _, l in ipairs(espData.outline) do l.Visible = false end
            end
        elseif espData.outline then
            for _, l in ipairs(espData.outline) do l.Visible = false end
        end
    end
end)

-- Init ESP hooks
local function hookPlayerForESP(player)
    player.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart", 5)
        task.wait(0.5)
        if ESP_ENABLED then createESP(player) end
    end)
    if player.Character and ESP_ENABLED then createESP(player) end
end

for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then hookPlayerForESP(p) end end
Players.PlayerAdded:Connect(hookPlayerForESP)
Players.PlayerRemoving:Connect(removeESP)

-- ---- ESP UI ----
TabESP:Section({ Title = "ESP Settings" })

TabESP:Toggle({
    Title = "Ativar ESP",
    Flag     = "ESPEnabled",
    Value = false,
    Callback = function(v) ESP_ENABLED = v refreshESP() end
})

-- Pre-definição das opções (evita dropdown vazio no WindUI)
TabESP:Dropdown({
    Title   = "Filtro de Time",
    Values  = { "All", "My Team", "Enemy Team" },
    Flag     = "ESPTeamFilter",
    Multi   = false,
    Default = 1,   -- "All"
    Callback = function(opt)
        ESP_TEAM_FILTER = parseDropdownValue(opt)
        refreshESP()
    end
})

TabESP:Section({ Title = "Componentes do ESP" })

TabESP:Toggle({ Title = "Nome",            Flag = "ESPName",     Value = true, Callback = function(v) NAME_ENABLED     = v end })
TabESP:Toggle({ Title = "Distância",       Flag = "ESPDistance", Value = true, Callback = function(v) DISTANCE_ENABLED = v end })
TabESP:Toggle({ Title = "Vida",            Flag = "ESPHealth",   Value = true, Callback = function(v) HEALTH_ENABLED   = v end })
TabESP:Toggle({ Title = "Linha Única",     Flag = "ESPLine",     Value = true, Callback = function(v) LINE_ENABLED     = v end })
TabESP:Toggle({ Title = "Contorno 4 Linhas", Flag = "ESPOutline", Value = true, Callback = function(v) OUTLINE_ENABLED = v end })

TabESP:Section({ Title = "Cores" })

TabESP:Colorpicker({
    Title = "Cor do ESP",
    Flag     = "ESPColor",
    Color = Color3.fromRGB(255, 0, 0),
    Callback = function(color)
        ESP_COLOR = color
    end
})

TabESP:Colorpicker({
    Title = "Cor da Linha",
    Flag     = "ESPLineColor",
    Color = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        LINE_COLOR = color
    end
})

-- ==================================================================================
-- ============================== HIGHLIGHT TAB =====================================
-- ==================================================================================

local HIGHLIGHT_ENABLED     = false
local HIGHLIGHT_TEAM_FILTER = "All"
local teamColor             = Color3.fromRGB(255, 255, 255)
local enemyColor            = Color3.fromRGB(255, 255, 255)
local highlightFillTrans    = 0.5
local highlightOutlineTrans = 0
local highlightDepthMode    = Enum.HighlightDepthMode.AlwaysOnTop
local highlightCache        = {}

local function addHighlight(player)
    if player == LP then return end
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
    highlight.Adornee            = char
    highlight.DepthMode          = highlightDepthMode
    local myTeam    = getPlayerTeam(LP)
    local theirTeam = getPlayerTeam(player)
    local color     = (myTeam and theirTeam and myTeam == theirTeam) and teamColor or enemyColor
    highlight.FillColor          = color
    highlight.OutlineColor       = color
    highlight.FillTransparency   = highlightFillTrans
    highlight.OutlineTransparency = highlightOutlineTrans
    highlight.Parent             = hrp
    highlightCache[player]       = highlight

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
    for _, h in pairs(highlightCache) do pcall(function() h:Destroy() end) end
    highlightCache = {}
end

local function updateAllHighlights()
    removeAllHighlights()
    if HIGHLIGHT_ENABLED then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LP and player.Character then addHighlight(player) end
        end
    end
end

-- Hooks de highlight para novos jogadores
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then
        p.CharacterAdded:Connect(function(char)
            char:WaitForChild("HumanoidRootPart", 5) task.wait(0.3)
            if HIGHLIGHT_ENABLED then addHighlight(p) end
        end)
    end
end
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart", 5) task.wait(0.3)
        if HIGHLIGHT_ENABLED then addHighlight(player) end
    end)
end)
Players.PlayerRemoving:Connect(removeHighlight)

-- Check periódico do highlight (time filter)
local lastHighlightCheck = 0
RunService.RenderStepped:Connect(function()
    if not HIGHLIGHT_ENABLED then return end
    local now = tick()
    if now - lastHighlightCheck < 2 then return end
    lastHighlightCheck = now
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if shouldShowPlayer(player, HIGHLIGHT_TEAM_FILTER) and hum and hum.Health > 0 then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp and not highlightCache[player] then addHighlight(player) end
            else
                removeHighlight(player)
            end
        end
    end
end)

-- ---- HIGHLIGHT UI ----
TabHighlight:Section({ Title = "Highlight ESP" })

TabHighlight:Toggle({
    Title = "Ativar Highlight ESP",
    Flag     = "HighlightEnabled",
    Value = false,
    Callback = function(v) HIGHLIGHT_ENABLED = v updateAllHighlights() end
})

TabHighlight:Dropdown({
    Title   = "Filtro de Time",
    Values  = { "All", "My Team", "Enemy Team" },
    Flag     = "HighlightTeamFilter",
    Multi   = false,
    Default = 1,   -- "All"
    Callback = function(opt)
        HIGHLIGHT_TEAM_FILTER = parseDropdownValue(opt)
        updateAllHighlights()
    end
})

TabHighlight:Section({ Title = "Cores" })

TabHighlight:Colorpicker({
    Title = "Cor do Time",
    Flag     = "HighlightTeamColor",
    Color = Color3.fromRGB(0, 255, 0),
    Callback = function(color) teamColor = color updateAllHighlights() end
})

TabHighlight:Colorpicker({
    Title = "Cor dos Inimigos",
    Flag     = "HighlightEnemyColor",
    Color = Color3.fromRGB(255, 0, 0),
    Callback = function(color) enemyColor = color updateAllHighlights() end
})

TabHighlight:Section({ Title = "Configurações" })

TabHighlight:Slider({
    Title = "Transparência do Preenchimento",
    Flag     = "HighlightFillTrans",
    Step  = 0.05,
    Value = { Min = 0, Max = 1, Default = 0.5 },
    Callback = function(v)
        highlightFillTrans = v
        for _, h in pairs(highlightCache) do if h then h.FillTransparency = v end end
    end
})

TabHighlight:Slider({
    Title = "Transparência do Contorno",
    Flag     = "HighlightOutlineTrans",
    Step  = 0.05,
    Value = { Min = 0, Max = 1, Default = 0 },
    Callback = function(v)
        highlightOutlineTrans = v
        for _, h in pairs(highlightCache) do if h then h.OutlineTransparency = v end end
    end
})

TabHighlight:Dropdown({
    Title   = "Modo de Profundidade",
    Flag     = "HighlightDepthMode",
    Values  = { "AlwaysOnTop", "Occluded" },
    Multi   = false,
    Default = 1,   -- "AlwaysOnTop"
    Callback = function(opt)
        local o = parseDropdownValue(opt)
        highlightDepthMode = o == "Occluded"
            and Enum.HighlightDepthMode.Occluded
            or  Enum.HighlightDepthMode.AlwaysOnTop
        for _, h in pairs(highlightCache) do if h then h.DepthMode = highlightDepthMode end end
    end
})

TabHighlight:Button({
    Title = "Atualizar Highlights",
    Callback = function()
        updateAllHighlights()
        WindUI:Notify({ Title = "Highlights", Content = "Atualizado!", Duration = 2 })
    end
})

-- ==================================================================================
-- ============================== AIM ASSIST TAB ====================================
-- ==================================================================================

local AIM_ENABLED     = false
local AIM_FOV         = 100
local AIM_SMOOTH      = 0.2
local AIM_TARGET_PART = "Head"
local AIM_WALLCHECK   = true
local AIM_TEAM_FILTER = "Enemy Team"
local currentTarget   = nil

local _aimRayParams = RaycastParams.new()
_aimRayParams.FilterType = Enum.RaycastFilterType.Blacklist

local function isVisible(targetPart)
    if not targetPart or not HRP then return false end
    _aimRayParams.FilterDescendantsInstances = { Character, targetPart.Parent }
    local ray = workspace:Raycast(Camera.CFrame.Position, targetPart.Position - Camera.CFrame.Position, _aimRayParams)
    return ray == nil
end

local function getTargetPart(character, partName)
    if not character then return nil end
    return character:FindFirstChild(partName)
        or character:FindFirstChild("HumanoidRootPart")
end

TabAim:Section({ Title = "Aim Assist" })

TabAim:Toggle({
    Title = "Ativar Aim Assist",
    Flag     = "AimEnabled",
    Value = false,
    Callback = function(v)
        AIM_ENABLED = v
        currentTarget = nil
        if v then WindUI:Notify({ Title = "Aim Assist", Content = "Ativado — mirando inimigos", Duration = 2 }) end
    end
})

TabAim:Dropdown({
    Title   = "Filtro de Time",
    Values  = { "All", "My Team", "Enemy Team" },
    Flag     = "AimTeamFilter",
    Multi   = false,
    Default = 3,   -- "Enemy Team"
    Callback = function(opt)
        AIM_TEAM_FILTER = parseDropdownValue(opt)
        currentTarget = nil
    end
})

TabAim:Section({ Title = "Configurações" })

TabAim:Toggle({ Title = "Wallcheck (não atirar por paredes)", Flag = "AimWallcheck", Value = true,
    Callback = function(v) AIM_WALLCHECK = v currentTarget = nil end })

TabAim:Slider({
    Title = "FOV (Campo de Visão)",
    Flag     = "AimFOV",
    Step  = 10,
    Value = { Min = 10, Max = 800, Default = 100 },
    Callback = function(v) AIM_FOV = v end
})

TabAim:Slider({
    Title = "Suavidade",
    Step  = 0.05,
    Flag     = "AimSmooth",
    Value = { Min = 0.05, Max = 1, Default = 0.2 },
    Callback = function(v) AIM_SMOOTH = v end
})

TabAim:Dropdown({
    Title   = "Parte do Corpo",
    Values  = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso" },
    Flag     = "AimPart",
    Multi   = false,
    Default = 1,   -- "Head"
    Callback = function(opt)
        AIM_TARGET_PART = parseDropdownValue(opt)
        if AIM_TARGET_PART == "" then AIM_TARGET_PART = "Head" end
        currentTarget = nil
    end
})

TabAim:Button({
    Title = "Resetar Alvo",
    Callback = function()
        currentTarget = nil
        WindUI:Notify({ Title = "Aim Assist", Content = "Alvo resetado!", Duration = 1.5 })
    end
})

local lastTargetCheck = 0
-- Aim Assist loop (target selection + camera steering em um único RenderStepped)
RunService.RenderStepped:Connect(function()
    if not AIM_ENABLED or not HRP or not Character then return end

    -- Seleciona alvo a cada 0.05s
    local now = tick()
    if now - lastTargetCheck >= 0.05 then
        lastTargetCheck = now
        local closestTarget, closestDistance = nil, AIM_FOV
        local viewportSize = Camera.ViewportSize
        local screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
        local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
        local aimPoint = isMobile and screenCenter or UserInputService:GetMouseLocation()

        for _, player in ipairs(Players:GetPlayers()) do
            if player == LP then continue end
            if not shouldShowPlayer(player, AIM_TEAM_FILTER) then continue end
            local char = player.Character
            if not char then continue end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then continue end
            local targetPart = getTargetPart(char, AIM_TARGET_PART)
            if not targetPart then continue end
            if AIM_WALLCHECK and not isVisible(targetPart) then continue end
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            if not onScreen or screenPos.Z <= 0 then continue end
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - aimPoint).Magnitude
            if dist < closestDistance then closestDistance = dist; closestTarget = targetPart end
        end

        if closestTarget and closestTarget.Parent then
            local th = closestTarget.Parent:FindFirstChildOfClass("Humanoid")
            currentTarget = (th and th.Health > 0) and closestTarget or nil
        else
            currentTarget = nil
        end
    end

    -- Aplica câmera em todo frame
    if currentTarget and currentTarget.Parent then
        local th = currentTarget.Parent:FindFirstChildOfClass("Humanoid")
        if not th or th.Health <= 0 then currentTarget = nil; return end
        local camPos = Camera.CFrame.Position
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(camPos, currentTarget.Position), AIM_SMOOTH)
    end
end)

-- ==================================================================================
-- ============================== PLAYER AIM TAB ====================================
-- ==================================================================================

local PlayerAimEnabled    = false
local PlayerAimSmoothness = 0.15
local PlayerAimPart       = "Head"
local PlayerAimFOVRadius  = 100
local PlayerAimPrediction = 0
local PlayerAimWallCheck  = true
local TargetPlayerName    = nil

local function UpdatePlayerAimList()
    local list = { "-- Nenhum --" }
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP then table.insert(list, player.Name) end
    end
    return list
end

local function GetTargetPlayer()
    if not TargetPlayerName or TargetPlayerName == "" or TargetPlayerName == "-- Nenhum --" then return nil end
    return Players:FindFirstChild(tostring(TargetPlayerName))
end

local function IsPlayerAimValid(player)
    return player and player ~= LP and player.Character
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
    local cam = workspace.CurrentCamera
    local pos, onScreen = cam:WorldToViewportPoint(part.Position)
    if not onScreen then return false end
    -- Mobile usa centro da tela, PC usa mouse
    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    local refPoint = isMobile
        and Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
        or  UserInputService:GetMouseLocation()
    return (refPoint - Vector2.new(pos.X, pos.Y)).Magnitude <= PlayerAimFOVRadius
end

local _wallRayParams = RaycastParams.new()
_wallRayParams.FilterType = Enum.RaycastFilterType.Exclude

local function CheckPlayerAimWall(part)
    if not PlayerAimWallCheck then return true end
    local cam    = workspace.CurrentCamera
    local origin = cam.CFrame.Position
    _wallRayParams.FilterDescendantsInstances = { LP.Character, part.Parent }
    local result = workspace:Raycast(origin, part.Position - origin, _wallRayParams)
    return not result or result.Instance:IsDescendantOf(part.Parent)
end

local function GetPartVelocity(part)
    if part.AssemblyLinearVelocity then return part.AssemblyLinearVelocity
    elseif part.Velocity            then return part.Velocity
    else return Vector3.new(0,0,0) end
end

-- Flag para suprimir notificações durante o auto-refresh da lista
local _isRefreshingAimList = false

local PlayerAimDropdown = TabPlayerAim:Dropdown({
    Title   = "Escolher Jogador Alvo",
    Values  = UpdatePlayerAimList(),
    Multi   = false,
    Default = 1,   -- "-- Nenhum --"
    Callback = function(option)
        -- Ignora callbacks disparados pelo Refresh automático
        if _isRefreshingAimList then return end
        local val = parseDropdownValue(option)
        if val == "-- Nenhum --" or val == "" then
            TargetPlayerName = nil
            PlayerAimEnabled = false
            WindUI:Notify({ Title = "Player Aim", Content = "Alvo removido.", Duration = 1.5 })
        else
            TargetPlayerName = val
            WindUI:Notify({ Title = "Alvo Selecionado", Content = val, Duration = 2 })
        end
    end
})

TabPlayerAim:Button({
    Title = "Atualizar Lista de Jogadores",
    Callback = function()
        _isRefreshingAimList = true
        local list = UpdatePlayerAimList()
        pcall(function() PlayerAimDropdown:Refresh(list) end)
        _isRefreshingAimList = false
        WindUI:Notify({ Title = "Lista Atualizada", Content = (# list - 1) .. " jogadores", Duration = 2 })
    end
})

TabPlayerAim:Section({ Title = "Controle" })

TabPlayerAim:Toggle({
    Title = "Ativar Aim no Jogador",
    Flag     = "PlayerAimEnabled",
    Value = false,
    Callback = function(v)
        if v and not TargetPlayerName then
            WindUI:Notify({ Title = "Aviso", Content = "Selecione um jogador primeiro!", Duration = 2 })
            PlayerAimEnabled = false
            return
        end
        PlayerAimEnabled = v
        -- Notifica apenas ao ativar via toggle (o keybind T já exibe a própria notificação)
        if v then
            WindUI:Notify({
                Title   = "Aim Ativado",
                Content = "Mirando em: " .. tostring(TargetPlayerName),
                Duration = 2
            })
        end
    end
})

TabPlayerAim:Section({ Title = "Configurações" })

TabPlayerAim:Slider({
    Title = "FOV (Campo de Visão)",
    Flag     = "PlayerAimFOV",
    Step  = 10,
    Value = { Min = 10, Max = 800, Default = 100 },
    Callback = function(v) PlayerAimFOVRadius = v end
})

TabPlayerAim:Slider({
    Title = "Suavidade",
    Step  = 0.01,
    Flag     = "PlayerAimSmooth",
    Value = { Min = 0.01, Max = 1, Default = 0.15 },
    Callback = function(v) PlayerAimSmoothness = v end
})

TabPlayerAim:Dropdown({
    Title   = "Parte do Corpo",
    Values  = { "Head", "Torso", "HumanoidRootPart" },
    Flag     = "PlayerAimPart",
    Multi   = false,
    Default = 1,   -- "Head"
    Callback = function(v)
        local val = parseDropdownValue(v)
        PlayerAimPart = (val ~= "") and val or "Head"
    end
})

TabPlayerAim:Slider({
    Title = "Predição de Movimento",
    Flag     = "PlayerAimPrediction",
    Step  = 0.01,
    Value = { Min = 0, Max = 0.5, Default = 0 },
    Callback = function(v) PlayerAimPrediction = v end
})

TabPlayerAim:Toggle({
    Title = "WallCheck (não mirar por paredes)",
    Flag     = "PlayerAimWallCheck",
    Value = true,
    Callback = function(v) PlayerAimWallCheck = v end
})

-- Player Aim loop
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
            targetPos = targetPos + GetPartVelocity(part) * PlayerAimPrediction
        end
        local cam    = workspace.CurrentCamera
        local lookAt = CFrame.new(cam.CFrame.Position, targetPos)
        cam.CFrame   = cam.CFrame:Lerp(lookAt, PlayerAimSmoothness)
    end)
end)

-- Auto-refresh da lista a cada 5s (silencioso – não dispara callback)
task.spawn(function()
    while task.wait(5) do
        pcall(function()
            _isRefreshingAimList = true
            PlayerAimDropdown:Refresh(UpdatePlayerAimList())
            _isRefreshingAimList = false
        end)
    end
end)

-- ==================================================================================
-- ============================== PROTECTION TAB ====================================
-- ==================================================================================

local godMode, lockHP, antiKB, antiVoid = false, false, false, false
local noclip = false  -- definido aqui, usado no runtime e no Utility Tab

-- Cache de partes do personagem para o noclip (evita GetDescendants() todo frame)
local _charPartsCache = {}
local function _rebuildCharCache(char)
    _charPartsCache = {}
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then table.insert(_charPartsCache, p) end
    end
    char.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") then table.insert(_charPartsCache, d) end
    end)
end
if LP.Character then _rebuildCharCache(LP.Character) end
LP.CharacterAdded:Connect(_rebuildCharCache)

TabProt:Section({ Title = "Proteções" })

TabProt:Toggle({ Title = "God Mode",         Flag = "GodMode",  Value = false, Callback = function(v) godMode  = v end })
TabProt:Toggle({ Title = "Lock HP",          Flag = "LockHP",   Value = false, Callback = function(v) lockHP   = v end })
TabProt:Toggle({ Title = "Anti Knockback",   Flag = "AntiKB",   Value = false, Callback = function(v) antiKB   = v end })
TabProt:Toggle({ Title = "Anti Void",        Flag = "AntiVoid", Value = false, Callback = function(v) antiVoid = v end })

-- ==================================================================================
-- ============================== PLAYERS TAB =======================================
-- ==================================================================================

TabPlayers:Section({ Title = "Teleporte e Spectate" })

do -- Players Tab
    local selectedName = nil

    local function getPlayerNames()
        local t = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then table.insert(t, p.Name) end
        end
        return t
    end

    local playerDropdown = TabPlayers:Dropdown({
        Title   = "Selecionar Player",
        Values  = getPlayerNames(),
        Multi   = false,
        Default = 1,
        Callback = function(v) selectedName = parseDropdownValue(v) end
    })

    TabPlayers:Button({
        Title = "Atualizar Lista",
        Callback = function() playerDropdown:Refresh(getPlayerNames()) end
    })

    TabPlayers:Button({
        Title = "TP para Player",
        Callback = function()
            local t = Players:FindFirstChild(selectedName)
            if t and t.Character and HRP then
                HRP.CFrame = t.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
            end
        end
    })

    TabPlayers:Button({
        Title = "Spectate",
        Callback = function()
            local t = Players:FindFirstChild(selectedName)
            if t and t.Character then
                Camera.CameraSubject = t.Character:FindFirstChildOfClass("Humanoid")
            end
        end
    })

    TabPlayers:Button({
        Title = "Voltar Camera",
        Callback = function() Camera.CameraSubject = Humanoid end
    })
end -- Players Tab

-- ==================================================================================
-- ============================== WAYPOINTS TAB =====================================
-- ==================================================================================

TabWaypoints:Section({ Title = "Sistema de Waypoints" })

do -- Waypoints Tab
    local savedWaypoints   = {}
    local waypointSelected = nil
    local waypointNameInput = ""

    local function resolvePosition(pos)
        if type(pos) == "userdata" then return pos end
        if type(pos) == "table" then return Vector3.new(pos.X or 0, pos.Y or 0, pos.Z or 0) end
        return nil
    end

    local function getWaypointList()
        local list = {}
        for name, _ in pairs(savedWaypoints) do table.insert(list, name) end
        table.sort(list)
        return #list > 0 and list or { "Nenhum waypoint salvo" }
    end

    TabWaypoints:Input({
        Title       = "Nome do Waypoint",
        Placeholder = "Digite o nome...",
        Callback    = function(text) waypointNameInput = text end
    })

    local waypointDropdown = TabWaypoints:Dropdown({
        Title   = "Selecionar Waypoint",
        Values  = getWaypointList(),
        Multi   = false,
        Default = 1,
        Callback = function(opt)
            waypointSelected = parseDropdownValue(opt)
        end
    })

    TabWaypoints:Button({
        Title = "Salvar Posição Atual",
        Callback = function()
            if not waypointNameInput or waypointNameInput == "" then
                WindUI:Notify({ Title = "Erro", Content = "Digite um nome para o waypoint!", Duration = 3 })
                return
            end
            if not HRP then return end
            local pos = HRP.CFrame.Position
            savedWaypoints[waypointNameInput] = { Position = { X = pos.X, Y = pos.Y, Z = pos.Z }, Time = os.date("%H:%M:%S") }
            waypointDropdown:Refresh(getWaypointList())
            WindUI:Notify({ Title = "Waypoint Salvo", Content = "'" .. waypointNameInput .. "' salvo!", Duration = 3 })
        end
    })

    TabWaypoints:Button({
        Title = "Teleportar para Waypoint",
        Callback = function()
            local name = type(waypointSelected) == "table" and waypointSelected[1] or tostring(waypointSelected or "")
            if not name or name == "" or name == "Nenhum waypoint salvo" then
                WindUI:Notify({ Title = "Erro", Content = "Selecione um waypoint válido!", Duration = 3 })
                return
            end
            local wpData = savedWaypoints[name]
            if not wpData or not HRP then WindUI:Notify({ Title = "Erro", Content = "Waypoint inválido!", Duration = 3 }) return end
            local pos = resolvePosition(wpData.Position)
            if pos then
                HRP.CFrame = CFrame.new(pos)
                WindUI:Notify({ Title = "Teleportado", Content = "Chegou em '" .. name .. "'!", Duration = 2 })
            end
        end
    })

    TabWaypoints:Button({
        Title = "Deletar Waypoint",
        Callback = function()
            local name = type(waypointSelected) == "table" and waypointSelected[1] or tostring(waypointSelected or "")
            if not name or name == "Nenhum waypoint salvo" then return end
            savedWaypoints[name] = nil
            waypointSelected     = nil
            waypointDropdown:Refresh(getWaypointList())
            WindUI:Notify({ Title = "Deletado", Content = "Waypoint removido!", Duration = 2 })
        end
    })

    TabWaypoints:Button({
        Title = "Atualizar Lista",
        Callback = function() waypointDropdown:Refresh(getWaypointList()) end
    })

    TabWaypoints:Section({ Title = "Teleporte Rápido" })

    TabWaypoints:Button({
        Title = "TP para Spawn",
        Callback = function()
            if not HRP then return end
            local spawnLocation = workspace:FindFirstChildOfClass("SpawnLocation") or workspace:FindFirstChild("Spawn")
            if not spawnLocation then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("SpawnLocation") then spawnLocation = obj break end
                end
            end
            if spawnLocation then
                HRP.CFrame = spawnLocation.CFrame + Vector3.new(0, 5, 0)
                WindUI:Notify({ Title = "Teleportado", Content = "Chegou no Spawn!", Duration = 2 })
            else
                HRP.CFrame = CFrame.new(0, 5, 0)
                WindUI:Notify({ Title = "Aviso", Content = "Spawn não encontrado. Foi para (0,5,0)", Duration = 3 })
            end
        end
    })
end -- Waypoints Tab

-- ==================================================================================
-- ============================== VISUALS TAB =======================================
-- ==================================================================================

TabVisuals:Section({ Title = "Campo de Visão" })

local DEFAULT_FOV = Camera.FieldOfView

TabVisuals:Slider({
    Title = "FOV",
    Step  = 1,
    Flag     = "CameraFOV",
    Value = { Min = 70, Max = 180, Default = DEFAULT_FOV },
    Callback = function(v) Camera.FieldOfView = v end
})

TabVisuals:Button({
    Title = "Resetar FOV",
    Callback = function() Camera.FieldOfView = DEFAULT_FOV end
})

TabVisuals:Section({ Title = "Iluminação" })

local FULLBRIGHT_ENABLED = false

local function toggleFullbright(enabled)
    if enabled then
        Lighting.Brightness    = 2
        Lighting.ClockTime     = 14
        Lighting.FogEnd        = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    else
        Lighting.Brightness    = 1
        Lighting.GlobalShadows = true
    end
end

TabVisuals:Toggle({
    Title = "Fullbright",
    Flag     = "Fullbright",
    Value = false,
    Callback = function(v) FULLBRIGHT_ENABLED = v toggleFullbright(v) end
})

TabVisuals:Section({ Title = "Câmera" })

local NO_CAMERA_SHAKE = false

TabVisuals:Toggle({
    Title = "No Camera Shake",
    Flag     = "NoCamShake",
    Value = false,
    Callback = function(v) NO_CAMERA_SHAKE = v end
})

RunService.RenderStepped:Connect(function()
    if NO_CAMERA_SHAKE then
        local humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.CameraOffset = Vector3.new(0, 0, 0) end
    end
end)

-- ==================================================================================
-- ================================= WORLD TAB ======================================
-- ==================================================================================

TabWorld:Section({ Title = "Tempo e Ambiente" })

TabWorld:Slider({
    Title = "Hora do Dia",
    Flag     = "WorldTime",
    Step  = 0.5,
    Value = { Min = 0, Max = 24, Default = 14 },
    Callback = function(v) Lighting.ClockTime = v end
})

TabWorld:Slider({
    Title = "Gravidade",
    Flag     = "WorldGravity",
    Step  = 10,
    Value = { Min = 60, Max = 500, Default = 196 },
    Callback = function(v) workspace.Gravity = v end
})

TabWorld:Button({
    Title = "Remover Fog",
    Callback = function() Lighting.FogEnd = 1e6 end
})

-- ==================================================================================
-- =============================== FPS/STATS TAB ====================================
-- ==================================================================================

TabFPS:Section({ Title = "Anti-Lag" })

local DELETE_3D_ENABLED        = false
local descendantAddedConnection = nil

-- No Lag Full System (by RIP#6666)
local function setupAdvancedAntiLag()
    local _StarterGui     = game:GetService("StarterGui")
    local _MaterialService = game:GetService("MaterialService")

    if not _G.Ignore then
        _G.Ignore = {}
    end
    if _G.SendNotifications == nil then
        _G.SendNotifications = true
    end
    if _G.ConsoleLogs == nil then
        _G.ConsoleLogs = false
    end

    if not game:IsLoaded() then
        repeat task.wait() until game:IsLoaded()
    end

    if not _G.Settings then
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
    end

    local ME, CanBeEnabled = LP, {"ParticleEmitter", "Trail", "Smoke", "Fire", "Sparkles"}

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
                if _G.Settings.Meshes.Destroy or _G.Settings["No Meshes"] then
                    Inst:Destroy()
                end
            elseif Inst:IsA("FaceInstance") then
                if _G.Settings.Images.Invisible then
                    Inst.Transparency = 1
                    Inst.Shiny = 1
                end
                if _G.Settings.Images.LowDetail then
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
                if _G.Settings["Invisible Particles"] or _G.Settings["No Particles"] or (_G.Settings.Other and _G.Settings.Other["Invisible Particles"]) or (_G.Settings.Particles and _G.Settings.Particles.Invisible) then
                    Inst.Enabled = false
                end
                if (_G.Settings.Other and _G.Settings.Other["No Particles"]) or (_G.Settings.Particles and _G.Settings.Particles.Destroy) then
                    Inst:Destroy()
                end
            elseif Inst:IsA("PostEffect") and (_G.Settings["No Camera Effects"] or (_G.Settings.Other and _G.Settings.Other["No Camera Effects"])) then
                Inst.Enabled = false
            elseif Inst:IsA("Explosion") then
                if _G.Settings["Smaller Explosions"] or (_G.Settings.Other and _G.Settings.Other["Smaller Explosions"]) or (_G.Settings.Explosions and _G.Settings.Explosions.Smaller) then
                    Inst.BlastPressure = 1
                    Inst.BlastRadius = 1
                end
                if _G.Settings["Invisible Explosions"] or (_G.Settings.Other and _G.Settings.Other["Invisible Explosions"]) or (_G.Settings.Explosions and _G.Settings.Explosions.Invisible) then
                    Inst.BlastPressure = 1
                    Inst.BlastRadius = 1
                    Inst.Visible = false
                end
                if _G.Settings["No Explosions"] or (_G.Settings.Other and _G.Settings.Other["No Explosions"]) or (_G.Settings.Explosions and _G.Settings.Explosions.Destroy) then
                    Inst:Destroy()
                end
            elseif Inst:IsA("Clothing") or Inst:IsA("SurfaceAppearance") or Inst:IsA("BaseWrap") then
                if _G.Settings["No Clothes"] or (_G.Settings.Other and _G.Settings.Other["No Clothes"]) then
                    Inst:Destroy()
                end
            elseif Inst:IsA("BasePart") and not Inst:IsA("MeshPart") then
                if _G.Settings["Low Quality Parts"] or (_G.Settings.Other and _G.Settings.Other["Low Quality Parts"]) then
                    Inst.Material = Enum.Material.Plastic
                    Inst.Reflectance = 0
                end
            elseif Inst:IsA("TextLabel") and Inst:IsDescendantOf(workspace) then
                if _G.Settings["Lower Quality TextLabels"] or (_G.Settings.Other and _G.Settings.Other["Lower Quality TextLabels"]) or (_G.Settings.TextLabels and _G.Settings.TextLabels.LowerQuality) then
                    Inst.Font = Enum.Font.SourceSans
                    Inst.TextScaled = false
                    Inst.RichText = false
                    Inst.TextSize = 14
                end
                if _G.Settings["Invisible TextLabels"] or (_G.Settings.Other and _G.Settings.Other["Invisible TextLabels"]) or (_G.Settings.TextLabels and _G.Settings.TextLabels.Invisible) then
                    Inst.Visible = false
                end
                if _G.Settings["No TextLabels"] or (_G.Settings.Other and _G.Settings.Other["No TextLabels"]) or (_G.Settings.TextLabels and _G.Settings.TextLabels.Destroy) then
                    Inst:Destroy()
                end
            elseif Inst:IsA("Model") then
                if _G.Settings["Low Quality Models"] or (_G.Settings.Other and _G.Settings.Other["Low Quality Models"]) then
                    Inst.LevelOfDetail = 1
                end
            elseif Inst:IsA("MeshPart") then
                if _G.Settings["Low Quality MeshParts"] or (_G.Settings.Other and _G.Settings.Other["Low Quality MeshParts"]) or (_G.Settings.MeshParts and _G.Settings.MeshParts.LowerQuality) then
                    Inst.RenderFidelity = 2
                    Inst.Reflectance = 0
                    Inst.Material = Enum.Material.Plastic
                end
                if _G.Settings["Invisible MeshParts"] or (_G.Settings.Other and _G.Settings.Other["Invisible MeshParts"]) or (_G.Settings.MeshParts and _G.Settings.MeshParts.Invisible) then
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
                if _G.Settings["No MeshParts"] or (_G.Settings.Other and _G.Settings.Other["No MeshParts"]) or (_G.Settings.MeshParts and _G.Settings.MeshParts.Destroy) then
                    Inst:Destroy()
                end
            end
        end
    end

    coroutine.wrap(pcall)(function()
        if (_G.Settings["Low Water Graphics"] or (_G.Settings.Other and _G.Settings.Other["Low Water Graphics"])) then
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
    coroutine.wrap(pcall)(function()
        if _G.Settings["No Shadows"] or (_G.Settings.Other and _G.Settings.Other["No Shadows"]) then
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.ShadowSoftness = 0
            if sethiddenproperty then
                sethiddenproperty(Lighting, "Technology", 2)
            end
        end
    end)
    coroutine.wrap(pcall)(function()
        if _G.Settings["Low Rendering"] or (_G.Settings.Other and _G.Settings.Other["Low Rendering"]) then
            settings().Rendering.QualityLevel = 1
            settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
        end
    end)
    coroutine.wrap(pcall)(function()
        if _G.Settings["Reset Materials"] or (_G.Settings.Other and _G.Settings.Other["Reset Materials"]) then
            for i, v in pairs(_MaterialService:GetChildren()) do
                v:Destroy()
            end
            _MaterialService.Use2022Materials = false
        end
    end)
    coroutine.wrap(pcall)(function()
        if _G.Settings["FPS Cap"] or (_G.Settings.Other and _G.Settings.Other["FPS Cap"]) then
            if setfpscap then
                if type(_G.Settings["FPS Cap"] or (_G.Settings.Other and _G.Settings.Other["FPS Cap"])) == "string"
                or type(_G.Settings["FPS Cap"] or (_G.Settings.Other and _G.Settings.Other["FPS Cap"])) == "number" then
                    setfpscap(tonumber(_G.Settings["FPS Cap"] or (_G.Settings.Other and _G.Settings.Other["FPS Cap"])))
                elseif _G.Settings["FPS Cap"] or (_G.Settings.Other and _G.Settings.Other["FPS Cap"]) == true then
                    setfpscap(1e6)
                end
            end
        end
    end)
    coroutine.wrap(pcall)(function()
        if _G.Settings.Other["ClearNilInstances"] then
            if getnilinstances then
                for _, v in pairs(getnilinstances()) do
                    pcall(v.Destroy, v)
                end
            end
        end
    end)

    for i, v in pairs(game:GetDescendants()) do
        CheckIfBad(v)
    end

    game.DescendantAdded:Connect(function(value)
        task.wait(_G.LoadedWait or 1)
        CheckIfBad(value)
    end)
end

local function hide3D(obj)
    pcall(function()
        if LP.Character and obj:IsDescendantOf(LP.Character) then return end
        if obj:IsA("BasePart") then
            obj.Transparency = 1
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 1
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
            obj.Enabled = false
        elseif obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            obj.Enabled = false
        end
    end)
end

TabFPS:Toggle({
    Title = "Advanced Anti-Lag (RIP)",
    Flag     = "AntiLag",
    Value = false,
    Callback = function(v)
        if v then
            setupAdvancedAntiLag()
            WindUI:Notify({ Title = "Anti-Lag", Content = "Sistema avançado ativado!", Duration = 2 })
        end
    end
})

TabFPS:Toggle({
    Title = "3D Delete (Hide World)",
    Flag     = "Delete3D",
    Value = false,
    Callback = function(v)
        DELETE_3D_ENABLED = v
        if v then
            for _, obj in ipairs(workspace:GetDescendants()) do hide3D(obj) end
            if descendantAddedConnection then descendantAddedConnection:Disconnect() end
            descendantAddedConnection = workspace.DescendantAdded:Connect(hide3D)
            WindUI:Notify({ Title = "3D Delete", Content = "Mundo escondido! FPS otimizado.", Duration = 2 })
        else
            if descendantAddedConnection then descendantAddedConnection:Disconnect(); descendantAddedConnection = nil end
            WindUI:Notify({ Title = "3D Delete", Content = "Desativado. Recarregue o jogo para restaurar.", Duration = 3 })
        end
    end
})

TabFPS:Toggle({
    Title = "Remover Sombras",
    Flag     = "RemoveShadows",
    Value = false,
    Callback = function(v)
        Lighting.GlobalShadows = not v
        if v then Lighting.ShadowSoftness = 0 end
    end
})

TabFPS:Slider({
    Title = "FPS Cap",
    Flag     = "FPSCap",
    Step  = 10,
    Value = { Min = 60, Max = 240, Default = 60 },
    Callback = function(v)
        pcall(function() setfpscap(v) end)
    end
})

-- ==================================================================================
-- ================================= STATS HUD ======================================
-- ==================================================================================

TabFPS:Section({ Title = "📊 Stats em Tempo Real" })

do -- Stats HUD
    local statsGui = Instance.new("ScreenGui")
    statsGui.Name           = "HubStatsHUD"
    statsGui.ResetOnSpawn   = false
    statsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    statsGui.IgnoreGuiInset = true
    pcall(function() statsGui.Parent = game:GetService("CoreGui") end)
    if not statsGui.Parent then statsGui.Parent = LP.PlayerGui end

    local statsFrame = Instance.new("Frame")
    statsFrame.Name                   = "StatsFrame"
    statsFrame.Size                   = UDim2.new(0, 210, 0, 0)
    statsFrame.AutomaticSize          = Enum.AutomaticSize.Y
    statsFrame.Position               = UDim2.new(1, -218, 0, 70)
    statsFrame.BackgroundColor3       = Color3.fromRGB(10, 10, 10)
    statsFrame.BackgroundTransparency = 0.35
    statsFrame.BorderSizePixel        = 0
    statsFrame.Visible                = false
    statsFrame.Parent                 = statsGui
    Instance.new("UICorner", statsFrame).CornerRadius = UDim.new(0, 6)
    local pad = Instance.new("UIPadding", statsFrame)
    pad.PaddingTop = UDim.new(0,5); pad.PaddingBottom = UDim.new(0,5)
    pad.PaddingLeft = UDim.new(0,6); pad.PaddingRight = UDim.new(0,6)

    local statsText = Instance.new("TextLabel", statsFrame)
    statsText.Size                   = UDim2.new(1, 0, 0, 0)
    statsText.AutomaticSize          = Enum.AutomaticSize.Y
    statsText.BackgroundTransparency = 1
    statsText.TextColor3             = Color3.fromRGB(220, 220, 220)
    statsText.TextSize               = 12
    statsText.Font                   = Enum.Font.Code
    statsText.TextXAlignment         = Enum.TextXAlignment.Left
    statsText.RichText               = true
    statsText.TextWrapped            = false
    statsText.Text                   = "Carregando stats..."

    local STATS_HUD_ENABLED = false
    local _fpsCount, _lastFpsUpdate, _currentFPS = 0, tick(), 0

    TabFPS:Toggle({
        Title = "Mostrar Stats HUD (overlay)",
        Flag  = "StatsHUD",
        Value = false,
        Callback = function(v)
            STATS_HUD_ENABLED  = v
            statsFrame.Visible = v
        end
    })

    RunService.RenderStepped:Connect(function()
        _fpsCount = _fpsCount + 1
        if tick() - _lastFpsUpdate >= 1 then
            _currentFPS    = _fpsCount
            _fpsCount      = 0
            _lastFpsUpdate = tick()
        end
    end)

    task.spawn(function()
        while task.wait(0.5) do
            if not STATS_HUD_ENABLED then continue end
            pcall(function()
                local ping        = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
                local playerCount = #Players:GetPlayers()
                local maxPlayers  = Players.MaxPlayers
                local hp, maxhp, speed, jump = "?", "?", "?", "?"
                if Character and Humanoid then
                    hp    = math.floor(Humanoid.Health)
                    maxhp = math.floor(Humanoid.MaxHealth)
                    speed = math.floor(Humanoid.WalkSpeed)
                    jump  = math.floor(Humanoid.JumpPower)
                end
                statsText.Text = string.format(
                    "<b>FPS:</b> %d\n<b>Ping:</b> %.0f ms\n<b>Players:</b> %d/%d\n<b>HP:</b> %s/%s\n<b>Speed:</b> %s  <b>Jump:</b> %s",
                    _currentFPS, ping, playerCount, maxPlayers, hp, maxhp, speed, jump
                )
            end)
        end
    end)
end -- Stats HUD

-- ==================================================================================
-- ============================== CONFIG TAB ========================================
-- ==================================================================================

-- Keybind variables
local keybindESP        = Enum.KeyCode.E
local keybindHighlight  = Enum.KeyCode.H
local keybindAim        = Enum.KeyCode.R
local keybindPlayerAim  = Enum.KeyCode.T
local keybindFly        = Enum.KeyCode.F
local keybindNoclip     = Enum.KeyCode.N
local keybindInfJump    = Enum.KeyCode.J
local keybindAutoClicker = Enum.KeyCode.C
local keybindGodMode    = Enum.KeyCode.G
local keybindFullbright  = Enum.KeyCode.B
local keybindAimLock    = Enum.KeyCode.L
local keybindGUI        = Enum.KeyCode.RightControl

-- Forward declarations das funções de aim lock
-- (definidas mais abaixo, mas referenciadas no InputBegan)
local getAimLockTarget, startAimLockLoop, stopAimLockLoop

TabConfig:Section({ Title = "Keybinds de Movimento" })

TabConfig:Keybind({
    Title    = "Fly",
    Flag     = "KeyFly",
    Value    = "F",
    Callback = function(key)
        keybindFly = type(key) == "string" and (Enum.KeyCode[key] or keybindFly) or key
    end
})

TabConfig:Keybind({
    Title    = "Noclip",
    Flag     = "KeyNoclip",
    Value    = "N",
    Callback = function(key)
        keybindNoclip = type(key) == "string" and (Enum.KeyCode[key] or keybindNoclip) or key
    end
})

TabConfig:Keybind({
    Title    = "Infinite Jump",
    Flag     = "KeyInfJump",
    Value    = "J",
    Callback = function(key)
        keybindInfJump = type(key) == "string" and (Enum.KeyCode[key] or keybindInfJump) or key
    end
})

TabConfig:Section({ Title = "Keybinds de ESP" })

TabConfig:Keybind({
    Title    = "ESP",
    Flag     = "KeyESP",
    Value    = "E",
    Callback = function(key)
        keybindESP = type(key) == "string" and (Enum.KeyCode[key] or keybindESP) or key
    end
})

TabConfig:Keybind({
    Title    = "Highlight ESP",
    Flag     = "KeyHighlight",
    Value    = "H",
    Callback = function(key)
        keybindHighlight = type(key) == "string" and (Enum.KeyCode[key] or keybindHighlight) or key
    end
})

TabConfig:Section({ Title = "Keybinds de Aim" })

TabConfig:Keybind({
    Title    = "Aim Assist",
    Flag     = "KeyAimAssist",
    Value    = "R",
    Callback = function(key)
        keybindAim = type(key) == "string" and (Enum.KeyCode[key] or keybindAim) or key
    end
})

TabConfig:Keybind({
    Title    = "Player Aim",
    Flag     = "KeyPlayerAim",
    Value    = "T",
    Callback = function(key)
        keybindPlayerAim = type(key) == "string" and (Enum.KeyCode[key] or keybindPlayerAim) or key
    end
})

TabConfig:Section({ Title = "Keybinds de Combat" })

TabConfig:Keybind({
    Title    = "Auto Clicker",
    Flag     = "KeyAutoClicker",
    Value    = "C",
    Callback = function(key)
        keybindAutoClicker = type(key) == "string" and (Enum.KeyCode[key] or keybindAutoClicker) or key
    end
})

TabConfig:Section({ Title = "Keybinds de Proteção" })

TabConfig:Keybind({
    Title    = "God Mode",
    Flag     = "KeyGodMode",
    Value    = "G",
    Callback = function(key)
        keybindGodMode = type(key) == "string" and (Enum.KeyCode[key] or keybindGodMode) or key
    end
})

TabConfig:Section({ Title = "Keybinds Visuais" })

TabConfig:Keybind({
    Title    = "Fullbright",
    Flag     = "KeyFullbright",
    Value    = "B",
    Callback = function(key)
        keybindFullbright = type(key) == "string" and (Enum.KeyCode[key] or keybindFullbright) or key
    end
})

TabConfig:Section({ Title = "Keybind Aim Lock" })

TabConfig:Keybind({
    Title    = "Aim Lock",
    Flag     = "KeyAimLock",
    Value    = "L",
    Callback = function(key)
        keybindAimLock = type(key) == "string" and (Enum.KeyCode[key] or keybindAimLock) or key
    end
})

TabConfig:Section({ Title = "Keybind da GUI" })

TabConfig:Keybind({
    Title    = "Toggle GUI",
    Flag     = "KeyGUI",
    Value    = "RCtrl",
    Callback = function(key)
        keybindGUI = type(key) == "string" and (Enum.KeyCode[key] or keybindGUI) or key
    end
})

-- Keybind detection
-- Não usa "gameProcessed" porque jogos Roblox marcam quase todas as teclas como processadas,
-- bloqueando os keybinds. Em vez disso, só ignora quando o foco está em um TextBox.
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- Permite passar mesmo com gameProcessed=true, exceto se estiver digitando
    if UserInputService:GetFocusedTextBox() then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    if input.KeyCode == keybindESP then
        ESP_ENABLED = not ESP_ENABLED
        refreshESP()
        WindUI:Notify({ Title = "ESP", Content = ESP_ENABLED and "✅ Ativado" or "❌ Desativado", Duration = 1.5 })

    elseif input.KeyCode == keybindHighlight then
        HIGHLIGHT_ENABLED = not HIGHLIGHT_ENABLED
        updateAllHighlights()
        WindUI:Notify({ Title = "Highlight ESP", Content = HIGHLIGHT_ENABLED and "✅ Ativado" or "❌ Desativado", Duration = 1.5 })

    elseif input.KeyCode == keybindAim then
        AIM_ENABLED = not AIM_ENABLED
        currentTarget = nil
        WindUI:Notify({ Title = "Aim Assist", Content = AIM_ENABLED and "✅ Ativado" or "❌ Desativado", Duration = 1.5 })

    elseif input.KeyCode == keybindPlayerAim then
        if not TargetPlayerName then
            WindUI:Notify({ Title = "Player Aim", Content = "Selecione um jogador primeiro!", Duration = 2 })
            return
        end
        PlayerAimEnabled = not PlayerAimEnabled
        WindUI:Notify({ Title = "Player Aim",
            Content = PlayerAimEnabled and ("✅ Mirando em " .. tostring(TargetPlayerName)) or "❌ Desativado",
            Duration = 1.5 })

    elseif input.KeyCode == keybindFly then
        local newState = not flyEnabled
        toggleFly(newState)
        WindUI:Notify({ Title = "Fly", Content = newState and "✅ Ativado" or "❌ Desativado", Duration = 1.5 })

    elseif input.KeyCode == keybindNoclip then
        noclip = not noclip
        WindUI:Notify({ Title = "Noclip", Content = noclip and "✅ Ativado" or "❌ Desativado", Duration = 1.5 })

    elseif input.KeyCode == keybindInfJump then
        infJump = not infJump
        WindUI:Notify({ Title = "Infinite Jump", Content = infJump and "✅ Ativado" or "❌ Desativado", Duration = 1.5 })

    elseif input.KeyCode == keybindAutoClicker then
        AUTO_CLICKER_ENABLED = not AUTO_CLICKER_ENABLED
        if AUTO_CLICKER_ENABLED then lastClick = tick() end
        WindUI:Notify({ Title = "Auto Clicker", Content = AUTO_CLICKER_ENABLED and "✅ Ativado" or "❌ Desativado", Duration = 1.5 })

    elseif input.KeyCode == keybindGodMode then
        godMode = not godMode
        WindUI:Notify({ Title = "God Mode", Content = godMode and "✅ Ativado" or "❌ Desativado", Duration = 1.5 })

    elseif input.KeyCode == keybindFullbright then
        FULLBRIGHT_ENABLED = not FULLBRIGHT_ENABLED
        toggleFullbright(FULLBRIGHT_ENABLED)
        WindUI:Notify({ Title = "Fullbright", Content = FULLBRIGHT_ENABLED and "✅ Ativado" or "❌ Desativado", Duration = 1.5 })

    elseif input.KeyCode == keybindAimLock then
        aimLockEnabled = not aimLockEnabled
        if aimLockEnabled then
            aimLockTarget = getAimLockTarget()
            startAimLockLoop()
            WindUI:Notify({ Title = "🔒 Aim Lock", Content = aimLockTarget and ("Trancado em: " .. aimLockTarget.Name) or "Nenhum alvo na frente", Duration = 2 })
        else
            stopAimLockLoop()
            WindUI:Notify({ Title = "🔓 Aim Lock", Content = "Desativado", Duration = 1.5 })
        end
        if _aimLockRefresh then _aimLockRefresh() end

    elseif input.KeyCode == keybindGUI then
        Window:Toggle()
    end
end)

-- ==================================================================================
-- ============================== CONFIG TAB - TEMA & CONFIG ========================
-- ==================================================================================

-- ===== SEÇÃO: PERSONALIZAÇÃO DE TEMA =====
TabConfig:Section({ Title = "Personalização de Tema" })

-- Cores padrão (Dark)
local TC = {
    Accent           = Color3.fromHex("#18181b"),
    Background       = Color3.fromHex("#101010"),
    Outline          = Color3.fromHex("#FFFFFF"),
    Text             = Color3.fromHex("#FFFFFF"),
    Placeholder      = Color3.fromHex("#7a7a7a"),
    Button           = Color3.fromHex("#00ff00"),
    Icon             = Color3.fromHex("#a1a1aa"),
    Toggle           = Color3.fromHex("#00ff00"),
    Slider           = Color3.fromHex("#00ff00"),
    GradStart        = Color3.fromHex("#1f1f23"),
    GradEnd          = Color3.fromHex("#18181b"),
}

local function applyTheme()
    pcall(function()
        WindUI:AddTheme({
            Name = "CustomHub",
            Accent                       = TC.Accent,
            Background                   = TC.Background,
            BackgroundTransparency       = 0,
            Outline                      = TC.Outline,
            Text                         = TC.Text,
            Placeholder                  = TC.Placeholder,
            Button                       = TC.Button,
            Icon                         = TC.Icon,
            Hover                        = TC.Text,
            WindowBackground             = TC.Background,
            WindowShadow                 = Color3.fromHex("#000000"),
            DialogBackground             = TC.Background,
            DialogBackgroundTransparency = 0,
            DialogTitle                  = TC.Text,
            DialogContent                = TC.Text,
            DialogIcon                   = TC.Icon,
            WindowTopbarButtonIcon       = TC.Icon,
            WindowTopbarTitle            = TC.Text,
            WindowTopbarAuthor           = TC.Text,
            WindowTopbarIcon             = TC.Icon,
            TabBackground                = TC.Text,
            TabTitle                     = TC.Text,
            TabIcon                      = TC.Icon,
            ElementBackground            = TC.Text,
            ElementTitle                 = TC.Text,
            ElementDesc                  = TC.Text,
            ElementIcon                  = TC.Icon,
            PopupBackground              = TC.Background,
            PopupBackgroundTransparency  = 0,
            PopupTitle                   = TC.Text,
            PopupContent                 = TC.Text,
            PopupIcon                    = TC.Icon,
            Toggle                       = TC.Toggle,
            ToggleBar                    = Color3.fromHex("#FFFFFF"),
            Checkbox                     = TC.Button,
            CheckboxIcon                 = Color3.fromHex("#FFFFFF"),
            Slider                       = TC.Slider,
            SliderThumb                  = Color3.fromHex("#FFFFFF"),
        })
        WindUI:SetTheme("CustomHub")
        WindUI:Gradient({
            ["0"]   = { Color = TC.GradStart, Transparency = 0 },
            ["100"] = { Color = TC.GradEnd,   Transparency = 0 },
        }, { Rotation = 0 })
    end)
end

TabConfig:Colorpicker({
    Title    = "Background Color",
    Flag     = "ThemeBG",
    Value    = TC.Background,
    Callback = function(c) TC.Background = c TC.WindowBackground = c end,
})

TabConfig:Colorpicker({
    Title    = "Accent Color",
    Flag     = "ThemeAccent",
    Value    = TC.Accent,
    Callback = function(c) TC.Accent = c end,
})

TabConfig:Colorpicker({
    Title    = "Outline Color",
    Flag     = "ThemeOutline",
    Value    = TC.Outline,
    Callback = function(c) TC.Outline = c end,
})

TabConfig:Colorpicker({
    Title    = "Text Color",
    Flag     = "ThemeText",
    Value    = TC.Text,
    Callback = function(c) TC.Text = c end,
})

TabConfig:Colorpicker({
    Title    = "Placeholder Text Color",
    Flag     = "ThemePlaceholder",
    Value    = TC.Placeholder,
    Callback = function(c) TC.Placeholder = c end,
})

TabConfig:Colorpicker({
    Title    = "Button Color",
    Flag     = "ThemeButton",
    Value    = TC.Button,
    Callback = function(c) TC.Button = c TC.Toggle = c TC.Slider = c end,
})

TabConfig:Colorpicker({
    Title    = "Icon Color",
    Flag     = "ThemeIcon",
    Value    = TC.Icon,
    Callback = function(c) TC.Icon = c end,
})

TabConfig:Colorpicker({
    Title    = "Gradient Início",
    Flag     = "ThemeGradStart",
    Value    = TC.GradStart,
    Callback = function(c) TC.GradStart = c end,
})

TabConfig:Colorpicker({
    Title    = "Gradient Fim",
    Flag     = "ThemeGradEnd",
    Value    = TC.GradEnd,
    Callback = function(c) TC.GradEnd = c end,
})

TabConfig:Button({
    Title    = "Atualizar Tema",
    Icon     = "sparkles",
    Callback = function()
        applyTheme()
        WindUI:Notify({ Title = "Tema", Content = "✅ Tema aplicado!", Duration = 2 })
    end,
})

TabConfig:Button({
    Title    = "Resetar Tema (Padrão)",
    Icon     = "rotate-ccw",
    Callback = function()
        TC.Accent      = Color3.fromHex("#18181b")
        TC.Background  = Color3.fromHex("#101010")
        TC.Outline     = Color3.fromHex("#FFFFFF")
        TC.Text        = Color3.fromHex("#FFFFFF")
        TC.Placeholder = Color3.fromHex("#7a7a7a")
        TC.Button      = Color3.fromHex("#00ff00")
        TC.Icon        = Color3.fromHex("#a1a1aa")
        TC.Toggle      = Color3.fromHex("#00ff00")
        TC.Slider      = Color3.fromHex("#00ff00")
        TC.GradStart   = Color3.fromHex("#1f1f23")
        TC.GradEnd     = Color3.fromHex("#18181b")
        applyTheme()
        WindUI:Notify({ Title = "Tema", Content = "🔄 Tema resetado ao padrão!", Duration = 2 })
    end,
})

-- ===== SEÇÃO: JANELA =====
TabConfig:Section({ Title = "Janela" })

TabConfig:Toggle({
    Title    = "Desativar Notificações",
    Flag     = "DisableNotif",
    Value    = false,
    Callback = function(v)
        WindUI._notifDisabled = v
    end,
})

-- Destruir GUI
TabConfig:Button({
    Title    = "Destruir GUI (Irreversível)",
    Icon     = "trash-2",
    Callback = function()
        clearAllESP()
        removeAllHighlights()
        WindUI:Notify({ Title = "GUI", Content = "Recarregue o script para usar novamente", Duration = 3 })
        task.wait(1.5)
        Window:Destroy()
    end,
})

-- ==================================================================================
-- ============================== AIM LOCK SYSTEM ===================================
-- ==================================================================================

local aimLockEnabled  = false
local aimLockTarget   = nil
local aimLockConn     = nil
local AIM_LOCK_FOV    = 160
local _aimLockRefresh = nil
local aimLockPosFrozen = false  -- trava a posição do botão na tela

-- Encontra o jogador vivo mais próximo da direção da câmera
getAimLockTarget = function()
    if not HRP then return nil end
    local camPos  = Camera.CFrame.Position
    local camLook = Camera.CFrame.LookVector
    local best, bestDot = nil, math.cos(math.rad(AIM_LOCK_FOV / 2))

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local tHRP = player.Character:FindFirstChild("HumanoidRootPart")
            local tHum = player.Character:FindFirstChildWhichIsA("Humanoid")
            if tHRP and tHum and tHum.Health > 0 then
                local dot = (tHRP.Position - camPos).Unit:Dot(camLook)
                if dot > bestDot then
                    bestDot = dot
                    best    = player
                end
            end
        end
    end
    return best
end

-- Loop principal do aim lock
startAimLockLoop = function()
    if aimLockConn then aimLockConn:Disconnect() end
    aimLockConn = RunService.RenderStepped:Connect(function()
        if not aimLockEnabled then return end

        -- Revalida o alvo se morreu ou saiu
        if aimLockTarget then
            local tHum = aimLockTarget.Character and aimLockTarget.Character:FindFirstChildWhichIsA("Humanoid")
            if not tHum or tHum.Health <= 0 then
                aimLockTarget = getAimLockTarget()
            end
        else
            aimLockTarget = getAimLockTarget()
        end

        if not aimLockTarget or not aimLockTarget.Character then return end
        local tHRP  = aimLockTarget.Character:FindFirstChild("HumanoidRootPart")
        local tHead = aimLockTarget.Character:FindFirstChild("Head")
        if not tHRP then return end

        local targetPos = tHead and tHead.Position or tHRP.Position
        local camPos    = Camera.CFrame.Position

        -- Tranca a câmera apontando pro alvo (funciona em 1ª e 3ª pessoa)
        Camera.CFrame = CFrame.lookAt(camPos, targetPos)
    end)
end

stopAimLockLoop = function()
    if aimLockConn then aimLockConn:Disconnect(); aimLockConn = nil end
    aimLockTarget = nil
end

-- ================== PADLOCK GUI (fora da UI principal) ==================
local _aimLockGui = nil

local function buildLockButton()
    pcall(function()
        local guiParent = (gethui and gethui()) or game:GetService("CoreGui")

        -- Remove instância anterior se existir
        local old = guiParent:FindFirstChild("AimLockPadlock")
        if old then old:Destroy() end

        local sg = Instance.new("ScreenGui")
        sg.Name              = "AimLockPadlock"
        sg.ResetOnSpawn      = false
        sg.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
        sg.IgnoreGuiInset    = true
        sg.Enabled           = false   -- começa oculto
        sg.Parent            = guiParent
        _aimLockGui          = sg

        -- Frame externo (sombra / glow)
        local glow = Instance.new("Frame")
        glow.Name             = "Glow"
        glow.Size             = UDim2.fromOffset(58, 58)
        glow.Position         = UDim2.fromOffset(30, 300)
        glow.BackgroundColor3 = Color3.fromRGB(0, 255, 80)
        glow.BackgroundTransparency = 1
        glow.BorderSizePixel  = 0
        glow.ZIndex           = 10
        glow.Parent           = sg
        Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 14)

        -- Botão principal
        local btn = Instance.new("TextButton")
        btn.Name                  = "LockBtn"
        btn.Size                  = UDim2.fromOffset(52, 52)
        btn.Position              = UDim2.fromOffset(3, 3)
        btn.BackgroundColor3      = Color3.fromRGB(22, 22, 28)
        btn.BackgroundTransparency = 0.08
        btn.BorderSizePixel       = 0
        btn.Text                  = "🔓"
        btn.TextSize              = 26
        btn.Font                  = Enum.Font.GothamBold
        btn.ZIndex                = 11
        btn.Parent                = glow
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)

        -- Borda do botão
        local stroke = Instance.new("UIStroke")
        stroke.Color     = Color3.fromRGB(50, 50, 60)
        stroke.Thickness = 1.5
        stroke.Parent    = btn

        -- Label "AIM LOCK" abaixo
        local label = Instance.new("TextLabel")
        label.Size                  = UDim2.fromOffset(72, 16)
        label.Position              = UDim2.new(0.5, -36, 1, 4)
        label.BackgroundTransparency = 1
        label.Text                  = "AIM LOCK"
        label.TextColor3            = Color3.fromRGB(160, 160, 180)
        label.TextSize              = 9
        label.Font                  = Enum.Font.GothamBold
        label.ZIndex                = 11
        label.Parent                = glow

        -- Função que atualiza visual do botão
        local function refreshVisual()
            if aimLockEnabled then
                btn.Text              = "🔒"
                btn.BackgroundColor3  = Color3.fromRGB(10, 32, 18)
                stroke.Color          = Color3.fromRGB(0, 255, 80)
                glow.BackgroundTransparency = 0.82
                label.TextColor3      = Color3.fromRGB(0, 255, 80)
            else
                btn.Text              = "🔓"
                btn.BackgroundColor3  = Color3.fromRGB(22, 22, 28)
                stroke.Color          = Color3.fromRGB(50, 50, 60)
                glow.BackgroundTransparency = 1
                label.TextColor3      = Color3.fromRGB(160, 160, 180)
            end
        end
        -- Expõe refreshVisual para o toggle da aba poder atualizar o visual
        _aimLockRefresh = refreshVisual

        -- ===== DRAG + TAP (mobile-safe) =====
        -- O TextButton (btn) fica em cima do glow e intercepta todos os toques.
        -- Por isso usamos os eventos do btn como origem do drag.
        -- Distinguimos tap de arraste pela distância percorrida (> DRAG_THRESHOLD = drag).
        local DRAG_THRESHOLD = 10
        local dragging   = false
        local wasDragged = false
        local dragStart  = nil
        local startPos   = nil

        btn.AutoButtonColor = false  -- evita conflito visual com o drag

        -- Função interna para executar o toggle do aim lock
        local function doAimLockToggle()
            aimLockEnabled = not aimLockEnabled
            if aimLockEnabled then
                aimLockTarget = getAimLockTarget()
                startAimLockLoop()
                WindUI:Notify({ Title = "🔒 Aim Lock", Content = aimLockTarget and ("Trancado em: " .. aimLockTarget.Name) or "Nenhum alvo na frente", Duration = 2 })
            else
                stopAimLockLoop()
                WindUI:Notify({ Title = "🔓 Aim Lock", Content = "Desativado", Duration = 1.5 })
            end
            refreshVisual()
        end

        -- Toque/clique começa no botão
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                if aimLockPosFrozen then
                    -- Posição travada: tap direto no InputBegan (sem esperar o soltar)
                    doAimLockToggle()
                    return
                end
                dragging   = true
                wasDragged = false
                dragStart  = input.Position
                startPos   = glow.Position
            end
        end)

        -- Movimento global → move o botão se passou do threshold
        UserInputService.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
                local delta = input.Position - dragStart
                if delta.Magnitude > DRAG_THRESHOLD then
                    wasDragged = true
                end
                if wasDragged then
                    glow.Position = UDim2.fromOffset(
                        startPos.X.Offset + delta.X,
                        startPos.Y.Offset + delta.Y
                    )
                end
            end
        end)

        -- Soltar: se não arrastou = tap → toggle aim lock
        UserInputService.InputEnded:Connect(function(input)
            if not dragging then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                if not wasDragged then
                    doAimLockToggle()
                end
                dragging   = false
                wasDragged = false
            end
        end)

        refreshVisual()
    end)
end

-- Reconstrói o botão ao respawnar
LP.CharacterAdded:Connect(function()
    task.wait(1)
    buildLockButton()
end)

-- Cria o botão ao carregar o script
task.spawn(function()
    task.wait(1.5)
    buildLockButton()
end)

-- Ativa o keybind do Aim Lock agora que getAimLockTarget/startAimLockLoop/stopAimLockLoop existem

-- ==================================================================================
-- ============================== INVENTORY ESP =====================================
-- ==================================================================================

local INV_ESP_ENABLED = false
local INV_ESP_MAX     = 5

local _INV_BASE_BOX   = 34
local _INV_BASE_GUI_W = 200
local _INV_BASE_GUI_H = 40

-- Tabela de estado por jogador: [player] = { gui, holder, layout, conns, lastScale }
local _invData = {}

local function _invDestroyPlayer(player)
    local d = _invData[player]
    if not d then return end
    for _, c in ipairs(d.conns) do pcall(function() c:Disconnect() end) end
    pcall(function() if d.gui then d.gui:Destroy() end end)
    _invData[player] = nil
end

-- Reconstrói as caixas de item para um jogador (chamado por eventos de inventário ou mudança de escala)
local function _invBuildBoxes(d, player, char, scale)
    local holder = d.holder
    local layout = d.layout

    for _, v in ipairs(holder:GetChildren()) do
        if v:IsA("Frame") then v:Destroy() end
    end

    local boxSize = math.max(16, math.round(_INV_BASE_BOX * scale))
    layout.Padding = UDim.new(0, math.max(2, math.round(4 * scale)))

    -- Coleta itens: equipados primeiro (destacados em verde), depois mochila
    local items      = {}
    local equippedSet = {}

    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            table.insert(items, { tool = tool, equipped = true })
            equippedSet[tool] = true
        end
    end

    local okBP, bp = pcall(function() return player.Backpack end)
    if okBP and bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") and not equippedSet[tool] then
                table.insert(items, { tool = tool, equipped = false })
            end
        end
    end

    for i, entry in ipairs(items) do
        if i > INV_ESP_MAX then break end

        local tool = entry.tool
        local img  = tool.TextureId or ""
        if img == "" then
            local handle = tool:FindFirstChild("Handle")
            if handle then
                local decal = handle:FindFirstChildOfClass("Decal")
                if decal then img = decal.Texture end
            end
        end

        -- Caixa principal
        local box = Instance.new("Frame")
        box.Size                  = UDim2.new(0, boxSize, 0, boxSize)
        box.BackgroundColor3      = entry.equipped
            and Color3.fromRGB(8, 38, 14)
            or  Color3.fromRGB(15, 15, 15)
        box.BackgroundTransparency = 0.2
        box.BorderSizePixel       = 0
        box.Parent                = holder

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = box

        -- Borda verde = equipado | branca = mochila
        local stroke = Instance.new("UIStroke")
        stroke.Thickness    = entry.equipped and 2 or 1.2
        stroke.Color        = entry.equipped
            and Color3.fromRGB(0, 220, 75)
            or  Color3.fromRGB(220, 220, 220)
        stroke.Transparency = entry.equipped and 0.05 or 0.45
        stroke.Parent       = box

        local imgLabel = Instance.new("ImageLabel")
        imgLabel.Size                 = UDim2.new(1, -6, 1, -6)
        imgLabel.Position             = UDim2.new(0, 3, 0, 3)
        imgLabel.BackgroundTransparency = 1
        imgLabel.Image                = img ~= "" and img or "rbxasset://textures/ui/GuiImagePlaceholder.png"
        imgLabel.ScaleType            = Enum.ScaleType.Fit
        imgLabel.Parent               = box
    end
end

local function _invSetupPlayer(player)
    if player == LP then return end

    local function onChar(char)
        if not char or not char.Parent then return end
        _invDestroyPlayer(player)

        local head = char:WaitForChild("Head", 10)
        if not head then return end

        local gui = Instance.new("BillboardGui")
        gui.Name         = "InvESP"
        gui.Adornee      = head
        gui.Size         = UDim2.new(0, _INV_BASE_GUI_W, 0, _INV_BASE_GUI_H)
        gui.StudsOffset  = Vector3.new(0, 2.6, 0)
        gui.AlwaysOnTop  = true
        gui.ResetOnSpawn = false
        gui.Enabled      = INV_ESP_ENABLED
        gui.Parent       = head

        local holder = Instance.new("Frame")
        holder.Size                 = UDim2.new(1, 0, 1, 0)
        holder.BackgroundTransparency = 1
        holder.Parent               = gui

        local layout = Instance.new("UIListLayout")
        layout.FillDirection        = Enum.FillDirection.Horizontal
        layout.HorizontalAlignment  = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment    = Enum.VerticalAlignment.Center
        layout.Padding              = UDim.new(0, 4)
        layout.Parent               = holder

        local d = { gui = gui, holder = holder, layout = layout, conns = {}, lastScale = -1 }
        _invData[player] = d

        local function safeConn(sig, fn)
            local ok, c = pcall(function() return sig:Connect(fn) end)
            if ok then table.insert(d.conns, c) end
        end

        -- Atualiza caixas quando inventário muda (event-driven, sem polling)
        local function onInvChange()
            if not INV_ESP_ENABLED then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            local scale = root
                and math.clamp(1 - (Camera.CFrame.Position - root.Position).Magnitude / 200, 0.4, 1)
                or 1
            d.lastScale = scale
            _invBuildBoxes(d, player, char, scale)
        end

        local okBP, bp = pcall(function() return player.Backpack end)
        if okBP and bp then
            safeConn(bp.ChildAdded,   onInvChange)
            safeConn(bp.ChildRemoved, onInvChange)
        end
        safeConn(char.ChildAdded,   onInvChange)
        safeConn(char.ChildRemoved, onInvChange)

        -- Limpeza automática quando o personagem sai
        safeConn(char.AncestryChanged, function()
            if not char.Parent then _invDestroyPlayer(player) end
        end)

        if INV_ESP_ENABLED then _invBuildBoxes(d, player, char, 1) end
    end

    player.CharacterAdded:Connect(onChar)
    if player.Character then task.spawn(onChar, player.Character) end
end

-- Loop de escala: throttle 10fps, compartilhado para todos os jogadores
local _invScaleTick = 0
RunService.RenderStepped:Connect(function()
    if not INV_ESP_ENABLED then return end
    local now = tick()
    if now - _invScaleTick < 0.1 then return end
    _invScaleTick = now

    for player, d in pairs(_invData) do
        if not d.gui or not d.gui.Parent then _invData[player] = nil; continue end
        local char = player.Character
        if not char then continue end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        local scale = math.clamp(1 - (Camera.CFrame.Position - root.Position).Magnitude / 200, 0.4, 1)
        d.gui.Size = UDim2.new(0, _INV_BASE_GUI_W * scale, 0, _INV_BASE_GUI_H * scale)

        -- Reconstrói só quando a escala muda o suficiente
        if math.abs(scale - d.lastScale) > 0.025 then
            d.lastScale = scale
            _invBuildBoxes(d, player, char, scale)
        end
    end
end)

-- Helper: rebuild de todos (usado pelo toggle e pelo slider)
local function _invRebuildAll()
    for player, d in pairs(_invData) do
        local char = player.Character
        if char then
            local s = math.max(d.lastScale, 0.4)
            _invBuildBoxes(d, player, char, s)
        end
    end
end

-- Inicializa para jogadores já presentes
for _, p in ipairs(Players:GetPlayers()) do _invSetupPlayer(p) end
Players.PlayerAdded:Connect(_invSetupPlayer)
Players.PlayerRemoving:Connect(_invDestroyPlayer)

-- ==================================================================================
-- ============================== UTILITY TAB =======================================
-- ==================================================================================

TabUtil:Section({ Title = "Aim Lock" })

TabUtil:Toggle({
    Title    = "Mostrar Botão Aim Lock",
    Flag     = "AimLockToggle",
    Value    = false,
    Callback = function(v)
        -- Mostra ou esconde o botão flutuante na tela
        if _aimLockGui then
            _aimLockGui.Enabled = v
        end
        if not v then
            -- Se esconder, desativa o aim lock também
            aimLockEnabled = false
            stopAimLockLoop()
            if _aimLockRefresh then _aimLockRefresh() end
        end
    end,
})

TabUtil:Slider({
    Title = "FOV do Aim Lock",
    Flag  = "AimLockFOV",
    Step  = 5,
    Value = { Min = 30, Max = 360, Default = 160 },
    Callback = function(v) AIM_LOCK_FOV = v end,
})

TabUtil:Toggle({
    Title    = "Travar Posição do Botão",
    Flag     = "AimLockPosLock",
    Value    = false,
    Callback = function(v)
        aimLockPosFrozen = v
        -- Feedback visual: borda laranja quando travado
        if _aimLockGui then
            local btn    = _aimLockGui.Glow and _aimLockGui.Glow:FindFirstChild("LockBtn")
            local stroke = btn and btn:FindFirstChildWhichIsA("UIStroke")
            if stroke and not aimLockEnabled then
                stroke.Color = v and Color3.fromRGB(255, 160, 0) or Color3.fromRGB(50, 50, 60)
            end
        end
        WindUI:Notify({
            Title   = v and "📌 Posição Travada" or "📌 Posição Livre",
            Content = v and "Botão fixo — arraste desativado" or "Botão pode ser arrastado",
            Duration = 2
        })
    end,
})

TabUtil:Section({ Title = "Inventory ESP" })

TabUtil:Toggle({
    Title    = "Mostrar Inventário ESP",
    Flag     = "InvESPEnabled",
    Value    = false,
    Callback = function(v)
        INV_ESP_ENABLED = v
        for _, d in pairs(_invData) do
            if d.gui then d.gui.Enabled = v end
        end
        if v then _invRebuildAll() end
        WindUI:Notify({
            Title   = "🎒 Inventory ESP",
            Content = v and "Ativado — itens verdes = equipados" or "Desativado",
            Duration = 2,
        })
    end,
})

TabUtil:Slider({
    Title = "Máx. Itens Visíveis",
    Flag  = "InvESPMax",
    Step  = 1,
    Value = { Min = 1, Max = 10, Default = 5 },
    Callback = function(v)
        INV_ESP_MAX = v
        if INV_ESP_ENABLED then _invRebuildAll() end
    end,
})

TabUtil:Section({ Title = "Noclip & ShiftLock" })

TabUtil:Toggle({
    Title    = "Noclip",
    Flag     = "UtilNoclip",
    Value    = false,
    Callback = function(v) noclip = v end
})

-- Shift Lock
local shiftLockEnabled     = false
local shiftLockRotConnection = nil
local oldAutoRotate        = nil

local function applyShiftLock(enabled)
    if not Character or not Humanoid or not HRP then return end
    shiftLockEnabled = enabled
    if UserInputService.MouseEnabled then
        UserInputService.MouseBehavior = enabled
            and Enum.MouseBehavior.LockCenter
            or  Enum.MouseBehavior.Default
    end
    if shiftLockRotConnection then shiftLockRotConnection:Disconnect(); shiftLockRotConnection = nil end
    if enabled then
        oldAutoRotate = Humanoid.AutoRotate
        Humanoid.AutoRotate = false
        shiftLockRotConnection = RunService.RenderStepped:Connect(function()
            local lookVector = Camera.CFrame.LookVector
            local flatVector = Vector3.new(lookVector.X, 0, lookVector.Z)
            if flatVector.Magnitude > 0.0001 then
                HRP.CFrame = CFrame.lookAt(HRP.Position, HRP.Position + flatVector.Unit, Vector3.yAxis)
            end
        end)
    else
        if oldAutoRotate ~= nil then Humanoid.AutoRotate = oldAutoRotate end
    end
end

LP.CharacterAdded:Connect(function()
    task.defer(function()
        task.wait(0.5)
        if shiftLockEnabled then applyShiftLock(true) end
    end)
end)

TabUtil:Toggle({
    Title = "Shift Lock",
    Flag     = "ShiftLock",
    Value = false,
    Callback = function(v) applyShiftLock(v) end
})

TabUtil:Toggle({
    Title = "Insta Interact",
    Flag     = "InstaInteract",
    Value = false,
    Callback = function(v)
        _G.InstaInteract = v
        if v then
            _G.InstaInteractConnection = ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
                fireproximityprompt(prompt)
            end)
        else
            if _G.InstaInteractConnection then _G.InstaInteractConnection:Disconnect() end
        end
    end
})

TabUtil:Section({ Title = "Server" })

TabUtil:Button({
    Title = "Rejoin",
    Callback = function() TeleportService:Teleport(game.PlaceId, LP) end
})

TabUtil:Button({
    Title = "Server Hop",
    Callback = function()
        local ok, servers = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(
                "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            ))
        end)
        if not ok then
            WindUI:Notify({ Title = "Erro", Content = "Falha ao obter servidores", Duration = 3 })
            return
        end
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

    -- Noclip
    if noclip then
        for _, p in ipairs(_charPartsCache) do
            if p and p.Parent then p.CanCollide = false end
        end
    end

    -- God Mode / Lock HP
    if godMode then
        Humanoid.MaxHealth = math.huge
        Humanoid.Health    = Humanoid.MaxHealth
    elseif lockHP then
        Humanoid.Health    = Humanoid.MaxHealth
    end

    -- Anti Void
    if antiVoid and HRP.Position.Y < -80 then
        HRP.CFrame = HRP.CFrame + Vector3.new(0, 200, 0)
    end

    -- Anti Knockback
    if antiKB then
        HRP.Velocity = HRP.Velocity * Vector3.new(0.8, 0.9, 0.8)
    end

    -- Anti Fall (mantém HP ao cair)
    if antiFall and Humanoid then
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    end
end)

-- Auto-load: carrega a HubConfig padrão ao iniciar (os Flags garantem restauração dos valores)
pcall(function() hubConfig:Load() end)

-- Aplica o tema verde automaticamente ao iniciar
task.spawn(function()
    task.wait(1) -- aguarda a GUI renderizar completamente
    applyTheme()
end)

print("✅ Universal Hub WindUI carregado - By ZakyzVortex!")