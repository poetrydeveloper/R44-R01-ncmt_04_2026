-- src/server/Init.server.lua
-- ТОЧКА ВХОДА СЕРВЕРА — ЗАПУСК ВСЕХ СЕРВИСОВ

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("=" :rep(60))
print("🧙‍♂️ NECROMANCER GAME - СЕРВЕР ЗАПУЩЕН")
print("=" :rep(60))

-- Загружаем конфиги
local BaseStats = require(ReplicatedStorage.Constants.BaseStats)
local Buffs = require(ReplicatedStorage.Constants.Buffs)
local Recipes = require(ReplicatedStorage.Constants.Recipes)

print("[Init] 📊 Конфиги загружены")

-- ============================================
-- ЗАПУСК СЕРВИСОВ (по порядку зависимостей)
-- ============================================

-- 1. ArmyService
local ArmyService = require(ServerStorage.Modules.ArmyService)
ArmyService.Init()

-- 2. CorpseManager
local CorpseManager = require(ServerStorage.Modules.CorpseManager)
CorpseManager.Start()

-- 3. RitualService
local RitualService = require(ServerStorage.Modules.RitualService)
RitualService.Init(ArmyService, CorpseManager)

-- 4. UnitFactory
local UnitFactory = require(ServerStorage.Modules.UnitFactory)
UnitFactory.Init(ArmyService)

-- 5. CraftingService
local CraftingService = require(ServerStorage.Modules.CraftingService)
CraftingService.Init(ArmyService)

-- 6. AggroService
local AggroService = require(ServerStorage.Modules.AggroService)
AggroService.Init(ArmyService)

-- 7. TestEnemySpawner (ТЕСТОВЫЙ! Для проверки)
local TestEnemySpawner = require(ServerStorage.Modules.TestEnemySpawner)
TestEnemySpawner.Init(ArmyService, CorpseManager)

-- ============================================
-- ИНИЦИАЛИЗАЦИЯ ИГРОКОВ
-- ============================================

for _, player in ipairs(Players:GetPlayers()) do
    AggroService.InitPlayer(player)
    print(`[Init] Инициализирована агрессия для ${player.Name}`)
end

Players.PlayerAdded:Connect(function(player)
    AggroService.InitPlayer(player)
    print(`[Init] 👋 ${player.Name} присоединился`)
end)

print("=" :rep(60))
print("[Init] ✅ ВСЕ СЕРВИСЫ ЗАГРУЖЕНЫ:")
print("   1. ArmyService       - мана, уровни, слоты")
print("   2. CorpseManager     - таймеры гниения")
print("   3. RitualService     - воскрешение")
print("   4. UnitFactory       - спавн юнитов")
print("   5. CraftingService   - слияние карточек")
print("   6. AggroService      - гнев деревни")
print("   7. TestEnemySpawner  - тестовые враги")
print("=" :rep(60))
print("[Init] 🎮 СЕРВЕР ГОТОВ К ПРИЕМУ ИГРОКОВ")
print("=" :rep(60))