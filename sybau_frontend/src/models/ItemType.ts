export const ItemType = {
    Cosmetic: 0,
    Booster: 1,
    RealMoney: 2
} as const;

export type ItemType = typeof ItemType[keyof typeof ItemType];
