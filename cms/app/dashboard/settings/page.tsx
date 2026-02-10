"use client";

import { useQuery, useQueryClient } from "@tanstack/react-query";
import {
    Bell,
    Mail,
    Save,
    Server,
    Settings2,
    Shield,
    Smartphone
} from "lucide-react";
import { useEffect, useState } from "react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select";
import { Separator } from "@/components/ui/separator";
import { Skeleton } from "@/components/ui/skeleton";
import { Switch } from "@/components/ui/switch";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Textarea } from "@/components/ui/textarea";
import {
    formToValues,
    settingsApi,
    valuesToForm,
} from "@/lib/api/settings";
import { handleApiError } from "@/lib/api-client";

// Types for settings
interface GeneralSettings {
  appName: string;
  appDescription: string;
  supportEmail: string;
  supportPhone: string;
  defaultCurrency: string;
  defaultLanguage: string;
  timezone: string;
}

interface BookingSettings {
  minBookingHours: number;
  maxBookingHours: number;
  advanceBookingDays: number;
  cancellationHours: number;
  serviceFeePercent: number;
  partnerCommissionPercent: number;
  autoConfirmBooking: boolean;
  allowInstantBooking: boolean;
}

interface NotificationSettings {
  emailNotifications: boolean;
  pushNotifications: boolean;
  smsNotifications: boolean;
  adminEmailAlerts: boolean;
  newUserAlert: boolean;
  newBookingAlert: boolean;
  kycPendingAlert: boolean;
}

interface SecuritySettings {
  requireEmailVerification: boolean;
  requirePhoneVerification: boolean;
  requireKycForPartner: boolean;
  maxLoginAttempts: number;
  sessionTimeout: number;
  passwordMinLength: number;
  enforceStrongPassword: boolean;
}

const DEFAULT_GENERAL: GeneralSettings = {
  appName: "Mate Social",
  appDescription: "Nền tảng đặt chỗ bạn đồng hành",
  supportEmail: "support@matesocial.vn",
  supportPhone: "+84 123 456 789",
  defaultCurrency: "VND",
  defaultLanguage: "vi",
  timezone: "Asia/Ho_Chi_Minh",
};
const DEFAULT_BOOKING: BookingSettings = {
  minBookingHours: 1,
  maxBookingHours: 8,
  advanceBookingDays: 30,
  cancellationHours: 24,
  serviceFeePercent: 15,
  partnerCommissionPercent: 85,
  autoConfirmBooking: false,
  allowInstantBooking: true,
};
const DEFAULT_NOTIFICATION: NotificationSettings = {
  emailNotifications: true,
  pushNotifications: true,
  smsNotifications: false,
  adminEmailAlerts: true,
  newUserAlert: true,
  newBookingAlert: true,
  kycPendingAlert: true,
};
const DEFAULT_SECURITY: SecuritySettings = {
  requireEmailVerification: true,
  requirePhoneVerification: false,
  requireKycForPartner: true,
  maxLoginAttempts: 5,
  sessionTimeout: 30, // ngày (thời gian hết hạn token)
  passwordMinLength: 8,
  enforceStrongPassword: true,
};

export default function SettingsPage() {
  const queryClient = useQueryClient();
  const [activeTab, setActiveTab] = useState("general");

  const { data: settingsData, isLoading } = useQuery({
    queryKey: ["admin", "settings"],
    queryFn: () => settingsApi.getAll(),
  });

  const [generalSettings, setGeneralSettings] = useState<GeneralSettings>(DEFAULT_GENERAL);
  const [bookingSettings, setBookingSettings] = useState<BookingSettings>(DEFAULT_BOOKING);
  const [notificationSettings, setNotificationSettings] = useState<NotificationSettings>(DEFAULT_NOTIFICATION);
  const [securitySettings, setSecuritySettings] = useState<SecuritySettings>(DEFAULT_SECURITY);
  const [isSaving, setIsSaving] = useState(false);

  // Sync backend values to form state when data loads
  useEffect(() => {
    if (!settingsData?.values) return;
    const v = settingsData.values;
    setGeneralSettings(valuesToForm<GeneralSettings>(v, DEFAULT_GENERAL));
    setBookingSettings(valuesToForm<BookingSettings>(v, DEFAULT_BOOKING));
    setNotificationSettings(valuesToForm<NotificationSettings>(v, DEFAULT_NOTIFICATION));
    setSecuritySettings(valuesToForm<SecuritySettings>(v, DEFAULT_SECURITY));
  }, [settingsData?.values]);

  const handleSaveGeneral = async () => {
    setIsSaving(true);
    try {
      const values = formToValues(generalSettings);
      await settingsApi.update(values);
      await queryClient.invalidateQueries({ queryKey: ["admin", "settings"] });
      toast.success("Đã lưu cài đặt chung");
    } catch (err) {
      toast.error(handleApiError(err) || "Lưu cài đặt thất bại");
    } finally {
      setIsSaving(false);
    }
  };

  const handleSaveBooking = async () => {
    setIsSaving(true);
    try {
      const values = formToValues(bookingSettings);
      await settingsApi.update(values);
      await queryClient.invalidateQueries({ queryKey: ["admin", "settings"] });
      toast.success("Đã lưu cài đặt đặt chỗ");
    } catch (err) {
      toast.error(handleApiError(err) || "Lưu cài đặt thất bại");
    } finally {
      setIsSaving(false);
    }
  };

  const handleSaveNotifications = async () => {
    setIsSaving(true);
    try {
      const values = formToValues(notificationSettings);
      await settingsApi.update(values);
      await queryClient.invalidateQueries({ queryKey: ["admin", "settings"] });
      toast.success("Đã lưu cài đặt thông báo");
    } catch (err) {
      toast.error(handleApiError(err) || "Lưu cài đặt thất bại");
    } finally {
      setIsSaving(false);
    }
  };

  const handleSaveSecurity = async () => {
    setIsSaving(true);
    try {
      const values = formToValues(securitySettings);
      await settingsApi.update(values);
      await queryClient.invalidateQueries({ queryKey: ["admin", "settings"] });
      toast.success("Đã lưu cài đặt bảo mật");
    } catch (err) {
      toast.error(handleApiError(err) || "Lưu cài đặt thất bại");
    } finally {
      setIsSaving(false);
    }
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div>
          <Skeleton className="h-9 w-48" />
          <Skeleton className="mt-2 h-5 w-80" />
        </div>
        <Skeleton className="h-10 w-full max-w-[600px]" />
        <Skeleton className="h-[400px] w-full" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Cài đặt hệ thống</h1>
        <p className="text-muted-foreground">
          Quản lý cấu hình và tùy chọn hệ thống
        </p>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
        <TabsList className="grid w-full grid-cols-4 lg:w-[600px]">
          <TabsTrigger value="general" className="flex items-center gap-2">
            <Settings2 className="h-4 w-4" />
            Chung
          </TabsTrigger>
          <TabsTrigger value="booking" className="flex items-center gap-2">
            <Server className="h-4 w-4" />
            Đặt chỗ
          </TabsTrigger>
          <TabsTrigger value="notifications" className="flex items-center gap-2">
            <Bell className="h-4 w-4" />
            Thông báo
          </TabsTrigger>
          <TabsTrigger value="security" className="flex items-center gap-2">
            <Shield className="h-4 w-4" />
            Bảo mật
          </TabsTrigger>
        </TabsList>

        {/* Cài đặt chung */}
        <TabsContent value="general" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Cài đặt ứng dụng</CardTitle>
              <CardDescription>
                Cấu hình thông tin cơ bản của ứng dụng
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="grid gap-4 md:grid-cols-2">
                <div className="space-y-2">
                  <Label htmlFor="appName">Tên ứng dụng</Label>
                  <Input
                    id="appName"
                    value={generalSettings.appName}
                    onChange={(e) =>
                      setGeneralSettings({ ...generalSettings, appName: e.target.value })
                    }
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="supportEmail">Email hỗ trợ</Label>
                  <Input
                    id="supportEmail"
                    type="email"
                    value={generalSettings.supportEmail}
                    onChange={(e) =>
                      setGeneralSettings({ ...generalSettings, supportEmail: e.target.value })
                    }
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="appDescription">Mô tả ứng dụng</Label>
                <Textarea
                  id="appDescription"
                  value={generalSettings.appDescription}
                  onChange={(e) =>
                    setGeneralSettings({ ...generalSettings, appDescription: e.target.value })
                  }
                />
              </div>

              <div className="grid gap-4 md:grid-cols-2">
                <div className="space-y-2">
                  <Label htmlFor="supportPhone">Số điện thoại hỗ trợ</Label>
                  <Input
                    id="supportPhone"
                    value={generalSettings.supportPhone}
                    onChange={(e) =>
                      setGeneralSettings({ ...generalSettings, supportPhone: e.target.value })
                    }
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="defaultCurrency">Tiền tệ mặc định</Label>
                  <Select
                    value={generalSettings.defaultCurrency}
                    onValueChange={(value) =>
                      setGeneralSettings({ ...generalSettings, defaultCurrency: value })
                    }
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="VND">VND - Việt Nam Đồng</SelectItem>
                      <SelectItem value="USD">USD - Đô la Mỹ</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div className="grid gap-4 md:grid-cols-2">
                <div className="space-y-2">
                  <Label htmlFor="defaultLanguage">Ngôn ngữ mặc định</Label>
                  <Select
                    value={generalSettings.defaultLanguage}
                    onValueChange={(value) =>
                      setGeneralSettings({ ...generalSettings, defaultLanguage: value })
                    }
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="vi">Tiếng Việt</SelectItem>
                      <SelectItem value="en">Tiếng Anh</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="timezone">Múi giờ</Label>
                  <Select
                    value={generalSettings.timezone}
                    onValueChange={(value) =>
                      setGeneralSettings({ ...generalSettings, timezone: value })
                    }
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="Asia/Ho_Chi_Minh">Asia/Ho_Chi_Minh (GMT+7)</SelectItem>
                      <SelectItem value="Asia/Bangkok">Asia/Bangkok (GMT+7)</SelectItem>
                      <SelectItem value="UTC">UTC (GMT+0)</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div className="flex justify-end">
                <Button onClick={handleSaveGeneral} disabled={isSaving}>
                  <Save className="mr-2 h-4 w-4" />
                  {isSaving ? "Đang lưu..." : "Lưu thay đổi"}
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Cài đặt đặt chỗ */}
        <TabsContent value="booking" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Cấu hình đặt chỗ</CardTitle>
              <CardDescription>
                Cấu hình quy tắc đặt chỗ và giá
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="grid gap-4 md:grid-cols-2">
                <div className="space-y-2">
                  <Label htmlFor="minBookingHours">Số giờ đặt tối thiểu</Label>
                  <Input
                    id="minBookingHours"
                    type="number"
                    min={1}
                    value={bookingSettings.minBookingHours}
                    onChange={(e) =>
                      setBookingSettings({
                        ...bookingSettings,
                        minBookingHours: parseInt(e.target.value),
                      })
                    }
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="maxBookingHours">Số giờ đặt tối đa</Label>
                  <Input
                    id="maxBookingHours"
                    type="number"
                    min={1}
                    value={bookingSettings.maxBookingHours}
                    onChange={(e) =>
                      setBookingSettings({
                        ...bookingSettings,
                        maxBookingHours: parseInt(e.target.value),
                      })
                    }
                  />
                </div>
              </div>

              <div className="grid gap-4 md:grid-cols-2">
                <div className="space-y-2">
                  <Label htmlFor="advanceBookingDays">Số ngày đặt trước</Label>
                  <Input
                    id="advanceBookingDays"
                    type="number"
                    min={1}
                    value={bookingSettings.advanceBookingDays}
                    onChange={(e) =>
                      setBookingSettings({
                        ...bookingSettings,
                        advanceBookingDays: parseInt(e.target.value),
                      })
                    }
                  />
                  <p className="text-xs text-muted-foreground">
                    Số ngày tối đa người dùng có thể đặt trước
                  </p>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="cancellationHours">Hủy miễn phí (giờ)</Label>
                  <Input
                    id="cancellationHours"
                    type="number"
                    min={1}
                    value={bookingSettings.cancellationHours}
                    onChange={(e) =>
                      setBookingSettings({
                        ...bookingSettings,
                        cancellationHours: parseInt(e.target.value),
                      })
                    }
                  />
                  <p className="text-xs text-muted-foreground">
                    Hủy trước số giờ này so với giờ đặt thì không mất phí
                  </p>
                </div>
              </div>

              <Separator />

              <div className="grid gap-4 md:grid-cols-2">
                <div className="space-y-2">
                  <Label htmlFor="serviceFeePercent">Phí dịch vụ (%)</Label>
                  <Input
                    id="serviceFeePercent"
                    type="number"
                    min={0}
                    max={100}
                    value={bookingSettings.serviceFeePercent}
                    onChange={(e) =>
                      setBookingSettings({
                        ...bookingSettings,
                        serviceFeePercent: parseInt(e.target.value),
                      })
                    }
                  />
                  <p className="text-xs text-muted-foreground">
                    Phí nền tảng thu từ người dùng
                  </p>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="partnerCommissionPercent">Hoa hồng đối tác (%)</Label>
                  <Input
                    id="partnerCommissionPercent"
                    type="number"
                    min={0}
                    max={100}
                    value={bookingSettings.partnerCommissionPercent}
                    onChange={(e) =>
                      setBookingSettings({
                        ...bookingSettings,
                        partnerCommissionPercent: parseInt(e.target.value),
                      })
                    }
                  />
                  <p className="text-xs text-muted-foreground">
                    Tỷ lệ tiền đặt chỗ trả cho đối tác
                  </p>
                </div>
              </div>

              <Separator />

              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <div className="space-y-0.5">
                    <Label>Tự động xác nhận đặt chỗ</Label>
                    <p className="text-sm text-muted-foreground">
                      Xác nhận đặt chỗ tự động không cần đối tác duyệt
                    </p>
                  </div>
                  <Switch
                    checked={bookingSettings.autoConfirmBooking}
                    onCheckedChange={(checked) =>
                      setBookingSettings({ ...bookingSettings, autoConfirmBooking: checked })
                    }
                  />
                </div>
                <div className="flex items-center justify-between">
                  <div className="space-y-0.5">
                    <Label>Cho phép đặt chỗ ngay</Label>
                    <p className="text-sm text-muted-foreground">
                      Người dùng có thể đặt đối tác ngay không cần chờ duyệt
                    </p>
                  </div>
                  <Switch
                    checked={bookingSettings.allowInstantBooking}
                    onCheckedChange={(checked) =>
                      setBookingSettings({ ...bookingSettings, allowInstantBooking: checked })
                    }
                  />
                </div>
              </div>

              <div className="flex justify-end">
                <Button onClick={handleSaveBooking} disabled={isSaving}>
                  <Save className="mr-2 h-4 w-4" />
                  {isSaving ? "Đang lưu..." : "Lưu thay đổi"}
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Cài đặt thông báo */}
        <TabsContent value="notifications" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Tùy chọn thông báo</CardTitle>
              <CardDescription>
                Cấu hình cách gửi thông báo
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="space-y-4">
                <h4 className="text-sm font-medium">Thông báo cho người dùng</h4>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <Mail className="h-4 w-4 text-muted-foreground" />
                    <div className="space-y-0.5">
                      <Label>Thông báo qua email</Label>
                      <p className="text-sm text-muted-foreground">
                        Gửi thông báo qua email
                      </p>
                    </div>
                  </div>
                  <Switch
                    checked={notificationSettings.emailNotifications}
                    onCheckedChange={(checked) =>
                      setNotificationSettings({ ...notificationSettings, emailNotifications: checked })
                    }
                  />
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <Smartphone className="h-4 w-4 text-muted-foreground" />
                    <div className="space-y-0.5">
                      <Label>Thông báo đẩy</Label>
                      <p className="text-sm text-muted-foreground">
                        Gửi thông báo đẩy đến ứng dụng di động
                      </p>
                    </div>
                  </div>
                  <Switch
                    checked={notificationSettings.pushNotifications}
                    onCheckedChange={(checked) =>
                      setNotificationSettings({ ...notificationSettings, pushNotifications: checked })
                    }
                  />
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <Bell className="h-4 w-4 text-muted-foreground" />
                    <div className="space-y-0.5">
                      <Label>Thông báo SMS</Label>
                      <p className="text-sm text-muted-foreground">
                        Gửi thông báo quan trọng qua SMS
                      </p>
                    </div>
                  </div>
                  <Switch
                    checked={notificationSettings.smsNotifications}
                    onCheckedChange={(checked) =>
                      setNotificationSettings({ ...notificationSettings, smsNotifications: checked })
                    }
                  />
                </div>
              </div>

              <Separator />

              <div className="space-y-4">
                <h4 className="text-sm font-medium">Cảnh báo cho quản trị</h4>
                <div className="flex items-center justify-between">
                  <div className="space-y-0.5">
                    <Label>Cảnh báo email cho quản trị</Label>
                    <p className="text-sm text-muted-foreground">
                      Nhận cảnh báo quản trị qua email
                    </p>
                  </div>
                  <Switch
                    checked={notificationSettings.adminEmailAlerts}
                    onCheckedChange={(checked) =>
                      setNotificationSettings({ ...notificationSettings, adminEmailAlerts: checked })
                    }
                  />
                </div>
                <div className="flex items-center justify-between">
                  <div className="space-y-0.5">
                    <Label>Đăng ký người dùng mới</Label>
                    <p className="text-sm text-muted-foreground">
                      Cảnh báo khi có người dùng mới đăng ký
                    </p>
                  </div>
                  <Switch
                    checked={notificationSettings.newUserAlert}
                    onCheckedChange={(checked) =>
                      setNotificationSettings({ ...notificationSettings, newUserAlert: checked })
                    }
                  />
                </div>
                <div className="flex items-center justify-between">
                  <div className="space-y-0.5">
                    <Label>Đặt chỗ mới</Label>
                    <p className="text-sm text-muted-foreground">
                      Cảnh báo khi có đặt chỗ mới
                    </p>
                  </div>
                  <Switch
                    checked={notificationSettings.newBookingAlert}
                    onCheckedChange={(checked) =>
                      setNotificationSettings({ ...notificationSettings, newBookingAlert: checked })
                    }
                  />
                </div>
                <div className="flex items-center justify-between">
                  <div className="space-y-0.5">
                    <Label>KYC chờ duyệt</Label>
                    <p className="text-sm text-muted-foreground">
                      Cảnh báo khi có KYC chờ xác minh
                    </p>
                  </div>
                  <Switch
                    checked={notificationSettings.kycPendingAlert}
                    onCheckedChange={(checked) =>
                      setNotificationSettings({ ...notificationSettings, kycPendingAlert: checked })
                    }
                  />
                </div>
              </div>

              <div className="flex justify-end">
                <Button onClick={handleSaveNotifications} disabled={isSaving}>
                  <Save className="mr-2 h-4 w-4" />
                  {isSaving ? "Đang lưu..." : "Lưu thay đổi"}
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Cài đặt bảo mật */}
        <TabsContent value="security" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Cấu hình bảo mật</CardTitle>
              <CardDescription>
                Cấu hình bảo mật và xác thực
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="space-y-4">
                <h4 className="text-sm font-medium">Yêu cầu xác minh</h4>
                <div className="flex items-center justify-between">
                  <div className="space-y-0.5">
                    <Label>Bắt buộc xác minh email</Label>
                    <p className="text-sm text-muted-foreground">
                      Người dùng phải xác minh email trước khi sử dụng tính năng
                    </p>
                  </div>
                  <Switch
                    checked={securitySettings.requireEmailVerification}
                    onCheckedChange={(checked) =>
                      setSecuritySettings({ ...securitySettings, requireEmailVerification: checked })
                    }
                  />
                </div>
                <div className="flex items-center justify-between">
                  <div className="space-y-0.5">
                    <Label>Bắt buộc xác minh số điện thoại</Label>
                    <p className="text-sm text-muted-foreground">
                      Người dùng phải xác minh số điện thoại
                    </p>
                  </div>
                  <Switch
                    checked={securitySettings.requirePhoneVerification}
                    onCheckedChange={(checked) =>
                      setSecuritySettings({ ...securitySettings, requirePhoneVerification: checked })
                    }
                  />
                </div>
                <div className="flex items-center justify-between">
                  <div className="space-y-0.5">
                    <Label>Bắt buộc KYC cho đối tác</Label>
                    <p className="text-sm text-muted-foreground">
                      Đối tác phải hoàn thành KYC trước khi nhận đặt chỗ
                    </p>
                  </div>
                  <Switch
                    checked={securitySettings.requireKycForPartner}
                    onCheckedChange={(checked) =>
                      setSecuritySettings({ ...securitySettings, requireKycForPartner: checked })
                    }
                  />
                </div>
              </div>

              <Separator />

              <div className="grid gap-4 md:grid-cols-2">
                <div className="space-y-2">
                  <Label htmlFor="maxLoginAttempts">Số lần đăng nhập sai tối đa</Label>
                  <Input
                    id="maxLoginAttempts"
                    type="number"
                    min={3}
                    max={10}
                    value={securitySettings.maxLoginAttempts}
                    onChange={(e) =>
                      setSecuritySettings({
                        ...securitySettings,
                        maxLoginAttempts: parseInt(e.target.value),
                      })
                    }
                  />
                  <p className="text-xs text-muted-foreground">
                    Khóa tài khoản sau số lần đăng nhập sai
                  </p>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="sessionTimeout">Thời gian hết hạn token (ngày)</Label>
                  <Input
                    id="sessionTimeout"
                    type="number"
                    min={1}
                    max={365}
                    value={securitySettings.sessionTimeout}
                    onChange={(e) =>
                      setSecuritySettings({
                        ...securitySettings,
                        sessionTimeout: parseInt(e.target.value, 10) || 1,
                      })
                    }
                  />
                  <p className="text-xs text-muted-foreground">
                    Token đăng nhập hết hạn sau số ngày
                  </p>
                </div>
              </div>

              <Separator />

              <div className="space-y-4">
                <h4 className="text-sm font-medium">Chính sách mật khẩu</h4>
                <div className="grid gap-4 md:grid-cols-2">
                  <div className="space-y-2">
                    <Label htmlFor="passwordMinLength">Độ dài mật khẩu tối thiểu</Label>
                    <Input
                      id="passwordMinLength"
                      type="number"
                      min={6}
                      max={20}
                      value={securitySettings.passwordMinLength}
                      onChange={(e) =>
                        setSecuritySettings({
                          ...securitySettings,
                          passwordMinLength: parseInt(e.target.value),
                        })
                      }
                    />
                  </div>
                  <div className="flex items-center justify-between">
                    <div className="space-y-0.5">
                      <Label>Bắt buộc mật khẩu mạnh</Label>
                      <p className="text-sm text-muted-foreground">
                        Yêu cầu chữ hoa, chữ thường, số và ký hiệu
                      </p>
                    </div>
                    <Switch
                      checked={securitySettings.enforceStrongPassword}
                      onCheckedChange={(checked) =>
                        setSecuritySettings({ ...securitySettings, enforceStrongPassword: checked })
                      }
                    />
                  </div>
                </div>
              </div>

              <div className="flex justify-end">
                <Button onClick={handleSaveSecurity} disabled={isSaving}>
                  <Save className="mr-2 h-4 w-4" />
                  {isSaving ? "Đang lưu..." : "Lưu thay đổi"}
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
