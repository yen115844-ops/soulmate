import apiClient from "@/lib/api-client";
import {
    ApiResponse,
    District,
    Interest,
    InterestCategory,
    Language,
    Province,
    ServiceType,
    Talent,
    TalentCategory,
} from "@/types";

// ==================== SERVICE TYPES ====================
export const serviceTypesApi = {
  getAll: async (includeInactive = false): Promise<ApiResponse<ServiceType[]>> => {
    const response = await apiClient.get("/master-data/service-types", {
      params: { includeInactive },
    });
    return response.data;
  },

  create: async (data: Partial<ServiceType>): Promise<ApiResponse<ServiceType>> => {
    const response = await apiClient.post("/master-data/service-types", data);
    return response.data;
  },

  update: async (
    id: string,
    data: Partial<ServiceType>
  ): Promise<ApiResponse<ServiceType>> => {
    const response = await apiClient.put(`/master-data/service-types/${id}`, data);
    return response.data;
  },

  delete: async (id: string): Promise<ApiResponse<null>> => {
    const response = await apiClient.delete(`/master-data/service-types/${id}`);
    return response.data;
  },
};

// ==================== PROVINCES ====================
export const provincesApi = {
  getAll: async (includeInactive = false): Promise<ApiResponse<Province[]>> => {
    const response = await apiClient.get("/master-data/provinces", {
      params: { includeInactive },
    });
    return response.data;
  },

  getById: async (id: string): Promise<ApiResponse<Province>> => {
    const response = await apiClient.get(`/master-data/provinces/${id}`);
    return response.data;
  },

  create: async (data: Partial<Province>): Promise<ApiResponse<Province>> => {
    const response = await apiClient.post("/master-data/provinces", data);
    return response.data;
  },

  update: async (
    id: string,
    data: Partial<Province>
  ): Promise<ApiResponse<Province>> => {
    const response = await apiClient.put(`/master-data/provinces/${id}`, data);
    return response.data;
  },

  delete: async (id: string): Promise<ApiResponse<null>> => {
    const response = await apiClient.delete(`/master-data/provinces/${id}`);
    return response.data;
  },
};

// ==================== DISTRICTS ====================
export const districtsApi = {
  getAll: async (
    provinceId?: string,
    includeInactive = false
  ): Promise<ApiResponse<District[]>> => {
    const response = await apiClient.get("/master-data/districts", {
      params: { provinceId, includeInactive },
    });
    return response.data;
  },

  getByProvince: async (provinceId: string): Promise<ApiResponse<District[]>> => {
    const response = await apiClient.get(
      `/master-data/provinces/${provinceId}/districts`
    );
    return response.data;
  },

  create: async (data: Partial<District>): Promise<ApiResponse<District>> => {
    const response = await apiClient.post("/master-data/districts", data);
    return response.data;
  },

  update: async (
    id: string,
    data: Partial<District>
  ): Promise<ApiResponse<District>> => {
    const response = await apiClient.put(`/master-data/districts/${id}`, data);
    return response.data;
  },

  delete: async (id: string): Promise<ApiResponse<null>> => {
    const response = await apiClient.delete(`/master-data/districts/${id}`);
    return response.data;
  },
};

// ==================== INTERESTS ====================
export const interestsApi = {
  getAll: async (
    categoryId?: string,
    includeInactive = false
  ): Promise<ApiResponse<Interest[]>> => {
    const response = await apiClient.get("/master-data/interests", {
      params: { categoryId, includeInactive },
    });
    return response.data;
  },

  create: async (data: Partial<Interest>): Promise<ApiResponse<Interest>> => {
    const response = await apiClient.post("/master-data/interests", data);
    return response.data;
  },

  update: async (
    id: string,
    data: Partial<Interest>
  ): Promise<ApiResponse<Interest>> => {
    const response = await apiClient.put(`/master-data/interests/${id}`, data);
    return response.data;
  },

  delete: async (id: string): Promise<ApiResponse<null>> => {
    const response = await apiClient.delete(`/master-data/interests/${id}`);
    return response.data;
  },
};

// ==================== INTEREST CATEGORIES ====================
export const interestCategoriesApi = {
  getAll: async (includeInactive = false): Promise<ApiResponse<InterestCategory[]>> => {
    const response = await apiClient.get("/master-data/interest-categories", {
      params: { includeInactive },
    });
    return response.data;
  },

  create: async (
    data: Partial<InterestCategory>
  ): Promise<ApiResponse<InterestCategory>> => {
    const response = await apiClient.post("/master-data/interest-categories", data);
    return response.data;
  },

  update: async (
    id: string,
    data: Partial<InterestCategory>
  ): Promise<ApiResponse<InterestCategory>> => {
    const response = await apiClient.put(
      `/master-data/interest-categories/${id}`,
      data
    );
    return response.data;
  },

  delete: async (id: string): Promise<ApiResponse<null>> => {
    const response = await apiClient.delete(`/master-data/interest-categories/${id}`);
    return response.data;
  },
};

// ==================== TALENTS ====================
export const talentsApi = {
  getAll: async (
    categoryId?: string,
    includeInactive = false
  ): Promise<ApiResponse<Talent[]>> => {
    const response = await apiClient.get("/master-data/talents", {
      params: { categoryId, includeInactive },
    });
    return response.data;
  },

  create: async (data: Partial<Talent>): Promise<ApiResponse<Talent>> => {
    const response = await apiClient.post("/master-data/talents", data);
    return response.data;
  },

  update: async (id: string, data: Partial<Talent>): Promise<ApiResponse<Talent>> => {
    const response = await apiClient.put(`/master-data/talents/${id}`, data);
    return response.data;
  },

  delete: async (id: string): Promise<ApiResponse<null>> => {
    const response = await apiClient.delete(`/master-data/talents/${id}`);
    return response.data;
  },
};

// ==================== TALENT CATEGORIES ====================
export const talentCategoriesApi = {
  getAll: async (includeInactive = false): Promise<ApiResponse<TalentCategory[]>> => {
    const response = await apiClient.get("/master-data/talent-categories", {
      params: { includeInactive },
    });
    return response.data;
  },

  create: async (
    data: Partial<TalentCategory>
  ): Promise<ApiResponse<TalentCategory>> => {
    const response = await apiClient.post("/master-data/talent-categories", data);
    return response.data;
  },

  update: async (
    id: string,
    data: Partial<TalentCategory>
  ): Promise<ApiResponse<TalentCategory>> => {
    const response = await apiClient.put(`/master-data/talent-categories/${id}`, data);
    return response.data;
  },

  delete: async (id: string): Promise<ApiResponse<null>> => {
    const response = await apiClient.delete(`/master-data/talent-categories/${id}`);
    return response.data;
  },
};

// ==================== LANGUAGES ====================
export const languagesApi = {
  getAll: async (includeInactive = false): Promise<ApiResponse<Language[]>> => {
    const response = await apiClient.get("/master-data/languages", {
      params: { includeInactive },
    });
    return response.data;
  },

  create: async (data: Partial<Language>): Promise<ApiResponse<Language>> => {
    const response = await apiClient.post("/master-data/languages", data);
    return response.data;
  },

  update: async (
    id: string,
    data: Partial<Language>
  ): Promise<ApiResponse<Language>> => {
    const response = await apiClient.put(`/master-data/languages/${id}`, data);
    return response.data;
  },

  delete: async (id: string): Promise<ApiResponse<null>> => {
    const response = await apiClient.delete(`/master-data/languages/${id}`);
    return response.data;
  },
};
