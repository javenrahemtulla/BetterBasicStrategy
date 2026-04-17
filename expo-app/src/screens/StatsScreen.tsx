import React, { useEffect, useState } from 'react'
import { View, Text, ScrollView, StyleSheet, TouchableOpacity, ActivityIndicator } from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'
import { Colors, shared } from '../theme'
import { loadStats } from '../services/SupabaseService'
import type { StatsData } from '../types'

interface Props {
  userId: string
  onBack: () => void
}

function pct(n: number) { return `${Math.round(n * 100)}%` }

function Row({ label, value, sub }: { label: string; value: string; sub?: string }) {
  return (
    <View style={st.row}>
      <Text style={st.rowLabel}>{label}</Text>
      <View style={{ alignItems: 'flex-end' }}>
        <Text style={st.rowValue}>{value}</Text>
        {sub ? <Text style={st.rowSub}>{sub}</Text> : null}
      </View>
    </View>
  )
}

export function StatsScreen({ userId, onBack }: Props) {
  const [stats, setStats] = useState<StatsData | null>(null)
  const [error, setError] = useState('')

  useEffect(() => {
    loadStats(userId)
      .then(setStats)
      .catch(() => setError('Failed to load stats.'))
  }, [userId])

  return (
    <SafeAreaView style={shared.screenBg}>
      <View style={st.header}>
        <TouchableOpacity onPress={onBack} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
          <Text style={st.back}>← Back</Text>
        </TouchableOpacity>
        <Text style={st.title}>Statistics</Text>
        <View style={{ width: 60 }} />
      </View>

      {error
        ? <View style={[shared.fill, shared.center]}><Text style={{ color: Colors.red }}>{error}</Text></View>
        : !stats
          ? <View style={[shared.fill, shared.center]}><ActivityIndicator color={Colors.gold} /></View>
          : (
            <ScrollView contentContainerStyle={st.scroll}>
              {/* Summary */}
              <View style={st.section}>
                <Text style={shared.sectionTitle}>Summary</Text>
                <Row label="Lifetime Hands"   value={String(stats.lifetimeHands)} />
                <Row label="Overall Accuracy" value={pct(stats.lifetimeAccuracy)} sub={`${stats.lifetimeDecisions} decisions`} />
                <Row label="Current Streak"   value={String(stats.currentStreak)} />
                <Row label="Longest Streak"   value={String(stats.longestStreak)} />
                <Row label="Shoes Played"     value={String(stats.shoesPlayed)} />
              </View>

              {/* Outcomes */}
              <View style={st.section}>
                <Text style={shared.sectionTitle}>Outcomes</Text>
                <Row label="Wins"       value={String(stats.outcomeCounts.wins)} />
                <Row label="Losses"     value={String(stats.outcomeCounts.losses)} />
                <Row label="Pushes"     value={String(stats.outcomeCounts.pushes)} />
                <Row label="Blackjacks" value={String(stats.outcomeCounts.blackjacks)} />
                <Row label="Surrenders" value={String(stats.outcomeCounts.surrenders)} />
              </View>

              {/* Accuracy by hand type */}
              {stats.accuracyByHandType.length > 0 && (
                <View style={st.section}>
                  <Text style={shared.sectionTitle}>Accuracy by Hand Type</Text>
                  {stats.accuracyByHandType.map(h => (
                    <Row key={h.label} label={h.label} value={pct(h.accuracy)} sub={`${h.total} hands`} />
                  ))}
                </View>
              )}

              {/* Accuracy by upcard */}
              {stats.accuracyByDealerUpcard.length > 0 && (
                <View style={st.section}>
                  <Text style={shared.sectionTitle}>Accuracy by Dealer Upcard</Text>
                  {stats.accuracyByDealerUpcard.map(h => (
                    <Row key={h.rank} label={`Dealer ${h.rank}`} value={pct(h.accuracy)} sub={`${h.total} hands`} />
                  ))}
                </View>
              )}

              {/* Top mistakes */}
              {stats.topMistakes.length > 0 && (
                <View style={st.section}>
                  <Text style={shared.sectionTitle}>Top Mistakes</Text>
                  {stats.topMistakes.map(m => (
                    <Row key={m.label} label={m.label} value={`${m.count}×`} sub={`Should: ${m.correctAction}`} />
                  ))}
                </View>
              )}

              {/* Recent sessions */}
              {stats.recentSessions.length > 0 && (
                <View style={st.section}>
                  <Text style={shared.sectionTitle}>Recent Sessions</Text>
                  {stats.recentSessions.map(s => {
                    const total = s.correct_decisions + s.incorrect_decisions
                    const acc = total ? s.correct_decisions / total : 0
                    return (
                      <Row
                        key={s.id}
                        label={new Date(s.started_at).toLocaleDateString()}
                        value={pct(acc)}
                        sub={`${s.hands_played} hands`}
                      />
                    )
                  })}
                </View>
              )}
            </ScrollView>
          )
      }
    </SafeAreaView>
  )
}

const st = StyleSheet.create({
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 16, paddingVertical: 12 },
  back: { color: Colors.gold, fontSize: 16, fontWeight: '600', width: 60 },
  title: { color: Colors.cream, fontSize: 18, fontWeight: '700' },
  scroll: { padding: 16, gap: 16 },
  section: { backgroundColor: Colors.feltDark, borderRadius: 12, padding: 16 },
  row: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingVertical: 8, borderBottomWidth: 1, borderBottomColor: Colors.felt },
  rowLabel: { color: Colors.cream, fontSize: 14 },
  rowValue: { color: Colors.gold, fontSize: 15, fontWeight: '700' },
  rowSub: { color: Colors.muted, fontSize: 11 },
})
