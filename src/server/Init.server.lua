-- src/server/Init.server.lua
-- ТОЧКА ВХОДА СЕРВЕРА
-- Запускает все сервисы в правильном порядке

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("=" :rep(60))
print("🧙‍♂️ NECROMANCER GAME - СЕРВЕР ЗАПУЩЕН")
print("=" :rep(60))

-- Загружаем конфиги для отладки
local BaseStats = require(ReplicatedStorage.Constants.BaseStats)
local Buffs = require(ReplicatedStorage.Constants.Buffs)
local Recipes = require(ReplicatedStorage.Constants.Recipes)
local Enums = require(ReplicatedStorage.Shared.Enums)

print("[Init] 📊 Загружены конфиги:")
print(string.format("   - BaseStats: %d юнитов, прогрессия до %d уровня", 
    table.count(BaseStats.Units), BaseStats.Progression.MaxLevel))
print(string.format("   - Buffs: %d типов", table.count(Buffs)))
print(string.format("   - Recipes: %d рецептов (2x) + %d рецептов (3x) + %d спец.рецептов",
    #Recipes.Merge2, #Recipes.Merge3, #Recipes.SpecialRecipes))

-- Загружаем и инициализируем сервисы (в порядке зависимостей)

-- 1. ArmyService (управление армией, маной, прогрессией)
local ArmyService = require(ServerStorage.Modules.ArmyService)
ArmyService.Init()

-- 2. TODO: CorpseManager (таймеры гниения трупов)
-- local CorpseManager = require(ServerStorage.Modules.CorpseManager)
-- CorpseManager.Init()

-- 3. TODO: RitualService (воскрешение)
-- local RitualService = require(ServerStorage.Modules.RitualService)
-- RitualService.Init()

-- 4. TODO: CraftingService (слияние могил)
-- local CraftingService = require(ServerStorage.Modules.CraftingService)
-- CraftingService.Init()

-- 5. TODO: AggroService (гнев деревни)
-- local AggroService = require(ServerStorage.Modules.AggroService)
-- AggroService.Init()

-- 6. TODO: StorageService (склепы)
-- local StorageService = require(ServerStorage.Modules.StorageService)
-- StorageService.Init()

-- 7. TODO: UnitFactory (спавн юнитов)
-- local UnitFactory = require(ServerStorage.Modules.UnitFactory)
-- UnitFactory.Init()

print("=" :rep(60))
print("[Init] ✅ Все сервисы инициализированы")
print("[Init] 🎮 Сервер готов к приему игроков")
print("=" :rep(60))

-- Вспомогательная функция для подсчета полей в таблице
function table.count(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end