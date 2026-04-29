-- src/client/NetworkBridge.lua
-- Клиентский мост для отправки запросов на сервер
-- ВЕРСИЯ 2.0 — С ПОДДЕРЖКОЙ ARMY REMOTEEVENTS

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ============================================
-- Получение RemoteEvent'ов
-- ============================================

local function GetRemoteEvent(folderName: string, eventName: string): RemoteEvent?
    local folder = ReplicatedStorage:FindFirstChild(folderName)
    if folder then
        local event = folder:FindFirstChild(eventName)
        if event then
            return event
        end
    end
    return nil
end

-- ============================================
-- Отправка запросов на сервер
-- ============================================

local NetworkBridge = {}

-- ========== УПРАВЛЕНИЕ КУБОМ ==========

function NetworkBridge.RequestEnterCube()
    local remote = GetRemoteEvent("ArmyRemoteEvents", "RequestEnterCube")
    if remote then
        remote:FireServer()
        print("[NetworkBridge] 🧊 Запрос на вход в куб отправлен")
    else
        warn("[NetworkBridge] RequestEnterCube не найден")
    end
end

function NetworkBridge.RequestExitCube(isForced: boolean)
    local remote = GetRemoteEvent("ArmyRemoteEvents", "RequestExitCube")
    if remote then
        remote:FireServer(isForced or false)
        print("[NetworkBridge] 🧊 Запрос на выход из куба отправлен")
    else
        warn("[NetworkBridge] RequestExitCube не найден")
    end
end

-- ========== ВОСКРЕШЕНИЕ ==========

function NetworkBridge.RequestResurrect(corpseId: number)
    local remote = GetRemoteEvent("RitualRemoteEvents", "RequestResurrect")
    if remote then
        remote:FireServer(corpseId)
        print(`[NetworkBridge] 💀 Запрос на воскрешение трупа ${corpseId} отправлен`)
    else
        warn("[NetworkBridge] RequestResurrect не найден")
    end
end

-- ========== КРАФТ (СЛИЯНИЕ) ==========

function NetworkBridge.RequestMerge(cardIds: { string })
    local remote = GetRemoteEvent("CraftingRemoteEvents", "RequestMerge")
    if remote then
        remote:FireServer(cardIds)
        print(`[NetworkBridge] 🔮 Запрос на слияние ${#cardIds} карточек отправлен`)
    else
        warn("[NetworkBridge] RequestMerge не найден")
    end
end

function NetworkBridge.RequestEnhance(cardId: string, buffType: string)
    local remote = GetRemoteEvent("CraftingRemoteEvents", "RequestEnhance")
    if remote then
        remote:FireServer(cardId, buffType)
        print(`[NetworkBridge] ⚡ Запрос на усиление карточки ${cardId} отправлен`)
    else
        warn("[NetworkBridge] RequestEnhance не найден")
    end
end

-- ========== УПРАВЛЕНИЕ ЮНИТАМИ ==========

function NetworkBridge.RequestOrder(unitId: string, targetPosition: Vector3, targetUnitId: string?)
    local remote = GetRemoteEvent("ArmyRemoteEvents", "RequestOrder")
    if remote then
        remote:FireServer(unitId, targetPosition, targetUnitId)
        print(`[NetworkBridge] ⚔️ Приказ юниту ${unitId} отправлен`)
    else
        warn("[NetworkBridge] RequestOrder не найден")
    end
end

-- ============================================
-- ИНИЦИАЛИЗАЦИЯ
-- ============================================

function NetworkBridge.Init()
    print("[NetworkBridge] 🔌 Инициализация сетевого моста")
    
    -- Проверяем наличие всех RemoteEvent'ов
    local events = {
        { folder = "ArmyRemoteEvents", name = "RequestEnterCube" },
        { folder = "ArmyRemoteEvents", name = "RequestExitCube" },
        { folder = "RitualRemoteEvents", name = "RequestResurrect" },
        { folder = "CraftingRemoteEvents", name = "RequestMerge" },
        { folder = "CraftingRemoteEvents", name = "RequestEnhance" },
    }
    
    for _, event in ipairs(events) do
        local remote = GetRemoteEvent(event.folder, event.name)
        if not remote then
            warn(`[NetworkBridge] ⚠️ ${event.folder}.${event.name} не найден`)
        end
    end
    
    print("[NetworkBridge] ✅ Готов к отправке запросов")
end

return NetworkBridge