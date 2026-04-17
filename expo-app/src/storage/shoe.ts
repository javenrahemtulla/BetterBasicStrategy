import AsyncStorage from '@react-native-async-storage/async-storage'
import type { ShoeState } from '../engine/shoe'

const KEY = 'bbs_shoe_v1'

export async function saveShoe(shoe: ShoeState): Promise<void> {
  try {
    await AsyncStorage.setItem(KEY, JSON.stringify(shoe))
  } catch (_) {}
}

export async function loadShoe(): Promise<ShoeState | null> {
  try {
    const raw = await AsyncStorage.getItem(KEY)
    if (!raw) return null
    return JSON.parse(raw) as ShoeState
  } catch (_) {
    return null
  }
}

export async function clearShoe(): Promise<void> {
  try { await AsyncStorage.removeItem(KEY) } catch (_) {}
}
