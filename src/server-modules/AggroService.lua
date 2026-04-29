-- src/server-modules/AggroService.lua
-- Управление гневом деревни
-- ВЕРСИЯ 2.0 — С REMOTEEVENT'АМИ И ПОЛНОЙ СВЯЗЬЮ С КЛИЕНТОМ

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local BaseStats = require(ReplicatedStorage.Constants.BaseStats)
local Enums = require(ReplicatedStorage.Shared.Enums)

-- ============================================
-- RemoteEvents для связи с клиентом
-- ============================================

local RemoteEventsFolder = ReplicatedStorage:FindFirstChild("ArmyRemoteEvents")
if not RemoteEventsFolder then
    RemoteEventsFolder = Instance.new("Folder")
    RemoteEventsFolder.Name = "ArmyRemoteEvents"
    RemoteEventsFolder.Parent = ReplicatedStorage
end

local UpdateAggroEvent = Instance.new("RemoteEvent")
UpdateAggroEvent.Name = "UpdateAggro"
UpdateAggroEvent.Parent = RemoteEventsFolder

-- ============================================
-- Константы из конфига
-- ============================================
local PER_ATTACK = BaseStats.Aggro.PerAttack or 5
local PER_KILL = BaseStats.Aggro.PerKill or 1
local DECAY_PER_SECOND = BaseStats.Aggro.DecayPerSecond or 0.1
local MAX_AGGRO = BaseStats.Aggro.MaxAggro or 100
local ATTACK_THRESHOLD = BaseStats.Aggro.AttackThreshold or 70

-- ============================================
-- Хранилище данных по игрокам
-- ============================================
-- AggroData[userId] = {
--     CurrentAggro = number,     -- 0-100
--     LastAttackTime = number,
--     IsUnderAttack = boolean,
--     AttackCooldown = number,
-- }

local AggroData = {}

-- Ссылка на погост игрока
local PlayerPogosts = {}  -- [userId] = Instance

-- Сервисы (заполняются при Init)
local ArmyService = nil

-- ============================================
-- Отправка обновлений клиенту
-- ============================================

local function SendAggroUpdate(player: Player, aggroLevel: number)
    UpdateAggroEvent:FireClient(player, aggroLevel, MAX_AGGRO)
    print(`[AggroService] 📊 Агрессия ${player.Name}: ${aggroLevel}/${MAX_AGGRO}`)
end

-- ============================================
-- Создание вражеского отряда
-- ============================================

local function SpawnAttackParty(player: Player, aggroLevel: number)
    local pogost = PlayerPogosts[player.UserId]
    if not pogost then
        print(`[AggroService] ⚠️ Нет погоста для игрока ${player.Name}, атака отменена`)
        return
    end
    
    local unitCount = math.min(math.floor(aggroLevel / 20) + 1, 5)
    
    local enemyTypes = {"Villager", "Militia"}
    if aggroLevel >= 50 then
        table.insert(enemyTypes, "Archer")
    end
    if aggroLevel >= 80 then
        table.insert(enemyTypes, "Knight")
    end
    
    print(`[AggroService] ⚔️ Деревня атакует погост ${player.Name}! Уровень агро: ${aggroLevel}, юнитов: ${unitCount}`)
    
    local pogostPosition = pogost:GetPivot()
    if not pogostPosition then
        pogostPosition = pogost.Position
    end
    local radius = 30
    
    for i = 1, unitCount do
        local randomAngle = math.random() * 2 * math.pi
        local offsetX = math.cos(randomAngle) * radius
        local offsetZ = math.sin(randomAngle) * radius
        local spawnPos = pogostPosition + Vector3.new(offsetX, 0, offsetZ)
        
        local enemyType = enemyTypes[math.random(1, #enemyTypes)]
        
        -- TODO: Создать модель врага через UnitFactory
        print(`[AggroService]    - Создан ${enemyType} на позиции ${spawnPos}`)
    end
    
    local data = AggroData[player.UserId]
    if data then
        data.AttackCooldown = os.time() + 60
    end
end

-- ============================================
-- Проверка и запуск атаки
-- ============================================

local function CheckAndTriggerAttack(player: Player, aggroLevel: number)
    local data = AggroData[player.UserId]
    if not data then return end
    
    if data.AttackCooldown and os.time() < data.AttackCooldown then
        return
    end
    
    if data.IsUnderAttack then
        return
    end
    
    if aggroLevel >= ATTACK_THRESHOLD then
        data.IsUnderAttack = true
        SpawnAttackParty(player, aggroLevel)
        
        local newAggro = math.max(0, aggroLevel - 30)
        data.CurrentAggro = newAggro
        SendAggroUpdate(player, newAggro)
        
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
    
    SendAggroUpdate(player, 0)
    print(`[AggroService] 📊 Инициализирована агрессия для ${player.Name}`)
end

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
    CheckAndTriggerAttack(player, newAggro)
end

function AggroService.AddKillAggro(player: Player, unitType: string)
    AggroService.AddAggro(player, PER_KILL, `убийство ${unitType}`)
end

function AggroService.ReduceAggro(player: Player, amount: number, reason: string)
    local data = AggroData[player.UserId]
    if not data then return end
    
    local newAggro = math.max(0, data.CurrentAggro - amount)
    data.CurrentAggro = newAggro
    
    print(`[AggroService] 🕊️ ${player.Name} -${amount} агрессии (${reason}). Теперь: ${newAggro}/${MAX_AGGRO}`)
    
    SendAggroUpdate(player, newAggro)
end

function AggroService.SetAggro(player: Player, value: number, reason: string)
    local data = AggroData[player.UserId]
    if not data then
        AggroService.InitPlayer(player)
        data = AggroData[player.UserId]
    end
    
    local newAggro = math.clamp(value, 0, MAX_AGGRO)
    data.CurrentAggro = newAggro
    data.LastAttackTime = os.time()
    
    print(`[AggroService] 🎯 ${player.Name} установлена агрессия ${newAggro} (${reason})`)
    
    SendAggroUpdate(player, newAggro)
    CheckAndTriggerAttack(player, newAggro)
end

function AggroService.GetAggroLevel(player: Player): number
    local data = AggroData[player.UserId]
    return data and data.CurrentAggro or 0
end

function AggroService.RegisterPogost(player: Player, pogostModel: Instance)
    PlayerPogosts[player.UserId] = pogostModel
    print(`[AggroService] 🏚️ Зарегистрирован погост для ${player.Name}`)
end

function AggroService.IsUnderAttack(player: Player): boolean
    local data = AggroData[player.UserId]
    return data and data.IsUnderAttack or false
end

function AggroService.GetMaxAggro(): number
    return MAX_AGGRO
end

-- ============================================
-- Цикл пассивного снижения агрессии
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
                local decayAmount = DECAY_PER_SECOND * deltaTime
                local newAggro = math.max(0, data.CurrentAggro - decayAmount)
                
                if newAggro ~= data.CurrentAggro then
                    data.CurrentAggro = newAggro
                    
                    local player = Players:GetPlayerByUserId(userId)
                    if player then
                        SendAggroUpdate(player, newAggro)
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
    
    AggroService.StartDecay()
    
    print("[AggroService] ========== ИНИЦИАЛИЗАЦИЯ ==========")
    print("   - Зависимости: ArmyService ✅")
    print("   - RemoteEvent: UpdateAggro ✅")
    print("   - За атаку на деревню: +", PER_ATTACK, "агро")
    print("   - За убийство жителя: +", PER_KILL, "агро")
    print("   - Пассивное снижение:", DECAY_PER_SECOND, "агро/сек")
    print("   - Порог атаки деревни:", ATTACK_THRESHOLD, "агро")
    print("[AggroService] ✅ Готов к работе")
end

return AggroService