--[[
    ══════════════════════════════════════════════════════════════════════
    👻 GHOST HUB V23 [UNIVERSAL RPG & SWORDBURST 2 EDITION]
    ══════════════════════════════════════════════════════════════════════
    Auditado para Swordburst 2, Dungeon Rollers e todos os RPGs do Roblox:
    ✔ Detecção Universal de Mobs: Suporte nativo a workspace.Mobs (Snowgre, Icewhal, etc.)
    ✔ Janela Aberta no Início: Interface 100% visível na tela ao executar!
    ✔ AutoFarm Ativo Imediato: Voa até o mob e ataca sem precisar clicar em nada.
    ✔ Modo Flutuante (Above): Fica 4.5 studs acima do mob (bate sem tomar dano!).
    ✔ Ataque Multi-Camadas: VIM + VirtualUser + Tool:Activate + Remotes + TouchInterest.
    ✔ Zero Alvo em Players: Ignora 100% qualquer jogador real ou pet.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local VIM = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

-- Destrói instâncias anteriores para evitar duplicações
local TargetGuiParent = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
if TargetGuiParent:FindFirstChild("GhostHubUniversal") then
    TargetGuiParent.GhostHubUniversal:Destroy()
end

-- ====================================================================
-- ⚙️ CONFIGURAÇÕES PRINCIPAIS (START AUTOMÁTICO)
-- ====================================================================
local Settings = {
    AutoFarm = true,         -- Ativo imediatamente ao carregar!
    AutoAttack = true,       -- Ataca automaticamente
    KillAura = true,         -- Acerta múltiplos inimigos próximos
    AttackCooldown = 0.28,   -- Cadência rápida e segura contra anti-cheat
    AttackRange = 14,        -- Alcance de ataque em studs

    -- Movimentação & Posicionamento
    NoClip = true,
    FarmPosition = "Above",  -- "Above" (4.5 studs acima - Seguro contra dano), "Direct" (Frente), "Behind" (Atrás)
    FlySpeed = 80,           -- Velocidade do glide (studs/s)
    HeightOffset = 4.5,      -- Altura acima do mob
    StopOffset = 3.2,        -- Distância frontal/traseira

    -- Detecção de Alvos
    TargetDistance = 3000,   -- Raio de busca (cobre o mapa inteiro)
    MobESP = true,
    AutoEquip = true,
    AntiAFK = true,
}

-- ====================================================================
-- 🛡️ GESTÃO DINÂMICA DO PERSONAGEM (SEM YIELD OU DEADLOCK)
-- ====================================================================
local function getMyCharacter()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not hum or not root or hum.Health <= 0 then
        return nil, nil, nil
    end
    return char, hum, root
end

-- Anti AFK Permanente
if Settings.AntiAFK then
    LocalPlayer.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.zero)
        end)
    end)
end

-- NoClip Total (Atravessa Paredes e Chão)
RunService.Stepped:Connect(function()
    if not Settings.NoClip then return end
    local char = LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- Auto Equip de Armas
local function checkAndEquipWeapon()
    if not Settings.AutoEquip then return end
    local char, hum = getMyCharacter()
    if not char or not hum then return end

    if not char:FindFirstChildOfClass("Tool") then
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        if bp then
            local tool = bp:FindFirstChildOfClass("Tool")
            if tool then
                hum:EquipTool(tool)
            end
        end
    end
end

-- ====================================================================
-- 🎯 DETECÇÃO UNIVERSAL DE MOBS (SWORDBURST 2 & RPGs)
-- ====================================================================
local espObjects = {}
local TargetCache = {}

local function isPlayerEntity(model)
    if not model or not model:IsA("Model") then return true end
    if model == LocalPlayer.Character then return true end
    if Players:GetPlayerFromCharacter(model) then return true end
    if Players:FindFirstChild(model.Name) then return true end

    -- Checa modelos aninhados de avatares
    local ancestor = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
    if ancestor and (Players:GetPlayerFromCharacter(ancestor) or Players:FindFirstChild(ancestor.Name)) then
        return true
    end

    -- Ignora partes de câmera ou mapa
    if model.Name == "Camera" or model.Name == "Terrain" or model.Name == "Map" then
        return true
    end

    return false
end

local function applyESP(model)
    if not Settings.MobESP then return end
    if espObjects[model] then return end

    pcall(function()
        local hl = Instance.new("Highlight")
        hl.Name = "GhostUniversalESP"
        hl.Adornee = model
        hl.FillColor = Color3.fromRGB(255, 40, 75)
        hl.FillTransparency = 0.4
        hl.OutlineColor = Color3.fromRGB(0, 255, 200)
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = model
        espObjects[model] = hl
    end)
end

local function scanTargets()
    local _, _, myRoot = getMyCharacter()
    if not myRoot then return end

    local list = {}
    local myPos = myRoot.Position
    local visited = {}

    local function inspectModel(model)
        if not model or not model:IsA("Model") or visited[model] then return end
        visited[model] = true

        if isPlayerEntity(model) then return end

        local hum = model:FindFirstChildOfClass("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso") or model.PrimaryPart

        if hum and root and hum.Health > 0 then
            local dist = (myPos - root.Position).Magnitude
            if dist <= Settings.TargetDistance then
                local isBoss = (model:GetAttribute("IsBoss") == true)
                    or (model.Parent and model.Parent.Name == "Bosses")
                    or (string.find(model.Name:lower(), "boss") ~= nil)
                    or (string.find(model.Name:lower(), "chefe") ~= nil)

                table.insert(list, {
                    Model = model,
                    Root = root,
                    Humanoid = hum,
                    Dist = dist,
                    IsBoss = isBoss,
                })
                applyESP(model)
            end
        end
    end

    -- 1. Suporte Específico para Swordburst 2 (workspace.Mobs e workspace.Bosses)
    local sb2Mobs = Workspace:FindFirstChild("Mobs")
    if sb2Mobs then
        for _, mob in ipairs(sb2Mobs:GetChildren()) do
            inspectModel(mob)
        end
    end

    local sb2Bosses = Workspace:FindFirstChild("Bosses")
    if sb2Bosses then
        for _, boss in ipairs(sb2Bosses:GetChildren()) do
            inspectModel(boss)
        end
    end

    -- 2. Suporte para Dungeon Rollers e RPGs Genéricos (workspace:GetChildren)
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") then
            inspectModel(obj)
        elseif obj:IsA("Folder") and not (obj.Name == "Map" or obj.Name == "Terrain" or obj.Name == "Camera") then
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("Model") then
                    inspectModel(child)
                end
            end
        end
    end

    -- Limpa ESP de monstros mortos
    for model, hl in pairs(espObjects) do
        if not model.Parent or not model:FindFirstChildOfClass("Humanoid") or model:FindFirstChildOfClass("Humanoid").Health <= 0 then
            pcall(function() hl:Destroy() end)
            espObjects[model] = nil
        end
    end

    -- Ordena pelo monstro mais próximo
    table.sort(list, function(a, b) return a.Dist < b.Dist end)
    TargetCache = list
end

-- ====================================================================
-- ⚔️ MOTOR DE ATAQUE MULTI-MÉTODO (COMPATÍVEL COM TODOS OS JOGOS)
-- ====================================================================
local lastAttackTick = 0

-- Cache de remotes de ataque conhecidos
local cachedRemotes = {}
local function findCombatRemotes()
    if #cachedRemotes > 0 then return cachedRemotes end
    local list = {}
    pcall(function()
        for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
            if desc:IsA("RemoteEvent") then
                local name = desc.Name:lower()
                if name:find("attack") or name:find("combat") or name:find("swing") or name:find("hit") or name:find("damage") then
                    table.insert(list, desc)
                end
            end
        end
    end)
    cachedRemotes = list
    return list
end

local function executeUniversalAttack(targetMob)
    if not targetMob or not targetMob.Root then return end
    local char, hum, root = getMyCharacter()
    if not char or not hum or not root then return end

    -- 1. Mira frontal / alinhamento com o alvo
    local lookPos = Vector3.new(targetMob.Root.Position.X, root.Position.Y, targetMob.Root.Position.Z)
    root.CFrame = CFrame.lookAt(root.Position, lookPos)

    -- 2. Ativação nativa da Tool equipada
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function() tool:Activate() end)
    end

    -- 3. Clique via VirtualUser (Nativo Roblox - funciona em Swordburst 2)
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(640, 360))
        VirtualUser:Button1Up(Vector2.new(640, 360))
    end)

    -- 4. Clique via VirtualInputManager
    pcall(function()
        VIM:SendMouseButtonEvent(640, 360, 0, true, game, 1)
        VIM:SendMouseButtonEvent(640, 360, 0, false, game, 1)
    end)

    -- 5. Disparo de Remotes de Ataque (Dungeon Rollers / Cardinal)
    local remotes = findCombatRemotes()
    for _, rem in ipairs(remotes) do
        pcall(function() rem:FireServer() end)
        pcall(function() rem:FireServer(targetMob.Model) end)
        pcall(function() rem:FireServer(targetMob.Root) end)
    end

    -- 6. TouchInterest (Hitbox instantânea se suportado pelo executor)
    if firetouchinterest and targetMob.Root then
        local blade = tool and (tool:FindFirstChild("Blade") or tool:FindFirstChild("Handle") or tool:FindFirstChildOfClass("BasePart"))
        if blade then
            pcall(function()
                firetouchinterest(blade, targetMob.Root, 0)
                firetouchinterest(blade, targetMob.Root, 1)
            end)
        end
    end
end

-- ====================================================================
-- 📱 INTERFACE MOBILE HUD V23 (100% VISÍVEL NO START)
-- ====================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GhostHubUniversal"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = TargetGuiParent

-- Botão Flutuante (Arrastável)
local FloatBtn = Instance.new("TextButton", ScreenGui)
FloatBtn.Size = UDim2.new(0, 120, 0, 38)
FloatBtn.Position = UDim2.new(0.02, 0, 0.18, 0)
FloatBtn.BackgroundColor3 = Color3.fromRGB(12, 15, 22)
FloatBtn.Text = "👻 GHOST V23"
FloatBtn.TextColor3 = Color3.fromRGB(0, 255, 180)
FloatBtn.Font = Enum.Font.GothamBlack
FloatBtn.TextSize = 12
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(0, 8)
local FloatStroke = Instance.new("UIStroke", FloatBtn)
FloatStroke.Color = Color3.fromRGB(0, 255, 180)
FloatStroke.Thickness = 1.6

-- Janela Principal (VISÍVEL POR PADRÃO!)
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 380, 0, 310)
MainFrame.Position = UDim2.new(0.5, -190, 0.5, -155)
MainFrame.BackgroundColor3 = Color3.fromRGB(14, 16, 24)
MainFrame.Visible = true -- <<< ABERTA AUTOMATICAMENTE NO INÍCIO!
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(0, 255, 180)
MainStroke.Thickness = 2

-- Arrastar Elementos (Mouse & Touch Mobile)
local function makeDraggable(frame, handle)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
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

makeDraggable(FloatBtn, FloatBtn)

-- Header
local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 38)
Header.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)
makeDraggable(MainFrame, Header)

local HeaderTitle = Instance.new("TextLabel", Header)
HeaderTitle.Size = UDim2.new(1, -50, 1, 0)
HeaderTitle.Position = UDim2.new(0, 12, 0, 0)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Text = "⚡ GHOST HUB V23 • SWORDBURST 2 & RPG"
HeaderTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
HeaderTitle.Font = Enum.Font.GothamBlack
HeaderTitle.TextSize = 11
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 28, 0, 26)
CloseBtn.Position = UDim2.new(1, -34, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 55, 75)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 11
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

FloatBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Barra de Status do Alvo
local StatusPanel = Instance.new("Frame", MainFrame)
StatusPanel.Size = UDim2.new(1, -20, 0, 48)
StatusPanel.Position = UDim2.new(0, 10, 0, 44)
StatusPanel.BackgroundColor3 = Color3.fromRGB(22, 26, 38)
Instance.new("UICorner", StatusPanel).CornerRadius = UDim.new(0, 8)

local StatusText = Instance.new("TextLabel", StatusPanel)
StatusText.Size = UDim2.new(1, -14, 1, 0)
StatusText.Position = UDim2.new(0, 8, 0, 0)
StatusText.BackgroundTransparency = 1
StatusText.Text = "🎯 Status: Varrendo monstros no mapa..."
StatusText.TextColor3 = Color3.fromRGB(0, 255, 180)
StatusText.Font = Enum.Font.GothamMedium
StatusText.TextSize = 10
StatusText.TextWrapped = true
StatusText.TextXAlignment = Enum.TextXAlignment.Left

-- Container de Controles com Scroll
local ControlsScroll = Instance.new("ScrollingFrame", MainFrame)
ControlsScroll.Size = UDim2.new(1, -20, 1, -100)
ControlsScroll.Position = UDim2.new(0, 10, 0, 96)
ControlsScroll.BackgroundTransparency = 1
ControlsScroll.ScrollBarThickness = 3
ControlsScroll.CanvasSize = UDim2.new(0, 0, 0, 360)

local ListLayout = Instance.new("UIListLayout", ControlsScroll)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 6)

local function createToggle(name, initialVal, callback)
    local frame = Instance.new("Frame", ControlsScroll)
    frame.Size = UDim2.new(1, 0, 0, 34)
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
    btn.Size = UDim2.new(0, 60, 0, 24)
    btn.Position = UDim2.new(1, -66, 0.5, -12)
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

createToggle("⚡ AUTO FARM (MOB HUNTER)", Settings.AutoFarm, function(v) Settings.AutoFarm = v end)
createToggle("⚔️ AUTO ATAQUE CONTÍNUO", Settings.AutoAttack, function(v) Settings.AutoAttack = v end)
createToggle("💥 KILL AURA (MULTIALVO)", Settings.KillAura, function(v) Settings.KillAura = v end)
createToggle("👻 NOCLIP (ATRAVESSA PAREDES)", Settings.NoClip, function(v) Settings.NoClip = v end)
createToggle("👁️ MOB ESP (DESTAQUE VISUAL)", Settings.MobESP, function(v) Settings.MobESP = v end)
createToggle("🗡️ AUTO EQUIPAR ARMA", Settings.AutoEquip, function(v) Settings.AutoEquip = v end)

-- Seletor de Posição
local PosFrame = Instance.new("Frame", ControlsScroll)
PosFrame.Size = UDim2.new(1, 0, 0, 34)
PosFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
Instance.new("UICorner", PosFrame).CornerRadius = UDim.new(0, 6)

local PosLabel = Instance.new("TextLabel", PosFrame)
PosLabel.Size = UDim2.new(0.5, 0, 1, 0)
PosLabel.Position = UDim2.new(0, 10, 0, 0)
PosLabel.BackgroundTransparency = 1
PosLabel.Text = "📍 POSIÇÃO TÁTICA"
PosLabel.TextColor3 = Color3.fromRGB(220, 225, 235)
PosLabel.Font = Enum.Font.GothamBold
PosLabel.TextSize = 10
PosLabel.TextXAlignment = Enum.TextXAlignment.Left

local PosBtn = Instance.new("TextButton", PosFrame)
PosBtn.Size = UDim2.new(0, 110, 0, 24)
PosBtn.Position = UDim2.new(1, -116, 0.5, -12)
PosBtn.BackgroundColor3 = Color3.fromRGB(35, 42, 58)
PosBtn.TextColor3 = Color3.fromRGB(0, 255, 180)
PosBtn.Font = Enum.Font.GothamBold
PosBtn.TextSize = 9
PosBtn.Text = "ACIMA (ABOVE 4.5)"
Instance.new("UICorner", PosBtn).CornerRadius = UDim.new(0, 6)

local positions = { "Above", "Direct", "Behind" }
local posIndex = 1
PosBtn.MouseButton1Click:Connect(function()
    posIndex = (posIndex % #positions) + 1
    Settings.FarmPosition = positions[posIndex]
    if Settings.FarmPosition == "Above" then
        PosBtn.Text = "ACIMA (ABOVE 4.5)"
    elseif Settings.FarmPosition == "Direct" then
        PosBtn.Text = "FRENTE (DIRECT)"
    else
        PosBtn.Text = "ATRÁS (BEHIND)"
    end
end)

-- ====================================================================
-- 🚀 MOTOR PRINCIPAL EM HEARTBEAT (GLIDE CFRAME & COMBATE)
-- ====================================================================
local lastScanTick = 0

RunService.Heartbeat:Connect(function(dt)
    local char, hum, root = getMyCharacter()
    if not char or not hum or not root then return end

    local now = os.clock()

    -- 1. Varredura a cada 0.3s
    if (now - lastScanTick) >= 0.30 then
        scanTargets()
        checkAndEquipWeapon()
        lastScanTick = now
    end

    if not Settings.AutoFarm then
        StatusText.Text = "⏸️ Status: Auto Farm Pausado. Clique no botão para ativar."
        return
    end

    local currentTarget = TargetCache[1]

    if currentTarget and currentTarget.Root and currentTarget.Humanoid.Health > 0 then
        local tRoot = currentTarget.Root
        local tHum = currentTarget.Humanoid
        local myPos = root.Position
        local tPos = tRoot.Position
        local dist = (myPos - tPos).Magnitude

        StatusText.Text = string.format("🎯 Alvo: %s\n❤️ Vida: %d/%d | 📏 Dist: %.1f studs",
            currentTarget.Model.Name,
            math.floor(tHum.Health),
            math.floor(tHum.MaxHealth),
            dist
        )

        -- Ponto de Destino Tático
        local destCFrame
        if Settings.FarmPosition == "Above" then
            -- Flutua 4.5 studs acima do monstro (mob não alcança você!)
            destCFrame = CFrame.new(tPos + Vector3.new(0, Settings.HeightOffset, 0))
        elseif Settings.FarmPosition == "Direct" then
            -- Frente a 3.2 studs
            local dir = (myPos - tPos)
            local flat = Vector3.new(dir.X, 0, dir.Z)
            if flat.Magnitude > 0.1 then
                destCFrame = CFrame.new(tPos + (flat.Unit * Settings.StopOffset))
            else
                destCFrame = CFrame.new(tPos + Vector3.new(0, 0, Settings.StopOffset))
            end
        else
            -- Atrás a 3.2 studs
            destCFrame = tRoot.CFrame * CFrame.new(0, 0, Settings.StopOffset)
        end

        local destPos = destCFrame.Position
        local distToDest = (myPos - destPos).Magnitude

        -- GLIDE ULTRA-SUAVE VIA CFRAME (Atravessa Paredes e Chão)
        if distToDest > 1.2 then
            local moveDir = (destPos - myPos).Unit
            local step = math.min(distToDest, Settings.FlySpeed * dt)
            local newPos = myPos + (moveDir * step)

            root.CFrame = CFrame.lookAt(newPos, Vector3.new(tPos.X, newPos.Y, tPos.Z))
            root.AssemblyLinearVelocity = Vector3.zero
        else
            root.CFrame = CFrame.lookAt(destPos, Vector3.new(tPos.X, destPos.Y, tPos.Z))
            root.AssemblyLinearVelocity = Vector3.zero
        end

        -- ATAQUE SINCRONIZADO
        if Settings.AutoAttack and (now - lastAttackTick >= Settings.AttackCooldown) then
            if Settings.KillAura then
                for _, mob in ipairs(TargetCache) do
                    if (root.Position - mob.Root.Position).Magnitude <= Settings.AttackRange then
                        executeUniversalAttack(mob)
                    end
                end
            elseif dist <= Settings.AttackRange then
                executeUniversalAttack(currentTarget)
            end
            lastAttackTick = now
        end
    else
        StatusText.Text = "🔍 Procurando monstros vivos no mapa..."
        root.AssemblyLinearVelocity = Vector3.zero
    end
end)

print("═════════════════════════════════════════════════════════════")
print("👻 [GHOST HUB V23] CARREGADO COM SUCESSO!")
print("   • Suporte Nativo: Swordburst 2 (Mobs) & RPGs")
print("   • UI: Visível na Tela")
print("   • Farm: Ativo Automaticamente")
print("═════════════════════════════════════════════════════════════")
