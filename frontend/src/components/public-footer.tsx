import Link from 'next/link'
import { Barbell, Phone, MapPin, FacebookLogo, InstagramLogo } from '@phosphor-icons/react'

export function PublicFooter() {
  return (
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
              <li><Link href="/#services" className="hover:text-white transition">আমাদের সেবা</Link></li>
              <li><Link href="/#plans" className="hover:text-white transition">মেম্বারশিপ প্ল্যান</Link></li>
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
                <a href="tel:+8801309665159" className="hover:text-white transition">
                  01309 665159
                </a>
              </li>
            </ul>
          </div>
        </div>

        <div className="pt-6 flex flex-col sm:flex-row items-center justify-between gap-2 text-white/30 text-[11px]">
          <p>© ২০২৬ ফিটনেস কেয়ার বাগেরহাট। সমস্ত অধিকার সংরক্ষিত।</p>
          <p>ডিজাইন ও ডেভেলপ — চন্দন সাহা নীল</p>
        </div>
      </div>
    </footer>
  )
}
