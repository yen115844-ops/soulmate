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
import { Textarea } from "@/components/ui/textarea";
import { serviceTypesApi } from "@/lib/api/master-data";
import { ServiceType } from "@/types";

export default function ServiceTypesPage() {
  const queryClient = useQueryClient();
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingItem, setEditingItem] = useState<ServiceType | null>(null);
  const [deleteItem, setDeleteItem] = useState<ServiceType | null>(null);
  const [formData, setFormData] = useState({
    code: "",
    name: "",
    nameVi: "",
    description: "",
    icon: "",
    sortOrder: 0,
    isActive: true,
  });

  // Fetch service types from API
  const { data: serviceTypesData, isLoading } = useQuery({
    queryKey: ["service-types"],
    queryFn: () => serviceTypesApi.getAll(true), // includeInactive = true for admin
  });

  const serviceTypes = serviceTypesData?.data || [];

  // Create mutation
  const createMutation = useMutation({
    mutationFn: (data: Partial<ServiceType>) => serviceTypesApi.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["service-types"] });
      toast.success("Service type created successfully");
      setIsFormOpen(false);
    },
    onError: () => {
      toast.error("Tạo loại dịch vụ thất bại");
    },
  });

  // Update mutation
  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<ServiceType> }) =>
      serviceTypesApi.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["service-types"] });
      toast.success("Đã cập nhật loại dịch vụ");
      setIsFormOpen(false);
      setEditingItem(null);
    },
    onError: () => {
      toast.error("Cập nhật loại dịch vụ thất bại");
    },
  });

  // Delete mutation
  const deleteMutation = useMutation({
    mutationFn: (id: string) => serviceTypesApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["service-types"] });
      toast.success("Đã xóa loại dịch vụ");
      setDeleteItem(null);
    },
    onError: () => {
      toast.error("Xóa loại dịch vụ thất bại");
    },
  });

  const openCreateForm = () => {
    setEditingItem(null);
    setFormData({
      code: "",
      name: "",
      nameVi: "",
      description: "",
      icon: "",
      sortOrder: serviceTypes.length + 1,
      isActive: true,
    });
    setIsFormOpen(true);
  };

  const openEditForm = (item: ServiceType) => {
    setEditingItem(item);
    setFormData({
      code: item.code,
      name: item.name,
      nameVi: item.nameVi || item.name,
      description: item.description || "",
      icon: item.icon || "",
      sortOrder: item.sortOrder,
      isActive: item.isActive,
    });
    setIsFormOpen(true);
  };

  const handleSubmit = () => {
    const payload = {
      ...formData,
      nameVi: formData.nameVi || formData.name,
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

  const isSubmitting = createMutation.isPending || updateMutation.isPending;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Loại dịch vụ</h1>
          <p className="text-muted-foreground">
            Quản lý loại dịch vụ mà đối tác có thể cung cấp
          </p>
        </div>
        <Button onClick={openCreateForm}>
          <Plus className="mr-2 h-4 w-4" />
          Thêm loại dịch vụ
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
                  <TableHead className="w-16">Icon</TableHead>
                  <TableHead>Code</TableHead>
                  <TableHead>Name</TableHead>
                  <TableHead>Description</TableHead>
                  <TableHead className="w-24">Sort</TableHead>
                  <TableHead className="w-24">Status</TableHead>
                  <TableHead className="w-24">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {serviceTypes.map((item) => (
                  <TableRow key={item.id}>
                    <TableCell className="text-2xl">{item.icon}</TableCell>
                    <TableCell className="font-mono">{item.code}</TableCell>
                    <TableCell className="font-medium">{item.nameVi || item.name}</TableCell>
                    <TableCell className="text-muted-foreground">
                      {item.description}
                    </TableCell>
                    <TableCell>{item.sortOrder}</TableCell>
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
              {editingItem ? "Sửa loại dịch vụ" : "Tạo loại dịch vụ"}
            </DialogTitle>
            <DialogDescription>
              {editingItem
                ? "Cập nhật thông tin loại dịch vụ"
                : "Thêm loại dịch vụ mới vào nền tảng"}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4">
            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label>Code</Label>
                <Input
                  placeholder="e.g., walking"
                  value={formData.code}
                  onChange={(e) =>
                    setFormData({ ...formData, code: e.target.value })
                  }
                />
              </div>
              <div className="space-y-2">
                <Label>Name (EN)</Label>
                <Input
                  placeholder="e.g., Walking"
                  value={formData.name}
                  onChange={(e) =>
                    setFormData({ ...formData, name: e.target.value })
                  }
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label>Tên tiếng Việt</Label>
              <Input
                placeholder="e.g., Đi dạo"
                value={formData.nameVi}
                onChange={(e) =>
                  setFormData({ ...formData, nameVi: e.target.value })
                }
              />
            </div>

            <div className="space-y-2">
              <Label>Description</Label>
              <Textarea
                placeholder="Enter description..."
                value={formData.description}
                onChange={(e) =>
                  setFormData({ ...formData, description: e.target.value })
                }
              />
            </div>

            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label>Icon (emoji)</Label>
                <Input
                  placeholder="e.g., ☕"
                  value={formData.icon}
                  onChange={(e) =>
                    setFormData({ ...formData, icon: e.target.value })
                  }
                />
              </div>
              <div className="space-y-2">
                <Label>Thứ tự (sortOrder)</Label>
                <Input
                  type="number"
                  value={formData.sortOrder}
                  onChange={(e) =>
                    setFormData({
                      ...formData,
                      sortOrder: parseInt(e.target.value) || 0,
                    })
                  }
                />
              </div>
            </div>

            <div className="flex items-center gap-2">
              <Switch
                checked={formData.isActive}
                onCheckedChange={(checked) =>
                  setFormData({ ...formData, isActive: checked })
                }
              />
              <Label>Active</Label>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setIsFormOpen(false)} disabled={isSubmitting}>
              Hủy
            </Button>
            <Button onClick={handleSubmit} disabled={isSubmitting}>
              {isSubmitting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              {editingItem ? "Cập nhật" : "Tạo"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <AlertDialog open={!!deleteItem} onOpenChange={() => setDeleteItem(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Xóa loại dịch vụ</AlertDialogTitle>
            <AlertDialogDescription>
              Bạn có chắc muốn xóa &quot;{deleteItem?.name}&quot;? Hành động này không thể hoàn tác.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={deleteMutation.isPending}>Hủy</AlertDialogCancel>
            <AlertDialogAction onClick={handleDelete} disabled={deleteMutation.isPending}>
              {deleteMutation.isPending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              Xóa
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
