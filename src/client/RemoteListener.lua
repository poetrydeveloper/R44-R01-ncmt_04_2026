-- src/client/RemoteListener.lua
-- Прослушивает события от сервера и обновляет UI
-- ВЕРСИЯ 1.1 — ИСПРАВЛЕННЫЕ ПУТИ

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ИСПРАВЛЕНО: правильный путь к UIManager
-- script.Parent = RemoteListener (лежит в папке client)
-- script.Parent.Parent = папка StarterPlayerScripts
-- оттуда берем папку ui и UIManager
local UIManager = require(script.Parent:WaitForChild("ui"):WaitForChild("UIManager"))

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
-- Обработчики событий
-- ============================================

local function OnManaUpdate(currentMana: number, maxMana: number)
    UIManager.UpdateMana(currentMana, maxMana)
    print(`[RemoteListener] 💙 Мана: ${currentMana}/${maxMana}`)
end

local function OnArmyUpdate(maxSlots: number, activeSlots: table)
    UIManager.UpdateSlots(maxSlots, activeSlots)
    local count = 0
    for _ in pairs(activeSlots) do count = count + 1 end
    print(`[RemoteListener] 📦 Армия: ${count}/${maxSlots} слотов`)
end

local function OnSoulStackUpdate(soulStack: table)
    UIManager.UpdateSoulStack(soulStack)
    local count = 0
    for _ in pairs(soulStack) do count = count + 1 end
    print(`[RemoteListener] 📇 Стек карточек: ${count} шт`)
end

local function OnLevelUpdate(level: number, experience: number, nextLevelExp: number)
    UIManager.UpdateLevel(level, experience, nextLevelExp)
    print(`[RemoteListener] 📈 Уровень ${level}: ${experience}/${nextLevelExp} опыта`)
end

local function OnCubeCooldownUpdate(remainingTime: number)
    local canEnter = remainingTime <= 0
    UIManager.UpdateCubeButton(canEnter, remainingTime)
    if remainingTime > 0 then
        print(`[RemoteListener] ⏰ Куб: кулдаун ${remainingTime} сек`)
    end
end

local function OnAggroUpdate(aggroLevel: number, maxAggro: number)
    UIManager.UpdateAggro(aggroLevel, maxAggro)
    print(`[RemoteListener] 😠 Агрессия: ${aggroLevel}/${maxAggro}`)
end

-- ============================================
-- ПОДПИСКА НА СОБЫТИЯ
-- ============================================

local RemoteListener = {}

function RemoteListener.Init()
    print("[RemoteListener] 📡 Инициализация слушателя событий")
    
    local manaEvent = GetRemoteEvent("ArmyRemoteEvents", "UpdateMana")
    if manaEvent then
        manaEvent.OnClientEvent:Connect(OnManaUpdate)
        print("[RemoteListener] ✅ Подписан на UpdateMana")
    else
        warn("[RemoteListener] UpdateMana не найден")
    end
    
    local armyEvent = GetRemoteEvent("ArmyRemoteEvents", "UpdateArmy")
    if armyEvent then
        armyEvent.OnClientEvent:Connect(OnArmyUpdate)
        print("[RemoteListener] ✅ Подписан на UpdateArmy")
    else
        warn("[RemoteListener] UpdateArmy не найден")
    end
    
    local stackEvent = GetRemoteEvent("ArmyRemoteEvents", "UpdateSoulStack")
    if stackEvent then
        stackEvent.OnClientEvent:Connect(OnSoulStackUpdate)
        print("[RemoteListener] ✅ Подписан на UpdateSoulStack")
    else
        warn("[RemoteListener] UpdateSoulStack не найден")
    end
    
    local levelEvent = GetRemoteEvent("ArmyRemoteEvents", "UpdateLevel")
    if levelEvent then
        levelEvent.OnClientEvent:Connect(OnLevelUpdate)
        print("[RemoteListener] ✅ Подписан на UpdateLevel")
    else
        warn("[RemoteListener] UpdateLevel не найден")
    end
    
    local cooldownEvent = GetRemoteEvent("ArmyRemoteEvents", "UpdateCubeCooldown")
    if cooldownEvent then
        cooldownEvent.OnClientEvent:Connect(OnCubeCooldownUpdate)
        print("[RemoteListener] ✅ Подписан на UpdateCubeCooldown")
    else
        warn("[RemoteListener] UpdateCubeCooldown не найден")
    end
    
    local aggroEvent = GetRemoteEvent("ArmyRemoteEvents", "UpdateAggro")
    if aggroEvent then
        aggroEvent.OnClientEvent:Connect(OnAggroUpdate)
        print("[RemoteListener] ✅ Подписан на UpdateAggro")
    else
        warn("[RemoteListener] UpdateAggro не найден")
    end
    
    print("[RemoteListener] ✅ Готов к приему событий")
end

return RemoteListener