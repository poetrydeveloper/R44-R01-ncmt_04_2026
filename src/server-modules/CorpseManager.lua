-- src/server-modules/CorpseManager.lua
-- Управление трупами: таймеры гниения, создание, удаление
-- Труп живет 45 секунд (или значение из BaseStats), затем исчезает

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BaseStats = require(ReplicatedStorage.Constants.BaseStats)

-- ============================================
-- Хранилище активных трупов
-- ============================================
-- Структура:
-- Corpses[corpseId] = {
--     Model = Instance,     -- 3D модель трупа в мире
--     ExpireTime = number,  -- os.time() + время жизни
--     UnitTypeId = string,  -- Тип юнита (например "SkeletonWarrior")
--     Position = Vector3,   -- Позиция для спавна
--     OwnerId = number,     -- ID игрока, который убил (кому принадлежит труп)
-- }

local Corpses = {}  -- [corpseId] = corpseData
local nextCorpseId = 1

-- Время жизни трупа (из конфига, 45 секунд по умолчанию)
local DECAY_TIME = BaseStats.Graveyard.CorpseDecayTime or 45

-- ============================================
-- Внутренние функции
-- ============================================

-- Удалить труп (из мира и из памяти)
local function DestroyCorpse(corpseId: number)
    local corpse = Corpses[corpseId]
    if not corpse then return end
    
    print(`[CorpseManager] 💀 Труп ${corpseId} (${corpse.UnitTypeId}) сгнил и исчез`)
    
    -- Удаляем модель из мира
    if corpse.Model and corpse.Model.Parent then
        corpse.Model:Destroy()
    end
    
    -- Удаляем из таблицы
    Corpses[corpseId] = nil
end

-- ============================================
-- Публичные функции (API)
-- ============================================

local CorpseManager = {}

-- Создать труп в мире
-- @param unitTypeId: string - тип юнита (из BaseStats.Units)
-- @param position: Vector3 - место, где упал труп
-- @param ownerId: number - UserId игрока, который убил (или 0 если ничей)
-- @param customModel: Instance? - опционально, готовая модель трупа
-- @return corpseId: number - ID созданного трупа
function CorpseManager.CreateCorpse(
    unitTypeId: string,
    position: Vector3,
    ownerId: number,
    customModel: Instance?
): number
    local corpseId = nextCorpseId
    nextCorpseId += 1
    
    local expireTime = os.time() + DECAY_TIME
    
    -- Создаем или используем готовую модель
    local model = customModel
    if not model then
        -- TODO: Создать простую модель трупа (например, дымок + иконка)
        -- Пока создаем заглушку — Part с названием
        model = Instance.new("Part")
        model.Name = `Corpse_{unitTypeId}`
        model.Size = Vector3.new(3, 1, 3)
        model.BrickColor = BrickColor.new("Dark gray")
        model.Material = Enum.Material.Slate
        model.Anchored = true
        model.CanCollide = true
        model.Transparency = 0.3
        model.Position = position
        model.Parent = workspace
    end
    
    -- Сохраняем данные
    Corpses[corpseId] = {
        Model = model,
        ExpireTime = expireTime,
        UnitTypeId = unitTypeId,
        Position = position,
        OwnerId = ownerId,
    }
    
    print(`[CorpseManager] 🩸 Создан труп ${corpseId} (${unitTypeId}) на ${position}. Исчезнет через ${DECAY_TIME} сек`)
    
    return corpseId
end

-- Получить данные трупа по ID
function CorpseManager.GetCorpse(corpseId: number)
    return Corpses[corpseId]
end

-- Получить труп по модели (если кликнули по ней)
function CorpseManager.GetCorpseByModel(model: Instance): (number, any)
    for id, corpse in pairs(Corpses) do
        if corpse.Model == model then
            return id, corpse
        end
    end
    return nil, nil
end

-- Удалить труп принудительно (например, после воскрешения)
function CorpseManager.RemoveCorpse(corpseId: number)
    if Corpses[corpseId] then
        print(`[CorpseManager] ⚰️ Труп ${corpseId} удален принудительно (воскрешен или убран)` )
        DestroyCorpse(corpseId)
        return true
    end
    return false
end

-- Получить все активные трупы на карте (опционально по владельцу)
function CorpseManager.GetAllCorpses(ownerId: number?)
    local result = {}
    for id, corpse in pairs(Corpses) do
        if ownerId == nil or corpse.OwnerId == ownerId then
            result[id] = corpse
        end
    end
    return result
end

-- Получить количество активных трупов
function CorpseManager.GetCorpseCount(): number
    local count = 0
    for _ in pairs(Corpses) do
        count += 1
    end
    return count
end

-- ============================================
-- ЦИКЛ ОБНОВЛЕНИЯ (проверка просроченных трупов)
-- ============================================

-- Запускаем таймер, который каждую секунду проверяет истекшие трупы
local heartbeatConnection = nil

function CorpseManager.Start()
    if heartbeatConnection then
        return  -- Уже запущен
    end
    
    print(`[CorpseManager] ⏰ Запущен менеджер трупов. Время жизни: ${DECAY_TIME} сек`)
    
    heartbeatConnection = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
        local now = os.time()
        local toRemove = {}
        
        -- Собираем истекшие трупы
        for id, corpse in pairs(Corpses) do
            if now >= corpse.ExpireTime then
                table.insert(toRemove, id)
            end
        end
        
        -- Удаляем их
        for _, id in ipairs(toRemove) do
            DestroyCorpse(id)
        end
        
        if #toRemove > 0 then
            print(`[CorpseManager] 🧹 Удалено ${#toRemove} сгнивших трупов. Осталось: ${CorpseManager.GetCorpseCount()}`)
        end
    end)
end

-- Остановить менеджер (если нужно)
function CorpseManager.Stop()
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
        print("[CorpseManager] ⏹️ Менеджер трупов остановлен")
    end
end

-- Очистить все трупы (при выгрузке карты)
function CorpseManager.ClearAll()
    for id, _ in pairs(Corpses) do
        DestroyCorpse(id)
    end
    print(`[CorpseManager] 🧹 Удалены все трупы`)
end

return CorpseManager