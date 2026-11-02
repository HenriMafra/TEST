--[[
    ══════════════════════════════════════════════════════════════════════
    🛰️ GHOST RADAR & COMBAT PROBE V25 [SWORDBURST 2 TOTALMENTE DESVENDADO]
    ══════════════════════════════════════════════════════════════════════
    ✔ Correção Fatal: v:IsA("ValueBase") e m:GetPivot().Position (100% blindado contra erros).
    ✔ Detecção das 42 Entidades de Workspace.Mobs (Snowgre, Icewhal, Angry Snowman).
    ✔ Reconhecimento de Armas Customizadas (Welds, RightGrip, Modelos anexados ao corpo).
    ✔ Auditoria Completa de Remotes do ReplicatedStorage (Cardinal & Combat).
    ✔ Teste de Glide Imediato: Voa suavemente para cima do mob mais próximo.
    ✔ Teste de Ataque: Simula corte em coordenadas limpas fora da interface gráfica.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
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
-- 🖥️ INTERFACE GRÁFICA HUD RADAR V25
-- ====================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GhostRadarGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999
ScreenGui.Parent = TargetGuiParent

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 430, 0, 360)
Main.Position = UDim2.new(0.5, -215, 0.5, -180)
Main.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
Main.Visible = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local Stroke = Instance.new("UIStroke", Main)
Stroke.Color = Color3.fromRGB(0, 255, 180)
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
Header.Size = UDim2.new(1, 0, 0, 36)
Header.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)
makeDraggable(Main, Header)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ GHOST RADAR V25 • SWORDBURST 2 AUTO-PROBE"
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

local Scroll = Instance.new("ScrollingFrame", Main)
Scroll.Size = UDim2.new(1, -20, 1, -95)
Scroll.Position = UDim2.new(0, 10, 0, 42)
Scroll.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
Instance.new("UICorner", Scroll).CornerRadius = UDim.new(0, 8)
Scroll.ScrollBarThickness = 4
Scroll.CanvasSize = UDim2.new(0, 0, 0, 1600)

local ReportLabel = Instance.new("TextLabel", Scroll)
ReportLabel.Size = UDim2.new(1, -16, 0, 1600)
ReportLabel.Position = UDim2.new(0, 8, 0, 6)
ReportLabel.BackgroundTransparency = 1
ReportLabel.TextColor3 = Color3.fromRGB(220, 235, 245)
ReportLabel.Font = Enum.Font.Code
ReportLabel.TextSize = 10
ReportLabel.TextXAlignment = Enum.TextXAlignment.Left
ReportLabel.TextYAlignment = Enum.TextYAlignment.Top
ReportLabel.TextWrapped = true
ReportLabel.Text = "⏳ Escaneando arquitetura de Swordburst 2..."

local ActionFrame = Instance.new("Frame", Main)
ActionFrame.Size = UDim2.new(1, -20, 0, 40)
ActionFrame.Position = UDim2.new(0, 10, 1, -48)
ActionFrame.BackgroundTransparency = 1

local TestGlideBtn = Instance.new("TextButton", ActionFrame)
TestGlideBtn.Size = UDim2.new(0.31, 0, 1, 0)
TestGlideBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 120)
TestGlideBtn.TextColor3 = Color3.fromRGB(10, 25, 15)
TestGlideBtn.Text = "🚀 GLIDE NO MOB"
TestGlideBtn.Font = Enum.Font.GothamBlack
TestGlideBtn.TextSize = 10
Instance.new("UICorner", TestGlideBtn).CornerRadius = UDim.new(0, 6)

local TestAttackBtn = Instance.new("TextButton", ActionFrame)
TestAttackBtn.Size = UDim2.new(0.31, 0, 1, 0)
TestAttackBtn.Position = UDim2.new(0.34, 0, 0, 0)
TestAttackBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 230)
TestAttackBtn.TextColor3 = Color3.fromRGB(10, 25, 30)
TestAttackBtn.Text = "⚔️ TESTAR ATAQUE"
TestAttackBtn.Font = Enum.Font.GothamBlack
TestAttackBtn.TextSize = 10
Instance.new("UICorner", TestAttackBtn).CornerRadius = UDim.new(0, 6)

local AutoFarmToggleBtn = Instance.new("TextButton", ActionFrame)
AutoFarmToggleBtn.Size = UDim2.new(0.31, 0, 1, 0)
AutoFarmToggleBtn.Position = UDim2.new(0.68, 0, 0, 0)
AutoFarmToggleBtn.BackgroundColor3 = Color3.fromRGB(220, 160, 30)
AutoFarmToggleBtn.TextColor3 = Color3.fromRGB(30, 20, 10)
AutoFarmToggleBtn.Text = "⚡ AUTO-FARM ON"
AutoFarmToggleBtn.Font = Enum.Font.GothamBlack
AutoFarmToggleBtn.TextSize = 10
Instance.new("UICorner", AutoFarmToggleBtn).CornerRadius = UDim.new(0, 6)

-- Botão Flutuante (Arrastável)
local FloatBtn = Instance.new("TextButton", ScreenGui)
FloatBtn.Size = UDim2.new(0, 115, 0, 36)
FloatBtn.Position = UDim2.new(0.02, 0, 0.20, 0)
FloatBtn.BackgroundColor3 = Color3.fromRGB(12, 15, 22)
FloatBtn.Text = "🛰️ RADAR V25"
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
-- 🔬 MOTOR DE AUDITORIA BLINDADO (ZERO CRASHES)
-- ====================================================================
local Logs = {}
local function logLine(txt)
    table.insert(Logs, txt)
    print("[RADAR] " .. txt)
    ReportLabel.Text = table.concat(Logs, "\n")
end

local DetectedMobs = {}
local DiscoveredRemotes = {}
local isAutoFarming = false

local function runFullAudit()
    Logs = {}
    logLine("==================================================")
    logLine("🛰️ RELATÓRIO DO GHOST RADAR V25 - " .. os.date("%X"))
    logLine("Jogo: Swordburst 2 | PlaceId: " .. tostring(game.PlaceId))
    logLine("==================================================")

    -- 1. Auditoria do Player e Armas
    local char = LocalPlayer.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hpStr = hum and (tostring(math.floor(hum.Health)) .. "/" .. tostring(math.floor(hum.MaxHealth))) or "100/100"
        logLine("👤 PLAYER: " .. LocalPlayer.Name .. " | HP: " .. hpStr)

        -- Detecta armas equipadas (Custom Welds / RightGrip / Models)
        local equippedWeapons = {}
        for _, p in ipairs(char:GetChildren()) do
            if p:IsA("Tool") then
                table.insert(equippedWeapons, "Tool: " .. p.Name)
            elseif p:IsA("Model") or p.Name:lower():find("sword") or p.Name:lower():find("blade") or p.Name:lower():find("weapon") or p.Name:lower():find("katana") then
                table.insert(equippedWeapons, "Modelo: " .. p.Name)
            elseif p.Name == "RightGrip" or p.Name == "RightGripAttachment" then
                table.insert(equippedWeapons, "Grip: " .. p.Name)
            end
        end
        if #equippedWeapons > 0 then
            logLine("   ⚔️ Armas Detectadas: " .. table.concat(equippedWeapons, ", "))
        else
            logLine("   ⚔️ Nenhuma Tool tradicional (Arma anexada via Motor6D/RightGrip)")
        end
    else
        logLine("❌ PLAYER: Personagem ainda não carregado")
    end

    -- 2. Varredura Total de Mobs (Suporte a Workspace.Mobs)
    logLine("--------------------------------------------------")
    logLine("👾 AUDITORIA DE MONSTROS (WORKSPACE.MOBS):")
    DetectedMobs = {}

    local myPos = (char and char:GetPivot().Position) or Vector3.zero

    local function parseMob(m, sourceName)
        pcall(function()
            if not m:IsA("Model") or m == char then return end
            if Players:GetPlayerFromCharacter(m) then return end

            local mobPivot = m:GetPivot()
            local mobPos = mobPivot.Position
            local dist = (myPos - mobPos).Magnitude

            -- Encontra a melhor parte de colisão / alvo
            local targetPart = m.PrimaryPart
                or m:FindFirstChild("HumanoidRootPart")
                or m:FindFirstChild("Torso")
                or m:FindFirstChild("UpperTorso")
                or m:FindFirstChild("Head")
                or m:FindFirstChildOfClass("MeshPart")
                or m:FindFirstChildOfClass("BasePart")

            -- Vida do monstro
            local hpStr = "Ativo"
            local hum = m:FindFirstChildOfClass("Humanoid")
            if hum then
                hpStr = tostring(math.floor(hum.Health)) .. "/" .. tostring(math.floor(hum.MaxHealth))
            else
                for _, child in ipairs(m:GetChildren()) do
                    if child:IsA("ValueBase") and (child.Name:lower():find("health") or child.Name:lower():find("hp")) then
                        hpStr = tostring(child.Value)
                        break
                    end
                end
            end

            table.insert(DetectedMobs, {
                Model = m,
                Name = m.Name,
                Source = sourceName,
                Part = targetPart,
                Position = mobPos,
                Dist = dist,
                Health = hpStr,
                HasHumanoid = (hum ~= nil),
            })
        end)
    end

    local mobsFolder = Workspace:FindFirstChild("Mobs")
    if mobsFolder then
        logLine("   ✔ Pasta 'Workspace.Mobs' encontrada com " .. #mobsFolder:GetChildren() .. " filhos!")
        for _, child in ipairs(mobsFolder:GetChildren()) do
            parseMob(child, "Workspace.Mobs")
        end
    end

    local bossesFolder = Workspace:FindFirstChild("Bosses")
    if bossesFolder then
        for _, child in ipairs(bossesFolder:GetChildren()) do
            parseMob(child, "Workspace.Bosses")
        end
    end

    -- Ordena por proximidade
    table.sort(DetectedMobs, function(a, b) return a.Dist < b.Dist end)

    logLine("   TOTAL DE MOBS CADASTRADOS NO RADAR: " .. #DetectedMobs)

    for i = 1, math.min(5, #DetectedMobs) do
        local mob = DetectedMobs[i]
        logLine(string.format("   [%d] %s | Dist: %.1f studs | HP: %s | Part: %s",
            i, mob.Name, mob.Dist, mob.Health, mob.Part and mob.Part.Name or "Pivot"
        ))
    end

    -- 3. Auditoria de Remotes do ReplicatedStorage
    logLine("--------------------------------------------------")
    logLine("📡 AUDITORIA DE REMOTES (REPLICATED STORAGE):")
    DiscoveredRemotes = {}
    pcall(function()
        for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
            if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
                table.insert(DiscoveredRemotes, desc)
            end
        end
    end)
    logLine("   Total de Remotes encontrados: " .. #DiscoveredRemotes)
    for i = 1, math.min(10, #DiscoveredRemotes) do
        local r = DiscoveredRemotes[i]
        logLine("   • " .. r.Name .. " (" .. r.ClassName .. " em " .. r.Parent.Name .. ")")
    end

    logLine("==================================================")
    logLine("✔ ESCANEAMENTO 100% CONCLUÍDO! Clique nos botões para testar.")
end

-- ====================================================================
-- 🚀 TESTE DE GLIDE NO MOB MAIS PRÓXIMO
-- ====================================================================
TestGlideBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if not char then
        logLine("❌ Erro: Personagem não encontrado.")
        return
    end

    if #DetectedMobs == 0 then
        logLine("⚠️ Nenhum mob cadastrado. Rodando novo escaneamento...")
        runFullAudit()
        if #DetectedMobs == 0 then
            logLine("❌ Ainda nenhum mob encontrado.")
            return
        end
    end

    local target = DetectedMobs[1]
    logLine("🚀 Glidando diretamente para: " .. target.Name .. " (Dist: " .. math.floor(target.Dist) .. " studs)")

    -- Ativa NoClip temporário
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end

    task.spawn(function()
        local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
        local startTime = os.clock()
        while (os.clock() - startTime) < 5.0 do
            local currentPos = char:GetPivot().Position
            -- Ponto tático: 4.5 studs acima do mob
            local targetPos = (target.Part and target.Part.Position or target.Position) + Vector3.new(0, 4.5, 0)
            local diff = targetPos - currentPos
            local dist = diff.Magnitude

            if dist < 1.5 then
                logLine("✅ CHEGOU COM SUCESSO ACIMA DO " .. target.Name .. "!")
                if root then root.AssemblyLinearVelocity = Vector3.zero end
                break
            end

            local step = math.min(dist, 85 * 0.03)
            local newPos = currentPos + (diff.Unit * step)

            if root then
                root.CFrame = CFrame.lookAt(newPos, targetPos - Vector3.new(0, 4.5, 0))
                root.AssemblyLinearVelocity = Vector3.zero
            else
                char:PivotTo(CFrame.lookAt(newPos, targetPos))
            end

            task.wait(0.03)
        end
    end)
end)

-- ====================================================================
-- ⚔️ TESTE DE ATAQUE NO SWORDBURST 2
-- ====================================================================
TestAttackBtn.MouseButton1Click:Connect(function()
    logLine("⚔️ Executando Teste de Ataque Multi-Método...")
    local char = LocalPlayer.Character

    -- 1. VirtualInputManager fora da tela do GUI (coordenada 100, 100)
    pcall(function()
        VIM:SendMouseButtonEvent(100, 100, 0, true, game, 1)
        task.wait(0.02)
        VIM:SendMouseButtonEvent(100, 100, 0, false, game, 1)
        logLine("   ✔ Clique simulado em (100, 100) via VirtualInputManager")
    end)

    -- 2. VirtualUser Click
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(100, 100))
        VirtualUser:Button1Up(Vector2.new(100, 100))
        logLine("   ✔ Clique simulado via VirtualUser")
    end)

    -- 3. Tool Activate (caso exista)
    pcall(function()
        local tool = char and char:FindFirstChildOfClass("Tool")
        if tool then
            tool:Activate()
            logLine("   ✔ Tool:Activate() executado na ferramenta: " .. tool.Name)
        end
    end)

    -- 4. Disparo de Remotes de Combate encontrados
    pcall(function()
        for _, r in ipairs(DiscoveredRemotes) do
            local name = r.Name:lower()
            if name:find("attack") or name:find("hit") or name:find("combat") or name:find("action") or name:find("damage") or name:find("swing") then
                r:FireServer()
                logLine("   ✔ Remote disparado: " .. r.Name)
            end
        end
    end)
end)

-- ====================================================================
-- ⚡ AUTO-FARM AUTOMÁTICO (LOOP CONTÍNUO)
-- ====================================================================
AutoFarmToggleBtn.MouseButton1Click:Connect(function()
    isAutoFarming = not isAutoFarming
    if isAutoFarming then
        AutoFarmToggleBtn.Text = "⚡ AUTO-FARM ATIVO"
        AutoFarmToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        logLine("🟢 AUTO-FARM LIGADO! Caçando monstros...")
    else
        AutoFarmToggleBtn.Text = "⚡ AUTO-FARM OFF"
        AutoFarmToggleBtn.BackgroundColor3 = Color3.fromRGB(220, 160, 30)
        logLine("🔴 AUTO-FARM PAUSADO.")
    end
end)

-- Loop de NoClip
RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if char and isAutoFarming then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then
                p.CanCollide = false
            end
        end
    end
end)

-- Loop de Caça Contínuo
task.spawn(function()
    while true do
        task.wait(0.15)
        if isAutoFarming then
            local char = LocalPlayer.Character
            local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
            
            if char and root and #DetectedMobs > 0 then
                local target = DetectedMobs[1]
                if target and target.Model and target.Model.Parent then
                    local myPos = char:GetPivot().Position
                    local targetPos = (target.Part and target.Part.Position or target.Position) + Vector3.new(0, 4.5, 0)
                    local diff = targetPos - myPos
                    local dist = diff.Magnitude

                    -- Glide suave
                    local step = math.min(dist, 80 * 0.15)
                    local newPos = myPos + (diff.Unit * step)
                    root.CFrame = CFrame.lookAt(newPos, targetPos - Vector3.new(0, 4.5, 0))
                    root.AssemblyLinearVelocity = Vector3.zero

                    -- Se estiver perto (<= 8 studs), ataca!
                    if dist <= 8.0 then
                        pcall(function()
                            VIM:SendMouseButtonEvent(100, 100, 0, true, game, 1)
                            task.wait(0.01)
                            VIM:SendMouseButtonEvent(100, 100, 0, false, game, 1)
                        end)
                        pcall(function()
                            VirtualUser:CaptureController()
                            VirtualUser:Button1Down(Vector2.new(100, 100))
                            VirtualUser:Button1Up(Vector2.new(100, 100))
                        end)
                    end
                else
                    table.remove(DetectedMobs, 1)
                    if #DetectedMobs == 0 then
                        runFullAudit()
                    end
                end
            end
        end
    end
end)

-- Executa o diagnóstico inicial
task.spawn(function()
    task.wait(0.6)
    runFullAudit()
end)
