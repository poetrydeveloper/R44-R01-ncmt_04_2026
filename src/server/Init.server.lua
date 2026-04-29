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
local Enums = require(ReplicatedStorage.Shared.Enums)

print("[Init] 📊 Конфиги загружены")
print(string.format("   - Юнитов: %d", table.count(BaseStats.Units)))
print(string.format("   - Баффов: %d", table.count(Buffs)))
print(string.format("   - Рецептов: %d (2x), %d (3x), %d (спец)",
    #(Recipes.Merge2 or {}),
    #(Recipes.Merge3 or {}),
    #(Recipes.SpecialRecipes or {})))

-- ============================================
-- ЗАПУСК СЕРВИСОВ (по порядку зависимостей)
-- ============================================

-- 1. ArmyService (ядро: мана, уровни, слоты, стек)
local ArmyService = require(ServerStorage.Modules.ArmyService)
ArmyService.Init()

-- 2. CorpseManager (таймеры гниения)
local CorpseManager = require(ServerStorage.Modules.CorpseManager)
CorpseManager.Start()

-- 3. RitualService (воскрешение трупов)
local RitualService = require(ServerStorage.Modules.RitualService)
RitualService.Init(ArmyService, CorpseManager)

-- 4. UnitFactory (спавн юнитов в мире)
local UnitFactory = require(ServerStorage.Modules.UnitFactory)
UnitFactory.Init(ArmyService)

-- 5. CraftingService (слияние карточек)
local CraftingService = require(ServerStorage.Modules.CraftingService)
CraftingService.Init(ArmyService)

-- 6. AggroService (гнев деревни)
local AggroService = require(ServerStorage.Modules.AggroService)
AggroService.Init(ArmyService)

-- ============================================
-- ИНИЦИАЛИЗАЦИЯ ИГРОКОВ (которые уже в игре)
-- ============================================

for _, player in ipairs(Players:GetPlayers()) do
    AggroService.InitPlayer(player)
    print(`[Init] Инициализирована агрессия для ${player.Name}`)
end

-- Подписка на новых игроков
Players.PlayerAdded:Connect(function(player)
    AggroService.InitPlayer(player)
    print(`[Init] 👋 ${player.Name} присоединился, агрессия инициализирована`)
end)

print("=" :rep(60))
print("[Init] ✅ ВСЕ СЕРВИСЫ ЗАГРУЖЕНЫ:")
print("   1. ArmyService     - мана, уровни, слоты, стек карточек")
print("   2. CorpseManager   - таймеры гниения трупов")
print("   3. RitualService   - воскрешение трупов")
print("   4. UnitFactory     - спавн юнитов, AI, бой")
print("   5. CraftingService - слияние карточек")
print("   6. AggroService    - гнев деревни")
print("=" :rep(60))
print("[Init] 🎮 СЕРВЕР ГОТОВ К ПРИЕМУ ИГРОКОВ")
print("=" :rep(60))

-- Вспомогательная функция
function table.count(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end