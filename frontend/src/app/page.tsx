'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { motion } from 'framer-motion'
import {
  Barbell, Heart, Lightning, Users, ChartLineUp,
  Phone, MapPin, ArrowRight, CheckCircle,
  Robot, Trophy, Timer, InstagramLogo, FacebookLogo,
  List, X, Star, AppleLogo,
} from '@phosphor-icons/react'
import { getRole, roleHomePath } from '@/lib/auth'
import { api } from '@/lib/api'

interface Plan {
  id: string
  name: string
  duration_days: number
  default_price: number
  billing_type: string
}

const fade = (delay = 0) => ({
  hidden: { opacity: 0, y: 20 },
  show: { opacity: 1, y: 0, transition: { duration: 0.5, delay } },
})

const SERVICES = [
  {
    icon: <Barbell size={28} weight="duotone" />,
    title: 'পেশাদার প্রশিক্ষণ',
    desc: 'অভিজ্ঞ কোচদের সাথে ব্যক্তিগতকৃত ওয়ার্কআউট প্ল্যান',
  },
  {
    icon: <Robot size={28} weight="duotone" />,
    title: 'AI ডায়েট পরিকল্পনা',
    desc: 'কৃত্রিম বুদ্ধিমত্তার মাধ্যমে তৈরি আপনার পার্ফেক্ট ডায়েট চার্ট',
  },
  {
    icon: <ChartLineUp size={28} weight="duotone" />,
    title: 'অগ্রগতি ট্র্যাকিং',
    desc: 'রিয়েল-টাইমে আপনার ফিটনেস যাত্রা পর্যবেক্ষণ করুন',
  },
  {
    icon: <Users size={28} weight="duotone" />,
    title: 'স্মার্ট সদস্য ব্যবস্থাপনা',
    desc: 'ডিজিটাল বিলিং, মেম্বারশিপ ও রিপোর্ট একটি অ্যাপেই',
  },
  {
    icon: <AppleLogo size={28} weight="duotone" />,
    title: 'পুষ্টি পরামর্শ',
    desc: 'লক্ষ্য অনুযায়ী খাদ্যতালিকা ও ক্যালোরি গণনা',
  },
  {
    icon: <Heart size={28} weight="duotone" />,
    title: 'স্বাস্থ্য পর্যবেক্ষণ',
    desc: 'ওজন, BMI ও সামগ্রিক স্বাস্থ্য ডেটা ট্র্যাক করুন',
  },
]

const STATS = [
  { value: '৫০০+', label: 'সক্রিয় সদস্য' },
  { value: '১০+', label: 'পেশাদার প্রশিক্ষক' },
  { value: '৫', label: 'বছরের অভিজ্ঞতা' },
  { value: '৯৮%', label: 'সদস্য সন্তুষ্টি' },
]


const WHY = [
  { icon: <Lightning size={22} weight="fill" />, text: 'আধুনিক ও পরিষ্কার পরিবেশ' },
  { icon: <Trophy size={22} weight="fill" />, text: 'প্রমাণিত ফলাফল ও সাফল্য' },
  { icon: <Timer size={22} weight="fill" />, text: 'নমনীয় সময়সূচী' },
  { icon: <Star size={22} weight="fill" />, text: 'বিশেষজ্ঞ প্রশিক্ষক দল' },
]

function durationLabel(days: number): string {
  if (days <= 31)  return '/মাস'
  if (days <= 95)  return '/৩ মাস'
  if (days <= 185) return '/৬ মাস'
  return '/বছর'
}

export default function LandingPage() {
  const [dashPath, setDashPath] = useState<string | null>(null)
  const [menuOpen, setMenuOpen] = useState(false)
  const [plans, setPlans]       = useState<Plan[]>([])

  useEffect(() => {
    const role = getRole()
    if (role) setDashPath(roleHomePath(role))
    api.get<{ success: boolean; data: Plan[] }>('/api/v1/plans')
      .then(({ data }) => { if (data.success) setPlans(data.data ?? []) })
      .catch(() => {/* silently ignore — page still works without plans */})
  }, [])

  return (
    <div className="min-h-screen bg-[#F5F7F0] overflow-x-hidden" lang="bn">

      {/* ── Navbar ─────────────────────────────────── */}
      <header className="fixed top-0 inset-x-0 z-50 glass-strong border-b border-white/30">
        <nav className="max-w-6xl mx-auto px-4 h-14 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-lg bg-[#1B5E20] flex items-center justify-center">
              <Barbell size={18} weight="bold" className="text-white" />
            </div>
            <span className="font-bold text-[#1B5E20] text-sm leading-tight">
              ফিটনেস কেয়ার<br />
              <span className="text-xs font-medium text-[#4C7A4F]">বাগেরহাট</span>
            </span>
          </div>

          {/* Desktop nav */}
          <div className="hidden sm:flex items-center gap-6 text-sm font-medium text-[#3a5c3f]">
            <a href="#services" className="hover:text-[#1B5E20]">সেবাসমূহ</a>
            <a href="#plans" className="hover:text-[#1B5E20]">মেম্বারশিপ</a>
            <a href="#contact" className="hover:text-[#1B5E20]">যোগাযোগ</a>
            <Link
              href={dashPath ?? '/login'}
              className="px-4 py-1.5 rounded-full bg-[#1B5E20] text-white text-xs font-semibold hover:bg-[#155218] transition"
            >
              {dashPath ? 'ড্যাশবোর্ড' : 'লগইন করুন'}
            </Link>
          </div>

          {/* Mobile hamburger */}
          <button
            className="sm:hidden p-2 rounded-lg text-[#1B5E20]"
            onClick={() => setMenuOpen(v => !v)}
            aria-label="মেনু"
          >
            {menuOpen ? <X size={22} /> : <List size={22} />}
          </button>
        </nav>

        {/* Mobile menu */}
        {menuOpen && (
          <div className="sm:hidden glass-strong border-t border-white/30 px-4 pb-4 flex flex-col gap-3 text-sm font-medium text-[#3a5c3f]">
            <a href="#services" onClick={() => setMenuOpen(false)} className="py-2 border-b border-[#e0e8e1]">সেবাসমূহ</a>
            <a href="#plans" onClick={() => setMenuOpen(false)} className="py-2 border-b border-[#e0e8e1]">মেম্বারশিপ</a>
            <a href="#contact" onClick={() => setMenuOpen(false)} className="py-2 border-b border-[#e0e8e1]">যোগাযোগ</a>
            <Link
              href={dashPath ?? '/login'}
              className="py-2.5 rounded-full bg-[#1B5E20] text-white text-center text-xs font-semibold"
            >
              {dashPath ? 'ড্যাশবোর্ড' : 'লগইন করুন'}
            </Link>
          </div>
        )}
      </header>

      {/* ── Hero ───────────────────────────────────── */}
      <section className="relative min-h-screen flex flex-col justify-center pt-14 overflow-hidden">
        {/* Background gradient blobs */}
        <div className="absolute inset-0 bg-gradient-to-br from-[#1B5E20] via-[#2E7D32] to-[#1a3d1c]" />
        <div className="absolute top-1/4 -right-24 w-72 h-72 rounded-full bg-[#FF6D00]/10 blur-3xl" />
        <div className="absolute bottom-1/4 -left-16 w-56 h-56 rounded-full bg-white/5 blur-2xl" />

        <div className="relative max-w-6xl mx-auto px-4 py-20 flex flex-col lg:flex-row items-center gap-12">
          {/* Text */}
          <div className="flex-1 text-center lg:text-left">
            <motion.div
              variants={fade(0)}
              initial="hidden"
              animate="show"
              className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/10 border border-white/20 text-white/80 text-xs mb-6"
            >
              <Star size={12} weight="fill" className="text-[#FF6D00]" />
              বাগেরহাটের সেরা ফিটনেস সেন্টার
            </motion.div>

            <motion.h1
              variants={fade(0.1)}
              initial="hidden"
              animate="show"
              className="text-4xl sm:text-5xl lg:text-6xl font-bold text-white leading-tight mb-4"
              style={{ fontFamily: 'system-ui, sans-serif' }}
            >
              শক্তি, স্বাস্থ্য ও<br />
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-[#FF6D00] to-[#ffb300]">
                সুস্থতার পথে
              </span>
            </motion.h1>

            <motion.p
              variants={fade(0.2)}
              initial="hidden"
              animate="show"
              className="text-white/70 text-base sm:text-lg max-w-lg mx-auto lg:mx-0 mb-8 leading-relaxed"
            >
              আধুনিক যন্ত্রপাতি, বিশেষজ্ঞ প্রশিক্ষক এবং AI-চালিত ডায়েট পরিকল্পনা নিয়ে
              আপনার স্বাস্থ্যকর জীবনযাপনের যাত্রা শুরু করুন।
            </motion.p>

            <motion.div
              variants={fade(0.3)}
              initial="hidden"
              animate="show"
              className="flex flex-col sm:flex-row gap-3 justify-center lg:justify-start"
            >
              <Link
                href={dashPath ?? '/login'}
                className="flex items-center justify-center gap-2 px-6 py-3 rounded-full bg-white text-[#1B5E20] font-bold text-sm hover:bg-[#f0f7f0] transition shadow-lg"
              >
                {dashPath ? 'ড্যাশবোর্ডে যান' : 'সদস্য লগইন'}
                <ArrowRight size={16} weight="bold" />
              </Link>
              {!dashPath && (
                <Link
                  href="/register"
                  className="flex items-center justify-center gap-2 px-6 py-3 rounded-full border border-white/30 text-white font-semibold text-sm hover:bg-white/10 transition"
                >
                  নিবন্ধন করুন
                </Link>
              )}
              {dashPath && (
                <a
                  href="#plans"
                  className="flex items-center justify-center gap-2 px-6 py-3 rounded-full border border-white/30 text-white font-semibold text-sm hover:bg-white/10 transition"
                >
                  মেম্বারশিপ দেখুন
                </a>
              )}
            </motion.div>
          </div>

          {/* Feature cards (decorative) */}
          <motion.div
            variants={fade(0.4)}
            initial="hidden"
            animate="show"
            className="flex-shrink-0 grid grid-cols-2 gap-3 w-full max-w-xs"
          >
            {[
              { icon: <Barbell size={20} weight="duotone" />, label: 'ওয়ার্কআউট' },
              { icon: <Robot size={20} weight="duotone" />, label: 'AI ডায়েট' },
              { icon: <ChartLineUp size={20} weight="duotone" />, label: 'ট্র্যাকিং' },
              { icon: <Heart size={20} weight="duotone" />, label: 'সুস্বাস্থ্য' },
            ].map((item, i) => (
              <div key={i} className="glass rounded-2xl p-4 flex flex-col items-center gap-2 text-white/90 text-sm font-medium border border-white/15">
                <span className="text-[#FF6D00]">{item.icon}</span>
                {item.label}
              </div>
            ))}
          </motion.div>
        </div>

        {/* Wave divider */}
        <div className="absolute bottom-0 inset-x-0">
          <svg viewBox="0 0 1440 60" fill="none" xmlns="http://www.w3.org/2000/svg" className="w-full">
            <path d="M0 60H1440V20C1200 60 960 0 720 20C480 40 240 0 0 20V60Z" fill="#F5F7F0" />
          </svg>
        </div>
      </section>

      {/* ── Stats ──────────────────────────────────── */}
      <section className="py-10 bg-[#F5F7F0]">
        <div className="max-w-4xl mx-auto px-4">
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
            {STATS.map((s, i) => (
              <motion.div
                key={i}
                variants={fade(i * 0.1)}
                initial="hidden"
                whileInView="show"
                viewport={{ once: true }}
                className="text-center p-4 rounded-2xl bg-white border border-[#e5ebe6] shadow-sm"
              >
                <div className="text-2xl sm:text-3xl font-bold text-[#1B5E20]">{s.value}</div>
                <div className="text-xs text-[#5E6E62] mt-1">{s.label}</div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Services ───────────────────────────────── */}
      <section id="services" className="py-16 bg-[#F5F7F0]">
        <div className="max-w-6xl mx-auto px-4">
          <motion.div
            variants={fade(0)}
            initial="hidden"
            whileInView="show"
            viewport={{ once: true }}
            className="text-center mb-10"
          >
            <span className="text-xs font-semibold uppercase tracking-widest text-[#4C7A4F]">আমাদের সেবা</span>
            <h2 className="text-2xl sm:text-3xl font-bold text-[#1A2E1F] mt-2">
              সব কিছু একটি প্ল্যাটফর্মে
            </h2>
            <p className="text-sm text-[#5E6E62] mt-2 max-w-md mx-auto">
              ফিটনেস থেকে পুষ্টি — আপনার সুস্থ জীবনের জন্য প্রয়োজনীয় সব সুবিধা
            </p>
          </motion.div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {SERVICES.map((s, i) => (
              <motion.div
                key={i}
                variants={fade(i * 0.08)}
                initial="hidden"
                whileInView="show"
                viewport={{ once: true }}
                className="glass rounded-2xl p-5 hover:shadow-md transition group"
              >
                <div className="w-11 h-11 rounded-xl bg-[#1B5E20]/10 flex items-center justify-center text-[#1B5E20] mb-4 group-hover:bg-[#1B5E20] group-hover:text-white transition">
                  {s.icon}
                </div>
                <h3 className="font-bold text-[#1A2E1F] mb-1 text-sm">{s.title}</h3>
                <p className="text-xs text-[#5E6E62] leading-relaxed">{s.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Why Us ─────────────────────────────────── */}
      <section className="py-14 bg-[#1B5E20]">
        <div className="max-w-6xl mx-auto px-4">
          <div className="flex flex-col lg:flex-row items-center gap-10">
            <motion.div
              variants={fade(0)}
              initial="hidden"
              whileInView="show"
              viewport={{ once: true }}
              className="flex-1 text-center lg:text-left"
            >
              <span className="text-xs font-semibold uppercase tracking-widest text-[#8BC34A]">কেন আমরা?</span>
              <h2 className="text-2xl sm:text-3xl font-bold text-white mt-2 mb-4">
                বাগেরহাটের সবচেয়ে স্মার্ট<br />ফিটনেস অভিজ্ঞতা
              </h2>
              <p className="text-white/70 text-sm leading-relaxed max-w-md mx-auto lg:mx-0">
                প্রযুক্তি ও মানবিক স্পর্শের মিলনে আমরা তৈরি করি এক অনন্য ফিটনেস পরিবেশ
                যেখানে প্রতিটি সদস্য পায় ব্যক্তিগত মনোযোগ ও বিজ্ঞানসম্মত পরামর্শ।
              </p>
            </motion.div>

            <motion.div
              variants={fade(0.2)}
              initial="hidden"
              whileInView="show"
              viewport={{ once: true }}
              className="flex-1 grid grid-cols-1 sm:grid-cols-2 gap-3 w-full max-w-md"
            >
              {WHY.map((w, i) => (
                <div key={i} className="flex items-center gap-3 p-4 rounded-xl bg-white/10 border border-white/15">
                  <span className="text-[#FF6D00] flex-shrink-0">{w.icon}</span>
                  <span className="text-white text-sm font-medium">{w.text}</span>
                </div>
              ))}
            </motion.div>
          </div>
        </div>
      </section>

      {/* ── Plans ──────────────────────────────────── */}
      <section id="plans" className="py-16 bg-[#F5F7F0]">
        <div className="max-w-6xl mx-auto px-4">
          <motion.div
            variants={fade(0)}
            initial="hidden"
            whileInView="show"
            viewport={{ once: true }}
            className="text-center mb-10"
          >
            <span className="text-xs font-semibold uppercase tracking-widest text-[#4C7A4F]">মেম্বারশিপ</span>
            <h2 className="text-2xl sm:text-3xl font-bold text-[#1A2E1F] mt-2">
              আপনার জন্য সঠিক প্ল্যান বেছে নিন
            </h2>
          </motion.div>

          {plans.length === 0 ? (
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              {[0, 1, 2].map((i) => (
                <div key={i} className="rounded-2xl bg-white border border-[#e5ebe6] h-64 animate-pulse" />
              ))}
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              {plans.map((p, i) => {
                const highlight = i === 1 && plans.length >= 3
                return (
                  <motion.div
                    key={p.id}
                    variants={fade(i * 0.1)}
                    initial="hidden"
                    whileInView="show"
                    viewport={{ once: true }}
                    className={`relative rounded-2xl p-6 flex flex-col border transition ${
                      highlight
                        ? 'bg-[#1B5E20] text-white border-[#1B5E20] shadow-xl'
                        : 'bg-white text-[#1A2E1F] border-[#e5ebe6] shadow-sm'
                    }`}
                  >
                    {highlight && (
                      <div className="absolute -top-3 inset-x-0 flex justify-center">
                        <span className="px-3 py-1 bg-[#FF6D00] text-white text-[10px] font-bold rounded-full uppercase tracking-wide">
                          সবচেয়ে জনপ্রিয়
                        </span>
                      </div>
                    )}
                    <div className={`text-xs font-semibold uppercase tracking-wider mb-3 ${highlight ? 'text-[#8BC34A]' : 'text-[#4C7A4F]'}`}>
                      {p.name}
                    </div>
                    <div className="flex items-baseline gap-1 mb-5">
                      <span className="text-3xl font-bold">৳{p.default_price.toLocaleString()}</span>
                      <span className={`text-sm ${highlight ? 'text-white/60' : 'text-[#5E6E62]'}`}>
                        {durationLabel(p.duration_days)}
                      </span>
                    </div>
                    <ul className="space-y-2 flex-1 mb-6">
                      <li className="flex items-center gap-2 text-sm">
                        <CheckCircle size={16} weight="fill" className={highlight ? 'text-[#8BC34A]' : 'text-[#1B5E20]'} />
                        সকল যন্ত্রপাতি ব্যবহার
                      </li>
                      <li className="flex items-center gap-2 text-sm">
                        <CheckCircle size={16} weight="fill" className={highlight ? 'text-[#8BC34A]' : 'text-[#1B5E20]'} />
                        {p.duration_days} দিনের মেম্বারশিপ
                      </li>
                      <li className="flex items-center gap-2 text-sm">
                        <CheckCircle size={16} weight="fill" className={highlight ? 'text-[#8BC34A]' : 'text-[#1B5E20]'} />
                        মোবাইল অ্যাপ অ্যাক্সেস
                      </li>
                    </ul>
                    <Link
                      href="/register"
                      className={`w-full py-2.5 rounded-full text-center text-sm font-bold transition ${
                        highlight
                          ? 'bg-white text-[#1B5E20] hover:bg-[#f0f7f0]'
                          : 'bg-[#1B5E20] text-white hover:bg-[#155218]'
                      }`}
                    >
                      শুরু করুন
                    </Link>
                  </motion.div>
                )
              })}
            </div>
          )}
        </div>
      </section>

      {/* ── Download CTA ───────────────────────────── */}
      <section className="py-14 bg-gradient-to-br from-[#FF6D00] to-[#e65000]">
        <div className="max-w-4xl mx-auto px-4 text-center">
          <motion.div
            variants={fade(0)}
            initial="hidden"
            whileInView="show"
            viewport={{ once: true }}
          >
            <div className="w-14 h-14 rounded-2xl bg-white/20 flex items-center justify-center mx-auto mb-4">
              <Lightning size={28} weight="fill" className="text-white" />
            </div>
            <h2 className="text-2xl sm:text-3xl font-bold text-white mb-3">
              মোবাইল অ্যাপ এখনই ডাউনলোড করুন
            </h2>
            <p className="text-white/80 text-sm mb-6 max-w-md mx-auto">
              যেকোনো সময়, যেকোনো জায়গা থেকে আপনার ফিটনেস ট্র্যাক করুন।
              ডায়েট চার্ট, ওয়ার্কআউট লগ এবং আরও অনেক কিছু হাতের মুঠোয়।
            </p>
            <a
              href="https://drive.google.com/drive/folders/1_rmlQSD9lmjuwAwyQrjNJQ8Mt2xF3XQK"
              className="inline-flex items-center gap-2 px-7 py-3 rounded-full bg-white text-[#e65000] font-bold text-sm hover:bg-[#fff8f5] transition shadow-lg"
            >
              Android APK ডাউনলোড করুন
              <ArrowRight size={16} weight="bold" />
            </a>
          </motion.div>
        </div>
      </section>

      {/* ── Contact / Footer ───────────────────────── */}
      <footer id="contact" className="bg-[#0f2d12] text-white py-12">
        <div className="max-w-6xl mx-auto px-4">
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-8 pb-8 border-b border-white/10">
            {/* Brand */}
            <div>
              <div className="flex items-center gap-2 mb-3">
                <div className="w-8 h-8 rounded-lg bg-[#1B5E20] flex items-center justify-center">
                  <Barbell size={18} weight="bold" className="text-white" />
                </div>
                <span className="font-bold text-white">ফিটনেস কেয়ার বাগেরহাট</span>
              </div>
              <p className="text-white/50 text-xs leading-relaxed">
                বাগেরহাটের প্রিমিয়াম ফিটনেস সেন্টার — আপনার সুস্থ ও সুখী জীবনের অংশীদার।
              </p>
              <div className="flex gap-3 mt-4">
                <a href="#" className="w-8 h-8 rounded-full bg-white/10 flex items-center justify-center hover:bg-[#1B5E20] transition">
                  <FacebookLogo size={16} />
                </a>
                <a href="#" className="w-8 h-8 rounded-full bg-white/10 flex items-center justify-center hover:bg-[#1B5E20] transition">
                  <InstagramLogo size={16} />
                </a>
              </div>
            </div>

            {/* Links */}
            <div>
              <h4 className="font-semibold mb-3 text-sm">দ্রুত লিংক</h4>
              <ul className="space-y-2 text-white/50 text-xs">
                <li><a href="#services" className="hover:text-white transition">আমাদের সেবা</a></li>
                <li><a href="#plans" className="hover:text-white transition">মেম্বারশিপ প্ল্যান</a></li>
                <li><Link href="/login" className="hover:text-white transition">সদস্য লগইন</Link></li>
                <li><a href="https://drive.google.com/drive/folders/1_rmlQSD9lmjuwAwyQrjNJQ8Mt2xF3XQK" className="hover:text-white transition">অ্যাপ ডাউনলোড</a></li>
              </ul>
            </div>

            {/* Contact */}
            <div>
              <h4 className="font-semibold mb-3 text-sm">যোগাযোগ</h4>
              <ul className="space-y-3 text-white/60 text-xs">
                <li className="flex items-start gap-2">
                  <MapPin size={14} className="text-[#FF6D00] mt-0.5 flex-shrink-0" />
                  বাগেরহাট সদর, খুলনা বিভাগ, বাংলাদেশ
                </li>
                <li className="flex items-center gap-2">
                  <Phone size={14} className="text-[#FF6D00] flex-shrink-0" />
                  <a href="tel:+8801700000000" className="hover:text-white transition">
                    +৮৮ ০১৭০০-০০০০০০
                  </a>
                </li>
              </ul>
            </div>
          </div>

          <div className="pt-6 flex flex-col sm:flex-row items-center justify-between gap-2 text-white/30 text-[11px]">
            <p>© ২০২৫ ফিটনেস কেয়ার বাগেরহাট। সমস্ত অধিকার সংরক্ষিত।</p>
            <p>ডিজাইন ও ডেভেলপমেন্ট — ডিজিটাল বাংলাদেশ</p>
          </div>
        </div>
      </footer>
    </div>
  )
}
