-- src/server-modules/RitualService.lua
-- Воскрешение: труп → карточка в стек (через ArmyService)
-- Требует маны, проверяет доступность трупа

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local BaseStats = require(ReplicatedStorage.Constants.BaseStats)
local Enums = require(ReplicatedStorage.Shared.Enums)

-- Сервисы (заполняются при Init)
local ArmyService = nil
local CorpseManager = nil

-- ============================================
-- RemoteEvent для получения запросов от клиента
-- ============================================
local RemoteEvents = Instance.new("Folder")
RemoteEvents.Name = "RitualRemoteEvents"
RemoteEvents.Parent = ReplicatedStorage

local RequestResurrect = Instance.new("RemoteEvent")
RequestResurrect.Name = "RequestResurrect"
RequestResurrect.Parent = RemoteEvents

-- ============================================
-- Вспомогательные функции
-- ============================================

-- Получить стоимость воскрешения для юнита (из BaseStats)
local function GetResurrectCost(unitTypeId: string): number
    -- Базовая стоимость + возможно модификатор от силы юнита
    local unitData = BaseStats.Units[unitTypeId]
    if not unitData then
        return BaseStats.Mana.ActionCost.Resurrect  -- по умолчанию 10
    end
    
    -- Чем сильнее юнит, тем дороже воскресить (опционально)
    local tierBonus = (unitData.Tier - 1) * 2
    return BaseStats.Mana.ActionCost.Resurrect + tierBonus
end

-- Проверить, можно ли воскресить этот труп
local function CanResurrect(player: Player, corpseId: number): (boolean, string)
    local corpse = CorpseManager.GetCorpse(corpseId)
    if not corpse then
        return false, "Труп уже сгнил или не существует"
    end
    
    -- Проверка владельца (опционально: только убивший может воскресить?)
    -- Если ownerId == 0, труп ничей (можно любому)
    if corpse.OwnerId ~= 0 and corpse.OwnerId ~= player.UserId then
        return false, "Этот труп принадлежит другому игроку"
    end
    
    local cost = GetResurrectCost(corpse.UnitTypeId)
    local playerData = ArmyService.GetPlayerData(player)
    
    if not playerData then
        return false, "Ошибка загрузки данных игрока"
    end
    
    if playerData.Mana.Current < cost then
        return false, string.format("Недостаточно маны (нужно %d, есть %d)", cost, playerData.Mana.Current)
    end
    
    return true, ""
end

-- ============================================
-- ОСНОВНЫЕ ФУНКЦИИ (API)
-- ============================================

local RitualService = {}

-- Воскресить труп (создать карточку в стеке)
-- @return boolean, string|Card - успех, сообщение или созданная карточка
function RitualService.ResurrectCorpse(player: Player, corpseId: number)
    -- Проверка возможности
    local canResurrect, reason = CanResurrect(player, corpseId)
    if not canResurrect then
        print(`[RitualService] ❌ ${player.Name} не может воскресить: ${reason}`)
        return false, reason
    end
    
    local corpse = CorpseManager.GetCorpse(corpseId)
    if not corpse then
        return false, "Труп не найден"
    end
    
    local unitTypeId = corpse.UnitTypeId
    local cost = GetResurrectCost(unitTypeId)
    
    -- Тратим ману
    local success = ArmyService.SpendMana(player, cost, Enums.CubeAction.Resurrect)
    if not success then
        return false, "Не удалось списать ману"
    end
    
    -- Создаем карточку
    local cardId = `card_{player.UserId}_{os.time()}_{corpseId}`
    local unitData = BaseStats.Units[unitTypeId]
    
    local newCard = {
        CardId = cardId,
        UnitTypeId = unitTypeId,
        Modifiers = {},  -- Пока без улучшений
        IsMerged = false,
    }
    
    -- Добавляем в стек игрока
    ArmyService.AddCardToStack(player, newCard)
    
    -- Удаляем труп из мира
    CorpseManager.RemoveCorpse(corpseId)
    
    print(`[RitualService] ✨ ${player.Name} воскресил ${unitTypeId} (ID: ${corpseId}) → карточка ${cardId}`)
    
    -- TODO: Отправить клиенту обновление стека карточек
    
    return true, newCard
end

-- Получить список воскрешаемых трупов для игрока (для UI)
function RitualService.GetResurrectableCorpses(player: Player): { [number]: any }
    local result = {}
    local allCorpses = CorpseManager.GetAllCorpses()
    
    for id, corpse in pairs(allCorpses) do
        -- Ничей труп или принадлежит игроку
        if corpse.OwnerId == 0 or corpse.OwnerId == player.UserId then
            local cost = GetResurrectCost(corpse.UnitTypeId)
            result[id] = {
                CorpseId = id,
                UnitTypeId = corpse.UnitTypeId,
                Cost = cost,
                Position = corpse.Position,
                OwnerId = corpse.OwnerId,
            }
        end
    end
    
    return result
end

-- ============================================
-- ОБРАБОТЧИКИ REMOTES
-- ============================================

local function SetupRemotes()
    -- Клиент просит воскресить труп
    RequestResurrect.OnServerEvent:Connect(function(player: Player, corpseId: number)
        if type(corpseId) ~= "number" then
            print(`[RitualService] ⚠️ ${player.Name} отправил некорректный corpseId: ${corpseId}`)
            return
        end
        
        local success, result = RitualService.ResurrectCorpse(player, corpseId)
        
        if success then
            -- Отправляем подтверждение клиенту
            -- TODO: RemoteEvent для подтверждения успеха
            print(`[RitualService] ✅ ${player.Name} успешно воскресил труп ${corpseId}`)
        else
            -- Отправляем ошибку клиенту
            -- TODO: RemoteEvent для отправки ошибки
            print(`[RitualService] ❌ ${player.Name} не смог воскресить: ${result}`)
        end
    end)
    
    print("[RitualService] 📡 RemoteEvents настроены")
end

-- ============================================
-- ИНИЦИАЛИЗАЦИЯ
-- ============================================

function RitualService.Init(armyService, corpseManager)
    ArmyService = armyService
    CorpseManager = corpseManager
    
    if not ArmyService or not CorpseManager then
        error("[RitualService] ❌ Не удалось инициализировать: зависимые сервисы отсутствуют")
    end
    
    SetupRemotes()
    
    print("[RitualService] ========== ИНИЦИАЛИЗАЦИЯ ==========")
    print("   - Зависимости: ArmyService ✅, CorpseManager ✅")
    print("   - Стоимость воскрешения: базово", BaseStats.Mana.ActionCost.Resurrect, "маны")
    print("   - Количество типов юнитов для воскрешения:", table.count(BaseStats.Units))
    print("[RitualService] ✅ Готов к работе")
end

return RitualService