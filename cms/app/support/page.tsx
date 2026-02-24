"use client";

import { supportApi } from "@/lib/api/support";
import { Mail, Loader2, Phone, ExternalLink } from "lucide-react";
import Link from "next/link";
import { useQuery } from "@tanstack/react-query";

export default function SupportPage() {
  const { data: info, isLoading, error } = useQuery({
    queryKey: ["public", "support"],
    queryFn: () => supportApi.getPublic(),
  });

  return (
    <div className="min-h-screen bg-background">
      <header className="border-b">
        <div className="container mx-auto px-4 py-4">
          <h1 className="text-lg font-semibold">
            {info?.appName ? `${info.appName} – Hỗ trợ` : "Hỗ trợ"}
          </h1>
        </div>
      </header>

      <main className="container mx-auto px-4 py-10 max-w-2xl">
        {isLoading && (
          <div className="flex items-center justify-center py-20">
            <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
          </div>
        )}

        {error && (
          <div className="text-center py-20 text-muted-foreground">
            Không thể tải thông tin hỗ trợ. Vui lòng thử lại sau.
          </div>
        )}

        {!isLoading && !error && info && (
          <div className="space-y-8">
            <p className="text-muted-foreground">
              Bạn cần hỗ trợ? Liên hệ chúng tôi qua các kênh sau.
            </p>

            <div className="space-y-4">
              {info.supportEmail && (
                <div className="flex items-center gap-3 rounded-lg border p-4">
                  <Mail className="h-5 w-5 shrink-0 text-muted-foreground" />
                  <div>
                    <p className="text-sm font-medium">Email</p>
                    <a
                      href={`mailto:${info.supportEmail}`}
                      className="text-primary hover:underline"
                    >
                      {info.supportEmail}
                    </a>
                  </div>
                </div>
              )}
              {info.supportPhone && (
                <div className="flex items-center gap-3 rounded-lg border p-4">
                  <Phone className="h-5 w-5 shrink-0 text-muted-foreground" />
                  <div>
                    <p className="text-sm font-medium">Điện thoại</p>
                    <a
                      href={`tel:${info.supportPhone.replace(/\s/g, "")}`}
                      className="text-primary hover:underline"
                    >
                      {info.supportPhone}
                    </a>
                  </div>
                </div>
              )}
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
              </ul>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
