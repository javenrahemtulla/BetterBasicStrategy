import { NextRequest, NextResponse } from 'next/server'
import { supabase } from '@/lib/supabase'

// POST /api/session — create session
export async function POST(req: NextRequest) {
  const { user_id, rules_snapshot } = await req.json()
  if (!user_id) return NextResponse.json({ error: 'user_id required' }, { status: 400 })

  const { data, error } = await supabase
    .from('game_sessions')
    .insert({
      user_id,
      rules_snapshot,
      hands_played: 0,
      correct_decisions: 0,
      incorrect_decisions: 0,
    })
    .select()
    .single()

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ session: data })
}

// PATCH /api/session — update session totals
export async function PATCH(req: NextRequest) {
  const { id, hands_played, correct_decisions, incorrect_decisions, ended_at } = await req.json()
  if (!id) return NextResponse.json({ error: 'id required' }, { status: 400 })

  const { data, error } = await supabase
    .from('game_sessions')
    .update({ hands_played, correct_decisions, incorrect_decisions, ended_at })
    .eq('id', id)
    .select()
    .single()

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ session: data })
}
