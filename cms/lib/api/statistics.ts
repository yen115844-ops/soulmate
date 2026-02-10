import apiClient from "@/lib/api-client";
import { ApiResponse } from "@/types";

export interface StatsOverview {
  users: {
    total: number;
    active: number;
    pending: number;
    suspended: number;
    banned: number;
  };
  partners: {
    total: number;
    active: number;
    available: number;
    averageRating: number;
  };
  bookings: {
    total: number;
    completed: number;
    cancelled: number;
    totalRevenue: number;
  };
  kyc: {
    pending: number;
    verified: number;
    rejected: number;
  };
}

export interface RevenueChartPoint {
  date: string;
  revenue: number;
  count: number;
}

export interface BookingsByStatusItem {
  status: string;
  count: number;
}

export interface BookingsByServiceTypeItem {
  serviceType: string;
  count: number;
  totalAmount: number;
}

export interface GrowthPoint {
  date: string;
  count: number;
}

export interface KycBreakdownItem {
  status: string;
  count: number;
  label: string;
}

export interface TopPartnerRevenue {
  partnerId: string;
  fullName: string;
  avatarUrl: string | null;
  totalRevenue: number;
  platformFee: number;
  bookingCount: number;
}

export interface StatisticsReport {
  overview: StatsOverview;
  revenueChart: RevenueChartPoint[];
  bookingsByStatus: BookingsByStatusItem[];
  bookingsByServiceType: BookingsByServiceTypeItem[];
  userGrowth: GrowthPoint[];
  partnerGrowth: GrowthPoint[];
  kycBreakdown: KycBreakdownItem[];
  topPartnersByRevenue: TopPartnerRevenue[];
  dateRange: { from: string; to: string };
}

export interface QueryStatsParams {
  from?: string;
  to?: string;
  groupBy?: "day" | "week" | "month";
}

export const statisticsApi = {
  getFullReport: async (
    params: QueryStatsParams = {}
  ): Promise<ApiResponse<StatisticsReport>> => {
    const response = await apiClient.get("/admin/statistics/report", {
      params,
    });
    return response.data;
  },

  getOverview: async (
    from?: string,
    to?: string
  ): Promise<ApiResponse<StatsOverview>> => {
    const response = await apiClient.get("/admin/statistics/overview", {
      params: { from, to },
    });
    return response.data;
  },

  getRevenueChart: async (
    params: QueryStatsParams
  ): Promise<ApiResponse<RevenueChartPoint[]>> => {
    const response = await apiClient.get("/admin/statistics/revenue-chart", {
      params,
    });
    return response.data;
  },

  getBookingsByStatus: async (
    params: QueryStatsParams
  ): Promise<ApiResponse<BookingsByStatusItem[]>> => {
    const response = await apiClient.get(
      "/admin/statistics/bookings-by-status",
      { params }
    );
    return response.data;
  },

  getBookingsByServiceType: async (
    params: QueryStatsParams
  ): Promise<ApiResponse<BookingsByServiceTypeItem[]>> => {
    const response = await apiClient.get(
      "/admin/statistics/bookings-by-service-type",
      { params }
    );
    return response.data;
  },

  getUserGrowth: async (
    params: QueryStatsParams
  ): Promise<ApiResponse<GrowthPoint[]>> => {
    const response = await apiClient.get("/admin/statistics/user-growth", {
      params,
    });
    return response.data;
  },

  getPartnerGrowth: async (
    params: QueryStatsParams
  ): Promise<ApiResponse<GrowthPoint[]>> => {
    const response = await apiClient.get("/admin/statistics/partner-growth", {
      params,
    });
    return response.data;
  },

  getKycBreakdown: async (): Promise<ApiResponse<KycBreakdownItem[]>> => {
    const response = await apiClient.get("/admin/statistics/kyc-breakdown");
    return response.data;
  },

  getTopPartnersByRevenue: async (
    params: QueryStatsParams
  ): Promise<ApiResponse<TopPartnerRevenue[]>> => {
    const response = await apiClient.get(
      "/admin/statistics/top-partners-revenue",
      { params }
    );
    return response.data;
  },
};
