"use client"

import { useState } from "react"
import { MapPin, User, Battery, Signal, Clock, Filter } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"

const officers = [
  {
    id: "1",
    name: "Raj Kumar",
    badge: "BADGE-1234",
    status: "active",
    location: { lat: 28.6139, lng: 77.209 },
    area: "Sector 15, Main Market",
    battery: 85,
    signal: "strong",
    lastUpdate: "2 min ago",
  },
  {
    id: "2",
    name: "Amit Singh",
    badge: "BADGE-2345",
    status: "active",
    location: { lat: 28.6229, lng: 77.219 },
    area: "Sector 18, Mall Road",
    battery: 45,
    signal: "strong",
    lastUpdate: "1 min ago",
  },
  {
    id: "3",
    name: "Priya Sharma",
    badge: "BADGE-3456",
    status: "issue",
    location: { lat: 28.6339, lng: 77.229 },
    area: "Gandhi Stadium",
    battery: 12,
    signal: "weak",
    lastUpdate: "5 min ago",
  },
  {
    id: "4",
    name: "Deepak Verma",
    badge: "BADGE-4567",
    status: "active",
    location: { lat: 28.6049, lng: 77.199 },
    area: "Railway Station",
    battery: 92,
    signal: "strong",
    lastUpdate: "30 sec ago",
  },
  {
    id: "5",
    name: "Sunil Yadav",
    badge: "BADGE-5678",
    status: "offline",
    location: { lat: 28.5949, lng: 77.189 },
    area: "Bus Terminal",
    battery: 0,
    signal: "none",
    lastUpdate: "15 min ago",
  },
]

export function MonitoringView() {
  const [selectedOfficer, setSelectedOfficer] = useState<string | null>(null)
  const [statusFilter, setStatusFilter] = useState<string>("all")

  const filteredOfficers =
    statusFilter === "all"
      ? officers
      : officers.filter((o) => o.status === statusFilter)

  return (
    <div className="space-y-6">
      {/* Controls */}
      <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
        <div className="flex items-center gap-2">
          <Filter className="h-4 w-4 text-muted-foreground" />
          <Select value={statusFilter} onValueChange={setStatusFilter}>
            <SelectTrigger className="w-40">
              <SelectValue placeholder="Filter by status" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Officers</SelectItem>
              <SelectItem value="active">Active</SelectItem>
              <SelectItem value="issue">Has Issues</SelectItem>
              <SelectItem value="offline">Offline</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <div className="flex items-center gap-2 text-sm text-muted-foreground">
          <div className="flex items-center gap-1">
            <span className="h-2 w-2 rounded-full bg-emerald-500" />
            Active ({officers.filter((o) => o.status === "active").length})
          </div>
          <div className="flex items-center gap-1">
            <span className="h-2 w-2 rounded-full bg-amber-500" />
            Issue ({officers.filter((o) => o.status === "issue").length})
          </div>
          <div className="flex items-center gap-1">
            <span className="h-2 w-2 rounded-full bg-red-500" />
            Offline ({officers.filter((o) => o.status === "offline").length})
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Map Area */}
        <Card className="lg:col-span-2 bg-card/50 border-border/50">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <MapPin className="h-5 w-5" />
              Live Map
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="aspect-[16/10] rounded-lg bg-muted/50 flex items-center justify-center relative overflow-hidden">
              {/* Simulated Map Background */}
              <div className="absolute inset-0 bg-gradient-to-br from-slate-800 to-slate-900" />
              <div className="absolute inset-0 opacity-20">
                {/* Grid lines */}
                {[...Array(10)].map((_, i) => (
                  <div
                    key={`h-${i}`}
                    className="absolute h-px bg-slate-600 w-full"
                    style={{ top: `${i * 10}%` }}
                  />
                ))}
                {[...Array(10)].map((_, i) => (
                  <div
                    key={`v-${i}`}
                    className="absolute w-px bg-slate-600 h-full"
                    style={{ left: `${i * 10}%` }}
                  />
                ))}
              </div>

              {/* Officer Markers */}
              {filteredOfficers.map((officer, index) => (
                <button
                  key={officer.id}
                  onClick={() => setSelectedOfficer(officer.id)}
                  className={`absolute transition-transform hover:scale-125 ${
                    selectedOfficer === officer.id ? "scale-125 z-10" : ""
                  }`}
                  style={{
                    left: `${20 + index * 15}%`,
                    top: `${30 + (index % 3) * 20}%`,
                  }}
                >
                  <div
                    className={`relative p-2 rounded-full ${
                      officer.status === "active"
                        ? "bg-emerald-500"
                        : officer.status === "issue"
                        ? "bg-amber-500"
                        : "bg-red-500"
                    }`}
                  >
                    <User className="h-4 w-4 text-white" />
                    {selectedOfficer === officer.id && (
                      <span className="absolute -bottom-6 left-1/2 -translate-x-1/2 text-xs whitespace-nowrap bg-background/90 px-2 py-1 rounded">
                        {officer.name}
                      </span>
                    )}
                  </div>
                </button>
              ))}

              {/* Map Legend */}
              <div className="absolute bottom-4 left-4 bg-background/80 backdrop-blur p-3 rounded-lg text-xs space-y-1">
                <p className="font-medium mb-2">Legend</p>
                <div className="flex items-center gap-2">
                  <span className="h-3 w-3 rounded-full bg-emerald-500" />
                  Active
                </div>
                <div className="flex items-center gap-2">
                  <span className="h-3 w-3 rounded-full bg-amber-500" />
                  Issue
                </div>
                <div className="flex items-center gap-2">
                  <span className="h-3 w-3 rounded-full bg-red-500" />
                  Offline
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Officer List */}
        <Card className="bg-card/50 border-border/50">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <User className="h-5 w-5" />
              Officers ({filteredOfficers.length})
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3 max-h-[500px] overflow-y-auto">
              {filteredOfficers.map((officer) => (
                <button
                  key={officer.id}
                  onClick={() => setSelectedOfficer(officer.id)}
                  className={`w-full text-left p-3 rounded-lg transition-colors ${
                    selectedOfficer === officer.id
                      ? "bg-primary/10 border border-primary/50"
                      : "bg-muted/30 hover:bg-muted/50"
                  }`}
                >
                  <div className="flex items-start justify-between mb-2">
                    <div>
                      <p className="font-medium">{officer.name}</p>
                      <p className="text-xs text-muted-foreground">
                        {officer.badge}
                      </p>
                    </div>
                    <Badge
                      variant="outline"
                      className={
                        officer.status === "active"
                          ? "border-emerald-500/50 text-emerald-500"
                          : officer.status === "issue"
                          ? "border-amber-500/50 text-amber-500"
                          : "border-red-500/50 text-red-500"
                      }
                    >
                      {officer.status}
                    </Badge>
                  </div>
                  <p className="text-xs text-muted-foreground mb-2 flex items-center gap-1">
                    <MapPin className="h-3 w-3" />
                    {officer.area}
                  </p>
                  <div className="flex items-center gap-3 text-xs text-muted-foreground">
                    <span className="flex items-center gap-1">
                      <Battery
                        className={`h-3 w-3 ${
                          officer.battery < 20
                            ? "text-red-500"
                            : officer.battery < 50
                            ? "text-amber-500"
                            : "text-emerald-500"
                        }`}
                      />
                      {officer.battery}%
                    </span>
                    <span className="flex items-center gap-1">
                      <Signal
                        className={`h-3 w-3 ${
                          officer.signal === "strong"
                            ? "text-emerald-500"
                            : officer.signal === "weak"
                            ? "text-amber-500"
                            : "text-red-500"
                        }`}
                      />
                      {officer.signal}
                    </span>
                    <span className="flex items-center gap-1">
                      <Clock className="h-3 w-3" />
                      {officer.lastUpdate}
                    </span>
                  </div>
                </button>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
