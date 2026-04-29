--!strict
-- src/server/init.server.lua
-- ТОЧКА ВХОДА СЕРВЕРА — ЗАПУСК ВСЕХ СЕРВИСОВ

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local line = string.rep("=", 60)

print(line)
print("🧙‍♂️ NECROMANCER GAME - СЕРВЕР ЗАПУЩЕН")
print(line)

-- Получаем папку с модулями (с ожиданием)
local Modules = ServerStorage:WaitForChild("Modules")

-- Загружаем конфиги
local BaseStats = require(ReplicatedStorage.Constants.BaseStats)
local Buffs = require(ReplicatedStorage.Constants.Buffs)
local Recipes = require(ReplicatedStorage.Constants.Recipes)

print("[Init] 📊 Конфиги загружены")

-- ============================================
-- ЗАПУСК СЕРВИСОВ (по порядку зависимостей)
-- ============================================

-- 1. ArmyService
local ArmyService = require(Modules:WaitForChild("ArmyService"))
ArmyService.Init()

-- 2. CorpseManager
local CorpseManager = require(Modules:WaitForChild("CorpseManager"))
CorpseManager.Start()

-- 3. RitualService
local RitualService = require(Modules:WaitForChild("RitualService"))
RitualService.Init(ArmyService, CorpseManager)

-- 4. UnitFactory
local UnitFactory = require(Modules:WaitForChild("UnitFactory"))
UnitFactory.Init(ArmyService)

-- 5. CraftingService
local CraftingService = require(Modules:WaitForChild("CraftingService"))
CraftingService.Init(ArmyService)

-- 6. AggroService
local AggroService = require(Modules:WaitForChild("AggroService"))
AggroService.Init(ArmyService)

-- 7. TestEnemySpawner (тестовый)
local TestEnemySpawner = require(Modules:WaitForChild("TestEnemySpawner"))
TestEnemySpawner.Init(ArmyService, CorpseManager)

-- ============================================
-- ИНИЦИАЛИЗАЦИЯ ИГРОКОВ
-- ============================================

-- Подписка на новых игроков
Players.PlayerAdded:Connect(function(player)
    AggroService.InitPlayer(player)
    print(`[Init] 👋 ${player.Name} присоединился`)
end)

-- Уже существующие игроки
for _, player in ipairs(Players:GetPlayers()) do
    AggroService.InitPlayer(player)
    print(`[Init] Инициализирована агрессия для ${player.Name}`)
end

print(line)
print("[Init] ✅ ВСЕ СЕРВИСЫ ЗАГРУЖЕНЫ")
print(line)
print("[Init] 🎮 СЕРВЕР ГОТОВ К ПРИЕМУ ИГРОКОВ")
print(line)