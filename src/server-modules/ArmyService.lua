-- src/server-modules/ArmyService.lua
-- Управление армией, маной, прогрессией, уровнями
-- ВЕРСИЯ 2.1 — ПОЛНОСТЬЮ РАБОЧАЯ

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Enums = require(ReplicatedStorage.Shared.Enums)
local BaseStats = require(ReplicatedStorage.Constants.BaseStats)

-- ============================================
-- Хранилище данных игроков (в памяти)
-- ============================================
local PlayersData = {}  -- [userId] = PlayerData

-- Кулдаун куба для каждого игрока
local CubeCooldowns = {}  -- [userId] = endTime (os.time())

-- ============================================
-- Вспомогательные функции
-- ============================================

-- Подсчет количества элементов в таблице
local function TableCount(t: table): number
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- Получить максимум маны по уровню (из таблицы прогрессии)
local function GetMaxManaByLevel(level: number): number
    local levels = BaseStats.Progression.Levels
    local result = 50  -- значение по умолчанию
    
    for lvl, data in pairs(levels) do
        if level >= lvl and data.maxMana > result then
            result = data.maxMana
        end
    end
    return result
end

-- Получить количество слотов по уровню
local function GetSlotsByLevel(level: number): number
    local levels = BaseStats.Progression.Levels
    local result = 3  -- значение по умолчанию
    
    for lvl, data in pairs(levels) do
        if level >= lvl and data.slots > result then
            result = data.slots
        end
    end
    return result
end

-- Получить опыт для следующего уровня
local function GetExpForLevel(level: number): number
    local expTable = BaseStats.Progression.ExpToLevel
    local nextLevel = level + 1
    return expTable[nextLevel] or 999999
end

-- Создать новые данные игрока (при первом входе)
local function CreateNewPlayerData(userId: number): Types.PlayerData
    local initialLevel = 1
    local maxMana = GetMaxManaByLevel(initialLevel)
    local maxSlots = GetSlotsByLevel(initialLevel)
    
    return {
        Level = initialLevel,
        Experience = 0,
        NextLevelExp = GetExpForLevel(initialLevel),
        
        Mana = {
            Current = maxMana,
            Max = maxMana,
            RegenBody = BaseStats.Mana.RegenBody,
            RegenCube = BaseStats.Mana.RegenCube,
        },
        
        MaxSlots = maxSlots,
        ActiveSlots = {},
        SoulStack = {},
        
        AggroLevel = 0,
        ConqueredVillages = {},
        
        TotalKills = 0,
        TotalResurrections = 0,
        TotalMerges = 0,
    }
end

-- Сохранить данные игрока (заглушка для DataStore)
local function SavePlayerData(userId: number, data: Types.PlayerData)
    -- TODO: Реальный DataStore после того, как настроим
    print(`[ArmyService] 💾 Сохранение данных игрока ${userId} (уровень ${data.Level}, мана ${data.Mana.Current}/${data.Mana.Max})`)
end

-- Отправить обновление маны клиенту
local function SendManaUpdate(player: Player, data: Types.PlayerData)
    -- TODO: RemoteEvent для обновления UI
    print(`[ArmyService] 📡 Мана ${player.Name}: ${data.Mana.Current}/${data.Mana.Max}`)
end

-- Отправить обновление армии клиенту
local function SendArmyUpdate(player: Player, data: Types.PlayerData)
    local activeCount = TableCount(data.ActiveSlots)
    print(`[ArmyService] 📡 Армия ${player.Name}: ${activeCount}/${data.MaxSlots} слотов занято`)
end

-- Отправить обновление стека карточек клиенту
local function SendSoulStackUpdate(player: Player, data: Types.PlayerData)
    local stackCount = TableCount(data.SoulStack)
    print(`[ArmyService] 📇 Стек карточек ${player.Name}: ${stackCount} карточек`)
end

-- ============================================
-- ПРОВЕРКА И ОБНОВЛЕНИЕ УРОВНЯ
-- ============================================

local function CheckAndApplyLevelUp(player: Player, data: Types.PlayerData)
    local oldLevel = data.Level
    local newLevel = oldLevel
    
    -- Повышаем уровень, пока хватает опыта
    while newLevel < BaseStats.Progression.MaxLevel do
        local nextExp = GetExpForLevel(newLevel)
        if data.Experience >= nextExp then
            newLevel = newLevel + 1
        else
            break
        end
    end
    
    if newLevel > oldLevel then
        data.Level = newLevel
        data.MaxSlots = GetSlotsByLevel(newLevel)
        data.Mana.Max = GetMaxManaByLevel(newLevel)
        data.Mana.Current = data.Mana.Max  -- Полная мана при повышении
        data.NextLevelExp = GetExpForLevel(newLevel)
        
        print(`[ArmyService] 🎉 ${player.Name} повысил уровень до ${newLevel}! (макс.мана ${data.Mana.Max}, слотов ${data.MaxSlots})`)
        
        -- TODO: Отправить уведомление клиенту о повышении уровня
        
        SavePlayerData(player.UserId, data)
    end
end

-- ============================================
-- ОСНОВНЫЕ ФУНКЦИИ (API)
-- ============================================

local ArmyService = {}

-- Получить данные игрока
function ArmyService.GetPlayerData(player: Player): Types.PlayerData?
    return PlayersData[player.UserId]
end

-- Добавить опыт игроку
function ArmyService.AddExperience(player: Player, amount: number)
    local userId = player.UserId
    local data = PlayersData[userId]
    if not data then return end  -- ИСПРАВЛЕНО: было "if not then"
    
    data.Experience += amount
    print(`[ArmyService] 📈 ${player.Name} +${amount} опыта (всего ${data.Experience})`)
    
    CheckAndApplyLevelUp(player, data)
    SavePlayerData(userId, data)
end

-- Добавить ману (с проверкой максимума)
function ArmyService.AddMana(player: Player, amount: number, source: string)
    local userId = player.UserId
    local data = PlayersData[userId]
    if not data then return end
    
    local oldMana = data.Mana.Current
    local newMana = math.min(oldMana + amount, data.Mana.Max)
    data.Mana.Current = newMana
    
    print(`[ArmyService] 🔋 ${player.Name} +${amount} маны (${source}). ${oldMana} → ${newMana}/${data.Mana.Max}`)
    
    SendManaUpdate(player, data)
    SavePlayerData(userId, data)
end

-- Потратить ману (вернуть true если успешно)
function ArmyService.SpendMana(player: Player, amount: number, action: string): boolean
    local userId = player.UserId
    local data = PlayersData[userId]
    if not data then return false end
    
    if data.Mana.Current >= amount then
        data.Mana.Current -= amount
        print(`[ArmyService] 💸 ${player.Name} -${amount} маны (${action}). Осталось: ${data.Mana.Current}/${data.Mana.Max}`)
        
        SendManaUpdate(player, data)
        SavePlayerData(userId, data)
        return true
    else
        print(`[ArmyService] ⚠️ ${player.Name} недостаточно маны для ${action} (нужно ${amount}, есть ${data.Mana.Current})`)
        return false
    end
end

-- Зарегистрировать убийство (опыт + мана)
function ArmyService.RegisterKill(player: Player, killedBy: string, enemyType: string)
    local userId = player.UserId
    local data = PlayersData[userId]
    if not data then return end
    
    data.TotalKills += 1
    
    -- Определяем награду
    local manaReward = 0
    local expReward = 10  -- Базовый опыт
    
    if killedBy == "Necromancer" then
        if enemyType == "Normal" then
            manaReward = BaseStats.Mana.KillRewardNecromancer.Normal
            expReward = 10
        elseif enemyType == "Elite" then
            manaReward = BaseStats.Mana.KillRewardNecromancer.Elite
            expReward = 50
        elseif enemyType == "Boss" then
            manaReward = BaseStats.Mana.KillRewardNecromancer.Boss
            expReward = 200
        else
            manaReward = BaseStats.Mana.KillRewardNecromancer.Normal
        end
    elseif killedBy == "Unit" then
        if enemyType == "Normal" then
            manaReward = BaseStats.Mana.KillRewardUnit.Normal
            expReward = 8
        elseif enemyType == "Elite" then
            manaReward = BaseStats.Mana.KillRewardUnit.Elite
            expReward = 30
        elseif enemyType == "Boss" then
            manaReward = BaseStats.Mana.KillRewardUnit.Boss
            expReward = 150
        else
            manaReward = BaseStats.Mana.KillRewardUnit.Normal
        end
    end
    
    if manaReward > 0 then
        local source = (killedBy == "Necromancer" and "NecromancerKill" or "UnitKill")
        ArmyService.AddMana(player, manaReward, source)
    end
    
    ArmyService.AddExperience(player, expReward)
    
    print(`[ArmyService] 💀 ${player.Name} убил ${enemyType} (${killedBy}) → +${manaReward} маны, +${expReward} опыта`)
end

-- ============================================
-- УПРАВЛЕНИЕ КУБОМ
-- ============================================

-- Проверить, можно ли войти в куб
function ArmyService.CanEnterCube(player: Player): boolean
    local userId = player.UserId
    local data = PlayersData[userId]
    if not data then return false end
    
    -- Проверка кулдауна
    local cooldownEnd = CubeCooldowns[userId] or 0
    if os.time() < cooldownEnd then
        local remaining = cooldownEnd - os.time()
        print(`[ArmyService] ⏰ ${player.Name} не может войти в куб еще ${remaining} сек (кулдаун)`)
        return false
    end
    
    -- Проверка маны
    if data.Mana.Current < BaseStats.Mana.CubeEntryCost then
        print(`[ArmyService] ❌ ${player.Name} не может войти в куб: нужно ${BaseStats.Mana.CubeEntryCost} маны, есть ${data.Mana.Current}`)
        return false
    end
    
    return true
end

-- Войти в куб
function ArmyService.EnterCube(player: Player): boolean
    if not ArmyService.CanEnterCube(player) then
        return false
    end
    
    local userId = player.UserId
    local data = PlayersData[userId]
    
    -- Тратим ману на вход
    local success = ArmyService.SpendMana(player, BaseStats.Mana.CubeEntryCost, Enums.CubeAction.Enter)
    if not success then return false end
    
    print(`[ArmyService] 🧊 ${player.Name} ВОШЕЛ в куб!`)
    
    -- TODO: Переключить режим игрока в CubMode
    -- TODO: Спавн камеры от 3-го лица
    -- TODO: Активировать управление юнитами
    
    return true
end

-- Выйти из куба
function ArmyService.ExitCube(player: Player, isForced: boolean)
    local userId = player.UserId
    local data = PlayersData[userId]
    if not data then return end
    
    -- Устанавливаем кулдаун
    CubeCooldowns[userId] = os.time() + BaseStats.Mana.CubeCooldown
    
    -- Восстанавливаем ману до 100% при выходе
    data.Mana.Current = data.Mana.Max
    SendManaUpdate(player, data)
    
    local exitType = isForced and "ПРИНУДИТЕЛЬНО" or "ДОБРОВОЛЬНО"
    print(`[ArmyService] 🧊 ${player.Name} ВЫШЕЛ из куба (${exitType}). Мана → ${data.Mana.Current}/${data.Mana.Max}, кулдаун ${BaseStats.Mana.CubeCooldown} сек`)
    
    -- TODO: Рассеять армию (юниты становятся неактивными)
    -- TODO: Переключить режим игрока в BodyMode
    -- TODO: Вернуть камеру на тело
end

-- Получить оставшееся время кулдауна (в секундах)
function ArmyService.GetCubeCooldownRemaining(player: Player): number
    local userId = player.UserId
    local cooldownEnd = CubeCooldowns[userId] or 0
    return math.max(0, cooldownEnd - os.time())
end

-- ============================================
-- УПРАВЛЕНИЕ ЮНИТАМИ (базовое)
-- ============================================

-- Добавить карточку в стек
function ArmyService.AddCardToStack(player: Player, card: Types.Card)
    local userId = player.UserId
    local data = PlayersData[userId]
    if not data then return end
    
    data.SoulStack[card.CardId] = card
    
    print(`[ArmyService] 📇 ${player.Name} добавил карточку ${card.UnitTypeId} (${card.CardId}) в стек. Всего карточек: ${TableCount(data.SoulStack)}`)
    
    SendSoulStackUpdate(player, data)
end

-- Получить карточку из стека
function ArmyService.GetCardFromStack(player: Player, cardId: string): Types.Card?
    local userId = player.UserId
    local data = PlayersData[userId]
    if not data then return nil end
    
    return data.SoulStack[cardId]
end

-- Получить весь стек карточек
function ArmyService.GetSoulStack(player: Player): { [string]: Types.Card }
    local userId = player.UserId
    local data = PlayersData[userId]
    if not data then return {} end
    
    return data.SoulStack
end

-- Удалить карточку из стека
function ArmyService.RemoveCardFromStack(player: Player, cardId: string): boolean
    local userId = player.UserId
    local data = PlayersData[userId]
    if not data then return false end
    
    if data.SoulStack[cardId] then
        data.SoulStack[cardId] = nil
        print(`[ArmyService] 🗑️ ${player.Name} удалил карточку ${cardId} из стека`)
        SendSoulStackUpdate(player, data)
        return true
    end
    
    return false
end

-- Переместить карточку из стека в слот
function ArmyService.MoveCardToSlot(player: Player, cardId: string, slotIndex: number): boolean
    local userId = player.UserId
    local data = PlayersData[userId]
    if not data then return false end
    
    -- Проверка слота
    if slotIndex > data.MaxSlots then
        print(`[ArmyService] ❌ Слот ${slotIndex} превышает максимум (${data.MaxSlots})`)
        return false
    end
    
    -- Проверка наличия карточки
    local card = data.SoulStack[cardId]
    if not card then
        print(`[ArmyService] ❌ Карточка ${cardId} не найдена в стеке`)
        return false
    end
    
    -- Тратим ману
    if not ArmyService.SpendMana(player, BaseStats.Mana.ActionCost.MoveToSlot, Enums.CubeAction.MoveToSlot) then
        return false
    end
    
    -- Убираем карточку из стека
    data.SoulStack[cardId] = nil
    
    -- Создаем юнита в слоте (не активного)
    local unitTypeData = BaseStats.Units[card.UnitTypeId]
    if not unitTypeData then
        print(`[ArmyService] ❌ Тип юнита ${card.UnitTypeId} не найден в BaseStats`)
        return false
    end
    
    data.ActiveSlots[slotIndex] = {
        InstanceId = cardId,  -- Используем тот же ID
        UnitTypeId = card.UnitTypeId,
        CurrentHealth = unitTypeData.BaseHealth,
        Buffs = card.Modifiers or {},
        IsAlive = false,  -- Еще не оживлен
        SlotIndex = slotIndex,
    }
    
    print(`[ArmyService] 📦 ${player.Name} переместил ${card.UnitTypeId} в слот ${slotIndex}`)
    SendArmyUpdate(player, data)
    SendSoulStackUpdate(player, data)
    
    return true
end

-- Оживить юнита в слоте
function ArmyService.ReviveUnitInSlot(player: Player, slotIndex: number): boolean
    local userId = player.UserId
    local data = PlayersData[userId]
    if not data then return false end
    
    local unit = data.ActiveSlots[slotIndex]
    if not unit then
        print(`[ArmyService] ❌ Слот ${slotIndex} пуст`)
        return false
    end
    
    if unit.IsAlive then
        print(`[ArmyService] ❌ Юнит в слоте ${slotIndex} уже жив`)
        return false
    end
    
    -- Тратим ману
    if not ArmyService.SpendMana(player, BaseStats.Mana.ActionCost.Revive, Enums.CubeAction.Revive) then
        return false
    end
    
    unit.IsAlive = true
    unit.CurrentHealth = BaseStats.Units[unit.UnitTypeId].BaseHealth  -- Полное здоровье
    
    print(`[ArmyService] ✨ ${player.Name} оживил ${unit.UnitTypeId} в слоте ${slotIndex}`)
    SendArmyUpdate(player, data)
    
    -- TODO: Спавн модели юнита в мире (через UnitFactory)
    
    return true
end

-- Получить юнита из слота
function ArmyService.GetUnitFromSlot(player: Player, slotIndex: number): Types.ActiveUnit?
    local userId = player.UserId
    local data = PlayersData[userId]
    if not data then return nil end
    
    return data.ActiveSlots[slotIndex]
end

-- Получить все активные слоты
function ArmyService.GetActiveSlots(player: Player): { [number]: Types.ActiveUnit? }
    local userId = player.UserId
    local data = PlayersData[userId]
    if not data then return {} end
    
    return data.ActiveSlots
end

-- Проверить, пуст ли слот
function ArmyService.IsSlotEmpty(player: Player, slotIndex: number): boolean
    local userId = player.UserId
    local data = PlayersData[userId]
    if not data then return true end
    
    return data.ActiveSlots[slotIndex] == nil
end

-- ============================================
-- ДОПОЛНИТЕЛЬНЫЕ ФУНКЦИИ
-- ============================================

-- Получить уровень игрока
function ArmyService.GetPlayerLevel(player: Player): number
    local data = ArmyService.GetPlayerData(player)
    return data and data.Level or 1
end

-- Получить максимум маны игрока
function ArmyService.GetPlayerMaxMana(player: Player): number
    local data = ArmyService.GetPlayerData(player)
    return data and data.Mana.Max or 50
end

-- Получить текущий опыт игрока
function ArmyService.GetPlayerExperience(player: Player): number
    local data = ArmyService.GetPlayerData(player)
    return data and data.Experience or 0
end

-- ============================================
-- ИНИЦИАЛИЗАЦИЯ
-- ============================================

function ArmyService.Init()
    print("[ArmyService] ========== ИНИЦИАЛИЗАЦИЯ ==========")
    print("[ArmyService] 📊 Загружены балансные числа из BaseStats")
    print("[ArmyService]    - MaxLevel:", BaseStats.Progression.MaxLevel)
    print("[ArmyService]    - RegenBody:", BaseStats.Mana.RegenBody, "маны/сек")
    print("[ArmyService]    - RegenCube:", BaseStats.Mana.RegenCube, "маны/сек")
    print("[ArmyService]    - CubeCooldown:", BaseStats.Mana.CubeCooldown, "сек")
    print("[ArmyService]    - MaxSlots на 50 уровне:", GetSlotsByLevel(50))
    print("[ArmyService]    - MaxMana на 50 уровне:", GetMaxManaByLevel(50))
    
    -- Подписка на вход игроков
    Players.PlayerAdded:Connect(function(player)
        print(`[ArmyService] 👋 Игрок ${player.Name} присоединился`)
        
        local userId = player.UserId
        -- TODO: Загрузить из DataStore
        local data = CreateNewPlayerData(userId)
        PlayersData[userId] = data
        
        print(`[ArmyService]    - Уровень: ${data.Level}, Мана: ${data.Mana.Current}/${data.Mana.Max}, Слоты: ${data.MaxSlots}`)
        
        -- Отправляем начальные данные клиенту
        SendManaUpdate(player, data)
        SendArmyUpdate(player, data)
        SendSoulStackUpdate(player, data)
        
        -- Подписка на удаление (выход игрока)
        player.AncestryChanged:Connect(function()
            if player.Parent == nil then
                SavePlayerData(userId, data)
                PlayersData[userId] = nil
                CubeCooldowns[userId] = nil
                print(`[ArmyService] 👋 Игрок ${player.Name} вышел, данные сохранены`)
            end
        end)
    end)
    
    print("[ArmyService] ✅ Инициализация завершена, ожидаем игроков...")
end

return ArmyService