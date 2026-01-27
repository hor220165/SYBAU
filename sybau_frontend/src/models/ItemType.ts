export const ItemType = {
    Cosmetic: 0,
    Booster: 1
} as const;

export type ItemType = typeof ItemType[keyof typeof ItemType];