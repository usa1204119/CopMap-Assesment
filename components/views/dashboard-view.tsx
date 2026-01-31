"use client"

import { Users, ClipboardList, Bell, MapPin, TrendingUp, Clock } from "lucide-react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"

const stats = [
  {
    title: "Active Officers",
    value: "24",
    description: "Currently on duty",
    icon: Users,
    trend: "+3 from yesterday",
    color: "text-emerald-500",
  },
  {
    title: "Active Duties",
    value: "12",
    description: "Ongoing assignments",
    icon: ClipboardList,
    trend: "8 patrol, 4 bandobast",
    color: "text-blue-500",
  },
  {
    title: "Pending Alerts",
    value: "3",
    description: "Requires attention",
    icon: Bell,
    trend: "2 urgent, 1 normal",
    color: "text-amber-500",
  },
  {
    title: "Coverage Area",
    value: "15",
    description: "Active zones",
    icon: MapPin,
    trend: "All sectors covered",
    color: "text-violet-500",
  },
]

const recentDuties = [
  {
    id: "1",
    type: "Patrol",
    area: "Sector 15, Main Market",
    officers: ["Raj Kumar", "Amit Singh"],
    status: "in_progress",
    startTime: "08:00 AM",
  },
  {
    id: "2",
    type: "Bandobast",
    area: "Gandhi Stadium",
    officers: ["Priya Sharma", "Deepak Verma", "Sunil Yadav"],
    status: "in_progress",
    startTime: "09:30 AM",
  },
  {
    id: "3",
    type: "Patrol",
    area: "Sector 22, Bus Stand",
    officers: ["Vikram Patel"],
    status: "pending",
    startTime: "10:00 AM",
  },
  {
    id: "4",
    type: "Patrol",
    area: "Railway Station Area",
    officers: ["Meena Kumari", "Ravi Shankar"],
    status: "completed",
    startTime: "06:00 AM",
  },
]

const recentAlerts = [
  {
    id: "1",
    type: "SOS",
    officer: "Constable Raj Kumar",
    message: "Emergency assistance needed",
    time: "5 min ago",
    priority: "high",
  },
  {
    id: "2",
    type: "Battery Low",
    officer: "Constable Amit Singh",
    message: "Device battery at 15%",
    time: "12 min ago",
    priority: "medium",
  },
  {
    id: "3",
    type: "Offline",
    officer: "Constable Priya Sharma",
    message: "Lost GPS signal",
    time: "28 min ago",
    priority: "low",
  },
]

export function DashboardView() {
  return (
    <div className="space-y-6">
      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {stats.map((stat) => (
          <Card key={stat.title} className="bg-card/50 border-border/50">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                {stat.title}
              </CardTitle>
              <stat.icon className={`h-5 w-5 ${stat.color}`} />
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold">{stat.value}</div>
              <p className="text-xs text-muted-foreground mt-1">
                {stat.description}
              </p>
              <div className="flex items-center gap-1 mt-2 text-xs text-muted-foreground">
                <TrendingUp className="h-3 w-3" />
                {stat.trend}
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent Duties */}
        <Card className="bg-card/50 border-border/50">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <ClipboardList className="h-5 w-5" />
              Recent Duties
            </CardTitle>
            <CardDescription>Latest duty assignments and status</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {recentDuties.map((duty) => (
                <div
                  key={duty.id}
                  className="flex items-start gap-4 p-3 rounded-lg bg-muted/30"
                >
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <Badge
                        variant={duty.type === "Patrol" ? "default" : "secondary"}
                        className="text-xs"
                      >
                        {duty.type}
                      </Badge>
                      <Badge
                        variant="outline"
                        className={
                          duty.status === "in_progress"
                            ? "border-emerald-500/50 text-emerald-500"
                            : duty.status === "pending"
                            ? "border-amber-500/50 text-amber-500"
                            : "border-muted-foreground/50 text-muted-foreground"
                        }
                      >
                        {duty.status.replace("_", " ")}
                      </Badge>
                    </div>
                    <p className="text-sm font-medium truncate">{duty.area}</p>
                    <p className="text-xs text-muted-foreground truncate">
                      {duty.officers.join(", ")}
                    </p>
                  </div>
                  <div className="flex items-center gap-1 text-xs text-muted-foreground">
                    <Clock className="h-3 w-3" />
                    {duty.startTime}
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Recent Alerts */}
        <Card className="bg-card/50 border-border/50">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Bell className="h-5 w-5" />
              Recent Alerts
            </CardTitle>
            <CardDescription>Active alerts requiring attention</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {recentAlerts.map((alert) => (
                <div
                  key={alert.id}
                  className={`flex items-start gap-4 p-3 rounded-lg ${
                    alert.priority === "high"
                      ? "bg-red-500/10 border border-red-500/20"
                      : alert.priority === "medium"
                      ? "bg-amber-500/10 border border-amber-500/20"
                      : "bg-muted/30"
                  }`}
                >
                  <div
                    className={`p-2 rounded-full ${
                      alert.priority === "high"
                        ? "bg-red-500/20"
                        : alert.priority === "medium"
                        ? "bg-amber-500/20"
                        : "bg-muted"
                    }`}
                  >
                    <Bell
                      className={`h-4 w-4 ${
                        alert.priority === "high"
                          ? "text-red-500"
                          : alert.priority === "medium"
                          ? "text-amber-500"
                          : "text-muted-foreground"
                      }`}
                    />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <Badge
                        variant="outline"
                        className={
                          alert.priority === "high"
                            ? "border-red-500/50 text-red-500"
                            : alert.priority === "medium"
                            ? "border-amber-500/50 text-amber-500"
                            : "border-muted-foreground/50"
                        }
                      >
                        {alert.type}
                      </Badge>
                      <span className="text-xs text-muted-foreground">
                        {alert.time}
                      </span>
                    </div>
                    <p className="text-sm font-medium">{alert.officer}</p>
                    <p className="text-xs text-muted-foreground">
                      {alert.message}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
