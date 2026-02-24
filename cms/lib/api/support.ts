import axios from "axios";

const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:3000/api/v1";

export interface SupportInfo {
  supportEmail: string;
  supportPhone: string;
  supportUrl: string;
  appName: string;
}

export const supportApi = {
  /** Public - get support info for support page (no auth) */
  getPublic: async (): Promise<SupportInfo> => {
    const base = API_BASE_URL.replace(/\/$/, "");
    const res = await axios.get<{ data?: SupportInfo } & SupportInfo>(
      `${base}/public/support`
    );
    const data = res.data?.data ?? res.data;
    return {
      supportEmail: (data as SupportInfo)?.supportEmail ?? "ngocbinhan8888@gmail.com",
      supportPhone: (data as SupportInfo)?.supportPhone ?? "",
      supportUrl: (data as SupportInfo)?.supportUrl ?? "",
      appName: (data as SupportInfo)?.appName ?? "Mate Social",
    };
  },
};
