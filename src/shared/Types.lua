--!strict
-- src/shared/Types.lua
-- Экспортируемые типы для игры NecromancerGame

local Types = {}

-- ============================================
-- ОПРЕДЕЛЕНИЯ ТИПОВ (Экспортируемые)
-- ============================================

export type BuffData = {
    BuffType: string,
    Value: number,
    RemainingTime: number,
}

export type UnitStats = {
    Id: string,
    Name: string,
    Tier: number,
    BaseHealth: number,
    BaseDamage: number,
    AttackRange: number,
    AttackType: "Melee" | "Ranged" | "Magic",
    ModelId: string,
    SoulValue: number,
}

export type ActiveUnit = {
    InstanceId: string,
    UnitTypeId: string,
    CurrentHealth: number,
    Buffs: { [string]: BuffData },
    IsAlive: boolean,
    SlotIndex: number,
}

export type Card = {
    CardId: string,
    UnitTypeId: string,
    Modifiers: { [string]: any },
    IsMerged: boolean,
}

export type ManaData = {
    Current: number,
    Max: number,
    RegenBody: number,
    RegenCube: number,
}

export type CubModeData = {
    IsActive: boolean,
    CooldownEndTime: number,
    BodyPosition: Vector3,
    BodyHealth: number,
}

export type PlayerData = {
    Level: number,
    Experience: number,
    NextLevelExp: number,
    Mana: ManaData,
    MaxSlots: number,
    ActiveSlots: { [number]: ActiveUnit? },
    SoulStack: { [string]: Card },
    AggroLevel: number,
    ConqueredVillages: { [string]: boolean },
    TotalKills: number,
    TotalResurrections: number,
    TotalMerges: number,
}

export type ServerState = {
    -- ИСПРАВЛЕНО: убрано "userId:", так как Luau ждет только тип в скобках []
    PlayersData: { [number]: PlayerData },
    GlobalAggro: number,
    TimeOfDay: number,
}

export type CombatResult = {
    AttackerId: string,
    TargetId: string,
    Damage: number,
    TargetDied: boolean,
    ManaGained: number,
    ExperienceGained: number,
}

-- Возвращаем Types для корректной работы require
return Types
