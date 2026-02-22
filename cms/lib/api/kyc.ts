import apiClient from "@/lib/api-client";
import { ApiResponse, KycStatus, KycVerification, PaginatedResponse } from "@/types";

export interface GetVerificationParams {
  page?: number;
  limit?: number;
  search?: string;
  status?: KycStatus;
  sortBy?: string;
  sortOrder?: "asc" | "desc";
}

export interface ReviewVerificationDto {
  status: KycStatus;
  rejectionReason?: string;
  reviewNote?: string;
}

export interface VerificationStats {
  total: number;
  pending: number;
  verified: number;
  rejected: number;
  none: number;
}

// Legacy exports for backward compatibility
export type GetKycParams = GetVerificationParams;
export type ReviewKycDto = ReviewVerificationDto;
export type KycStats = VerificationStats;

export const verificationApi = {
  getList: async (
    params: GetVerificationParams = {}
  ): Promise<PaginatedResponse<KycVerification>> => {
    const response = await apiClient.get("/verification/admin/list", { params });
    // Backend wraps in { success, data, timestamp } via TransformInterceptor
    // response.data = { success, data: { data: [], total, page, limit, totalPages }, timestamp }
    return response.data;
  },

  getById: async (id: string): Promise<ApiResponse<KycVerification>> => {
    const response = await apiClient.get(`/verification/admin/${id}`);
    return response.data;
  },

  review: async (
    id: string,
    dto: ReviewVerificationDto
  ): Promise<ApiResponse<KycVerification>> => {
    const response = await apiClient.patch(`/verification/admin/${id}/review`, dto);
    return response.data;
  },

  getStats: async (): Promise<VerificationStats> => {
    const response = await apiClient.get("/verification/admin/stats");
    // Backend wraps: { success: true, data: { total, pending, ... } }
    // We need to unwrap .data to get the actual stats object
    const body = response.data;
    return body?.data ?? body;
  },
};

// Legacy alias for backward compatibility
export const kycApi = {
  getKycList: verificationApi.getList,
  getKycById: verificationApi.getById,
  reviewKyc: verificationApi.review,
  getKycStats: verificationApi.getStats,
};
