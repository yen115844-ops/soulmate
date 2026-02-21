"use client";

import { useEffect, useState } from "react";

// Simple star component for ratings
function StarIcon({ filled }: { filled: boolean }) {
  return (
    <svg
      width="16"
      height="16"
      viewBox="0 0 24 24"
      fill={filled ? "#FBBF24" : "none"}
      stroke={filled ? "#FBBF24" : "#D1D5DB"}
      strokeWidth="2"
    >
      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
    </svg>
  );
}

function VerifiedBadge() {
  return (
    <svg
      width="20"
      height="20"
      viewBox="0 0 24 24"
      fill="#3B82F6"
      className="inline-block ml-1"
    >
      <path d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
    </svg>
  );
}

interface PartnerProfileViewProps {
  partnerId: string;
  name: string;
  avatarUrl: string;
  coverUrl: string;
  bio: string;
  location: string;
  rating: number;
  reviewCount: number;
  completedBookings: number;
  hourlyRate: number;
  isVerified: boolean;
  isAvailable: boolean;
  gallery: string[];
  services: string[];
  interests: string[];
  talents: string[];
}

function formatCredits(amount: number): string {
  if (amount >= 1_000_000) {
    return `${(amount / 1_000_000).toFixed(amount % 1_000_000 === 0 ? 0 : 1)}M`;
  }
  if (amount >= 1_000) {
    return `${(amount / 1_000).toFixed(0)}K`;
  }
  return amount.toLocaleString("vi-VN");
}

export default function PartnerProfileView({
  partnerId,
  name,
  avatarUrl,
  coverUrl,
  bio,
  location,
  rating,
  reviewCount,
  completedBookings,
  hourlyRate,
  isVerified,
  isAvailable,
  gallery,
  services,
  interests,
  talents,
}: PartnerProfileViewProps) {
  const [isMobile, setIsMobile] = useState(false);

  useEffect(() => {
    // Check if user is on mobile
    const ua = navigator.userAgent;
    setIsMobile(/iPhone|iPad|iPod|Android/i.test(ua));
  }, []);

  const deepLinkUrl = `matesocial://partner/${partnerId}`;
  // App store URLs - TODO: replace with actual URLs when published
  const appStoreUrl = "https://apps.apple.com/app/mate-social/id000000000";
  const playStoreUrl =
    "https://play.google.com/store/apps/details?id=soulmate.vn";

  const handleOpenInApp = () => {
    // Try to open the app with custom scheme
    window.location.href = deepLinkUrl;

    // Fallback: if app is not installed, redirect to store after a delay
    setTimeout(() => {
      const ua = navigator.userAgent;
      if (/iPhone|iPad|iPod/i.test(ua)) {
        window.location.href = appStoreUrl;
      } else if (/Android/i.test(ua)) {
        window.location.href = playStoreUrl;
      }
    }, 2000);
  };

  const starCount = Math.round(rating);

  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-50 to-white">
      {/* Cover / Header */}
      <div className="relative h-56 sm:h-72 bg-gradient-to-br from-indigo-500 via-purple-500 to-pink-500 overflow-hidden">
        {coverUrl && (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={coverUrl}
            alt=""
            className="absolute inset-0 w-full h-full object-cover opacity-60"
          />
        )}
        <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />

        {/* Mate Social branding */}
        <div className="absolute top-4 left-4 sm:top-6 sm:left-6">
          <h2 className="text-white/90 text-lg font-bold tracking-wide">
            Mate Social
          </h2>
        </div>

        {/* Availability badge */}
        {isAvailable && (
          <div className="absolute top-4 right-4 sm:top-6 sm:right-6">
            <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-green-500/20 backdrop-blur-sm border border-green-400/30 text-green-100 text-xs font-medium">
              <span className="w-2 h-2 rounded-full bg-green-400 animate-pulse" />
              Đang hoạt động
            </span>
          </div>
        )}
      </div>

      {/* Profile Card */}
      <div className="max-w-lg mx-auto px-4 -mt-20 relative z-10 pb-32">
        {/* Avatar */}
        <div className="flex justify-center mb-4">
          <div className="w-28 h-28 rounded-full border-4 border-white shadow-xl overflow-hidden bg-gray-200">
            {avatarUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={avatarUrl}
                alt={name}
                className="w-full h-full object-cover"
              />
            ) : (
              <div className="w-full h-full flex items-center justify-center text-gray-400 text-3xl font-bold">
                {name.charAt(0).toUpperCase()}
              </div>
            )}
          </div>
        </div>

        {/* Name & Verified */}
        <div className="text-center mb-2">
          <h1 className="text-2xl font-bold text-gray-900 inline-flex items-center gap-1">
            {name}
            {isVerified && <VerifiedBadge />}
          </h1>
          {location && (
            <p className="text-sm text-gray-500 mt-1">📍 {location}</p>
          )}
        </div>

        {/* Stats Row */}
        <div className="flex justify-center gap-8 my-6">
          <div className="text-center">
            <div className="flex items-center justify-center gap-0.5 mb-1">
              {[1, 2, 3, 4, 5].map((i) => (
                <StarIcon key={i} filled={i <= starCount} />
              ))}
            </div>
            <p className="text-xs text-gray-500">
              {rating.toFixed(1)} ({reviewCount} đánh giá)
            </p>
          </div>
          <div className="text-center">
            <p className="text-xl font-bold text-gray-900">
              {completedBookings}
            </p>
            <p className="text-xs text-gray-500">Lượt đặt</p>
          </div>
          <div className="text-center">
            <p className="text-xl font-bold text-indigo-600">
              {formatCredits(hourlyRate)} Credits
            </p>
            <p className="text-xs text-gray-500">/giờ</p>
          </div>
        </div>

        {/* Bio */}
        {bio && (
          <div className="bg-white rounded-2xl p-4 shadow-sm border border-gray-100 mb-4">
            <h3 className="text-sm font-semibold text-gray-700 mb-2">
              Giới thiệu
            </h3>
            <p className="text-sm text-gray-600 leading-relaxed">{bio}</p>
          </div>
        )}

        {/* Services */}
        {services.length > 0 && (
          <div className="bg-white rounded-2xl p-4 shadow-sm border border-gray-100 mb-4">
            <h3 className="text-sm font-semibold text-gray-700 mb-3">
              Dịch vụ
            </h3>
            <div className="flex flex-wrap gap-2">
              {services.map((service, i) => (
                <span
                  key={i}
                  className="px-3 py-1.5 rounded-full bg-indigo-50 text-indigo-700 text-xs font-medium"
                >
                  {service}
                </span>
              ))}
            </div>
          </div>
        )}

        {/* Interests & Talents */}
        {(interests.length > 0 || talents.length > 0) && (
          <div className="bg-white rounded-2xl p-4 shadow-sm border border-gray-100 mb-4">
            {interests.length > 0 && (
              <>
                <h3 className="text-sm font-semibold text-gray-700 mb-3">
                  Sở thích
                </h3>
                <div className="flex flex-wrap gap-2 mb-3">
                  {interests.map((interest, i) => (
                    <span
                      key={i}
                      className="px-3 py-1.5 rounded-full bg-pink-50 text-pink-700 text-xs font-medium"
                    >
                      {interest}
                    </span>
                  ))}
                </div>
              </>
            )}
            {talents.length > 0 && (
              <>
                <h3 className="text-sm font-semibold text-gray-700 mb-3">
                  Tài năng
                </h3>
                <div className="flex flex-wrap gap-2">
                  {talents.map((talent, i) => (
                    <span
                      key={i}
                      className="px-3 py-1.5 rounded-full bg-amber-50 text-amber-700 text-xs font-medium"
                    >
                      {talent}
                    </span>
                  ))}
                </div>
              </>
            )}
          </div>
        )}

        {/* Gallery */}
        {gallery.length > 0 && (
          <div className="bg-white rounded-2xl p-4 shadow-sm border border-gray-100 mb-4">
            <h3 className="text-sm font-semibold text-gray-700 mb-3">
              Ảnh ({gallery.length})
            </h3>
            <div className="grid grid-cols-3 gap-2">
              {gallery.slice(0, 6).map((url, i) => (
                <div
                  key={i}
                  className="aspect-square rounded-xl overflow-hidden bg-gray-100"
                >
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={url}
                    alt=""
                    className="w-full h-full object-cover"
                  />
                </div>
              ))}
            </div>
            {gallery.length > 6 && (
              <p className="text-center text-xs text-gray-400 mt-2">
                +{gallery.length - 6} ảnh khác
              </p>
            )}
          </div>
        )}
      </div>

      {/* Sticky CTA */}
      <div className="fixed bottom-0 left-0 right-0 bg-white/95 backdrop-blur-md border-t border-gray-200 p-4 z-50">
        <div className="max-w-lg mx-auto flex gap-3">
          <button
            onClick={handleOpenInApp}
            className="flex-1 bg-gradient-to-r from-indigo-500 to-purple-600 text-white font-semibold py-3.5 px-6 rounded-2xl shadow-lg shadow-indigo-500/25 active:scale-[0.98] transition-transform text-sm"
          >
            {isMobile ? "Mở trong ứng dụng" : "Tải ứng dụng"}
          </button>
        </div>
        <p className="text-center text-xs text-gray-400 mt-2 max-w-lg mx-auto">
          Xem chi tiết và đặt lịch hẹn trên ứng dụng Mate Social
        </p>
      </div>
    </div>
  );
}
