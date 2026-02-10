"use client";

import { TermsContent } from "@/components/terms-content";
import { Loader2 } from "lucide-react";
import { useQuery } from "@tanstack/react-query";
import { termsApi } from "@/lib/api/terms";

export default function TermsAndConditionsPage() {
  const { data: content, isLoading, error } = useQuery({
    queryKey: ["public", "terms", "terms-and-conditions"],
    queryFn: () => termsApi.getPublic("terms-and-conditions"),
  });

  return (
    <div className="min-h-screen bg-background">
      <header className="border-b">
        <div className="container mx-auto px-4 py-4">
          <h1 className="text-lg font-semibold">Điều kiện sử dụng</h1>
        </div>
      </header>

      <main className="container mx-auto px-4 py-8 max-w-3xl">
        {isLoading && (
          <div className="flex items-center justify-center py-20">
            <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
          </div>
        )}

        {error && (
          <div className="text-center py-20 text-muted-foreground">
            Không thể tải nội dung. Vui lòng thử lại sau.
          </div>
        )}

        {!isLoading && !error && content && (
          <>
            <p className="text-sm text-muted-foreground mb-6">
              Cập nhật lần cuối: {new Date().toLocaleDateString("vi-VN")}
            </p>
            <TermsContent content={content} />
          </>
        )}
      </main>
    </div>
  );
}
