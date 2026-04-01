import { NextRequest, NextResponse } from 'next/server'
import { supabase } from '@/lib/supabase'

// POST /api/shoe — record a new shoe starting
export async function POST(req: NextRequest) {
  try {
    const { user_id } = await req.json()
    if (!user_id) return NextResponse.json({ error: 'user_id required' }, { status: 400 })

    const { error } = await supabase
      .from('shoe_events')
      .insert({ user_id })

    if (error) return NextResponse.json({ error: error.message }, { status: 500 })
    return NextResponse.json({ ok: true })
  } catch (err) {
    return NextResponse.json({ error: String(err) }, { status: 500 })
  }
}
