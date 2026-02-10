"use client";

import { useQuery, useQueryClient } from "@tanstack/react-query";
import { FileText, Save, Loader2 } from "lucide-react";
import { useState, useEffect } from "react";
import { toast } from "sonner";

import { MarkdownEditor } from "@/components/markdown-editor";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { termsApi } from "@/lib/api/terms";
import { handleApiError } from "@/lib/api-client";

export default function TermsEditorPage() {
  const queryClient = useQueryClient();
  const [activeTab, setActiveTab] = useState("terms-of-service");
  const [termsOfService, setTermsOfService] = useState("");
  const [termsAndConditions, setTermsAndConditions] = useState("");
  const [isSaving, setIsSaving] = useState(false);

  const { data, isLoading } = useQuery({
    queryKey: ["admin", "terms"],
    queryFn: () => termsApi.getAdmin(),
  });

  useEffect(() => {
    if (data) {
      setTermsOfService(data.termsOfService);
      setTermsAndConditions(data.termsAndConditions);
    }
  }, [data]);

  const handleSaveTermsOfService = async () => {
    setIsSaving(true);
    try {
      await termsApi.updateAdmin({ termsOfService });
      await queryClient.invalidateQueries({ queryKey: ["admin", "terms"] });
      await queryClient.invalidateQueries({ queryKey: ["public", "terms", "terms-of-service"] });
      toast.success("Đã lưu Điều khoản sử dụng");
    } catch (err) {
      toast.error(handleApiError(err) || "Lưu thất bại");
    } finally {
      setIsSaving(false);
    }
  };

  const handleSaveTermsAndConditions = async () => {
    setIsSaving(true);
    try {
      await termsApi.updateAdmin({ termsAndConditions });
      await queryClient.invalidateQueries({ queryKey: ["admin", "terms"] });
      await queryClient.invalidateQueries({ queryKey: ["public", "terms", "terms-and-conditions"] });
      toast.success("Đã lưu Điều kiện sử dụng");
    } catch (err) {
      toast.error(handleApiError(err) || "Lưu thất bại");
    } finally {
      setIsSaving(false);
    }
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div>
          <Skeleton className="h-9 w-64" />
          <Skeleton className="mt-2 h-5 w-96" />
        </div>
        <Skeleton className="h-10 w-full max-w-[400px]" />
        <Skeleton className="h-[400px] w-full" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Điều khoản & Điều kiện</h1>
        <p className="text-muted-foreground">
          Chỉnh sửa nội dung Điều khoản sử dụng và Điều kiện sử dụng. Hỗ trợ Markdown (# tiêu đề, ## tiêu đề nhỏ, - danh sách).
        </p>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
        <TabsList className="grid w-full max-w-md grid-cols-2">
          <TabsTrigger value="terms-of-service" className="flex items-center gap-2">
            <FileText className="h-4 w-4" />
            Điều khoản sử dụng
          </TabsTrigger>
          <TabsTrigger value="terms-and-conditions" className="flex items-center gap-2">
            <FileText className="h-4 w-4" />
            Điều kiện sử dụng
          </TabsTrigger>
        </TabsList>

        <TabsContent value="terms-of-service" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Điều khoản sử dụng</CardTitle>
              <CardDescription>
                Nội dung hiển thị tại trang /terms-of-service. Dùng Markdown: # tiêu đề, ## mục, - danh sách.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <MarkdownEditor
                value={termsOfService}
                onChange={(v) => setTermsOfService(v ?? "")}
                placeholder="# Điều khoản sử dụng

## 1. Giới thiệu
..."
                minHeight={500}
              />
              <div className="flex justify-end">
                <Button onClick={handleSaveTermsOfService} disabled={isSaving}>
                  {isSaving ? (
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  ) : (
                    <Save className="mr-2 h-4 w-4" />
                  )}
                  {isSaving ? "Đang lưu..." : "Lưu"}
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="terms-and-conditions" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Điều kiện sử dụng</CardTitle>
              <CardDescription>
                Nội dung hiển thị tại trang /terms-and-conditions. Dùng Markdown: # tiêu đề, ## mục, - danh sách.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <MarkdownEditor
                value={termsAndConditions}
                onChange={(v) => setTermsAndConditions(v ?? "")}
                placeholder="# Điều kiện sử dụng

## 1. Điều kiện chung
..."
                minHeight={500}
              />
              <div className="flex justify-end">
                <Button onClick={handleSaveTermsAndConditions} disabled={isSaving}>
                  {isSaving ? (
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  ) : (
                    <Save className="mr-2 h-4 w-4" />
                  )}
                  {isSaving ? "Đang lưu..." : "Lưu"}
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
