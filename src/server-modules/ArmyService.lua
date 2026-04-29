-- src/server-modules/ArmyService.lua
-- Управление армией, маной, прогрессией, уровнями
-- ВЕРСИЯ 3.0 — С REMOTEEVENT'АМИ И ПОЛНОЙ СВЯЗЬЮ С КЛИЕНТОМ

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Enums = require(ReplicatedStorage.Shared.Enums)
local BaseStats = require(ReplicatedStorage.Constants.BaseStats)

-- ============================================
-- RemoteEvents для связи с клиентом
-- ============================================

local RemoteEventsFolder = Instance.new("Folder")
RemoteEventsFolder.Name = "ArmyRemoteEvents"
RemoteEventsFolder.Parent = ReplicatedStorage

-- События сервер → клиент
local UpdateManaEvent = Instance.new("RemoteEvent")
UpdateManaEvent.Name = "UpdateMana"
UpdateManaEvent.Parent = RemoteEventsFolder

local UpdateArmyEvent = Instance.new("RemoteEvent")
UpdateArmyEvent.Name = "UpdateArmy"
UpdateArmyEvent.Parent = RemoteEventsFolder

local UpdateSoulStackEvent = Instance.new("RemoteEvent")
UpdateSoulStackEvent.Name = "UpdateSoulStack"
UpdateSoulStackEvent.Parent = RemoteEventsFolder

local UpdateLevelEvent = Instance.new("RemoteEvent")
UpdateLevelEvent.Name = "UpdateLevel"
UpdateLevelEvent.Parent = RemoteEventsFolder

local UpdateCubeCooldownEvent = Instance.new("RemoteEvent")
UpdateCubeCooldownEvent.Name = "UpdateCubeCooldown"
UpdateCubeCooldownEvent.Parent = RemoteEventsFolder

-- События клиент → сервер
local RequestEnterCubeEvent = Instance.new("RemoteEvent")
RequestEnterCubeEvent.Name = "RequestEnterCube"
RequestEnterCubeEvent.Parent = RemoteEventsFolder

local RequestExitCubeEvent = Instance.new("RemoteEvent")
RequestExitCubeEvent.Name = "RequestExitCube"
RequestExitCubeEvent.Parent = RemoteEventsFolder

-- ============================================
-- Хранилище данных игроков (в памяти)
-- ============================================
local PlayersData = {}  -- [userId] = PlayerData

-- Кулдаун куба для каждого игрока
local CubeCooldowns = {}  -- [userId] = endTime (os.time())

-- Режим игрока (Body или Cube)
local PlayerMode = {}  -- [userId] = "Body" or "Cube"

-- ============================================
-- Вспомогательные функции
-- ============================================

local function TableCount(t: table): number
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

local function GetMaxManaByLevel(level: number): number
    local levels = BaseStats.Progression.Levels
    local result = 50
    for lvl, data in pairs(levels) do
        if level >= lvl and data.maxMana > result then
            result = data.maxMana
        end
    end
    return result
end

local function GetSlotsByLevel(level: number): number
    local levels = BaseStats.Progression.Levels
    local result = 3
    for lvl, data in pairs(levels) do
        if level >= lvl and data.slots > result then
            result = data.slots
        end
    end
    return result
end

local function GetExpForLevel(level: number): number
    local expTable = BaseStats.Progression.ExpToLevel
    local nextLevel = level + 1
    return expTable[nextLevel] or 999999
end

-- ============================================
-- Отправка обновлений клиенту
-- ============================================

local function SendManaUpdate(player: Player, data: Types.PlayerData)
    UpdateManaEvent:FireClient(player, data.Mana.Current, data.Mana.Max)
end

local function SendArmyUpdate(player: Player, data: Types.PlayerData)
    UpdateArmyEvent:FireClient(player, data.MaxSlots, data.ActiveSlots)
end

local function SendSoulStackUpdate(player: Player, data: Types.PlayerData)
    UpdateSoulStackEvent:FireClient(player, data.SoulStack)
end

local function SendLevelUpdate(player: Player, data: Types.PlayerData)
    UpdateLevelEvent:FireClient(player, data.Level, data.Experience, data.NextLevelExp)
end

local function SendCubeCooldownUpdate(player: Player)
    local remaining = 0
    local cooldownEnd = CubeCooldowns[player.UserId] or 0
    if os.time() < cooldownEnd then
        remaining = cooldownEnd - os.time()
    end
    UpdateCubeCooldownEvent:FireClient(player, remaining)
end

-- ============================================
-- Создание новых данных игрока
-- ============================================

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

local function SavePlayerData(userId: number, data: Types.PlayerData)
    print(`[ArmyService] 💾 Сохранение данных игрока ${userId} (уровень ${data.Level})`)
end

-- ============================================
-- Проверка и повышение уровня
-- ============================================

local function CheckAndApplyLevelUp(player: Player, data: Types.PlayerData)
    local oldLevel = data.Level
    local newLevel = oldLevel
    
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
        data.Mana.Current = data.Mana.Max
        data.NextLevelExp = GetExpForLevel(newLevel)
        
        print(`[ArmyService] 🎉 ${player.Name} повысил уровень до ${newLevel}!`)
        
        SendLevelUpdate(player, data)
        SendManaUpdate(player, data)
        SendArmyUpdate(player, data)
        
        SavePlayerData(player.UserId, data)
    end
end

-- ============================================
-- ОСНОВНЫЕ ФУНКЦИИ (API)
-- ============================================

local ArmyService = {}

function ArmyService.GetPlayerData(player: Player): Types.PlayerData?
    return PlayersData[player.UserId]
end

function ArmyService.AddExperience(player: Player, amount: number)
    local userId = player.UserId
    local data = PlayersData[userId]
    if not data then return end
    
    data.Experience += amount
    print(`[ArmyService] 📈 ${player.Name} +${amount} опыта (всего ${data.Experience})`)
    
    CheckAndApplyLevelUp(player, data)
    SavePlayerData(userId, data)
end

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

function ArmyService.RegisterKill(player: Player, killedBy: string, enemyType: string)
    local userId = player.UserId
    local data = PlayersData[userId]
    if not data then return end
    
    data.TotalKills += 1
    
    local manaReward = 0
    local expReward = 10
    
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

function ArmyService.CanEnterCube(player: Player): boolean
    local userId = player.UserId
    local data = PlayersData[userId]
    if not data then return false end
    
    local cooldownEnd = CubeCooldowns[userId] or 0
    if os.time() < cooldownEnd then
        return false
    end
    
    if data.Mana.Current < BaseStats.Mana.CubeEntryCost then
        return false
    end
    
    return true
end

function ArmyService.EnterCube(player: Player): boolean
    if not ArmyService.CanEnterCube(player) then
        return false
    end
    
    local userId = player.UserId
    local data = PlayersData[userId]
    
    local success = ArmyService.SpendMana(player, BaseStats.Mana.CubeEntryCost, Enums.CubeAction.Enter)
    if not success then return false end
    
    PlayerMode[userId] = "Cube"
    
    print(`[ArmyService] 🧊 ${player.Name} ВОШЕЛ в куб! (режим: ${PlayerMode[userId]})`)
    
    return true
end

function ArmyService.ExitCube(player: Player, isForced: boolean)
    local userId = player.UserId
    local data = PlayersData[userId]
    if not data then return end
    
    CubeCooldowns[userId] = os.time() + BaseStats.Mana.CubeCooldown
    
    data.Mana.Current = data.Mana.Max
    SendManaUpdate(player, data)
    SendCubeCooldownUpdate(player)
    
    PlayerMode[userId] = "Body"
    
    local exitType = isForced and "ПРИНУДИТЕЛЬНО" or "ДОБРОВОЛЬНО"
    print(`[ArmyService] 🧊 ${player.Name} ВЫШЕЛ из куба (${exitType}). Режим: ${PlayerMode[userId]}`)
end

function ArmyService.GetCubeCooldownRemaining(player: Player): number
    local userId = player.UserId
    local cooldownEnd = CubeCooldowns[userId] or 0
    return math.max(0, cooldownEnd - os.time())
end

function ArmyService.GetPlayerMode(player: Player): string
    return PlayerMode[player.UserId] or "Body"
end

-- ============================================
-- УПРАВЛЕНИЕ ЮНИТАМИ
-- ============================================

function ArmyService.AddCardToStack(player: Player, card: Types.Card)
    local userId = player.UserId
    local data = PlayersData[userId]
    if not data then return end
    
    data.SoulStack[card.CardId] = card
    print(`[ArmyService] 📇 ${player.Name} добавил карточку ${card.UnitTypeId}`)
    SendSoulStackUpdate(player, data)
end

function ArmyService.GetCardFromStack(player: Player, cardId: string): Types.Card?
    local data = PlayersData[player.UserId]
    return data and data.SoulStack[cardId]
end

function ArmyService.GetSoulStack(player: Player): { [string]: Types.Card }
    local data = PlayersData[player.UserId]
    return data and data.SoulStack or {}
end

function ArmyService.RemoveCardFromStack(player: Player, cardId: string): boolean
    local userId = player.UserId
    local data = PlayersData[userId]
    if not data or not data.SoulStack[cardId] then return false end
    
    data.SoulStack[cardId] = nil
    print(`[ArmyService] 🗑️ ${player.Name} удалил карточку ${cardId}`)
    SendSoulStackUpdate(player, data)
    return true
end

function ArmyService.MoveCardToSlot(player: Player, cardId: string, slotIndex: number): boolean
    local userId = player.UserId
    local data = PlayersData[userId]
    if not data then return false end
    
    if slotIndex > data.MaxSlots then
        print(`[ArmyService] ❌ Слот ${slotIndex} превышает максимум (${data.MaxSlots})`)
        return false
    end
    
    local card = data.SoulStack[cardId]
    if not card then
        print(`[ArmyService] ❌ Карточка ${cardId} не найдена`)
        return false
    end
    
    if not ArmyService.SpendMana(player, BaseStats.Mana.ActionCost.MoveToSlot, Enums.CubeAction.MoveToSlot) then
        return false
    end
    
    data.SoulStack[cardId] = nil
    
    local unitTypeData = BaseStats.Units[card.UnitTypeId]
    if not unitTypeData then
        print(`[ArmyService] ❌ Тип юнита ${card.UnitTypeId} не найден`)
        return false
    end
    
    data.ActiveSlots[slotIndex] = {
        InstanceId = cardId,
        UnitTypeId = card.UnitTypeId,
        CurrentHealth = unitTypeData.BaseHealth,
        Buffs = card.Modifiers or {},
        IsAlive = false,
        SlotIndex = slotIndex,
    }
    
    print(`[ArmyService] 📦 ${player.Name} переместил ${card.UnitTypeId} в слот ${slotIndex}`)
    SendArmyUpdate(player, data)
    SendSoulStackUpdate(player, data)
    
    return true
end

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
    
    if not ArmyService.SpendMana(player, BaseStats.Mana.ActionCost.Revive, Enums.CubeAction.Revive) then
        return false
    end
    
    unit.IsAlive = true
    unit.CurrentHealth = BaseStats.Units[unit.UnitTypeId].BaseHealth
    
    print(`[ArmyService] ✨ ${player.Name} оживил ${unit.UnitTypeId} в слоте ${slotIndex}`)
    SendArmyUpdate(player, data)
    
    return true
end

function ArmyService.GetUnitFromSlot(player: Player, slotIndex: number): Types.ActiveUnit?
    local data = PlayersData[player.UserId]
    return data and data.ActiveSlots[slotIndex]
end

function ArmyService.GetActiveSlots(player: Player): { [number]: Types.ActiveUnit? }
    local data = PlayersData[player.UserId]
    return data and data.ActiveSlots or {}
end

function ArmyService.IsSlotEmpty(player: Player, slotIndex: number): boolean
    local data = PlayersData[player.UserId]
    return not data or data.ActiveSlots[slotIndex] == nil
end

-- ============================================
-- ДОПОЛНИТЕЛЬНЫЕ ФУНКЦИИ
-- ============================================

function ArmyService.GetPlayerLevel(player: Player): number
    local data = PlayersData[player.UserId]
    return data and data.Level or 1
end

function ArmyService.GetPlayerMaxMana(player: Player): number
    local data = PlayersData[player.UserId]
    return data and data.Mana.Max or 50
end

function ArmyService.GetPlayerExperience(player: Player): number
    local data = PlayersData[player.UserId]
    return data and data.Experience or 0
end

-- ============================================
-- ОБРАБОТЧИКИ REMOTEEVENTS
-- ============================================

local function SetupRemoteEventHandlers()
    RequestEnterCubeEvent.OnServerEvent:Connect(function(player)
        ArmyService.EnterCube(player)
    end)
    
    RequestExitCubeEvent.OnServerEvent:Connect(function(player, isForced)
        ArmyService.ExitCube(player, isForced or false)
    end)
end

-- ============================================
-- ИНИЦИАЛИЗАЦИЯ
-- ============================================

function ArmyService.Init()
    print("[ArmyService] ========== ИНИЦИАЛИЗАЦИЯ ==========")
    print("[ArmyService] 📊 Загружены балансные числа из BaseStats")
    print("[ArmyService]    - MaxLevel:", BaseStats.Progression.MaxLevel)
    print("[ArmyService]    - CubeCooldown:", BaseStats.Mana.CubeCooldown, "сек")
    print("[ArmyService]    - MaxSlots на 50 уровне:", GetSlotsByLevel(50))
    
    SetupRemoteEventHandlers()
    
    Players.PlayerAdded:Connect(function(player)
        print(`[ArmyService] 👋 Игрок ${player.Name} присоединился`)
        
        local userId = player.UserId
        local data = CreateNewPlayerData(userId)
        PlayersData[userId] = data
        PlayerMode[userId] = "Body"
        
        print(`[ArmyService]    - Уровень: ${data.Level}, Мана: ${data.Mana.Current}/${data.Mana.Max}, Слоты: ${data.MaxSlots}`)
        
        SendManaUpdate(player, data)
        SendArmyUpdate(player, data)
        SendSoulStackUpdate(player, data)
        SendLevelUpdate(player, data)
        SendCubeCooldownUpdate(player)
        
        player.AncestryChanged:Connect(function()
            if player.Parent == nil then
                SavePlayerData(userId, data)
                PlayersData[userId] = nil
                CubeCooldowns[userId] = nil
                PlayerMode[userId] = nil
                print(`[ArmyService] 👋 Игрок ${player.Name} вышел`)
            end
        end)
    end)
    
    print("[ArmyService] ✅ Инициализация завершена")
end

return ArmyService