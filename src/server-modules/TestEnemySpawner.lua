-- src/server-modules/TestEnemySpawner.lua
-- Спавн тестовых врагов для проверки механик
-- ВЕРСИЯ 1.0

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local BaseStats = require(ReplicatedStorage.Constants.BaseStats)

-- Сервисы (заполняются при Init)
local ArmyService = nil
local CorpseManager = nil

-- ============================================
-- Хранилище активных врагов
-- ============================================
local ActiveEnemies = {}  -- [enemyId] = {Model, Humanoid, UnitType, Position}

-- ============================================
-- Создание модели врага
-- ============================================

local function CreateEnemyModel(enemyType: string, position: Vector3): Model
    local model = Instance.new("Model")
    model.Name = enemyType
    
    -- Humanoid
    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = 50
    humanoid.Health = 50
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = model
    
    -- PrimaryPart (простая парт для физики)
    local primaryPart = Instance.new("Part")
    primaryPart.Name = "HumanoidRootPart"
    primaryPart.Size = Vector3.new(3, 3, 3)
    primaryPart.Shape = Enum.PartType.Block
    primaryPart.BrickColor = BrickColor.new("Bright red")
    primaryPart.Material = Enum.Material.SmoothPlastic
    primaryPart.Anchored = false
    primaryPart.CanCollide = true
    primaryPart.Position = position
    primaryPart.Parent = model
    
    model.PrimaryPart = primaryPart
    
    -- Голова (для красоты)
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(2, 2, 2)
    head.BrickColor = BrickColor.new("Really red")
    head.Material = Enum.Material.SmoothPlastic
    head.Position = position + Vector3.new(0, 2, 0)
    head.Parent = model
    
    -- Туловище
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2.5, 2, 2)
    torso.BrickColor = BrickColor.new("Dark red")
    torso.Material = Enum.Material.SmoothPlastic
    torso.Position = position + Vector3.new(0, 0, 0)
    torso.Parent = model
    
    model.Parent = Workspace
    
    print(`[TestEnemySpawner] 🧟 Создан враг ${enemyType} на позиции ${position}`)
    
    return model
end

-- ============================================
-- Обработка смерти врага
-- ============================================

local function OnEnemyDeath(enemyId: string, enemyModel: Model, enemyType: string, position: Vector3)
    print(`[TestEnemySpawner] 💀 Враг ${enemyId} (${enemyType}) убит!`)
    
    -- Удаляем из активных
    ActiveEnemies[enemyId] = nil
    
    -- Создаем труп через CorpseManager
    if CorpseManager then
        local killerId = 0  -- TODO: определить кто убил
        CorpseManager.CreateCorpse(enemyType, position, killerId)
    end
    
    -- Начисляем ману и опыт игроку (TODO: определить кто убил)
    -- Пока просто спавним нового врага через 5 секунд
    task.delay(5, function()
        TestEnemySpawner.SpawnEnemy("TestEnemy", Vector3.new(
            math.random(-50, 50),
            5,
            math.random(-50, 50)
        ))
    end)
end

-- ============================================
-- AI врага (простой: бежит к игроку)
-- ============================================

local function EnemyAI(enemyId: string, deltaTime: number)
    local enemy = ActiveEnemies[enemyId]
    if not enemy or not enemy.Model or not enemy.Model.PrimaryPart then
        return
    end
    
    -- Ищем ближайшего игрока
    local players = game:GetService("Players"):GetPlayers()
    local nearestPlayer = nil
    local nearestDistance = 50  -- Радиус поиска
    
    for _, player in ipairs(players) do
        local character = player.Character
        if character and character.PrimaryPart then
            local distance = (enemy.Model.PrimaryPart.Position - character.PrimaryPart.Position).Magnitude
            if distance < nearestDistance then
                nearestDistance = distance
                nearestPlayer = player
            end
        end
    end
    
    if nearestPlayer and nearestPlayer.Character and nearestPlayer.Character.PrimaryPart then
        -- Движение к игроку
        local targetPos = nearestPlayer.Character.PrimaryPart.Position
        local direction = (targetPos - enemy.Model.PrimaryPart.Position).Unit
        local speed = 20  -- Скорость передвижения
        
        enemy.Model.PrimaryPart.Position = enemy.Model.PrimaryPart.Position + direction * speed * deltaTime
        
        -- Атака, если близко
        if nearestDistance < 5 then
            local humanoid = nearestPlayer.Character:FindFirstChildWhichIsA("Humanoid")
            if humanoid then
                humanoid.Health -= 10
                print(`[TestEnemySpawner] ⚔️ Враг ${enemyId} атаковал ${nearestPlayer.Name}!`)
            end
        end
    end
end

-- ============================================
-- ПУБЛИЧНЫЕ ФУНКЦИИ
-- ============================================

local TestEnemySpawner = {}

function TestEnemySpawner.SpawnEnemy(enemyType: string, position: Vector3): string?
    local enemyId = `enemy_{os.time()}_{math.random(1000, 9999)}`
    
    local model = CreateEnemyModel(enemyType, position)
    local humanoid = model:FindFirstChildWhichIsA("Humanoid")
    
    if not humanoid then
        model:Destroy()
        return nil
    end
    
    -- Подписываемся на смерть
    humanoid.Died:Connect(function()
        OnEnemyDeath(enemyId, model, enemyType, position)
    end)
    
    ActiveEnemies[enemyId] = {
        Model = model,
        Humanoid = humanoid,
        UnitType = enemyType,
        Position = position,
    }
    
    print(`[TestEnemySpawner] 🎮 Спавн врага ${enemyId} (${enemyType})`)
    
    return enemyId
end

function TestEnemySpawner.SpawnTestEnemies()
    print("[TestEnemySpawner] 🎮 Спавн тестовых врагов...")
    
    -- Спавним 3 врагов вокруг центра карты
    TestEnemySpawner.SpawnEnemy("TestEnemy", Vector3.new(20, 5, 20))
    TestEnemySpawner.SpawnEnemy("TestEnemy", Vector3.new(-20, 5, -20))
    TestEnemySpawner.SpawnEnemy("TestEnemy", Vector3.new(20, 5, -20))
    
    print("[TestEnemySpawner] ✅ 3 тестовых врага созданы")
end

function TestEnemySpawner.ClearAllEnemies()
    for enemyId, enemy in pairs(ActiveEnemies) do
        if enemy.Model then
            enemy.Model:Destroy()
        end
    end
    ActiveEnemies = {}
    print("[TestEnemySpawner] 🧹 Все враги удалены")
end

-- ============================================
-- Цикл AI
-- ============================================

local aiConnection = nil

function TestEnemySpawner.StartAI()
    if aiConnection then
        return
    end
    
    print("[TestEnemySpawner] 🤖 Запуск AI для врагов")
    
    aiConnection = RunService.Heartbeat:Connect(function(deltaTime)
        for enemyId, _ in pairs(ActiveEnemies) do
            EnemyAI(enemyId, deltaTime)
        end
    end)
end

function TestEnemySpawner.StopAI()
    if aiConnection then
        aiConnection:Disconnect()
        aiConnection = nil
        print("[TestEnemySpawner] ⏹️ AI врагов остановлен")
    end
end

-- ============================================
-- ИНИЦИАЛИЗАЦИЯ
-- ============================================

function TestEnemySpawner.Init(armyService, corpseManager)
    ArmyService = armyService
    CorpseManager = corpseManager
    
    if not ArmyService then
        error("[TestEnemySpawner] ❌ Не удалось инициализировать: ArmyService отсутствует")
    end
    
    TestEnemySpawner.StartAI()
    
    -- Автоматический спавн врагов
    task.wait(3)  -- Ждем загрузки карты
    TestEnemySpawner.SpawnTestEnemies()
    
    print("[TestEnemySpawner] ========== ИНИЦИАЛИЗАЦИЯ ==========")
    print("   - Зависимости: ArmyService ✅")
    print("   - AI статус: активен")
    print("   - Тестовые враги: созданы")
    print("[TestEnemySpawner] ✅ Готов к работе")
end

return TestEnemySpawner