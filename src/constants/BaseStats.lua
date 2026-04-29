-- src/constants/BaseStats.lua
-- Статические данные: юниты, прогрессия, баланс маны

local BaseStats = {
    -- ============================================
    -- ПРОГРЕССИЯ НЕКРОМАНТА (уровень → слоты → макс.мана)
    -- ============================================
    Progression = {
        MaxLevel = 50,
        
        -- [уровень] = { slots = X, maxMana = Y }
        Levels = {
            [1]  = { slots = 3,  maxMana = 50 },
            [5]  = { slots = 5,  maxMana = 80 },
            [10] = { slots = 6,  maxMana = 120 },
            [15] = { slots = 8,  maxMana = 150 },
            [20] = { slots = 10, maxMana = 200 },
            [30] = { slots = 12, maxMana = 300 },
            [40] = { slots = 16, maxMana = 400 },
            [50] = { slots = 20, maxMana = 500 },
        },
        
        -- Опыт для достижения уровня
        ExpToLevel = {
            [1] = 0,
            [2] = 100,
            [3] = 250,
            [4] = 450,
            [5] = 700,
            [10] = 3000,
            [20] = 12000,
            [30] = 30000,
            [40] = 60000,
            [50] = 100000,
        },
    },
    
    -- ============================================
    -- МАНА
    -- ============================================
    Mana = {
        CubeEntryCost = 50,          -- Вход в куб
        RegenBody = 5,               -- +5/сек в режиме тела
        RegenCube = 2,               -- +2/сек в режиме куба
        CubeCooldown = 10,           -- 10 секунд после выхода
        
        -- Награда за убийства (Некромант в теле)
        KillRewardNecromancer = {
            Normal = 20,
            Elite = 50,
            Boss = 150,
        },
        
        -- Награда за убийства (Юниты в кубе)
        KillRewardUnit = {
            Normal = 3,
            Elite = 8,
            Boss = 25,
        },
        
        -- Стоимость действий в кубе
        ActionCost = {
            Resurrect = 10,          -- Труп → карточка
            MoveToSlot = 5,          -- Карточка → слот
            Revive = 15,             -- Слот → активный юнит
            Merge = 20,              -- Слияние
            Enhance = 10,            -- Усиление (базовая цена)
            Order = 1,               -- Приказ юниту
        },
    },
    
    -- ============================================
    -- ЮНИТЫ (статистика)
    -- ============================================
    Units = {
        -- Tier 1 (Обычные)
        SkeletonWarrior = {
            Id = "SkeletonWarrior",
            Name = "Скелет-воин",
            Tier = 1,
            BaseHealth = 50,
            BaseDamage = 10,
            AttackRange = 8,
            AttackType = "Melee",
            SoulCost = 10,
            ModelId = "rbxassetid://待定",
        },
        
        Zombie = {
            Id = "Zombie",
            Name = "Зомби",
            Tier = 1,
            BaseHealth = 80,
            BaseDamage = 8,
            AttackRange = 6,
            AttackType = "Melee",
            SoulCost = 8,
            ModelId = "rbxassetid://待定",
        },
        
        SkeletonArcher = {
            Id = "SkeletonArcher",
            Name = "Скелет-лучник",
            Tier = 1,
            BaseHealth = 40,
            BaseDamage = 12,
            AttackRange = 40,
            AttackType = "Ranged",
            SoulCost = 12,
            ModelId = "rbxassetid://待定",
        },
        
        -- Tier 2 (Средние)
        DeathKnight = {
            Id = "DeathKnight",
            Name = "Рыцарь смерти",
            Tier = 2,
            BaseHealth = 120,
            BaseDamage = 25,
            AttackRange = 8,
            AttackType = "Melee",
            SoulCost = 20,
            ModelId = "rbxassetid://待定",
        },
        
        -- Tier 3 (Сильные)
        IceGolem = {
            Id = "IceGolem",
            Name = "Ледяной голем",
            Tier = 3,
            BaseHealth = 250,
            BaseDamage = 35,
            AttackRange = 12,
            AttackType = "Melee",
            SoulCost = 35,
            ModelId = "rbxassetid://待定",
        },
        
        -- Tier 4 (Элитные)
        Lich = {
            Id = "Lich",
            Name = "Лич",
            Tier = 4,
            BaseHealth = 180,
            BaseDamage = 40,
            AttackRange = 50,
            AttackType = "Magic",
            SoulCost = 50,
            ModelId = "rbxassetid://待定",
        },
        
        -- Tier 5 (Легендарные)
        SkeletonDragon = {
            Id = "SkeletonDragon",
            Name = "Костяной дракон",
            Tier = 5,
            BaseHealth = 500,
            BaseDamage = 60,
            AttackRange = 20,
            AttackType = "Magic",
            SoulCost = 80,
            ModelId = "rbxassetid://待定",
        },
    },
    
    -- ============================================
    -- ПОГОСТ
    -- ============================================
    Graveyard = {
        GravesCount = 12,            -- Могил на погосте
        CorpseDecayTime = 45,        -- Труп исчезает через 45 секунд
        ResurrectAnimationTime = 2,  -- Секунд на анимацию воскрешения
    },
    
    -- ============================================
    -- КУБ
    -- ============================================
    Cube = {
        BaseHealth = 200,            -- Прочность куба
        DamageReduction = 0.5,       -- 50% урона в кубе
    },
    
    -- ============================================
    -- АГРЕССИЯ
    -- ============================================
    Aggro = {
        PerAttack = 5,               -- +5 за нападение на деревню
        PerKill = 1,                 -- +1 за убийство жителя
        DecayPerSecond = 0.1,        -- Падает на 0.1/сек
        MaxAggro = 100,
        AttackThreshold = 70,        -- При 70+ деревня атакует
    },
}

return BaseStats