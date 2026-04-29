-- src/ui/UIManager.lua
-- Главный менеджер интерфейса (упрощенная версия)
-- Компоненты вынесены в папку components/

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Подключаем UI компоненты
local ManaBar = require(script.Parent.components.ManaBar)
local LevelPanel = require(script.Parent.components.LevelPanel)
local CubeButton = require(script.Parent.components.CubeButton)
local CraftingButton = require(script.Parent.components.CraftingButton)
local ToggleStackButton = require(script.Parent.components.ToggleStackButton)
local HotkeyText = require(script.Parent.components.HotkeyText)

-- Подключаем основные UI модули
local SlotPanel = require(script.Parent.SlotPanel)
local SoulStackUI = require(script.Parent.SoulStackUI)
local CraftingMenu = require(script.Parent.CraftingMenu)
local AggroBar = require(script.Parent.AggroBar)

-- Подключаем NetworkBridge для отправки запросов
local NetworkBridge = require(script.Parent.Parent.client.NetworkBridge)

-- ============================================
-- ScreenGui
-- ============================================

local screenGui = nil

local function CreateScreenGui()
    if screenGui then return screenGui end
    
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NecromancerUI"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    return screenGui
end

-- ============================================
-- Компоненты (глобальные ссылки)
-- ============================================

local Components = {
    ManaBar = nil,
    LevelPanel = nil,
    CubeBtn = nil,
}

-- ============================================
-- ПУБЛИЧНЫЕ ФУНКЦИИ
-- ============================================

local UIManager = {}

function UIManager.UpdateMana(current: number, max: number)
    if Components.ManaBar then
        Components.ManaBar.Update(current, max)
    end
end

function UIManager.UpdateCubeButton(canEnter: boolean, cooldownRemaining: number)
    if Components.CubeBtn then
        Components.CubeBtn.Update(canEnter, cooldownRemaining)
    end
end

function UIManager.UpdateLevel(level: number, experience: number, nextLevelExp: number)
    if Components.LevelPanel then
        Components.LevelPanel.Update(level, experience, nextLevelExp)
    end
end

function UIManager.UpdateAggro(aggroLevel: number, maxAggro: number)
    AggroBar.Update(aggroLevel, maxAggro or 100)
end

function UIManager.UpdateSlots(maxSlots: number, activeSlots: table)
    SlotPanel.Update(maxSlots, activeSlots)
end

function UIManager.UpdateSoulStack(soulStack: table)
    SoulStackUI.UpdateSoulStack(soulStack)
end

function UIManager.ShowNotification(text: string, duration: number)
    print(`[UIManager] 🔔 ${text}`)
end

function UIManager.ShowLevelUp(level: number)
    UIManager.ShowNotification(`🎉 ПОВЫШЕНИЕ УРОВНЯ! Вы достигли ${level} уровня 🎉`, 3)
end

-- ============================================
-- ИНИЦИАЛИЗАЦИЯ
-- ============================================

function UIManager.Init()
    print("[UIManager] 🎨 Инициализация интерфейса")
    
    -- Создаем основной Gui
    local gui = CreateScreenGui()
    
    -- Создаем компоненты
    Components.ManaBar = ManaBar.New(gui)
    Components.LevelPanel = LevelPanel.New(gui)
    Components.CubeBtn = CubeButton.New(gui, function()
        if Components.CubeBtn.IsActive() then
            NetworkBridge.RequestEnterCube()
        end
    end)
    
    CraftingButton.New(gui, function()
        CraftingMenu.Toggle()
    end)
    
    ToggleStackButton.New(gui, function(isVisible)
        SoulStackUI.SetVisible(isVisible)
    end)
    
    HotkeyText.New(gui)
    
    -- Инициализируем компоненты
    SlotPanel.Init()
    AggroBar.Init()
    CraftingMenu.Init()
    SoulStackUI.Init()
    
    -- Начальные значения
    UIManager.UpdateMana(50, 50)
    UIManager.UpdateCubeButton(false, 0)
    UIManager.UpdateLevel(1, 0, 100)
    UIManager.UpdateAggro(0, 100)
    UIManager.UpdateSlots(3, {})
    UIManager.UpdateSoulStack({})
    
    print("[UIManager] ✅ Интерфейс создан")
end

return UIManager