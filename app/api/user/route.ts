import { NextRequest, NextResponse } from 'next/server'
import { supabase } from '@/lib/supabase'

// GET /api/user?username=xxx
export async function GET(req: NextRequest) {
  const username = req.nextUrl.searchParams.get('username')?.toLowerCase().trim()
  if (!username) return NextResponse.json({ error: 'username required' }, { status: 400 })

  const { data, error } = await supabase
    .from('users')
    .select('*')
    .eq('username', username)
    .single()

  if (error && error.code !== 'PGRST116') {
    return NextResponse.json({ error: error.message }, { status: 500 })
  }

  return NextResponse.json({ user: data ?? null })
}

// POST /api/user  { username }
export async function POST(req: NextRequest) {
  try {
    const { username } = await req.json()
    const clean = username?.toLowerCase().trim()
    if (!clean) return NextResponse.json({ error: 'username required' }, { status: 400 })

    const { data, error } = await supabase
      .from('users')
      .upsert({ username: clean }, { onConflict: 'username' })
      .select()
      .single()

    if (error) return NextResponse.json({ error: error.message }, { status: 500 })
    return NextResponse.json({ user: data })
  } catch (err) {
    return NextResponse.json({ error: String(err) }, { status: 500 })
  }
}
