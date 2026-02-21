import apiClient from "@/lib/api-client";
import { ApiResponse, CreditPackage } from "@/types";

export interface CreditPackagesResponse {
  packages: CreditPackage[];
  exchangeRate: number;
}

// ==================== CREDIT PACKAGES ====================
export const creditPackagesApi = {
  getAll: async (includeInactive = false): Promise<CreditPackagesResponse> => {
    const response = await apiClient.get("/credits/packages", {
      params: { includeInactive },
    });
    return response.data['data'];
  },

  getById: async (id: string): Promise<ApiResponse<CreditPackage>> => {
    const response = await apiClient.get(`/credits/packages/${id}`);
    return response.data;
  },

  create: async (data: Partial<CreditPackage>): Promise<ApiResponse<CreditPackage>> => {
    const response = await apiClient.post("/credits/packages", data);
    return response.data;
  },

  update: async (
    id: string,
    data: Partial<CreditPackage>
  ): Promise<ApiResponse<CreditPackage>> => {
    const response = await apiClient.put(`/credits/packages/${id}`, data);
    return response.data;
  },

  delete: async (id: string): Promise<ApiResponse<null>> => {
    const response = await apiClient.delete(`/credits/packages/${id}`);
    return response.data;
  },
};
