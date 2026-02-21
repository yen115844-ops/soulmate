"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Coins, Loader2, Pencil, Plus, Star, Trash2 } from "lucide-react";
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
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
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
import { Textarea } from "@/components/ui/textarea";
import { creditPackagesApi } from "@/lib/api/credits";
import { CreditPackage } from "@/types";

export default function CreditPackagesPage() {
  const queryClient = useQueryClient();
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingItem, setEditingItem] = useState<CreditPackage | null>(null);
  const [deleteItem, setDeleteItem] = useState<CreditPackage | null>(null);
  const [formData, setFormData] = useState({
    code: "",
    name: "",
    nameVi: "",
    description: "",
    creditAmount: 100,
    bonusCredits: 0,
    priceVnd: 100000,
    appleProductId: "",
    googleProductId: "",
    originalPrice: 0,
    discountPercent: 0,
    isBestValue: false,
    isActive: true,
    sortOrder: 0,
  });

  // Fetch credit packages from API
  const { data: packagesData, isLoading } = useQuery({
    queryKey: ["credit-packages"],
    queryFn: () => creditPackagesApi.getAll(true),
  });

  const packages = packagesData?.packages || [];
  const exchangeRate = packagesData?.exchangeRate || 1000;

  // Create mutation
  const createMutation = useMutation({
    mutationFn: (data: Partial<CreditPackage>) => creditPackagesApi.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["credit-packages"] });
      toast.success("Đã tạo gói credits");
      setIsFormOpen(false);
      resetForm();
    },
    onError: () => {
      toast.error("Tạo gói credits thất bại");
    },
  });

  // Update mutation
  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<CreditPackage> }) =>
      creditPackagesApi.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["credit-packages"] });
      toast.success("Đã cập nhật gói credits");
      setIsFormOpen(false);
      setEditingItem(null);
      resetForm();
    },
    onError: () => {
      toast.error("Cập nhật gói credits thất bại");
    },
  });

  // Delete mutation
  const deleteMutation = useMutation({
    mutationFn: (id: string) => creditPackagesApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["credit-packages"] });
      toast.success("Đã xóa gói credits");
      setDeleteItem(null);
    },
    onError: () => {
      toast.error("Xóa gói credits thất bại");
    },
  });

  const resetForm = () => {
    setFormData({
      code: "",
      name: "",
      nameVi: "",
      description: "",
      creditAmount: 100,
      bonusCredits: 0,
      priceVnd: 100000,
      appleProductId: "",
      googleProductId: "",
      originalPrice: 0,
      discountPercent: 0,
      isBestValue: false,
      isActive: true,
      sortOrder: packages.length + 1,
    });
  };

  const openCreateForm = () => {
    setEditingItem(null);
    resetForm();
    setIsFormOpen(true);
  };

  const openEditForm = (item: CreditPackage) => {
    setEditingItem(item);
    setFormData({
      code: item.code,
      name: item.name,
      nameVi: item.nameVi || item.name,
      description: item.description || "",
      creditAmount: item.creditAmount,
      bonusCredits: item.bonusCredits,
      priceVnd: item.priceVnd,
      appleProductId: item.appleProductId || "",
      googleProductId: item.googleProductId || "",
      originalPrice: item.originalPrice || 0,
      discountPercent: item.discountPercent || 0,
      isBestValue: item.isBestValue,
      isActive: item.isActive,
      sortOrder: item.sortOrder,
    });
    setIsFormOpen(true);
  };

  const handleSubmit = () => {
    const payload = {
      ...formData,
      nameVi: formData.nameVi || formData.name,
      appleProductId: formData.appleProductId || undefined,
      googleProductId: formData.googleProductId || undefined,
      originalPrice: formData.originalPrice || undefined,
      discountPercent: formData.discountPercent || undefined,
    };
    if (editingItem) {
      updateMutation.mutate({ id: editingItem.id, data: payload });
    } else {
      createMutation.mutate(payload);
    }
  };

  const handleDelete = () => {
    if (deleteItem) {
      deleteMutation.mutate(deleteItem.id);
    }
  };

  const formatPrice = (price: number) => {
    return new Intl.NumberFormat("vi-VN", {
      style: "currency",
      currency: "VND",
    }).format(price);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Gói Credits</h1>
          <p className="text-muted-foreground">
            Quản lý các gói credits (consumable) cho người dùng mua
          </p>
        </div>
        <Button onClick={openCreateForm}>
          <Plus className="mr-2 h-4 w-4" />
          Thêm gói
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid gap-4 md:grid-cols-3">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Tổng số gói</CardTitle>
            <Coins className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{packages.length}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Đang hoạt động</CardTitle>
            <Star className="h-4 w-4 text-green-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {packages.filter((p) => p.isActive).length}
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Gói Best Value</CardTitle>
            <Star className="h-4 w-4 text-amber-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {packages.filter((p) => p.isBestValue).length}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Table */}
      <Card>
        <CardHeader>
          <CardTitle>Danh sách gói Credits</CardTitle>
          <CardDescription>
            Tỷ giá hiện tại: 1 Credit = {exchangeRate.toLocaleString()}đ
          </CardDescription>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-3">
              {[1, 2, 3].map((i) => (
                <Skeleton key={i} className="h-12 w-full" />
              ))}
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Mã</TableHead>
                  <TableHead>Tên gói</TableHead>
                  <TableHead className="text-right">Credits</TableHead>
                  <TableHead className="text-right">Bonus</TableHead>
                  <TableHead className="text-right">Giá</TableHead>
                  <TableHead>Trạng thái</TableHead>
                  <TableHead className="text-right">Thao tác</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {packages.map((pkg) => (
                  <TableRow key={pkg.id}>
                    <TableCell className="font-mono text-sm">{pkg.code}</TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        {pkg.nameVi || pkg.name}
                        {pkg.isBestValue && (
                          <Badge variant="secondary" className="bg-amber-100 text-amber-800">
                            Best Value
                          </Badge>
                        )}
                      </div>
                    </TableCell>
                    <TableCell className="text-right font-medium">
                      {pkg.creditAmount.toLocaleString()}
                    </TableCell>
                    <TableCell className="text-right">
                      {pkg.bonusCredits > 0 && (
                        <span className="text-green-600">+{pkg.bonusCredits}</span>
                      )}
                    </TableCell>
                    <TableCell className="text-right">
                      {formatPrice(pkg.priceVnd)}
                      {pkg.discountPercent && pkg.discountPercent > 0 && (
                        <span className="ml-1 text-xs text-green-600">
                          -{pkg.discountPercent}%
                        </span>
                      )}
                    </TableCell>
                    <TableCell>
                      <Badge variant={pkg.isActive ? "default" : "secondary"}>
                        {pkg.isActive ? "Hoạt động" : "Tắt"}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="flex justify-end gap-2">
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => openEditForm(pkg)}
                        >
                          <Pencil className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => setDeleteItem(pkg)}
                        >
                          <Trash2 className="h-4 w-4 text-destructive" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
                {packages.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={7} className="text-center text-muted-foreground">
                      Chưa có gói credits nào
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Create/Edit Dialog */}
      <Dialog open={isFormOpen} onOpenChange={setIsFormOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>
              {editingItem ? "Chỉnh sửa gói Credits" : "Thêm gói Credits mới"}
            </DialogTitle>
            <DialogDescription>
              {editingItem
                ? "Cập nhật thông tin gói credits"
                : "Tạo gói credits mới cho người dùng mua"}
            </DialogDescription>
          </DialogHeader>

          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="code">Mã gói *</Label>
                <Input
                  id="code"
                  placeholder="credits_100"
                  value={formData.code}
                  onChange={(e) =>
                    setFormData({ ...formData, code: e.target.value })
                  }
                  disabled={!!editingItem}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="sortOrder">Thứ tự</Label>
                <Input
                  id="sortOrder"
                  type="number"
                  value={formData.sortOrder}
                  onChange={(e) =>
                    setFormData({ ...formData, sortOrder: parseInt(e.target.value) || 0 })
                  }
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="name">Tên (EN)</Label>
                <Input
                  id="name"
                  placeholder="100 Credits"
                  value={formData.name}
                  onChange={(e) =>
                    setFormData({ ...formData, name: e.target.value })
                  }
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="nameVi">Tên (VI) *</Label>
                <Input
                  id="nameVi"
                  placeholder="100 Credits"
                  value={formData.nameVi}
                  onChange={(e) =>
                    setFormData({ ...formData, nameVi: e.target.value })
                  }
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="description">Mô tả</Label>
              <Textarea
                id="description"
                placeholder="Mô tả gói credits..."
                value={formData.description}
                onChange={(e) =>
                  setFormData({ ...formData, description: e.target.value })
                }
              />
            </div>

            <div className="grid grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label htmlFor="creditAmount">Số Credits *</Label>
                <Input
                  id="creditAmount"
                  type="number"
                  value={formData.creditAmount}
                  onChange={(e) =>
                    setFormData({ ...formData, creditAmount: parseInt(e.target.value) || 0 })
                  }
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="bonusCredits">Bonus Credits</Label>
                <Input
                  id="bonusCredits"
                  type="number"
                  value={formData.bonusCredits}
                  onChange={(e) =>
                    setFormData({ ...formData, bonusCredits: parseInt(e.target.value) || 0 })
                  }
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="priceVnd">Giá (VND) *</Label>
                <Input
                  id="priceVnd"
                  type="number"
                  value={formData.priceVnd}
                  onChange={(e) =>
                    setFormData({ ...formData, priceVnd: parseInt(e.target.value) || 0 })
                  }
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="appleProductId">Apple Product ID</Label>
                <Input
                  id="appleProductId"
                  placeholder="com.app.credits_100"
                  value={formData.appleProductId}
                  onChange={(e) =>
                    setFormData({ ...formData, appleProductId: e.target.value })
                  }
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="googleProductId">Google Product ID</Label>
                <Input
                  id="googleProductId"
                  placeholder="credits_100"
                  value={formData.googleProductId}
                  onChange={(e) =>
                    setFormData({ ...formData, googleProductId: e.target.value })
                  }
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="originalPrice">Giá gốc (VND)</Label>
                <Input
                  id="originalPrice"
                  type="number"
                  placeholder="Để trống nếu không có"
                  value={formData.originalPrice || ""}
                  onChange={(e) =>
                    setFormData({ ...formData, originalPrice: parseInt(e.target.value) || 0 })
                  }
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="discountPercent">Giảm giá (%)</Label>
                <Input
                  id="discountPercent"
                  type="number"
                  max={100}
                  value={formData.discountPercent || ""}
                  onChange={(e) =>
                    setFormData({ ...formData, discountPercent: parseInt(e.target.value) || 0 })
                  }
                />
              </div>
            </div>

            <div className="flex items-center gap-6">
              <div className="flex items-center space-x-2">
                <Switch
                  id="isActive"
                  checked={formData.isActive}
                  onCheckedChange={(checked) =>
                    setFormData({ ...formData, isActive: checked })
                  }
                />
                <Label htmlFor="isActive">Hoạt động</Label>
              </div>
              <div className="flex items-center space-x-2">
                <Switch
                  id="isBestValue"
                  checked={formData.isBestValue}
                  onCheckedChange={(checked) =>
                    setFormData({ ...formData, isBestValue: checked })
                  }
                />
                <Label htmlFor="isBestValue">Best Value (đánh dấu nổi bật)</Label>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setIsFormOpen(false)}>
              Hủy
            </Button>
            <Button
              onClick={handleSubmit}
              disabled={createMutation.isPending || updateMutation.isPending}
            >
              {(createMutation.isPending || updateMutation.isPending) && (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              )}
              {editingItem ? "Cập nhật" : "Tạo mới"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <AlertDialog open={!!deleteItem} onOpenChange={() => setDeleteItem(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Xác nhận xóa</AlertDialogTitle>
            <AlertDialogDescription>
              Bạn có chắc muốn xóa gói credits &quot;{deleteItem?.nameVi || deleteItem?.name}&quot;?
              Hành động này không thể hoàn tác.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Hủy</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDelete}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
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
