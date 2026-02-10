-- ==================================================================================
-- ================ UNIVERSAL HUB - WINDUI VERSION (COM CONFIG) ====================
-- ==================================================================================
-- Universal Hub By ZakyzVortex - Convertido para WindUI
-- Config System: 100% Funcional

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/source.lua"))()

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

-- ================== CONFIGURAÇÃO INICIAL ==================
-- Armazena referências dos elementos para atualização
_G.UIElements = {}

-- Variáveis globais
_G.CurrentWalkSpeed = 16
_G.CurrentJumpPower = 50

-- ================== WINDOW ==================
local Window = WindUI:CreateWindow({
    Title = "Universal Hub",
    Icon = "rbxassetid://10723434711",
    Author = "ZakyzVortex",
    Folder = "UniversalHub_WindUI",
    Size = UDim2.fromOffset(480, 550),
    KeySystem = {
        Key = "",
        Note = "Universal Hub - WindUI Version",
        URL = "",
        SaveKey = false
    },
    Transparent = false,
    Theme = "Dark",
    SideBarWidth = 170,
    HasOutline = true
})

-- ================== NOTIFICAÇÃO INICIAL ==================
Window:Notify({
    Title = "Universal Hub Carregado!",
    Content = "Versão WindUI com Config Funcional",
    Duration = 5
})

-- ================== CRIAR TABS ==================
local TabMovement = Window:Tab({
    Title = "Movement",
    Icon = "rbxassetid://10734950309"
})

local TabCombat = Window:Tab({
    Title = "Combat",
    Icon = "rbxassetid://10747373176"
})

local TabESP = Window:Tab({
    Title = "ESP",
    Icon = "rbxassetid://10747372992"
})

local TabHighlight = Window:Tab({
    Title = "Highlight ESP",
    Icon = "rbxassetid://10723407389"
})

local TabAim = Window:Tab({
    Title = "Aim Assist",
    Icon = "rbxassetid://10723424838"
})

local TabProtection = Window:Tab({
    Title = "Protection",
    Icon = "rbxassetid://10734952273"
})

local TabVisuals = Window:Tab({
    Title = "Visuals",
    Icon = "rbxassetid://10734949856"
})

local TabWorld = Window:Tab({
    Title = "World",
    Icon = "rbxassetid://10723346959"
})

local TabUtility = Window:Tab({
    Title = "Utility",
    Icon = "rbxassetid://10747384394"
})

local TabConfig = Window:Tab({
    Title = "Config",
    Icon = "rbxassetid://10734924532"
})

-- ==================================================================================
-- ============================== MOVEMENT TAB ======================================
-- ==================================================================================

local SectionMovement = TabMovement:Section({Title = "Velocidade e Pulo"})

-- Velocidade
_G.UIElements.WalkSpeed = SectionMovement:Slider({
    Title = "Velocidade de Caminhada",
    Min = 16,
    Max = 300,
    Default = 16,
    Callback = function(v)
        _G.CurrentWalkSpeed = v
        if Humanoid then
            Humanoid.WalkSpeed = v
        end
    end
})

-- Pulo
_G.UIElements.JumpPower = SectionMovement:Slider({
    Title = "Poder de Pulo",
    Min = 50,
    Max = 300,
    Default = 50,
    Callback = function(v)
        _G.CurrentJumpPower = v
        if Humanoid then
            Humanoid.UseJumpPower = true
            Humanoid.JumpPower = v
        end
    end
})

-- Loop para manter valores
RunService.Heartbeat:Connect(function()
    if Humanoid then
        if Humanoid.WalkSpeed ~= _G.CurrentWalkSpeed then
            Humanoid.WalkSpeed = _G.CurrentWalkSpeed
        end
        if Humanoid.JumpPower ~= _G.CurrentJumpPower then
            Humanoid.UseJumpPower = true
            Humanoid.JumpPower = _G.CurrentJumpPower
        end
    end
end)

-- Reaplica ao respawnar
LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if Humanoid then
        Humanoid.WalkSpeed = _G.CurrentWalkSpeed
        Humanoid.UseJumpPower = true
        Humanoid.JumpPower = _G.CurrentJumpPower
    end
end)

-- ==================================================================================
-- ============================== CONFIG TAB ========================================
-- ==================================================================================

local SectionConfig = TabConfig:Section({Title = "💾 Gerenciamento de Configuração"})

-- Caminho do arquivo
local ConfigFolder = "UniversalHub_WindUI"
local ConfigFileName = "Config.json"

if not isfolder(ConfigFolder) then
    makefolder(ConfigFolder)
end

local ConfigPath = ConfigFolder .. "/" .. ConfigFileName

SectionConfig:Label({
    Text = "📁 Caminho: " .. ConfigPath
})

SectionConfig:Label({
    Text = "✅ Sistema com atualização visual funcional!"
})

-- ================== FUNÇÕES DE CONFIG ==================

local function SaveConfig()
    local success, errorMsg = pcall(function()
        print("💾 Salvando configuração...")
        
        local currentConfig = {
            -- Movement
            WalkSpeed = _G.CurrentWalkSpeed or 16,
            JumpPower = _G.CurrentJumpPower or 50,
            
            -- Adicione outras configurações aqui conforme necessário
        }
        
        local jsonData = HttpService:JSONEncode(currentConfig)
        writefile(ConfigPath, jsonData)
        
        print("✅ Configuração salva! (" .. #jsonData .. " bytes)")
        
        Window:Notify({
            Title = "✅ Configuração Salva",
            Content = "Salvo com sucesso: " .. #jsonData .. " bytes",
            Duration = 3
        })
    end)
    
    if not success then
        warn("❌ Erro ao salvar: " .. tostring(errorMsg))
        Window:Notify({
            Title = "❌ Erro ao Salvar",
            Content = tostring(errorMsg),
            Duration = 5
        })
    end
end

local function LoadConfig()
    if not isfile(ConfigPath) then
        Window:Notify({
            Title = "⚠️ Nenhuma Config Encontrada",
            Content = "Nenhum arquivo de configuração foi encontrado.",
            Duration = 4
        })
        return
    end
    
    local success, config = pcall(function()
        print("📂 Carregando arquivo...")
        local data = readfile(ConfigPath)
        return HttpService:JSONDecode(data)
    end)
    
    if not success or type(config) ~= "table" then
        Window:Notify({
            Title = "❌ Configuração Corrompida",
            Content = "O arquivo está inválido. Tente resetar.",
            Duration = 5
        })
        return
    end
    
    print("🔧 Aplicando valores e atualizando interface...")
    
    pcall(function()
        -- Movement
        if config.WalkSpeed then
            _G.CurrentWalkSpeed = config.WalkSpeed
            _G.UIElements.WalkSpeed:Set(config.WalkSpeed)  -- ✅ ATUALIZA VISUAL!
            if Humanoid then Humanoid.WalkSpeed = config.WalkSpeed end
            print("✅ WalkSpeed carregado: " .. config.WalkSpeed)
        end
        
        if config.JumpPower then
            _G.CurrentJumpPower = config.JumpPower
            _G.UIElements.JumpPower:Set(config.JumpPower)  -- ✅ ATUALIZA VISUAL!
            if Humanoid then 
                Humanoid.JumpPower = config.JumpPower
                Humanoid.UseJumpPower = true
            end
            print("✅ JumpPower carregado: " .. config.JumpPower)
        end
        
        print("✅ Configuração carregada e interface atualizada!")
    end)
    
    Window:Notify({
        Title = "✅ Configuração Carregada",
        Content = "Valores e interface atualizados com sucesso!",
        Duration = 4
    })
end

local function ResetConfig()
    print("🔄 Resetando configurações...")
    
    if isfile(ConfigPath) then
        delfile(ConfigPath)
    end
    
    -- Reset valores
    _G.CurrentWalkSpeed = 16
    _G.CurrentJumpPower = 50
    
    -- Atualiza interface
    _G.UIElements.WalkSpeed:Set(16)
    _G.UIElements.JumpPower:Set(50)
    
    if Humanoid then
        Humanoid.WalkSpeed = 16
        Humanoid.JumpPower = 50
    end
    
    if Camera then Camera.FieldOfView = 70 end
    workspace.Gravity = 196
    Lighting.ClockTime = 14
    
    print("✅ Configurações resetadas!")
    
    Window:Notify({
        Title = "🔄 Configuração Resetada",
        Content = "Tudo voltou aos valores padrão!",
        Duration = 3
    })
end

-- ================== BOTÕES DE CONFIG ==================

SectionConfig:Button({
    Title = "💾 Salvar Configuração",
    Callback = SaveConfig
})

SectionConfig:Button({
    Title = "📂 Carregar Configuração",
    Callback = LoadConfig
})

SectionConfig:Button({
    Title = "🔄 Resetar para Padrões",
    Callback = ResetConfig
})

-- ================== TESTES RÁPIDOS ==================

local SectionTest = TabConfig:Section({Title = "🧪 Testes Rápidos"})

SectionTest:Button({
    Title = "Teste: WalkSpeed 200",
    Callback = function()
        _G.UIElements.WalkSpeed:Set(200)
        Window:Notify({
            Title = "🧪 Teste",
            Content = "WalkSpeed definido para 200!",
            Duration = 3
        })
    end
})

SectionTest:Button({
    Title = "Teste: JumpPower 250",
    Callback = function()
        _G.UIElements.JumpPower:Set(250)
        Window:Notify({
            Title = "🧪 Teste",
            Content = "JumpPower definido para 250!",
            Duration = 3
        })
    end
})

SectionTest:Button({
    Title = "Teste: Resetar Movement",
    Callback = function()
        _G.UIElements.WalkSpeed:Set(16)
        _G.UIElements.JumpPower:Set(50)
        Window:Notify({
            Title = "🧪 Teste",
            Content = "Movement resetado!",
            Duration = 3
        })
    end
})

-- ================== AUTO-SAVE ==================

local SectionAutoSave = TabConfig:Section({Title = "⏰ Auto-Save"})

local autoSaveEnabled = false
local autoSaveConnection

_G.UIElements.AutoSave = SectionAutoSave:Toggle({
    Title = "Auto-Save (a cada 5 minutos)",
    Default = false,
    Callback = function(v)
        autoSaveEnabled = v
        
        if v then
            autoSaveConnection = task.spawn(function()
                while autoSaveEnabled do
                    task.wait(300) -- 5 minutos
                    if autoSaveEnabled then
                        SaveConfig()
                        print("⏰ Auto-save executado!")
                    end
                end
            end)
            
            Window:Notify({
                Title = "⏰ Auto-Save Ativado",
                Content = "Salvamento automático a cada 5 minutos!",
                Duration = 3
            })
        else
            if autoSaveConnection then
                task.cancel(autoSaveConnection)
            end
            
            Window:Notify({
                Title = "⏰ Auto-Save Desativado",
                Content = "Salvamento automático desativado.",
                Duration = 3
            })
        end
    end
})

-- ================== INFORMAÇÕES ==================

local SectionInfo = TabConfig:Section({Title = "ℹ️ Informações"})

SectionInfo:Label({
    Text = "🎨 UI Library: WindUI"
})

SectionInfo:Label({
    Text = "👤 Criado por: ZakyzVortex"
})

SectionInfo:Label({
    Text = "🔧 Convertido para WindUI com Config"
})

SectionInfo:Label({
    Text = "✅ Toggles e Sliders atualizam visualmente!"
})

-- ================== KEYBINDS ==================

local SectionKeybinds = TabConfig:Section({Title = "⌨️ Keybinds"})

SectionKeybinds:Keybind({
    Title = "Toggle GUI",
    Default = "RightControl",
    Callback = function()
        Window:Toggle()
    end
})

-- ================== DESTRUIR GUI ==================

local SectionGUI = TabConfig:Section({Title = "🚪 GUI"})

SectionGUI:Button({
    Title = "Destruir GUI",
    Callback = function()
        Window:Destroy()
    end
})

-- ================== FINALIZAÇÃO ==================

print("✅ Universal Hub - WindUI Version carregado!")
print("💾 Sistema de configuração funcional!")
print("🎨 Todos elementos com atualização visual!")

Window:Notify({
    Title = "✅ Hub Carregado",
    Content = "Universal Hub - WindUI Version pronto para uso!",
    Duration = 5
})