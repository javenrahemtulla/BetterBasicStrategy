'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'

export default function LandingPage() {
  const [username, setUsername] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const router = useRouter()

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    const clean = username.trim().toLowerCase()
    if (!clean) return

    setLoading(true)
    setError('')

    try {
      const res = await fetch('/api/user', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username: clean }),
      })
      const data = await res.json()
      if (!res.ok) throw new Error(data.error)

      // Store user in sessionStorage for the game
      sessionStorage.setItem('bbs_user', JSON.stringify(data.user))
      router.push('/game')
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err))
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-[#0f3818] px-4">
      {/* Subtle grain overlay */}
      <div className="fixed inset-0 pointer-events-none opacity-30"
        style={{ backgroundImage: 'url("data:image/svg+xml,%3Csvg viewBox=\'0 0 256 256\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cfilter id=\'noise\'%3E%3CfeTurbulence type=\'fractalNoise\' baseFrequency=\'0.9\' numOctaves=\'4\' stitchTiles=\'stitch\'/%3E%3C/filter%3E%3Crect width=\'100%25\' height=\'100%25\' filter=\'url(%23noise)\' opacity=\'0.4\'/%3E%3C/svg%3E")', backgroundSize: '200px 200px' }} />

      <div className="relative z-10 w-full max-w-sm">
        {/* Logo / Title */}
        <div className="text-center mb-10">
          <div className="text-5xl mb-4">♠</div>
          <h1 className="text-3xl font-bold text-[#f9f5e3] tracking-tight">
            Better Basic Strategy
          </h1>
          <p className="mt-2 text-[#a09880] text-sm">
            A blackjack strategy trainer
          </p>
        </div>

        {/* Username form */}
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-[#b89a4d] tracking-widest uppercase mb-2">
              Username
            </label>
            <input
              type="text"
              value={username}
              onChange={e => setUsername(e.target.value)}
              placeholder="Enter any username"
              maxLength={32}
              autoFocus
              className="w-full px-4 py-3 rounded-xl bg-white/10 border border-white/20 text-[#f9f5e3] placeholder-[#a09880] text-lg focus:outline-none focus:border-[#b89a4d] focus:ring-1 focus:ring-[#b89a4d] transition"
            />
            <p className="mt-2 text-xs text-[#a09880]">
              No password needed. Your stats are tied to this name across all devices.
            </p>
          </div>

          {error && (
            <p className="text-red-400 text-sm">{error}</p>
          )}

          <button
            type="submit"
            disabled={!username.trim() || loading}
            className="w-full py-4 rounded-xl bg-[#b89a4d] text-black font-bold text-lg hover:bg-[#cead5a] disabled:opacity-40 disabled:cursor-not-allowed transition"
          >
            {loading ? 'Loading...' : 'Play'}
          </button>
        </form>

        <p className="text-center text-xs text-[#a09880] mt-8">
          Fully offline play · Stats sync across devices
        </p>
      </div>
    </div>
  )
}
