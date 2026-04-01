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
      const text = await res.text()
      if (!text) throw new Error(`Server error (${res.status})`)
      const data = JSON.parse(text)
      if (!res.ok) throw new Error(data.error ?? `Server error ${res.status}`)
      sessionStorage.setItem('bbs_user', JSON.stringify(data.user))
      router.push('/game')
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err))
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-[#0d2b15] flex items-center justify-center p-6">
      <div className="w-full max-w-sm">
        {/* Header */}
        <div className="mb-10">
          <p className="text-[#6b8f71] text-xs font-medium tracking-[0.2em] uppercase mb-3">
            Blackjack Training
          </p>
          <h1 className="text-[#e8e0cc] text-3xl font-semibold tracking-tight">
            Better Basic Strategy
          </h1>
          <p className="mt-2 text-[#6b8f71] text-sm leading-relaxed">
            Master the mathematically correct play for every hand against a 6-deck shoe.
          </p>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="space-y-3">
          <div>
            <label className="block text-[#9b9080] text-xs font-medium mb-1.5">
              Username
            </label>
            <input
              type="text"
              value={username}
              onChange={e => setUsername(e.target.value)}
              placeholder="Choose a name"
              maxLength={32}
              autoFocus
              className="w-full px-3.5 py-2.5 rounded-lg bg-white/[0.06] border border-white/10 text-[#e8e0cc] placeholder-[#4a5c4e] text-sm focus:outline-none focus:border-[#a08840] focus:bg-white/[0.08] transition"
            />
            <p className="mt-1.5 text-[#4a5c4e] text-xs">
              No password. Access your stats from any device.
            </p>
          </div>

          {error && (
            <p className="text-red-400/80 text-xs py-2">{error}</p>
          )}

          <button
            type="submit"
            disabled={!username.trim() || loading}
            className="w-full py-2.5 rounded-lg bg-[#a08840] text-[#0d2b15] text-sm font-semibold hover:bg-[#b89a4d] disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
          >
            {loading ? 'Loading…' : 'Continue'}
          </button>
        </form>

        {/* Footer */}
        <div className="mt-10 pt-6 border-t border-white/[0.06] grid grid-cols-3 gap-4 text-center">
          {[
            ['6-Deck Shoe', 'Physically accurate dealing'],
            ['All Rules', 'H17, DAS, surrender'],
            ['Your Stats', 'Tracked across sessions'],
          ].map(([title, desc]) => (
            <div key={title}>
              <p className="text-[#e8e0cc] text-xs font-medium">{title}</p>
              <p className="text-[#4a5c4e] text-[11px] mt-0.5 leading-snug">{desc}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
