-- src/shared/Types.lua
-- Концепция: Некромант с двумя режимами (Тело + Куб), мана как ресурс, прогрессия до 50 уровня

-- ============================================
-- ТИП: UnitStats (статические характеристики типа юнита)
-- ============================================
export type UnitStats = {
    Id: string,                    -- Уникальный ID типа (например "SkeletonWarrior")
    Name: string,                  -- Отображаемое имя
    Tier: number,                  -- 1★ до 5★ (влияет на силу)
    BaseHealth: number,            -- Максимальное здоровье
    BaseDamage: number,            -- Базовый урон
    AttackRange: number,           -- Дальность атаки (студиевые единицы)
    AttackType: "Melee" | "Ranged" | "Magic",
    ModelId: string,               -- Asset ID модели в Roblox
    SoulValue: number,             -- Ценность в "душах" (для баланса мержа)
}

-- ============================================
-- ТИП: ActiveUnit (юнит в активном слоте)
-- ============================================
export type ActiveUnit = {
    InstanceId: string,            -- Уникальный ID этого экземпляра
    UnitTypeId: string,            -- Ссылка на UnitStats.Id
    CurrentHealth: number,         -- Текущее здоровье
    Buffs: { [string]: BuffData }, -- Активные баффы
    IsAlive: boolean,              -- Жив ли сейчас
    SlotIndex: number,             -- В каком слоте (1-20)
}

-- ============================================
-- ТИП: Card (карточка в стеке душ)
-- ============================================
export type Card = {
    CardId: string,                -- Уникальный ID карточки
    UnitTypeId: string,            -- Какой юнит можно оживить
    Modifiers: { [string]: any },  -- Усиления (лед, яд, невидимость и т.д.)
    IsMerged: boolean,             -- Получен ли через мерж?
}

-- ============================================
-- ТИП: BuffData
-- ============================================
export type BuffData = {
    BuffType: string,              -- Из Enums.BuffType
    Value: number,                 -- Сила эффекта
    RemainingTime: number,         -- Оставшееся время (-1 = постоянно)
}

-- ============================================
-- ТИП: ManaData (вся информация о мане игрока)
-- ============================================
export type ManaData = {
    Current: number,               -- Текущая мана (0 - MaxMana)
    Max: number,                   -- Максимум маны (зависит от уровня)
    RegenBody: number,             -- Регенерация в режиме тела (+5/сек)
    RegenCube: number,             -- Регенерация в режиме куба (+2/сек)
}

-- ============================================
-- ТИП: CubModeData (состояние куба)
-- ============================================
export type CubModeData = {
    IsActive: boolean,             -- В кубе ли сейчас игрок
    CooldownEndTime: number,       -- Когда закончится кулдаун (os.time() + 10)
    BodyPosition: Vector3,         -- Где стоит тело, пока игрок в кубе
    BodyHealth: number,            -- Прочность куба (броня)
}

-- ============================================
-- ТИП: PlayerData (ВСЕ данные игрока, сохраняемые между сессиями)
-- ============================================
export type PlayerData = {
    -- Прогрессия
    Level: number,                 -- 1-50
    Experience: number,            -- Текущий опыт
    NextLevelExp: number,          -- Сколько нужно до следующего уровня
    
    -- Ресурсы
    Mana: ManaData,
    
    -- Армия
    MaxSlots: number,              -- 3 → 20 (растет с уровнем)
    ActiveSlots: { [number]: ActiveUnit? },  -- Ключ 1..MaxSlots
    
    -- Стек душ (карточки)
    SoulStack: { [string]: Card }, -- Ключ = CardId
    
    -- База / Прогресс мира
    AggroLevel: number,            -- Уровень агрессии деревни (0-100)
    ConqueredVillages: { [string]: boolean }, -- Какие деревни захвачены
    
    -- Статистика (для достижений)
    TotalKills: number,            -- Всего убийств (некромант + юниты)
    TotalResurrections: number,    -- Всего воскрешений
    TotalMerges: number,           -- Всего мержей
}

-- ============================================
-- ТИП: ServerState (состояние мира на сервере)
-- ============================================
export type ServerState = {
    PlayersData: { [userId: number]: PlayerData },
    GlobalAggro: number,           -- Глобальный уровень агрессии
    TimeOfDay: number,             -- Время суток (влияет на врагов?)
}

-- ============================================
-- ТИП: CombatResult (результат боя)
-- ============================================
export type CombatResult = {
    AttackerId: string,            -- Кто атаковал (UnitId или "Necromancer")
    TargetId: string,              -- Цель
    Damage: number,                -- Нанесенный урон
    TargetDied: boolean,           -- Умерла ли цель
    ManaGained: number,            -- Сколько маны получено за убийство
    ExperienceGained: number,      -- Сколько опыта получено
}