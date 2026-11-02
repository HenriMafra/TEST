--[[
    ══════════════════════════════════════════════════════════════════════
    👻 GHOST HUB V30 [SWORDBURST 2 APEX - TRUE UNDERGROUND & GHOST BLADES]
    ══════════════════════════════════════════════════════════════════════
    Aprimoramentos de Precisão de Posição & Invisibilidade de Armas:
    ✔ Verdadeiro Subterrâneo via GetBoundingBox():
      - Calcula a base exata dos pés do mob e posiciona o jogador a -5.2 studs
        abaixo do chão (nunca mais fica dentro do mob!).
    ✔ Espadas e Armas 100% Invisíveis:
      - Aplica transparência total em Workspace.CharacterItems[UserId]
        (Lâminas, cabos, partículas, trails e brilhos completamente invisíveis).
    ✔ Kill Aura Global do Mapa Inteiro:
      - Dispara ataques simultâneos contra TODOS os mobs vivos do mapa no tick de combate.
      - Super Warp Subterrâneo (320 studs/s) para satisfazer qualquer checagem de distância do servidor.
    ✔ Anti-Gravidade e Anti-Void:
      - BodyVelocity com força 1e9 impede qualquer queda no void.
    ✔ Prioridade Menor Vida + Desempate por Distância.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local VIM = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Auto Login se estiver no menu inicial
if game.PlaceId == 659222129 then
    pcall(function()
        ReplicatedStorage:WaitForChild("Function"):InvokeServer("Login")
    end)
    return
end

-- Limpa instâncias anteriores do HUD
local TargetGuiParent = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
for _, name in ipairs({ "GhostHubApex", "GhostHubSB2", "GhostRadarGui" }) do
    local old = TargetGuiParent:FindFirstChild(name)
    if old then old:Destroy() end
end

-- ====================================================================
-- ⚙️ CONFIGURAÇÕES PRINCIPAIS (APEX V30)
-- ====================================================================
local Settings = {
    AutoFarm = true,          -- ATIVADO por padrão (caça e bate imediatamente!)
    Underground = true,       -- Farma debaixo da terra (100% abaixo do piso)
    FarmDepth = 5.2,          -- Profundidade abaixo da SOLA DOS PÉS do mob (studs)
    FarmHeight = 4.2,         -- Altura caso o modo aéreo seja ativado
    Invisibility = true,      -- Personagem E ESPADAS transparentes/invisíveis
    SoloOnly = false,         -- Desligado por padrão para funcionar em servidores públicos
    KillAura = true,          -- Kill Aura multialvo
    MapWideAura = true,       -- Alcance do Kill Aura cobre o mapa inteiro
    AuraRange = 5000,         -- Raio em studs
    MaxMultiTargets = 25,     -- Quantidade máxima de mobs atacados simultaneamente por ciclo
    SwordSkills = true,       -- Uso de habilidades nativas de espada
    InfStamina = true,        -- 100% de estâmina ininterrupta
    NoClip = true,            -- Atravessa chão, paredes e pedras
    AutoDungeon = true,       -- Inicia masmorras automaticamente
    MobESP = true,            -- Destaque visual dos monstros

    FlySpeed = 320,           -- Velocidade máxima de deslocamento CFrame (studs/s)
    AttackCooldown = 0.12,    -- Frequência de ataque ultra-rápida
    SkillCooldown = 1.0,      -- Intervalo de habilidades especiais
}

local Stats = {
    MobsSlain = 0,
    StartTime = os.clock(),
    CurrentTarget = nil,
}

-- Remotes Oficiais do Swordburst 2
local Event = ReplicatedStorage:WaitForChild("Event")
local Function = ReplicatedStorage:WaitForChild("Function")

-- Habilidades de Espada Oficiais
local SwordSkillsList = {
    "Downward Smash",
    "Leaping Slash",
    "Piercing Dash",
    "Whirlwind Spin",
    "Sweeping Strike",
    "Infinity Slash",
}

local rng = Random.new()
local function genKey()
    return string.format("%d%d%d", rng:NextInteger(1, 9), rng:NextInteger(1, 9), rng:NextInteger(1, 9))
end

-- ====================================================================
-- 🗡️ GERENCIADOR DE LÂMINAS & HITBOX (CHARACTER ITEMS)
-- ====================================================================
local myBlades = {}

local function scanMyBlades()
    myBlades = {}
    local charItems = Workspace:FindFirstChild("CharacterItems")
    if charItems then
        local userFolder = charItems:FindFirstChild(tostring(LocalPlayer.UserId))
        if userFolder then
            for _, weapon in ipairs(userFolder:GetChildren()) do
                if weapon.Name == "RightWeapon" or weapon.Name == "LeftWeapon" then
                    local tool = weapon:FindFirstChild("Tool") or weapon:FindFirstChildOfClass("Model") or weapon
                    local blade = tool and (tool:FindFirstChild("Blade") or tool:FindFirstChild("Handle") or tool:FindFirstChildOfClass("BasePart"))
                    if blade and blade:IsA("BasePart") then
                        blade.CanTouch = true
                        table.insert(myBlades, blade)
                    end
                end
            end
        end
    end

    -- Fallback nas armas dentro do próprio personagem
    local char = LocalPlayer.Character
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and (p.Name:lower():find("blade") or p.Name:lower():find("sword") or p.Name == "RightGrip") then
                p.CanTouch = true
                table.insert(myBlades, p)
            end
        end
    end
end

-- ====================================================================
-- 💀 DETECÇÃO E FILTRAGEM AVANÇADA DE MOBS
-- ====================================================================
local function isMobDead(mob)
    if not mob or not mob.Parent then return true end

    -- Checagem oficial de Swordburst 2 via Entity.Health
    local entity = mob:FindFirstChild("Entity")
    if entity and entity:FindFirstChild("Health") and entity.Health:IsA("ValueBase") then
        local hpVal = entity.Health.Value
        local minVal = entity.Health.MinValue or 0
        if hpVal <= minVal then return true end
    end

    -- Checagem via Humanoid clássico
    local hum = mob:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return true end

    return false
end

-- Obtém o valor numérico de vida para cálculo e ordenação
local function getNumericHP(mob)
    if not mob or not mob.Parent then return 9999999 end
    local entity = mob:FindFirstChild("Entity")
    if entity then
        local hpVal = entity:FindFirstChild("Health")
        if hpVal and hpVal:IsA("ValueBase") then
            return hpVal.Value
        end
    end
    local hum = mob:FindFirstChildOfClass("Humanoid")
    if hum then
        return hum.Health
    end
    return 9999999
end

local function getMobRoot(mob)
    return mob:FindFirstChild("HumanoidRootPart")
        or mob.PrimaryPart
        or mob:FindFirstChild("Torso")
        or mob:FindFirstChild("UpperTorso")
        or mob:FindFirstChild("Head")
        or mob:FindFirstChildOfClass("MeshPart")
        or mob:FindFirstChildOfClass("BasePart")
end

local TargetCache = {}

local function scanTargets()
    local char = LocalPlayer.Character
    if not char then return end
    local myPos = char:GetPivot().Position

    local list = {}
    local mobsFolder = Workspace:FindFirstChild("Mobs")
    local bossesFolder = Workspace:FindFirstChild("Bosses")

    local function checkMob(m)
        pcall(function()
            if not m or not m:IsA("Model") or not m.Parent then return end
            if Players:GetPlayerFromCharacter(m) then return end
            if isMobDead(m) then return end

            local root = getMobRoot(m)
            if not root then return end

            local dist = (myPos - root.Position).Magnitude
            local hp = getNumericHP(m)

            table.insert(list, {
                Model = m,
                Name = m.Name,
                Root = root,
                Dist = dist,
                HP = hp,
                HPText = string.format("%d HP", math.floor(hp)),
                IsBoss = (m.Parent and m.Parent.Name == "Bosses") or (string.find(m.Name:lower(), "boss") ~= nil),
            })
        end)
    end

    if mobsFolder then
        for _, m in ipairs(mobsFolder:GetChildren()) do checkMob(m) end
    end
    if bossesFolder then
        for _, b in ipairs(bossesFolder:GetChildren()) do checkMob(b) end
    end

    -- 🎯 REGRA SOLICITADA: Menor vida primeiro. Se tiverem a mesma vida, o mais perto primeiro!
    table.sort(list, function(a, b)
        if math.abs(a.HP - b.HP) > 0.05 then
            return a.HP < b.HP
        else
            return a.Dist < b.Dist
        end
    end)
    TargetCache = list
end

-- ====================================================================
-- ⚡ MOTOR DE ATAQUE EXTREMO (REMOTE COMBAT + TOUCH + SKILLS)
-- ====================================================================
local lastAttackTick = 0
local lastSkillTick = 0
local skillIndex = 1

local function executeApexAttack(targetMob)
    if not targetMob or isMobDead(targetMob.Model) then return end
    local mobModel = targetMob.Model
    local mobRoot = targetMob.Root
    if not mobModel or not mobRoot then return end

    -- 1. Disparo do Remote Oficial do Swordburst 2 (Combat Attack)
    pcall(function()
        Event:FireServer(
            "Combat",
            { "\204", "\214", "\177", "\251" },
            {
                "Attack",
                nil,
                mobModel,
                genKey()
            }
        )
    end)

    -- 2. Habilidade Especial de Espada (Sword Skills)
    if Settings.SwordSkills and (os.clock() - lastSkillTick >= Settings.SkillCooldown) then
        local currentSkill = SwordSkillsList[skillIndex]
        skillIndex = (skillIndex % #SwordSkillsList) + 1
        pcall(function()
            Event:FireServer("Skills", { "UseSkill", currentSkill, { Direction = Vector3.new(0, 0, 0) } })
            Event:FireServer(
                "Combat",
                { "\204", "\214", "\177", "\251" },
                {
                    "Attack",
                    currentSkill,
                    mobModel,
                    genKey()
                }
            )
        end)
        lastSkillTick = os.clock()
    end

    -- 3. TouchInterest Instantâneo nas Lâminas (Dano de Contato Físico)
    if firetouchinterest and mobRoot then
        for _, blade in ipairs(myBlades) do
            if blade and blade.Parent then
                pcall(function()
                    firetouchinterest(blade, mobRoot, 0)
                    firetouchinterest(blade, mobRoot, 1)
                end)
            end
        end
    end

    -- 4. Clique 3D na tela se o mob estiver no campo de visão
    local screenPos, onScreen = Camera:WorldToViewportPoint(mobRoot.Position)
    if onScreen then
        pcall(function()
            VIM:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, true, game, 1)
            task.wait(0.005)
            VIM:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, false, game, 1)
        end)
    end
end

-- ====================================================================
-- 📱 INTERFACE MOBILE HUD APEX V30 (TOUCH & DESKTOP ULTRA-RESPONSIVO)
-- ====================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GhostHubApex"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999
ScreenGui.Parent = TargetGuiParent

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 390, 0, 340)
Main.Position = UDim2.new(0.5, -195, 0.5, -170)
Main.BackgroundColor3 = Color3.fromRGB(11, 13, 19)
Main.Visible = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local Stroke = Instance.new("UIStroke", Main)
Stroke.Color = Color3.fromRGB(0, 255, 185)
Stroke.Thickness = 2

local function makeDraggable(frame, handle)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Cabeçalho
local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1, 0, 0, 38)
Header.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)
makeDraggable(Main, Header)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "👻 GHOST APEX V30 • TRUE UNDERGROUND"
Title.TextColor3 = Color3.fromRGB(0, 255, 185)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 11
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 28, 0, 26)
CloseBtn.Position = UDim2.new(1, -34, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 70)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 11
CloseBtn.Active = true
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
local function closeMenu() Main.Visible = false end
CloseBtn.Activated:Connect(closeMenu)
CloseBtn.MouseButton1Click:Connect(closeMenu)

-- 🔘 BOTÃO MASTER GIGANTE (INICIAR / PAUSAR AUTO-FARM)
local MasterFarmBtn = Instance.new("TextButton", Main)
MasterFarmBtn.Size = UDim2.new(1, -20, 0, 36)
MasterFarmBtn.Position = UDim2.new(0, 10, 0, 44)
MasterFarmBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 110)
MasterFarmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MasterFarmBtn.Text = "⏹️ PAUSAR AUTO-FARM (RODANDO)"
MasterFarmBtn.Font = Enum.Font.GothamBold
MasterFarmBtn.TextSize = 11
MasterFarmBtn.Active = true
Instance.new("UICorner", MasterFarmBtn).CornerRadius = UDim.new(0, 8)
local MasterStroke = Instance.new("UIStroke", MasterFarmBtn)
MasterStroke.Color = Color3.fromRGB(0, 255, 185)
MasterStroke.Thickness = 1.5

local function updateMasterVisual()
    if Settings.AutoFarm then
        MasterFarmBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 110)
        MasterFarmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        MasterFarmBtn.Text = "⏹️ PAUSAR AUTO-FARM (RODANDO)"
        MasterStroke.Color = Color3.fromRGB(0, 255, 185)
    else
        MasterFarmBtn.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
        MasterFarmBtn.TextColor3 = Color3.fromRGB(200, 210, 225)
        MasterFarmBtn.Text = "▶️ INICIAR AUTO-FARM (PAUSADO)"
        MasterStroke.Color = Color3.fromRGB(70, 80, 105)
    end
end

local masterDebounce = false
local function toggleMasterFarm()
    if masterDebounce then return end
    masterDebounce = true
    Settings.AutoFarm = not Settings.AutoFarm
    updateMasterVisual()
    task.wait(0.2)
    masterDebounce = false
end
MasterFarmBtn.Activated:Connect(toggleMasterFarm)
MasterFarmBtn.MouseButton1Click:Connect(toggleMasterFarm)

-- Painel de Status Detalhado
local StatusPanel = Instance.new("Frame", Main)
StatusPanel.Size = UDim2.new(1, -20, 0, 68)
StatusPanel.Position = UDim2.new(0, 10, 0, 86)
StatusPanel.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
Instance.new("UICorner", StatusPanel).CornerRadius = UDim.new(0, 8)

local StatusText = Instance.new("TextLabel", StatusPanel)
StatusText.Size = UDim2.new(1, -16, 1, 0)
StatusText.Position = UDim2.new(0, 8, 0, 0)
StatusText.BackgroundTransparency = 1
StatusText.TextColor3 = Color3.fromRGB(0, 255, 185)
StatusText.Font = Enum.Font.GothamMedium
StatusText.TextSize = 9.5
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.TextWrapped = true
StatusText.Text = "🎯 Localizando monstros no mapa..."

-- Lista de Opções Rolável (Com AutomaticCanvasSize para suportar todos os botões)
local ControlsScroll = Instance.new("ScrollingFrame", Main)
ControlsScroll.Size = UDim2.new(1, -20, 1, -166)
ControlsScroll.Position = UDim2.new(0, 10, 0, 160)
ControlsScroll.BackgroundTransparency = 1
ControlsScroll.ScrollBarThickness = 4
ControlsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ControlsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local ListLayout = Instance.new("UIListLayout", ControlsScroll)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 6)

-- Gerador de Toggles com suporte mobile 100% garantido (.Activated + debounced tap na linha inteira)
local function createToggle(name, initialVal, callback)
    local frame = Instance.new("TextButton", ControlsScroll)
    frame.Size = UDim2.new(1, 0, 0, 34)
    frame.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
    frame.Text = ""
    frame.AutoButtonColor = false
    frame.Active = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -85, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(220, 225, 235)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 9.5
    label.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 72, 0, 24)
    btn.Position = UDim2.new(1, -78, 0.5, -12)
    btn.Active = true
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local state = initialVal
    local function updateVisual()
        if state then
            btn.BackgroundColor3 = Color3.fromRGB(0, 200, 120)
            btn.TextColor3 = Color3.fromRGB(10, 25, 15)
            btn.Text = "ATIVO"
        else
            btn.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
            btn.TextColor3 = Color3.fromRGB(160, 170, 185)
            btn.Text = "DESLIGADO"
        end
    end

    local debounce = false
    local function toggle()
        if debounce then return end
        debounce = true
        state = not state
        updateVisual()
        callback(state)
        task.wait(0.2)
        debounce = false
    end

    -- Escuta no botão e na linha inteira (facilita o toque com os dedos no Waydroid)
    btn.Activated:Connect(toggle)
    btn.MouseButton1Click:Connect(toggle)
    frame.Activated:Connect(toggle)
    frame.MouseButton1Click:Connect(toggle)

    updateVisual()
    return frame
end

-- Toggles Solicitados
createToggle("🕳️ MODO SUBTERRÂNEO (ABAIXO DO CHÃO)", Settings.Underground, function(v) Settings.Underground = v end)
createToggle("👻 INVISIBILIDADE (AVATAR & ESPADAS)", Settings.Invisibility, function(v) Settings.Invisibility = v end)
createToggle("💥 KILL AURA (MAPA INTEIRO)", Settings.KillAura, function(v) Settings.KillAura = v end)
createToggle("🗡️ USAR SWORD SKILLS NATIVAS", Settings.SwordSkills, function(v) Settings.SwordSkills = v end)
createToggle("🏃 ESTÂMINA INFINITA (100%)", Settings.InfStamina, function(v) Settings.InfStamina = v end)
createToggle("🛡️ FARM APENAS SOZINHO (SOLO)", Settings.SoloOnly, function(v) Settings.SoloOnly = v end)
createToggle("👻 NOCLIP (PAREDES/CHÃO)", Settings.NoClip, function(v) Settings.NoClip = v end)
createToggle("🏰 AUTO-INICIAR DUNGEONS", Settings.AutoDungeon, function(v) Settings.AutoDungeon = v end)

-- Botão Flutuante (Arrastável e com clique confiável via .Activated)
local FloatBtn = Instance.new("TextButton", ScreenGui)
FloatBtn.Size = UDim2.new(0, 115, 0, 36)
FloatBtn.Position = UDim2.new(0.02, 0, 0.20, 0)
FloatBtn.BackgroundColor3 = Color3.fromRGB(12, 15, 22)
FloatBtn.Text = "👻 APEX V30"
FloatBtn.TextColor3 = Color3.fromRGB(0, 255, 185)
FloatBtn.Font = Enum.Font.GothamBlack
FloatBtn.TextSize = 11
FloatBtn.Active = true
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(0, 8)
local FStroke = Instance.new("UIStroke", FloatBtn)
FStroke.Color = Color3.fromRGB(0, 255, 185)
FStroke.Thickness = 1.5
makeDraggable(FloatBtn, FloatBtn)

local function toggleGuiVisibility()
    Main.Visible = not Main.Visible
end
FloatBtn.Activated:Connect(toggleGuiVisibility)
FloatBtn.MouseButton1Click:Connect(toggleGuiVisibility)

-- ====================================================================
-- 🔄 LOOPS DE SUPORTE (INVISIBILIDADE COMPLETA, NOCLIP, ESTÂMINA)
-- ====================================================================

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end)
end)

-- Auto Start Dungeons
if Settings.AutoDungeon and Workspace:GetAttribute("DungeonFloor") then
    pcall(function()
        Event:FireServer("UniqueFloorTypes", { "Dungeons", "Start" })
    end)
end

-- Invisibilidade Total (Avatar + Espadas no CharacterItems), NoClip & Estâmina no Stepped
RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end

    -- Estâmina Infinita (Bluu & Oufguy Method)
    if Settings.InfStamina then
        local entity = char:FindFirstChild("Entity")
        if entity and entity:FindFirstChild("Stamina") then
            entity.Stamina.Value = 100
        end
        pcall(function() Event:FireServer("Actions", { "Sprint", "Disabled" }) end)
    end

    -- NoClip: Apenas se AutoFarm estiver ATIVO e caçando!
    if Settings.NoClip and Settings.AutoFarm then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then
                p.CanCollide = false
            end
        end
    else
        -- Quando pausado, mantém colisão para ficar firme no chão sem afundar
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and (p.Name == "HumanoidRootPart" or p.Name == "Torso" or p.Name == "UpperTorso" or p.Name == "LowerTorso") then
                p.CanCollide = true
            end
        end
    end

    -- 👻 INVISIBILIDADE TOTAL: AVATAR + ESPADAS / ARMAS
    if Settings.Invisibility then
        -- 1. Peças do Avatar
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                p.Transparency = 1
            elseif p:IsA("Decal") or p:IsA("Texture") then
                p.Transparency = 1
            elseif p:IsA("ParticleEmitter") or p:IsA("Trail") or p:IsA("Beam") or p:IsA("Highlight") then
                p.Enabled = false
            end
        end

        -- 2. Espadas e Armas no CharacterItems (Swordburst 2 guarda as armas aqui!)
        local charItems = Workspace:FindFirstChild("CharacterItems")
        if charItems then
            local userFolder = charItems:FindFirstChild(tostring(LocalPlayer.UserId))
            if userFolder then
                for _, p in ipairs(userFolder:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p.Transparency = 1
                    elseif p:IsA("Decal") or p:IsA("Texture") then
                        p.Transparency = 1
                    elseif p:IsA("ParticleEmitter") or p:IsA("Trail") or p:IsA("Beam") or p:IsA("Highlight") then
                        p.Enabled = false
                    end
                end
            end
        end
    end
end)

-- Varredura inicial imediata de alvos e armas
task.spawn(function()
    task.wait(0.2)
    scanMyBlades()
    scanTargets()
end)

-- ====================================================================
-- 🚀 MOTOR PRINCIPAL EM HEARTBEAT (UNDERGROUND GLIDE & MULTI-AURA)
-- ====================================================================
local lastScanTick = 0
local lastBladesTick = 0

RunService.Heartbeat:Connect(function(dt)
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not root then return end

    local now = os.clock()

    -- 🛡️ ANTI-GRAVIDADE ABSOLUTA: Trava o boneco no ar ou terra impedindo queda no void
    local bv = root:FindFirstChild("ApexAntiGrav")
    if Settings.AutoFarm then
        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.Name = "ApexAntiGrav"
            bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            bv.Velocity = Vector3.zero
            bv.Parent = root
        end
    else
        if bv then bv:Destroy() end
    end

    -- Varredura rápida de Mobs a cada 0.2s
    if (now - lastScanTick) >= 0.20 then
        scanTargets()
        lastScanTick = now
    end

    -- Atualiza lâminas ativas a cada 1.5s
    if (now - lastBladesTick) >= 1.5 then
        scanMyBlades()
        lastBladesTick = now
    end

    -- 🛡️ CHECAGEM SOLO-ONLY: Se houver outro jogador no servidor E a opção estiver ativa, pausa
    local otherPlayers = #Players:GetPlayers() - 1
    if Settings.SoloOnly and otherPlayers > 0 then
        StatusText.Text = string.format(
            "🛡️ MODO SEGURO: %d outros jogadores no servidor!\n⏸️ Farm pausado por segurança.",
            otherPlayers
        )
        root.AssemblyLinearVelocity = Vector3.zero
        return
    end

    -- ⏸️ PAUSA DO AUTO-FARM
    if not Settings.AutoFarm then
        StatusText.Text = "⏸️ Status: Auto-Farm Pausado.\nClique no botão verde acima para iniciar a caçada!"
        root.AssemblyLinearVelocity = Vector3.zero
        return
    end

    local currentTarget = TargetCache[1]

    if currentTarget and currentTarget.Model and currentTarget.Model.Parent and not isMobDead(currentTarget.Model) then
        local myPos = char:GetPivot().Position
        local tModel = currentTarget.Model

        -- 🕳️ CALCULA A SOLA DOS PÉS DO MOB VIA GetBoundingBox():
        -- Garante que o boneco fique 100% DEBAIXO DA TERRA e NUNCA dentro do mob!
        local mobCFrame, mobSize = tModel:GetBoundingBox()
        local mobFloorY = mobCFrame.Position.Y - (mobSize.Y * 0.5)
        local mobCenterX = mobCFrame.Position.X
        local mobCenterZ = mobCFrame.Position.Z

        local targetGoalPos
        if Settings.Underground then
            -- Exatamente 5.2 studs abaixo dos pés do mob (completamente sob o solo!)
            targetGoalPos = Vector3.new(mobCenterX, mobFloorY - Settings.FarmDepth, mobCenterZ)
        else
            -- Modo aéreo: 4.2 studs acima da cabeça do mob
            local mobTopY = mobCFrame.Position.Y + (mobSize.Y * 0.5)
            targetGoalPos = Vector3.new(mobCenterX, mobTopY + Settings.FarmHeight, mobCenterZ)
        end

        local diff = targetGoalPos - myPos
        local dist = diff.Magnitude

        local elapsed = math.floor(now - Stats.StartTime)
        local mins = math.floor(elapsed / 60)
        local secs = elapsed % 60

        StatusText.Text = string.format(
            "🎯 Alvo Menor Vida: %s (%s)\n📏 Dist: %.1f studs | ⏱️ %02d:%02d | ⚔️ Abatidos: %d\n🕳️ Posição: %s | 👥 Servidor: %s\n🗡️ Lâminas: %d | ⚡ Estâmina: 100%%",
            currentTarget.Name,
            currentTarget.HPText,
            dist,
            mins, secs,
            Stats.MobsSlain,
            Settings.Underground and string.format("Subterrâneo (-%.1f studs)", Settings.FarmDepth) or "Aéreo (+4 studs)",
            otherPlayers == 0 and "SOLO" or string.format("%d Players", otherPlayers + 1),
            #myBlades
        )

        -- ⚡ DESLOCAMENTO CFrame ULTRA-RÁPIDO COM RESGATE DO VOID
        if dist > 50 then
            -- Teleporte instantâneo se estiver muito longe ou voltando do void
            root.CFrame = CFrame.lookAt(targetGoalPos, mobCFrame.Position)
            root.AssemblyLinearVelocity = Vector3.zero
        elseif dist > 1.2 then
            local moveDir = diff.Unit
            local step = math.min(dist, Settings.FlySpeed * dt)
            local newPos = myPos + (moveDir * step)

            root.CFrame = CFrame.lookAt(newPos, mobCFrame.Position)
            root.AssemblyLinearVelocity = Vector3.zero
        else
            root.CFrame = CFrame.lookAt(targetGoalPos, mobCFrame.Position)
            root.AssemblyLinearVelocity = Vector3.zero
        end

        -- Câmera apontada para o mob
        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, mobCFrame.Position)

        -- 💥 ATAQUE SINCRONIZADO APEX (KILL AURA GLOBAL NO MAPA INTEIRO)
        if (now - lastAttackTick >= Settings.AttackCooldown) then
            if Settings.KillAura then
                local multiCount = 0
                -- Dispara contra todos os monstros vivos da dungeon simultaneamente
                for _, mob in ipairs(TargetCache) do
                    if not isMobDead(mob.Model) then
                        local mDist = (myPos - mob.Root.Position).Magnitude
                        if Settings.MapWideAura or mDist <= Settings.AuraRange then
                            executeApexAttack(mob)
                            multiCount = multiCount + 1
                            if multiCount >= Settings.MaxMultiTargets then break end
                        end
                    end
                end
            else
                executeApexAttack(currentTarget)
            end
            lastAttackTick = now
        end
    else
        -- Mob eliminado! Avança estatística e busca próximo com menor vida
        if currentTarget and isMobDead(currentTarget.Model) then
            Stats.MobsSlain = Stats.MobsSlain + 1
            table.remove(TargetCache, 1)
        end
        StatusText.Text = "🔍 Procurando próximo monstro vivo com menor vida..."
        if root then root.AssemblyLinearVelocity = Vector3.zero end
    end
end)

print("═════════════════════════════════════════════════════════════")
print("👻 [GHOST HUB V30 TRUE UNDERGROUND] CARREGADO COM SUCESSO!")
print("   • Subterrâneo Perfeito: -5.2 studs abaixo da sola dos pés")
print("   • Invisibilidade Total: Avatar + Espadas (CharacterItems)")
print("   • Kill Aura Global: Ataca até 25 mobs simultâneos no mapa")
print("   • Super Warp CFrame: 320 studs/s")
print("   • Anti-Gravidade Absoluta: ATIVA")
print("═════════════════════════════════════════════════════════════")
