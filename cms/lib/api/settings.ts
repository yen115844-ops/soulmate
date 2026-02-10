import apiClient from "@/lib/api-client";

/** Backend returns { items: AppSetting[], values: Record<string, string> } */
export interface AppSettingItem {
  id: string;
  key: string;
  value: string;
  description?: string;
}

export interface AppSettingsResponse {
  items: AppSettingItem[];
  values: Record<string, string>;
}

/** Map CMS form keys (camelCase) to backend keys (snake_case) */
export const SETTINGS_KEY_MAP = {
  // General
  appName: "app_name",
  appDescription: "app_description",
  supportEmail: "support_email",
  supportPhone: "support_phone",
  defaultCurrency: "default_currency",
  defaultLanguage: "default_language",
  timezone: "timezone",
  // Booking
  minBookingHours: "min_booking_hours",
  maxBookingHours: "max_booking_hours",
  advanceBookingDays: "advance_booking_days",
  cancellationHours: "cancellation_hours",
  serviceFeePercent: "service_fee_percent",
  partnerCommissionPercent: "partner_commission_percent",
  autoConfirmBooking: "auto_confirm_booking",
  allowInstantBooking: "allow_instant_booking",
  // Notifications
  emailNotifications: "email_notifications",
  pushNotifications: "push_notifications",
  smsNotifications: "sms_notifications",
  adminEmailAlerts: "admin_email_alerts",
  newUserAlert: "new_user_alert",
  newBookingAlert: "new_booking_alert",
  kycPendingAlert: "kyc_pending_alert",
  // Security
  requireEmailVerification: "require_email_verification",
  requirePhoneVerification: "require_phone_verification",
  requireKycForPartner: "require_kyc_for_partner",
  maxLoginAttempts: "max_login_attempts",
  sessionTimeout: "session_timeout",
  passwordMinLength: "password_min_length",
  enforceStrongPassword: "enforce_strong_password",
} as const;

const REVERSE_KEY_MAP: Record<string, string> = {};
Object.entries(SETTINGS_KEY_MAP).forEach(([camel, snake]) => {
  REVERSE_KEY_MAP[snake] = camel;
});

/** Convert backend values (snake_case keys) to CMS form state (camelCase keys) */
export function valuesToForm<T extends object>(
  values: Record<string, string>,
  defaults: T
): T {
  const result = { ...defaults };
  Object.entries(values).forEach(([snakeKey, value]) => {
    const camelKey = REVERSE_KEY_MAP[snakeKey];
    if (camelKey && camelKey in result) {
      const current = (result as Record<string, unknown>)[camelKey];
      if (typeof current === "boolean") {
        (result as Record<string, unknown>)[camelKey] = value === "true";
      } else if (typeof current === "number") {
        (result as Record<string, unknown>)[camelKey] = parseInt(value, 10) || 0;
      } else {
        (result as Record<string, unknown>)[camelKey] = value;
      }
    }
  });
  return result;
}

/** Convert CMS form state (camelCase) to backend values (snake_case keys, string values) */
export function formToValues(form: object): Record<string, string> {
  const result: Record<string, string> = {};
  Object.entries(form).forEach(([camelKey, value]) => {
    const snakeKey = (SETTINGS_KEY_MAP as Record<string, string>)[camelKey];
    if (snakeKey != null) {
      result[snakeKey] = typeof value === "boolean" ? String(value) : String(value ?? "");
    }
  });
  return result;
}

export const settingsApi = {
  getAll: async (): Promise<AppSettingsResponse> => {
    const response = await apiClient.get<{ data: AppSettingsResponse }>(
      "/admin/settings"
    );
    return response.data.data ?? response.data;
  },

  update: async (values: Record<string, string>): Promise<AppSettingsResponse> => {
    const response = await apiClient.put<{ data: AppSettingsResponse }>(
      "/admin/settings",
      { values }
    );
    return response.data.data ?? response.data;
  },
};
