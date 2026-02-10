"use client";

import { authApi } from "@/lib/api";
import { AdminUser, UserRole } from "@/types";
import Cookies from "js-cookie";
import { create } from "zustand";
import { createJSONStorage, persist } from "zustand/middleware";

interface AuthState {
  user: AdminUser | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
  login: (email: string, password: string) => Promise<boolean>;
  logout: () => Promise<void>;
  checkAuth: () => Promise<void>;
  clearError: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      isAuthenticated: false,
      isLoading: true,
      error: null,

      login: async (email: string, password: string) => {
        set({ isLoading: true, error: null });
        try {
          const response = await authApi.login({ email, password });
          // Backend returns: { success: true, data: { user, accessToken, refreshToken } }
          const data = response.data;
          const { accessToken, refreshToken, user } = data;

          // Check if user is admin
          if (user.role !== UserRole.ADMIN) {
            set({ isLoading: false, error: "Access denied. Admin only." });
            return false;
          }

          // Save tokens
          Cookies.set("accessToken", accessToken, { expires: 1 }); // 1 day
          Cookies.set("refreshToken", refreshToken, { expires: 7 }); // 7 days

          set({
            user,
            isAuthenticated: true,
            isLoading: false,
            error: null,
          });

          return true;
        } catch (error: unknown) {
          let errorMessage = "Login failed";
          const axiosError = error as { response?: { data?: { message?: string } } };
          if (axiosError?.response?.data?.message) {
            errorMessage = axiosError.response.data.message;
          } else if (error instanceof Error) {
            errorMessage = error.message;
          }
          set({ isLoading: false, error: errorMessage });
          return false;
        }
      },

      logout: async () => {
        const refreshToken = Cookies.get("refreshToken");
        try {
          if (refreshToken) {
            await authApi.logout(refreshToken);
          }
        } catch {
          // Ignore logout errors
        } finally {
          Cookies.remove("accessToken");
          Cookies.remove("refreshToken");
          set({ user: null, isAuthenticated: false, isLoading: false });
        }
      },

      checkAuth: async () => {
        const accessToken = Cookies.get("accessToken");
        const refreshToken = Cookies.get("refreshToken");
        const currentState = get();
        
        // No tokens at all - definitely not authenticated
        if (!accessToken && !refreshToken) {
          set({ user: null, isAuthenticated: false, isLoading: false });
          return;
        }

        // If we have persisted auth state and tokens exist, trust it initially
        // This prevents logout on page reload while API is being called
        if (currentState.isAuthenticated && currentState.user && accessToken) {
          // Verify in background without changing loading state
          try {
            const response = await authApi.getCurrentUser();
            // Backend returns: { success: true, data: { user: {...} } }
            const user = response.data.user;

            if (user.role !== UserRole.ADMIN) {
              // Actually not admin - logout
              Cookies.remove("accessToken");
              Cookies.remove("refreshToken");
              set({ user: null, isAuthenticated: false, isLoading: false });
              return;
            }

            // Update user data silently
            set({ user, isAuthenticated: true, isLoading: false });
          } catch (error: unknown) {
            // Check if it's a 401 error (token actually invalid)
            const axiosError = error as { response?: { status?: number } };
            if (axiosError?.response?.status === 401) {
              // Token is invalid and refresh also failed - logout
              Cookies.remove("accessToken");
              Cookies.remove("refreshToken");
              set({ user: null, isAuthenticated: false, isLoading: false });
            } else {
              // Network error or other issue - keep current session
              console.warn("Failed to verify auth, keeping current session");
              set({ isLoading: false });
            }
          }
          return;
        }

        // Not authenticated yet but has token - try to authenticate
        set({ isLoading: true });
        try {
          const response = await authApi.getCurrentUser();
          // Backend returns: { success: true, data: { user: {...} } }
          const user = response.data.user;

          if (user.role !== UserRole.ADMIN) {
            throw new Error("Access denied");
          }

          set({ user, isAuthenticated: true, isLoading: false });
        } catch {
          Cookies.remove("accessToken");
          Cookies.remove("refreshToken");
          set({ user: null, isAuthenticated: false, isLoading: false });
        }
      },

      clearError: () => set({ error: null }),
    }),
    {
      name: "auth-storage",
      storage: createJSONStorage(() => localStorage),
      partialize: (state) => ({
        user: state.user,
        isAuthenticated: state.isAuthenticated,
      }),
    }
  )
);
