import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();
const SALT_ROUNDS = 10;

// Service type codes
const ServiceTypeCode = {
  WALKING: 'walking',
  COFFEE: 'coffee',
  MOVIE: 'movie',
  DINNER: 'dinner',
  PARTY: 'party',
  EVENT: 'event',
  SHOPPING: 'shopping',
  GYM: 'gym',
  TRAVEL: 'travel',
  OTHER: 'other',
} as const;

async function main() {
  console.log('Start seeding...');

  // Seed Service Types - icon dùng emoji để đồng bộ giữa CMS và mobile
  const serviceTypes = [
    { code: ServiceTypeCode.WALKING, name: 'Walking', nameVi: 'Đi dạo', description: 'Đi dạo cùng partner', icon: '🚶', sortOrder: 1 },
    { code: ServiceTypeCode.COFFEE, name: 'Coffee', nameVi: 'Uống cà phê', description: 'Đi uống cà phê cùng partner', icon: '☕', sortOrder: 2 },
    { code: ServiceTypeCode.MOVIE, name: 'Movie', nameVi: 'Xem phim', description: 'Đi xem phim cùng partner', icon: '🎬', sortOrder: 3 },
    { code: ServiceTypeCode.DINNER, name: 'Dinner', nameVi: 'Ăn tối', description: 'Đi ăn tối cùng partner', icon: '🍽️', sortOrder: 4 },
    { code: ServiceTypeCode.PARTY, name: 'Party', nameVi: 'Tiệc tùng', description: 'Tham gia tiệc cùng partner', icon: '🎉', sortOrder: 5 },
    { code: ServiceTypeCode.EVENT, name: 'Event', nameVi: 'Sự kiện', description: 'Tham gia sự kiện cùng partner', icon: '📅', sortOrder: 6 },
    { code: ServiceTypeCode.SHOPPING, name: 'Shopping', nameVi: 'Mua sắm', description: 'Đi mua sắm cùng partner', icon: '🛍️', sortOrder: 7 },
    { code: ServiceTypeCode.GYM, name: 'Gym', nameVi: 'Tập gym', description: 'Đi tập gym cùng partner', icon: '💪', sortOrder: 8 },
    { code: ServiceTypeCode.TRAVEL, name: 'Travel', nameVi: 'Du lịch', description: 'Du lịch cùng partner', icon: '✈️', sortOrder: 9 },
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
    { key: 'support_email', value: 'support@matesocial.vn', description: 'Support email address' },
    { key: 'support_phone', value: '+84 123 456 789', description: 'Support phone number' },
    { key: 'default_currency', value: 'VND', description: 'Default currency code' },
    { key: 'default_language', value: 'vi', description: 'Default language code' },
    { key: 'timezone', value: 'Asia/Ho_Chi_Minh', description: 'Default timezone' },
    { key: 'support_hotline', value: '1900-xxxx', description: 'Support hotline number' },
    // Booking
    { key: 'min_booking_hours', value: '1', description: 'Minimum booking hours' },
    { key: 'max_booking_hours', value: '8', description: 'Maximum booking hours' },
    { key: 'advance_booking_days', value: '30', description: 'Days in advance users can book' },
    { key: 'cancellation_hours', value: '24', description: 'Hours before booking for free cancellation' },
    { key: 'service_fee_percent', value: '15', description: 'Platform service fee percentage' },
    { key: 'partner_commission_percent', value: '85', description: 'Partner commission percentage' },
    { key: 'auto_confirm_booking', value: 'false', description: 'Auto-confirm bookings without partner approval' },
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
    { key: 'max_login_attempts', value: '5', description: 'Max failed login attempts before lock' },
    { key: 'session_timeout', value: '30', description: 'Token expiry in days' },
    { key: 'password_min_length', value: '8', description: 'Minimum password length' },
    { key: 'enforce_strong_password', value: 'true', description: 'Enforce strong password policy' },
  ];

  for (const setting of appSettings) {
    await prisma.appSetting.upsert({
      where: { key: setting.key },
      update: setting,
      create: setting,
    });
  }

  console.log(`Seeded ${appSettings.length} app settings`);

  // Seed Master Data - Provinces (Vietnam)
  const provinces = [
    { code: 'HCM', name: 'TP. Hồ Chí Minh', nameEn: 'Ho Chi Minh City', sortOrder: 1 },
    { code: 'HN', name: 'Hà Nội', nameEn: 'Hanoi', sortOrder: 2 },
    { code: 'DN', name: 'Đà Nẵng', nameEn: 'Da Nang', sortOrder: 3 },
    { code: 'HP', name: 'Hải Phòng', nameEn: 'Hai Phong', sortOrder: 4 },
    { code: 'CT', name: 'Cần Thơ', nameEn: 'Can Tho', sortOrder: 5 },
    { code: 'BD', name: 'Bình Dương', nameEn: 'Binh Duong', sortOrder: 6 },
    { code: 'DNG', name: 'Đồng Nai', nameEn: 'Dong Nai', sortOrder: 7 },
    { code: 'KH', name: 'Khánh Hòa', nameEn: 'Khanh Hoa', sortOrder: 8 },
    { code: 'TTH', name: 'Thừa Thiên Huế', nameEn: 'Thua Thien Hue', sortOrder: 9 },
    { code: 'QN', name: 'Quảng Ninh', nameEn: 'Quang Ninh', sortOrder: 10 },
  ];

  for (const province of provinces) {
    await prisma.province.upsert({
      where: { code: province.code },
      update: province,
      create: province,
    });
  }
  console.log(`Seeded ${provinces.length} provinces`);

  // Seed Districts for HCM
  const hcmProvince = await prisma.province.findUnique({ where: { code: 'HCM' } });
  if (hcmProvince) {
    const hcmDistricts = [
      { code: 'Q1', name: 'Quận 1', nameEn: 'District 1', sortOrder: 1 },
      { code: 'Q2', name: 'Quận 2 (TP Thủ Đức)', nameEn: 'District 2', sortOrder: 2 },
      { code: 'Q3', name: 'Quận 3', nameEn: 'District 3', sortOrder: 3 },
      { code: 'Q4', name: 'Quận 4', nameEn: 'District 4', sortOrder: 4 },
      { code: 'Q5', name: 'Quận 5', nameEn: 'District 5', sortOrder: 5 },
      { code: 'Q6', name: 'Quận 6', nameEn: 'District 6', sortOrder: 6 },
      { code: 'Q7', name: 'Quận 7', nameEn: 'District 7', sortOrder: 7 },
      { code: 'Q8', name: 'Quận 8', nameEn: 'District 8', sortOrder: 8 },
      { code: 'Q9', name: 'Quận 9 (TP Thủ Đức)', nameEn: 'District 9', sortOrder: 9 },
      { code: 'Q10', name: 'Quận 10', nameEn: 'District 10', sortOrder: 10 },
      { code: 'Q11', name: 'Quận 11', nameEn: 'District 11', sortOrder: 11 },
      { code: 'Q12', name: 'Quận 12', nameEn: 'District 12', sortOrder: 12 },
      { code: 'BT', name: 'Quận Bình Thạnh', nameEn: 'Binh Thanh District', sortOrder: 13 },
      { code: 'GV', name: 'Quận Gò Vấp', nameEn: 'Go Vap District', sortOrder: 14 },
      { code: 'PN', name: 'Quận Phú Nhuận', nameEn: 'Phu Nhuan District', sortOrder: 15 },
      { code: 'TB', name: 'Quận Tân Bình', nameEn: 'Tan Binh District', sortOrder: 16 },
      { code: 'TP', name: 'Quận Tân Phú', nameEn: 'Tan Phu District', sortOrder: 17 },
      { code: 'TD', name: 'TP Thủ Đức', nameEn: 'Thu Duc City', sortOrder: 18 },
    ];

    for (const district of hcmDistricts) {
      const existingDistrict = await prisma.district.findFirst({
        where: { code: district.code, provinceId: hcmProvince.id },
      });
      if (!existingDistrict) {
        await prisma.district.create({
          data: { ...district, provinceId: hcmProvince.id },
        });
      }
    }
    console.log(`Seeded ${hcmDistricts.length} districts for HCM`);
  }

  // Seed Districts for HN
  const hnProvince = await prisma.province.findUnique({ where: { code: 'HN' } });
  if (hnProvince) {
    const hnDistricts = [
      { code: 'HK', name: 'Quận Hoàn Kiếm', nameEn: 'Hoan Kiem District', sortOrder: 1 },
      { code: 'BD', name: 'Quận Ba Đình', nameEn: 'Ba Dinh District', sortOrder: 2 },
      { code: 'DD', name: 'Quận Đống Đa', nameEn: 'Dong Da District', sortOrder: 3 },
      { code: 'TX', name: 'Quận Thanh Xuân', nameEn: 'Thanh Xuan District', sortOrder: 4 },
      { code: 'CG', name: 'Quận Cầu Giấy', nameEn: 'Cau Giay District', sortOrder: 5 },
      { code: 'HM', name: 'Quận Hai Bà Trưng', nameEn: 'Hai Ba Trung District', sortOrder: 6 },
      { code: 'LB', name: 'Quận Long Biên', nameEn: 'Long Bien District', sortOrder: 7 },
      { code: 'TH', name: 'Quận Tây Hồ', nameEn: 'Tay Ho District', sortOrder: 8 },
      { code: 'HE', name: 'Quận Hoàng Mai', nameEn: 'Hoang Mai District', sortOrder: 9 },
      { code: 'NT', name: 'Quận Nam Từ Liêm', nameEn: 'Nam Tu Liem District', sortOrder: 10 },
    ];

    for (const district of hnDistricts) {
      const existingDistrict = await prisma.district.findFirst({
        where: { code: district.code, provinceId: hnProvince.id },
      });
      if (!existingDistrict) {
        await prisma.district.create({
          data: { ...district, provinceId: hnProvince.id },
        });
      }
    }
    console.log(`Seeded ${hnDistricts.length} districts for HN`);
  }

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
        city: 'TP. Hồ Chí Minh',
        district: 'Quận Bình Thạnh',
        languages: ['Tiếng Việt', 'English'],
        interests: ['mountain', 'camping', 'running', 'yoga'],
        talents: ['guitar', 'photography_talent'],
      },
    },
  ];

  for (const userData of sampleUsers) {
    await prisma.user.upsert({
      where: { email: userData.email },
      update: {
        passwordHash: userPassword,
        status: 'ACTIVE',
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
            city: userData.profile.city,
            district: userData.profile.district,
            languages: userData.profile.languages,
            interests: userData.profile.interests,
            talents: userData.profile.talents,
            photos: [],
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

  for (const partnerData of samplePartners) {
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
              avatarUrl: partnerData.profile.avatarUrl,
              bio: partnerData.profile.bio,
              gender: partnerData.profile.gender,
              dateOfBirth: partnerData.profile.dateOfBirth,
              heightCm: partnerData.profile.heightCm,
              weightKg: partnerData.profile.weightKg,
              city: partnerData.profile.city,
              district: partnerData.profile.district,
              languages: partnerData.profile.languages,
              interests: partnerData.profile.interests,
              talents: partnerData.profile.talents,
              photos: [],
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
        },
      });
    }
  }
  console.log(`Seeded ${samplePartners.length} sample partners`);

  console.log('Seeding completed!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
