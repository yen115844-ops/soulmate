import apiClient from "@/lib/api-client";
import { ApiResponse, Booking, BookingStatus, PaginatedResponse } from "@/types";

export interface GetBookingsParams {
  page?: number;
  limit?: number;
  search?: string;
  status?: BookingStatus;
  userId?: string;
  partnerId?: string;
  startDate?: string;
  endDate?: string;
  sortBy?: string;
  sortOrder?: "asc" | "desc";
}

export interface UpdateBookingStatusDto {
  status: BookingStatus;
  reason?: string;
}

export interface BookingStats {
  total: number;
  pending: number;
  confirmed: number;
  paid: number;
  inProgress: number;
  completed: number;
  cancelled: number;
  disputed: number;
  todayCount: number;
  monthlyRevenue: number;
}

export const bookingsApi = {
  getBookings: async (
    params: GetBookingsParams = {}
  ): Promise<PaginatedResponse<Booking>> => {
    const response = await apiClient.get("/bookings/admin/list", { params });
    return response.data;
  },

  getBookingById: async (id: string): Promise<ApiResponse<Booking>> => {
    const response = await apiClient.get(`/bookings/${id}`);
    return response.data;
  },

  updateBookingStatus: async (
    id: string,
    dto: UpdateBookingStatusDto
  ): Promise<ApiResponse<Booking>> => {
    const response = await apiClient.patch(`/bookings/admin/${id}/status`, dto);
    return response.data;
  },

  getBookingStats: async (): Promise<ApiResponse<BookingStats>> => {
    const response = await apiClient.get("/bookings/admin/stats");
    return response.data;
  },
};
