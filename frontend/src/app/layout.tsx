import type { Metadata, Viewport } from 'next'
import { Plus_Jakarta_Sans, Outfit, Inter } from 'next/font/google'
import { Providers } from '@/components/providers'
import './globals.css'

const jakarta = Plus_Jakarta_Sans({ variable: '--font-jakarta', subsets: ['latin'], display: 'swap' })
const outfit  = Outfit({ variable: '--font-outfit', subsets: ['latin'], display: 'swap' })
const inter   = Inter({ variable: '--font-inter', subsets: ['latin'], display: 'swap' })

export const metadata: Metadata = {
  title: 'Fitness Care Bagerhat',
  description: 'A calm, premium gym management platform — for members, admins, and superadmins.',
}

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  themeColor: '#1B5E20',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${jakarta.variable} ${outfit.variable} ${inter.variable} h-full`}>
      <body className="h-full antialiased">
        <Providers>{children}</Providers>
      </body>
    </html>
  )
}
