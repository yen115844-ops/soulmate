import apiClient from "@/lib/api-client";
import { ApiResponse, DashboardStats } from "@/types";

export const dashboardApi = {
  getStats: async (): Promise<ApiResponse<DashboardStats>> => {
    const response = await apiClient.get("/admin/dashboard/stats");
    return response.data;
  },

  getRecentBookings: async (limit = 5): Promise<ApiResponse<unknown[]>> => {
    const response = await apiClient.get("/admin/dashboard/recent-bookings", {
      params: { limit },
    });
    return response.data;
  },

  getRecentUsers: async (limit = 5): Promise<ApiResponse<unknown[]>> => {
    const response = await apiClient.get("/admin/dashboard/recent-users", {
      params: { limit },
    });
    return response.data;
  },

  getRevenueChart: async (
    period: "week" | "month" | "year" = "month"
  ): Promise<ApiResponse<{ date: string; revenue: number }[]>> => {
    const response = await apiClient.get("/admin/dashboard/revenue-chart", {
      params: { period },
    });
    return response.data;
  },
};
