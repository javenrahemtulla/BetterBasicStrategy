import React, { useState } from 'react'
import { View, Text, TextInput, TouchableOpacity, StyleSheet, ActivityIndicator, KeyboardAvoidingView, Platform } from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'
import { Colors, shared } from '../theme'
import { getOrCreateUser } from '../services/SupabaseService'
import type { BBSUser } from '../types'

interface Props {
  savedUsername: string
  onEnter: (user: BBSUser) => void
}

export function LandingScreen({ savedUsername, onEnter }: Props) {
  const [username, setUsername] = useState(savedUsername)
  const [loading, setLoading]   = useState(false)
  const [error, setError]       = useState('')

  async function handlePlay() {
    const u = username.trim()
    if (!u) { setError('Enter a username to continue.'); return }
    setLoading(true); setError('')
    try {
      const user = await getOrCreateUser(u)
      onEnter(user)
    } catch (e) {
      setError('Could not connect. Check your internet connection.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <SafeAreaView style={shared.screenBg}>
      <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined} style={shared.fill}>
        <View style={styles.inner}>
          <Text style={styles.title}>Better Basic{'\n'}Strategy</Text>
          <Text style={styles.subtitle}>Blackjack coaching trainer</Text>

          <View style={styles.form}>
            <Text style={styles.label}>Username</Text>
            <TextInput
              style={styles.input}
              value={username}
              onChangeText={setUsername}
              placeholder="e.g. cardshark42"
              placeholderTextColor={Colors.muted}
              autoCapitalize="none"
              autoCorrect={false}
              returnKeyType="go"
              onSubmitEditing={handlePlay}
            />
            {!!error && <Text style={styles.error}>{error}</Text>}
            <TouchableOpacity style={styles.btn} onPress={handlePlay} activeOpacity={0.8} disabled={loading}>
              {loading
                ? <ActivityIndicator color={Colors.feltDark} />
                : <Text style={styles.btnLabel}>PLAY</Text>}
            </TouchableOpacity>
          </View>
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  )
}

const styles = StyleSheet.create({
  inner: { flex: 1, justifyContent: 'center', paddingHorizontal: 32 },
  title: { color: Colors.gold, fontSize: 40, fontWeight: '800', textAlign: 'center', lineHeight: 46, marginBottom: 8 },
  subtitle: { color: Colors.muted, fontSize: 15, textAlign: 'center', marginBottom: 48 },
  form: { gap: 12 },
  label: { color: Colors.cream, fontSize: 14, fontWeight: '600' },
  input: {
    backgroundColor: Colors.feltDark, color: Colors.cream,
    borderRadius: 10, paddingHorizontal: 16, paddingVertical: 14,
    fontSize: 16, borderWidth: 1, borderColor: Colors.gold + '55',
  },
  error: { color: Colors.red, fontSize: 13 },
  btn: {
    backgroundColor: Colors.gold, borderRadius: 10,
    paddingVertical: 16, alignItems: 'center', marginTop: 8,
  },
  btnLabel: { color: Colors.feltDark, fontWeight: '800', fontSize: 16, letterSpacing: 1 },
})
