import axios from "axios";
import apiClient from "@/lib/api-client";

const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:3000/api/v1";

export type TermsType = "terms-of-service" | "terms-and-conditions";

export interface TermsResponse {
  content: string;
}

export interface AdminTermsResponse {
  termsOfService: string;
  termsAndConditions: string;
}

export const termsApi = {
  /** Public - get terms content by type (no auth) */
  getPublic: async (type: TermsType): Promise<string> => {
    const base = API_BASE_URL.replace(/\/$/, "");
    const res = await axios.get<{ data?: TermsResponse; content?: string }>(
      `${base}/public/terms/${type}`
    );
    const data = res.data?.data ?? res.data;
    return (data as TermsResponse)?.content ?? (data as { content?: string })?.content ?? "";
  },

  /** Admin - get both terms contents */
  getAdmin: async (): Promise<AdminTermsResponse> => {
    const res = await apiClient.get("/admin/settings/terms");
    const d = res.data as unknown;
    if (d && typeof d === "object" && "data" in d && d.data) {
      return d.data as AdminTermsResponse;
    }
    return d as AdminTermsResponse;
  },

  /** Admin - update terms contents */
  updateAdmin: async (data: {
    termsOfService?: string;
    termsAndConditions?: string;
  }): Promise<AdminTermsResponse> => {
    const res = await apiClient.put("/admin/settings/terms", data);
    const d = res.data as unknown;
    if (d && typeof d === "object" && "data" in d && d.data) {
      return d.data as AdminTermsResponse;
    }
    return d as AdminTermsResponse;
  },
};
