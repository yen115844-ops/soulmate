"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Loader2, Pencil, Plus, Trash2 } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

import {
    AlertDialog,
    AlertDialogAction,
    AlertDialogCancel,
    AlertDialogContent,
    AlertDialogDescription,
    AlertDialogFooter,
    AlertDialogHeader,
    AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import { Switch } from "@/components/ui/switch";
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from "@/components/ui/table";
import { languagesApi } from "@/lib/api/master-data";
import { Language } from "@/types";

export default function LanguagesPage() {
  const queryClient = useQueryClient();
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingItem, setEditingItem] = useState<Language | null>(null);
  const [deleteItem, setDeleteItem] = useState<Language | null>(null);
  const [formData, setFormData] = useState({
    code: "",
    name: "",
    nativeName: "",
    displayOrder: 0,
    isActive: true,
  });

  const { data: languagesData, isLoading } = useQuery({
    queryKey: ["languages"],
    queryFn: () => languagesApi.getAll(true),
  });

  const languages = languagesData?.data || [];

  // Mutations
  const createMutation = useMutation({
    mutationFn: (data: Partial<Language>) => languagesApi.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["languages"] });
      toast.success("Đã tạo ngôn ngữ");
      setIsFormOpen(false);
    },
    onError: () => toast.error("Tạo ngôn ngữ thất bại"),
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<Language> }) =>
      languagesApi.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["languages"] });
      toast.success("Đã cập nhật ngôn ngữ");
      setIsFormOpen(false);
      setEditingItem(null);
    },
    onError: () => toast.error("Cập nhật ngôn ngữ thất bại"),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => languagesApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["languages"] });
      toast.success("Đã xóa ngôn ngữ");
      setDeleteItem(null);
    },
    onError: () => toast.error("Xóa ngôn ngữ thất bại"),
  });

  const openCreateForm = () => {
    setEditingItem(null);
    setFormData({
      code: "",
      name: "",
      nativeName: "",
      displayOrder: languages.length + 1,
      isActive: true,
    });
    setIsFormOpen(true);
  };

  const openEditForm = (item: Language) => {
    setEditingItem(item);
    setFormData({
      code: item.code,
      name: item.name,
      nativeName: item.nativeName || "",
      displayOrder: item.displayOrder,
      isActive: item.isActive,
    });
    setIsFormOpen(true);
  };

  const handleSubmit = () => {
    if (editingItem) {
      updateMutation.mutate({
        id: editingItem.id,
        data: formData,
      });
    } else {
      createMutation.mutate(formData);
    }
  };

  const handleDelete = () => {
    if (deleteItem) {
      deleteMutation.mutate(deleteItem.id);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Ngôn ngữ</h1>
          <p className="text-muted-foreground">
            Quản lý ngôn ngữ trên nền tảng
          </p>
        </div>
        <Button onClick={openCreateForm}>
          <Plus className="mr-2 h-4 w-4" />
          Thêm ngôn ngữ
        </Button>
      </div>

      <Card>
        <CardContent className="p-0">
          {isLoading ? (
            <div className="space-y-4 p-6">
              {Array.from({ length: 5 }).map((_, i) => (
                <Skeleton key={i} className="h-12 w-full" />
              ))}
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-24">Mã</TableHead>
                  <TableHead>Tên</TableHead>
                  <TableHead>Tên bản địa</TableHead>
                  <TableHead className="w-24">Thứ tự</TableHead>
                  <TableHead className="w-24">Trạng thái</TableHead>
                  <TableHead className="w-24">Thao tác</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {languages.map((item) => (
                  <TableRow key={item.id}>
                    <TableCell>
                      <Badge variant="outline" className="font-mono uppercase">
                        {item.code}
                      </Badge>
                    </TableCell>
                    <TableCell className="font-medium">{item.name}</TableCell>
                    <TableCell className="text-muted-foreground">
                      {item.nativeName}
                    </TableCell>
                    <TableCell>{item.displayOrder}</TableCell>
                    <TableCell>
                      <Badge variant={item.isActive ? "default" : "secondary"}>
                        {item.isActive ? "Hoạt động" : "Ẩn"}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => openEditForm(item)}
                        >
                          <Pencil className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => setDeleteItem(item)}
                        >
                          <Trash2 className="h-4 w-4 text-destructive" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Create/Edit Dialog */}
      <Dialog open={isFormOpen} onOpenChange={setIsFormOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {editingItem ? "Sửa ngôn ngữ" : "Tạo ngôn ngữ"}
            </DialogTitle>
            <DialogDescription>
              {editingItem
                ? "Cập nhật thông tin ngôn ngữ"
                : "Thêm ngôn ngữ mới vào nền tảng"}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4">
            <div className="space-y-2">
              <Label>Code (ISO 639-1)</Label>
              <Input
                placeholder="e.g., vi, en, ja"
                value={formData.code}
                onChange={(e) =>
                  setFormData({ ...formData, code: e.target.value.toLowerCase() })
                }
                maxLength={5}
              />
              <p className="text-xs text-muted-foreground">
                Use standard language codes like &quot;vi&quot;, &quot;en&quot;, &quot;ja&quot;
              </p>
            </div>

            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label>Name</Label>
                <Input
                  placeholder="e.g., Vietnamese"
                  value={formData.name}
                  onChange={(e) =>
                    setFormData({ ...formData, name: e.target.value })
                  }
                />
              </div>
              <div className="space-y-2">
                <Label>Native Name</Label>
                <Input
                  placeholder="e.g., Tiếng Việt"
                  value={formData.nativeName}
                  onChange={(e) =>
                    setFormData({ ...formData, nativeName: e.target.value })
                  }
                />
              </div>
            </div>

            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label>Display Order</Label>
                <Input
                  type="number"
                  value={formData.displayOrder}
                  onChange={(e) =>
                    setFormData({
                      ...formData,
                      displayOrder: parseInt(e.target.value) || 0,
                    })
                  }
                />
              </div>
              <div className="flex items-center gap-2 pt-6">
                <Switch
                  checked={formData.isActive}
                  onCheckedChange={(checked) =>
                    setFormData({ ...formData, isActive: checked })
                  }
                />
                <Label>Active</Label>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button 
              variant="outline" 
              onClick={() => setIsFormOpen(false)}
              disabled={createMutation.isPending || updateMutation.isPending}
            >
              Hủy
            </Button>
            <Button 
              onClick={handleSubmit}
              disabled={createMutation.isPending || updateMutation.isPending}
            >
              {(createMutation.isPending || updateMutation.isPending) && (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              )}
              {editingItem ? "Cập nhật" : "Tạo"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <AlertDialog open={!!deleteItem} onOpenChange={() => setDeleteItem(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Xóa ngôn ngữ</AlertDialogTitle>
            <AlertDialogDescription>
              Bạn có chắc muốn xóa &quot;{deleteItem?.name}&quot;? Hành động này không thể hoàn tác.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={deleteMutation.isPending}>
              Hủy
            </AlertDialogCancel>
            <AlertDialogAction 
              onClick={handleDelete}
              disabled={deleteMutation.isPending}
            >
              {deleteMutation.isPending && (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              )}
              Xóa
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
