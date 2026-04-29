-- src/client/InputHandler.lua
-- Обработка кликов по объектам в мире (трупы, могилы, юниты)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetworkBridge = require(script.Parent.NetworkBridge)
local CameraController = require(script.Parent.CameraController)

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- ============================================
-- Определение типов объектов
-- ============================================

local function GetObjectType(obj: Instance): string?
    if not obj then return nil end
    
    local name = obj.Name
    
    -- Трупы (создаются CorpseManager'ом)
    if string.find(name, "Corpse") or (obj.Parent and string.find(obj.Parent.Name, "Corpse")) then
        return "Corpse"
    end
    
    -- Могилы на погосте
    if name == "Grave" or (obj.Parent and obj.Parent.Name == "Grave") then
        return "Grave"
    end
    
    -- Юниты (активные)
    if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
        return "Unit"
    end
    
    return nil
end

-- Получить ID трупа (из названия или атрибута)
local function GetCorpseId(obj: Instance): number?
    -- TODO: Реальная логика получения ID трупа
    print(`[InputHandler] Клик по трупу: ${obj.Name}`)
    return 1  -- Заглушка
end

-- ============================================
-- Обработчики кликов
-- ============================================

local function OnClick(obj: Instance)
    local objectType = GetObjectType(obj)
    
    if not objectType then
        -- Возможно клик по части модели
        if obj.Parent then
            objectType = GetObjectType(obj.Parent)
        end
    end
    
    if not objectType then
        return
    end
    
    print(`[InputHandler] 🖱️ Клик по типу: ${objectType}`)
    
    -- В зависимости от режима камеры
    local cameraMode = CameraController.GetMode()
    
    if objectType == "Corpse" then
        -- Труп можно воскресить ТОЛЬКО в режиме куба
        if cameraMode == "Cube" then
            local corpseId = GetCorpseId(obj)
            if corpseId then
                NetworkBridge.RequestResurrect(corpseId)
            end
        else
            print("[InputHandler] ⚠️ Нельзя воскрешать трупы вне куба")
            -- TODO: Показать уведомление игроку
        end
    end
    
    if objectType == "Grave" then
        -- Могилы можно открывать только в режиме куба на погосте
        if cameraMode == "Cube" then
            print("[InputHandler] 🪦 Клик по могиле — открыть")
            -- TODO: Открыть могилу (рандомная карточка)
        else
            print("[InputHandler] ⚠️ Нельзя открывать могилы вне куба")
        end
    end
    
    if objectType == "Unit" then
        -- Управление юнитами только в режиме куба
        if cameraMode == "Cube" then
            print("[InputHandler] ⚔️ Клик по юниту — выбрать")
            -- TODO: Выбрать юнита для управления
        else
            -- В режиме тела можно атаковать врагов
            print("[InputHandler] ⚔️ Атака врага")
            -- TODO: Атака от лица некроманта
        end
    end
end

-- ============================================
-- Инициализация
-- ============================================

local InputHandler = {}

function InputHandler.Init()
    print("[InputHandler] 🖱️ Инициализация обработчика ввода")
    
    mouse.Button1Down:Connect(function()
        local target = mouse.Target
        if target then
            OnClick(target)
        end
    end)
    
    print("[InputHandler] ✅ Готов")
end

return InputHandler