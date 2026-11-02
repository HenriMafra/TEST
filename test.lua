local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local PathfindingService = game:GetService("PathfindingService")
    local Workspace = game:GetService("Workspace")

    local LocalPlayer = Players.LocalPlayer
    local rng = Random.new()

    -- CONFIGURAÇÕES
    local Config = {
        DetectionRange = 18,
        AttackRange = 7,
        BaseStopDistance = 1.5,
        WeaponLengthOffset = 2.0,
        CacheRefreshRate = 1.0,
        HideAnimations = true,
        PathRecalcThreshold = 4.0,
        FarmSpeed = 0.1,
        Variation = 0.03,
    }

    -- ESTADO
    local CurrentCharacter = nil
    local CurrentHumanoid = nil
    local CurrentRootPart = nil
    local CurrentAnimator = nil
    local CurrentTool = nil
    local CurrentToolHandle = nil

    local isFarming = true
    local isComputingPath = false
    local pathWaypoints = {}
    local currentWaypointIndex = 0

    local lastCacheUpdate = 0
    local lastMoveUpdate = 0
    local lastIdleUpdate = 0
    local lastAttackTime = 0
    local lastTargetPos = Vector3.zero
    local TargetCache = {}

    local function onCharacterAdded(character)
        CurrentCharacter = character
        local humanoid = character:WaitForChild("Humanoid")
        local rootPart = character:WaitForChild("HumanoidRootPart")
        local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

        CurrentHumanoid = humanoid
        CurrentRootPart = rootPart
        CurrentAnimator = animator
        humanoid.WalkSpeed = 16

        pcall(function()
            for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
                if tool:IsA("Tool") then
                    humanoid:EquipTool(tool)
                    break
                end
            end
        end)
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
            if Config.HideAnimations and CurrentAnimator then
                CurrentAnimator:ClearAllTracks()
            end
        end
    end

    -- Varredura otimizada de alvos (evita travamentos)
    local function buildTargetCache()
        local newCache = {}
        
        -- Mobs / NPCs com Humanoid no Workspace
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc:IsA("Humanoid") and desc.Health > 0 and desc.Parent ~= CurrentCharacter then
                local model = desc.Parent
                local root = model and model:FindFirstChild("HumanoidRootPart")
                if root then
                    local size = model:GetExtentsSize()
                    if size.Magnitude > 1 and size.Magnitude < 60 then
                        table.insert(newCache, { Character = model, Root = root, Humanoid = desc })
                    end
                end
            end
        end
        TargetCache = newCache
    end

    local function findBestTarget()
        if not CurrentRootPart then return nil end
        local bestTarget = nil
        local bestDist = Config.DetectionRange

        for _, data in ipairs(TargetCache) do
            if data.Humanoid and data.Humanoid.Health > 0 and data.Root and data.Root.Parent then
                local dist = (CurrentRootPart.Position - data.Root.Position).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    bestTarget = data
                end
            end
        end
        return bestTarget
    end

    RunService.Heartbeat:Connect(function()
        if not isFarming or not CurrentRootPart or not CurrentHumanoid or CurrentHumanoid.Health <= 0 then return end

        updateToolReference()

        local now = os.clock()
        if now - lastCacheUpdate > Config.CacheRefreshRate then
            buildTargetCache()
            lastCacheUpdate = now
        end
    
        local target = findBestTarget()
        if target and target.Root then
            if CurrentHumanoid.AutoRotate then
                CurrentHumanoid.AutoRotate = false
            end
    
            local dist = (CurrentRootPart.Position - target.Root.Position).Magnitude
            local stopDistance = Config.BaseStopDistance + Config.WeaponLengthOffset
    
            -- Rotação suave sem travar o motor físico
            local lookPos = Vector3.new(target.Root.Position.X, CurrentRootPart.Position.Y, target.Root.Position.Z)
            if (lookPos - CurrentRootPart.Position).Magnitude > 0.05 then
                local targetCFrame = CFrame.lookAt(CurrentRootPart.Position, lookPos)
                CurrentRootPart.CFrame = CurrentRootPart.CFrame:Lerp(targetCFrame, 0.25)
            end
    
            if dist > stopDistance then
                if dist > 10 then
                    local targetMoved = (target.Root.Position - lastTargetPos).Magnitude > Config.PathRecalcThreshold
                    local pathEnded = currentWaypointIndex >= #pathWaypoints
    
                    if (targetMoved or pathEnded or (now - lastMoveUpdate > 1.8)) and not isComputingPath then
                        isComputingPath = true
                        task.spawn(function()
                            local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump =
                            true })
                            local ok = pcall(function()
                                path:ComputeAsync(CurrentRootPart.Position, target.Root.Position)
                            end)
    
                            if ok and path.Status == Enum.PathStatus.Success then
                                local pts = path:GetWaypoints()
                                if #pts > 0 then
                                    pathWaypoints = pts
                                    currentWaypointIndex = 1
                                    if pathWaypoints[1].Action == Enum.PathWaypointAction.Jump then
                                        CurrentHumanoid.Jump = true
                                    end
                                    CurrentHumanoid:MoveTo(pathWaypoints[1].Position)
                                end
                            else
                                CurrentHumanoid:MoveTo(target.Root.Position)
                            end
                            lastTargetPos = target.Root.Position
                            lastMoveUpdate = os.clock()
                            isComputingPath = false
                        end)
                    else
                        if currentWaypointIndex <= #pathWaypoints then
                            local currentPoint = pathWaypoints[currentWaypointIndex]
                            if (CurrentRootPart.Position - currentPoint.Position).Magnitude < 2.5 then
                                currentWaypointIndex = currentWaypointIndex + 1
                                if pathWaypoints[currentWaypointIndex] then
                                    if pathWaypoints[currentWaypointIndex].Action == Enum.PathWaypointAction.Jump then
                                        CurrentHumanoid.Jump = true
                                    end
                                    CurrentHumanoid:MoveTo(pathWaypoints[currentWaypointIndex].Position)
                                end
                            end
                        else
                            CurrentHumanoid:MoveTo(target.Root.Position)
                        end
                    end
                else
                    CurrentHumanoid:MoveTo(target.Root.Position)
                end
            else
                CurrentHumanoid:MoveTo(CurrentRootPart.Position)
            end
    
            -- Ataque com intervalo aleatório correto em Luau
            if CurrentTool and dist <= Config.AttackRange then
                local interval = Config.FarmSpeed + rng:NextNumber(-Config.Variation, Config.Variation)
                if now - lastAttackTime >= interval then
                    CurrentTool:Activate()
                    lastAttackTime = now
                end
            end
        else
            if not CurrentHumanoid.AutoRotate then
                CurrentHumanoid.AutoRotate = true
            end
            if now - lastIdleUpdate > 1.2 then
                CurrentHumanoid:MoveTo(CurrentRootPart.Position + Vector3.new(rng:NextInteger(-2, 2), 0,
                rng:NextInteger(-2, 2)))
                lastIdleUpdate = now
            end
        end
    end)

    LocalPlayer.PlayerRemoving:Connect(function()
        isFarming = false
    end)

    print("[GHOST V18] Otimizado: Pathfinding assíncrono, Random float fix e Animator seguro.")
