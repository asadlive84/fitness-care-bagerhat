'use client'

import { ShieldCheck, Warning } from '@phosphor-icons/react'

export default function SuperAdminAdmins() {
  return (
    <div className="p-4 md:p-6 max-w-2xl mx-auto space-y-5">
      <div className="flex items-center gap-2">
        <ShieldCheck size={22} className="text-primary" />
        <h1 className="text-xl font-bold">Admin Accounts</h1>
      </div>

      <div className="bg-amber-50 border border-amber-200 rounded-2xl p-5 flex gap-3">
        <Warning size={20} className="text-amber-600 shrink-0 mt-0.5" />
        <div>
          <p className="font-semibold text-amber-800 text-sm">Backend endpoint required</p>
          <p className="text-xs text-amber-700 mt-1">
            Admin account management (list, disable, view-only mode, last active) requires a{' '}
            <code className="bg-amber-100 px-1 rounded text-xs">/api/v1/superadmin/admins</code> endpoint.
            This is planned for the next backend step.
          </p>
          <p className="text-xs text-amber-700 mt-2">
            When available, this page will show: admin ID, name, last login, status toggle,
            view-only mode switch, and activity log.
          </p>
        </div>
      </div>

      {/* Placeholder skeleton UI to show the intended layout */}
      <div className="space-y-2 opacity-40 pointer-events-none">
        {['Admin Account 1', 'Admin Account 2'].map((label) => (
          <div key={label} className="bg-card border border-border rounded-xl px-4 py-3 flex items-center gap-3">
            <div className="w-9 h-9 rounded-full bg-blue-100 flex items-center justify-center shrink-0">
              <ShieldCheck size={16} className="text-blue-600" />
            </div>
            <div className="flex-1">
              <p className="text-sm font-medium">{label}</p>
              <p className="text-xs text-muted-foreground">Last active: —</p>
            </div>
            <span className="text-xs bg-green-100 text-green-700 px-2 py-0.5 rounded-full font-semibold">Active</span>
          </div>
        ))}
      </div>
    </div>
  )
}
