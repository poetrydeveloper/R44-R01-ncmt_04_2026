-- src/server-modules/UnitFactory.lua
-- Создание и управление юнитами в мире (модели, AI, бой)
-- Получает команды от ArmyService (когда юнит оживлен)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local BaseStats = require(ReplicatedStorage.Constants.BaseStats)
local Enums = require(ReplicatedStorage.Shared.Enums)

-- ============================================
-- Хранилище активных юнитов в мире
-- ============================================
-- ActiveUnits[unitId] = {
--     Model = Instance,
--     Humanoid = Instance,
--     UnitData = Types.ActiveUnit,
--     CurrentTarget = Instance?,  -- Кого атакует
--     Owner = Player,
-- }

local ActiveUnits = {}  -- [unitId] = unitInstance

-- Ссылка на ArmyService (заполняется при Init)
local ArmyService = nil

-- ============================================
-- Создание модели юнита
-- ============================================

local function CreateUnitModel(unitTypeId: string, position: Vector3): Model
    local unitData = BaseStats.Units[unitTypeId]
    if not unitData then
        error(`[UnitFactory] Неизвестный тип юнита: ${unitTypeId}`)
    end
    
    -- Создаем модель
    local model = Instance.new("Model")
    model.Name = unitData.Name
    
    -- Создаем Humanoid (для AI и здоровья)
    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = unitData.BaseHealth
    humanoid.Health = unitData.BaseHealth
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = model
    
    -- Создаем PrimaryPart (простая парт для физики и позиции)
    local primaryPart = Instance.new("Part")
    primaryPart.Name = "PrimaryPart"
    primaryPart.Size = Vector3.new(2, 2, 2)
    primaryPart.Shape = Enum.PartType.Block
    primaryPart.BrickColor = BrickColor.new("Dark gray")
    primaryPart.Material = Enum.Material.Slate
    primaryPart.Anchored = false
    primaryPart.CanCollide = true
    primaryPart.Position = position
    primaryPart.Parent = model
    
    model.PrimaryPart = primaryPart
    
    -- TODO: Загрузить реальную модель из AssetId (unitData.ModelId)
    -- Если есть модель, заменить этой заглушкой
    
    model.Parent = workspace
    
    print(`[UnitFactory] 🏗️ Создана модель юнита ${unitData.Name} на позиции ${position}`)
    
    return model
end

-- ============================================
-- Поиск ближайшего врага
-- ============================================

local function FindNearestEnemy(unitModel: Model, position: Vector3, attackRange: number, owner: Player)
    -- Ищем врагов поблизости
    local nearestDistance = attackRange
    local nearestEnemy = nil
    
    -- TODO: Более умный поиск (по тегам, командам, агрессии)
    -- Пока ищем любых NPC не принадлежащих игроку
    
    for _, npc in ipairs(workspace:GetDescendants()) do
        if npc:IsA("Model") and npc ~= unitModel then
            -- Проверка, что это враг (упрощенно: не является юнитом игрока)
            local isOwnUnit = false
            for _, activeUnit in pairs(ActiveUnits) do
                if activeUnit.Model == npc and activeUnit.Owner == owner then
                    isOwnUnit = true
                    break
                end
            end
            
            if not isOwnUnit and npc.PrimaryPart then
                local distance = (position - npc.PrimaryPart.Position).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestEnemy = npc
                end
            end
        end
    end
    
    return nearestEnemy
end

-- ============================================
-- Атака (обработка урона)
-- ============================================

local function DealDamage(attacker: Model, target: Model, damage: number, attackerUnitId: string, owner: Player)
    local targetHumanoid = target:FindFirstChildWhichIsA("Humanoid")
    if not targetHumanoid then return end
    
    targetHumanoid.Health -= damage
    
    print(`[UnitFactory] ⚔️ Юнит ${attacker.Name} нанес ${damage} урона ${target.Name}. Осталось здоровья: ${targetHumanoid.Health}`)
    
    -- Если цель умерла
    if targetHumanoid.Health <= 0 then
        -- Проверяем, является ли цель юнитом игрока
        local killedByPlayer = owner
        local enemyType = "Normal"  -- TODO: Определять тип врага (Elite, Boss)
        
        -- Уведомляем ArmyService для начисления маны и опыта
        if ArmyService then
            ArmyService.RegisterKill(killedByPlayer, "Unit", enemyType)
        end
        
        -- TODO: Создать труп через CorpseManager
        -- CorpseManager.CreateCorpse(unitTypeId, target.PrimaryPart.Position, owner.UserId)
        
        -- Удаляем убитого
        target:Destroy()
    end
end

-- ============================================
-- Цикл AI для одного юнита
-- ============================================

local function UnitAI(unitId: string)
    local unit = ActiveUnits[unitId]
    if not unit then return end
    
    local model = unit.Model
    local unitData = unit.UnitData
    local owner = unit.Owner
    
    if not model or not model.PrimaryPart then return end
    
    local currentPosition = model.PrimaryPart.Position
    local stats = BaseStats.Units[unitData.UnitTypeId]
    
    -- Поиск врага
    local target = FindNearestEnemy(model, currentPosition, stats.AttackRange, owner)
    
    if target and target.PrimaryPart then
        -- Атакуем
        unit.CurrentTarget = target
        
        -- Движение к цели если далеко
        local distanceToTarget = (currentPosition - target.PrimaryPart.Position).Magnitude
        if distanceToTarget > stats.AttackRange then
            -- Двигаемся к цели
            local direction = (target.PrimaryPart.Position - currentPosition).Unit
            model.PrimaryPart.Position += direction * 16  -- Скорость 16 студий/сек
        else
            -- В радиусе атаки
            local damage = stats.BaseDamage
            
            -- Применяем баффы (лед, яд и т.д.)
            for buffName, buffData in pairs(unitData.Buffs or {}) do
                if buffName == Enums.BuffType.IceTouch then
                    damage = damage + (buffData.Value or 10)
                    -- TODO: Замедление цели
                elseif buffName == Enums.BuffType.PoisonAura then
                    -- TODO: Облако яда
                end
            end
            
            DealDamage(model, target, damage, unitId, owner)
        end
    else
        -- Нет цели — стоим на месте
        unit.CurrentTarget = nil
    end
end

-- ============================================
-- ОСНОВНЫЕ ФУНКЦИИ (API)
-- ============================================

local UnitFactory = {}

-- Создать активного юнита в мире
-- @param unitData: Types.ActiveUnit - данные юнита из слота
-- @param owner: Player - владелец
-- @param spawnPosition: Vector3 - место появления
function UnitFactory.SpawnUnit(unitData: Types.ActiveUnit, owner: Player, spawnPosition: Vector3): boolean
    local stats = BaseStats.Units[unitData.UnitTypeId]
    if not stats then
        print(`[UnitFactory] ❌ Неизвестный тип юнита: ${unitData.UnitTypeId}`)
        return false
    end
    
    -- Создаем модель
    local model = CreateUnitModel(unitData.UnitTypeId, spawnPosition)
    
    -- Сохраняем в активные
    ActiveUnits[unitData.InstanceId] = {
        Model = model,
        UnitData = unitData,
        Owner = owner,
        CurrentTarget = nil,
    }
    
    print(`[UnitFactory] ✨ Спавн юнита ${stats.Name} (${unitData.InstanceId}) для игрока ${owner.Name}`)
    
    return true
end

-- Удалить юнита из мира (при смерти или рассеивании)
function UnitFactory.DespawnUnit(unitId: string)
    local unit = ActiveUnits[unitId]
    if not unit then return end
    
    if unit.Model then
        unit.Model:Destroy()
    end
    
    ActiveUnits[unitId] = nil
    
    print(`[UnitFactory] 💀 Юнит ${unitId} удален из мира`)
end

-- Рассеять ВСЕХ юнитов игрока (при выходе из куба)
function UnitFactory.DespawnAllUnitsForPlayer(player: Player)
    local toRemove = {}
    
    for unitId, unit in pairs(ActiveUnits) do
        if unit.Owner == player then
            table.insert(toRemove, unitId)
        end
    end
    
    for _, unitId in ipairs(toRemove) do
        UnitFactory.DespawnUnit(unitId)
    end
    
    print(`[UnitFactory] 🧹 Рассеяно ${#toRemove} юнитов игрока ${player.Name}`)
end

-- Получить всех активных юнитов игрока
function UnitFactory.GetPlayerUnits(player: Player): { [string]: any }
    local result = {}
    for unitId, unit in pairs(ActiveUnits) do
        if unit.Owner == player then
            result[unitId] = unit
        end
    end
    return result
end

-- ============================================
-- ЦИКЛ ИГРОВОГО ПРОЦЕССА (AI)
-- ============================================

local aiConnection = nil

function UnitFactory.StartAI()
    if aiConnection then
        return
    end
    
    print("[UnitFactory] 🤖 Запуск системы AI для юнитов")
    
    aiConnection = RunService.Heartbeat:Connect(function(deltaTime)
        -- Обновляем AI для каждого юнита
        for unitId, _ in pairs(ActiveUnits) do
            UnitAI(unitId)
        end
    end)
end

function UnitFactory.StopAI()
    if aiConnection then
        aiConnection:Disconnect()
        aiConnection = nil
        print("[UnitFactory] ⏹️ Система AI остановлена")
    end
end

-- ============================================
-- ИНИЦИАЛИЗАЦИЯ
-- ============================================

function UnitFactory.Init(armyService)
    ArmyService = armyService
    
    if not ArmyService then
        error("[UnitFactory] ❌ Не удалось инициализировать: ArmyService отсутствует")
    end
    
    UnitFactory.StartAI()
    
    print("[UnitFactory] ========== ИНИЦИАЛИЗАЦИЯ ==========")
    print("   - Зависимости: ArmyService ✅")
    print("   - AI статус: активен")
    print("   - Модели юнитов: заглушки (ждут реальных моделей)")
    print("[UnitFactory] ✅ Готов к работе")
end

return UnitFactory