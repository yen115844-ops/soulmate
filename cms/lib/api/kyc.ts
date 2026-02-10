import apiClient from "@/lib/api-client";
import { ApiResponse, KycStatus, KycVerification, PaginatedResponse } from "@/types";

export interface GetKycParams {
  page?: number;
  limit?: number;
  search?: string;
  status?: KycStatus;
  sortBy?: string;
  sortOrder?: "asc" | "desc";
}

export interface ReviewKycDto {
  status: KycStatus;
  rejectionReason?: string;
  reviewNote?: string;
}

export interface KycStats {
  total: number;
  pending: number;
  verified: number;
  rejected: number;
  none: number;
}

export const kycApi = {
  getKycList: async (
    params: GetKycParams = {}
  ): Promise<PaginatedResponse<KycVerification>> => {
    const response = await apiClient.get("/users/admin/kyc/list", { params });
    return response.data;
  },

  getKycById: async (id: string): Promise<ApiResponse<KycVerification>> => {
    const response = await apiClient.get(`/users/admin/kyc/${id}`);
    return response.data;
  },

  reviewKyc: async (
    id: string,
    dto: ReviewKycDto
  ): Promise<ApiResponse<KycVerification>> => {
    const response = await apiClient.patch(`/users/admin/kyc/${id}/review`, dto);
    return response.data;
  },

  getKycStats: async (): Promise<KycStats> => {
    const response = await apiClient.get("/users/admin/kyc/stats");
    return response.data;
  },
};
