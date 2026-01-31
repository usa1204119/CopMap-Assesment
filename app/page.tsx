"use client"

import { useState } from "react"
import { LoginScreen } from "@/components/login-screen"
import { DashboardLayout } from "@/components/dashboard-layout"
import { OfficerApp } from "@/components/officer-app"

export type UserRole = "station_master" | "field_officer"

export interface User {
  id: string
  email: string
  name: string
  role: UserRole
  badge?: string
}

export default function Home() {
  const [user, setUser] = useState<User | null>(null)
  const [isLoading, setIsLoading] = useState(false)

  const handleLogin = async (email: string, password: string) => {
    setIsLoading(true)
    // Simulate authentication
    await new Promise((resolve) => setTimeout(resolve, 1000))

    // Determine role based on email pattern (demo logic)
    const isStationMaster = email.toLowerCase().includes("station") || email.toLowerCase().includes("master")

    setUser({
      id: `user_${Date.now()}`,
      email,
      name: isStationMaster ? "Station Master" : "Officer " + email.split("@")[0],
      role: isStationMaster ? "station_master" : "field_officer",
      badge: isStationMaster ? undefined : `BADGE-${Math.floor(Math.random() * 9000) + 1000}`,
    })
    setIsLoading(false)
  }

  const handleLogout = () => {
    setUser(null)
  }

  if (!user) {
    return <LoginScreen onLogin={handleLogin} isLoading={isLoading} />
  }

  if (user.role === "station_master") {
    return <DashboardLayout user={user} onLogout={handleLogout} />
  }

  return <OfficerApp user={user} onLogout={handleLogout} />
}
