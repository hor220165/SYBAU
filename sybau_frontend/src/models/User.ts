import type {Avatar} from "@/models/Avatar.ts";

export interface user{
    id: number,
    username: string,
    email: string,
    coins: number,
    avatar: Avatar,
    isAdmin: boolean,
}