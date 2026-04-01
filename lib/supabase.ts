import { createClient } from '@supabase/supabase-js'

function getSupabase() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
  if (!url || !anonKey) throw new Error('Supabase env vars not set')
  return createClient(url, anonKey)
}

let _client: ReturnType<typeof createClient> | null = null

export function getClient() {
  if (!_client) _client = getSupabase()
  return _client
}

// Convenience alias
export const supabase = new Proxy({} as ReturnType<typeof createClient>, {
  get(_, prop) {
    return (getClient() as unknown as Record<string, unknown>)[prop as string]
  },
})
