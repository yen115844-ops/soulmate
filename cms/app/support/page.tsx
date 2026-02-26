"use client";

import { supportApi } from "@/lib/api/support";
import { Mail, Loader2, Phone, ExternalLink, HelpCircle } from "lucide-react";
import Link from "next/link";
import { useQuery } from "@tanstack/react-query";

/** Fallback khi API lỗi hoặc trống – đáp ứng Guideline 1.5 (Support URL luôn có thông tin) */
const FALLBACK_APP_NAME = "Mate Social";
const FALLBACK_SUPPORT_EMAIL = "ngocbinhan8888@gmail.com";

export default function SupportPage() {
  const { data: info, isLoading, error } = useQuery({
    queryKey: ["public", "support"],
    queryFn: () => supportApi.getPublic(),
    retry: 1,
  });

  const appName = info?.appName || FALLBACK_APP_NAME;
  const supportEmail = info?.supportEmail || FALLBACK_SUPPORT_EMAIL;
  const supportPhone = info?.supportPhone ?? "";

  return (
    <div className="min-h-screen bg-background">
      <header className="border-b">
        <div className="container mx-auto px-4 py-4">
          <h1 className="text-lg font-semibold">{appName} – Hỗ trợ</h1>
        </div>
      </header>

      <main className="container mx-auto px-4 py-10 max-w-2xl">
        {error && (
          <div className="rounded-lg border border-amber-200 bg-amber-50 dark:border-amber-800 dark:bg-amber-950/30 p-4 mb-6">
            <p className="text-sm text-amber-800 dark:text-amber-200">
              Không thể tải thông tin từ máy chủ. Dưới đây là các kênh liên hệ
              bạn có thể sử dụng.
            </p>
          </div>
        )}

        {isLoading && (
          <div className="flex items-center gap-2 py-2 mb-4">
            <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
            <span className="text-sm text-muted-foreground">
              Đang tải thông tin...
            </span>
          </div>
        )}

        {/* Luôn có nội dung hỗ trợ (API hoặc fallback) – Guideline 1.5 */}
        <div className="space-y-8">
          <p className="text-muted-foreground">
            Bạn cần hỗ trợ? Liên hệ chúng tôi qua các kênh sau.
          </p>

          <div className="space-y-4">
            <div className="flex items-center gap-3 rounded-lg border p-4">
              <Mail className="h-5 w-5 shrink-0 text-muted-foreground" />
              <div>
                <p className="text-sm font-medium">Email</p>
                <a
                  href={`mailto:${supportEmail}`}
                  className="text-primary hover:underline"
                >
                  {supportEmail}
                </a>
              </div>
            </div>

            {supportPhone && (
              <div className="flex items-center gap-3 rounded-lg border p-4">
                <Phone className="h-5 w-5 shrink-0 text-muted-foreground" />
                <div>
                  <p className="text-sm font-medium">Điện thoại</p>
                  <a
                    href={`tel:${supportPhone.replace(/\s/g, "")}`}
                    className="text-primary hover:underline"
                  >
                    {supportPhone}
                  </a>
                </div>
              </div>
            )}

            <div className="flex items-center gap-3 rounded-lg border p-4 bg-muted/30">
              <HelpCircle className="h-5 w-5 shrink-0 text-muted-foreground" />
              <div>
                <p className="text-sm font-medium">Trong ứng dụng</p>
                <p className="text-sm text-muted-foreground">
                  Mở ứng dụng {appName} → Hồ sơ → Trung tâm trợ giúp để xem câu
                  hỏi thường gặp và gửi yêu cầu hỗ trợ.
                </p>
              </div>
            </div>
          </div>

          <div className="border-t pt-6">
            <p className="text-sm text-muted-foreground mb-3">Tài liệu</p>
            <ul className="space-y-2">
              <li>
                <Link
                  href="/terms-of-service"
                  className="inline-flex items-center gap-1 text-primary hover:underline"
                >
                  Điều khoản sử dụng
                  <ExternalLink className="h-3.5 w-3.5" />
                </Link>
              </li>
              <li>
                <Link
                  href="/terms-and-conditions"
                  className="inline-flex items-center gap-1 text-primary hover:underline"
                >
                  Điều khoản và điều kiện
                  <ExternalLink className="h-3.5 w-3.5" />
                </Link>
              </li>
              <li>
                <Link
                  href="/privacy-policy"
                  className="inline-flex items-center gap-1 text-primary hover:underline"
                >
                  Chính sách bảo mật
                  <ExternalLink className="h-3.5 w-3.5" />
                </Link>
              </li>
            </ul>
          </div>
        </div>
      </main>
    </div>
  );
}
