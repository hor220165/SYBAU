import type {ItemType} from "@/models/ItemType.ts";

export interface item{
    id: number,
    name: string,
    description: string,
    price: number,
    realMoneyPrice?: number | null,
    type: ItemType | string,
    xpBoostPercentage: number,
    coinBoostPercentage: number,
    rarity?: 'common' | 'rare' | 'epic' | 'legendary' | 'mythic',
    quantity?: number,
    maxQuantity?: number,
    imageUrl?: string
}
