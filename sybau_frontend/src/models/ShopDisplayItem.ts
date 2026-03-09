import type { ItemType } from '@/models/ItemType';

export interface ShopDisplayItem {
  id: number;
  name: string;
  description: string;
  price: number;
  type: ItemType | string;
  xpBoostPercentage: number;
  category: 'chest' | 'boost' | 'item';
  categoryLabel: string;
  rarity: 'common' | 'rare' | 'epic' | 'legendary';
  icon: string;
  highlights: string[];
}
