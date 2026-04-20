"use client";

import {
  ArrowRight,
  BadgeCheck,
  Crown,
  MessageCircle,
  ShieldCheck,
  Sparkles,
  Users,
} from "lucide-react";
import { Calistoga, Inter, JetBrains_Mono } from "next/font/google";

const calistoga = Calistoga({
  subsets: ["latin", "vietnamese"],
  weight: "400",
  variable: "--font-calistoga",
});

const inter = Inter({
  subsets: ["latin", "vietnamese"],
  weight: ["400", "500", "600", "700"],
  variable: "--font-inter-ui",
});

const jetbrainsMono = JetBrains_Mono({
  subsets: ["latin", "vietnamese"],
  weight: ["400", "500"],
  variable: "--font-jetbrains-mono",
});

const appStoreUrl = "https://apps.apple.com/vn/app/mimate/id6759095989";

const featureCards = [
  {
    icon: Users,
    title: "Kết nối theo sở thích",
    description:
      "Tìm người phù hợp để đi cà phê, xem phim, chơi thể thao, du lịch và nhiều hoạt động khác.",
  },
  {
    icon: MessageCircle,
    title: "Mời hoạt động nhanh",
    description:
      "Gửi lời mời, trò chuyện trong app và thống nhất lịch hẹn chỉ trong vài bước đơn giản.",
  },
  {
    icon: ShieldCheck,
    title: "An toàn là ưu tiên",
    description:
      "Xác thực hồ sơ, báo cáo - chặn người dùng, kiểm duyệt nội dung và nút SOS trong hoạt động.",
  },
  {
    icon: Crown,
    title: "Premium qua Apple IAP",
    description:
      "Gói Premium tùy chọn qua In-App Purchase để tăng hiển thị, thêm lời mời và huy hiệu hồ sơ.",
  },
];

const stats = [
  { label: "Mục tiêu", value: "Social Activity", detail: "Kết nối theo hoạt động" },
  { label: "Mô hình", value: "0đ giữa người dùng", detail: "Không thanh toán user-user" },
  { label: "Monetization", value: "Apple IAP", detail: "Premium tùy chọn" },
  { label: "Nền tảng", value: "App Store", detail: "MiMate đã live" },
];

export default function HomePage() {
  return (
    <main
      className={`${inter.variable} ${calistoga.variable} ${jetbrainsMono.variable} bg-[#FAFAFA] text-[#0F172A]`}
    >
      <style jsx global>{`
        .landing-display {
          font-family: var(--font-calistoga), Georgia, serif;
        }

        .landing-ui {
          font-family: var(--font-inter-ui), system-ui, sans-serif;
        }

        .landing-mono {
          font-family: var(--font-jetbrains-mono), monospace;
        }

        .landing-gradient-text {
          background: linear-gradient(to right, #0052ff, #4d7cff);
          -webkit-background-clip: text;
          background-clip: text;
          color: transparent;
        }

        .landing-dot-pattern {
          background-image: radial-gradient(circle, rgba(255, 255, 255, 0.16) 1px, transparent 1px);
          background-size: 32px 32px;
        }

        .landing-pulse {
          animation: landingPulse 2s ease-in-out infinite;
        }

        .landing-rotate {
          animation: landingRotate 60s linear infinite;
        }

        .landing-float-slow {
          animation: landingFloat 5s ease-in-out infinite;
        }

        .landing-float-fast {
          animation: landingFloat 4s ease-in-out infinite reverse;
        }

        @keyframes landingPulse {
          0%,
          100% {
            opacity: 1;
            transform: scale(1);
          }
          50% {
            opacity: 0.72;
            transform: scale(1.3);
          }
        }

        @keyframes landingRotate {
          from {
            transform: rotate(0deg);
          }
          to {
            transform: rotate(360deg);
          }
        }

        @keyframes landingFloat {
          0%,
          100% {
            transform: translateY(0px);
          }
          50% {
            transform: translateY(-10px);
          }
        }

        @media (prefers-reduced-motion: reduce) {
          .landing-pulse,
          .landing-rotate,
          .landing-float-slow,
          .landing-float-fast {
            animation: none !important;
          }
        }
      `}</style>

      <section className="relative overflow-hidden border-b border-[#E2E8F0]">
        <div className="pointer-events-none absolute -right-20 top-16 h-80 w-80 rounded-full bg-[#0052FF]/10 blur-[120px]" />
        <div className="pointer-events-none absolute -left-20 bottom-0 h-72 w-72 rounded-full bg-[#4D7CFF]/8 blur-[130px]" />

        <div className="mx-auto flex w-full max-w-6xl items-center justify-between px-6 py-6 md:px-8">
          <div className="flex items-center gap-3">
            <div className="inline-flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-[#0052FF] to-[#4D7CFF] text-white shadow-[0_8px_24px_rgba(0,82,255,0.35)]">
              <Sparkles className="h-5 w-5" />
            </div>
            <div>
              <p className="landing-display text-2xl tracking-tight">MiMate</p>
              <p className="landing-mono text-[11px] uppercase tracking-[0.16em] text-[#64748B]">
                Social Activity App
              </p>
            </div>
          </div>

          <a
            href={appStoreUrl}
            target="_blank"
            rel="noreferrer"
            className="group inline-flex h-11 items-center justify-center rounded-xl bg-gradient-to-r from-[#0052FF] to-[#4D7CFF] px-5 text-sm font-semibold text-white shadow-[0_4px_14px_rgba(0,82,255,0.25)] transition-all duration-200 hover:-translate-y-0.5 hover:brightness-110 hover:shadow-[0_8px_24px_rgba(0,82,255,0.35)]"
          >
            Tải trên App Store
            <ArrowRight className="ml-2 h-4 w-4 transition-transform duration-200 group-hover:translate-x-1" />
          </a>
        </div>

        <div className="mx-auto grid w-full max-w-6xl grid-cols-1 items-center gap-12 px-6 pb-24 pt-10 md:px-8 lg:grid-cols-[1.1fr_0.9fr] lg:pb-32 lg:pt-14">
          <div>
            <div className="mb-6 inline-flex items-center gap-3 rounded-full border border-[#0052FF]/30 bg-[#0052FF]/5 px-5 py-2">
              <span className="landing-pulse h-2 w-2 rounded-full bg-[#0052FF]" />
              <span className="landing-mono text-xs uppercase tracking-[0.15em] text-[#0052FF]">
                Now Live On Apple Store
              </span>
            </div>

            <h1 className="landing-display text-[2.75rem] leading-[1.06] tracking-[-0.02em] sm:text-6xl xl:text-[5.2rem]">
              MiMate giúp bạn
              <br />
              <span className="relative inline-block landing-gradient-text">
                kết nối đúng vibe
                <span className="absolute -bottom-1 left-0 h-3 w-full rounded-sm bg-gradient-to-r from-[#0052FF]/15 to-[#4D7CFF]/10 md:-bottom-2 md:h-4" />
              </span>
            </h1>

            <p className="mt-7 max-w-2xl text-lg leading-relaxed text-[#475569] md:text-xl">
              MiMate là nền tảng hoạt động xã hội, nơi bạn tìm người có cùng sở thích để đi cà phê,
              xem phim, chơi thể thao hoặc tham gia sự kiện. Tất cả hoạt động giữa người dùng đều miễn
              phí, không có thanh toán user-to-user.
            </p>

            <div className="mt-10 flex flex-col gap-4 sm:flex-row">
              <a
                href={appStoreUrl}
                target="_blank"
                rel="noreferrer"
                className="group inline-flex h-14 items-center justify-center rounded-xl bg-gradient-to-r from-[#0052FF] to-[#4D7CFF] px-7 text-base font-semibold text-white shadow-[0_4px_14px_rgba(0,82,255,0.25)] transition-all duration-200 hover:-translate-y-0.5 hover:brightness-110 hover:shadow-[0_8px_24px_rgba(0,82,255,0.35)] active:scale-[0.98]"
              >
                Mở App Store và tải MiMate
                <ArrowRight className="ml-2 h-5 w-5 transition-transform duration-200 group-hover:translate-x-1" />
              </a>
              <a
                href="/support"
                className="inline-flex h-14 items-center justify-center rounded-xl border border-[#E2E8F0] bg-white px-7 text-base font-semibold text-[#0F172A] transition-all duration-200 hover:-translate-y-0.5 hover:border-[#0052FF]/40 hover:bg-[#F8FAFF] hover:shadow-lg"
              >
                Xem trung tâm hỗ trợ
              </a>
            </div>

            <div className="mt-8 rounded-2xl border border-[#E2E8F0] bg-white p-5 shadow-md">
              <p className="landing-mono text-xs uppercase tracking-[0.12em] text-[#64748B]">MiMate Promise</p>
              <p className="mt-2 text-sm leading-relaxed text-[#475569]">
                MiMate tập trung vào kết nối hoạt động xã hội lành mạnh, minh bạch tính năng và đặt an toàn
                người dùng làm ưu tiên hàng đầu.
              </p>
            </div>
          </div>

          <div className="relative hidden lg:block">
            <div className="relative mx-auto aspect-square max-w-[470px] rounded-[2.2rem] border border-[#E2E8F0] bg-white shadow-[0_20px_25px_rgba(15,23,42,0.1)]">
              <div className="landing-rotate absolute left-1/2 top-1/2 h-[88%] w-[88%] -translate-x-1/2 -translate-y-1/2 rounded-full border border-dashed border-[#0052FF]/30" />
              <div className="absolute inset-5 rounded-[1.5rem] bg-[radial-gradient(circle_at_30%_20%,rgba(0,82,255,0.13),transparent_50%),radial-gradient(circle_at_70%_70%,rgba(77,124,255,0.13),transparent_45%)]" />

              <div className="landing-float-slow absolute left-8 top-10 w-[70%] rounded-2xl border border-[#E2E8F0] bg-white/95 p-4 shadow-xl backdrop-blur-sm">
                <p className="text-xs font-semibold uppercase tracking-[0.12em] text-[#64748B]">Hobbies</p>
                <p className="mt-2 text-base font-semibold text-[#0F172A]">Coffee, Sports, Movies, Travel</p>
              </div>

              <div className="landing-float-fast absolute bottom-12 right-8 w-[62%] rounded-2xl border border-[#0052FF]/20 bg-white p-4 shadow-[0_20px_25px_rgba(0,82,255,0.18)]">
                <p className="text-xs font-semibold uppercase tracking-[0.12em] text-[#64748B]">Premium</p>
                <p className="mt-2 text-base font-semibold text-[#0F172A]">Priority visibility + more invites</p>
              </div>

              <div className="absolute bottom-8 left-8 grid grid-cols-3 gap-2">
                {Array.from({ length: 9 }).map((_, index) => (
                  <span
                    key={index}
                    className="h-2.5 w-2.5 rounded-full bg-[#0052FF]/40"
                  />
                ))}
              </div>

              <div className="absolute right-7 top-7 h-16 w-16 rounded-2xl bg-[#0052FF] shadow-[0_14px_30px_rgba(0,82,255,0.35)]" />
            </div>
          </div>
        </div>
      </section>

      <section className="relative overflow-hidden bg-[#0F172A] py-24 text-white md:py-28">
        <div className="landing-dot-pattern absolute inset-0 opacity-40" />
        <div className="pointer-events-none absolute -left-20 top-10 h-64 w-64 rounded-full bg-[#0052FF]/20 blur-[140px]" />
        <div className="pointer-events-none absolute -right-16 bottom-0 h-72 w-72 rounded-full bg-[#4D7CFF]/20 blur-[150px]" />

        <div className="relative mx-auto grid w-full max-w-6xl grid-cols-2 gap-8 px-6 md:grid-cols-4 md:px-8">
          {stats.map((item) => (
            <article key={item.label} className="border-l border-white/15 pl-4 md:pl-5">
              <p className="landing-mono text-[11px] uppercase tracking-[0.16em] text-white/60">{item.label}</p>
              <p className="mt-2 text-2xl font-semibold tracking-tight md:text-3xl">{item.value}</p>
              <p className="mt-2 text-sm text-white/70">{item.detail}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="py-24 md:py-32">
        <div className="mx-auto w-full max-w-6xl px-6 md:px-8">
          <div className="mb-6 inline-flex items-center gap-3 rounded-full border border-[#0052FF]/30 bg-[#0052FF]/5 px-5 py-2">
            <span className="h-2 w-2 rounded-full bg-[#0052FF]" />
            <span className="landing-mono text-xs uppercase tracking-[0.15em] text-[#0052FF]">Core Features</span>
          </div>

          <h2 className="landing-display max-w-3xl text-4xl leading-tight sm:text-5xl">
            Trải nghiệm kết nối
            <span className="landing-gradient-text"> hiện đại và an toàn</span>
          </h2>

          <p className="mt-5 max-w-3xl text-lg leading-relaxed text-[#475569]">
            Thiết kế sản phẩm tập trung vào clarity: ít nhiễu, thao tác nhanh, nhưng vẫn có chiều sâu với
            hệ thống xác thực và kiểm duyệt để người dùng yên tâm khi tham gia hoạt động ngoài đời thực.
          </p>

          <div className="mt-12 grid gap-6 md:grid-cols-2">
            {featureCards.map((feature, index) => {
              const Icon = feature.icon;

              return (
                <article
                  key={feature.title}
                  className={`group relative overflow-hidden rounded-2xl border border-[#E2E8F0] bg-white p-7 shadow-md transition-all duration-300 hover:-translate-y-1 hover:shadow-xl ${
                    index === 1 ? "md:-mt-6" : ""
                  }`}
                >
                  <div className="absolute inset-0 bg-gradient-to-br from-[#0052FF]/[0.03] to-transparent opacity-0 transition-opacity duration-300 group-hover:opacity-100" />
                  <div className="relative">
                    <div className="mb-5 inline-flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br from-[#0052FF] to-[#4D7CFF] text-white shadow-[0_8px_18px_rgba(0,82,255,0.28)] transition-transform duration-300 group-hover:scale-110">
                      <Icon className="h-5 w-5" />
                    </div>
                    <h3 className="text-xl font-semibold tracking-[-0.01em] text-[#0F172A]">{feature.title}</h3>
                    <p className="mt-3 text-base leading-relaxed text-[#64748B]">{feature.description}</p>
                  </div>
                </article>
              );
            })}
          </div>
        </div>
      </section>

      <section className="border-y border-[#E2E8F0] bg-[#F8FAFC] py-24 md:py-32">
        <div className="mx-auto grid w-full max-w-6xl grid-cols-1 gap-10 px-6 md:px-8 lg:grid-cols-[1.2fr_0.8fr] lg:items-center">
          <div>
            <div className="mb-6 inline-flex items-center gap-3 rounded-full border border-[#0052FF]/30 bg-[#0052FF]/5 px-5 py-2">
              <span className="landing-pulse h-2 w-2 rounded-full bg-[#0052FF]" />
              <span className="landing-mono text-xs uppercase tracking-[0.15em] text-[#0052FF]">How It Works</span>
            </div>

            <h2 className="landing-display text-4xl leading-tight sm:text-5xl">
              3 bước để bắt đầu hoạt động cùng
              <span className="landing-gradient-text"> cộng đồng MiMate</span>
            </h2>

            <div className="mt-10 space-y-6">
              <article className="rounded-2xl border border-[#E2E8F0] bg-white p-6 shadow-sm">
                <p className="landing-mono text-xs uppercase tracking-[0.15em] text-[#0052FF]">Step 01</p>
                <h3 className="mt-2 text-xl font-semibold text-[#0F172A]">Khám phá hồ sơ cùng sở thích</h3>
                <p className="mt-2 text-[#64748B]">Xem hoạt động yêu thích và chọn người có vibe phù hợp với bạn.</p>
              </article>
              <article className="rounded-2xl border border-[#E2E8F0] bg-white p-6 shadow-sm">
                <p className="landing-mono text-xs uppercase tracking-[0.15em] text-[#0052FF]">Step 02</p>
                <h3 className="mt-2 text-xl font-semibold text-[#0F172A]">Gửi lời mời và chat trong app</h3>
                <p className="mt-2 text-[#64748B]">Chốt địa điểm, thời gian và chuẩn bị cho một buổi gặp mặt thoải mái.</p>
              </article>
              <article className="rounded-2xl border border-[#E2E8F0] bg-white p-6 shadow-sm">
                <p className="landing-mono text-xs uppercase tracking-[0.15em] text-[#0052FF]">Step 03</p>
                <h3 className="mt-2 text-xl font-semibold text-[#0F172A]">Tham gia hoạt động và đánh giá</h3>
                <p className="mt-2 text-[#64748B]">Báo cáo/chặn luôn sẵn sàng nếu cần để giữ cộng đồng văn minh và an toàn.</p>
              </article>
            </div>
          </div>

          <aside className="rounded-tl-[4rem] rounded-br-[4rem] border border-[#0052FF]/25 bg-gradient-to-br from-[#0052FF] to-[#4D7CFF] p-[2px] shadow-[0_20px_40px_rgba(0,82,255,0.22)]">
            <div className="h-full rounded-tl-[3.85rem] rounded-br-[3.85rem] bg-white p-8">
              <p className="landing-mono text-xs uppercase tracking-[0.15em] text-[#0052FF]">Safety Stack</p>
              <h3 className="mt-3 text-2xl font-semibold tracking-tight text-[#0F172A]">Bảo vệ người dùng chủ động</h3>
              <ul className="mt-5 space-y-4 text-[#475569]">
                <li className="flex items-start gap-3">
                  <BadgeCheck className="mt-0.5 h-5 w-5 text-[#0052FF]" />
                  Xác thực selfie/liveness cho hồ sơ.
                </li>
                <li className="flex items-start gap-3">
                  <BadgeCheck className="mt-0.5 h-5 w-5 text-[#0052FF]" />
                  Cơ chế báo cáo và chặn người dùng ngay trong ứng dụng.
                </li>
                <li className="flex items-start gap-3">
                  <BadgeCheck className="mt-0.5 h-5 w-5 text-[#0052FF]" />
                  Nút SOS cho tình huống khẩn cấp khi đang hoạt động.
                </li>
                <li className="flex items-start gap-3">
                  <BadgeCheck className="mt-0.5 h-5 w-5 text-[#0052FF]" />
                  Kiểm duyệt nội dung tin nhắn và ảnh để giảm hành vi lạm dụng.
                </li>
              </ul>
            </div>
          </aside>
        </div>
      </section>

      <section className="relative overflow-hidden bg-[#0F172A] py-24 text-white md:py-28">
        <div className="landing-dot-pattern absolute inset-0 opacity-35" />
        <div className="pointer-events-none absolute left-1/2 top-0 h-64 w-64 -translate-x-1/2 rounded-full bg-[#0052FF]/20 blur-[140px]" />

        <div className="relative mx-auto w-full max-w-4xl px-6 text-center md:px-8">
          <div className="mb-6 inline-flex items-center gap-3 rounded-full border border-white/20 bg-white/5 px-5 py-2">
            <span className="landing-pulse h-2 w-2 rounded-full bg-[#4D7CFF]" />
            <span className="landing-mono text-xs uppercase tracking-[0.15em] text-white/90">Available Now</span>
          </div>

          <h2 className="landing-display text-4xl leading-tight sm:text-5xl md:text-6xl">
            Tải MiMate trên
            <span className="landing-gradient-text"> Apple Store</span>
          </h2>

          <p className="mx-auto mt-6 max-w-2xl text-lg leading-relaxed text-white/75">
            Bắt đầu kết nối theo sở thích, tham gia hoạt động miễn phí và trải nghiệm hệ thống social có
            kiểm soát an toàn rõ ràng.
          </p>

          <div className="mt-10 flex flex-col items-center justify-center gap-4 sm:flex-row">
            <a
              href={appStoreUrl}
              target="_blank"
              rel="noreferrer"
              className="group inline-flex h-14 w-full items-center justify-center rounded-xl bg-gradient-to-r from-[#0052FF] to-[#4D7CFF] px-7 text-base font-semibold text-white shadow-[0_4px_14px_rgba(0,82,255,0.25)] transition-all duration-200 hover:-translate-y-0.5 hover:brightness-110 hover:shadow-[0_8px_24px_rgba(0,82,255,0.35)] active:scale-[0.98] sm:w-auto"
            >
              Tải MiMate ngay
              <ArrowRight className="ml-2 h-5 w-5 transition-transform duration-200 group-hover:translate-x-1" />
            </a>
            <a
              href="/terms-of-service"
              className="inline-flex h-14 w-full items-center justify-center rounded-xl border border-white/25 bg-white/5 px-7 text-base font-semibold text-white transition-all duration-200 hover:-translate-y-0.5 hover:bg-white/10 sm:w-auto"
            >
              Điều khoản sử dụng
            </a>
          </div>
        </div>
      </section>
    </main>
  );
}
