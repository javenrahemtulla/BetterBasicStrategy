export type Json = string | number | boolean | null | { [key: string]: Json } | Json[]

export interface Database {
  public: {
    Tables: {
      users: {
        Row: { id: string; username: string; created_at: string }
        Insert: { id?: string; username: string; created_at?: string }
        Update: { id?: string; username?: string; created_at?: string }
      }
      game_sessions: {
        Row: {
          id: string; user_id: string; started_at: string; ended_at: string | null
          rules_snapshot: Json; hands_played: number
          correct_decisions: number; incorrect_decisions: number
        }
        Insert: {
          id?: string; user_id: string; started_at?: string; ended_at?: string | null
          rules_snapshot?: Json; hands_played?: number
          correct_decisions?: number; incorrect_decisions?: number
        }
        Update: {
          id?: string; user_id?: string; started_at?: string; ended_at?: string | null
          rules_snapshot?: Json; hands_played?: number
          correct_decisions?: number; incorrect_decisions?: number
        }
      }
      hand_records: {
        Row: {
          id: string; session_id: string; user_id: string; timestamp: string
          spot_number: number; player_cards: Json; dealer_upcard: Json | null
          dealer_final_hand: Json; hand_type: string; player_total: number
          actions_taken: Json; outcome: string
          was_split: boolean; was_doubled: boolean; was_surrendered: boolean
        }
        Insert: {
          id?: string; session_id: string; user_id: string; timestamp?: string
          spot_number?: number; player_cards?: Json; dealer_upcard?: Json | null
          dealer_final_hand?: Json; hand_type: string; player_total: number
          actions_taken?: Json; outcome: string
          was_split?: boolean; was_doubled?: boolean; was_surrendered?: boolean
        }
        Update: {
          id?: string; session_id?: string; user_id?: string; timestamp?: string
          spot_number?: number; player_cards?: Json; dealer_upcard?: Json | null
          dealer_final_hand?: Json; hand_type?: string; player_total?: number
          actions_taken?: Json; outcome?: string
          was_split?: boolean; was_doubled?: boolean; was_surrendered?: boolean
        }
      }
    }
  }
}
