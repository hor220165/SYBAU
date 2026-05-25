import type { ItemType } from '@/models/ItemType';

export interface ShopDisplayItem {
  id: number;
  name: string;
  description: string;
  price: number;
  realMoneyPrice?: number | null;
  type: ItemType | string;
  xpBoostPercentage: number;
  coinBoostPercentage: number;
  category: 'chest' | 'boost' | 'item';
  categoryLabel: string;
  rarity: 'common' | 'rare' | 'epic' | 'legendary' | 'mythic';
  icon: string;
  imageUrl?: string;
  highlights: string[];
  ownedQuantity: number;
}
