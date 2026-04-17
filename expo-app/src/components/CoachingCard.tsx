import React from 'react'
import { View, Text, TouchableOpacity, StyleSheet, Modal } from 'react-native'
import type { StrategyEntry } from '../types'
import { Colors } from '../theme'

interface Props {
  entry: StrategyEntry | null
  onDismiss: () => void
}

export function CoachingCard({ entry, onDismiss }: Props) {
  if (!entry) return null
  return (
    <Modal transparent animationType="fade" visible onRequestClose={onDismiss}>
      <View style={styles.backdrop}>
        <View style={styles.card}>
          <Text style={styles.heading}>INCORRECT</Text>
          <Text style={styles.action}>Correct: <Text style={styles.actionBold}>{entry.action.replace(/Or/, ' or ').toUpperCase()}</Text></Text>
          <Text style={styles.explanation}>{entry.explanation}</Text>
          <TouchableOpacity style={styles.btn} onPress={onDismiss} activeOpacity={0.8}>
            <Text style={styles.btnLabel}>GOT IT</Text>
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  )
}

const styles = StyleSheet.create({
  backdrop: { flex: 1, backgroundColor: 'rgba(0,0,0,0.65)', justifyContent: 'center', alignItems: 'center', padding: 24 },
  card: { backgroundColor: Colors.feltDark, borderRadius: 14, padding: 24, width: '100%', maxWidth: 360, borderWidth: 1, borderColor: Colors.gold },
  heading: { color: Colors.red, fontWeight: '800', fontSize: 18, letterSpacing: 1, marginBottom: 12, textAlign: 'center' },
  action: { color: Colors.muted, fontSize: 14, marginBottom: 8, textAlign: 'center' },
  actionBold: { color: Colors.gold, fontWeight: '700' },
  explanation: { color: Colors.cream, fontSize: 15, lineHeight: 22, textAlign: 'center', marginBottom: 20 },
  btn: { backgroundColor: Colors.gold, borderRadius: 8, paddingVertical: 12, alignItems: 'center' },
  btnLabel: { color: Colors.feltDark, fontWeight: '800', fontSize: 15, letterSpacing: 0.5 },
})
