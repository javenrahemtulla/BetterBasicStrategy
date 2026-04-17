import React, { useEffect, useState } from 'react'
import { StatusBar } from 'expo-status-bar'
import { SafeAreaProvider } from 'react-native-safe-area-context'
import AsyncStorage from '@react-native-async-storage/async-storage'

import { LandingScreen } from './src/screens/LandingScreen'
import { GameScreen }    from './src/screens/GameScreen'
import { StatsScreen }   from './src/screens/StatsScreen'
import type { BBSUser }  from './src/types'

type Route = 'landing' | 'game' | 'stats'

const USERNAME_KEY = 'bbs_username_v1'

export default function App() {
  const [route, setRoute]               = useState<Route>('landing')
  const [user, setUser]                 = useState<BBSUser | null>(null)
  const [savedUsername, setSavedUsername] = useState('')

  useEffect(() => {
    AsyncStorage.getItem(USERNAME_KEY).then(u => { if (u) setSavedUsername(u) }).catch(() => {})
  }, [])

  function handleEnter(u: BBSUser) {
    setUser(u)
    setRoute('game')
    AsyncStorage.setItem(USERNAME_KEY, u.username).catch(() => {})
  }

  if (route === 'landing' || !user) {
    return (
      <SafeAreaProvider>
        <StatusBar style="light" />
        <LandingScreen savedUsername={savedUsername} onEnter={handleEnter} />
      </SafeAreaProvider>
    )
  }

  if (route === 'stats') {
    return (
      <SafeAreaProvider>
        <StatusBar style="light" />
        <StatsScreen userId={user.id} onBack={() => setRoute('game')} />
      </SafeAreaProvider>
    )
  }

  return (
    <SafeAreaProvider>
      <StatusBar style="light" />
      <GameScreen userId={user.id} username={user.username} onStats={() => setRoute('stats')} />
    </SafeAreaProvider>
  )
}
