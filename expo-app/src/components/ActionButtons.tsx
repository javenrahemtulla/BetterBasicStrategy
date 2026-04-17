import React from 'react'
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native'
import type { DecisionCategory } from '../types'
import { Colors, actionColor } from '../theme'

interface Props {
  available: Set<DecisionCategory>
  onAction: (a: DecisionCategory) => void
  disabled?: boolean
}

const MAIN: DecisionCategory[] = ['hit', 'stand', 'double', 'split']
const LABEL: Record<DecisionCategory, string> = { hit: 'HIT', stand: 'STAND', double: 'DOUBLE', split: 'SPLIT', surrender: 'SURRENDER' }

export function ActionButtons({ available, onAction, disabled }: Props) {
  return (
    <View style={styles.root}>
      <View style={styles.grid}>
        {MAIN.map(a => {
          const on = available.has(a) && !disabled
          return (
            <TouchableOpacity
              key={a}
              style={[styles.btn, { backgroundColor: actionColor[a] }, !on && styles.btnOff]}
              onPress={() => on && onAction(a)}
              activeOpacity={0.75}
            >
              <Text style={[styles.label, !on && styles.labelOff]}>{LABEL[a]}</Text>
            </TouchableOpacity>
          )
        })}
      </View>
      {available.has('surrender') && (
        <TouchableOpacity
          style={[styles.surrender, disabled && styles.btnOff]}
          onPress={() => !disabled && onAction('surrender')}
          activeOpacity={0.75}
        >
          <Text style={styles.surrenderLabel}>{LABEL.surrender}</Text>
        </TouchableOpacity>
      )}
    </View>
  )
}

const styles = StyleSheet.create({
  root: { gap: 8 },
  grid: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  btn: {
    flex: 1, minWidth: '45%', paddingVertical: 14,
    borderRadius: 8, alignItems: 'center',
  },
  btnOff: { opacity: 0.35 },
  label: { color: Colors.white, fontWeight: '700', fontSize: 15, letterSpacing: 0.5 },
  labelOff: { color: Colors.muted },
  surrender: {
    backgroundColor: Colors.surrender, paddingVertical: 10,
    borderRadius: 8, alignItems: 'center',
  },
  surrenderLabel: { color: Colors.white, fontWeight: '700', fontSize: 14, letterSpacing: 0.5 },
})
