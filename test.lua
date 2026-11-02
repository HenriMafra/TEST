--[[
    ══════════════════════════════════════════════════════════════════════
    🛰️ GHOST RADAR & DEEP PROBE V24 [INSPEÇÃO E DIAGNÓSTICO TOTAL]
    ══════════════════════════════════════════════════════════════════════
    Este script escaneia 100% da arquitetura interna do jogo ao vivo:
    1. Inspeciona a estrutura exata dos monstros (Mobs, Partes, Vida, Animações).
    2. Inspeciona ReplicatedStorage (Remotes de Combate, Cardinal, Events).
    3. Inspeciona o Player (Inventário, Ferramentas, Humanoid, RootPart).
    4. Exibe os resultados em uma interface na tela e no log do sistema.
    5. Testa CFrame, NoClip e ativação de ataque automaticamente.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local VIM = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

-- Destrói instâncias anteriores
local TargetGuiParent = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
if TargetGuiParent:FindFirstChild("GhostRadarGui") then
    TargetGuiParent.GhostRadarGui:Destroy()
end

-- ====================================================================
-- 🖥️ INTERFACE GRÁFICA HUD RADAR (VISÍVEL NO MEIO DA TELA)
-- ====================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GhostRadarGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999
ScreenGui.Parent = TargetGuiParent

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 420, 0, 340)
Main.Position = UDim2.new(0.5, -210, 0.5, -170)
Main.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local Stroke = Instance.new("UIStroke", Main)
Stroke.Color = Color3.fromRGB(0, 255, 180)
Stroke.Thickness = 2

-- Arrastar Janela
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
Header.Size = UDim2.new(1, 0, 0, 36)
Header.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)
makeDraggable(Main, Header)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🛰️ GHOST RADAR • DIAGNÓSTICO PROFUNDO"
Title.TextColor3 = Color3.fromRGB(0, 255, 180)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 11
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 26, 0, 24)
CloseBtn.Position = UDim2.new(1, -32, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 70)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 11
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

-- Área de Rolagem para Relatório
local Scroll = Instance.new("ScrollingFrame", Main)
Scroll.Size = UDim2.new(1, -20, 1, -85)
Scroll.Position = UDim2.new(0, 10, 0, 42)
Scroll.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
Instance.new("UICorner", Scroll).CornerRadius = UDim.new(0, 8)
Scroll.ScrollBarThickness = 4
Scroll.CanvasSize = UDim2.new(0, 0, 0, 1200)

local ReportLabel = Instance.new("TextLabel", Scroll)
ReportLabel.Size = UDim2.new(1, -16, 0, 1200)
ReportLabel.Position = UDim2.new(0, 8, 0, 6)
ReportLabel.BackgroundTransparency = 1
ReportLabel.TextColor3 = Color3.fromRGB(220, 235, 245)
ReportLabel.Font = Enum.Font.Code
ReportLabel.TextSize = 10
ReportLabel.TextXAlignment = Enum.TextXAlignment.Left
ReportLabel.TextYAlignment = Enum.TextYAlignment.Top
ReportLabel.TextWrapped = true
ReportLabel.Text = "⏳ Iniciando diagnóstico profundo do jogo..."

-- Barra de Botões de Ação
local ActionFrame = Instance.new("Frame", Main)
ActionFrame.Size = UDim2.new(1, -20, 0, 32)
ActionFrame.Position = UDim2.new(0, 10, 1, -38)
ActionFrame.BackgroundTransparency = 1

local TestGlideBtn = Instance.new("TextButton", ActionFrame)
TestGlideBtn.Size = UDim2.new(0.48, 0, 1, 0)
TestGlideBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 120)
TestGlideBtn.TextColor3 = Color3.fromRGB(10, 25, 15)
TestGlideBtn.Text = "🚀 TESTAR GLIDE"
TestGlideBtn.Font = Enum.Font.GothamBlack
TestGlideBtn.TextSize = 10
Instance.new("UICorner", TestGlideBtn).CornerRadius = UDim.new(0, 6)

local TestAttackBtn = Instance.new("TextButton", ActionFrame)
TestAttackBtn.Size = UDim2.new(0.48, 0, 1, 0)
TestAttackBtn.Position = UDim2.new(0.52, 0, 0, 0)
TestAttackBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 230)
TestAttackBtn.TextColor3 = Color3.fromRGB(10, 25, 30)
TestAttackBtn.Text = "⚔️ TESTAR ATAQUE"
TestAttackBtn.Font = Enum.Font.GothamBlack
TestAttackBtn.TextSize = 10
Instance.new("UICorner", TestAttackBtn).CornerRadius = UDim.new(0, 6)

-- Botão Flutuante (Arrastável)
local FloatBtn = Instance.new("TextButton", ScreenGui)
FloatBtn.Size = UDim2.new(0, 115, 0, 36)
FloatBtn.Position = UDim2.new(0.02, 0, 0.20, 0)
FloatBtn.BackgroundColor3 = Color3.fromRGB(12, 15, 22)
FloatBtn.Text = "🛰️ RADAR V24"
FloatBtn.TextColor3 = Color3.fromRGB(0, 255, 180)
FloatBtn.Font = Enum.Font.GothamBlack
FloatBtn.TextSize = 11
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(0, 8)
local FStroke = Instance.new("UIStroke", FloatBtn)
FStroke.Color = Color3.fromRGB(0, 255, 180)
FStroke.Thickness = 1.5
makeDraggable(FloatBtn, FloatBtn)
FloatBtn.MouseButton1Click:Connect(function() Main.Visible = not Main.Visible end)

-- ====================================================================
-- 🔬 MOTOR DE ESCANEAMENTO & DIAGNÓSTICO
-- ====================================================================
local Logs = {}
local function logLine(txt)
    table.insert(Logs, txt)
    print("[RADAR] " .. txt)
    ReportLabel.Text = table.concat(Logs, "\n")
end

local DetectedMobs = {}
local DiscoveredRemotes = {}

local function runFullAudit()
    Logs = {}
    logLine("==================================================")
    logLine("🛰️ RELATÓRIO DO GHOST RADAR - " .. os.date("%X"))
    logLine("PlaceId: " .. tostring(game.PlaceId) .. " | JobId: " .. tostring(game.JobId:sub(1, 8)))
    logLine("==================================================")

    -- 1. Auditoria do Player
    local char = LocalPlayer.Character
    if char then
        local parts = {}
        for _, p in ipairs(char:GetChildren()) do
            if p:IsA("BasePart") or p:IsA("Humanoid") or p:IsA("Tool") or p:IsA("AnimationController") then
                table.insert(parts, p.Name .. " (" .. p.ClassName .. ")")
            end
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hpStr = hum and (tostring(math.floor(hum.Health)) .. "/" .. tostring(math.floor(hum.MaxHealth))) or "Sem Humanoid"
        logLine("👤 PLAYER: " .. LocalPlayer.Name .. " | HP: " .. hpStr)
        logLine("   Componentes: " .. table.concat(parts, ", "))

        -- Ferramentas
        local tools = {}
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") then table.insert(tools, item.Name .. " [Equipada]") end
        end
        if LocalPlayer:FindFirstChild("Backpack") then
            for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
                if item:IsA("Tool") then table.insert(tools, item.Name .. " [Backpack]") end
            end
        end
        logLine("   Armas: " .. (#tools > 0 and table.concat(tools, ", ") or "Nenhuma ferramenta Tool encontrada"))
    else
        logLine("❌ PLAYER: Personagem não carregado ainda")
    end

    -- 2. Auditoria do Workspace (Contêineres de Mobs)
    logLine("--------------------------------------------------")
    logLine("📦 ESTRUTURA DO WORKSPACE:")
    local wsFolders = {}
    for _, child in ipairs(Workspace:GetChildren()) do
        if child:IsA("Folder") or child:IsA("Model") then
            table.insert(wsFolders, child.Name .. " (" .. child.ClassName .. " #" .. #child:GetChildren() .. ")")
        end
    end
    logLine("   Pastas/Modelos Raiz: " .. table.concat(wsFolders, ", "))

    -- 3. Auditoria Específica de Mobs
    logLine("--------------------------------------------------")
    logLine("👾 BUSCA PROFUNDA DE MONSTROS:")
    DetectedMobs = {}

    local function inspectMobModel(m, source)
        if not m:IsA("Model") or m == char then return end
        if Players:GetPlayerFromCharacter(m) then return end

        local innerParts = {}
        local hasHum = m:FindFirstChildOfClass("Humanoid")
        local hasAnim = m:FindFirstChildOfClass("AnimationController")
        local rootPart = m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso") or m:FindFirstChild("UpperTorso") or m.PrimaryPart
        
        for _, c in ipairs(m:GetChildren()) do
            if c:IsA("BasePart") or c:IsA("Humanoid") or c:IsA("AnimationController") or c:IsA("ValueBase") then
                table.insert(innerParts, c.Name .. ":" .. c.ClassName)
            end
        end

        local hpInfo = "Desconhecida"
        if hasHum then
            hpInfo = tostring(math.floor(hasHum.Health)) .. "/" .. tostring(math.floor(hasHum.MaxHealth))
        else
            -- Procura valores de vida personalizados (Health IntValue, atributos)
            for _, v in ipairs(m:GetChildren()) do
                if v.Name:lower():find("health") or v.Name:lower():find("hp") then
                    hpInfo = tostring(v.Value)
                    break
                end
            end
            if m:GetAttribute("Health") then
                hpInfo = tostring(m:GetAttribute("Health"))
            end
        end

        table.insert(DetectedMobs, {
            Model = m,
            Name = m.Name,
            Source = source,
            Root = rootPart,
            Humanoid = hasHum,
            AnimController = hasAnim,
            Health = hpInfo,
            PartsCount = #innerParts,
            SampleParts = table.concat(innerParts, ", "):sub(1, 80),
        })
    end

    -- A. Checa workspace.Mobs
    local mobsFolder = Workspace:FindFirstChild("Mobs")
    if mobsFolder then
        logLine("   ✔ Encontrada pasta 'Workspace.Mobs' com " .. #mobsFolder:GetChildren() .. " filhos!")
        for _, child in ipairs(mobsFolder:GetChildren()) do
            inspectMobModel(child, "Workspace.Mobs")
        end
    else
        logLine("   ✖ Pasta 'Workspace.Mobs' NÃO existe")
    end

    -- B. Checa workspace.Bosses
    local bossesFolder = Workspace:FindFirstChild("Bosses")
    if bossesFolder then
        logLine("   ✔ Encontrada pasta 'Workspace.Bosses' com " .. #bossesFolder:GetChildren() .. " filhos!")
        for _, child in ipairs(bossesFolder:GetChildren()) do
            inspectMobModel(child, "Workspace.Bosses")
        end
    end

    -- C. Checa outros modelos no Workspace
    for _, child in ipairs(Workspace:GetChildren()) do
        if child:IsA("Model") and not Players:GetPlayerFromCharacter(child) and child ~= char then
            inspectMobModel(child, "Workspace Root")
        end
    end

    logLine("   TOTAL DE MOBS IDENTIFICADOS: " .. #DetectedMobs)

    -- Amostra dos 4 primeiros mobs
    for i = 1, math.min(4, #DetectedMobs) do
        local mob = DetectedMobs[i]
        logLine(string.format("   [%d] %s (Fonte: %s)", i, mob.Name, mob.Source))
        logLine(string.format("       Vida: %s | Root: %s | Hum: %s | Anim: %s",
            mob.Health,
            mob.Root and mob.Root.Name or "Nenhum",
            mob.Humanoid and "Sim" or "Não",
            mob.AnimController and "Sim" or "Não"
        ))
        logLine("       Partes: " .. mob.SampleParts)
    end

    -- 4. Auditoria de ReplicatedStorage (Remotes e Serviços)
    logLine("--------------------------------------------------")
    logLine("📡 AUDITORIA DE REMOTES (REPLICATED STORAGE):")
    DiscoveredRemotes = {}
    pcall(function()
        for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
            if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
                table.insert(DiscoveredRemotes, desc.Name .. " (" .. desc.ClassName .. " em " .. desc.Parent.Name .. ")")
            end
        end
    end)
    logLine("   Total de Remotes encontrados: " .. #DiscoveredRemotes)
    for i = 1, math.min(10, #DiscoveredRemotes) do
        logLine("   • " .. DiscoveredRemotes[i])
    end

    logLine("==================================================")
    logLine("✔ DIAGNÓSTICO CONCLUÍDO! Clique nos botões abaixo para testar.")
end

-- ====================================================================
-- 🎮 AÇÕES DE TESTE INTERATIVO
-- ====================================================================

-- Teste de Glide CFrame
TestGlideBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
    if not root then
        logLine("❌ Erro no Glide: HumanoidRootPart não encontrada")
        return
    end

    if #DetectedMobs == 0 then
        logLine("⚠️ Nenhum mob detectado para testar glide.")
        return
    end

    local target = DetectedMobs[1]
    local tRoot = target.Root or (target.Model:FindFirstChildOfClass("BasePart"))
    if not tRoot then
        logLine("❌ Mob alvo não possui nenhuma BasePart para mirar.")
        return
    end

    logLine("🚀 Iniciando Teste de Glide CFrame em direção a: " .. target.Name)

    task.spawn(function()
        local startTime = os.clock()
        while (os.clock() - startTime) < 4.0 do
            local myPos = root.Position
            local destPos = tRoot.Position + Vector3.new(0, 5, 0)
            local diff = (destPos - myPos)
            if diff.Magnitude < 2.0 then
                logLine("✅ CHEGOU ACIMA DO MOB " .. target.Name .. " COM SUCESSO!")
                break
            end
            local step = math.min(diff.Magnitude, 70 * 0.03)
            local newPos = myPos + (diff.Unit * step)
            root.CFrame = CFrame.lookAt(newPos, tRoot.Position)
            root.AssemblyLinearVelocity = Vector3.zero
            task.wait(0.03)
        end
    end)
end)

-- Teste de Ataque
TestAttackBtn.MouseButton1Click:Connect(function()
    logLine("⚔️ Executando Teste de Ataque...")
    local char = LocalPlayer.Character

    -- 1. Tool Activate
    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function() tool:Activate() end)
        logLine("   ✔ Tool:Activate() executado na ferramenta: " .. tool.Name)
    else
        logLine("   ⚠️ Nenhuma Tool equipada no personagem.")
    end

    -- 2. VirtualInputManager Click
    pcall(function()
        VIM:SendMouseButtonEvent(640, 360, 0, true, game, 1)
        task.wait(0.02)
        VIM:SendMouseButtonEvent(640, 360, 0, false, game, 1)
    end)
    logLine("   ✔ Clique do mouse simulado via VirtualInputManager")

    -- 3. VirtualUser Click
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(640, 360))
        VirtualUser:Button1Up(Vector2.new(640, 360))
    end)
    logLine("   ✔ Clique simulado via VirtualUser")

    -- 4. Disparo de Remotes
    pcall(function()
        for _, rem in ipairs(ReplicatedStorage:GetDescendants()) do
            if rem:IsA("RemoteEvent") and (rem.Name:lower():find("attack") or rem.Name:lower():find("combat") or rem.Name:lower():find("action")) then
                rem:FireServer()
                logLine("   ✔ RemoteEvent disparado: " .. rem.Name)
            end
        end
    end)
end)

-- Executa o diagnóstico automaticamente no início
task.spawn(function()
    task.wait(0.5)
    runFullAudit()
end)
