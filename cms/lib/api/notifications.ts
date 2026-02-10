import apiClient from "@/lib/api-client";
import {
  ApiResponse,
  Notification,
  NotificationStats,
  NotificationType,
  PaginatedResponse,
} from "@/types";

export interface GetNotificationsParams {
  page?: number;
  limit?: number;
  search?: string;
  type?: NotificationType;
  userId?: string;
  isRead?: boolean;
  sortBy?: string;
  sortOrder?: "asc" | "desc";
}

export interface SendNotificationDto {
  title: string;
  body: string;
  type?: NotificationType;
  imageUrl?: string;
  actionType?: string;
  actionId?: string;
  data?: any;
  sendPush?: boolean;
  userIds?: string[];
}

export interface SendNotificationResponse {
  success: boolean;
  sentCount: number;
  skippedCount?: number;
  message?: string;
}

export const notificationsApi = {
  // ==================== CURRENT USER (Header) ====================

  // Get unread count for current user (admin)
  getUnreadCount: async (): Promise<{ unreadCount: number }> => {
    const response = await apiClient.get("/notifications/unread-count");
    return response.data.data || response.data;
  },

  // Get current user's notifications (for header dropdown)
  getMyNotifications: async (
    params: { limit?: number; isRead?: boolean } = {}
  ): Promise<{ data: Notification[]; meta: { unreadCount: number } }> => {
    const response = await apiClient.get("/notifications", { params });
    return response.data;
  },

  // Mark notification as read
  markAsRead: async (id: string): Promise<ApiResponse<null>> => {
    const response = await apiClient.post(`/notifications/mark-read/${id}`);
    return response.data;
  },

  // Mark all as read
  markAllAsRead: async (ids?: string[]): Promise<ApiResponse<{ updatedCount: number }>> => {
    const response = await apiClient.post("/notifications/mark-all-read", { ids: ids || [] });
    return response.data;
  },

  // ==================== ADMIN ====================

  // Get notification statistics
  getStats: async (): Promise<NotificationStats> => {
    const response = await apiClient.get("/notifications/admin/stats");
    return response.data.data || response.data;
  },

  // Get notifications list with pagination and filters
  getNotifications: async (
    params: GetNotificationsParams = {}
  ): Promise<PaginatedResponse<Notification>> => {
    const response = await apiClient.get("/notifications/admin/list", { params });
    return response.data;
  },

  // Send notification to specific users
  sendNotification: async (
    dto: SendNotificationDto
  ): Promise<ApiResponse<SendNotificationResponse>> => {
    const response = await apiClient.post("/notifications/admin/send", dto);
    return response.data;
  },

  // Broadcast notification to all users
  broadcastNotification: async (
    dto: Omit<SendNotificationDto, "userIds">
  ): Promise<ApiResponse<SendNotificationResponse>> => {
    const response = await apiClient.post("/notifications/admin/broadcast", dto);
    return response.data;
  },

  // Delete a notification
  deleteNotification: async (id: string): Promise<ApiResponse<null>> => {
    const response = await apiClient.delete(`/notifications/admin/${id}`);
    return response.data;
  },
};
