"use client";

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { bookingsApi, BookingStats } from "@/lib/api/bookings";
import { kycApi, KycStats } from "@/lib/api/kyc";
import { partnersApi, PartnerStats } from "@/lib/api/partners";
import { usersApi, UserStats } from "@/lib/api/users";
import { Booking, BookingStatus, KycVerification } from "@/types";
import { useQuery } from "@tanstack/react-query";
import { formatDistanceToNow } from "date-fns";
import { vi } from "date-fns/locale";
import {
    Activity,
    Calendar,
    DollarSign,
    ShieldCheck,
    TrendingUp,
    UserCheck,
    Users,
} from "lucide-react";

// Helper to format currency
const formatCurrency = (amount: number) => {
  if (amount >= 1000000000) {
    return `₫${(amount / 1000000000).toFixed(1)}B`;
  }
  if (amount >= 1000000) {
    return `₫${(amount / 1000000).toFixed(1)}M`;
  }
  return new Intl.NumberFormat("vi-VN", {
    style: "currency",
    currency: "VND",
    maximumFractionDigits: 0,
  }).format(amount);
};

// Helper to format number
const formatNumber = (num: number) => {
  return new Intl.NumberFormat("vi-VN").format(num);
};

// Booking status badge - nhãn tiếng Việt
const bookingStatusLabels: Record<BookingStatus, string> = {
  [BookingStatus.PENDING]: "Chờ xử lý",
  [BookingStatus.CONFIRMED]: "Đã xác nhận",
  [BookingStatus.PAID]: "Đã thanh toán",
  [BookingStatus.IN_PROGRESS]: "Đang thực hiện",
  [BookingStatus.COMPLETED]: "Hoàn thành",
  [BookingStatus.CANCELLED]: "Đã hủy",
  [BookingStatus.DISPUTED]: "Tranh chấp",
};

function BookingStatusBadge({ status }: { status: BookingStatus }) {
  const variants: Record<
    BookingStatus,
    { variant: "default" | "secondary" | "destructive" | "outline"; className?: string }
  > = {
    [BookingStatus.PENDING]: { variant: "secondary" },
    [BookingStatus.CONFIRMED]: { variant: "outline", className: "border-blue-500 text-blue-500" },
    [BookingStatus.PAID]: { variant: "default" },
    [BookingStatus.IN_PROGRESS]: { variant: "default", className: "bg-blue-500" },
    [BookingStatus.COMPLETED]: { variant: "default", className: "bg-green-500" },
    [BookingStatus.CANCELLED]: { variant: "destructive" },
    [BookingStatus.DISPUTED]: { variant: "destructive", className: "bg-orange-500" },
  };

  const config = variants[status] || { variant: "secondary" };
  return (
    <Badge variant={config.variant} className={config.className}>
      {bookingStatusLabels[status] ?? status}
    </Badge>
  );
}

function StatCard({
  title,
  value,
  description,
  icon: Icon,
}: {
  title: string;
  value: string;
  description: string;
  icon: React.ComponentType<{ className?: string }>;
}) {
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">
          {title}
        </CardTitle>
        <Icon className="h-4 w-4 text-muted-foreground" />
      </CardHeader>
      <CardContent>
        <div className="text-2xl font-bold">{value}</div>
        <p className="text-xs text-muted-foreground">{description}</p>
      </CardContent>
    </Card>
  );
}

function StatCardSkeleton() {
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <Skeleton className="h-4 w-24" />
        <Skeleton className="h-4 w-4" />
      </CardHeader>
      <CardContent>
        <Skeleton className="h-8 w-20" />
        <Skeleton className="mt-1 h-3 w-32" />
      </CardContent>
    </Card>
  );
}

function RecentBookingSkeleton() {
  return (
    <div className="flex items-center justify-between border-b pb-3 last:border-0 last:pb-0">
      <div className="flex items-center gap-3">
        <Skeleton className="h-10 w-10 rounded-full" />
        <div>
          <Skeleton className="h-4 w-24 mb-1" />
          <Skeleton className="h-3 w-32" />
        </div>
      </div>
      <div className="text-right">
        <Skeleton className="h-4 w-20 mb-1" />
        <Skeleton className="h-3 w-16" />
      </div>
    </div>
  );
}

function PendingKycSkeleton() {
  return (
    <div className="flex items-center justify-between border-b pb-3 last:border-0 last:pb-0">
      <div className="flex items-center gap-3">
        <Skeleton className="h-10 w-10 rounded-full" />
        <div>
          <Skeleton className="h-4 w-28 mb-1" />
          <Skeleton className="h-3 w-20" />
        </div>
      </div>
      <Skeleton className="h-6 w-16 rounded-full" />
    </div>
  );
}

export default function DashboardPage() {
  // Fetch user stats
  const { data: userStats, isLoading: userStatsLoading } = useQuery({
    queryKey: ["user-stats"],
    queryFn: () => usersApi.getUserStats(),
  });

  // Fetch partner stats
  const { data: partnerStats, isLoading: partnerStatsLoading } = useQuery({
    queryKey: ["partner-stats"],
    queryFn: () => partnersApi.getPartnerStats(),
  });

  // Fetch booking stats
  const { data: bookingStats, isLoading: bookingStatsLoading } = useQuery({
    queryKey: ["booking-stats"],
    queryFn: () => bookingsApi.getBookingStats(),
  });

  // Fetch KYC stats
  const { data: kycStats, isLoading: kycStatsLoading } = useQuery({
    queryKey: ["kyc-stats"],
    queryFn: () => kycApi.getKycStats(),
  });

  // Fetch recent bookings
  const { data: recentBookingsData, isLoading: recentBookingsLoading } = useQuery({
    queryKey: ["recent-bookings"],
    queryFn: () => bookingsApi.getBookings({ limit: 5, sortBy: "createdAt", sortOrder: "desc" }),
  });

  // Fetch pending KYC
  const { data: pendingKycData, isLoading: pendingKycLoading } = useQuery({
    queryKey: ["pending-kyc"],
    queryFn: () => kycApi.getKycList({ limit: 5, status: "PENDING" as any }),
  });

  const isStatsLoading = userStatsLoading || partnerStatsLoading || bookingStatsLoading || kycStatsLoading;

  // Extract data safely (handle ApiResponse wrapper)
  const defaultUserStats: UserStats = { total: 0, active: 0, pending: 0, suspended: 0, banned: 0, partners: 0, admins: 0 };
  const defaultPartnerStats: PartnerStats = { total: 0, active: 0, pending: 0, suspended: 0, banned: 0, available: 0, averageRating: 0, totalBookings: 0, completedBookings: 0 };
  const defaultBookingStats: BookingStats = { total: 0, pending: 0, confirmed: 0, paid: 0, inProgress: 0, completed: 0, cancelled: 0, disputed: 0, todayCount: 0, monthlyRevenue: 0 };
  const defaultKycStats: KycStats = { total: 0, pending: 0, verified: 0, rejected: 0, none: 0 };

  const users: UserStats = (userStats as any)?.data ?? userStats ?? defaultUserStats;
  const partners: PartnerStats = (partnerStats as any)?.data ?? partnerStats ?? defaultPartnerStats;
  const bookings: BookingStats = (bookingStats as any)?.data ?? bookingStats ?? defaultBookingStats;
  const kyc: KycStats = (kycStats as any)?.data ?? kycStats ?? defaultKycStats;

  // Build stats array from API data - nhãn tiếng Việt
  const stats = [
    { title: "Tổng người dùng", value: formatNumber(users.total || 0), description: `${formatNumber(users.active || 0)} đang hoạt động`, icon: Users },
    { title: "Đối tác hoạt động", value: formatNumber(partners.active || 0), description: `${formatNumber(partners.available || 0)} sẵn sàng`, icon: UserCheck },
    { title: "Tổng đặt chỗ", value: formatNumber(bookings.total || 0), description: `${formatNumber(bookings.completed || 0)} hoàn thành`, icon: Calendar },
    { title: "KYC chờ duyệt", value: formatNumber(kyc.pending || 0), description: `${formatNumber(kyc.verified || 0)} đã xác minh`, icon: ShieldCheck },
    { title: "Đặt chỗ hôm nay", value: formatNumber(bookings.todayCount || 0), description: "Đặt chỗ trong ngày", icon: Activity },
    { title: "Doanh thu tháng", value: formatCurrency(bookings.monthlyRevenue || 0), description: "Tháng này", icon: DollarSign },
    { title: "Đặt chỗ chờ xử lý", value: formatNumber(bookings.pending || 0), description: "Chờ xác nhận", icon: TrendingUp },
    { title: "Điểm đánh giá TB", value: Number(partners.averageRating || 0).toFixed(1), description: "Trung bình đối tác", icon: TrendingUp },
  ];

  // Extract recent bookings
  const recentBookings: Booking[] = (recentBookingsData as any)?.data?.data || (recentBookingsData as any)?.data || [];

  // Extract pending KYCs
  const pendingKycs: KycVerification[] = (pendingKycData as any)?.data?.data || (pendingKycData as any)?.data || [];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Tổng quan</h1>
        <p className="text-muted-foreground">
          Chào mừng đến trang quản trị Mate Social
        </p>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {isStatsLoading
          ? Array.from({ length: 8 }).map((_, i) => <StatCardSkeleton key={i} />)
          : stats.map((stat) => (
              <StatCard
                key={stat.title}
                title={stat.title}
                value={stat.value}
                description={stat.description}
                icon={stat.icon}
              />
            ))}
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Đặt chỗ gần đây</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {recentBookingsLoading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <RecentBookingSkeleton key={i} />
                ))
              ) : recentBookings.length === 0 ? (
                <p className="text-sm text-muted-foreground text-center py-4">
                  Chưa có đặt chỗ gần đây
                </p>
              ) : (
                recentBookings.map((booking) => (
                  <div
                    key={booking.id}
                    className="flex items-center justify-between border-b pb-3 last:border-0 last:pb-0"
                  >
                    <div className="flex items-center gap-3">
                      <Avatar className="h-10 w-10">
                        <AvatarImage src={booking.user?.profile?.avatarUrl} />
                        <AvatarFallback>
                          {booking.user?.profile?.fullName?.charAt(0) || "U"}
                        </AvatarFallback>
                      </Avatar>
                      <div>
                        <p className="font-medium">#{booking.bookingCode}</p>
                        <p className="text-sm text-muted-foreground">
                          {booking.user?.profile?.fullName || "Khách"} → {booking.partner?.profile?.fullName || "Đối tác"}
                        </p>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="font-medium">{formatCurrency(booking.totalAmount)}</p>
                      <BookingStatusBadge status={booking.status} />
                    </div>
                  </div>
                ))
              )}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Xác minh KYC chờ duyệt</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {pendingKycLoading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <PendingKycSkeleton key={i} />
                ))
              ) : pendingKycs.length === 0 ? (
                <p className="text-sm text-muted-foreground text-center py-4">
                  Không có KYC chờ duyệt
                </p>
              ) : (
                pendingKycs.map((kyc) => (
                  <div
                    key={kyc.id}
                    className="flex items-center justify-between border-b pb-3 last:border-0 last:pb-0"
                  >
                    <div className="flex items-center gap-3">
                      <Avatar className="h-10 w-10">
                        <AvatarImage src={kyc.user?.profile?.avatarUrl} />
                        <AvatarFallback>
                          {kyc.user?.profile?.fullName?.charAt(0) || "U"}
                        </AvatarFallback>
                      </Avatar>
                      <div>
                        <p className="font-medium">{kyc.user?.profile?.fullName || "Chưa rõ"}</p>
                        <p className="text-sm text-muted-foreground">
                          {kyc.submittedAt
                            ? `Nộp ${formatDistanceToNow(new Date(kyc.submittedAt), { addSuffix: true, locale: vi })}`
                            : "Vừa nộp"}
                        </p>
                      </div>
                    </div>
                    <Badge variant="secondary" className="bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200">
                      Chờ duyệt
                    </Badge>
                  </div>
                ))
              )}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
