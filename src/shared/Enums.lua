-- src/shared/Enums.lua
-- АКТУАЛЬНАЯ ВЕРСИЯ от 29 апреля 2026

local Enums = {
    -- ============================================
    -- Режимы игры
    -- ============================================
    GameMode = {
        Body = "Body",     -- Режим тела (управляем некромантом)
        Cube = "Cube",     -- Режим куба (управляем армией)
    },
    
    -- ============================================
    -- Редкость юнитов (Tier)
    -- ============================================
    UnitTier = {
        Tier1 = 1,   -- Обычный (скелет, зомби)
        Tier2 = 2,   -- Средний (рыцарь, лучник)
        Tier3 = 3,   -- Сильный (огненный голем)
        Tier4 = 4,   -- Элитный (рыцарь смерти)
        Tier5 = 5,   -- Легендарный (дракон-скелет)
    },
    
    -- ============================================
    -- Тип атаки
    -- ============================================
    AttackType = {
        Melee = "Melee",   -- Ближний бой
        Ranged = "Ranged", -- Дальний бой
        Magic = "Magic",   -- Магия
    },
    
    -- ============================================
    -- Типы баффов (усилений карточек)
    -- ============================================
    BuffType = {
        IceTouch = "IceTouch",           -- Ледяное прикосновение (+урон, замедление)
        PoisonAura = "PoisonAura",       -- Ядовитый покров (облако яда)
        Invisibility = "Invisibility",   -- Невидимость на расстоянии
        ChainDarkness = "ChainDarkness", -- Цепь тьмы (дальняя атака)
        SpeedBoost = "SpeedBoost",       -- Скорость
        ArmorBoost = "ArmorBoost",       -- Броня
    },
    
    -- ============================================
    -- Источники маны
    -- ============================================
    ManaSource = {
        PassiveBody = "PassiveBody",     -- Пассивная в теле (+5/сек)
        PassiveCube = "PassiveCube",     -- Пассивная в кубе (+2/сек)
        KillByNecromancer = "KillByNecromancer",   -- Убийство некромантом (+20/50/150)
        KillByUnit = "KillByUnit",       -- Убийство юнитом (+3/8/25)
        QuestReward = "QuestReward",     -- Награда за квест
    },
    
    -- ============================================
    -- Действия в кубе (тратят ману)
    -- ============================================
    CubeAction = {
        Enter = "Enter",                 -- Вход в куб (-50)
        Resurrect = "Resurrect",         -- Воскресить труп → карточка (-10)
        MoveToSlot = "MoveToSlot",       -- Переместить карточку в слот (-5)
        Revive = "Revive",               -- Оживить юнита из слота (-15)
        Merge = "Merge",                 -- Слияние могил / карточек (-20)
        Enhance = "Enhance",             -- Усиление карточки (-10-25)
        Order = "Order",                 -- Отдать приказ юниту (-1-2)
    },
    
    -- ============================================
    -- Типы врагов
    -- ============================================
    EnemyType = {
        Wild = "Wild",           -- Дикий зверь
        VillageMilitia = "VillageMilitia",  -- Ополчение деревни
        CityGuard = "CityGuard",            -- Городская стража
        Elite = "Elite",                    -- Элитный враг
        Boss = "Boss",                      -- Босс
    },
    
    -- ============================================
    -- События (для Remotes)
    -- ============================================
    RemoteEvent = {
        -- Клиент → Сервер
        EnterCube = "EnterCube",
        ExitCube = "ExitCube",
        ResurrectCorpse = "ResurrectCorpse",
        MergeGraves = "MergeGraves",
        EnhanceCard = "EnhanceCard",
        OrderUnit = "OrderUnit",
        
        -- Сервер → Клиент
        UpdateMana = "UpdateMana",
        UpdateCooldown = "UpdateCooldown",
        UpdateArmy = "UpdateArmy",
        UpdateSoulStack = "UpdateSoulStack",
        UpdateAggro = "UpdateAggro",
        CombatResult = "CombatResult",
    },
}

return Enums