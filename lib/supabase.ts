import { createClient } from '@supabase/supabase-js'
import type { Database } from './database.types'

let _client: ReturnType<typeof createClient<Database>> | null = null

export function getClient() {
  if (!_client) {
    const url = process.env.NEXT_PUBLIC_SUPABASE_URL
    const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
    if (!url || !anonKey) throw new Error('Supabase env vars not set')
    _client = createClient<Database>(url, anonKey)
  }
  return _client
}

export const supabase = new Proxy({} as ReturnType<typeof createClient<Database>>, {
  get(_, prop) {
    return (getClient() as unknown as Record<string, unknown>)[prop as string]
  },
})
