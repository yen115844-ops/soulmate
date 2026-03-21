import { PrismaPg } from '@prisma/adapter-pg';
import * as bcrypt from 'bcryptjs';
import * as fs from 'fs';
import * as path from 'path';
import {
  PrismaClient,
  type DrinkingHabit,
  type Education,
  type SmokingHabit,
} from '../src/generated/prisma/client';

const adapter = new PrismaPg({
  connectionString: process.env.DATABASE_URL,
});

const prisma = new PrismaClient({ adapter });
const SALT_ROUNDS = 10;

// Service type codes
const ServiceTypeCode = {
  WALKING: 'walking',
  COFFEE: 'coffee',
  MOVIE: 'movie',
  DINNER: 'dinner',
  LUNCH: 'lunch',
  KARAOKE: 'karaoke',
  PARTY: 'party',
  EVENT: 'event',
  SHOPPING: 'shopping',
  GYM: 'gym',
  TRAVEL: 'travel',
  PICNIC: 'picnic',
  BOARD_GAME: 'board_game',
  MUSEUM: 'museum',
  OTHER: 'other',
} as const;

type CommuneSeed = {
  code: string;
  name: string;
  nameEn: string;
  sortOrder: number;
};

type ProvinceSeed = {
  code: string;
  name: string;
  nameEn: string;
  sortOrder: number;
  addressKitCode: string;
};

function mapProvinceCode(addressKitCode: string): string {
  const code = addressKitCode.trim();
  if (code === '79') return 'HCM';
  if (code === '01') return 'HN';
  if (code === '48') return 'DN';
  if (code === '31') return 'HP';
  if (code === '92') return 'CT';
  return `VN${code}`;
}

async function fetchAddressKitProvinces(
  baseUrl: string,
  effectiveDate: string,
): Promise<ProvinceSeed[]> {
  const url = `${baseUrl.replace(/\/$/, '')}/${effectiveDate}/provinces`;
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`AddressKit provinces request failed: ${response.status}`);
  }

  const payload = await response.json() as Record<string, unknown>;
  const list = Array.isArray(payload.provinces)
    ? payload.provinces
    : Array.isArray(payload.data)
      ? payload.data
      : Array.isArray(payload.result)
        ? payload.result
        : [];

  const provinces = list
    .map((item, index) => {
      const row = item as Record<string, unknown>;
      const rawCode = row.code ?? row.id;
      const rawName = row.name ?? row.provinceName;
      const rawNameEn = row.englishName ?? row.nameEn;

      if (typeof rawCode !== 'string' || typeof rawName !== 'string') {
        return null;
      }

      return {
        code: mapProvinceCode(rawCode),
        name: rawName.trim(),
        nameEn: typeof rawNameEn === 'string' && rawNameEn.trim().length > 0
          ? rawNameEn.trim()
          : rawName.trim(),
        sortOrder: index + 1,
        addressKitCode: rawCode.trim(),
      } as ProvinceSeed;
    })
    .filter((item): item is ProvinceSeed => item !== null);

  if (provinces.length === 0) {
    throw new Error('AddressKit provinces payload has no valid rows');
  }

  return provinces;
}

async function fetchAddressKitCommunes(
  baseUrl: string,
  effectiveDate: string,
  provinceId: string,
  fallback: CommuneSeed[],
): Promise<{ communes: CommuneSeed[]; source: 'api' | 'fallback' }> {
  try {
    const url = `${baseUrl.replace(/\/$/, '')}/${effectiveDate}/provinces/${provinceId}/communes`;
    const response = await fetch(url);
    if (!response.ok) {
      return { communes: fallback, source: 'fallback' };
    }

    const payload = await response.json() as Record<string, unknown>;
    const list = Array.isArray(payload)
      ? payload
      : Array.isArray(payload.communes)
        ? payload.communes
      : Array.isArray(payload.data)
        ? payload.data
        : Array.isArray(payload.result)
          ? payload.result
          : [];

    if (!Array.isArray(list) || list.length === 0) {
      return { communes: fallback, source: 'fallback' };
    }

    const communes = list
      .map((item, index) => {
        const row = item as Record<string, unknown>;
        const rawCode = row.id ?? row.code ?? row.communeID ?? row.communeId ?? row.codeName;
        const rawName = row.name ?? row.communeName ?? row.fullName;
        if (typeof rawName !== 'string' || rawName.trim().length === 0) {
          return null;
        }

        const normalizedCode = String(rawCode ?? `C${index + 1}`)
          .replace(/[^A-Za-z0-9]/g, '')
          .slice(0, 12)
          .toUpperCase();

        return {
          code: normalizedCode.length > 0 ? normalizedCode : `C${index + 1}`,
          name: rawName.trim(),
          nameEn: rawName.trim(),
          sortOrder: index + 1,
        } as CommuneSeed;
      })
      .filter((item): item is CommuneSeed => item !== null);

    if (communes.length === 0) {
      return { communes: fallback, source: 'fallback' };
    }

    return { communes, source: 'api' };
  } catch {
    return { communes: fallback, source: 'fallback' };
  }
}

async function deleteAllData() {
  console.log('🗑️  Deleting all existing data...');

  // Xoá theo thứ tự: bảng con trước, bảng cha sau (tránh lỗi foreign key)
  await prisma.reviewResponse.deleteMany();
  await prisma.review.deleteMany();
  await prisma.bookingStatusHistory.deleteMany();
  await prisma.locationLog.deleteMany();
  await prisma.sosEvent.deleteMany();
  await prisma.booking.deleteMany();
  await prisma.message.deleteMany();
  await prisma.conversationParticipant.deleteMany();
  await prisma.conversation.deleteMany();
  await prisma.transaction.deleteMany();
  await prisma.escrowHolding.deleteMany();
  await prisma.creditPurchase.deleteMany();
  await prisma.subscription.deleteMany();
  await prisma.favorite.deleteMany();
  await prisma.notification.deleteMany();
  await prisma.deviceToken.deleteMany();
  await prisma.refreshToken.deleteMany();
  await prisma.emergencyContact.deleteMany();
  await prisma.userBlacklist.deleteMany();
  await prisma.systemBlacklist.deleteMany();
  await prisma.report.deleteMany();
  await prisma.otpCode.deleteMany();
  await prisma.availabilitySlot.deleteMany();
  await prisma.partnerProfile.deleteMany();
  await prisma.kycVerification.deleteMany();
  await prisma.wallet.deleteMany();
  await prisma.userSettings.deleteMany();
  await prisma.profile.deleteMany();
  await prisma.user.deleteMany();
  await prisma.interest.deleteMany();
  await prisma.interestCategory.deleteMany();
  await prisma.talent.deleteMany();
  await prisma.talentCategory.deleteMany();
  await prisma.language.deleteMany();
  await prisma.district.deleteMany();
  await prisma.province.deleteMany();
  await prisma.serviceType.deleteMany();
  await prisma.appSetting.deleteMany();
  await prisma.subscriptionPlan.deleteMany();
  await prisma.creditPackage.deleteMany();

  console.log('✅ All existing data deleted!');
}

async function main() {
  console.log('Start seeding...');

  // Xoá toàn bộ dữ liệu cũ trước khi seed dữ liệu mới
  await deleteAllData();

  const getRealAvatarUrl = (seed: number, gender: 'men' | 'women') =>
    `https://randomuser.me/api/portraits/${gender}/${Math.abs(seed) % 100}.jpg`;
  const getRealPhotoGallery = (seed: number, gender: 'men' | 'women') => [
    getRealAvatarUrl(seed, gender),
    getRealAvatarUrl(seed + 17, gender),
    getRealAvatarUrl(seed + 43, gender),
  ];

  // Seed Service Types - icon dùng emoji để đồng bộ giữa CMS và mobile
  const serviceTypes = [
    { code: ServiceTypeCode.WALKING, name: 'Walking', nameVi: 'Đi dạo', description: 'Đi dạo cùng partner', icon: '🚶', sortOrder: 1 },
    { code: ServiceTypeCode.COFFEE, name: 'Coffee', nameVi: 'Uống cà phê', description: 'Đi uống cà phê cùng partner', icon: '☕', sortOrder: 2 },
    { code: ServiceTypeCode.MOVIE, name: 'Movie', nameVi: 'Xem phim', description: 'Đi xem phim cùng partner', icon: '🎬', sortOrder: 3 },
    { code: ServiceTypeCode.DINNER, name: 'Dinner', nameVi: 'Ăn tối', description: 'Đi ăn tối cùng partner', icon: '🍽️', sortOrder: 4 },
    { code: ServiceTypeCode.LUNCH, name: 'Lunch', nameVi: 'Ăn trưa', description: 'Đi ăn trưa cùng partner', icon: '🥗', sortOrder: 5 },
    { code: ServiceTypeCode.KARAOKE, name: 'Karaoke', nameVi: 'Hát karaoke', description: 'Đi hát karaoke cùng partner', icon: '🎤', sortOrder: 6 },
    { code: ServiceTypeCode.PARTY, name: 'Party', nameVi: 'Tiệc tùng', description: 'Tham gia tiệc cùng partner', icon: '🎉', sortOrder: 7 },
    { code: ServiceTypeCode.EVENT, name: 'Event', nameVi: 'Sự kiện', description: 'Tham gia sự kiện cùng partner', icon: '📅', sortOrder: 8 },
    { code: ServiceTypeCode.SHOPPING, name: 'Shopping', nameVi: 'Mua sắm', description: 'Đi mua sắm cùng partner', icon: '🛍️', sortOrder: 9 },
    { code: ServiceTypeCode.GYM, name: 'Gym', nameVi: 'Tập gym', description: 'Đi tập gym cùng partner', icon: '💪', sortOrder: 10 },
    { code: ServiceTypeCode.TRAVEL, name: 'Travel', nameVi: 'Du lịch', description: 'Du lịch cùng partner', icon: '✈️', sortOrder: 11 },
    { code: ServiceTypeCode.PICNIC, name: 'Picnic', nameVi: 'Dã ngoại', description: 'Đi dã ngoại cùng partner', icon: '🧺', sortOrder: 12 },
    { code: ServiceTypeCode.BOARD_GAME, name: 'Board Game', nameVi: 'Chơi board game', description: 'Đi chơi board game cùng partner', icon: '🎲', sortOrder: 13 },
    { code: ServiceTypeCode.MUSEUM, name: 'Museum', nameVi: 'Tham quan bảo tàng', description: 'Đi bảo tàng cùng partner', icon: '🏛️', sortOrder: 14 },
    { code: ServiceTypeCode.OTHER, name: 'Other', nameVi: 'Khác', description: 'Hoạt động khác', icon: '➕', sortOrder: 99 },
  ];

  for (const serviceType of serviceTypes) {
    await prisma.serviceType.upsert({
      where: { code: serviceType.code },
      update: serviceType,
      create: serviceType,
    });
  }

  console.log(`Seeded ${serviceTypes.length} service types`);

  // Seed App Settings (keys match CMS settings form - snake_case)
  const appSettings = [
    // General
    { key: 'app_name', value: 'Mate Social', description: 'Application name' },
    { key: 'app_description', value: 'Nền tảng đặt chỗ bạn đồng hành', description: 'Application description' },
    { key: 'support_email', value: 'ngocbinhan8888@gmail.com', description: 'Support email address' },
    { key: 'support_phone', value: '+84 986 384 628', description: 'Support phone number' },
    { key: 'support_url', value: 'https://gomate-cms.vercel.app/support', description: 'Support page URL (e.g. for App Store product page)' },
    { key: 'default_currency', value: 'VND', description: 'Default currency code' },
    { key: 'default_language', value: 'vi', description: 'Default language code' },
    { key: 'timezone', value: 'Asia/Ho_Chi_Minh', description: 'Default timezone' },
    { key: 'addresskit_api_base_url', value: 'https://production.cas.so/address-kit', description: 'AddressKit API base URL for Vietnam administrative units' },
    { key: 'addresskit_effective_date', value: 'latest', description: 'AddressKit effectiveDate. Use latest or yyyy-mm-dd' },
    { key: 'support_hotline', value: '1900-xxxx', description: 'Support hotline number' },
    // Booking
    { key: 'min_booking_hours', value: '1', description: 'Minimum booking hours' },
    { key: 'max_booking_hours', value: '8', description: 'Maximum booking hours' },
    { key: 'advance_booking_days', value: '30', description: 'Days in advance users can book' },
    { key: 'cancellation_hours', value: '24', description: 'Hours before booking for free cancellation' },
    { key: 'service_fee_percent', value: '15', description: 'Platform service fee percentage' },
    { key: 'partner_commission_percent', value: '85', description: 'Partner commission percentage' },
    { key: 'auto_confirm_booking', value: 'false', description: 'Auto-confirm bookings without partner approval' },
    { key: 'require_premium_for_booking', value: 'true', description: 'Require premium subscription to create booking. If false, booking is free for all users.' },
    { key: 'allow_instant_booking', value: 'true', description: 'Allow instant booking' },
    { key: 'platform_fee_rate', value: '0.15', description: 'Platform fee rate (15%)' },
    { key: 'escrow_release_delay_hours', value: '24', description: 'Hours to wait before releasing escrow' },
    { key: 'max_emergency_contacts', value: '5', description: 'Maximum number of emergency contacts per user' },
    // Notifications
    { key: 'email_notifications', value: 'true', description: 'Send notifications via email' },
    { key: 'push_notifications', value: 'true', description: 'Send push notifications' },
    { key: 'sms_notifications', value: 'false', description: 'Send SMS notifications' },
    { key: 'admin_email_alerts', value: 'true', description: 'Admin receives email alerts' },
    { key: 'new_user_alert', value: 'true', description: 'Alert when new users register' },
    { key: 'new_booking_alert', value: 'true', description: 'Alert when new bookings are created' },
    { key: 'kyc_pending_alert', value: 'true', description: 'Alert when KYC is pending' },
    // Security
    { key: 'require_email_verification', value: 'true', description: 'Require email verification' },
    { key: 'require_phone_verification', value: 'false', description: 'Require phone verification' },
    { key: 'require_kyc_for_partner', value: 'true', description: 'Require KYC for partners' },
    { key: 'require_approval_for_partner', value: 'false', description: 'Require admin approval when user registers as partner. If false, user becomes partner immediately.' },
    { key: 'max_login_attempts', value: '5', description: 'Max failed login attempts before lock' },
    { key: 'login_lock_minutes', value: '15', description: 'Account lock duration in minutes after too many failed logins' },
    { key: 'otp_expiry_minutes', value: '5', description: 'OTP expiry time in minutes' },
    { key: 'otp_max_attempts', value: '5', description: 'Max OTP verification attempts before invalidation' },
    { key: 'session_timeout', value: '30', description: 'Token expiry in days' },
    { key: 'password_min_length', value: '8', description: 'Minimum password length' },
    { key: 'enforce_strong_password', value: 'false', description: 'Enforce strong password policy (only min length 8)' },
  ];

  for (const setting of appSettings) {
    await prisma.appSetting.upsert({
      where: { key: setting.key },
      update: setting,
      create: setting,
    });
  }

  console.log(`Seeded ${appSettings.length} app settings`);

  // Seed Master Data - Provinces + Communes từ AddressKit
  const addressKitBaseUrl = process.env.ADDRESSKIT_API_BASE_URL ?? 'https://production.cas.so/address-kit';
  const addressKitEffectiveDate = process.env.ADDRESSKIT_EFFECTIVE_DATE ?? 'latest';

  const provincesFallback: ProvinceSeed[] = [
    { code: 'HN', name: 'Thành phố Hà Nội', nameEn: 'Ha Noi', sortOrder: 1, addressKitCode: '01' },
    { code: 'HCM', name: 'Thành phố Hồ Chí Minh', nameEn: 'Ho Chi Minh City', sortOrder: 2, addressKitCode: '79' },
    { code: 'DN', name: 'Thành phố Đà Nẵng', nameEn: 'Da Nang', sortOrder: 3, addressKitCode: '48' },
    { code: 'HP', name: 'Thành phố Hải Phòng', nameEn: 'Hai Phong', sortOrder: 4, addressKitCode: '31' },
    { code: 'CT', name: 'Thành phố Cần Thơ', nameEn: 'Can Tho', sortOrder: 5, addressKitCode: '92' },
  ];

  let provinces: ProvinceSeed[] = provincesFallback;
  let provinceSource: 'api' | 'fallback' = 'fallback';

  try {
    provinces = await fetchAddressKitProvinces(addressKitBaseUrl, addressKitEffectiveDate);
    provinceSource = 'api';
  } catch {
    provinces = provincesFallback;
    provinceSource = 'fallback';
  }

  for (const province of provinces) {
    await prisma.province.upsert({
      where: { code: province.code },
      update: {
        name: province.name,
        nameEn: province.nameEn,
        sortOrder: province.sortOrder,
        isActive: true,
      },
      create: {
        code: province.code,
        name: province.name,
        nameEn: province.nameEn,
        sortOrder: province.sortOrder,
      },
    });
  }
  console.log(`Seeded ${provinces.length} provinces (${provinceSource})`);

  const defaultCommuneFallback: CommuneSeed[] = [
    { code: 'C001', name: 'Phường Trung tâm', nameEn: 'Central Ward', sortOrder: 1 },
    { code: 'C002', name: 'Xã Trung tâm', nameEn: 'Central Commune', sortOrder: 2 },
  ];

  let totalCommunesSeeded = 0;
  for (const province of provinces) {
    const provinceRow = await prisma.province.findUnique({ where: { code: province.code } });
    if (!provinceRow) {
      continue;
    }

    const { communes } = await fetchAddressKitCommunes(
      addressKitBaseUrl,
      addressKitEffectiveDate,
      province.addressKitCode,
      defaultCommuneFallback,
    );

    for (const commune of communes) {
      const existingDistrict = await prisma.district.findFirst({
        where: { code: commune.code, provinceId: provinceRow.id },
      });

      if (existingDistrict) {
        await prisma.district.update({
          where: { id: existingDistrict.id },
          data: {
            name: commune.name,
            nameEn: commune.nameEn,
            sortOrder: commune.sortOrder,
            isActive: true,
          },
        });
      } else {
        await prisma.district.create({
          data: {
            code: commune.code,
            name: commune.name,
            nameEn: commune.nameEn,
            sortOrder: commune.sortOrder,
            provinceId: provinceRow.id,
          },
        });
      }
    }

    totalCommunesSeeded += communes.length;
  }

  console.log(`Seeded ${totalCommunesSeeded} ward/commune records across ${provinces.length} provinces`);

  // Seed Interest Categories
  const interestCategories = [
    { code: 'entertainment', name: 'Giải trí', nameEn: 'Entertainment', icon: '🎬', sortOrder: 1 },
    { code: 'sports', name: 'Thể thao', nameEn: 'Sports', icon: '⚽', sortOrder: 2 },
    { code: 'music', name: 'Âm nhạc', nameEn: 'Music', icon: '🎵', sortOrder: 3 },
    { code: 'food', name: 'Ẩm thực', nameEn: 'Food & Drinks', icon: '🍜', sortOrder: 4 },
    { code: 'travel', name: 'Du lịch', nameEn: 'Travel', icon: '✈️', sortOrder: 5 },
    { code: 'art', name: 'Nghệ thuật', nameEn: 'Art', icon: '🎨', sortOrder: 6 },
    { code: 'tech', name: 'Công nghệ', nameEn: 'Technology', icon: '💻', sortOrder: 7 },
    { code: 'lifestyle', name: 'Phong cách sống', nameEn: 'Lifestyle', icon: '🌟', sortOrder: 8 },
  ];

  for (const category of interestCategories) {
    await prisma.interestCategory.upsert({
      where: { code: category.code },
      update: category,
      create: category,
    });
  }
  console.log(`Seeded ${interestCategories.length} interest categories`);

  // Seed Interests
  const entertainmentCat = await prisma.interestCategory.findUnique({ where: { code: 'entertainment' } });
  const sportsCat = await prisma.interestCategory.findUnique({ where: { code: 'sports' } });
  const musicCat = await prisma.interestCategory.findUnique({ where: { code: 'music' } });
  const foodCat = await prisma.interestCategory.findUnique({ where: { code: 'food' } });
  const travelCat = await prisma.interestCategory.findUnique({ where: { code: 'travel' } });
  const lifestyleCat = await prisma.interestCategory.findUnique({ where: { code: 'lifestyle' } });

  const interests = [
    { code: 'movies', name: 'Xem phim', nameEn: 'Movies', icon: '🎬', categoryId: entertainmentCat?.id, sortOrder: 1 },
    { code: 'gaming', name: 'Chơi game', nameEn: 'Gaming', icon: '🎮', categoryId: entertainmentCat?.id, sortOrder: 2 },
    { code: 'karaoke', name: 'Karaoke', nameEn: 'Karaoke', icon: '🎤', categoryId: entertainmentCat?.id, sortOrder: 3 },
    { code: 'reading', name: 'Đọc sách', nameEn: 'Reading', icon: '📚', categoryId: entertainmentCat?.id, sortOrder: 4 },
    { code: 'football', name: 'Bóng đá', nameEn: 'Football', icon: '⚽', categoryId: sportsCat?.id, sortOrder: 1 },
    { code: 'gym', name: 'Tập gym', nameEn: 'Gym', icon: '💪', categoryId: sportsCat?.id, sortOrder: 2 },
    { code: 'yoga', name: 'Yoga', nameEn: 'Yoga', icon: '🧘', categoryId: sportsCat?.id, sortOrder: 3 },
    { code: 'swimming', name: 'Bơi lội', nameEn: 'Swimming', icon: '🏊', categoryId: sportsCat?.id, sortOrder: 4 },
    { code: 'running', name: 'Chạy bộ', nameEn: 'Running', icon: '🏃', categoryId: sportsCat?.id, sortOrder: 5 },
    { code: 'pop', name: 'Nhạc Pop', nameEn: 'Pop Music', icon: '🎵', categoryId: musicCat?.id, sortOrder: 1 },
    { code: 'edm', name: 'EDM', nameEn: 'EDM', icon: '🎧', categoryId: musicCat?.id, sortOrder: 2 },
    { code: 'kpop', name: 'K-Pop', nameEn: 'K-Pop', icon: '🇰🇷', categoryId: musicCat?.id, sortOrder: 3 },
    { code: 'concert', name: 'Xem concert', nameEn: 'Concert', icon: '🎸', categoryId: musicCat?.id, sortOrder: 4 },
    { code: 'coffee', name: 'Cà phê', nameEn: 'Coffee', icon: '☕', categoryId: foodCat?.id, sortOrder: 1 },
    { code: 'cooking', name: 'Nấu ăn', nameEn: 'Cooking', icon: '👨‍🍳', categoryId: foodCat?.id, sortOrder: 2 },
    { code: 'foodie', name: 'Ăn vặt', nameEn: 'Foodie', icon: '🍜', categoryId: foodCat?.id, sortOrder: 3 },
    { code: 'wine', name: 'Rượu vang', nameEn: 'Wine', icon: '🍷', categoryId: foodCat?.id, sortOrder: 4 },
    { code: 'beach', name: 'Biển', nameEn: 'Beach', icon: '🏖️', categoryId: travelCat?.id, sortOrder: 1 },
    { code: 'mountain', name: 'Leo núi', nameEn: 'Mountain', icon: '⛰️', categoryId: travelCat?.id, sortOrder: 2 },
    { code: 'camping', name: 'Cắm trại', nameEn: 'Camping', icon: '⛺', categoryId: travelCat?.id, sortOrder: 3 },
    { code: 'photography', name: 'Chụp ảnh', nameEn: 'Photography', icon: '📷', categoryId: lifestyleCat?.id, sortOrder: 1 },
    { code: 'fashion', name: 'Thời trang', nameEn: 'Fashion', icon: '👗', categoryId: lifestyleCat?.id, sortOrder: 2 },
    { code: 'shopping', name: 'Mua sắm', nameEn: 'Shopping', icon: '🛍️', categoryId: lifestyleCat?.id, sortOrder: 3 },
    { code: 'pet', name: 'Thú cưng', nameEn: 'Pets', icon: '🐕', categoryId: lifestyleCat?.id, sortOrder: 4 },
  ];

  for (const interest of interests) {
    if (interest.categoryId) {
      await prisma.interest.upsert({
        where: { code: interest.code },
        update: interest,
        create: interest,
      });
    }
  }
  console.log(`Seeded ${interests.length} interests`);

  // Seed Talent Categories
  const talentCategories = [
    { code: 'music', name: 'Âm nhạc', nameEn: 'Music', icon: '🎵', sortOrder: 1 },
    { code: 'dance', name: 'Nhảy múa', nameEn: 'Dance', icon: '💃', sortOrder: 2 },
    { code: 'language', name: 'Ngôn ngữ', nameEn: 'Language', icon: '🗣️', sortOrder: 3 },
    { code: 'sports', name: 'Thể thao', nameEn: 'Sports', icon: '🏆', sortOrder: 4 },
    { code: 'creative', name: 'Sáng tạo', nameEn: 'Creative', icon: '🎨', sortOrder: 5 },
  ];

  for (const category of talentCategories) {
    await prisma.talentCategory.upsert({
      where: { code: category.code },
      update: category,
      create: category,
    });
  }
  console.log(`Seeded ${talentCategories.length} talent categories`);

  // Seed Talents
  const musicTalentCat = await prisma.talentCategory.findUnique({ where: { code: 'music' } });
  const danceTalentCat = await prisma.talentCategory.findUnique({ where: { code: 'dance' } });
  const languageTalentCat = await prisma.talentCategory.findUnique({ where: { code: 'language' } });
  const sportsTalentCat = await prisma.talentCategory.findUnique({ where: { code: 'sports' } });
  const creativeTalentCat = await prisma.talentCategory.findUnique({ where: { code: 'creative' } });

  const talents = [
    { code: 'singing', name: 'Ca hát', nameEn: 'Singing', icon: '🎤', categoryId: musicTalentCat?.id, sortOrder: 1 },
    { code: 'guitar', name: 'Đàn Guitar', nameEn: 'Guitar', icon: '🎸', categoryId: musicTalentCat?.id, sortOrder: 2 },
    { code: 'piano', name: 'Đàn Piano', nameEn: 'Piano', icon: '🎹', categoryId: musicTalentCat?.id, sortOrder: 3 },
    { code: 'dj', name: 'DJ', nameEn: 'DJ', icon: '🎧', categoryId: musicTalentCat?.id, sortOrder: 4 },
    { code: 'dance_modern', name: 'Nhảy hiện đại', nameEn: 'Modern Dance', icon: '💃', categoryId: danceTalentCat?.id, sortOrder: 1 },
    { code: 'dance_traditional', name: 'Múa dân tộc', nameEn: 'Traditional Dance', icon: '🩰', categoryId: danceTalentCat?.id, sortOrder: 2 },
    { code: 'hiphop', name: 'Hip Hop', nameEn: 'Hip Hop', icon: '🕺', categoryId: danceTalentCat?.id, sortOrder: 3 },
    { code: 'english', name: 'Tiếng Anh', nameEn: 'English', icon: '🇬🇧', categoryId: languageTalentCat?.id, sortOrder: 1 },
    { code: 'korean', name: 'Tiếng Hàn', nameEn: 'Korean', icon: '🇰🇷', categoryId: languageTalentCat?.id, sortOrder: 2 },
    { code: 'japanese', name: 'Tiếng Nhật', nameEn: 'Japanese', icon: '🇯🇵', categoryId: languageTalentCat?.id, sortOrder: 3 },
    { code: 'chinese', name: 'Tiếng Trung', nameEn: 'Chinese', icon: '🇨🇳', categoryId: languageTalentCat?.id, sortOrder: 4 },
    { code: 'basketball', name: 'Bóng rổ', nameEn: 'Basketball', icon: '🏀', categoryId: sportsTalentCat?.id, sortOrder: 1 },
    { code: 'badminton', name: 'Cầu lông', nameEn: 'Badminton', icon: '🏸', categoryId: sportsTalentCat?.id, sortOrder: 2 },
    { code: 'tennis', name: 'Tennis', nameEn: 'Tennis', icon: '🎾', categoryId: sportsTalentCat?.id, sortOrder: 3 },
    { code: 'drawing', name: 'Vẽ', nameEn: 'Drawing', icon: '🎨', categoryId: creativeTalentCat?.id, sortOrder: 1 },
    { code: 'photography_talent', name: 'Nhiếp ảnh', nameEn: 'Photography', icon: '📸', categoryId: creativeTalentCat?.id, sortOrder: 2 },
    { code: 'makeup', name: 'Trang điểm', nameEn: 'Makeup', icon: '💄', categoryId: creativeTalentCat?.id, sortOrder: 3 },
    { code: 'design', name: 'Thiết kế', nameEn: 'Design', icon: '✏️', categoryId: creativeTalentCat?.id, sortOrder: 4 },
  ];

  for (const talent of talents) {
    if (talent.categoryId) {
      await prisma.talent.upsert({
        where: { code: talent.code },
        update: talent,
        create: talent,
      });
    }
  }
  console.log(`Seeded ${talents.length} talents`);

  // Seed Languages
  const languages = [
    { code: 'vi', name: 'Tiếng Việt', nativeName: 'Tiếng Việt', sortOrder: 1 },
    { code: 'en', name: 'Tiếng Anh', nativeName: 'English', sortOrder: 2 },
    { code: 'ko', name: 'Tiếng Hàn', nativeName: '한국어', sortOrder: 3 },
    { code: 'ja', name: 'Tiếng Nhật', nativeName: '日本語', sortOrder: 4 },
    { code: 'zh', name: 'Tiếng Trung', nativeName: '中文', sortOrder: 5 },
    { code: 'fr', name: 'Tiếng Pháp', nativeName: 'Français', sortOrder: 6 },
    { code: 'de', name: 'Tiếng Đức', nativeName: 'Deutsch', sortOrder: 7 },
    { code: 'es', name: 'Tiếng Tây Ban Nha', nativeName: 'Español', sortOrder: 8 },
    { code: 'th', name: 'Tiếng Thái', nativeName: 'ไทย', sortOrder: 9 },
    { code: 'id', name: 'Tiếng Indonesia', nativeName: 'Bahasa Indonesia', sortOrder: 10 },
  ];

  for (const language of languages) {
    await prisma.language.upsert({
      where: { code: language.code },
      update: language,
      create: language,
    });
  }
  console.log(`Seeded ${languages.length} languages`);

  // Seed Admin Usern@1
  const adminPassword = await bcrypt.hash('Admin@123', SALT_ROUNDS);
  const admin = await prisma.user.upsert({
    where: { email: 'admin@matesocial.com' },
    update: {
      passwordHash: adminPassword,
      role: 'ADMIN',
      status: 'ACTIVE',
    },
    create: {
      email: 'admin@matesocial.com',
      phone: '+84999999999',
      passwordHash: adminPassword,
      role: 'ADMIN',
      status: 'ACTIVE',
      profile: {
        create: {
          fullName: 'System Admin',
          displayName: 'Admin',
        },
      },
    },
  });
  console.log(`Seeded admin user: ${admin.email}`);

  // Seed Sample Users
  const userPassword = await bcrypt.hash('User@123', SALT_ROUNDS);
  
  const sampleUsers = [
    {
      email: 'user1@example.com',
      phone: '+84901234567',
      role: 'USER' as const,
      profile: {
        fullName: 'Nguyễn Văn An',
        displayName: 'Văn An',
        bio: 'Yêu thích du lịch và khám phá ẩm thực',
        gender: 'MALE' as const,
        dateOfBirth: new Date('1995-05-15'),
        heightCm: 175,
        weightKg: 70,
        education: 'BACHELOR',
        smokingHabit: 'NEVER',
        drinkingHabit: 'SOCIALLY',
        city: 'TP. Hồ Chí Minh',
        district: 'Quận 1',
        languages: ['Tiếng Việt', 'English'],
        interests: ['movies', 'coffee', 'travel', 'gym'],
        talents: ['guitar', 'singing'],
      },
    },
    {
      email: 'user2@example.com',
      phone: '+84902234568',
      role: 'USER' as const,
      profile: {
        fullName: 'Trần Thị Bích',
        displayName: 'Bích Trần',
        bio: 'Đam mê âm nhạc và nghệ thuật',
        gender: 'FEMALE' as const,
        dateOfBirth: new Date('1998-08-20'),
        heightCm: 165,
        weightKg: 52,
        education: 'HIGH_SCHOOL',
        smokingHabit: 'NEVER',
        drinkingHabit: 'NEVER',
        city: 'TP. Hồ Chí Minh',
        district: 'Quận 3',
        languages: ['Tiếng Việt', 'English', 'Tiếng Hàn'],
        interests: ['kpop', 'concert', 'fashion', 'shopping'],
        talents: ['dance_modern', 'korean', 'makeup'],
      },
    },
    {
      email: 'user3@example.com',
      phone: '+84903234569',
      role: 'USER' as const,
      profile: {
        fullName: 'Lê Hoàng Minh',
        displayName: 'Hoàng Minh',
        bio: 'Thích thể thao và công nghệ',
        gender: 'MALE' as const,
        dateOfBirth: new Date('1992-03-10'),
        heightCm: 180,
        weightKg: 78,
        education: 'MASTER',
        smokingHabit: 'NEVER',
        drinkingHabit: 'REGULARLY',
        city: 'Hà Nội',
        district: 'Quận Cầu Giấy',
        languages: ['Tiếng Việt', 'English'],
        interests: ['football', 'gym', 'gaming', 'tech'],
        talents: ['basketball', 'english'],
      },
    },
    {
      email: 'user4@example.com',
      phone: '+84904234570',
      role: 'USER' as const,
      profile: {
        fullName: 'Phạm Thùy Linh',
        displayName: 'Thùy Linh',
        bio: 'Foodie và travel blogger',
        gender: 'FEMALE' as const,
        dateOfBirth: new Date('1997-11-25'),
        heightCm: 162,
        weightKg: 48,
        education: 'BACHELOR',
        smokingHabit: 'NEVER',
        drinkingHabit: 'SOCIALLY',
        city: 'Đà Nẵng',
        district: '',
        languages: ['Tiếng Việt', 'English', 'Tiếng Nhật'],
        interests: ['foodie', 'photography', 'beach', 'coffee'],
        talents: ['photography_talent', 'japanese', 'cooking'],
      },
    },
    {
      email: 'user5@example.com',
      phone: '+84905234571',
      role: 'USER' as const,
      profile: {
        fullName: 'Võ Đình Khoa',
        displayName: 'Đình Khoa',
        bio: 'Yêu thiên nhiên và leo núi',
        gender: 'MALE' as const,
        dateOfBirth: new Date('1990-07-08'),
        heightCm: 172,
        weightKg: 68,
        education: 'VOCATIONAL',
        smokingHabit: 'QUIT',
        drinkingHabit: 'NEVER',
        city: 'TP. Hồ Chí Minh',
        district: 'Quận Bình Thạnh',
        languages: ['Tiếng Việt', 'English'],
        interests: ['mountain', 'camping', 'running', 'yoga'],
        talents: ['guitar', 'photography_talent'],
      },
    },
  ];

  for (const [index, userData] of sampleUsers.entries()) {
    const avatarGender: 'men' | 'women' = userData.profile.gender === 'FEMALE' ? 'women' : 'men';
    const avatarUrl = getRealAvatarUrl(index + 1, avatarGender);
    const photos = getRealPhotoGallery(index + 1, avatarGender);

    await prisma.user.upsert({
      where: { email: userData.email },
      update: {
        passwordHash: userPassword,
        status: 'ACTIVE',
        profile: {
          upsert: {
            create: {
              fullName: userData.profile.fullName,
              displayName: userData.profile.displayName,
              bio: userData.profile.bio,
              gender: userData.profile.gender,
              dateOfBirth: userData.profile.dateOfBirth,
              heightCm: userData.profile.heightCm,
              weightKg: userData.profile.weightKg,
              education: userData.profile.education as Education,
              smokingHabit: userData.profile.smokingHabit as SmokingHabit,
              drinkingHabit: userData.profile.drinkingHabit as DrinkingHabit,
              city: userData.profile.city,
              district: userData.profile.district,
              languages: userData.profile.languages,
              interests: userData.profile.interests,
              talents: userData.profile.talents,
              avatarUrl,
              photos,
            },
            update: {
              fullName: userData.profile.fullName,
              displayName: userData.profile.displayName,
              bio: userData.profile.bio,
              gender: userData.profile.gender,
              dateOfBirth: userData.profile.dateOfBirth,
              heightCm: userData.profile.heightCm,
              weightKg: userData.profile.weightKg,
              education: userData.profile.education as Education,
              smokingHabit: userData.profile.smokingHabit as SmokingHabit,
              drinkingHabit: userData.profile.drinkingHabit as DrinkingHabit,
              city: userData.profile.city,
              district: userData.profile.district,
              languages: userData.profile.languages,
              interests: userData.profile.interests,
              talents: userData.profile.talents,
              avatarUrl,
              photos,
            },
          },
        },
      },
      create: {
        email: userData.email,
        phone: userData.phone,
        passwordHash: userPassword,
        role: userData.role,
        status: 'ACTIVE',
        kycStatus: 'VERIFIED',
        profile: {
          create: {
            fullName: userData.profile.fullName,
            displayName: userData.profile.displayName,
            bio: userData.profile.bio,
            gender: userData.profile.gender,
            dateOfBirth: userData.profile.dateOfBirth,
            heightCm: userData.profile.heightCm,
            weightKg: userData.profile.weightKg,
            education: userData.profile.education as Education,
            smokingHabit: userData.profile.smokingHabit as SmokingHabit,
            drinkingHabit: userData.profile.drinkingHabit as DrinkingHabit,
            city: userData.profile.city,
            district: userData.profile.district,
            languages: userData.profile.languages,
            interests: userData.profile.interests,
            talents: userData.profile.talents,
            avatarUrl,
            photos,
          },
        },
        settings: {
          create: {},
        },
      },
    });
  }
  console.log(`Seeded ${sampleUsers.length} sample users`);

  // Seed Sample Partners
  const partnerPassword = await bcrypt.hash('Partner@123', SALT_ROUNDS);
  
  const samplePartners = [
    {
      email: 'partner1@example.com',
      phone: '+84911234567',
      profile: {
        fullName: 'Nguyễn Thanh Hà',
        displayName: 'Thanh Hà',
        avatarUrl: 'https://picsum.photos/seed/partner1/400/400',
        bio: 'Hướng dẫn viên du lịch chuyên nghiệp với 5 năm kinh nghiệm. Yêu thích giao tiếp và chia sẻ văn hóa Việt Nam.',
        gender: 'FEMALE' as const,
        dateOfBirth: new Date('1996-02-14'),
        heightCm: 168,
        weightKg: 55,
        education: 'BACHELOR',
        smokingHabit: 'NEVER',
        drinkingHabit: 'SOCIALLY',
        city: 'TP. Hồ Chí Minh',
        district: 'Quận 1',
        languages: ['Tiếng Việt', 'English', 'Tiếng Trung'],
        interests: ['travel', 'coffee', 'photography', 'foodie'],
        talents: ['english', 'chinese', 'photography_talent'],
      },
      partnerProfile: {
        hourlyRate: 300000,
        minimumHours: 3,
        serviceTypes: ['walking', 'coffee', 'travel', 'shopping'],
        introduction: 'Xin chào! Mình là Thanh Hà, hướng dẫn viên du lịch tại TP.HCM. Mình có thể đưa bạn đi khám phá những địa điểm thú vị, thưởng thức ẩm thực địa phương và trải nghiệm văn hóa Sài Gòn.',
        experienceYears: 5,
        averageRating: 4.85,
        totalReviews: 128,
        completedBookings: 156,
      },
    },
    {
      email: 'partner2@example.com',
      phone: '+84912234568',
      profile: {
        fullName: 'Trần Minh Tuấn',
        displayName: 'Minh Tuấn',
        avatarUrl: 'https://picsum.photos/seed/partner2/400/400',
        bio: 'PT gym với 3 năm kinh nghiệm. Đam mê thể thao và lối sống lành mạnh.',
        gender: 'MALE' as const,
        dateOfBirth: new Date('1994-06-20'),
        heightCm: 182,
        weightKg: 82,
        education: 'HIGH_SCHOOL',
        smokingHabit: 'NEVER',
        drinkingHabit: 'SOCIALLY',
        city: 'TP. Hồ Chí Minh',
        district: 'Quận 7',
        languages: ['Tiếng Việt', 'English'],
        interests: ['gym', 'running', 'swimming', 'football'],
        talents: ['basketball', 'english'],
      },
      partnerProfile: {
        hourlyRate: 250000,
        minimumHours: 2,
        serviceTypes: ['gym', 'walking', 'coffee'],
        introduction: 'Chào bạn! Mình là Tuấn, personal trainer. Nếu bạn cần người đồng hành tập gym, chạy bộ hay chỉ đơn giản là trò chuyện về fitness, mình sẵn sàng!',
        experienceYears: 3,
        averageRating: 4.72,
        totalReviews: 89,
        completedBookings: 112,
      },
    },
    {
      email: 'partner3@example.com',
      phone: '+84913234569',
      profile: {
        fullName: 'Lê Thị Mỹ Duyên',
        displayName: 'Mỹ Duyên',
        avatarUrl: 'https://picsum.photos/seed/partner3/400/400',
        bio: 'Sinh viên năm cuối ngành Quan hệ Công chúng. Thích giao tiếp, sự kiện và networking.',
        gender: 'FEMALE' as const,
        dateOfBirth: new Date('2000-12-05'),
        heightCm: 165,
        weightKg: 50,
        education: 'BACHELOR',
        smokingHabit: 'NEVER',
        drinkingHabit: 'NEVER',
        city: 'TP. Hồ Chí Minh',
        district: 'Quận 10',
        languages: ['Tiếng Việt', 'English', 'Tiếng Hàn'],
        interests: ['kpop', 'concert', 'party', 'fashion'],
        talents: ['dance_modern', 'korean', 'makeup'],
      },
      partnerProfile: {
        hourlyRate: 200000,
        minimumHours: 3,
        serviceTypes: ['party', 'event', 'movie', 'karaoke'],
        introduction: 'Hi! Mình là Duyên, đang học PR. Mình thích tham gia các sự kiện, tiệc tùng và có thể giúp bạn hòa nhập trong các buổi networking.',
        experienceYears: 1,
        averageRating: 4.65,
        totalReviews: 45,
        completedBookings: 52,
      },
    },
    {
      email: 'partner4@example.com',
      phone: '+84914234570',
      profile: {
        fullName: 'Phạm Quốc Bảo',
        displayName: 'Quốc Bảo',
        avatarUrl: 'https://picsum.photos/seed/partner4/400/400',
        bio: 'Nhiếp ảnh gia tự do. Yêu thích du lịch và ghi lại những khoảnh khắc đẹp.',
        gender: 'MALE' as const,
        dateOfBirth: new Date('1993-09-18'),
        heightCm: 175,
        weightKg: 70,
        education: 'VOCATIONAL',
        smokingHabit: 'QUIT',
        drinkingHabit: 'SOCIALLY',
        city: 'Hà Nội',
        district: 'Quận Hoàn Kiếm',
        languages: ['Tiếng Việt', 'English'],
        interests: ['photography', 'travel', 'coffee', 'movies'],
        talents: ['photography_talent', 'design', 'english'],
      },
      partnerProfile: {
        hourlyRate: 350000,
        minimumHours: 2,
        serviceTypes: ['travel', 'walking', 'coffee', 'event'],
        introduction: 'Xin chào! Mình là Bảo, nhiếp ảnh gia. Nếu bạn cần người đồng hành khám phá Hà Nội và ghi lại những kỷ niệm đẹp, hãy liên hệ mình nhé!',
        experienceYears: 6,
        averageRating: 4.90,
        totalReviews: 203,
        completedBookings: 245,
      },
    },
    {
      email: 'partner5@example.com',
      phone: '+84915234571',
      profile: {
        fullName: 'Hoàng Thị Kim Ngân',
        displayName: 'Kim Ngân',
        avatarUrl: 'https://picsum.photos/seed/partner5/400/400',
        bio: 'Bartender tại một rooftop bar. Thích ẩm thực, cocktail và cuộc sống về đêm.',
        gender: 'FEMALE' as const,
        dateOfBirth: new Date('1997-04-30'),
        heightCm: 170,
        weightKg: 54,
        education: 'HIGH_SCHOOL',
        smokingHabit: 'SOMETIMES',
        drinkingHabit: 'REGULARLY',
        city: 'TP. Hồ Chí Minh',
        district: 'Quận 2 (TP Thủ Đức)',
        languages: ['Tiếng Việt', 'English'],
        interests: ['wine', 'foodie', 'party', 'music'],
        talents: ['singing', 'english', 'makeup'],
      },
      partnerProfile: {
        hourlyRate: 280000,
        minimumHours: 3,
        serviceTypes: ['dinner', 'party', 'coffee', 'event'],
        introduction: 'Hey! Mình là Ngân, bartender. Mình có thể giới thiệu cho bạn những quán bar, nhà hàng tuyệt vời ở Sài Gòn và chia sẻ về văn hóa cocktail.',
        experienceYears: 4,
        averageRating: 4.78,
        totalReviews: 156,
        completedBookings: 189,
      },
    },
    {
      email: 'partner6@example.com',
      phone: '+84916234572',
      profile: {
        fullName: 'Đỗ Văn Hùng',
        displayName: 'Văn Hùng',
        avatarUrl: 'https://picsum.photos/seed/partner6/400/400',
        bio: 'Giáo viên tiếng Nhật và hướng dẫn viên du lịch part-time.',
        gender: 'MALE' as const,
        dateOfBirth: new Date('1991-01-12'),
        heightCm: 170,
        weightKg: 65,
        education: 'MASTER',
        smokingHabit: 'NEVER',
        drinkingHabit: 'SOCIALLY',
        city: 'Đà Nẵng',
        district: '',
        languages: ['Tiếng Việt', 'English', 'Tiếng Nhật'],
        interests: ['travel', 'beach', 'reading', 'cooking'],
        talents: ['japanese', 'english', 'guitar'],
      },
      partnerProfile: {
        hourlyRate: 320000,
        minimumHours: 2,
        serviceTypes: ['travel', 'walking', 'coffee', 'dinner'],
        introduction: 'Xin chào! Mình là Hùng, giáo viên tiếng Nhật tại Đà Nẵng. Mình có thể đưa bạn khám phá thành phố biển xinh đẹp này và giao tiếp bằng nhiều ngôn ngữ.',
        experienceYears: 7,
        averageRating: 4.88,
        totalReviews: 178,
        completedBookings: 210,
      },
    },
    {
      email: 'partner7@example.com',
      phone: '+84917234573',
      profile: {
        fullName: 'Vũ Thị Mai Anh',
        displayName: 'Mai Anh',
        avatarUrl: 'https://picsum.photos/seed/partner7/400/400',
        bio: 'Fashion blogger và influencer. Đam mê thời trang và mua sắm.',
        gender: 'FEMALE' as const,
        dateOfBirth: new Date('1998-07-22'),
        heightCm: 172,
        weightKg: 52,
        education: 'BACHELOR',
        smokingHabit: 'NEVER',
        drinkingHabit: 'SOCIALLY',
        city: 'TP. Hồ Chí Minh',
        district: 'Quận 3',
        languages: ['Tiếng Việt', 'English', 'Tiếng Hàn'],
        interests: ['fashion', 'shopping', 'photography', 'coffee'],
        talents: ['makeup', 'photography_talent', 'korean'],
      },
      partnerProfile: {
        hourlyRate: 400000,
        minimumHours: 2,
        serviceTypes: ['shopping', 'coffee', 'event', 'party'],
        introduction: 'Hi các bạn! Mình là Mai Anh, fashion blogger. Nếu bạn cần tư vấn thời trang, đi shopping hay tham gia các sự kiện fashion, mình sẵn sàng đồng hành!',
        experienceYears: 3,
        averageRating: 4.82,
        totalReviews: 98,
        completedBookings: 115,
      },
    },
    {
      email: 'partner8@example.com',
      phone: '+84918234574',
      profile: {
        fullName: 'Ngô Đức Thắng',
        displayName: 'Đức Thắng',
        avatarUrl: 'https://picsum.photos/seed/partner8/400/400',
        bio: 'Tour guide tại Hà Nội. Chuyên gia về lịch sử và văn hóa Việt Nam.',
        gender: 'MALE' as const,
        dateOfBirth: new Date('1989-11-08'),
        heightCm: 173,
        weightKg: 72,
        education: 'BACHELOR',
        smokingHabit: 'QUIT',
        drinkingHabit: 'SOCIALLY',
        city: 'Hà Nội',
        district: 'Quận Ba Đình',
        languages: ['Tiếng Việt', 'English', 'Tiếng Pháp'],
        interests: ['travel', 'reading', 'coffee', 'photography'],
        talents: ['english', 'guitar', 'photography_talent'],
      },
      partnerProfile: {
        hourlyRate: 380000,
        minimumHours: 3,
        serviceTypes: ['travel', 'walking', 'coffee', 'dinner'],
        introduction: 'Xin chào! Mình là Thắng, hướng dẫn viên du lịch tại Hà Nội với 10 năm kinh nghiệm. Mình sẽ giúp bạn khám phá lịch sử và văn hóa ngàn năm của Thủ đô.',
        experienceYears: 10,
        averageRating: 4.95,
        totalReviews: 312,
        completedBookings: 380,
      },
    },
  ];

  for (const [index, partnerData] of samplePartners.entries()) {
    const avatarGender: 'men' | 'women' = partnerData.profile.gender === 'FEMALE' ? 'women' : 'men';
    const avatarUrl = getRealAvatarUrl(index + 101, avatarGender);
    const photos = getRealPhotoGallery(index + 101, avatarGender);

    const existingPartner = await prisma.user.findUnique({
      where: { email: partnerData.email },
    });

    if (!existingPartner) {
      await prisma.user.create({
        data: {
          email: partnerData.email,
          phone: partnerData.phone,
          passwordHash: partnerPassword,
          role: 'PARTNER',
          status: 'ACTIVE',
          kycStatus: 'VERIFIED',
          profile: {
            create: {
              fullName: partnerData.profile.fullName,
              displayName: partnerData.profile.displayName,
              avatarUrl,
              bio: partnerData.profile.bio,
              gender: partnerData.profile.gender,
              dateOfBirth: partnerData.profile.dateOfBirth,
              heightCm: partnerData.profile.heightCm,
              weightKg: partnerData.profile.weightKg,
              education: partnerData.profile.education as Education,
              smokingHabit: partnerData.profile.smokingHabit as SmokingHabit,
              drinkingHabit: partnerData.profile.drinkingHabit as DrinkingHabit,
              city: partnerData.profile.city,
              district: partnerData.profile.district,
              languages: partnerData.profile.languages,
              interests: partnerData.profile.interests,
              talents: partnerData.profile.talents,
              photos,
            },
          },
          partnerProfile: {
            create: {
              hourlyRate: partnerData.partnerProfile.hourlyRate,
              minimumHours: partnerData.partnerProfile.minimumHours,
              serviceTypes: partnerData.partnerProfile.serviceTypes,
              introduction: partnerData.partnerProfile.introduction,
              experienceYears: partnerData.partnerProfile.experienceYears,
              averageRating: partnerData.partnerProfile.averageRating,
              totalReviews: partnerData.partnerProfile.totalReviews,
              completedBookings: partnerData.partnerProfile.completedBookings,
              isVerified: true,
              verificationBadge: partnerData.partnerProfile.averageRating >= 4.9 ? 'gold' : 
                                 partnerData.partnerProfile.averageRating >= 4.7 ? 'silver' : 'bronze',
              isAvailable: true,
              lastActiveAt: new Date(),
            },
          },
          settings: {
            create: {},
          },
        },
      });
    } else {
      // Update existing partner
      await prisma.user.update({
        where: { email: partnerData.email },
        data: {
          passwordHash: partnerPassword,
          status: 'ACTIVE',
          profile: {
            upsert: {
              create: {
                fullName: partnerData.profile.fullName,
                displayName: partnerData.profile.displayName,
                avatarUrl,
                bio: partnerData.profile.bio,
                gender: partnerData.profile.gender,
                dateOfBirth: partnerData.profile.dateOfBirth,
                heightCm: partnerData.profile.heightCm,
                weightKg: partnerData.profile.weightKg,
                education: partnerData.profile.education as Education,
                smokingHabit: partnerData.profile.smokingHabit as SmokingHabit,
                drinkingHabit: partnerData.profile.drinkingHabit as DrinkingHabit,
                city: partnerData.profile.city,
                district: partnerData.profile.district,
                languages: partnerData.profile.languages,
                interests: partnerData.profile.interests,
                talents: partnerData.profile.talents,
                photos,
              },
              update: {
                fullName: partnerData.profile.fullName,
                displayName: partnerData.profile.displayName,
                avatarUrl,
                bio: partnerData.profile.bio,
                gender: partnerData.profile.gender,
                dateOfBirth: partnerData.profile.dateOfBirth,
                heightCm: partnerData.profile.heightCm,
                weightKg: partnerData.profile.weightKg,
                education: partnerData.profile.education as Education,
                smokingHabit: partnerData.profile.smokingHabit as SmokingHabit,
                drinkingHabit: partnerData.profile.drinkingHabit as DrinkingHabit,
                city: partnerData.profile.city,
                district: partnerData.profile.district,
                languages: partnerData.profile.languages,
                interests: partnerData.profile.interests,
                talents: partnerData.profile.talents,
                photos,
              },
            },
          },
        },
      });
    }
  }
  console.log(`Seeded ${samplePartners.length} sample partners`);

  // Seed Subscription Plans
  // Pricing Strategy:
  // - Weekly: Higher per-day cost to encourage longer subscriptions
  // - Monthly: Standard baseline
  // - 3 Months: ~16% savings
  // - 12 Months: ~41% savings (best value)
  const subscriptionPlans = [
    {
      code: 'premium_1w',
      name: 'Premium 1 Week',
      nameVi: 'Premium 1 tuần',
      description: 'Try premium features for 1 week',
      durationMonths: 0, // Special case: 7 days
      durationDays: 7,
      priceVnd: 49000,
      appleProductId: 'premium_1w',
      googleProductId: 'premium_weekly',
      sortOrder: 1,
    },
    {
      code: 'premium_1m',
      name: 'Premium 1 Month',
      nameVi: 'Premium 1 tháng',
      description: 'Unlock all premium features for 1 month',
      durationMonths: 1,
      priceVnd: 99000,
      appleProductId: 'premium_1m',
      googleProductId: 'premium_monthly',
      sortOrder: 2,
    },
    {
      code: 'premium_3m',
      name: 'Premium 3 Months',
      nameVi: 'Premium 3 tháng',
      description: 'Unlock all premium features for 3 months. Save 16%!',
      durationMonths: 3,
      priceVnd: 249000,
      originalPrice: 297000,
      discountPercent: 16,
      appleProductId: 'premium_3m',
      googleProductId: 'premium_quarterly',
      sortOrder: 3,
    },
    {
      code: 'premium_12m',
      name: 'Premium 12 Months',
      nameVi: 'Premium 12 tháng',
      description: 'Unlock all premium features for 1 year. Best value - Save 41%!',
      durationMonths: 12,
      priceVnd: 699000,
      originalPrice: 1188000,
      discountPercent: 41,
      appleProductId: 'premium_12m',
      googleProductId: 'premium_yearly',
      sortOrder: 4,
    },
  ];

  for (const plan of subscriptionPlans) {
    await prisma.subscriptionPlan.upsert({
      where: { code: plan.code },
      update: plan,
      create: plan,
    });
  }
  console.log(`Seeded ${subscriptionPlans.length} subscription plans`);

  // Seed Credit Packages (IAP Consumables)
  // Pricing: 1 Credit = 1,000 VND
  // Larger packages get bonus credits
  const creditPackages = [
    {
      code: 'credits_10',
      name: '10 Credits',
      nameVi: '10 Credits',
      description: 'Starter pack - 10 credits',
      creditAmount: 10,
      bonusCredits: 0,
      priceVnd: 9000, // 10 x 1,000 = 10K
      appleProductId: 'credits_10',
      googleProductId: 'credits_10',
      sortOrder: 1,
    },
    {
      code: 'credits_30',
      name: '30 Credits',
      nameVi: '30 Credits',
      description: 'Get 30 credits for booking services',
      creditAmount: 30,
      bonusCredits: 0,
      priceVnd: 29000, // 30K
      appleProductId: 'credits_30',
      googleProductId: 'credits_30',
      sortOrder: 2,
    },
    {
      code: 'credits_50',
      name: '50 Credits',
      nameVi: '50 Credits',
      description: 'Get 50 credits + 3 bonus credits!',
      creditAmount: 50,
      bonusCredits: 3,
      priceVnd: 49000, // 50K
      originalPrice: 53000,
      discountPercent: 6,
      appleProductId: 'credits_50',
      googleProductId: 'credits_50',
      sortOrder: 3,
    },
    {
      code: 'credits_100',
      name: '100 Credits',
      nameVi: '100 Credits',
      description: 'Get 100 credits + 8 bonus credits!',
      creditAmount: 100,
      bonusCredits: 8,
      priceVnd: 99000, // 100K
      originalPrice: 108000,
      discountPercent: 7,
      appleProductId: 'credits_100',
      googleProductId: 'credits_100',
      sortOrder: 4,
    },
    {
      code: 'credits_300',
      name: '300 Credits',
      nameVi: '300 Credits',
      description: 'Get 300 credits + 30 bonus credits!',
      creditAmount: 300,
      bonusCredits: 30,
      priceVnd: 299000, // 300K
      originalPrice: 330000,
      discountPercent: 9,
      appleProductId: 'credits_300',
      googleProductId: 'credits_300',
      sortOrder: 5,
    },
    {
      code: 'credits_500',
      name: '500 Credits',
      nameVi: '500 Credits',
      description: 'Get 500 credits + 60 bonus credits!',
      creditAmount: 500,
      bonusCredits: 60,
      priceVnd: 499000, // 500K
      originalPrice: 560000,
      discountPercent: 11,
      appleProductId: 'credits_500',
      googleProductId: 'credits_500',
      isBestValue: true,
      sortOrder: 6,
    },
    {
      code: 'credits_1000',
      name: '1000 Credits',
      nameVi: '1000 Credits',
      description: 'Get 1000 credits + 150 bonus credits! Best value!',
      creditAmount: 1000,
      bonusCredits: 150,
      priceVnd: 999000, // 1M
      originalPrice: 1150000,
      discountPercent: 13,
      appleProductId: 'credits_1000',
      googleProductId: 'credits_1000',
      sortOrder: 7,
    },
  ];

  for (const pkg of creditPackages) {
    await prisma.creditPackage.upsert({
      where: { code: pkg.code },
      update: pkg,
      create: pkg,
    });
  }
  console.log(`Seeded ${creditPackages.length} credit packages`);

    // =================== SEED PARTNERS + BOOKINGS ===================
    // Load real images from image_links.txt (4 photos per partner)
    const imageLinksPath = path.join(__dirname, 'image_links.txt');
    const allImageLinks = fs.readFileSync(imageLinksPath, 'utf-8')
      .split('\n')
      .map(l => l.trim())
      .filter(l => l.length > 0);
    const PHOTOS_PER_PARTNER = 4;
    const TOTAL_PARTNERS = Math.floor(allImageLinks.length / PHOTOS_PER_PARTNER);
    console.log(`🚀 Starting to seed ${TOTAL_PARTNERS} partners (from ${allImageLinks.length} images, ${PHOTOS_PER_PARTNER} per partner)...`);

    // Vietnamese names
    const firstNames = ['Nguyễn', 'Trần', 'Lê', 'Phạm', 'Hoàng', 'Võ', 'Đỗ', 'Ngo', 'Vương', 'Tạ', 'Huỳnh', 'Đinh', 'Bùi', 'Tôn', 'Mạc', 'Vũ'];
    const lastNames = ['Minh', 'Anh', 'Hà', 'Huy', 'Tuấn', 'Linh', 'Ngân', 'Khoa', 'An', 'Duyên', 'Bảo', 'Thắng', 'Mai', 'Sơn', 'Long', 'Hải', 'Nam', 'Tâm', 'Hạnh', 'Vy'];
    const hcmDistricts = ['Phường Xuân Hòa', 'Phường Bến Thành', 'Phường Bàn Cờ', 'Phường Diên Hồng', 'Phường Gia Định', 'Phường Cầu Ông Lãnh', 'Phường Tân Hưng', 'Phường Tân Mỹ', 'Phường Thủ Đức', 'Phường Tân Sơn Nhất'];
    const dnDistricts = ['Phường Hải Châu', 'Phường Thanh Khê', 'Phường Sơn Trà', 'Phường Ngũ Hành Sơn', 'Phường Liên Chiểu', 'Phường Cẩm Lệ', 'Xã Hòa Vang'];
    const partnerSeedCity = 'Đà Nẵng';
    const jobTitles = ['Hướng dẫn viên du lịch', 'Huấn luyện viên gym', 'Nhà thiết kế', 'Lập trình viên', 'Giáo viên', 'Thợ ảnh', 'Bartender', 'Blogger', 'Stylist'];
    const hobbies = ['du lịch', 'thể thao', 'âm nhạc', 'ẩm thực', 'công nghệ'];
    const allServiceTypes = ['walking', 'coffee', 'movie', 'dinner', 'lunch', 'karaoke', 'party', 'event', 'shopping', 'gym', 'travel', 'picnic', 'board_game', 'museum'];
    const educations_: Education[] = ['HIGH_SCHOOL', 'BACHELOR', 'MASTER', 'VOCATIONAL'];
    const smokings_: SmokingHabit[] = ['NEVER', 'SOMETIMES', 'QUIT'];
    const drinkings_: DrinkingHabit[] = ['NEVER', 'SOCIALLY', 'REGULARLY', 'QUIT'];

    const getRandomItem = <T,>(arr: T[]): T => arr[Math.floor(Math.random() * arr.length)];
    const getRandomItems = (arr: any[], count: number): any[] => {
      const result: any[] = [], copy = [...arr];
      for (let i = 0; i < Math.min(count, copy.length); i++) {
        const idx = Math.floor(Math.random() * copy.length);
            const item = copy[idx];
            if (item !== undefined) {
              result.push(item);
            }
        copy.splice(idx, 1);
      }
      return result;
    };
    const getDistrictsByCity = (city: string): string[] => city === 'Đà Nẵng' ? dnDistricts : [''];

    const BATCH_SIZE = 50;
  
    for (let batch = 0; batch < Math.ceil(TOTAL_PARTNERS / BATCH_SIZE); batch++) {
      const batchStart = batch * BATCH_SIZE;
      const batchEnd = Math.min((batch + 1) * BATCH_SIZE, TOTAL_PARTNERS);

      for (let i = batchStart; i < batchEnd; i++) {
        const firstName = getRandomItem(firstNames);
        const lastName = getRandomItem(lastNames);
        const city = partnerSeedCity;
        const district = getRandomItem(getDistrictsByCity(city));
        const email = `partner${i}@matesocial.local`;
        const phone = `+8410${String(i).padStart(8, '0')}`;
        const fullName = `${firstName} ${lastName}`;
        const displayName = lastName;
        const partnerGender = Math.random() > 0.5 ? 'MALE' : 'FEMALE';
        // Lấy 4 ảnh thật từ image_links.txt cho mỗi partner
        const photoStartIdx = i * PHOTOS_PER_PARTNER;
        const photos = allImageLinks.slice(photoStartIdx, photoStartIdx + PHOTOS_PER_PARTNER);
        const avatarUrl = photos[0];
        const experienceYears = Math.floor(Math.random() * 15) + 1;
        const avgRating = 4.5 + Math.random() * 0.5;
        const completedBookings = Math.floor(Math.random() * 300) + 50;
        const serviceTypes = getRandomItems(allServiceTypes, Math.floor(Math.random() * 4) + 2);
        const languages = ['Tiếng Việt', 'English'];
        const interests = getRandomItems(['movies', 'gaming', 'gym', 'yoga', 'running', 'coffee', 'foodie', 'photography', 'travel'], 4);
        const talents = getRandomItems(['singing', 'guitar', 'dance_modern', 'english', 'photography_talent', 'makeup'], 2);
        const dob = new Date();
        dob.setFullYear(1985 + Math.floor(Math.random() * 35));
        dob.setMonth(Math.floor(Math.random() * 12));
        dob.setDate(Math.floor(Math.random() * 28) + 1);
        const bio = `Yêu thích ${getRandomItem(hobbies)}. ${experienceYears} năm kinh nghiệm.`;
      
        try {
          const existingPartner = await prisma.user.findUnique({ where: { email } });
          if (!existingPartner) {
            const hashedPassword = await bcrypt.hash(`Partner@${Math.random().toString(36).slice(2, 8)}`, SALT_ROUNDS);
            await prisma.user.create({
              data: {
                email, phone, passwordHash: hashedPassword, role: 'PARTNER', status: 'ACTIVE', kycStatus: 'VERIFIED',
                profile: {
                  create: {
                    fullName, displayName, bio, city, district, gender: partnerGender,
                    avatarUrl,
                    dateOfBirth: dob, heightCm: 155 + Math.floor(Math.random() * 30), weightKg: 45 + Math.floor(Math.random() * 35),
                    education: getRandomItem(educations_), smokingHabit: getRandomItem(smokings_), drinkingHabit: getRandomItem(drinkings_),
                    languages, interests, talents, photos,
                  },
                },
                partnerProfile: {
                  create: {
                    hourlyRate: 200000 + Math.floor(Math.random() * 200000), minimumHours: Math.floor(Math.random() * 3) + 1,
                    serviceTypes: serviceTypes as any,
                    introduction: `Xin chào! Mình là ${displayName}, ${getRandomItem(jobTitles)}. Có ${experienceYears} năm kinh nghiệm!`,
                      experienceYears, averageRating: parseFloat(avgRating.toFixed(2)), totalReviews: Math.floor(completedBookings * 0.7),
                    completedBookings, isVerified: true,
                    verificationBadge: avgRating >= 4.9 ? 'gold' : avgRating >= 4.7 ? 'silver' : 'bronze',
                      isAvailable: true, lastActiveAt: new Date(), responseRate: parseFloat((85 + Math.random() * 15).toFixed(2)),
                    responseTime: 15 + Math.floor(Math.random() * 100),
                  },
                },
                settings: { create: {} },
              },
            });
          } else {
            await prisma.user.update({
              where: { id: existingPartner.id },
              data: {
                phone,
                role: 'PARTNER',
                status: 'ACTIVE',
                kycStatus: 'VERIFIED',
                profile: {
                  upsert: {
                    create: {
                      fullName,
                      displayName,
                      bio,
                      city,
                      district,
                      gender: partnerGender,
                      avatarUrl,
                      dateOfBirth: dob,
                      heightCm: 155 + Math.floor(Math.random() * 30),
                      weightKg: 45 + Math.floor(Math.random() * 35),
                      education: getRandomItem(educations_),
                      smokingHabit: getRandomItem(smokings_),
                      drinkingHabit: getRandomItem(drinkings_),
                      languages,
                      interests,
                      talents,
                      photos,
                    },
                    update: {
                      fullName,
                      displayName,
                      bio,
                      city,
                      district,
                      gender: partnerGender,
                      avatarUrl,
                      dateOfBirth: dob,
                      heightCm: 155 + Math.floor(Math.random() * 30),
                      weightKg: 45 + Math.floor(Math.random() * 35),
                      education: getRandomItem(educations_),
                      smokingHabit: getRandomItem(smokings_),
                      drinkingHabit: getRandomItem(drinkings_),
                      languages,
                      interests,
                      talents,
                      photos,
                    },
                  },
                },
                partnerProfile: {
                  upsert: {
                    create: {
                      hourlyRate: 200000 + Math.floor(Math.random() * 200000),
                      minimumHours: Math.floor(Math.random() * 3) + 1,
                      serviceTypes: serviceTypes as any,
                      introduction: `Xin chào! Mình là ${displayName}, ${getRandomItem(jobTitles)}. Có ${experienceYears} năm kinh nghiệm!`,
                      experienceYears,
                      averageRating: parseFloat(avgRating.toFixed(2)),
                      totalReviews: Math.floor(completedBookings * 0.7),
                      completedBookings,
                      isVerified: true,
                      verificationBadge: avgRating >= 4.9 ? 'gold' : avgRating >= 4.7 ? 'silver' : 'bronze',
                      isAvailable: true,
                      lastActiveAt: new Date(),
                      responseRate: parseFloat((85 + Math.random() * 15).toFixed(2)),
                      responseTime: 15 + Math.floor(Math.random() * 100),
                    },
                    update: {
                      hourlyRate: 200000 + Math.floor(Math.random() * 200000),
                      minimumHours: Math.floor(Math.random() * 3) + 1,
                      serviceTypes: serviceTypes as any,
                      introduction: `Xin chào! Mình là ${displayName}, ${getRandomItem(jobTitles)}. Có ${experienceYears} năm kinh nghiệm!`,
                      experienceYears,
                      averageRating: parseFloat(avgRating.toFixed(2)),
                      totalReviews: Math.floor(completedBookings * 0.7),
                      completedBookings,
                      isVerified: true,
                      verificationBadge: avgRating >= 4.9 ? 'gold' : avgRating >= 4.7 ? 'silver' : 'bronze',
                      isAvailable: true,
                      lastActiveAt: new Date(),
                      responseRate: parseFloat((85 + Math.random() * 15).toFixed(2)),
                      responseTime: 15 + Math.floor(Math.random() * 100),
                    },
                  },
                },
                settings: {
                  upsert: {
                    create: {},
                    update: {},
                  },
                },
              },
            });
          }
        } catch (error) {}
      }

      console.log(`✓ Batch ${batch + 1}/${Math.ceil(TOTAL_PARTNERS / BATCH_SIZE)} (${batchEnd}/${TOTAL_PARTNERS} partners)`);
    }

    console.log(`✓ Seeded ${TOTAL_PARTNERS} partners!`);

    // Post-process: update all profiles with provinceId/districtId based on city/district names
    console.log('🔄 Updating profiles with provinceId/districtId...');
    const allProvinces = await prisma.province.findMany();
    const allDistricts = await prisma.district.findMany();
    const allProfiles = await prisma.profile.findMany();

    const normalizeProvinceName = (value: string) => value
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .toLowerCase()
      .replace(/^thanh pho\s+/u, '')
      .replace(/^tinh\s+/u, '')
      .replace(/^tp\.?\s*/u, '')
      .replace(/\s+/g, ' ')
      .trim();

    let updatedCount = 0;
    for (const profile of allProfiles) {
      const needsProvince = !profile.provinceId;
      const needsDistrict = !profile.districtId && !!profile.district;
      if (!needsProvince && !needsDistrict) {
        continue;
      }

      let province = profile.provinceId
        ? allProvinces.find((p) => p.id === profile.provinceId)
        : null;

      if (!province && profile.city) {
        const profileCityNormalized = normalizeProvinceName(profile.city);
        province = allProvinces.find((p) => {
          const nameNormalized = normalizeProvinceName(p.name);
          const nameEnNormalized = p.nameEn ? normalizeProvinceName(p.nameEn) : '';
          return profileCityNormalized === nameNormalized || profileCityNormalized === nameEnNormalized;
        }) ?? null;
      }

      if (!province) {
        continue;
      }

      const district = profile.district
        ? allDistricts.find((d) => d.name === profile.district && d.provinceId === province.id)
        : null;

      await prisma.profile.update({
        where: { id: profile.id },
        data: {
          provinceId: province.id,
          districtId: district?.id || profile.districtId || null,
        },
      });
      updatedCount++;
    }
    console.log(`✓ Updated ${updatedCount} profiles with provinceId/districtId`);

    // Seed bookings
    console.log('📅 Seeding bookings...');
    const allUsers = await prisma.user.findMany({ where: { role: 'USER' }, select: { id: true } });
    const allPartners = await prisma.user.findMany({ where: { role: 'PARTNER' }, select: { id: true, partnerProfile: { select: { serviceTypes: true } } } });

    if (allUsers.length > 0 && allPartners.length > 0) {
      let bookingCount = 0;
      for (let i = 0; i < allPartners.length; i += BATCH_SIZE) {
        const partnerBatch = allPartners.slice(i, Math.min(i + BATCH_SIZE, allPartners.length));
        for (const partner of partnerBatch) {
          const bookingCount_ = Math.floor(Math.random() * 3) + 2;
          const serviceTypesArray = (partner.partnerProfile?.serviceTypes as string[]) || ['walking'];
          for (let b = 0; b < bookingCount_; b++) {
            try {
              const user = getRandomItem(allUsers);
              const serviceType = getRandomItem(serviceTypesArray);
              const hoursBooked = Math.floor(Math.random() * 6) + 1;
              const dateOffset = Math.floor(Math.random() * 60) - 30;
              const bookingDate = new Date();
              bookingDate.setDate(bookingDate.getDate() + dateOffset);
              bookingDate.setHours(0, 0, 0, 0);
              const startHour = 6 + Math.floor(Math.random() * 12);
              const startTime = new Date(bookingDate);
              startTime.setHours(startHour, 0, 0, 0);
              const endTime = new Date(startTime);
              endTime.setHours(startHour + hoursBooked, 0, 0, 0);
              let status = 'PENDING' as any;
              if (dateOffset < -3) status = 'COMPLETED';
              else if (dateOffset < 0) status = getRandomItem(['COMPLETED', 'CANCELLED']);
              else if (dateOffset === 0) status = getRandomItem(['IN_PROGRESS', 'CONFIRMED', 'PENDING']);
              else status = getRandomItem(['PENDING', 'CONFIRMED']);
              const bookingCode = `BK-${Date.now()}-${Math.random().toString(36).substr(2, 6).toUpperCase()}`;
              await prisma.booking.create({
                data: {
                  bookingCode, userId: user.id, partnerId: partner.id, serviceType, date: bookingDate,
                    startTime, endTime, durationHours: hoursBooked, totalHours: hoursBooked,
                   status, createdAt: new Date(bookingDate.getTime() - 3600000),
                  confirmedAt: status !== 'PENDING' ? new Date(bookingDate.getTime() - 1800000) : null,
                  completedAt: status === 'COMPLETED' ? endTime : null,
                  cancelledAt: status === 'CANCELLED' ? new Date() : null,
                },
              });
              bookingCount++;
            } catch (error) {}
          }
        }
        console.log(`✓ Bookings for: ${Math.min(i + BATCH_SIZE, allPartners.length)}/${allPartners.length} partners`);
      }
      console.log(`✓ Seeded ${bookingCount} bookings!`);
    }

    // Seed Reviews for Completed Bookings
    console.log('⭐ Seeding reviews...');
    const completedBookings = await prisma.booking.findMany({
      where: { status: 'COMPLETED' },
      select: { id: true, userId: true, partnerId: true },
    });

    console.log(`📊 Found ${completedBookings.length} COMPLETED bookings for review seeding`);

    const reviewComments = [
      'Tuyệt vời, rất vui được gặp bạn! 😊',
      'Bạn thật tuyệt vời, sẽ liên hệ lại lần sau',
      'Chuyên nghiệp, vui vẻ và thân thiện',
      'Đúng giờ, giao tiếp tốt, sẽ đặt lại',
      'Rất hài lòng với dịch vụ, cảm ơn bạn',
      'Gặp được bạn là may mắn, cảm ơn nhiều',
      'Bạn rất cute 😍 Sẽ liên hệ lại',
      'Thái độ tốt, thân thiện, đúng giờ',
      'Không hối hận khi chọn bạn',
      'Bạn giành được lòng tin của mình',
      'Chuyên nghiệp và vui vẻ',
      'Giao tiếp dễ chịu, vui vẻ',
      'Đơn giản là tuyệt vời!',
      'Bạn thật là một người tuyệt vời',
      'Offically a fan of you! 💕',
    ];

    const reviewTags = [
      ['friendly', 'professional', 'on_time'],
      ['cute', 'friendly', 'fun'],
      ['professional', 'on_time', 'kind'],
      ['talkative', 'fun', 'friendly'],
      ['attentive', 'professional', 'kind'],
      ['honest', 'authentic', 'fun'],
      ['joyful', 'energetic', 'friendly'],
      ['respectful', 'professional', 'warm'],
    ];

    let reviewCount = 0;
    for (const booking of completedBookings) {
      try {
        // User review for Partner
        const hasReview = Math.random() > 0.3; // 70% chance of review
        if (hasReview) {
          const overallRating = Math.floor(Math.random() * 2) + 4; // 4-5 stars
          await prisma.review.create({
            data: {
              bookingId: booking.id,
              reviewerId: booking.userId,
              revieweeId: booking.partnerId,
              reviewType: 'user_to_partner',
              overallRating,
              punctualityRating: Math.floor(Math.random() * 2) + 4,
              communicationRating: Math.floor(Math.random() * 2) + 4,
              attitudeRating: Math.floor(Math.random() * 2) + 4,
              appearanceRating: Math.floor(Math.random() * 2) + 4,
              serviceQualityRating: Math.floor(Math.random() * 2) + 4,
              comment: getRandomItem(reviewComments),
              tags: getRandomItem(reviewTags),
              isVisible: true,
              isAnonymous: false,
            },
          });
          reviewCount++;
        }
      } catch (error) {}
    }
    console.log(`✓ Seeded ${reviewCount} reviews!`);

    console.log('✅ Seeding completed!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
