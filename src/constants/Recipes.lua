-- src/constants/Recipes.lua
-- Рецепты слияния могил/карточек

local Recipes = {
    -- ============================================
    -- Слияние 2 могил → случайный юнит следующего тира
    -- ============================================
    Merge2 = {
        -- (Tier1 + Tier1) → Tier2
        {
            InputTiers = { 1, 1 },
            OutputTier = 2,
            OutputPool = {    -- Из каких юнитов выбирать
                "DeathKnight",
                "SkeletonWarlock",
            },
        },
        
        -- (Tier2 + Tier2) → Tier3
        {
            InputTiers = { 2, 2 },
            OutputTier = 3,
            OutputPool = {
                "IceGolem",
                "ShadowPriest",
            },
        },
        
        -- (Tier3 + Tier3) → Tier4
        {
            InputTiers = { 3, 3 },
            OutputTier = 4,
            OutputPool = {
                "Lich",
                "VampireLord",
            },
        },
        
        -- (Tier4 + Tier4) → Tier5
        {
            InputTiers = { 4, 4 },
            OutputTier = 5,
            OutputPool = {
                "SkeletonDragon",
                "Dullahan",
            },
        },
    },
    
    -- ============================================
    -- Слияние 3 могил → гарантированный конкретный юнит
    -- ============================================
    Merge3 = {
        -- 3×Tier1 → конкретный Tier2
        {
            InputTiers = { 1, 1, 1 },
            OutputTier = 2,
            OutputUnit = "DeathKnight",  -- Гарантированно
        },
        
        -- 3×Tier2 → конкретный Tier3
        {
            InputTiers = { 2, 2, 2 },
            OutputTier = 3,
            OutputUnit = "IceGolem",
        },
        
        -- 3×Tier3 → конкретный Tier4
        {
            InputTiers = { 3, 3, 3 },
            OutputTier = 4,
            OutputUnit = "Lich",
        },
        
        -- 3×Tier4 → конкретный Tier5
        {
            InputTiers = { 4, 4, 4 },
            OutputTier = 5,
            OutputUnit = "SkeletonDragon",
        },
    },
    
    -- ============================================
    -- Специальные рецепты (уникальные)
    -- ============================================
    SpecialRecipes = {
        -- 2×Ледяной голем + 1×Лич → Ледяной Лич (уникальный)
        {
            InputUnits = { "IceGolem", "IceGolem", "Lich" },
            OutputUnit = "FrostLich",
            OutputTier = 5,
            Description = "Союз льда и магии",
        },
        
        -- 1×Рыцарь смерти + 2×Скелет-лучник → Темный стрелок
        {
            InputUnits = { "DeathKnight", "SkeletonArcher", "SkeletonArcher" },
            OutputUnit = "DarkRanger",
            OutputTier = 4,
            Description = "Проклятый лучник",
        },
    },
}

return Recipes