-- src/server-modules/CraftingService.lua
-- Слияние могил / карточек (по Recipes.lua)
-- Позволяет объединять 2-3 слабых юнита в одного сильного

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local BaseStats = require(ReplicatedStorage.Constants.BaseStats)
local Recipes = require(ReplicatedStorage.Constants.Recipes)
local Enums = require(ReplicatedStorage.Shared.Enums)

-- Сервисы (заполняются при Init)
local ArmyService = nil

-- ============================================
-- RemoteEvent для получения запросов от клиента
-- ============================================
local RemoteEvents = Instance.new("Folder")
RemoteEvents.Name = "CraftingRemoteEvents"
RemoteEvents.Parent = ReplicatedStorage

local RequestMerge = Instance.new("RemoteEvent")
RequestMerge.Name = "RequestMerge"
RequestMerge.Parent = RemoteEvents

local RequestEnhance = Instance.new("RemoteEvent")
RequestEnhance.Name = "RequestEnhance"
RequestEnhance.Parent = RemoteEvents

-- ============================================
-- Вспомогательные функции
-- ============================================

-- Получить Tier юнита по его UnitTypeId
local function GetUnitTier(unitTypeId: string)
    local unitData = BaseStats.Units[unitTypeId]
    if not unitData then
        return 1
    end
    return unitData.Tier or 1
end

-- Создать новую карточку из рецепта
local function CreateCardFromRecipe(unitTypeId: string, isMerged: boolean)
    local cardId = `merged_card_{os.time()}_{math.random(1000, 9999)}`
    
    return {
        CardId = cardId,
        UnitTypeId = unitTypeId,
        Modifiers = {},
        IsMerged = isMerged,
    }
end

-- Проверить, подходят ли карточки для рецепта (2x)
local function CheckMerge2Recipe(cards)
    if #cards ~= 2 then return nil end
    
    local tier1 = GetUnitTier(cards[1].UnitTypeId)
    local tier2 = GetUnitTier(cards[2].UnitTypeId)
    
    for _, recipe in ipairs(Recipes.Merge2) do
        if recipe.InputTiers[1] == tier1 and recipe.InputTiers[2] == tier2 then
            local outputIndex = math.random(1, #recipe.OutputPool)
            return recipe.OutputPool[outputIndex]
        end
    end
    
    return nil
end

-- Проверить, подходят ли карточки для рецепта (3x)
local function CheckMerge3Recipe(cards)
    if #cards ~= 3 then return nil end
    
    local tier1 = GetUnitTier(cards[1].UnitTypeId)
    local tier2 = GetUnitTier(cards[2].UnitTypeId)
    local tier3 = GetUnitTier(cards[3].UnitTypeId)
    
    for _, recipe in ipairs(Recipes.Merge3) do
        if recipe.InputTiers[1] == tier1 and 
           recipe.InputTiers[2] == tier2 and 
           recipe.InputTiers[3] == tier3 then
            return recipe.OutputUnit
        end
    end
    
    return nil
end

-- Проверить специальный рецепт
local function CheckSpecialRecipe(cards)
    if #cards < 2 or #cards > 3 then return nil end
    
    local unitIds = {}
    for _, card in ipairs(cards) do
        table.insert(unitIds, card.UnitTypeId)
    end
    table.sort(unitIds)
    
    for _, recipe in ipairs(Recipes.SpecialRecipes) do
        local recipeIds = {}
        for _, id in ipairs(recipe.InputUnits) do
            table.insert(recipeIds, id)
        end
        table.sort(recipeIds)
        
        local match = true
        if #unitIds ~= #recipeIds then
            match = false
        else
            for i = 1, #unitIds do
                if unitIds[i] ~= recipeIds[i] then
                    match = false
                    break
                end
            end
        end
        
        if match then
            print(`[CraftingService] 🎯 Найден специальный рецепт: ${recipe.Description} → ${recipe.OutputUnit}`)
            return recipe.OutputUnit
        end
    end
    
    return nil
end

-- ============================================
-- ОСНОВНЫЕ ФУНКЦИИ (API)
-- ============================================

local CraftingService = {}

function CraftingService.MergeCards(player, cardIds)
    local playerData = ArmyService.GetPlayerData(player)
    if not playerData then
        return false, "Ошибка загрузки данных игрока"
    end
    
    if #cardIds < 2 or #cardIds > 3 then
        return false, "Для слияния нужно 2 или 3 карточки"
    end
    
    local cards = {}
    for _, cardId in ipairs(cardIds) do
        local card = ArmyService.GetCardFromStack(player, cardId)
        if not card then
            return false, `Карточка ${cardId} не найдена в стеке`
        end
        table.insert(cards, card)
    end
    
    local outputUnitType = CheckSpecialRecipe(cards)
    
    if not outputUnitType and #cards == 3 then
        outputUnitType = CheckMerge3Recipe(cards)
    end
    
    if not outputUnitType and #cards == 2 then
        outputUnitType = CheckMerge2Recipe(cards)
    end
    
    if not outputUnitType then
        return false, "Нет подходящего рецепта для этих карточек"
    end
    
    local mergeCost = BaseStats.Mana.ActionCost.Merge
    if playerData.Mana.Current < mergeCost then
        return false, `Недостаточно маны (нужно ${mergeCost}, есть ${playerData.Mana.Current})`
    end
    
    local success = ArmyService.SpendMana(player, mergeCost, Enums.CubeAction.Merge)
    if not success then
        return false, "Не удалось списать ману"
    end
    
    for _, cardId in ipairs(cardIds) do
        ArmyService.RemoveCardFromStack(player, cardId)
    end
    
    local newCard = CreateCardFromRecipe(outputUnitType, true)
    ArmyService.AddCardToStack(player, newCard)
    
    playerData.TotalMerges = (playerData.TotalMerges or 0) + 1
    
    print(`[CraftingService] 🔮 ${player.Name} слил ${#cards} карточек → ${outputUnitType}`)
    
    return true, newCard
end

function CraftingService.EnhanceCard(player, cardId, buffType)
    local playerData = ArmyService.GetPlayerData(player)
    if not playerData then
        return false, "Ошибка загрузки данных игрока"
    end
    
    local card = ArmyService.GetCardFromStack(player, cardId)
    if not card then
        return false, "Карточка не найдена в стеке"
    end
    
    local Buffs = require(ReplicatedStorage.Constants.Buffs)
    local buffData = Buffs[buffType]
    if not buffData then
        return false, "Неизвестный тип усиления"
    end
    
    if card.Modifiers and card.Modifiers[buffType] then
        return false, "У карточки уже есть это усиление"
    end
    
    local enhanceCost = buffData.Cost or BaseStats.Mana.ActionCost.Enhance
    if playerData.Mana.Current < enhanceCost then
        return false, `Недостаточно маны (нужно ${enhanceCost}, есть ${playerData.Mana.Current})`
    end
    
    local success = ArmyService.SpendMana(player, enhanceCost, Enums.CubeAction.Enhance)
    if not success then
        return false, "Не удалось списать ману"
    end
    
    card.Modifiers = card.Modifiers or {}
    card.Modifiers[buffType] = {
        Value = buffData.Value,
        Duration = buffData.Duration or -1,
    }
    
    print(`[CraftingService] ⚡ ${player.Name} усилил карточку ${card.UnitTypeId} баффом ${buffType}`)
    
    return true, "Усиление добавлено"
end

function CraftingService.GetAvailableRecipes(player)
    local playerData = ArmyService.GetPlayerData(player)
    if not playerData then return {} end
    
    local recipes = {
        merge2 = {},
        merge3 = {},
        special = {},
    }
    
    for _, recipe in ipairs(Recipes.Merge2 or {}) do
        table.insert(recipes.merge2, recipe)
    end
    
    for _, recipe in ipairs(Recipes.Merge3 or {}) do
        table.insert(recipes.merge3, recipe)
    end
    
    for _, recipe in ipairs(Recipes.SpecialRecipes or {}) do
        table.insert(recipes.special, recipe)
    end
    
    return recipes
end

-- ============================================
-- ОБРАБОТЧИКИ REMOTES
-- ============================================

local function SetupRemotes()
    RequestMerge.OnServerEvent:Connect(function(player, cardIds)
        if type(cardIds) ~= "table" or #cardIds < 2 then
            print(`[CraftingService] ⚠️ ${player.Name} отправил некорректный запрос на слияние`)
            return
        end
        
        local success, result = CraftingService.MergeCards(player, cardIds)
        
        if success then
            print(`[CraftingService] ✅ ${player.Name} успешно слил карточки`)
        else
            print(`[CraftingService] ❌ ${player.Name} не смог слить карточки: ${result}`)
        end
    end)
    
    RequestEnhance.OnServerEvent:Connect(function(player, cardId, buffType)
        if type(cardId) ~= "string" or type(buffType) ~= "string" then
            print(`[CraftingService] ⚠️ ${player.Name} отправил некорректный запрос на усиление`)
            return
        end
        
        local success, result = CraftingService.EnhanceCard(player, cardId, buffType)
        
        if success then
            print(`[CraftingService] ✅ ${player.Name} успешно усилил карточку ${cardId}`)
        else
            print(`[CraftingService] ❌ ${player.Name} не смог усилить карточку: ${result}`)
        end
    end)
    
    print("[CraftingService] 📡 RemoteEvents настроены")
end

-- ============================================
-- ИНИЦИАЛИЗАЦИЯ
-- ============================================

function CraftingService.Init(armyService)
    ArmyService = armyService
    
    if not ArmyService then
        error("[CraftingService] ❌ Не удалось инициализировать: ArmyService отсутствует")
    end
    
    SetupRemotes()
    
    print("[CraftingService] ========== ИНИЦИАЛИЗАЦИЯ ==========")
    print("   - Зависимости: ArmyService ✅")
    print("   - Рецептов 2x:", #(Recipes.Merge2 or {}))
    print("   - Рецептов 3x:", #(Recipes.Merge3 or {}))
    print("   - Специальных рецептов:", #(Recipes.SpecialRecipes or {}))
    print("   - Стоимость слияния:", BaseStats.Mana.ActionCost.Merge, "маны")
    print("[CraftingService] ✅ Готов к работе")
end

return CraftingService