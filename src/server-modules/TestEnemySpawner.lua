-- src/server-modules/TestEnemySpawner.lua
-- Спавн тестовых врагов у деревни с патрулированием
-- ВЕРСИЯ 2.0

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local BaseStats = require(ReplicatedStorage.Constants.BaseStats)

-- ============================================
-- КОНФИГУРАЦИЯ ДЕРЕВНИ
-- ============================================

-- Позиция деревни (по координатам твоей модели)
local VILLAGE_POSITION = Vector3.new(207, 22.901, 250)

-- Радиус спавна вокруг деревни
local SPAWN_RADIUS = 50

-- Радиус патрулирования
local PATROL_RADIUS_MIN = 20
local PATROL_RADIUS_MAX = 60

-- Радиус агро (когда враг замечает игрока)
local AGRO_RADIUS = 50

-- Радиус потери игрока (возврат к патрулю)
local LOSE_RADIUS = 70

-- ============================================
-- Состояния врага
-- ============================================
local EnemyState = {
    PATROL = "Patrol",
    CHASE = "Chase",
}

-- ============================================
-- Хранилище активных врагов
-- ============================================
local ActiveEnemies = {}  -- [enemyId] = {Model, Humanoid, UnitType, Position, State, PatrolTarget, Target}

-- Сервисы
local ArmyService = nil
local CorpseManager = nil

-- ============================================
-- Вспомогательные функции
-- ============================================

-- Выбор случайной точки для патруля
local function GetRandomPatrolPoint()
    local angle = math.random() * 2 * math.pi
    local radius = math.random(PATROL_RADIUS_MIN, PATROL_RADIUS_MAX)
    local x = VILLAGE_POSITION.X + math.cos(angle) * radius
    local z = VILLAGE_POSITION.Z + math.sin(angle) * radius
    return Vector3.new(x, VILLAGE_POSITION.Y, z)
end

-- Выбор случайной точки для спавна
local function GetRandomSpawnPoint()
    local angle = math.random() * 2 * math.pi
    local radius = math.random(30, SPAWN_RADIUS)
    local x = VILLAGE_POSITION.X + math.cos(angle) * radius
    local z = VILLAGE_POSITION.Z + math.sin(angle) * radius
    return Vector3.new(x, VILLAGE_POSITION.Y, z)
end

-- ============================================
-- Создание модели врага
-- ============================================

local function CreateEnemyModel(enemyType: string, position: Vector3): Model
    local model = Instance.new("Model")
    model.Name = enemyType
    
    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = 50
    humanoid.Health = 50
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = model
    
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
    
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(2, 2, 2)
    head.BrickColor = BrickColor.new("Really red")
    head.Material = Enum.Material.SmoothPlastic
    head.Position = position + Vector3.new(0, 2, 0)
    head.Parent = model
    
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
    
    ActiveEnemies[enemyId] = nil
    
    if CorpseManager then
        local killerId = 0
        CorpseManager.CreateCorpse(enemyType, position, killerId)
    end
    
    -- Спавним нового врага через 10 секунд
    task.delay(10, function()
        if TestEnemySpawner then
            local spawnPos = GetRandomSpawnPoint()
            TestEnemySpawner.SpawnEnemy("TestEnemy", spawnPos)
        end
    end)
end

-- ============================================
-- AI врага (патруль + преследование)
-- ============================================

local function EnemyAI(enemyId: string, deltaTime: number)
    local enemy = ActiveEnemies[enemyId]
    if not enemy or not enemy.Model or not enemy.Model.PrimaryPart then
        return
    end
    
    -- Инициализация состояния
    if not enemy.State then
        enemy.State = EnemyState.PATROL
        enemy.PatrolTarget = GetRandomPatrolPoint()
    end
    
    local currentPos = enemy.Model.PrimaryPart.Position
    
    -- Поиск ближайшего игрока
    local nearestPlayer = nil
    local nearestDistance = AGRO_RADIUS
    
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character and character.PrimaryPart then
            local distance = (currentPos - character.PrimaryPart.Position).Magnitude
            if distance < nearestDistance then
                nearestDistance = distance
                nearestPlayer = player
            end
        end
    end
    
    -- Переключение состояний
    if nearestPlayer and nearestDistance < AGRO_RADIUS then
        if enemy.State ~= EnemyState.CHASE then
            enemy.State = EnemyState.CHASE
            print(`[TestEnemySpawner] 🏃 Враг ${enemyId} заметил игрока ${nearestPlayer.Name}`)
        end
        enemy.Target = nearestPlayer
    elseif enemy.State == EnemyState.CHASE and (not nearestPlayer or nearestDistance > LOSE_RADIUS) then
        enemy.State = EnemyState.PATROL
        enemy.Target = nil
        enemy.PatrolTarget = GetRandomPatrolPoint()
        print(`[TestEnemySpawner] 🚶 Враг ${enemyId} вернулся к патрулю`)
    end
    
    -- Действия по состоянию
    if enemy.State == EnemyState.CHASE and enemy.Target and enemy.Target.Character then
        -- Преследование игрока
        local targetPos = enemy.Target.Character.PrimaryPart.Position
        local direction = (targetPos - currentPos).Unit
        local speed = 20
        
        enemy.Model.PrimaryPart.Position = currentPos + direction * speed * deltaTime
        
        -- Атака, если близко
        if (currentPos - targetPos).Magnitude < 5 then
            local humanoid = enemy.Target.Character:FindFirstChildWhichIsA("Humanoid")
            if humanoid then
                humanoid.Health -= 10
                print(`[TestEnemySpawner] ⚔️ Враг ${enemyId} атаковал ${enemy.Target.Name}!`)
            end
        end
    elseif enemy.State == EnemyState.PATROL then
        -- Патрулирование
        local direction = (enemy.PatrolTarget - currentPos).Unit
        local speed = 12
        
        enemy.Model.PrimaryPart.Position = currentPos + direction * speed * deltaTime
        
        -- Если достиг цели, выбираем новую
        if (currentPos - enemy.PatrolTarget).Magnitude < 5 then
            enemy.PatrolTarget = GetRandomPatrolPoint()
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
    
    humanoid.Died:Connect(function()
        OnEnemyDeath(enemyId, model, enemyType, position)
    end)
    
    ActiveEnemies[enemyId] = {
        Model = model,
        Humanoid = humanoid,
        UnitType = enemyType,
        Position = position,
        State = EnemyState.PATROL,
        PatrolTarget = GetRandomPatrolPoint(),
        Target = nil,
    }
    
    print(`[TestEnemySpawner] 🎮 Спавн врага ${enemyId} (${enemyType}) у деревни`)
    
    return enemyId
end

function TestEnemySpawner.SpawnTestEnemies()
    print("[TestEnemySpawner] 🎮 Спавн тестовых врагов у деревни...")
    
    local enemiesCount = 5
    for i = 1, enemiesCount do
        local spawnPos = GetRandomSpawnPoint()
        TestEnemySpawner.SpawnEnemy("TestEnemy", spawnPos)
    end
    
    print(`[TestEnemySpawner] ✅ ${enemiesCount} тестовых врагов создано у деревни`)
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
    
    task.wait(3)
    TestEnemySpawner.SpawnTestEnemies()
    
    print("[TestEnemySpawner] ========== ИНИЦИАЛИЗАЦИЯ ==========")
    print("   - Зависимости: ArmyService ✅")
    print("   - Позиция деревни:", VILLAGE_POSITION)
    print("   - AI статус: активен")
    print("   - Тестовые враги: созданы")
    print("[TestEnemySpawner] ✅ Готов к работе")
end

return TestEnemySpawner