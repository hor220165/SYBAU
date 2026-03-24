import type {ItemType} from "@/models/ItemType.ts";

export interface item{
    id: number,
    name: string,
    description: string,
    price: number,
    type: ItemType,
    xpBoostPercentage: number,
    coinBoostPercentage: number,
    quantity?: number,
    maxQuantity?: number
}

