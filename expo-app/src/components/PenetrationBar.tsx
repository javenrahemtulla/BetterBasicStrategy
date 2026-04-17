import React from 'react'
import { View, Text, StyleSheet } from 'react-native'
import { Colors } from '../theme'

interface Props {
  penetration: number
  trigger: number
}

export function PenetrationBar({ penetration, trigger }: Props) {
  const pct = Math.min(penetration, 1)
  return (
    <View style={styles.root}>
      <View style={styles.track}>
        <View style={[styles.fill, { width: `${pct * 100}%` }]} />
        <View style={[styles.marker, { left: `${trigger * 100}%` }]} />
      </View>
      <Text style={styles.label}>{Math.round(pct * 100)}%</Text>
    </View>
  )
}

const styles = StyleSheet.create({
  root: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  track: { flex: 1, height: 6, backgroundColor: Colors.feltDark, borderRadius: 3, overflow: 'visible' },
  fill: { height: '100%', backgroundColor: Colors.gold, borderRadius: 3 },
  marker: { position: 'absolute', top: -3, width: 2, height: 12, backgroundColor: Colors.muted, borderRadius: 1 },
  label: { color: Colors.muted, fontSize: 11, width: 34, textAlign: 'right' },
})
