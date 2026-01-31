"use client"

import { useState } from "react"
import {
  Shield,
  LayoutDashboard,
  MapPin,
  ClipboardList,
  Bell,
  Users,
  LogOut,
  Menu,
  X,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { cn } from "@/lib/utils"
import type { User } from "@/app/page"
import { DashboardView } from "@/components/views/dashboard-view"
import { MonitoringView } from "@/components/views/monitoring-view"
import { DutiesView } from "@/components/views/duties-view"
import { AlertsView } from "@/components/views/alerts-view"
import { OfficersView } from "@/components/views/officers-view"

interface DashboardLayoutProps {
  user: User
  onLogout: () => void
}

const navItems = [
  { id: "dashboard", label: "Dashboard", icon: LayoutDashboard },
  { id: "monitoring", label: "Live Monitoring", icon: MapPin },
  { id: "duties", label: "Duties", icon: ClipboardList },
  { id: "alerts", label: "Alerts", icon: Bell },
  { id: "officers", label: "Officers", icon: Users },
]

export function DashboardLayout({ user, onLogout }: DashboardLayoutProps) {
  const [activeView, setActiveView] = useState("dashboard")
  const [sidebarOpen, setSidebarOpen] = useState(false)

  const renderView = () => {
    switch (activeView) {
      case "dashboard":
        return <DashboardView />
      case "monitoring":
        return <MonitoringView />
      case "duties":
        return <DutiesView />
      case "alerts":
        return <AlertsView />
      case "officers":
        return <OfficersView />
      default:
        return <DashboardView />
    }
  }

  return (
    <div className="min-h-screen bg-background flex">
      {/* Sidebar */}
      <aside
        className={cn(
          "fixed inset-y-0 left-0 z-50 w-64 bg-card border-r border-border transform transition-transform duration-200 ease-in-out lg:translate-x-0 lg:static",
          sidebarOpen ? "translate-x-0" : "-translate-x-full"
        )}
      >
        <div className="flex flex-col h-full">
          {/* Logo */}
          <div className="flex items-center gap-3 p-6 border-b border-border">
            <div className="p-2 bg-primary/10 rounded-lg">
              <Shield className="h-6 w-6 text-primary" />
            </div>
            <div>
              <h1 className="font-bold text-lg">CopMap</h1>
              <p className="text-xs text-muted-foreground">Station Dashboard</p>
            </div>
            <Button
              variant="ghost"
              size="icon"
              className="ml-auto lg:hidden"
              onClick={() => setSidebarOpen(false)}
            >
              <X className="h-5 w-5" />
            </Button>
          </div>

          {/* Navigation */}
          <nav className="flex-1 p-4 space-y-1">
            {navItems.map((item) => (
              <button
                key={item.id}
                onClick={() => {
                  setActiveView(item.id)
                  setSidebarOpen(false)
                }}
                className={cn(
                  "w-full flex items-center gap-3 px-4 py-3 rounded-lg text-sm font-medium transition-colors",
                  activeView === item.id
                    ? "bg-primary text-primary-foreground"
                    : "text-muted-foreground hover:text-foreground hover:bg-muted"
                )}
              >
                <item.icon className="h-5 w-5" />
                {item.label}
              </button>
            ))}
          </nav>

          {/* User Info */}
          <div className="p-4 border-t border-border">
            <div className="flex items-center gap-3 mb-4">
              <div className="h-10 w-10 rounded-full bg-primary/10 flex items-center justify-center">
                <span className="text-sm font-medium text-primary">
                  {user.name.charAt(0).toUpperCase()}
                </span>
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium truncate">{user.name}</p>
                <p className="text-xs text-muted-foreground truncate">
                  {user.email}
                </p>
              </div>
            </div>
            <Button
              variant="outline"
              className="w-full justify-start gap-2"
              onClick={onLogout}
            >
              <LogOut className="h-4 w-4" />
              Sign out
            </Button>
          </div>
        </div>
      </aside>

      {/* Overlay for mobile */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 bg-background/80 backdrop-blur-sm z-40 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Main Content */}
      <main className="flex-1 flex flex-col min-h-screen">
        {/* Header */}
        <header className="sticky top-0 z-30 flex items-center gap-4 px-6 py-4 bg-background/95 backdrop-blur border-b border-border">
          <Button
            variant="ghost"
            size="icon"
            className="lg:hidden"
            onClick={() => setSidebarOpen(true)}
          >
            <Menu className="h-5 w-5" />
          </Button>
          <div>
            <h2 className="text-xl font-semibold capitalize">
              {navItems.find((item) => item.id === activeView)?.label}
            </h2>
            <p className="text-sm text-muted-foreground">
              Real-time police station management
            </p>
          </div>
        </header>

        {/* View Content */}
        <div className="flex-1 p-6">{renderView()}</div>
      </main>
    </div>
  )
}
