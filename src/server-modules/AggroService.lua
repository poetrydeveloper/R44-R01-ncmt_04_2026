-- src/server-modules/AggroService.lua
-- Управление гневом деревни
-- Чем больше игрок нападает на деревню, тем сильнее ответная атака

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local BaseStats = require(ReplicatedStorage.Constants.BaseStats)
local Enums = require(ReplicatedStorage.Shared.Enums)

-- Сервисы (заполняются при Init)
local ArmyService = nil

-- ============================================
-- Хранилище данных по игрокам
-- ============================================
-- AggroData[userId] = {
--     CurrentAggro = number,     -- 0-100
--     LastAttackTime = number,   -- для расчета падения агро
--     IsUnderAttack = boolean,   -- атакуют ли погост игрока сейчас
--     AttackCooldown = number,   -- когда можно снова атаковать
-- }

local AggroData = {}

-- Ссылка на погост игрока (пока заглушка)
local PlayerPogosts = {}  -- [userId] = Instance (модель погоста)

-- ============================================
-- Константы из конфига
-- ============================================
local PER_ATTACK = BaseStats.Aggro.PerAttack or 5
local PER_KILL = BaseStats.Aggro.PerKill or 1
local DECAY_PER_SECOND = BaseStats.Aggro.DecayPerSecond or 0.1
local MAX_AGGRO = BaseStats.Aggro.MaxAggro or 100
local ATTACK_THRESHOLD = BaseStats.Aggro.AttackThreshold or 70

-- ============================================
-- Внутренние функции
-- ============================================

-- Получить данные агрессии игрока
local function GetAggroData(player: Player): table?
    return AggroData[player.UserId]
end

-- Обновить UI игрока (отправить текущий уровень агрессии)
local function SendAggroUpdate(player: Player, aggroLevel: number)
    -- TODO: RemoteEvent для обновления шкалы агрессии на UI
    print(`[AggroService] 📊 Агрессия ${player.Name}: ${aggroLevel}/${MAX_AGGRO}`)
end

-- Создать вражеский отряд для атаки на погост
local function SpawnAttackParty(player: Player, aggroLevel: number)
    local pogost = PlayerPogosts[player.UserId]
    if not pogost then
        print(`[AggroService] ⚠️ Нет погоста для игрока ${player.Name}, атака отменена`)
        return
    end
    
    -- Определяем силу отряда в зависимости от уровня агрессии
    local unitCount = math.floor(aggroLevel / 20) + 1  -- 1-5 юнитов
    unitCount = math.min(unitCount, 5)
    
    -- Типы врагов (чем выше агро, тем сильнее)
    local enemyTypes = {"Villager", "Militia"}
    if aggroLevel >= 50 then
        table.insert(enemyTypes, "Archer")
    end
    if aggroLevel >= 80 then
        table.insert(enemyTypes, "Knight")
    end
    
    print(`[AggroService] ⚔️ Деревня атакует погост ${player.Name}! Уровень агро: ${aggroLevel}, юнитов: ${unitCount}`)
    
    -- Создаем врагов вокруг погоста
    local pogostPosition = pogost:GetPivot() or pogost.Position
    local radius = 30
    
    for i = 1, unitCount do
        local randomAngle = math.random() * 2 * math.pi
        local offsetX = math.cos(randomAngle) * radius
        local offsetZ = math.sin(randomAngle) * radius
        local spawnPos = pogostPosition + Vector3.new(offsetX, 0, offsetZ)
        
        local enemyType = enemyTypes[math.random(1, #enemyTypes)]
        
        -- TODO: Создать модель врага
        print(`[AggroService]    - Создан ${enemyType} на позиции ${spawnPos}`)
        
        -- TODO: Добавить врага в систему боя
    end
    
    -- Устанавливаем кулдаун на следующую атаку
    local data = AggroData[player.UserId]
    if data then
        data.AttackCooldown = os.time() + 60  -- 60 секунд между атаками
    end
end

-- Проверить, нужно ли начать атаку на погост
local function CheckAndTriggerAttack(player: Player, aggroLevel: number)
    local data = AggroData[player.UserId]
    if not data then return end
    
    -- Проверяем, не в кулдауне ли атака
    if data.AttackCooldown and os.time() < data.AttackCooldown then
        return
    end
    
    -- Проверяем, не идет ли уже атака
    if data.IsUnderAttack then
        return
    end
    
    -- Проверяем порог агрессии
    if aggroLevel >= ATTACK_THRESHOLD then
        data.IsUnderAttack = true
        SpawnAttackParty(player, aggroLevel)
        
        -- Сбрасываем агро после атаки (деревня "выпустила пар")
        local newAggro = math.max(0, aggroLevel - 30)
        data.CurrentAggro = newAggro
        SendAggroUpdate(player, newAggro)
        
        -- Через некоторое время снимаем флаг атаки
        task.delay(120, function()
            if AggroData[player.UserId] then
                AggroData[player.UserId].IsUnderAttack = false
                print(`[AggroService] ✅ Атака на погост ${player.Name} завершена`)
            end
        end)
    end
end

-- ============================================
-- ОСНОВНЫЕ ФУНКЦИИ (API)
-- ============================================

local AggroService = {}

-- Инициализировать данные агрессии для игрока
function AggroService.InitPlayer(player: Player)
    local userId = player.UserId
    if AggroData[userId] then
        return
    end
    
    AggroData[userId] = {
        CurrentAggro = 0,
        LastAttackTime = os.time(),
        IsUnderAttack = false,
        AttackCooldown = 0,
    }
    
    print(`[AggroService] 📊 Инициализирована агрессия для ${player.Name}`)
end

-- Добавить агрессию (когда игрок атакует деревню)
-- @param player: Player - игрок
-- @param amount: number - количество агрессии (опционально, по умолчанию PER_ATTACK)
-- @param reason: string - причина (для логирования)
function AggroService.AddAggro(player: Player, amount: number?, reason: string)
    local data = AggroData[player.UserId]
    if not data then
        AggroService.InitPlayer(player)
        data = AggroData[player.UserId]
    end
    
    local addAmount = amount or PER_ATTACK
    local newAggro = math.min(data.CurrentAggro + addAmount, MAX_AGGRO)
    data.CurrentAggro = newAggro
    data.LastAttackTime = os.time()
    
    print(`[AggroService] 😠 ${player.Name} +${addAmount} агрессии (${reason}). Теперь: ${newAggro}/${MAX_AGGRO}`)
    
    SendAggroUpdate(player, newAggro)
    
    -- Проверяем, не пора ли атаковать
    CheckAndTriggerAttack(player, newAggro)
end

-- Добавить агрессию за убийство мирного жителя
function AggroService.AddKillAggro(player: Player, unitType: string)
    AggroService.AddAggro(player, PER_KILL, `убийство ${unitType}`)
end

-- Уменьшить агрессию (со временем или за выполнение квеста)
function AggroService.ReduceAggro(player: Player, amount: number, reason: string)
    local data = AggroData[player.UserId]
    if not data then return end
    
    local newAggro = math.max(0, data.CurrentAggro - amount)
    data.CurrentAggro = newAggro
    
    print(`[AggroService] 🕊️ ${player.Name} -${amount} агрессии (${reason}). Теперь: ${newAggro}/${MAX_AGGRO}`)
    
    SendAggroUpdate(player, newAggro)
end

-- Получить текущий уровень агрессии игрока
function AggroService.GetAggroLevel(player: Player): number
    local data = AggroData[player.UserId]
    if not data then return 0 end
    return data.CurrentAggro
end

-- Зарегистрировать погост игрока (куда будут приходить атаки)
function AggroService.RegisterPogost(player: Player, pogostModel: Instance)
    PlayerPogosts[player.UserId] = pogostModel
    print(`[AggroService] 🏚️ Зарегистрирован погост для ${player.Name}`)
end

-- Проверить, атакуют ли погост игрока
function AggroService.IsUnderAttack(player: Player): boolean
    local data = AggroData[player.UserId]
    return data and data.IsUnderAttack or false
end

-- ============================================
-- ЦИКЛ ПАССИВНОГО СНИЖЕНИЯ АГРЕССИИ
-- ============================================

local decayConnection = nil

function AggroService.StartDecay()
    if decayConnection then
        return
    end
    
    print(`[AggroService] ⏰ Запущено пассивное снижение агрессии (${DECAY_PER_SECOND}/сек)`)
    
    decayConnection = RunService.Heartbeat:Connect(function(deltaTime)
        for userId, data in pairs(AggroData) do
            if data.CurrentAggro > 0 and not data.IsUnderAttack then
                -- Снижаем агрессию со временем
                local decayAmount = DECAY_PER_SECOND * deltaTime
                local newAggro = math.max(0, data.CurrentAggro - decayAmount)
                
                if newAggro ~= data.CurrentAggro then
                    data.CurrentAggro = newAggro
                    
                    -- Отправляем обновление только если изменилось значительно
                    if math.floor(newAggro) ~= math.floor(data.CurrentAggro + decayAmount) then
                        local player = Players:GetPlayerByUserId(userId)
                        if player then
                            SendAggroUpdate(player, newAggro)
                        end
                    end
                end
            end
        end
    end)
end

function AggroService.StopDecay()
    if decayConnection then
        decayConnection:Disconnect()
        decayConnection = nil
        print("[AggroService] ⏹️ Пассивное снижение агрессии остановлено")
    end
end

-- ============================================
-- ИНИЦИАЛИЗАЦИЯ
-- ============================================

function AggroService.Init(armyService)
    ArmyService = armyService
    
    if not ArmyService then
        error("[AggroService] ❌ Не удалось инициализировать: ArmyService отсутствует")
    end
    
    -- Запускаем пассивное снижение агрессии
    AggroService.StartDecay()
    
    print("[AggroService] ========== ИНИЦИАЛИЗАЦИЯ ==========")
    print("   - Зависимости: ArmyService ✅")
    print("   - За атаку на деревню: +", PER_ATTACK, "агро")
    print("   - За убийство жителя: +", PER_KILL, "агро")
    print("   - Пассивное снижение:", DECAY_PER_SECOND, "агро/сек")
    print("   - Порог атаки деревни:", ATTACK_THRESHOLD, "агро")
    print("[AggroService] ✅ Готов к работе")
end

return AggroService