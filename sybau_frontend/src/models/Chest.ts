import type { item } from '@/models/Item';

export interface Chest {
  id: number;
  name: string;
  price: number;
  imageUrl: string;
  commonChance: number;
  rareChance: number;
  epicChance: number;
  legendaryChance: number;
  mythicChance: number;
  items: item[];
}
