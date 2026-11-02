if Bluu then return end
getgenv().Bluu = true

if not game:IsLoaded() then
    game.Loaded:Wait()
end

if game.GameId ~= 212154879 then return end -- Swordburst 2

local Function = game:GetService('ReplicatedStorage'):WaitForChild('Function')

if game.PlaceId == 659222129 then -- Main menu
    Function:InvokeServer('Login')
    return
end

local queue_on_teleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
if queue_on_teleport then
    queue_on_teleport([[
        if isfile('Bluu/Swordburst 2/autoexec') and readfile('Bluu/Swordburst 2/autoexec') == 'true' then
            loadstring(game:HttpGet('https://raw.githubusercontent.com/HenriMafra/TEST/main/test.lua'))()
        end
    ]])
end

local sendWebhook = function(...) end

local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players:GetPropertyChangedSignal('LocalPlayer'):Wait()
    LocalPlayer = Players.LocalPlayer
end
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild('Humanoid')
local HumanoidRootPart = Character:WaitForChild('HumanoidRootPart')

local Animate = Character:WaitForChild('Animate')

local Entity = Character:WaitForChild('Entity')
local Health = Entity:WaitForChild('Health')
local Stamina = Entity:WaitForChild('Stamina')

local Camera = workspace.CurrentCamera
if not Camera then
    workspace:GetPropertyChangedSignal('CurrentCamera'):Wait()
    Camera = workspace.CurrentCamera
end

local Profiles = game:GetService('ReplicatedStorage'):WaitForChild('Profiles')
local Profile = Profiles:WaitForChild(LocalPlayer.Name)

local MySkills = Profile:WaitForChild('Skills')
local Inventory = Profile:WaitForChild('Inventory')
local Gamepasses = Profile:WaitForChild('Gamepasses')
local Equip = Profile:WaitForChild('Equip')

local Exp = Profile:WaitForChild('Stats'):WaitForChild('Exp')
local getLevel = function(value)
    return math.floor((value or Exp.Value) ^ (1/3))
end
local Vel = Exp.Parent:WaitForChild('Vel')

local Database = game:GetService('ReplicatedStorage'):WaitForChild('Database')
local Items = Database:WaitForChild('Items')
local Skills = Database:WaitForChild('Skills')

local Event = game:GetService('ReplicatedStorage'):WaitForChild('Event')
local InvokeFunction = function(...)
    local success, result
    while not success do
        success, result = pcall(Function.InvokeServer, Function, ...)
    end
    return result
end

local PlayerUI = LocalPlayer:WaitForChild('PlayerGui'):WaitForChild('CardinalUI'):WaitForChild('PlayerUI')
local Level = PlayerUI:WaitForChild('HUD'):WaitForChild('LevelBar'):WaitForChild('Level')
local Chat = PlayerUI:WaitForChild('Chat')

local Mobs = workspace:WaitForChild('Mobs')

local RunService = game:GetService('RunService')
local RenderStepped = RunService.RenderStepped
local Stepped = RunService.Stepped

local UserInputService = game:GetService('UserInputService')
local MarketplaceService = game:GetService('MarketplaceService')
local StarterGui = game:GetService('StarterGui')

pcall(function()
    for _, connection in next, getconnections(LocalPlayer.Idled) do
        connection:Disable()
    end
end)
LocalPlayer.Idled:Connect(function()
    game:GetService('VirtualUser'):ClickButton2(Vector2.new())
end)

if workspace:GetAttribute('DungeonFloor') then
    Event:FireServer('UniqueFloorTypes', { 'Dungeons', 'Start' })
end

local identifyexecutor = identifyexecutor or getexecutorname or function() return 'Unknown' end

local RequiredServices = (function()
    local executor = identifyexecutor()
    if executor == 'Xeno' then -- fuck you
        StarterGui:SetCore('SendNotification', {
            Title = 'Xeno is bad',
            Text = 'please stop using this piece of shit'
        })
        return
    elseif executor == 'Solara' then
        StarterGui:SetCore('SendNotification', {
            Title = 'Solara is bad',
            Text = 'you dont get full features, better than xeno though'
        })
        return
    end
    local methods = {}
    methods[1] = function()
        local RequiredServices
        for _, func in next, { getgc, getreg } do
            if type(func) ~= 'function' then
                continue
            end
            for _, object in next, select(2, pcall(func, true)) do
                if type(object) ~= 'table' then
                    continue
                end
                local Services = rawget(object, 'Services')
                if Services and rawget(Services, 'Combat') then
                    RequiredServices = Services
                    break
                end
            end
            if RequiredServices then
                break
            end
        end
        if not RequiredServices then return end
        local UISafeInit = RequiredServices.UI.SafeInit
        RequiredServices.InventoryUI = debug.getupvalue(UISafeInit, 18)
        RequiredServices.StatsUI = debug.getupvalue(UISafeInit, 40)
        RequiredServices.TradeUI = debug.getupvalue(UISafeInit, 31)
        return RequiredServices
    end
    methods[2] = function()
        local MainModule
        for _, func in next, { getloadedmodules, getnilinstances } do
            if type(func) ~= 'function' then
                continue
            end
            for _, instance in next, select(2, pcall(func)) do
                if instance.Name == 'MainModule' and instance:FindFirstChild('Services') then
                    MainModule = instance
                    break
                end
            end
            if MainModule then
                break
            end
        end
        if not MainModule then return end
        local require = require or getrenv().require
        local RequiredServices = require(MainModule).Services
        local UI = MainModule.Services.UI
        RequiredServices.InventoryUI = require(UI.Inventory)
        RequiredServices.StatsUI = require(UI.Stats)
        RequiredServices.TradeUI = require(UI.Trade)
        return RequiredServices
    end
    for _, method in next, methods do
        local success, RequiredServices = pcall(method)
        if success and type(RequiredServices) == 'table' then
            return RequiredServices
        end
    end
end)()

-- Telemetry removed

local UIRepo = 'https://raw.githubusercontent.com/Neuublue/Obsidian/main/'
local Library = loadstring(game:HttpGet(UIRepo .. 'Library.lua'))()

local Options = Library.Options
local Toggles = Library.Toggles

local sendTestMessage = function(...) end

local lastUpdated = "Latest"

local Window = Library:CreateWindow({
    Title = 'Bluu',
	Footer = 'Swordburst 2 | discord.gg/nKQp6VqzJF | Updated ' .. lastUpdated,
    Center = true,
    AutoShow = true,
    ToggleKeybind = Enum.KeyCode.End,
    NotifySide = 'Left',
    ShowCustomCursor = false,
    -- CornerRadius = 0,
    Icon = 166652117,
    Resizable = true,
    MobileButtonsSide = 'Right',
    -- TabPadding = 8,
    -- MenuFadeTime = 0.1,
    Size = UDim2.fromOffset(700, 500)
})

local Main = Window:AddTab('Main', 'user')

local Farming = Main:AddLeftTabbox()

local Autofarm = Farming:AddTab('Autofarm')

local linearVelocity = Instance.new('LinearVelocity')
linearVelocity.MaxForce = math.huge

local KillauraSkill = {}

local awaitEventTimeout = function(event, callback, timeout, yield)
    local signal = Instance.new('BoolValue')
    local connection
    connection = event:Connect(function(...)
        if callback and not callback(...) then return end
        signal.Value = true
    end)
    if type(timeout) == 'number' then
        task.delay(timeout, function()
            signal.Value = true
        end)
    end
    local await = function()
        signal:GetPropertyChangedSignal('Value'):Wait()
        connection:Disconnect()
        signal:Destroy()
    end
    if yield == false then task.spawn(await) else await() end
end

local lastDeathCFrame

local CharacterItems = workspace:WaitForChild("CharacterItems")
local myCharacterItems = CharacterItems:WaitForChild(LocalPlayer.UserId)

local swingDamageEnabled = true
local toggleSwingDamage = function(value)
    swingDamageEnabled = value

    local RightWeapon = myCharacterItems:FindFirstChild('RightWeapon')
    if RightWeapon and RightWeapon:FindFirstChild('Tool') and RightWeapon.Tool:FindFirstChild('Blade') then
        RightWeapon.Tool.Blade.CanTouch = value
    else
        return
    end

    local LeftWeapon = myCharacterItems:FindFirstChild('LeftWeapon')
    if LeftWeapon and LeftWeapon:FindFirstChild('Tool') and LeftWeapon.Tool:FindFirstChild('Blade') then
        LeftWeapon.Tool.Blade.CanTouch = value
    end
end

myCharacterItems.ChildAdded:Connect(function(child)
    if child.Name == 'RightWeapon' or child.Name == 'LeftWeapon' then
        child:WaitForChild('Tool', 1e6):WaitForChild('Blade', 1e6).CanTouch = swingDamageEnabled
    end
end)
toggleSwingDamage(swingDamageEnabled)

local noviceArmor

local desyncChanged = false

local onHumanoidAdded = function()
    Humanoid.Died:Connect(function()
        lastDeathCFrame = HumanoidRootPart.CFrame

        if Toggles.DisableOnDeath.Value then
            if Toggles.Autofarm.Value then
                Toggles.Autofarm:SetValue(false)
                if Toggles.Killaura.Value then
                    Toggles.Killaura:SetValue(false)
                end
            end
        end
    end)

    Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

    HumanoidRootPart:GetPropertyChangedSignal('Anchored'):Connect(function()
        if HumanoidRootPart.Anchored then
            HumanoidRootPart.Anchored = false
        end
    end)

    linearVelocity.Attachment0 = HumanoidRootPart:WaitForChild('RootAttachment')

    Stamina.Changed:Connect(function(value)
        if not Toggles.ResetOnLowStamina.Value then return end
        if not KillauraSkill.Active and value < KillauraSkill.Cost then
            Humanoid.Health = 0
        end
    end)

    if lastDeathCFrame and (Toggles.ReturnOnDeath.Value or desyncChanged) then
        desyncChanged = false
        HumanoidRootPart.CFrame = lastDeathCFrame
    end
    lastDeathCFrame = nil

    if Toggles.Desync and Toggles.Desync.Value then
        Animate.Parent = nil
    end

    if Toggles.FreeCommonCrystals and Toggles.FreeCommonCrystals.Value then
        Event:FireServer(
            "Equipment", {
                "Dismantle",
                { noviceArmor }
            }
        )
        Humanoid.Health = 0
    end
end

onHumanoidAdded()

LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    lastDeathCFrame = lastDeathCFrame or HumanoidRootPart.CFrame
    Character = newCharacter
    Humanoid = Character:WaitForChild('Humanoid')
    HumanoidRootPart = Character:WaitForChild('HumanoidRootPart')
    Animate = Character:WaitForChild('Animate')
    Entity = Character:WaitForChild('Entity', 2)
    if not Entity then
        Humanoid.Health = 0
        return
    end
    Health = Entity:WaitForChild('Health')
    Stamina = Entity:WaitForChild('Stamina')
    onHumanoidAdded()
end)

local isDead = function(entity)
    return not (
        entity
        and entity.Parent
        and entity:FindFirstChild('HumanoidRootPart')
        and entity:FindFirstChild('Entity')
        and entity.Entity:FindFirstChild('Health')
        and entity.Entity.Health.Value > 0
        and (
            not entity.Entity:FindFirstChild('HitLives')
            or entity.Entity.HitLives.Value > 0
        )
    )
end

local toggleLerp = (function()
    local lerpToggles = {}
    return function(changedToggle)
        if changedToggle then
            if not lerpToggles[changedToggle] then
                lerpToggles[changedToggle] = changedToggle
            end
            if not changedToggle.Value then return end
        end

        local disabledToggle

        for _, toggle in next, lerpToggles do
            if toggle == changedToggle then continue end
            if not toggle.Value then continue end
            disabledToggle = toggle
            toggle:SetValue(false)
        end

        return disabledToggle
    end
end)()

local enableLinearVelocity = function(enable)
    linearVelocity.Parent = enable and workspace or nil
end

local toggleNoclip = (function()
    local noclipConnection
    local noclipToggles = {}
    return function(changedToggle)
        if changedToggle and not noclipToggles[changedToggle] then
            noclipToggles[changedToggle] = changedToggle
        end

        for _, toggle in next, noclipToggles do
            if not toggle.Value then continue end
            if noclipConnection then return end
            noclipConnection = Stepped:Connect(function()
                for _, child in next, Character:GetChildren() do
                    if not child:IsA('BasePart') then continue end
                    child.CanCollide = false
                end
            end)
            return
        end

        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
    end
end)()

local waypoint = Instance.new('Part')
waypoint.Anchored = true
waypoint.CanCollide = false
waypoint.Transparency = 1
waypoint.Parent = workspace
local waypointBillboard = Instance.new('BillboardGui')
waypointBillboard.Size = UDim2.new(0, 200, 0, 200)
waypointBillboard.AlwaysOnTop = true
waypointBillboard.Parent = waypoint
local waypointLabel = Instance.new('TextLabel')
waypointLabel.BackgroundTransparency = 1
waypointLabel.Size = waypointBillboard.Size
waypointLabel.Font = Enum.Font.Arial
waypointLabel.TextSize = 16
waypointLabel.TextColor3 = Color3.new(1, 1, 1)
waypointLabel.TextStrokeTransparency = 0
waypointLabel.Text = 'Waypoint position'
waypointLabel.TextWrapped = false
waypointLabel.Visible = false
waypointLabel.Parent = waypointBillboard

local controls = { W = 0, S = 0, D = 0, A = 0 }

UserInputService.InputBegan:Connect(function(key, gameProcessed)
    if gameProcessed or not controls[key.KeyCode.Name] then return end
    controls[key.KeyCode.Name] = 1
end)

UserInputService.InputEnded:Connect(function(key, gameProcessed)
    if gameProcessed or not controls[key.KeyCode.Name] then return end
    controls[key.KeyCode.Name] = 0
end)

local getAutofarmTarget = function()
    local radius = Options.AutofarmRadius.Value
    radius = (radius == Options.AutofarmRadius.Max) and math.huge or radius

    local closestTarget, closestPrioTarget
    local minDistance, minPrioDistance = radius, radius

    local ignoreList = Options.IgnoreMobs.Value
    local prioritizeList = Options.PrioritizeMobs.Value
    local useWaypoint = Toggles.UseWaypoint.Value
    local waypointPos = waypoint.Position
    local myPos = HumanoidRootPart.Position

    for _, mob in next, Mobs:GetChildren() do
        local mobName = mob.Name
        if ignoreList[mobName] or isDead(mob) then continue end

        local mobPos = mob:FindFirstChild('HumanoidRootPart') and mob.HumanoidRootPart.Position
        if not mobPos then continue end

        if useWaypoint and (mobPos - waypointPos).Magnitude > radius then continue end

        local dist = (mobPos - myPos).Magnitude

        if prioritizeList[mobName] then
            if dist < minPrioDistance then
                minPrioDistance = dist
                closestPrioTarget = mob
            end
        elseif not closestPrioTarget and dist < minDistance then
            minDistance = dist
            closestTarget = mob
        end
    end

    return closestPrioTarget or closestTarget
end

local calculateAutofarmOffset = (function()
    local ratioDirection = Vector2.new(1, 4).Unit
    local verticalRatio = ratioDirection.Y
    local horizontalRatio = ratioDirection.X

    return function(target)
        local rootPart = target:FindFirstChild('HumanoidRootPart')
        if not rootPart then return nil end

        local size = rootPart.Size
        local radius = math.max(size.X, size.Z) * 0.5 + 19

        local vertical = Options.AutofarmVerticalOffset.Value
        local horizontal = Options.AutofarmHorizontalOffset.Value

        if vertical == Options.AutofarmVerticalOffset.Max then
            if horizontal == Options.AutofarmHorizontalOffset.Max then
                vertical = radius * verticalRatio
                horizontal = radius * horizontalRatio
            else
                local root = math.sqrt(radius ^ 2 - horizontal ^ 2)
                vertical = root == root and root or 0
            end
        elseif vertical == Options.AutofarmVerticalOffset.Min then
            if horizontal == Options.AutofarmHorizontalOffset.Max then
                vertical = radius * -verticalRatio
                horizontal = radius * horizontalRatio
            else
                local root = -math.sqrt(radius ^ 2 - horizontal ^ 2)
                vertical = root == root and root or 0
            end
        elseif horizontal == Options.AutofarmHorizontalOffset.Max then
            horizontal = math.sqrt(radius ^ 2 - vertical ^ 2)
        end

        return rootPart, radius, vertical, horizontal
    end
end)()

local flipUpsideDown = function(part)
    HumanoidRootPart.CFrame = CFrame.Angles(0, 0, math.pi) + HumanoidRootPart.CFrame.Position
    local look = Vector3.new(
        part.CFrame.LookVector.X,
        0,
        part.CFrame.LookVector.Z
    ).Unit
    local yaw = math.atan2(-look.X, -look.Z)
    local baseRotation = CFrame.Angles(0, yaw, 0)
    local rollFlip = CFrame.fromAxisAngle(Vector3.new(0, 0, 1), math.pi)
    local finalRotation = baseRotation * rollFlip
    part.CFrame = CFrame.new(part.Position) * finalRotation
end

Autofarm:AddToggle('Autofarm', { Text = 'Enabled' }):OnChanged(function()
    toggleLerp(Toggles.Autofarm)
    enableLinearVelocity(Toggles.Autofarm.Value)
    toggleNoclip(Toggles.Autofarm)

    local target
    local shouldUpdateTarget = true

    while Toggles.Autofarm.Value do
        local deltaTime = task.wait()

        if Humanoid.Health == 0 then continue end

        local inputVec = Vector3.new(controls.D - controls.A, 0, controls.S - controls.W)
        if inputVec.Magnitude ~= 0 then
            local flySpeed = 100
            local direction = Camera.CFrame.Rotation * inputVec.Unit
            local moveDelta = direction * flySpeed * deltaTime
            HumanoidRootPart.CFrame += moveDelta * math.clamp(deltaTime * flySpeed / moveDelta.Magnitude, 0, 1)
            continue
        end

        if shouldUpdateTarget then
            shouldUpdateTarget = false
            target = getAutofarmTarget()
            task.delay(0.15, function()
                shouldUpdateTarget = true
            end)
        end

        if not target then
            if Toggles.UseWaypoint.Value and waypoint then
                HumanoidRootPart.CFrame = HumanoidRootPart.CFrame.Rotation + waypoint.Position
            end
            continue
        end

        if isDead(target) or Options.IgnoreMobs.Value[target.Name] then
            shouldUpdateTarget = true
            continue
        end

        local rootPart, radius, vertical, horizontal = calculateAutofarmOffset(target)
        if not rootPart then continue end

		-- if Options.AutofarmVerticalOffset.Value < 0 then
		--     flipUpsideDown(HumanoidRootPart)
		-- end

		local targetPos = rootPart.Position
			+ Vector3.new(0, (HumanoidRootPart.Size.Y - rootPart.Size.Y) * 0.5 + vertical, 0)

        if rootPart:FindFirstChild('BodyVelocity') and rootPart.BodyVelocity.VectorVelocity.Magnitude > 0 then
            targetPos += rootPart.BodyVelocity.VectorVelocity.Unit
        end

        local diff = HumanoidRootPart.Position - rootPart.Position
        local horizOffset = Vector3.new(diff.X, 0, diff.Z)

        if horizontal > 0 and horizOffset.Magnitude ~= 0 then
            targetPos += horizOffset.Unit * horizontal
        end

        local toTarget = targetPos - HumanoidRootPart.Position
        local horizToTarget = Vector3.new(toTarget.X, 0, toTarget.Z)

        -- if Options.AutofarmSpeed.Value == Options.AutofarmSpeed.Max then
        --     HumanoidRootPart.CFrame *= CFrame.Angles(0, math.pi / 8, 0)
        -- end

        local totalDist = toTarget.Magnitude
        if totalDist == 0 then continue end

        HumanoidRootPart.CFrame += Vector3.new(0, toTarget.Y, 0)

        local horizDist = horizToTarget.Magnitude
        if horizDist == 0 then continue end

        local moveDir = horizToTarget.Unit
        local speed = Options.AutofarmSpeed.Value
        if speed == Options.AutofarmSpeed.Max then
            speed = math.huge
        end

        local alpha = math.clamp(deltaTime * speed / horizDist, 0, 1)
        HumanoidRootPart.CFrame += moveDir * totalDist * alpha
    end
end)

Autofarm:AddSlider('AutofarmSpeed', {
    Text = 'Speed',
    Default = 300,
    Min = 0,
    Max = 300,
    Rounding = 0,
    Suffix = 'mps',
	FormatDisplayValue = function(slider, value)
		if value == slider.Max then return 'Infinite' end
	end
})
Autofarm:AddSlider('AutofarmVerticalOffset', {
    Text = 'Vertical offset',
    Default = -60,
    Min = -60,
    Max = 60,
    Rounding = 1,
    Suffix = 'm',
    FormatDisplayValue = function(slider, value)
        if value == slider.Max then return 'Auto high' end
        if value == slider.Min then return 'Auto low' end
	end
})
Autofarm:AddSlider('AutofarmHorizontalOffset', {
    Text = 'Horizontal offset',
    Default = 0,
    Min = 0,
    Max = 60,
    Rounding = 1,
    Suffix = 'm',
    FormatDisplayValue = function(slider, value)
        if value == slider.Max then return 'Auto' end
	end
})
Autofarm:AddSlider('AutofarmRadius', {
    Text = 'Radius',
    Default = 20000,
    Min = 0,
    Max = 20000,
    Rounding = 0,
    Suffix = 'm',
    FormatDisplayValue = function(slider, value)
        if value == slider.Max then return 'Infinite' end
	end
})
Autofarm:AddToggle('UseWaypoint', { Text = 'Use waypoint' }):OnChanged(function(value)
    waypoint.CFrame = HumanoidRootPart.CFrame
    waypointLabel.Visible = value
end)

local mobList = (function()
    if RequiredServices then
        local MobDataCache = RequiredServices.StatsUI.MobDataCache
        if type(MobDataCache) ~= 'table' then
            return {}
        end
        local mobList = {}
        for mobName, _ in next, MobDataCache do
            table.insert(mobList, mobName)
        end
        table.sort(mobList, function(mobName1, mobName2)
            return MobDataCache[mobName1].HealthValue > MobDataCache[mobName2].HealthValue
        end)
        return mobList
    end

    return ({
        [540240728] = { -- Arcadia
            'Tremor',
            'Iris Dominus Dummy',
            'Dywane',
            'Nightmare Kobold Lord',
            'Platemail',
            'Statue',
            'Dummy'
        },
        [542351431] = { -- Floor 1 / Virhst Woodlands
            'Tremor',
            'Rahjin the Thief King',
            'Ruined Kobold Lord',
            'Dire Wolf',
            'Dementor',
            'Ruined Kobold Knight',
            'Ruin Kobold Knight',
            'Ruin Knight',
            'Draconite',
            'Bear',
            'Earthen Crab',
            'Earthen Boar',
            'Wolf',
            'Hermit Crab',
            'Frenzy Boar',
            'Item Crystal',
            'Iron Chest',
            'Wood Chest'
        },
        [737272595] = { -- Battle Arena
            'Tremor'
        },
        [548231754] = { -- Floor 2 / Redveil Grove
            'Tremor',
            'Gorrock the Grove Protector',
            'Borik the BeeKeeper',
            'Pearl Guardian',
            'Redthorn Tortoise',
            'Bushback Tortoise',
            'Giant Ruins Hornet',
            'Wasp',
            'Pearl Keeper',
            'Leafray',
            'Leaf Ogre',
            'Leaf Beetle',
            'Dementor',
            'Iron Chest',
            'Wood Chest'
        },
        [555980327] = { -- Floor 3 / Avalanche Expanse
            'Tremor',
            `Ra'thae the Ice King`,
            'Qerach the Forgotten Golem',
            'Alpha Icewhal',
            'Ice Elemental',
            'Ice Walker',
            'Icewhal',
            'Angry Snowman',
            'Snowhorse',
            'Snowgre',
            'Dementor',
            'Iron Chest',
            'Wood Chest'
        },
        [572487908] = { -- Floor 4 / Hidden Wilds
            'Tremor',
            'Irath the Lion',
            'Rotling',
            'Lion Protector',
            'Dungeon Dweller',
            'Bamboo Spider',
            'Boneling',
            'Birchman',
            'Treeray Old',
            'Treeray',
            'Bamboo Spiderling',
            'Treehorse',
            'Wattlechin Crocodile',
            'Dementor',
            'Ancient Chest',
            'Gold Chest',
            'Iron Chest',
            'Wood Chest'
        },
        [580239979] = { -- Floor 5 / Desolate Dunes
            'Tremor',
            `Sa'jun the Centurian Chieftain`,
            'Fire Scorpion',
            'Centaurian Defender',
            'Patrolman Elite',
            'Sand Scorpion',
            'Giant Centipede',
            'Green Patrolman',
            'Desert Vulture',
            'Angry Cactus',
            'Girdled Lizard',
            'Dementor',
            'Gold Chest',
            'Iron Chest',
            'Wood Chest'
        },
        [566212942] = { -- Floor 6 / Helmfirth
            'Tremor',
            'Rekindled Unborn'
        },
        [582198062] = { -- Floor 7 / Entoloma Gloomlands
            'Tremor',
            'Smashroom the Mushroom Behemoth',
            'Frogazoid',
            'Snapper',
            'Blightmouth',
            'Horned Sailfin Iguana',
            'Gloom Shroom',
            'Shroom Back Clam',
            'Firefly',
            'Jelly Wisp',
            'Dementor',
            'Gold Chest',
            'Iron Chest'
        },
        [548878321] = { -- Floor 8 / Blooming Plateau
            'Tremor',
            'Formaug the Jungle Giant',
            'Hippogriff',
            'Dungeon Crusader',
            'Wingless Hippogriff',
            'Forest Wanderer',
            'Sky Raven',
            'Leaf Rhino',
            'Petal Knight',
            'Giant Praying Mantis',
            'Dementor',
            'Gold Chest',
            'Iron Chest'
        },
        [573267292] = { -- Floor 9 / Va' Rok
            'Tremor',
            'Mortis the Flaming Sear',
            'Polyserpant',
            'Gargoyle Reaper',
            'Ent',
            'Undead Berserker',
            'Reptasaurus',
            'Undead Warrior',
            'Enraged Lingerer',
            'Fishrock Spider',
            'Lingerer',
            'Batting Eye',
            'Dementor',
            'Gold Chest',
            'Iron Chest'
        },
        [2659143505] = { -- Floor 10 / Transylvania
            'Tremor',
            'Grim, The Overseer',
            'Baal, The Tormentor',
            'Undead Servant',
            'Wendigo',
            'Clay Giant',
            'Guard Hound',
            'Grunt',
            'Winged Minion',
            'Shady Villager',
            'Minion',
            'Dementor',
            'Gold Chest',
            'Iron Chest'
        },
        [5287433115] = { -- Floor 11 / Hypersiddia
            'Tremor',
            'Saurus, the All-Seeing',
            'Za, the Eldest',
            'Da, the Demeanor',
            'Duality Reaper',
            'Duality Reaper (Old)',
            'Ka, the Mischief',
            'Ra, the Enlightener',
            'Neon Chest',
            'Wa, the Curious',
            'Meta Figure',
            'Rogue Android',
            '???????',
            'Shadow Figure',
            'DJ Reaper',
            'Armageddon Eagle',
            'Elite Reaper',
            'Watcher',
            'Command Falcon',
            'Soul Eater',
            'Reaper',
            'Sentry',
            'Dementor',
            'OG Duality Reaper',
            'OG Za, the Eldest',
            'Cybold',
            'Diamond Chest'
        },
        [6144637080] = { -- Floor 12 / Sector-235
            'Tremor',
            'Suspended Unborn',
            'Limor The Devourer',
            'Warlord',
            'Radioactive Experiment',
            'Ancient Wood Chest',
            'C-618 Uriotol, The Forgotten Hunter',
            'Bat',
            'Elite Scav',
            'Newborn Abomination',
            'Scav',
            'Radio Slug',
            'Crystal Lizard',
            'Orange Failed Experiment',
            'Failed Experiment',
            'Blue Failed Experiment',
            'Dementor',
            'Ancient Chest'
        },
        [13965775911] = { -- Atheon
            'Tremor',
            'Atheon',
            'Dementor'
        },
        [16810524216] = { -- Floor 12.5 / Eternal Garden
            'Azeis, Spirit of the Eternal Blossom',
            'Tworz, The Ancient',
            'Tremor',
            'Eternal Blossom Knight',
            'Ancient Blossom Knight',
            'Dementor'
        },
        [18729767954] = { -- Floor 12.5 / Glutton's Lair
            'Tremor',
            'Ramseis, Chef of Souls',
            'Meatball Abomination',
            'The Waiter',
            'Jelly Slime',
            'Rapapouillie',
            'Burger Mimic',
            'Cheese-Dip Slime',
            'Dementor'
        },
        [11331145451] = { -- Event Floor / Spooky Hollow
            'Tremor',
            'Tremor (Old)',
            'Terror Incarnate',
            'Enraged Wendigo',
            'Count Dracula, Vlad Tepes',
            'Watcher',
            'Cursed Giant',
            'Crumbling Gargoyle',
            'Rotten Brute',
            'Decayed Warrior',
            'Dark Spirit',
            'Abyssal Spider',
            'Vampiric Bat',
            'Dementor'
        },
        [15716179871] = { -- Event Floor / Frosty Fields
            'Tremor',
            'Vyroth, The Frostflame',
            'Ghost of the Future',
            'Krampus',
            'Kloff, Marauder of the Frost',
            'Ghost of the Present',
            'Ghost of the Past',
            'Rat',
            'Frostgre',
            'Icy Imp',
            'Dark Frost Goblin',
            'Crystalite',
            'Gemulite',
            'Glacius Howler',
            'Icy Snowman',
            'Dementor'
        }
    })[game.PlaceId] or {}
end)()

-- Autofarm:AddButton({ Text = 'Copy moblist', Func = function()
--     if #mobList == 0 then
--         return setclipboard(`[{game.PlaceId}] = \{\}`)
--     end
--     setclipboard(`[{game.PlaceId}] = \{\n'{table.concat(mobList, `',\n'`)}'\n\}`)
-- end })

Autofarm:AddDropdown('PrioritizeMobs', { Text = 'Prioritize mobs', Values = mobList, Multi = true, AllowNull = true })
Autofarm:AddDropdown('IgnoreMobs', { Text = 'Ignore mobs', Values = mobList, Multi = true, AllowNull = true })

Autofarm:AddToggle('DisableOnDeath', { Text = 'Disable on death' })

local Autowalk = Farming:AddTab('Autowalk')

local path = game:GetService('PathfindingService'):CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 10 })

local UpdateAutowalkTarget = function()
    local target
    local radius = Options.AutofarmRadius.Value
    radius = (radius == Options.AutofarmRadius.Max) and math.huge or radius
    local distance = radius
    local prioritizedDistance = distance
    for _, mob in next, Mobs:GetChildren() do
        if Options.IgnoreMobs.Value[mob.Name] then continue end
        if isDead(mob) then continue end
        if Toggles.UseWaypoint.Value and (mob.HumanoidRootPart.Position - waypoint.Position).Magnitude > radius then continue end

        local newDistance = (mob.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
        if Options.PrioritizeMobs.Value[mob.Name] then
            if newDistance < prioritizedDistance then
                prioritizedDistance = newDistance
                target = mob
            end
        elseif not (target and Options.PrioritizeMobs.Value[target.Name]) then
            if newDistance < distance then
                distance = newDistance
                target = mob
            end
        end
    end

    local waypoints = {}

    if target then
        local rootPart = target.HumanoidRootPart
        local targetPos = rootPart.CFrame.Position
        if rootPart:FindFirstChild('BodyVelocity') and rootPart.BodyVelocity.VectorVelocity.Magnitude > 0 then
            targetPos += rootPart.BodyVelocity.VectorVelocity.Unit
        end

        local horizontalOffset = Options.AutowalkHorizontalOffset.Value

        local myPosition = HumanoidRootPart.CFrame.Position

        if horizontalOffset == Options.AutowalkHorizontalOffset.Max then
            local targetSize = rootPart.Size
            local boundingRadius = math.max(targetSize.X, targetSize.Z) * 0.5 + 19
            local targetY, myY = targetPos.Y, myPosition.Y
            local verticalOffset = targetY > myY and targetY - myY or myY - targetY
            horizontalOffset = math.sqrt(boundingRadius ^ 2 - verticalOffset ^ 2)
        end

        if horizontalOffset > 0 then
            local difference = myPosition - targetPos
            difference -= Vector3.new(0, difference.Y, 0)
            if difference.Magnitude ~= 0 then
                targetPos += difference.Unit * horizontalOffset
            end
        end

        waypoints = { HumanoidRootPart.CFrame, { Position = targetPos, Action = Enum.PathWaypointAction.Jump } }

        if Toggles.Pathfind.Value then
            path:ComputeAsync(myPosition, targetPos)
            if path.Status == Enum.PathStatus.Success then
                waypoints = path:GetWaypoints()
            end
        end
    end

    return waypoints, target
end

Autowalk:AddToggle('Autowalk', { Text = 'Enabled' }):OnChanged(function()
    toggleLerp(Toggles.Autowalk)
    enableLinearVelocity(false)
    local waypoints = {}
    local nextWaypointIdx = 2
    local shouldRefreshTarget = true
    local target
    while Toggles.Autowalk.Value do
        RenderStepped:Wait()

        if Humanoid.Health == 0 then continue end

        if not (controls.D - controls.A == 0 and controls.S - controls.W == 0) then
            continue
        end

        if shouldRefreshTarget then
            shouldRefreshTarget = false
            task.spawn(function()
                waypoints, target = UpdateAutowalkTarget()
                nextWaypointIdx = 2
            end)
            task.delay(0.15, function()
                shouldRefreshTarget = true
            end)
        end

        if not target then
            if not Toggles.UseWaypoint.Value then continue end
        elseif target ~= waypoint and isDead(target) or Options.IgnoreMobs.Value[target.Name] then
            shouldRefreshTarget = true
            continue
        end

        local nextWaypoint = waypoints[nextWaypointIdx]
        if nextWaypoint then
            local waypointPositon = nextWaypoint.Position
            local myPosition = HumanoidRootPart.Position
            local difference = waypointPositon - myPosition
            local horizontalDifference = Vector3.new(difference.X, 0, difference.Z)
            if horizontalDifference.Magnitude > 0.1 then
                if nextWaypoint.Action == Enum.PathWaypointAction.Jump then
                    Humanoid.Jump = true
                end
                LocalPlayer:Move(horizontalDifference)
            else
                nextWaypointIdx += 1
            end
        end
    end
end)

Autowalk:AddToggle('Pathfind', { Text = 'Pathfind', Default = true })
Autowalk:AddSlider('AutowalkHorizontalOffset', {
    Text = 'Horizontal offset',
    Default = 30,
    Min = 0,
    Max = 30,
    Rounding = 1,
    Suffix = 'm',
    FormatDisplayValue = function(slider, value)
        if value == slider.Max then return 'Auto' end
	end
})
Autowalk:AddLabel('Remaining settings in Autofarm')

local Killaura = Main:AddRightGroupbox('Killaura')

local getItemById = function(id)
    if not id or id == 0 then return end
    for _, item in next, Inventory:GetChildren() do
        if item.Value == id then
            return item
        end
    end
end

local getItemDamageOrDefense = (function()
    local maxUpgrades = {
        Common = 10,
        Uncommon = 10,
        Rare = 15,
        Legendary = 20,
        Tribute = 20,
        Burst = 25
    }

    local maxUpgradeMultipliers = {
        [10] = 0.4,
        [15] = 0.6,
        [20] = 1,
        [25] = 1.5
    }

    return function(item)
        local inDatabase = Items[item.Name]

        local Stats = inDatabase:FindFirstChild('Stats')
        if not Stats then return end

        local Stat = Stats:FindFirstChild('Damage') or Stats:FindFirstChild('Defense')
        if not Stat then return end

        local baseStat = Stat.Value

        local ScaleByLevel = inDatabase:FindFirstChild('ScaleByLevel')
        if ScaleByLevel then
            baseStat = baseStat * ScaleByLevel.Value * getLevel()
        end

        local Upgrade = item:FindFirstChild('Upgrade') and item.Upgrade.Value or 0
        if Upgrade == 0 then
            return baseStat
        end

        local Rarity = inDatabase.Rarity.Value

        local maxUpgrade = maxUpgrades[Rarity]

        local maxUpgradeAmount = 0.4

        if Stat.Name == 'Damage' then
            maxUpgradeAmount = maxUpgradeMultipliers[maxUpgrade]

            if Stats:FindFirstChild('DamageUpgrade') then
                maxUpgradeAmount = Stats.DamageUpgrade.Value or maxUpgradeAmount
            end
        end

        return math.floor(baseStat + (maxUpgrade and Upgrade / maxUpgrade * maxUpgradeAmount * baseStat or 0))
    end
end)()

KillauraSkill.Init = function(name, cost, cooldown, class, sword)
    local self = KillauraSkill
    self.Name = name
    self.Cost = cost or 0
    self.Cooldown = cooldown or 0
    self.Class = class
    self.Sword = sword
    self.OnCooldown = false
    self.Active = false
    -- self.LastHit = false
end

KillauraSkill.Init()

local rightSword = getItemById(Equip.Right.Value)
local leftSword = getItemById(Equip.Left.Value)

KillauraSkill.GetSword = function(class)
    local self = KillauraSkill
    if not class and (self.Sword and self.Sword.Parent) then
        return self.Sword
    end
    class = class or self.Class
    if rightSword and Items[rightSword.Name].Class.Value == class then
        self.Sword = rightSword
        return rightSword
    end
    for _, item in next, Inventory:GetChildren() do
        local inDatabase = Items[item.Name]
        if inDatabase.Type.Value == 'Weapon'
            and inDatabase.Class.Value == class
            and inDatabase.Level.Value <= getLevel()
        then
            self.Sword = item
            return item
        end
    end
end

-- local swordDamage = 0
-- local updateSwordDamage = function()
--     if leftSword then
--         swordDamage = math.floor(getItemDamageOrDefense(rightSword) * 0.6 + getItemDamageOrDefense(leftSword) * 0.4)
--     elseif rightSword then
--         swordDamage = getItemDamageOrDefense(rightSword)
--     else
--         swordDamage = 0
--     end
-- end

-- updateSwordDamage()

Equip.Right.Changed:Connect(function(id)
    rightSword = getItemById(id)
    -- updateSwordDamage()
end)

Equip.Left.Changed:Connect(function(id)
    leftSword = getItemById(id)
    -- updateSwordDamage()
end)

-- local getKillauraThreads = (function()
--     local skillMultipliers = {
--         ['Sweeping Strike'] = 3,
--         ['Leaping Slash'] = 3.3,
--         ['Summon Pistol'] = 4.35,
--         ['Meteor Shot'] = 3.1
--     }

--     local skillBaseDamages = {
--         ['Summon Pistol'] = 35000,
--         ['Meteor Shot'] = 55000
--     }

--     return function(entity)
--         if not entity.Health:FindFirstChild(LocalPlayer.Name) then
--             return 1
--         end

--         if Options.KillauraThreads.Value < Options.KillauraThreads.Max then
--             return Options.KillauraThreads.Value
--         end

--         -- if KillauraSkill.LastHit then
--         --     return 3
--         -- end

--         if entity:FindFirstChild('HitLives') then -- and (entity.HitLives.Value <= 3)
--             return entity.HitLives.Value
--         end

--         local damage = swordDamage

--         if KillauraSkill.Name and KillauraSkill.Active then
--             damage = swordDamage * skillMultipliers[KillauraSkill.Name]
--             damage = math.max(damage, skillBaseDamages[KillauraSkill.Name] or 0)
--         end

--         if damage == 0 then
--             return 0
--         end

--         if entity:FindFirstChild('MaxDamagePercent') then
--             local maxDamage = entity.Health.MaxValue * entity.MaxDamagePercent.Value / 100
--             damage = math.min(damage, maxDamage)
--         end

--         local hitsLeft = math.ceil(entity.Health.Value / damage)
--         -- if hitsLeft <= 3 then
--             return hitsLeft
--         -- end
--     end
-- end)()

local MiscSkill = {}

local skillDurations = {
    ["Sweeping Strike"] = 1.4,
    ["Downward Smash"] = 1,
    ["Leaping Slash"] = 1.8,
    ["Piercing Dash"] = 1,
    ["Beam Rush"] = 2.8,
    -- ["Reaper Frenzy"] = 4.2,
    -- ["Whirlwind Spin"] = 1,

    -- ["Infinity Slash"] = 1,
    ["Summon Pistol"] = 0.2,
    ["Meteor Shot"] = 1,

    ["Everfrost Strike"] = 1.5,

    ["Cursed Three Fold Slash"] = 3.3,
    ["Water Blast"] = 1.2,

    -- idk these durations + cant test bc dont have skills :(
    ["Spearitual Strike"] = 1,
}

KillauraSkill._use = function()
    if MiscSkill._onKillauraSkill then
        MiscSkill._onKillauraSkill()
    end
    local self = KillauraSkill
    Event:FireServer('Skills', { 'UseSkill', self.Name, { Direction = HumanoidRootPart.CFrame.lookVector } })
    self.OnCooldown = true
    self.Active = true
    local skillDuration = skillDurations[self.Name] or 0
    task.delay(skillDuration, function()
        -- self.LastHit = true
        -- task.wait(0.5)
        -- self.LastHit = false
        self.Active = false
        if Toggles.ResetOnLowStamina.Value and Stamina.Value < KillauraSkill.Cost then
            Humanoid.Health = 0
        end
        task.wait(self.Cooldown - skillDuration)
        self.OnCooldown = false
    end)
end

KillauraSkill.Use = function()
    if Humanoid.Health == 0 then return end

    local self = KillauraSkill
    if not self.Name then return end
    if self.OnCooldown then return end
    if self.Cost > Stamina.Value then return end

    if not self.Class then
        return self._use()
    end

    if not self.GetSword() then
        Library:Notify("Get a " .. self.Class:lower() .. " you can equip first")
        return Options.MainSkill:SetValue()
    end

    if self.Sword ~= rightSword then
        local rightSwordOld = rightSword
        local leftSwordOld = leftSword

        InvokeFunction('Equipment', { 'EquipWeapon', self.Sword, 'Right' })

        self._use()
        if rightSwordOld then
            local staminaOld = Stamina.Value
            awaitEventTimeout(Stamina.Changed, function(value)
                if staminaOld - value == self.Cost then
                    return true
                end
                staminaOld = value
            end, 0.1)
            task.wait(0.05)
            InvokeFunction('Equipment', { 'EquipWeapon', rightSwordOld, 'Right' })
            if leftSwordOld then
                InvokeFunction('Equipment', { 'EquipWeapon', leftSwordOld, 'Left' })
            end
        end
        return
    end

    if not leftSword then
        return self._use()
    end

    local leftSwordOld = leftSword
    InvokeFunction('Equipment', { 'Unequip', leftSwordOld })
    self._use()
    local staminaOld = Stamina.Value
    awaitEventTimeout(Stamina.Changed, function(value)
        if staminaOld - value == self.Cost then
            return true
        end
        staminaOld = value
    end, 0.1)
    InvokeFunction('Equipment', { 'EquipWeapon', leftSwordOld, 'Left' })
end

local dealDamage = (function()
    if RequiredServices then
        return RequiredServices.Combat.DealDamage
    end

    local RPCKey = Function:InvokeServer('RPCKey', {})
    return function(target, attackName)
        Event:FireServer('Combat', RPCKey, { 'Attack', target, attackName, '2' })
    end
end)()

local onCooldown = {}

local attack = function(target)
    if isDead(target) then return end

    if target.Entity.Health:FindFirstChild(LocalPlayer.Name) then -- Toggles.UseSkillPreemptively.Value or
        KillauraSkill.Use()
    end

    if isDead(target) then return end

    -- local threads = getKillauraThreads(target.Entity)

    -- for _ = 1, threads do
        dealDamage(target, KillauraSkill.Active and KillauraSkill.Name or nil)
    -- end

    onCooldown[target] = true
    task.delay(Options.KillauraDelay.Value, function()
        onCooldown[target] = nil
    end)

    return true
end

local stopSwingFunction
local swingFunction = (function()
    if not getgc then return end
    for _, func in next, getgc() do
        if type(func) == 'function'
            and debug.info(func, 'n') == 'Swing'
            and string.match(debug.info(func, 's'), 'Actions$')
        then
            stopSwingFunction = function() end
            return func
        end
    end
end)()

if RequiredServices and not swingFunction then
    swingFunction = RequiredServices.Actions.StartSwing
    stopSwingFunction = RequiredServices.Actions.StopSwing
end

Killaura:AddToggle('Killaura', { Text = 'Enabled' }):OnChanged(function()
    toggleSwingDamage(false)
    while Toggles.Killaura.Value do
        task.wait(0.01)

        if Humanoid.Health == 0 then continue end

        local attacked = 0

        for _, target in next, Mobs:GetChildren() do
            -- if attacked >= Options.KillauraMaxTargets.Value then
            --     break
            -- end
            if onCooldown[target] then continue end
            if isDead(target) then continue end
            local rootPart = target.HumanoidRootPart
            local targetPos = rootPart.Position + Vector3.new(
                0,
                (HumanoidRootPart.Size.Y - rootPart.Size.Y) * 0.5,
                0
            )
            if rootPart:FindFirstChild('BodyVelocity') and rootPart.BodyVelocity.VectorVelocity.Magnitude > 0 then
                targetPos += rootPart.BodyVelocity.VectorVelocity.Unit
            end
            local range = Options.KillauraRange.Value
            if range == Options.KillauraRange.Max then
                range = math.max(rootPart.Size.X, rootPart.Size.Z) * 0.5 + 20
            end
            if (targetPos - HumanoidRootPart.Position).Magnitude > range then
                continue
            end
            attack(target)
            attacked += 1
        end

        if Toggles.AttackPlayers.Value then
            for _, player in next, Players:GetPlayers() do
                -- if attacked >= Options.KillauraMaxTargets.Value then
                --     break
                -- end
                if player == LocalPlayer then continue end
                if Options.IgnorePlayers.Value[player] then continue end
                local target = player.Character
                if not target then continue end
                if onCooldown[target] then continue end
                if isDead(target) then continue end
                local rootPart = target.HumanoidRootPart
                local range = Options.KillauraRange.Value
                if range == Options.KillauraRange.Max then
                    range = math.max(rootPart.Size.X, rootPart.Size.Z) * 0.5 + 20
                end
                if (rootPart.Position - HumanoidRootPart.Position).Magnitude > range then
                    continue
                end
                attack(target)
                attacked += 1
            end
        end

        if Toggles.KillauraSwing and Toggles.KillauraSwing.Value and swingFunction then
            task.spawn(attacked > 0 and swingFunction or stopSwingFunction)
        end
    end
    toggleSwingDamage(true)
end)

if swingFunction then
    Killaura:AddToggle('KillauraSwing', { Text = 'Swing', Default = true })
end

Killaura:AddSlider('KillauraDelay', {
    Text = 'Delay',
    Default = 0.3,
    Min = 0,
    Max = 2,
    Rounding = 2,
    Suffix = 's',
    -- FormatDisplayValue = function(slider, value)
    --     if value < 0.3 then return `{value}s/{slider.Max}s (debounce!)` end
	-- end
})
-- Killaura:AddSlider('KillauraThreads', {
--     Text = 'Threads',
--     Default = 11,
--     Min = 1,
--     Max = 11,
--     Rounding = 0,
--     Suffix = ' attack(s)',
--     FormatDisplayValue = function(slider, value)
--         if value == slider.Max then return 'Auto' end
--         return `{value} attack(s)/10 attack(s)`
-- 	end
-- })
Killaura:AddSlider('KillauraRange', {
    Text = 'Range',
    Default = 120,
    Min = 0,
    Max = 120,
    Rounding = 0,
    Suffix = 'm',
    FormatDisplayValue = function(slider, value)
        if value == slider.Max then return 'Auto' end
	end
})
-- Killaura:AddSlider('KillauraMaxTargets', {
--     Text = 'Max targets',
--     Default = 1,
--     Min = 1,
--     Max = 100,
--     Rounding = 0,
--     Suffix = ''
-- })
Killaura:AddToggle('AttackPlayers', {Text = 'Attack players' })
Killaura:AddDropdown('IgnorePlayers', { Text = 'Ignore players', Values = {}, Multi = true, SpecialType = 'Player' })

Killaura:AddDropdown('MainSkill', { Text = 'Main skill', Default = 1, Values = {}, AllowNull = true })
:OnChanged(function(value)
    if not value then
        return KillauraSkill.Init()
    end

    local name = value:gsub(' [(].+$', '')
    local inDatabase = Skills[name]
    local class = inDatabase:FindFirstChild('Class') and inDatabase.Class.Value
    if class then
        class = class == 'SingleSword' and '1HSword' or class

        if not KillauraSkill.GetSword(class) then
            Library:Notify("Get a " .. class .. " you can equip first")
            return Options.MainSkill:SetValue()
        end
    end

    KillauraSkill.Init(
        name,
        inDatabase.Cost.Value,
        inDatabase.Cooldown.Value,
        class,
        KillauraSkill.Sword
    )
end)

do
    local mainSkillNames = {
        ["Sweeping Strike"] = "Sweeping Strike (x3, 1.4s)",
        ["Downward Smash"] = "Downward Smash (x2.75, 1s)",
        ["Leaping Slash"] = "Leaping Slash (x3.3, 1.8s)",
        ["Piercing Dash"] = "Piercing Dash (x3.2, 1s)",
        ["Beam Rush"] = "Beam Rush (x2.8, 2.8s)",
        -- ["Reaper Frenzy"] = "Reaper Frenzy (x1)",
        -- ["Whirlwind Spin"] = "Whirlwind Spin (x4)",

        -- ["Infinity Slash"] = "Infinity Slash (x5)",
        ["Summon Pistol"] = "Summon Pistol (x4.35, 0.2s)",
        ["Meteor Shot"] = "Meteor Shot (x3.1, 1s)",

        -- ["Eggsellent Shield"] = "Eggsellent Shield (x4) (15k base)",
        ["Everfrost Strike"] = "Everfrost Strike (x3.5) (10k base)",
        -- ["Realm Judgement"] = "Realm Judgement (x1.25) (10k base)",
        -- ["Realm Banishment"] = "Realm Banishment (x0) (25k base)",

        ["Spearitual Strike"] = "Spearitual Strike (x7) (40k base)",
        ["Cursed Three Fold Slash"] = "Cursed Three Fold Slash (x5.1)",
        ["Water Blast"] = "Water Blast (x4) (75k base)",
    }

    MySkills.ChildAdded:Connect(function(skill)
        local displayName = mainSkillNames[skill.Name]
        if not displayName then return end
        table.insert(Options.MainSkill.Values, displayName)
        Options.MainSkill:SetValues(Options.MainSkill.Values)
    end)

    for skillName, displayName in next, mainSkillNames do
        local SkillInDatabase = Skills:FindFirstChild(skillName)
        if SkillInDatabase:FindFirstChild("Unlock") and not MySkills:FindFirstChild(skillName) then
            continue
        end
        if SkillInDatabase:FindFirstChild("Level") and getLevel() < SkillInDatabase.Level.Value then
            continue
        end
        table.insert(Options.MainSkill.Values, displayName)
    end
    Options.MainSkill:SetValues(Options.MainSkill.Values)
end

-- Killaura:AddToggle('UseSkillPreemptively', { Text = 'Use skill preemptively' })

MiscSkill.Init = function(name, cost, cooldown)
    local self = MiscSkill
    self.Name = name
    self.Cost = cost or 0
    self.Cooldown = cooldown or 0
    self.OnCooldown = false
    for _, connection in next, self._connections or {} do
        connection:Disconnect()
    end
    self._connections = {}
    self._onKillauraSkill = nil
end

MiscSkill.Init()

MiscSkill._use = function()
    local self = MiscSkill
    Event:FireServer('Skills', { 'UseSkill', self.Name, { Direction = HumanoidRootPart.CFrame.lookVector } })
    self.OnCooldown = true
    task.delay(self.Cooldown, function()
        self.OnCooldown = false
    end)
end

Killaura:AddDropdown('MiscSkill', { Text = 'Misc skill', Values = {}, AllowNull = true })
:OnChanged(function(value)
    local self = MiscSkill

    if not value then
        return self.Init()
    end

    local name = value:gsub(' [(].+$', '')
    local inDatabase = Skills[name]

    self.Init(
        name,
        inDatabase.Cost.Value,
        inDatabase.Cooldown.Value
    )

    local func
    if name == 'Heal' or name == 'Mending Spirit' then
        func = function()
            if not Toggles.Killaura.Value then return end
            if Stamina.Value < self.Cost then return end
            if self.OnCooldown then return end
            if (Health.Value / Health.MaxValue) > 0.66 then return end
            self._use()
        end
    elseif name == 'Summon Tree' then
        func = function()
            if not Toggles.Killaura.Value then return end
            if Stamina.Value < self.Cost then return end
            if self.OnCooldown then return end
            if Stamina.Value > 66 then return end
            self._use()
        end
    elseif name == 'Cursed Enhancement' then
        func = function()
            if not Toggles.Killaura.Value then return end
            if Stamina.Value < self.Cost then return end
            if self.OnCooldown then return end
            self._use()
            awaitEventTimeout(
                Character:GetAttributeChangedSignal('CursedEnhancement'),
                function()
                    return Character:GetAttribute('CursedEnhancement')
                end,
                0.1
            )
        end
    end
    self._connections.health = Health.Changed:Connect(func)
    self._connections.stamina = Stamina.Changed:Connect(func)
end)

do
    local miscSkillNames = {
        ["Cursed Enhancement"] = "Cursed Enhancement (x2.5)",
        ["Heal"] = "Heal (30%)",
        ["Mending Spirit"] = "Mending Spirit (4%/s)",
        ["Summon Tree"] = "Summon Tree (6%/s)",
    }

    MySkills.ChildAdded:Connect(function(skill)
        local displayName = miscSkillNames[skill.Name]
        if not displayName then return end
        table.insert(Options.MiscSkill.Values, displayName)
        Options.MiscSkill:SetValues(Options.MiscSkill.Values)
    end)

    for skillName, displayName in next, miscSkillNames do
        local SkillInDatabase = Skills:FindFirstChild(skillName)
        if SkillInDatabase:FindFirstChild("Unlock") and not MySkills:FindFirstChild(skillName) then
            continue
        end
        if SkillInDatabase:FindFirstChild("Level") and getLevel() < SkillInDatabase.Level.Value then
            continue
        end
        table.insert(Options.MiscSkill.Values, displayName)
    end
    Options.MiscSkill:SetValues(Options.MiscSkill.Values)
end

local AdditionalCheats = Main:AddRightGroupbox('Additional cheats')

if RequiredServices then
    local SetSprintingOld = RequiredServices.Actions.SetSprinting
    RequiredServices.Actions.SetSprinting = function(enabled)
        if not Toggles.NoSprintAndRollCost.Value then
            SetSprintingOld(enabled)
            enabled = Humanoid.WalkSpeed ~= Character:GetAttribute('Walkspeed')
        end

        Humanoid.WalkSpeed = enabled and Options.SprintSpeed.Value or 20

        if Toggles.NoSprintAndRollCost.Value then
            RequiredServices.Graphics.DoEffect('Sprint Trail', { Enabled = enabled, Character = Character })
            Event:FireServer('Actions', { 'Sprint', enabled and 'Enabled' or 'Disabled' })
        end
    end

    local rollSkillHandler = RequiredServices.Skills.skillHandlers.Roll
    local rollCost = Skills.Roll.Cost.Value

    AdditionalCheats:AddToggle('NoSprintAndRollCost', { Text = 'No sprint & roll cost' })
    :OnChanged(function(value)
        debug.setconstant(rollSkillHandler, 6, value and '' or 'UseSkill')
        Skills.Roll.Cost.Value = value and 0 or rollCost
    end)

    AdditionalCheats:AddSlider('SprintSpeed', {
        Text = 'Sprint speed',
        Default = 27,
        Min = 27,
        Max = 100,
        Rounding = 0,
        Suffix = 'mps',
        FormatDisplayValue = function(slider, value)
            if value == slider.Min then return 'Default' end
        end
    })
else
    UserInputService.InputEnded:Connect(function(key, gameProcessed)
        if gameProcessed or key.KeyCode.Name ~= Profile.Settings.SprintKey.Value then return end
        Humanoid.WalkSpeed = Options.WalkSpeed.Value
    end)

    AdditionalCheats:AddSlider('WalkSpeed', { Text = 'Walk speed', Default = 20, Min = 20, Max = 100, Rounding = 0, Suffix = 'mps' })
    :OnChanged(function(value)
        Humanoid.WalkSpeed = value
    end)
end

AdditionalCheats:AddToggle('Fly', { Text = 'Fly' }):OnChanged(function()
    toggleLerp(Toggles.Fly)
    enableLinearVelocity(Toggles.Fly.Value)
    while Toggles.Fly.Value do
        local deltaTime = task.wait()
        if not (controls.D - controls.A == 0 and controls.S - controls.W == 0) then
            local flySpeed = 80 -- math.max(Humanoid.WalkSpeed, 60)
            local targetPos = Camera.CFrame.Rotation
                * Vector3.new(controls.D - controls.A, 0, controls.S - controls.W)
                * flySpeed * deltaTime
            HumanoidRootPart.CFrame += targetPos
                * math.clamp(deltaTime * flySpeed / targetPos.Magnitude, 0, 1)
            continue
        end
    end
end)

AdditionalCheats:AddToggle('Noclip', { Text = 'Noclip' }):OnChanged(function()
    toggleNoclip(Toggles.Noclip)
end)

AdditionalCheats:AddToggle('ClickTeleport', { Text = 'Click teleport' }):OnChanged((function()
    local mouse = LocalPlayer:GetMouse()
    local Button1DownConnection
    local teleporting = false
    local onButton1Down = function()
        if not Toggles.ClickTeleport.Value then return end
        if teleporting then return end
        teleporting = true
        HumanoidRootPart.CFrame = HumanoidRootPart.CFrame.Rotation + mouse.Hit.Position + Vector3.new(0, 3, 0)
        teleporting = false
    end
    return function(value)
        toggleLerp(Toggles.ClickTeleport)
        enableLinearVelocity(false)
        if value then
            if Button1DownConnection then return end
            Button1DownConnection = mouse.Button1Down:Connect(onButton1Down)
        elseif Button1DownConnection then
            Button1DownConnection:Disconnect()
            Button1DownConnection = nil
        end
    end
end)())

local mapTeleports = {}

AdditionalCheats:AddDropdown('MapTeleports', { Text = 'Map teleports', Values = { 'Spawn' }, AllowNull = true })
:OnChanged(function(value)
    if not value then return end
    Options.MapTeleports:SetValue()

    local disabledToggle = toggleLerp()

    if value == 'Spawn' then
        Event:FireServer('Checkpoints', { 'TeleportToSpawn' })
    elseif firetouchinterest then
        firetouchinterest(HumanoidRootPart, mapTeleports[value], 0)
        firetouchinterest(HumanoidRootPart, mapTeleports[value], 1)
    end

    if disabledToggle then
        task.wait()
        awaitEventTimeout(HumanoidRootPart:GetPropertyChangedSignal('CFrame'), function()
            return true
        end, 0.5)
        disabledToggle:SetValue(true)
    end
end)

local mobSpawns = {}
local mobSpawnLabels = {}
do
    local index = 1
    for _, instance in next, workspace:GetChildren() do
        if not instance.Name:find("ASpawn") then
            continue
        end
        mobSpawns[instance.Name] = instance.WorldPivot
        mobSpawnLabels[index] = instance.Name
        index += 1
    end
end


AdditionalCheats:AddDropdown('MapMobSpawns', { Text = 'Map mob spawns', Values = mobSpawnLabels, AllowNull = true })
:OnChanged(function(value)
    if not value then return end
    Options.MapMobSpawns:SetValue()

    local disabledToggle = toggleLerp()

    HumanoidRootPart.CFrame = mobSpawns[value]

    if disabledToggle then
        disabledToggle:SetValue(true)
    end
end)

task.spawn(function()
    local mapTeleportLabels = ({
        [542351431] = { -- floor 1
            Boss = Vector3.new(-2942.51099, -125.638321, 336.995087),
            Portal = Vector3.new(-2940.8562, -207.597794, 982.687012),
            Miniboss = Vector3.new(139.343933, 225.040985, -132.926147)
        },
        [548231754] = { -- floor 2
            Boss = Vector3.new(-2452.30371, 411.394135, -8925.62598),
            Portal = Vector3.new(-2181.09204, 466.482727, -8955.31055)
        },
        [555980327] = { -- floor 3
            Boss = Vector3.new(448.331146, 4279.3374, -385.050385),
            Portal = Vector3.new(-381.196564, 4184.99902, -327.238312)
        },
        [572487908] = { -- floor 4
            Boss = Vector3.new(-2318.12964, 2280.41992, -514.067749),
            Portal = Vector3.new(-2319.54028, 2091.30078, -106.37648),
            Miniboss = Vector3.new(-1361.35596, 5173.21387, -390.738007)
        },
        [580239979] = { -- floor 5
            Boss = Vector3.new(2189.17822, 1308.125, -121.071182),
            Portal = Vector3.new(2188.29614, 1255.37036, -407.864594)
        },
        [582198062] = { -- floor 7
            Boss = Vector3.new(3347.78955, 800.043884, -804.310425),
            Portal = Vector3.new(3336.35645, 747.824036, -614.307983)
        },
        [548878321] = { -- floor 8
            Boss = Vector3.new(1848.35413, 4110.43945, 7723.38623),
            Portal = Vector3.new(1665.46252, 4094.20312, 7722.29443),
            Miniboss = Vector3.new(-811.7854, 3179.59814, -949.255676)
        },
        [573267292] = { -- floor 9
            Boss = Vector3.new(12241.4648, 461.776215, -3655.09009),
            Portal = Vector3.new(12357.0059, 439.948914, -3470.23218),
            Miniboss = Vector3.new(-255.197311, 3077.04272, -4604.19238),
            ['Second miniboss'] = Vector3.new(1973.94238, 2986.00952, -4486.8125)
        },
        [2659143505] = { -- floor 10
            Boss = Vector3.new(45.494194, 1003.77246, 25432.9902),
            Portal = Vector3.new(110.383698, 940.75531, 24890.9922),
            Miniboss = Vector3.new(-894.185791, 467.646698, 6505.85254)
        },
        [5287433115] = { -- floor 11
            Boss = Vector3.new(4916.49414, 2312.97021, 7762.28955),
            Portal = Vector3.new(5224.18994, 2602.94019, 6438.44678),
            Miniboss = Vector3.new(4801.12695, 1646.30347, 2083.19116),
            ['Za, the Eldest'] = Vector3.new(4001.55908, 421.515015, -3794.19727),
            ['Wa, the Curious'] = Vector3.new(4821.5874, 3226.32788, 5868.81787),
            ['Duality Reaper  '] = Vector3.new(4763.06934, 501.713593, -4344.83838),
            ['Neon chest       '] = Vector3.new(5204.35449, 2294.14502, 5778.00195)
        },
        [6144637080] = { -- floor 12
            ['Suspended Unborn'] = Vector3.new(-5324.62305, 427.934784, 3754.23682),
            ['Limor the Devourer'] = Vector3.new(-1093.02625, -169.141785, 7769.1875),
            ['Radioactive Experiment'] = Vector3.new(-4643.86816, 425.090515, 3782.8252)
        }
    })[game.PlaceId] or {}

    local unstreamedMapTeleports = ({
        [555980327] = { -- floor 3
            Vector3.new(-381, 4185, -327), Vector3.new(448, 4279, -385), Vector3.new(-375, 3938, 502), Vector3.new(1180, 6738, 1675)
        },
        [582198062] = { -- floor 7
            Vector3.new(3336, 748, -614), Vector3.new(3348, 800, -804), Vector3.new(1219, 1084, -274), Vector3.new(1905, 729, -327)
        },
        [5287433115] = { -- floor 11
            Vector3.new(5087, 217, 298), Vector3.new(5144, 1035, 298), Vector3.new(4510, 419, -2418), Vector3.new(3457, 465, -3474), Vector3.new(4632, 155, 950),
            Vector3.new(4629, 138, 1008), Vector3.new(5445, 2587, 6324), Vector3.new(5226, 2356, 6451), Vector3.new(5134, 1630, 2501), Vector3.new(5151, 1953, 4508),
            Vector3.new(5505, 1000, -5552), Vector3.new(4247, 507, -4774), Vector3.new(4977, 118, 1495), Vector3.new(5138, 416, 1676), Vector3.new(10827, 1565, -2375),
            Vector3.new(3633, 1767, 2662), Vector3.new(4208, 369, 939), Vector3.new(1029, 13, 686), Vector3.new(4835, 2543, 5275), Vector3.new(5204, 2294, 5778),
            Vector3.new(6054, 182, 965), Vector3.new(5354, 1001, -5465), Vector3.new(4626, 119, 960), Vector3.new(4617, 138, 1008), Vector3.new(521, 123, 346),
            Vector3.new(1034, 9, -345), Vector3.new(4801, 1646, 2083), Vector3.new(4846, 1640, 2091), Vector3.new(5182, 200, 1227), Vector3.new(5075, 127, 1287),
            Vector3.new(5174, 2035, 5702), Vector3.new(5205, 2259, 5684), Vector3.new(4684, 220, 215), Vector3.new(4476, 1245, -26), Vector3.new(3469, 405, -3555),
            Vector3.new(11911, 1572, -2100), Vector3.new(720, 139, 109), Vector3.new(3194, 1764, 647), Vector3.new(4642, 2337, 5969), Vector3.new(5161, 3230, 6034),
            Vector3.new(5208, 2290, 6370), Vector3.new(4916, 2400, 7751), Vector3.new(4655, 405, -3199), Vector3.new(4690, 462, -3423), Vector3.new(5209, 2350, 5915),
            Vector3.new(5334, 3231, 5589), Vector3.new(5225, 2602, 6434), Vector3.new(4916, 2310, 7764), Vector3.new(5224, 2603, 6438), Vector3.new(4916, 2313, 7762),
            Vector3.new(5542, 1001, -5465), Vector3.new(4565, 405, -2917), Vector3.new(4563, 405, -2621), Vector3.new(4528, 405, -2396), Vector3.new(4982, 2587, 6321),
            Vector3.new(5215, 2356, 6451), Vector3.new(4763, 502, -4345), Vector3.new(5900, 853, -4256), Vector3.new(4822, 3226, 5869), Vector3.new(5292, 3224, 6044),
            Vector3.new(5055, 3224, 5706), Vector3.new(5389, 3224, 5774), Vector3.new(4002, 422, -3794), Vector3.new(2094, 939, -6307)
        },
        [6144637080] = { -- floor 12
            Vector3.new(-182, 178, 6148), Vector3.new(-939, -171, 6885), Vector3.new(-714, 143, 4961), Vector3.new(-418, 183, 5650), Vector3.new(-1093, -169, 7769),
            Vector3.new(-301, -319, 7953), Vector3.new(-2290, 242, 3090), Vector3.new(-3163, 221, 3284), Vector3.new(-4268, 217, 3785), Vector3.new(-4644, 425, 3783),
            Vector3.new(-2446, 49, 4145), Vector3.new(-5325, 428, 3754), Vector3.new(-404, 198, 5562), Vector3.new(-419, 177, 5648)
        }
    })[game.PlaceId] or {}

    for _, position in next, unstreamedMapTeleports do
        LocalPlayer:RequestStreamAroundAsync(position)
    end

    local teleportSystems = {}
    for _, instance in next, workspace:GetChildren() do
        if instance.Name ~= 'TeleportSystem' then continue end
        table.insert(teleportSystems, {})
        for _, part in next, instance:GetChildren() do
            if part.Name ~= 'Part' then continue end
            table.insert(teleportSystems[#teleportSystems], part)
            local locationName = #mapTeleports + 1
            for name, position in next, mapTeleportLabels do
                if part.CFrame.Position ~= position then continue end
                locationName = name
                break
            end
            mapTeleports[locationName] = part
            table.insert(Options.MapTeleports.Values, locationName)
        end
    end

    if game.PlaceId == 566212942 then -- floor 6
        mapTeleports['Undershroud'] = workspace:WaitForChild('Portal'):WaitForChild('TouchPart')
        table.insert(Options.MapTeleports.Values, 'Undershroud')
    elseif game.PlaceId == 6144637080 then -- floor 12
        LocalPlayer:RequestStreamAroundAsync(Vector3.new(-2415.14258, 128.760483, 6343.8584))
        mapTeleports['Atheon'] = workspace:WaitForChild('AtheonPortal')
        table.insert(Options.MapTeleports.Values, 'Atheon')
    end

    table.sort(Options.MapTeleports.Values, function(a, b)
        if type(a) == 'string' then
            if type(b) == 'string' then
                return #a < #b
            else
                return true
            end
        elseif type(b) == 'number' then
            return a < b
        end
    end)

    Options.MapTeleports:SetValues(Options.MapTeleports.Values)
end)

-- local proximityPromptIndex = 0
-- local proximityPrompts = {}
-- local proximityPromptNames = {}
-- for _, proximityPrompt in next, game:GetDescendants() do
--     if proximityPrompt.ClassName ~= 'ProximityPrompt' then continue end
--     proximityPromptIndex += 1
--     local name = `{proximityPrompt.Parent.Parent.Name} {proximityPromptIndex}`
--     proximityPrompts[name] = proximityPrompt
--     table.insert(proximityPromptNames, name)
-- end

-- AdditionalCheats:AddDropdown('FireProximityPrompts', {
--     Text = 'Fire proximityprompts',
--     Values = proximityPromptNames,
--     AllowNull = true
-- }):OnChanged(function(proximityPromptName)
--     if not proximityPromptName then return end
--     Options.FireProximityPrompts:SetValue()

--     local proximityPrompt = proximityPrompts[proximityPromptName]
--     if proximityPrompt.Parent and proximityPrompt.Parent.Parent then
--         HumanoidRootPart.CFrame = proximityPrompt.Parent.Parent.CFrame
--         fireproximityprompt(proximityPrompt)
--     end
-- end)

local ServerHopBox = Main:AddRightGroupbox('Server Hop')

local TeleportService = game:GetService('TeleportService')
local isHopping = false

local function hopToEmptyServer()
    if isHopping then return end
    isHopping = true
    Library:Notify('Buscando novo servidor via TeleportService...', 5)

    task.spawn(function()
        local placeId = game.PlaceId
        pcall(function()
            TeleportService:Teleport(placeId, LocalPlayer)
        end)
        task.wait(8)
        isHopping = false
    end)
end

ServerHopBox:AddToggle('AutoServerHop', { Text = 'Hop when player joins' })
ServerHopBox:AddToggle('SoloOnly', { Text = 'Solo only (Hop if > 0 players)' })
ServerHopBox:AddButton({ Text = 'Hop to new server now', Func = hopToEmptyServer })

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer and Toggles.AutoServerHop and Toggles.AutoServerHop.Value then
        Library:Notify(`Player {player.Name} joined! Hopping server...`, 5)
        task.wait(1.5)
        hopToEmptyServer()
    end
end)

task.spawn(function()
    while true do
        task.wait(5)
        if Toggles.SoloOnly and Toggles.SoloOnly.Value then
            local otherPlayers = #Players:GetPlayers() - 1
            if otherPlayers > 0 and not isHopping then
                Library:Notify(`{otherPlayers} other player(s) in server. Hopping...`, 5)
                hopToEmptyServer()
            end
        end
    end
end)

local Miscs = Main:AddLeftTabbox()

local Misc1 = Miscs:AddTab('Misc')

local AnimPackNames = {}
for _, AnimPack in next, game:GetService('StarterPlayer').StarterCharacterScripts.Animate.Packs:GetChildren() do
    table.insert(AnimPackNames, AnimPack.Name)
end

local getCurrentAnimSetting = function()
    if leftSword then return 'DualWield' end
    if not rightSword then return 'Unarmed' end
    local SwordClass = Items[rightSword.Name].Class.Value
    return SwordClass == '1HSword' and 'SingleSword' or SwordClass
end

local animPackAnimSettings = {
    Berserker = '2HSword',
    Ninja = 'Katana',
    Noble = 'SingleSword',
    Vigilante = 'DualWield',
    SwissSabre = 'Rapier',
    Swiftstrike = 'Spear',
    Reaper = 'Scythe'
}

local unownedAnimPacks = {}
for animPackName, swordClass in next, animPackAnimSettings do
    if Gamepasses:FindFirstChild(animPackName) then continue end
    local animPack = Instance.new('StringValue')
    animPack.Name = animPackName
    animPack.Value = swordClass
    unownedAnimPacks[animPackName] = animPack
end

Misc1:AddDropdown('ChangeAnimationPack', {
    Text = 'Change animation pack',
    Values = AnimPackNames,
    AllowNull = true
}):OnChanged(function(animPackName)
    if not animPackName then return end
    Options.ChangeAnimationPack:SetValue()
    local swordClass = getCurrentAnimSetting()
    local animSetting = Profile.AnimSettings[swordClass]
    animSetting.Value = animSetting.Value == animPackName and '' or animPackName
end)

Misc1:AddToggle('UnlockAllAnimations', { Text = 'Unlock all animations' }):OnChanged(function(value)
    for _, animPack in next, unownedAnimPacks do
        animPack.Parent = value and Gamepasses or nil
    end
end)

PlayerUI.MainFrame.TabFrames.Settings.Attachments.AnimPacks.ChildAdded:Connect(function(entry)
    entry.Activated:Connect(function()
        local animPackName = (function()
            for _, item in next, Database.CashShop:GetChildren() do
                if item.Icon.Texture ~= entry.Frame.Icon.Image then continue end
                return item.Name:gsub(' Animation Pack', ''):gsub(' ', '')
            end
        end)()
        if not unownedAnimPacks[animPackName] then return end
        local swordClass = animPackAnimSettings[animPackName]
        local animSetting = Profile.AnimSettings[swordClass]
        animSetting.Value = animSetting.Value == animPackName and '' or animPackName
    end)
end)

local chatSize = Chat.Size
local chatSizeStretched = UDim2.fromScale(Chat.Size.X.Scale, Chat.Size.Y.Scale * 2)
Misc1:AddToggle('StretchChat', { Text = 'Stretch chat' }):OnChanged(function(value)
    Chat.Size = value and chatSizeStretched or chatSize
end)

Camera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
    if not Toggles.StretchChat.Value then return end
    Chat.Size = UDim2.new(0, 600, 0, Camera.ViewportSize.Y - 177)
end)

local defaultCameraMaxZoomDistance = LocalPlayer.CameraMaxZoomDistance

Misc1:AddToggle('InfiniteZoomDistance', { Text = 'Infinite zoom distance' })
:OnChanged(function(value)
    LocalPlayer.CameraMaxZoomDistance = value and math.huge or defaultCameraMaxZoomDistance
    LocalPlayer.DevCameraOcclusionMode = value and 1 or 0
end)

Misc1:AddDropdown('PerformanceBoosters', {
    Text = 'Performance boosters',
    Values = {
        'No damage text',
        'No damage particles',
        'Delete dead mobs',
        'No vel obtained in chat',
        'Disable rendering',
        'Limit FPS'
    },
    Multi = true,
    AllowNull = true
}):OnChanged(function(values)
    RunService:Set3dRenderingEnabled(not values['Disable rendering'])
    if setfpscap then
        setfpscap(values['Limit FPS'] and 15 or UserSettings():GetService('UserGameSettings').FramerateCap)
    end
end)

workspace:WaitForChild('HitEffects').ChildAdded:Connect(function(hitPart)
    if not Options.PerformanceBoosters.Value['No damage particles'] then return end
    task.wait()
    hitPart:Destroy()
end)

if RequiredServices then
    local GraphicsServerEventOld = RequiredServices.Graphics.ServerEvent
    RequiredServices.Graphics.ServerEvent = function(...)
        local args = {...}
        if args[1][1] == 'Damage Text' then
            if Options.PerformanceBoosters.Value['No damage text'] then return end
        elseif args[1][1] == 'KillFade' then
            if Options.PerformanceBoosters.Value['Delete dead mobs'] then
                return args[1][2]:Destroy()
            end
        end
        return GraphicsServerEventOld(...)
    end

    local UIServerEventOld = RequiredServices.UI.ServerEvent
    RequiredServices.UI.ServerEvent = function(...)
        local args = {...}
        if args[1][2] == 'VelObtained' then
            if Options.PerformanceBoosters.Value['No vel obtained in chat'] then return end
        end
        return UIServerEventOld(...)
    end
else
    workspace.ChildAdded:Connect(function(part)
        if not Options.PerformanceBoosters.Value['Damage Text'] then return end
        if part:IsA('Part') then return end
        if not part:WaitForChild('DamageText', 1) then return end
        part:Destroy()
    end)

    Chat.ScrollContent.ChildAdded:Connect(function(frame)
        if not Options.PerformanceBoosters.Value['No vel obtained in chat'] then return end
        if frame.Name ~= 'ChatVelTemplate' then return end
        frame.Visible = false
        frame.Size = UDim2.fromOffset(0, -5)
        frame:GetPropertyChangedSignal('Position'):Wait()
        frame:Destroy()
    end)
end

local Misc2 = Miscs:AddTab('More misc')

local equipBestWeapon = function()
    if not Toggles.EquipBestWeapon.Value then return end
    if rightSword and Items[rightSword.Name].Level.Value > getLevel() then return end

    local highestDamage = 0
    local bestKatana = false
    local highestStamina = 0
    local bestWeapon

    for _, item in next, Inventory:GetChildren() do
        local inDatabase = Items[item.Name]
        local level = inDatabase:FindFirstChild('Level') and inDatabase.Level.Value or 0
        if level > getLevel() then continue end
        local itemType = inDatabase.Type.Value
        if itemType ~= 'Weapon' then continue end
        local damage = getItemDamageOrDefense(item)
        local isKatana = inDatabase.Class.Value == 'Katana'
        local stamina = inDatabase:FindFirstChild('Buffs')
            and inDatabase.Buffs:FindFirstChild('StaminaRegeneration')
            and inDatabase.Buffs.StaminaRegeneration.Value
            or 0
        if (
			damage > highestDamage or (
                damage == highestDamage and isKatana and (
                    not bestKatana or stamina > highestStamina
                )
            )
        ) then
            highestDamage = damage
            bestKatana = isKatana
            highestStamina = stamina
            bestWeapon = item
        end
    end

    if bestWeapon and Equip.Right.Value ~= bestWeapon.Value then
        InvokeFunction('Equipment', { 'EquipWeapon', bestWeapon, 'Right' })
    end
end

local equipBestArmor = function()
    if not Toggles.EquipBestArmor.Value then return end
    local armor = getItemById(Equip.Clothing.Value)
    if armor and Items[armor.Name].Level.Value > getLevel() then return end

    local highestDefense = 0
    local highestStamina = 0
    local bestArmor

    for _, item in next, Inventory:GetChildren() do
        local inDatabase = Items[item.Name]
        local level = inDatabase:FindFirstChild('Level') and inDatabase.Level.Value or 0
        if level > getLevel() then continue end
        local itemType = inDatabase.Type.Value
        if itemType ~= 'Clothing' then continue end
        local defense = getItemDamageOrDefense(item)
        local stamina = inDatabase:FindFirstChild('Buffs')
            and inDatabase.Buffs:FindFirstChild('StaminaRegeneration')
            and inDatabase.Buffs.StaminaRegeneration.Value
            or 0
        if defense > highestDefense or (
            defense == highestDefense and stamina > highestStamina
        ) then
            highestDefense = defense
            highestStamina = stamina
            bestArmor = item
        end
    end

    if bestArmor and Equip.Clothing.Value ~= bestArmor.Value then
        InvokeFunction('Equipment', { 'Wear', bestArmor })
    end
end

local equipBestAccessory = function()
    if not Toggles.EquipBestAccessory.Value then return end

    local highestStamina = 0
    local highestDefense = 0
    local highestHealth = 0
    local bestAccessory

    for _, item in next, Inventory:GetChildren() do
        local inDatabase = Items[item.Name]
        local level = inDatabase:FindFirstChild('Level') and inDatabase.Level.Value or 0
        if level > getLevel() then continue end
        local itemType = inDatabase.Type.Value
        if itemType ~= 'Accessory' then continue end
        local Buffs = inDatabase:FindFirstChild('Buffs')
        if not Buffs then continue end
        local stamina = Buffs:FindFirstChild('StaminaRegeneration')
            and Buffs.StaminaRegeneration.Value
            or 0
        local health = Buffs:FindFirstChild('HealthRegeneration')
            and Buffs.HealthRegeneration.Value
            or 0
        local defense = inDatabase:FindFirstChild('Stats')
            and inDatabase.Stats:FindFirstChild('Defense')
            and inDatabase.Stats.Defense.Value
            or 0
        if stamina > highestStamina or (
            stamina == highestStamina and (
                defense > highestDefense or (
                    defense == highestDefense and health > highestHealth
                )
            )
        ) then
            highestStamina = stamina
            highestDefense = defense
            highestHealth = health
            bestAccessory = item
        end
    end

    if not bestAccessory then return end

    local accessory1 = Equip:FindFirstChild('Accessory1') and Equip.Accessory1.Value or 0
    local accessory2 = Equip:FindFirstChild('Accessory2') and Equip.Accessory2.Value or 0
    if accessory1 ~= bestAccessory.Value or accessory2 ~= bestAccessory.Value then
        InvokeFunction('Equipment', { 'Wear', bestAccessory })
        if accessory2 ~= 0 then
            InvokeFunction('Equipment', { 'Unequip', accessory2 })
        end
        InvokeFunction('Equipment', { 'Wear', bestAccessory })
    end
end

Misc2:AddToggle('EquipBestWeapon', { Text = 'Equip best weapon' }):OnChanged(equipBestWeapon)
Misc2:AddToggle('EquipBestArmor', { Text = 'Equip best armor' }):OnChanged(equipBestArmor)
Misc2:AddToggle('EquipBestAccessory', { Text = 'Equip best accessory' }):OnChanged(equipBestAccessory)
Inventory.ChildAdded:Connect(equipBestWeapon)
Level.Changed:Connect(equipBestWeapon)

Misc2:AddToggle('ReturnOnDeath', { Text = 'Return on death' })
Misc2:AddToggle('ResetOnLowStamina', { Text = 'Reset on low stamina' })

Misc2:AddToggle('AutoJoinNewFloor', { Text = 'Auto join new floor' })
Profile.Locations.ChildAdded:Connect(function(location)
    if not Toggles.AutoJoinNewFloor.Value then
        return
    end

    while true do
        local success, response = pcall(Function.InvokeServer, Function, 'Teleport', {
            'Teleport',
            tonumber(location.Name)
        })
        -- print(response)
        if not success then
        elseif not response or response == 'Already teleporting...' then
            local teleporting = Profile:WaitForChild('TELEPORTING', 1)
            teleporting = teleporting and teleporting.Destroying:Wait()
            break
        elseif response == 'You must be on a teleport pad to teleport!' then
            if Profile:FindFirstChild('Checkpoint') then
                Event:FireServer('Checkpoints', { 'TeleportToSpawn' })
            else
                Humanoid.Health = 0
            end
        else
            break
        end
        task.wait(0.3)
    end
end)

-- if setfflag
--     and pcall(setfflag, "NextGenReplicatorEnabledWrite4", "True")
--     and pcall(setfflag, "NextGenReplicatorEnabledWrite4", "False")
-- then
--     Misc2:AddToggle('Desync', { Text = 'Desync' }):OnChanged(function(value)
--         desyncChanged = true
--         setfflag("NextGenReplicatorEnabledWrite4", value and "True" or "False")
--         task.wait(0.1)
--         Humanoid.Health = 0
--     end)
-- end

local Misc = Window:AddTab('Misc', 'shuffle')

local ItemsBox = Misc:AddLeftGroupbox('Items')

if RequiredServices then
    local UIModule = RequiredServices.UI
    ItemsBox:AddButton({ Text = 'Open upgrade', Func = UIModule.openUpgrade })
    ItemsBox:AddButton({ Text = 'Open dismantle', Func = UIModule.openDismantle })
    ItemsBox:AddButton({ Text = 'Open forge', Func = UIModule.openCrystalForge })
end

local unboxableItems = {}
local unboxableItemNames = {}

local function addUnboxable(item, dontRefreshDropdown)
    if not unboxableItems[item.Name] and Items[item.Name]:FindFirstChild('Unboxable') then
        unboxableItems[item.Name] = item
        table.insert(unboxableItemNames, item.Name)
        if not dontRefreshDropdown then
            Options.UseItem:SetValues(Options.UseItem.Values)
        end
    end
end

for _, item in next, Inventory:GetChildren() do
    addUnboxable(item, true)
end

Inventory.ChildAdded:Connect(addUnboxable)
Inventory.ChildRemoved:Connect(function(item)
    if unboxableItems[item.Name] then
        unboxableItems[item.Name] = nil
        table.remove(unboxableItemNames, table.find(unboxableItemNames, item.Name))
        Options.UseItem:SetValues(Options.UseItem.Values)
    end
end)

ItemsBox:AddDropdown('UseItem', { Text = 'Use item(s)', Values = unboxableItemNames, AllowNull = true })
:OnChanged(function(itemName)
    if not itemName then return end
    Options.UseItem:SetValue()

    local item = unboxableItems[itemName]
    if not item then return end

    Function:InvokeServer('Equipment', { 'UseItem', item, 1 })
end)

do
    local connection
    ItemsBox:AddToggle("FreeCommonCrystals", { Text = "Free common crystals" })
    :OnChanged(function(value)
        if not value then
            if connection then
                connection:Disconnect()
            end
            return
        end

        for _, item in next, Inventory:GetChildren() do
            if item.Name == "Blue Novice Armor" then
                noviceArmor = item
                break
            elseif item.Name:find(" Novice Armor") then
                noviceArmor = item
            end
        end

        if not noviceArmor then
            Library:Notify("Get a novice armor first")
            return
        end

        InvokeFunction("Equipment", { "Wear", noviceArmor })
        Event:FireServer(
            "Equipment", {
                "Dismantle",
                { noviceArmor }
            }
        )
        Humanoid.Health = 0

        connection = Inventory.ChildAdded:Connect(function(item)
            if item.Name == "Blue Novice Armor" then
                noviceArmor = item
            end
        end)
    end)
end

local PlayersBox = Misc:AddRightGroupbox('Players')

local selectedPlayer

PlayersBox:AddDropdown('PlayerList', { Text = 'Player list', Values = {}, SpecialType = 'Player' })
:OnChanged(function(player)
    selectedPlayer = player

    if RequiredServices and Toggles.ViewPlayersInventory and Toggles.ViewPlayersInventory.Value then
        debug.setupvalue(RequiredServices.InventoryUI.GetInventoryData, 2, Profiles[player.Name])
    end
end)

PlayersBox:AddButton({ Text = "View player's stats", Func = function()
    if not Options.PlayerList.Value then return end

    pcall(function()
        local profile = Profiles:FindFirstChild(selectedPlayer.Name)

        if profile.Locations:FindFirstChild('1') then
            profile.Locations['1']:Destroy()
        end

        local stats = {
            -- AnimPacks = 'no',
            Gamepasses = 'no',
            Skills = 'no'
        }

        for statName, _ in next, stats do
            local statChildrenNames = {}
            for _, stat in next, profile[statName]:GetChildren() do
                table.insert(statChildrenNames, stat.Name)
            end
            if #statChildrenNames > 0 then
                stats[statName] = 'the ' .. table.concat(statChildrenNames, ', '):lower()
            end
        end

		Library:Notify(
			`{selectedPlayer.Name}'s account is {selectedPlayer.AccountAge} days old,\n`
				.. `level {getLevel(profile.Stats.Exp.Value)},\n`
				.. `has {profile.Stats.Vel.Value} vel,\n`
				.. `floor {#profile.Locations:GetChildren() - 2},\n`
				-- .. `{stats.AnimPacks} animation packs bought,\n`
				.. `{stats.Gamepasses} gamepasses bought,\n`
				.. `and {stats.Skills} special skills unlocked`,
			10
		)
    end)
end })

if RequiredServices then
    PlayersBox:AddToggle('ViewPlayersInventory', { Text = `View player's inventory` }):OnChanged(function(value)
        if not value then
            debug.setupvalue(RequiredServices.InventoryUI.GetInventoryData, 2, Profile)
            return
        end

        local player = Options.PlayerList.Value
        if not player then return end
        debug.setupvalue(RequiredServices.InventoryUI.GetInventoryData, 2, Profiles[player.Name])
    end)
end

PlayersBox:AddToggle('ViewPlayer', { Text = 'View player' }):OnChanged(function(value)
    if not value then return end
    while Toggles.ViewPlayer.Value do
        if selectedPlayer and not isDead(selectedPlayer.Character) then
            Camera.CameraSubject = selectedPlayer.Character
        end
        task.wait(0.1)
    end
    Camera.CameraSubject = Character
end)

PlayersBox:AddToggle('GoToPlayer', { Text = 'Go to player' }):OnChanged(function(value)
    toggleLerp(Toggles.GoToPlayer)
    enableLinearVelocity(Toggles.GoToPlayer.Value)
    toggleNoclip(Toggles.GoToPlayer)
    if not value then return end
    while Toggles.GoToPlayer.Value do
        task.wait()

        if not selectedPlayer or isDead(selectedPlayer.Character) then continue end

        local rootPart = selectedPlayer.Character.HumanoidRootPart

        HumanoidRootPart.CFrame = rootPart.CFrame +
            Vector3.new(Options.XOffset.Value, Options.YOffset.Value, Options.ZOffset.Value)
    end
end)

PlayersBox:AddSlider('XOffset', { Text = 'X offset', Default = 0, Min = -20, Max = 20, Rounding = 0 })
PlayersBox:AddSlider('YOffset', { Text = 'Y offset', Default = 5, Min = -20, Max = 20, Rounding = 0 })
PlayersBox:AddSlider('ZOffset', { Text = 'Z offset', Default = 0, Min = -20, Max = 20, Rounding = 0 })

local Drops = Misc:AddLeftGroupbox('Drops')

local Rarities = { 'Common', 'Uncommon', 'Rare', 'Legendary', 'Tribute' }

Drops:AddDropdown('AutoDismantle', { Text = 'Auto dismantle', Values = Rarities, Multi = true, AllowNull = true })

Drops:AddInput('DropWebhook', { Text = 'Drop webhook', Placeholder = 'https://discord.com/api/webhooks/' })
:OnChanged(sendTestMessage)

Drops:AddToggle('PingInMessage', { Text = 'Ping in message' })

Drops:AddDropdown('RaritiesForWebhook', { Text = 'Rarities for webhook', Values = Rarities, Default = Rarities, Multi = true, AllowNull = true })

local dropList = {}

Drops:AddDropdown('DropList', { Text = 'Drop list (select to dismantle)', Values = {}, AllowNull = true })
:OnChanged(function(dropName)
    if not dropName then return end
    Options.DropList:SetValue()
    Event:FireServer('Equipment', { 'Dismantle', { dropList[dropName] } })
    dropList[dropName] = nil
    table.remove(Options.DropList.Values, table.find(Options.DropList.Values, dropName))
end)

local rarityColors = {
    Empty = Color3.fromRGB(127, 127, 127),
    Common = Color3.fromRGB(255, 255, 255),
    Uncommon = Color3.fromRGB(64, 255, 102),
    Rare = Color3.fromRGB(25, 182, 255),
    Legendary = Color3.fromRGB(240, 69, 255),
    Tribute = Color3.fromRGB(255, 208, 98),
    Burst = Color3.fromRGB(81, 0, 1),
    Error = Color3.fromRGB(255, 255, 255)
}

Inventory.ChildAdded:Connect(function(item)
    local inDatabase = Items[item.Name]

    if item.Name:find('Novice') or item.Name:find('Aura') then return end

    local rarity = inDatabase.Rarity.Value

    if Options.AutoDismantle.Value[rarity] then
        return Event:FireServer('Equipment', { 'Dismantle', { item } })
    end

    if not Options.RaritiesForWebhook.Value[rarity] then return end

    local FormattedItem = os.date('[%I:%M:%S] ') .. item.Name
    dropList[FormattedItem] = item
    table.insert(Options.DropList.Values, 1, FormattedItem)
    Options.DropList:SetValues(Options.DropList.Values)
    sendWebhook(Options.DropWebhook.Value, {
        embeds = {{
            title = `You received {item.Name}!`,
            color = tonumber('0x' .. rarityColors[rarity]:ToHex()),
            fields = {
                {
                    name = 'User',
                    value = `||[{LocalPlayer.Name}](https://www.roblox.com/users/{LocalPlayer.UserId})||`,
                    inline = true
                }, {
                    name = 'Game',
                    value = `[{MarketplaceService:GetProductInfo(game.PlaceId).Name}](https://www.roblox.com/games/{game.PlaceId})`,
                    inline = true
                }, {
                    name = 'Item Stats',
                    value = `[Level {(inDatabase:FindFirstChild('Level') and inDatabase.Level.Value or 0)} {rarity}]`
                        .. `(https://swordburst2.fandom.com/wiki/{string.gsub(item.Name, ' ', '_')})`,
                    inline = true
                }
            }
        }}
    }, Toggles.PingInMessage.Value)
end)

local ownedSkillNames = {}

for _, skill in next, MySkills:GetChildren() do
    table.insert(ownedSkillNames, skill.Name)
end

MySkills.ChildAdded:Connect(function(skill)
    if table.find(ownedSkillNames, skill.Name) then return end
    table.insert(ownedSkillNames, skill.Name)

    local inDatabase = Skills[skill.Name]
    sendWebhook(Options.DropWebhook.Value, {
        embeds = {{
            title = `You received {skill.Name}!`,
            color = tonumber('0x' .. rarityColors.Burst:ToHex()),
            fields = {
                {
                    name = 'User',
                    value = `||[{LocalPlayer.Name}](https://www.roblox.com/users/{LocalPlayer.UserId})||`,
                    inline = true
                }, {
                    name = 'Game',
                    value = `[{MarketplaceService:GetProductInfo(game.PlaceId).Name}](https://www.roblox.com/games/{game.PlaceId})`,
                    inline = true
                }, {
                    name = 'Skill Stats',
                    value = `[Level {(inDatabase:FindFirstChild('Level') and inDatabase.Level.Value or 0)}]`
                        .. `(https://swordburst2.fandom.com/wiki/{string.gsub(skill.Name, ' ', '_')})`,
                    inline = true
                }
            }
        }}
    }, Toggles.PingInMessage.Value)
end)

local LevelsAndVelGained = Drops:AddLabel()

local levelsGained, velGained = 0, 0
local levelOld, velOld = getLevel(), Vel.Value

local UpdateLevelAndVel = function()
    local levelNew, velNew = getLevel(), Vel.Value
    levelsGained += levelNew > levelOld and levelNew - levelOld or 0
    velGained += velNew > velOld and velNew - velOld or 0
    LevelsAndVelGained:SetText(`{levelsGained} levels | {velGained} vel gained`)
    levelOld, velOld = levelNew, velNew
end

UpdateLevelAndVel()
Vel.Changed:Connect(UpdateLevelAndVel)
Level.Changed:Connect(UpdateLevelAndVel)

local KickBox = Misc:AddLeftTabbox()

local ModDetector = KickBox:AddTab('Mods')

local mods = {
    12671,
    4402987,
    7858636,
    13444058,
    24156180,
    35311411,
    38559058,
    45035796,
    48662268,
    50879012,
    51696441,
    55715138,
    57436909,
    59341698,
    60673083,
    62240513,
    66489540,
    68210875,
    72480719,
    75043989,
    76999375,
    81113783,
    90258662,
    93988508,
    101291900,
    102706901,
    104541778,
    109105759,
    111051084,
    121104177,
    129806297,
    151751026,
    154847513,
    154876159,
    161577703,
    161949719,
    163733925,
    167655046,
    167856414,
    173116569,
    184366742,
    194755784,
    220726786,
    225179429,
    269112100,
    271388254,
    309775741,
    349854657,
    354326302,
    357870914,
    358748060,
    367879806,
    371108489,
    373676463,
    429690599,
    434696913,
    440458342,
    448343431,
    454205259,
    455293249,
    461121215,
    478848349,
    500009807,
    533787513,
    542470517,
    571218846,
    575623917,
    630696850,
    810458354,
    852819491,
    874771971,
    918971121,
    1033291447,
    1033291716,
    1058240421,
    1099119770,
    1114937945,
    1190978597,
    1266604023,
    1379309318,
    1390415574,
    1416070243,
    1584345084,
    1607227678,
    1648776562,
    1650372835,
    1666720713,
    1728535349,
    1785469599,
    1794965093,
    1801714748,
    1868318363,
    1998442044,
    2034822362,
    2216826820,
    2324028828,
    2462374233,
    2787915712,
    360470140,
    2475151189,
    3522932153,
    3772282131,
    7557087747,
    5536587740,
    3931735673,
    33903799,
    22026533,
    417576199,
    80692318,
    102583875,
    492574273,
    468344010,
    1560324163
}

ModDetector:AddToggle('Autokick', { Text = 'Autokick' })
ModDetector:AddSlider('KickDelay', { Text = 'Kick delay', Default = 30, Min = 0, Max = 60, Rounding = 0, Suffix = 's', Compact = true })
ModDetector:AddToggle('Autopanic', { Text = 'Autopanic' })
ModDetector:AddSlider('PanicDelay', { Text = 'Panic delay', Default = 15, Min = 0, Max = 60, Rounding = 0, Suffix = 's', Compact = true })

local modCheck = function(player, leaving)
    if player == LocalPlayer or not table.find(mods, player.UserId) then return end
    Library:Notify(`Mod {player.Name} {leaving and 'left' or 'joined'} your game at {os.date('%I:%M:%S %p')}`, 60)

    if leaving then return end

    StarterGui:SetCore('PromptBlockPlayer', player)

    task.delay(Options.KickDelay.Value, function()
        if Toggles.Autokick.Value then
            LocalPlayer:Kick(`\n\n{player.Name} joined at {os.date('%I:%M:%S %p')}\n`)
        end
    end)

    task.delay(Options.PanicDelay.Value, function()
        if Toggles.Autopanic.Value then
            toggleLerp()
            enableLinearVelocity(false)
            Toggles.Killaura:SetValue(false)
            Event:FireServer('Checkpoints', { 'TeleportToSpawn' })
        end
    end)
end

for _, player in next, Players:GetPlayers() do
    task.spawn(modCheck, player)
end

Players.PlayerAdded:Connect(modCheck)

Players.PlayerRemoving:Connect(function(player)
    modCheck(player, true)
end)

local checkingModsIngame
ModDetector:AddButton({ Text = `Mods in game (don't use at spawn)`, Func = function()
    if checkingModsIngame then return end
    checkingModsIngame = {}
    Library:Notify('Checking profiles...')
    local counter = 0
    for _, userId in next, mods do
        task.spawn(function()
            local response = InvokeFunction('Teleport', { 'FriendTeleport', userId })
            if not response then return end

            if response:find('!$') and not response:find('error') then
                table.insert(checkingModsIngame, Players:GetNameFromUserIdAsync(userId))
            end

            counter += 1
            if counter ~= #mods then return end

            if #checkingModsIngame > 0 then
                Library:Notify('The mods that are currently in-game are: \n' .. table.concat(checkingModsIngame, ', \n'), 10)
            else
                Library:Notify('There are no mods in game')
            end

            checkingModsIngame = nil
        end)
    end
end })

local FarmingKicks = KickBox:AddTab('Kicks')

Level.Changed:Connect(function()
    local currentLevel = getLevel()
    if not (Toggles.LevelKick.Value and currentLevel == Options.KickLevel.Value) then return end
    LocalPlayer:Kick(`\n\nYou got to level {currentLevel} at {os.date('%I:%M:%S %p')}\n`)
end)

FarmingKicks:AddToggle('LevelKick', { Text = 'Level kick' })
FarmingKicks:AddSlider('KickLevel', { Text = 'Kick level', Default = 130, Min = 0, Max = 400, Rounding = 0, Compact = true })

MySkills.ChildAdded:Connect(function(skill)
    if not Toggles.SkillKick.Value then return end
    LocalPlayer:Kick(`\n\n{skill.Name} acquired at {os.date('%I:%M:%S %p')}\n`)
end)

FarmingKicks:AddToggle('SkillKick', { Text = 'Skill kick' })

FarmingKicks:AddInput('KickWebhook', { Text = 'Kick webhook', Finished = true, Placeholder = 'https://discord.com/api/webhooks/' })
:OnChanged(function()
    sendTestMessage(Options.KickWebhook.Value)
end)

game:GetService('GuiService').ErrorMessageChanged:Connect(function(message)
    local Body = {
        embeds = {{
            title = 'You were kicked!',
            color = tonumber('0x' .. rarityColors.Error:ToHex()),
            fields = {
                {
                    name = 'User',
                    value = `||[{LocalPlayer.Name}](https://www.roblox.com/users/{LocalPlayer.UserId})||`,
                    inline = true
                }, {
                    name = 'Game',
                    value = `[{MarketplaceService:GetProductInfo(game.PlaceId).Name}](https://www.roblox.com/games/{game.PlaceId})`,
                    inline = true
                }, {
                    name = 'Message',
                    value = message,
                    inline = true
                },
            }
        }}
    }

    sendWebhook(Options.KickWebhook.Value, Body, Toggles.PingInMessage.Value)
end)

local SwingCheats = Misc:AddRightGroupbox('Swing cheats (can debounce)')

if RequiredServices then
    local Actions = RequiredServices.Actions
    local StopSwingOld = Actions.StopSwing

    SwingCheats:AddToggle('Autoswing', { Text = 'Autoswing' }):OnChanged(function(value)
        if value then
            Actions.StopSwing = function() end
            Actions.StartSwing()
        else
            Actions.StopSwing = StopSwingOld
            StopSwingOld()
        end
    end)

    local AttackRequestOld = RequiredServices.Combat.AttackRequest
    RequiredServices.Combat.AttackRequest = function(...)
        local args = {...}
        if Toggles.OverrideBurstState.Value then
            debug.setupvalue(args[3], 2, Options.BurstState.Value)
        end
        return AttackRequestOld(...)
    end

    SwingCheats:AddToggle('OverrideBurstState', { Text = 'Override burst state' })
    SwingCheats:AddSlider('BurstState', { Text = 'Burst state', Default = 0, Min = 0, Max = 10, Rounding = 0, Suffix = ' hits', Compact = true })

    SwingCheats:AddDivider()
end

if swingFunction then
    SwingCheats:AddSlider('SwingDelay', { Text = 'Swing delay', Default = 0.55, Min = 0.25, Max = 0.85, Rounding = 2, Suffix = 's' })
    :OnChanged(function()
        debug.setconstant(swingFunction, 13, Options.SwingDelay.Value)
    end)

    SwingCheats:AddSlider('BurstDelayReduction', { Text = 'Burst delay reduction', Default = 0.2, Min = 0, Max = 0.4, Rounding = 2, Suffix = 's' })
    :OnChanged(function()
        debug.setconstant(swingFunction, 14, Options.BurstDelayReduction.Value)
    end)

    SwingCheats:AddDivider()
end

-- if RequiredServices then
--     SwingCheats:AddSlider('SwingThreads', { Text = 'Threads', Default = 1, Min = 1, Max = 10, Rounding = 0, Suffix = ' attack(s)' })

--     RequiredServices.Combat.DealDamage = function(target, attackName)
--         if Toggles.Killaura.Value or onCooldown[target] then return end

--         for _ = 1, Options.SwingThreads.Value do
--             dealDamage(target, attackName)
--         end

--         onCooldown[target] = true
--         task.delay(Options.SwingThreads.Value * 0.25, function()
--             onCooldown[target] = nil
--         end)
--     end
-- end

local inTrade = Instance.new('BoolValue')
local tradeLastSent = 0

local Crystals = Window:AddTab('Crystals', 'gem')

local Trading = Crystals:AddLeftGroupbox('Trading')
Trading:AddDropdown('TargetAccount', { Text = 'Target account', Values = {}, SpecialType = 'Player' })
:OnChanged(function()
    tradeLastSent = 0
end)

local CrystalCounter
CrystalCounter = {
    Given = {
        Value = 0,
        ThisCycle = 0,
        Label = Trading:AddLabel(),
        Update = function()
            CrystalCounter.Given.Label:SetText(
                `{CrystalCounter.Given.Value} ({math.floor(CrystalCounter.Given.Value / 64 * 10 ^ 5) / 10 ^ 5} stacks) given`
            )
        end
    },
    Received = {
        Value = 0,
        Label = Trading:AddLabel(),
        Update = function()
            CrystalCounter.Received.Label:SetText(
                `{CrystalCounter.Received.Value} ({math.floor(CrystalCounter.Received.Value / 64 * 10 ^ 5) / 10 ^ 5} stacks) received`
            )
        end
    }
}

CrystalCounter.Given.Update()
CrystalCounter.Received.Update()

Trading:AddButton({ Text = 'Reset counter', Func = function()
        CrystalCounter.Given.Value = 0
        CrystalCounter.Received.Value = 0
        CrystalCounter.Given.Update()
        CrystalCounter.Received.Update()
end })

local Giving = Crystals:AddRightGroupbox('Giving')

Giving:AddToggle('SendTrades', { Text = 'Send trades', Default = false }):OnChanged(function()
    CrystalCounter.Given.ThisCycle = 0
    while Toggles.SendTrades.Value do
        local target = Options.TargetAccount.Value
        if target and not inTrade.Value and tick() - tradeLastSent >= 0.5 then
            tradeLastSent = InvokeFunction('Trade', 'Request', { target }) and tick() or tick() - 0.4
        end
        task.wait()
    end
end)

Giving:AddInput('CrystalAmount', { Text = 'Crystal amount', Numeric = true, Finished = true, Placeholder = 1 })
:OnChanged(function(value)
    Options.CrystalAmount.Value = tonumber(value) or 1
end)

Giving:AddButton({ Text = 'Convert stacks to crystals', Func = function()
    Options.CrystalAmount:SetValue(math.ceil(Options.CrystalAmount.Value * 64))
end })

Giving:AddDropdown('CrystalType', { Text = 'Crystal type', Values = Rarities, AllowNull = true })
:OnChanged(function(crystalType)
    if not crystalType then return end
    if Inventory:FindFirstChild(crystalType .. ' Upgrade Crystal') then return end
    Library:Notify(`You need to have at least 1 {crystalType:lower()} upgrade crystal`)
end)

Giving:AddButton({
    Text = 'Add crystals to trade',
    Func = function()
        if not Options.CrystalType.Value then
            return Library:Notify('Select the crystal type first')
        end

        local item = Inventory:FindFirstChild(Options.CrystalType.Value .. ' Upgrade Crystal')

        if not item then
            return Library:Notify(`You need to have at least 1 {Options.CrystalType.Value:lower()} upgrade crystal`)
        end

        for value = 1, item:FindFirstChild('Count') and item.Count.Value or 1 do
            Event:FireServer('Trade', 'TradeAddItem', { item })
            if value == Options.AmountToAdd.Value then break end
        end
    end
})

Giving:AddSlider('AmountToAdd', { Text = 'Amount to add', Default = 128, Min = 0, Max = 128, Rounding = 0, Compact = true })

local Receiving = Crystals:AddRightGroupbox('Receiving')

Receiving:AddToggle('AcceptTrades', {
    Text = 'Accept trades',
    Default = false
})

inTrade.Changed:Connect(function(enteredTrade)
    if not enteredTrade then return end
    if not Toggles.SendTrades.Value then return end
    if not Options.CrystalType.Value then
        return Library:Notify('Select the crystal type first')
    end

    local item = Inventory:FindFirstChild(Options.CrystalType.Value .. ' Upgrade Crystal')

    if not item then
        Library:Notify(`You need to have at least 1 {Options.CrystalType.Value:lower()} upgrade crystal`)
        return Toggles.SendTrades:SetValue(false)
    end

    for _ = 1, (item:FindFirstChild('Count') and math.min(128, item.Count.Value, Options.CrystalAmount.Value - CrystalCounter.Given.ThisCycle) or 1) do
        Event:FireServer('Trade', 'TradeAddItem', { item })
    end

    Event:FireServer('Trade', 'TradeConfirm', {})
    Event:FireServer('Trade', 'TradeAccept', {})
end)

local lastTradeChange
Event.OnClientEvent:Connect(function(...)
    local args = {...}
    if not (args[1] == 'UI' and args[2][1] == 'Trade') then return end
    if args[2][2] == 'Request' then
        if not (Toggles.AcceptTrades.Value or Toggles.SendTrades.Value) then return end
        if Options.TargetAccount.Value.Name == args[2][3].Name then
            Event:FireServer('Trade', 'RequestAccept', {})
            inTrade.Value = true
        else
            Event:FireServer('Trade', 'RequestDecline', {})
        end
    elseif args[2][2] == 'TradeChanged' then
        lastTradeChange = args[2][3]
        if not (Toggles.AcceptTrades.Value or Toggles.SendTrades.Value) then return end
        local targetRole = lastTradeChange.Requester == LocalPlayer and 'Partner' or 'Requester'
        local ourRole = targetRole == 'Partner' and 'Requester' or 'Partner'
        if not (lastTradeChange[targetRole .. 'Confirmed'] and not lastTradeChange[ourRole .. 'Accepted']) then return end
        Event:FireServer('Trade', 'TradeConfirm', {})
        Event:FireServer('Trade', 'TradeAccept', {})
    elseif args[2][2] == 'RequestAccept' then
        inTrade.Value = true
    elseif args[2][2] == 'RequestDecline' then
        tradeLastSent = 0
    elseif args[2][2] == 'TradeCompleted' then
        local targetRole = lastTradeChange.Requester == LocalPlayer and 'Partner' or 'Requester'
        local ourRole = targetRole == 'Partner' and 'Requester' or 'Partner'
        for _, itemData in next, lastTradeChange[targetRole .. 'Items'] do
            if not itemData.item.Name:find('Upgrade Crystal') then continue end
            CrystalCounter.Received.Value += 1
        end
        CrystalCounter.Received.Update()
        for _, itemData in next, lastTradeChange[ourRole .. 'Items'] do
            if not itemData.item.Name:find('Upgrade Crystal') then continue end
            CrystalCounter.Given.Value += 1
            if not Toggles.SendTrades.Value then continue end
            CrystalCounter.Given.ThisCycle += 1
            if CrystalCounter.Given.ThisCycle ~= Options.CrystalAmount.Value then continue end
            Toggles.SendTrades:SetValue(false)
        end
        CrystalCounter.Given.Update()
        inTrade.Value = false
    elseif args[2][2] == 'TradeCancel' then
        inTrade.Value = false
    end
end)

local Settings = Window:AddTab('Settings', 'settings')

local Menu = Settings:AddLeftGroupbox('Menu', 'menu')

Menu:AddLabel('Menu keybind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true })

Library.ToggleKeybind = Options.MenuKeybind

local autoexecute = true
if isfile('Bluu/Swordburst 2/autoexec') and readfile('Bluu/Swordburst 2/autoexec') == 'false' then
    autoexecute = false
end

Menu:AddToggle('Autoexecute', { Text = 'Autoexecute', Default = autoexecute }):OnChanged(function(value)
    writefile('Bluu/Swordburst 2/autoexec', tostring(value))
end)

Menu:AddButton("Unload Script", function()
    for _, toggle in next, Toggles do
        if toggle.Value then
            toggle:SetValue(false)
        end
    end

    pcall(function()
        linearVelocity.Parent = nil
        waypoint:Destroy()
        Humanoid.WalkSpeed = 20
        Camera.CameraSubject = Character
        LocalPlayer.CameraMaxZoomDistance = defaultCameraMaxZoomDistance
        LocalPlayer.DevCameraOcclusionMode = 0
        Chat.Size = chatSize
        Library:Unload()
    end)

    getgenv().Bluu = false
end)

local ThemeManager = loadstring(game:HttpGet(UIRepo .. 'addons/ThemeManager.lua'))()
ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder('Bluu/Swordburst 2')
ThemeManager:ApplyToTab(Settings)

local SaveManager = loadstring(game:HttpGet(UIRepo .. 'addons/SaveManager.lua'))()
SaveManager:SetLibrary(Library)
SaveManager:SetFolder('Bluu/Swordburst 2')
SaveManager:IgnoreThemeSettings()
SaveManager:BuildConfigSection(Settings)
SaveManager:LoadAutoloadConfig()

local Credits = Settings:AddRightGroupbox('Credits')

Credits:AddLabel('de_Neuublue - Script')
Credits:AddLabel('Inori - UI library')
Credits:AddLabel('wally - UI addons')
