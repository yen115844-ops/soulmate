import apiClient from "@/lib/api-client";
import { ApiResponse, PaginatedResponse, PartnerProfile, User, UserStatus } from "@/types";

export interface GetPartnersParams {
  page?: number;
  limit?: number;
  search?: string;
  status?: UserStatus;
  serviceType?: string;
  isAvailable?: boolean;
  sortBy?: string;
  sortOrder?: "asc" | "desc";
}

export interface UpdatePartnerStatusDto {
  status: UserStatus;
  reason?: string;
}

export interface PartnerStats {
  total: number;
  active: number;
  pending: number;
  suspended: number;
  banned: number;
  available: number;
  averageRating: number;
  totalBookings: number;
  completedBookings: number;
}

export const partnersApi = {
  getPartners: async (
    params: GetPartnersParams = {}
  ): Promise<PaginatedResponse<PartnerProfile & { user: User }>> => {
    const response = await apiClient.get("/partners/admin/list", { params });
    return response.data;
  },

  getPartnerById: async (
    id: string
  ): Promise<ApiResponse<PartnerProfile & { user: User }>> => {
    const response = await apiClient.get(`/partners/${id}`);
    return response.data;
  },

  updatePartnerStatus: async (
    id: string,
    dto: UpdatePartnerStatusDto
  ): Promise<ApiResponse<PartnerProfile>> => {
    const response = await apiClient.patch(`/partners/admin/${id}/status`, dto);
    return response.data;
  },

  getPartnerStats: async (): Promise<PartnerStats> => {
    const response = await apiClient.get("/partners/admin/stats");
    return response.data;
  },
};
