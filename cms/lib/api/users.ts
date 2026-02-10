import apiClient from "@/lib/api-client";
import { ApiResponse, PaginatedResponse, User, UserRole, UserStatus } from "@/types";

export interface GetUsersParams {
  page?: number;
  limit?: number;
  search?: string;
  role?: UserRole;
  status?: UserStatus;
  sortBy?: string;
  sortOrder?: "asc" | "desc";
}

export interface UpdateUserStatusDto {
  status: UserStatus;
  reason?: string;
}

export interface UserStats {
  total: number;
  active: number;
  pending: number;
  suspended: number;
  banned: number;
  partners: number;
  admins: number;
}

export const usersApi = {
  getUsers: async (params: GetUsersParams = {}): Promise<PaginatedResponse<User>> => {
    const response = await apiClient.get("/users/admin/list", { params });
    return response.data;
  },

  getUserById: async (id: string): Promise<ApiResponse<User>> => {
    const response = await apiClient.get(`/users/${id}`);
    return response.data;
  },

  updateUserStatus: async (
    id: string,
    dto: UpdateUserStatusDto
  ): Promise<ApiResponse<User>> => {
    const response = await apiClient.patch(`/users/admin/${id}/status`, dto);
    return response.data;
  },

  deleteUser: async (id: string): Promise<ApiResponse<null>> => {
    const response = await apiClient.delete(`/users/${id}`);
    return response.data;
  },

  getUserStats: async (): Promise<ApiResponse<UserStats>> => {
    const response = await apiClient.get("/users/admin/stats");
    return response.data;
  },
};
