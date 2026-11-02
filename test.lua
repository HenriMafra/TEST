--[[
    ══════════════════════════════════════════════════════════════════════
    👻 GHOST HUB V27 [SWORDBURST 2 APEX EDITION - EXTREME POWER]
    ══════════════════════════════════════════════════════════════════════
    Construído fundindo o estado da arte de Bluu, Ugly & Oufguy (Sem Webhooks):
    ✔ Protocolo Oficial do Event: Combat + Skills ('Downward Smash', 'Infinity Slash', etc.)
    ✔ Infinite Stamina: Mantém Entity.Stamina em 100% ininterrupto.
    ✔ Blade Hitbox Extrema: Localiza Blade em CharacterItems[UserId] com TouchInstant.
    ✔ Auto-Dungeon Instantâneo: Inicia masmorras automaticamente (UniqueFloorTypes).
    ✔ Verificação Real de Vida: mob.Entity.Health.Value <= MinValue (zero engasgos).
    ✔ Glide CFrame Hiper-Rápido: 90 studs/s flutuando 4.2 studs acima do mob.
    ✔ Zero Webhooks / Zero Bloat: 100% focado em performance pura no Waydroid/PC.
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

-- Destrói instâncias anteriores
local TargetGuiParent = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
if TargetGuiParent:FindFirstChild("GhostHubApex") then
    TargetGuiParent.GhostHubApex:Destroy()
end
if TargetGuiParent:FindFirstChild("GhostHubSB2") then
    TargetGuiParent.GhostHubSB2:Destroy()
end
if TargetGuiParent:FindFirstChild("GhostRadarGui") then
    TargetGuiParent.GhostRadarGui:Destroy()
end

-- ====================================================================
-- ⚙️ CONFIGURAÇÕES PRINCIPAIS (APEX SETTINGS)
-- ====================================================================
local Settings = {
    AutoFarm = true,
    KillAura = true,
    SwordSkills = true,
    InfStamina = true,
    NoClip = true,
    AutoDungeon = true,
    MobESP = true,

    FlySpeed = 90,           -- Velocidade do glide (studs/s)
    FarmHeight = 4.2,        -- Altura acima do mob (imune a dano terrestre)
    AttackCooldown = 0.18,   -- Frequência máxima de ataque
    SkillCooldown = 1.2,     -- Intervalo entre habilidades especiais
    AuraRange = 25,          -- Raio do KillAura
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

    -- Fallback no próprio personagem
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
    if entity and entity:FindFirstChild("Health") then
        local hpVal = entity.Health.Value
        local minVal = entity.Health.MinValue or 0
        if hpVal <= minVal then return true end
    end

    -- Checagem via Humanoid clássico
    local hum = mob:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return true end

    return false
end

local function getMobHP(mob)
    local entity = mob:FindFirstChild("Entity")
    if entity and entity:FindFirstChild("Health") then
        return string.format("%d HP", math.floor(entity.Health.Value))
    end
    local hum = mob:FindFirstChildOfClass("Humanoid")
    if hum then
        return string.format("%d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth))
    end
    return "Vivo"
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
            if dist <= 3500 then
                table.insert(list, {
                    Model = m,
                    Name = m.Name,
                    Root = root,
                    Dist = dist,
                    HP = getMobHP(m),
                    IsBoss = (m.Parent and m.Parent.Name == "Bosses") or (string.find(m.Name:lower(), "boss") ~= nil),
                })
            end
        end)
    end

    if mobsFolder then
        for _, m in ipairs(mobsFolder:GetChildren()) do checkMob(m) end
    end
    if bossesFolder then
        for _, b in ipairs(bossesFolder:GetChildren()) do checkMob(b) end
    end

    table.sort(list, function(a, b) return a.Dist < b.Dist end)
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

    -- 4. Clique 3D na tela (WorldToViewportPoint)
    if mobRoot then
        local screenPos, onScreen = Camera:WorldToViewportPoint(mobRoot.Position)
        local cx = onScreen and screenPos.X or (Camera.ViewportSize.X * 0.5)
        local cy = onScreen and screenPos.Y or (Camera.ViewportSize.Y * 0.5)

        pcall(function()
            VIM:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
            task.wait(0.01)
            VIM:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
        end)
    end
end

-- ====================================================================
-- 📱 INTERFACE MOBILE HUD APEX V27
-- ====================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GhostHubApex"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999
ScreenGui.Parent = TargetGuiParent

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 400, 0, 310)
Main.Position = UDim2.new(0.5, -200, 0.5, -155)
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

local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1, 0, 0, 38)
Header.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)
makeDraggable(Main, Header)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ GHOST APEX V27 • SWORDBURST 2 GOD"
Title.TextColor3 = Color3.fromRGB(0, 255, 185)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 11
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 26, 0, 24)
CloseBtn.Position = UDim2.new(1, -32, 0, 7)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 70)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 11
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

-- Status Panel
local StatusPanel = Instance.new("Frame", Main)
StatusPanel.Size = UDim2.new(1, -20, 0, 66)
StatusPanel.Position = UDim2.new(0, 10, 0, 46)
StatusPanel.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
Instance.new("UICorner", StatusPanel).CornerRadius = UDim.new(0, 8)

local StatusText = Instance.new("TextLabel", StatusPanel)
StatusText.Size = UDim2.new(1, -16, 1, 0)
StatusText.Position = UDim2.new(0, 8, 0, 0)
StatusText.BackgroundTransparency = 1
StatusText.TextColor3 = Color3.fromRGB(0, 255, 185)
StatusText.Font = Enum.Font.GothamMedium
StatusText.TextSize = 10
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.TextWrapped = true
StatusText.Text = "🎯 Localizando monstros no mapa..."

-- Controles
local ControlsScroll = Instance.new("ScrollingFrame", Main)
ControlsScroll.Size = UDim2.new(1, -20, 1, -126)
ControlsScroll.Position = UDim2.new(0, 10, 0, 120)
ControlsScroll.BackgroundTransparency = 1
ControlsScroll.ScrollBarThickness = 3
ControlsScroll.CanvasSize = UDim2.new(0, 0, 0, 220)

local ListLayout = Instance.new("UIListLayout", ControlsScroll)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 6)

local function createToggle(name, initialVal, callback)
    local frame = Instance.new("Frame", ControlsScroll)
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -75, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(220, 225, 235)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 60, 0, 22)
    btn.Position = UDim2.new(1, -66, 0.5, -11)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9

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

    btn.MouseButton1Click:Connect(function()
        state = not state
        updateVisual()
        callback(state)
    end)

    updateVisual()
    return frame
end

createToggle("⚡ AUTO-FARM EXTREMO", Settings.AutoFarm, function(v) Settings.AutoFarm = v end)
createToggle("💥 KILL AURA (MULTIALVO)", Settings.KillAura, function(v) Settings.KillAura = v end)
createToggle("🗡️ USAR SWORD SKILLS", Settings.SwordSkills, function(v) Settings.SwordSkills = v end)
createToggle("🏃 ESTÂMINA INFINITA (100%)", Settings.InfStamina, function(v) Settings.InfStamina = v end)
createToggle("👻 NOCLIP (PAREDES/CHÃO)", Settings.NoClip, function(v) Settings.NoClip = v end)
createToggle("🏰 AUTO-INICIAR DUNGEONS", Settings.AutoDungeon, function(v) Settings.AutoDungeon = v end)

-- Botão Flutuante (Arrastável)
local FloatBtn = Instance.new("TextButton", ScreenGui)
FloatBtn.Size = UDim2.new(0, 115, 0, 36)
FloatBtn.Position = UDim2.new(0.02, 0, 0.20, 0)
FloatBtn.BackgroundColor3 = Color3.fromRGB(12, 15, 22)
FloatBtn.Text = "⚡ APEX V27"
FloatBtn.TextColor3 = Color3.fromRGB(0, 255, 185)
FloatBtn.Font = Enum.Font.GothamBlack
FloatBtn.TextSize = 11
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(0, 8)
local FStroke = Instance.new("UIStroke", FloatBtn)
FStroke.Color = Color3.fromRGB(0, 255, 185)
FStroke.Thickness = 1.5
makeDraggable(FloatBtn, FloatBtn)
FloatBtn.MouseButton1Click:Connect(function() Main.Visible = not Main.Visible end)

-- ====================================================================
-- 🔄 LOOPS DE SUPORTE (STAMINA, NOCLIP, DUNGEONS, ANTI-AFK)
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

-- NoClip & Estâmina Infinita no Stepped
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

    -- NoClip
    if Settings.NoClip and Settings.AutoFarm then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then
                p.CanCollide = false
            end
        end
    end
end)

-- ====================================================================
-- 🚀 MOTOR PRINCIPAL EM HEARTBEAT (GLIDE APEX & COMBATE)
-- ====================================================================
local lastScanTick = 0
local lastBladesTick = 0

RunService.Heartbeat:Connect(function(dt)
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not root then return end

    local now = os.clock()

    -- Varredura de Mobs a cada 0.35s
    if (now - lastScanTick) >= 0.35 then
        scanTargets()
        lastScanTick = now
    end

    -- Atualiza lâminas a cada 1.5s
    if (now - lastBladesTick) >= 1.5 then
        scanMyBlades()
        lastBladesTick = now
    end

    if not Settings.AutoFarm then
        StatusText.Text = "⏸️ Status: Auto-Farm Pausado. Clique no botão para ativar."
        return
    end

    local currentTarget = TargetCache[1]

    if currentTarget and currentTarget.Model and currentTarget.Model.Parent and not isMobDead(currentTarget.Model) then
        local myPos = char:GetPivot().Position
        local tRoot = currentTarget.Root
        local tPos = tRoot.Position

        -- Ponto flutuante seguro: 4.2 studs acima do mob
        local hoverPos = tPos + Vector3.new(0, Settings.FarmHeight, 0)
        local diff = hoverPos - myPos
        local dist = diff.Magnitude

        local elapsed = math.floor(now - Stats.StartTime)
        local mins = math.floor(elapsed / 60)
        local secs = elapsed % 60

        StatusText.Text = string.format(
            "🎯 Alvo: %s (%s)\n📏 Dist: %.1f studs | ⏱️ %02d:%02d | ⚔️ Mobs Abatidos: %d\n🗡️ Lâminas: %d ativas | ⚡ Estâmina: 100%%",
            currentTarget.Name,
            currentTarget.HP,
            dist,
            mins, secs,
            Stats.MobsSlain,
            #myBlades
        )

        -- GLIDE ULTRA-RÁPIDO (90 studs/s atravessando tudo)
        if dist > 1.2 then
            local moveDir = diff.Unit
            local step = math.min(dist, Settings.FlySpeed * dt)
            local newPos = myPos + (moveDir * step)

            root.CFrame = CFrame.lookAt(newPos, tPos)
            root.AssemblyLinearVelocity = Vector3.zero
        else
            root.CFrame = CFrame.lookAt(hoverPos, tPos)
            root.AssemblyLinearVelocity = Vector3.zero
        end

        -- Vira a câmera diretamente para o monstro
        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, tPos)

        -- ATAQUE SINCRONIZADO APEX
        if (now - lastAttackTick >= Settings.AttackCooldown) then
            if Settings.KillAura then
                -- Acerta o alvo e qualquer outro mob dentro do raio
                for _, mob in ipairs(TargetCache) do
                    if (myPos - mob.Root.Position).Magnitude <= Settings.AuraRange then
                        executeApexAttack(mob)
                    end
                end
            elseif dist <= Settings.AuraRange then
                executeApexAttack(currentTarget)
            end
            lastAttackTick = now
        end
    else
        -- Mob eliminado! Avança estatística e busca próximo
        if currentTarget and isMobDead(currentTarget.Model) then
            Stats.MobsSlain = Stats.MobsSlain + 1
            table.remove(TargetCache, 1)
        end
        StatusText.Text = "🔍 Procurando próximo monstro vivo no mapa..."
        if root then root.AssemblyLinearVelocity = Vector3.zero end
    end
end)

print("═════════════════════════════════════════════════════════════")
print("👻 [GHOST HUB V27 APEX] CARREGADO COM PODER EXTREMO!")
print("   • Protocolo Oficial: Combat + Sword Skills + Remotes")
print("   • Estâmina Infinita: ATIVA")
print("   • Lâminas e Hitbox: TouchInstant Ativo")
print("   • Glide CFrame: 90 studs/s")
print("═════════════════════════════════════════════════════════════")
