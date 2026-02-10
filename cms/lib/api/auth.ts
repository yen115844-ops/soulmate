import apiClient from "@/lib/api-client";
import { AdminUser, ApiResponse, AuthTokens, LoginCredentials } from "@/types";

export const authApi = {
  login: async (credentials: LoginCredentials): Promise<ApiResponse<AuthTokens & { user: AdminUser }>> => {
    const response = await apiClient.post("/auth/login", credentials);
    return response.data;
  },

  logout: async (refreshToken: string): Promise<ApiResponse<null>> => {
    const response = await apiClient.post("/auth/logout", { refreshToken });
    return response.data;
  },

  refreshToken: async (refreshToken: string): Promise<ApiResponse<AuthTokens>> => {
    const response = await apiClient.post("/auth/refresh", { refreshToken });
    return response.data;
  },

  getCurrentUser: async (): Promise<ApiResponse<{ user: AdminUser }>> => {
    const response = await apiClient.get("/auth/me");
    return response.data;
  },
};
