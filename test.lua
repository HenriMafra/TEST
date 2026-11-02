 -- [[ GHOST HUB V19 - AUTO FARM COM HUD COMPLETO ]] --
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local PathfindingService = game:GetService("PathfindingService")
    local Workspace = game:GetService("Workspace")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")

    local LocalPlayer = Players.LocalPlayer
    local rng = Random.new()
    
    -- Onde injetar a GUI com segurança em qualquer executor
    local TargetGuiParent = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")

    -- Remove instâncias antigas para não sobrepor telas
    if TargetGuiParent:FindFirstChild("GhostFarmHub") then
        TargetGuiParent.GhostFarmHub:Destroy()
    end

    -- ====================================================================
    -- CONFIGURAÇÕES
    -- ====================================================================
    local Config = {
        AutoFarm = true,
        AutoAttack = true,
        AutoEquip = true,
        DetectionRange = 120, -- Aumentado de 15 para 120 studs!
        AttackRange = 8,
        BaseStopDistance = 2.0,
        FarmSpeed = 0.1,
    }

    -- ESTADOS
    local CurrentCharacter = nil
    local CurrentHumanoid = nil
    local CurrentRootPart = nil
    local CurrentTool = nil
    local CurrentToolHandle = nil
    
    local isComputingPath = false
    local pathWaypoints = {}
    local currentWaypointIndex = 0
    local lastCacheUpdate = 0
    local lastMoveUpdate = 0
    local lastAttackTime = 0
    local lastTargetPos = Vector3.zero
    local TargetCache = {}
    local currentTargetData = nil

    -- ====================================================================
    -- INTERFACE GRÁFICA (HUD)
    -- ====================================================================
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "GhostFarmHub"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = TargetGuiParent
    
    -- 1. BOTÃO FLUTUANTE DE ABRIR/FECHAR (Arrastável no Mobile)
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Size = UDim2.new(0, 90, 0, 36)
    ToggleButton.Position = UDim2.new(0.02, 0, 0.25, 0)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    ToggleButton.Text = "👻 GHOST"
    ToggleButton.TextColor3 = Color3.fromRGB(0, 255, 200)
    ToggleButton.TextSize = 13
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.Parent = ScreenGui

    local ToggleCorner = Instance.new("UICorner", ToggleButton)
    ToggleCorner.CornerRadius = UDim.new(0, 8)
    local ToggleStroke = Instance.new("UIStroke", ToggleButton)
    ToggleStroke.Color = Color3.fromRGB(0, 255, 200)
    ToggleStroke.Thickness = 1.5

    -- Torna o botão flutuante arrastável no toque
    local isDraggingToggle = false
    local dragStartPos, dragStartMouse
    ToggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingToggle = true
            dragStartMouse = input.Position
            dragStartPos = ToggleButton.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDraggingToggle = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isDraggingToggle and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType ==
        Enum.UserInputType.Touch) then
            local delta = input.Position - dragStartMouse
            ToggleButton.Position = UDim2.new(dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X, dragStartPos.Y.Scale,
            dragStartPos.Y.Offset + delta.Y)
        end
    end)
    
    -- 2. PAINEL PRINCIPAL
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 240, 0, 220)
    MainFrame.Position = UDim2.new(0.02, 0, 0.33, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner", MainFrame)
    MainCorner.CornerRadius = UDim.new(0, 10)
    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.Color = Color3.fromRGB(0, 255, 200)
    MainStroke.Thickness = 1.8

    -- Cabeçalho
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 32)
    Title.BackgroundTransparency = 1
    Title.Text = "⚡ GHOST AUTO-FARM V19"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 12
    Title.Font = Enum.Font.GothamBlack
    Title.Parent = MainFrame

    -- Status Text
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -20, 0, 36)
    StatusLabel.Position = UDim2.new(0, 10, 0, 32)
    StatusLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    StatusLabel.Text = "Status: Procurando alvos..."
    StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 210)
    StatusLabel.TextSize = 10
    StatusLabel.Font = Enum.Font.GothamMedium
    StatusLabel.TextWrapped = true
    StatusLabel.Parent = MainFrame
    Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 6)
    
    -- Botão Toggle Auto-Farm
    local FarmButton = Instance.new("TextButton")
    FarmButton.Size = UDim2.new(1, -20, 0, 36)
    FarmButton.Position = UDim2.new(0, 10, 0, 76)
    FarmButton.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
    FarmButton.Text = "🟢 AUTO FARM: ATIVADO"
    FarmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    FarmButton.TextSize = 11
    FarmButton.Font = Enum.Font.GothamBold
    FarmButton.Parent = MainFrame
    Instance.new("UICorner", FarmButton).CornerRadius = UDim.new(0, 6)

    FarmButton.MouseButton1Click:Connect(function()
        Config.AutoFarm = not Config.AutoFarm
        if Config.AutoFarm then
            FarmButton.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
            FarmButton.Text = "🟢 AUTO FARM: ATIVADO"
        else
            FarmButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
            FarmButton.Text = "🔴 AUTO FARM: DESLIGADO"
            StatusLabel.Text = "Status: Pausado pelo usuário."
        end
    end)
    
    -- Botão Toggle Auto-Attack
    local AttackButton = Instance.new("TextButton")
    AttackButton.Size = UDim2.new(1, -20, 0, 36)
    AttackButton.Position = UDim2.new(0, 10, 0, 120)
    AttackButton.BackgroundColor3 = Color3.fromRGB(0, 150, 220)
    AttackButton.Text = "⚔️ AUTO ATAQUE: ATIVADO"
    AttackButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    AttackButton.TextSize = 11
    AttackButton.Font = Enum.Font.GothamBold
    AttackButton.Parent = MainFrame
    Instance.new("UICorner", AttackButton).CornerRadius = UDim.new(0, 6)

    AttackButton.MouseButton1Click:Connect(function()
        Config.AutoAttack = not Config.AutoAttack
        if Config.AutoAttack then
            AttackButton.BackgroundColor3 = Color3.fromRGB(0, 150, 220)
            AttackButton.Text = "⚔️ AUTO ATAQUE: ATIVADO"
        else
            AttackButton.BackgroundColor3 = Color3.fromRGB(80, 80, 95)
            AttackButton.Text = "🛡️ AUTO ATAQUE: DESLIGADO"
        end
    end)
    
    -- Botão Alcance (30 -> 80 -> 150)
    local RangeButton = Instance.new("TextButton")
    RangeButton.Size = UDim2.new(1, -20, 0, 36)
    RangeButton.Position = UDim2.new(0, 10, 0, 164)
    RangeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    RangeButton.Text = "🎯 Alcance: 120 studs"
    RangeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    RangeButton.TextSize = 11
    RangeButton.Font = Enum.Font.GothamBold
    RangeButton.Parent = MainFrame
    Instance.new("UICorner", RangeButton).CornerRadius = UDim.new(0, 6)

    RangeButton.MouseButton1Click:Connect(function()
        if Config.DetectionRange == 60 then
            Config.DetectionRange = 120
        elseif Config.DetectionRange == 120 then
            Config.DetectionRange = 250
        else
            Config.DetectionRange = 60
        end
        RangeButton.Text = "🎯 Alcance: " .. tostring(Config.DetectionRange) .. " studs"
    end)
    
    -- Abrir / Fechar Painel ao clicar no botão GHOST
    ToggleButton.MouseButton1Click:Connect(function()
        MainFrame.Visible = not MainFrame.Visible
    end)
    
    -- NOTIFICAÇÃO TOAST DE INICIALIZAÇÃO
    local Toast = Instance.new("TextLabel")
    Toast.Size = UDim2.new(0, 260, 0, 42)
    Toast.Position = UDim2.new(0.5, -130, 0.08, 0)
    Toast.BackgroundColor3 = Color3.fromRGB(0, 200, 130)
    Toast.Text = "✅ GHOST V19 Carregado com Sucesso!"
    Toast.TextColor3 = Color3.fromRGB(255, 255, 255)
    Toast.TextSize = 12
    Toast.Font = Enum.Font.GothamBlack
    Toast.Parent = ScreenGui
    Instance.new("UICorner", Toast).CornerRadius = UDim.new(0, 8)
    task.delay(4, function()
        TweenService:Create(Toast, TweenInfo.new(0.6), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
        task.wait(0.6)
        Toast:Destroy()
    end)
    
    -- ====================================================================
    -- LÓGICA DO PERSONAGEM E FARM
    -- ====================================================================
    local function onCharacterAdded(character)
        CurrentCharacter = character
        local humanoid = character:WaitForChild("Humanoid")
        local rootPart = character:WaitForChild("HumanoidRootPart")
        local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
    
        CurrentHumanoid = humanoid
        CurrentRootPart = rootPart
        humanoid.WalkSpeed = 16
    
        if Config.AutoEquip then
            pcall(function()
                for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
                    if tool:IsA("Tool") then
                        humanoid:EquipTool(tool)
                        break
                    end
                end
            end)
        end
    end
    
    if LocalPlayer.Character then
        onCharacterAdded(LocalPlayer.Character)
    end
    LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
    
    local function updateToolReference()
        if not CurrentCharacter then return end
        local newTool = CurrentCharacter:FindFirstChildOfClass("Tool")
        if newTool ~= CurrentTool then
            CurrentTool = newTool
            CurrentToolHandle = CurrentTool and (CurrentTool:FindFirstChild("Handle") or CurrentTool) or nil
        end
    end
    
    local function buildTargetCache()
        local list = {}
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc:IsA("Humanoid") and desc.Health > 0 and desc.Parent ~= CurrentCharacter then
                local model = desc.Parent
                local root = model and model:FindFirstChild("HumanoidRootPart")
                if root and (CurrentRootPart and (CurrentRootPart.Position - root.Position).Magnitude <=
                Config.DetectionRange) then
                    table.insert(list, { Character = model, Root = root, Humanoid = desc })
                end
            end
        end
        TargetCache = list
    end
    
    local function findBestTarget()
        if not CurrentRootPart then return nil end
        local best = nil
        local bestDist = Config.DetectionRange
    
        for _, data in ipairs(TargetCache) do
            if data.Humanoid and data.Humanoid.Health > 0 and data.Root and data.Root.Parent then
                local dist = (CurrentRootPart.Position - data.Root.Position).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    best = data
                end
            end
        end
        return best
    end
    
    -- LOOP PRINCIPAL
    RunService.Heartbeat:Connect(function()
        if not Config.AutoFarm or not CurrentRootPart or not CurrentHumanoid or CurrentHumanoid.Health <= 0 then 
            return 
        end
    
        updateToolReference()
    
        local now = os.clock()
        if now - lastCacheUpdate > 1.2 then
            buildTargetCache()
            lastCacheUpdate = now
        end
    
        local target = findBestTarget()
        currentTargetData = target
    
        if target and target.Root then
            local dist = (CurrentRootPart.Position - target.Root.Position).Magnitude
            local hpPercent = math.floor((target.Humanoid.Health / target.Humanoid.MaxHealth) * 100)
            StatusLabel.Text = string.format("Alvo: %s\nVida: %d%% | Dist: %.1fm", target.Character.Name, hpPercent, dist)
    
            if CurrentHumanoid.AutoRotate then
                CurrentHumanoid.AutoRotate = false
            end
    
            local lookPos = Vector3.new(target.Root.Position.X, CurrentRootPart.Position.Y, target.Root.Position.Z)
            if (lookPos - CurrentRootPart.Position).Magnitude > 0.05 then
                CurrentRootPart.CFrame = CurrentRootPart.CFrame:Lerp(CFrame.lookAt(CurrentRootPart.Position, lookPos),
                0.25)
            end
    
            local stopDistance = Config.BaseStopDistance + 2.0
            if dist > stopDistance then
                if dist > 12 and not isComputingPath then
                    isComputingPath = true
                    task.spawn(function()
                        local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true
                        })
                        pcall(function() path:ComputeAsync(CurrentRootPart.Position, target.Root.Position) end)
                        if path.Status == Enum.PathStatus.Success then
                            local pts = path:GetWaypoints()
                            if #pts > 0 then
                                CurrentHumanoid:MoveTo(pts[1].Position)
                            end
                        else
                            CurrentHumanoid:MoveTo(target.Root.Position)
                        end
                        task.wait(1.5)
                        isComputingPath = false
                    end)
                else
                    CurrentHumanoid:MoveTo(target.Root.Position)
                end
            else
                CurrentHumanoid:MoveTo(CurrentRootPart.Position)
            end

            if Config.AutoAttack and CurrentTool and dist <= Config.AttackRange then
                if now - lastAttackTime >= Config.FarmSpeed then
                    CurrentTool:Activate()
                    lastAttackTime = now
                end
            end
        else
            StatusLabel.Text = "Status: Procurando alvos no raio de " .. Config.DetectionRange .. "m..."
            if not CurrentHumanoid.AutoRotate then
                CurrentHumanoid.AutoRotate = true
            end
        end
    end)

    print("[GHOST V19] HUD Injetado e Ativo!")
