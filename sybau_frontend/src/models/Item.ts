import type {ItemType} from "@/models/ItemType.ts";

export interface item{
    id: number,
    name: string,
    description: string,
    price: number,
    type: ItemType,
    xpBoostPercentage: number,
    coinBoostPercentage: number,
    rarity?: 'common' | 'rare' | 'epic' | 'legendary',
    quantity?: number,
    maxQuantity?: number,
    imageUrl?: string
}
