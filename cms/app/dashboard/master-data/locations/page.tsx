"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ChevronRight, Loader2, MapPin, Pencil, Plus, Trash2 } from "lucide-react";
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
    Collapsible,
    CollapsibleContent,
    CollapsibleTrigger,
} from "@/components/ui/collapsible";
import {
    Dialog,
    DialogContent,
    DialogFooter,
    DialogHeader,
    DialogTitle
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select";
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
import { districtsApi, provincesApi } from "@/lib/api/master-data";
import { District, Province } from "@/types";

export default function LocationsPage() {
  const queryClient = useQueryClient();
  const [isProvinceFormOpen, setIsProvinceFormOpen] = useState(false);
  const [isDistrictFormOpen, setIsDistrictFormOpen] = useState(false);
  const [editingProvince, setEditingProvince] = useState<Province | null>(null);
  const [editingDistrict, setEditingDistrict] = useState<District | null>(null);
  const [selectedProvinceId, setSelectedProvinceId] = useState<string | null>(null);
  const [deleteItem, setDeleteItem] = useState<{ type: "province" | "district"; item: Province | District } | null>(null);

  const [provinceForm, setProvinceForm] = useState({
    code: "",
    name: "",
    nameEn: "",
    sortOrder: 0,
    isActive: true,
  });

  const [districtForm, setDistrictForm] = useState({
    provinceId: "",
    code: "",
    name: "",
    nameEn: "",
    sortOrder: 0,
    isActive: true,
  });

  const { data: provincesData, isLoading } = useQuery({
    queryKey: ["provinces"],
    queryFn: () => provincesApi.getAll(true),
  });

  const provinces = provincesData?.data || [];

  // Province mutations
  const createProvinceMutation = useMutation({
    mutationFn: (data: Partial<Province>) => provincesApi.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["provinces"] });
      toast.success("Đã tạo tỉnh");
      setIsProvinceFormOpen(false);
    },
    onError: () => toast.error("Failed to create province"),
  });

  const updateProvinceMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<Province> }) =>
      provincesApi.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["provinces"] });
      toast.success("Đã cập nhật tỉnh");
      setIsProvinceFormOpen(false);
      setEditingProvince(null);
    },
    onError: () => toast.error("Failed to update province"),
  });

  const deleteProvinceMutation = useMutation({
    mutationFn: (id: string) => provincesApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["provinces"] });
      toast.success("Đã xóa tỉnh");
      setDeleteItem(null);
    },
    onError: () => toast.error("Failed to delete province"),
  });

  // District mutations
  const createDistrictMutation = useMutation({
    mutationFn: (data: Partial<District>) => districtsApi.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["districts"] });
      // Also invalidate provinces to update counts if needed
      queryClient.invalidateQueries({ queryKey: ["provinces"] });
      toast.success("Đã tạo quận/huyện");
      setIsDistrictFormOpen(false);
    },
    onError: () => toast.error("Failed to create district"),
  });

  const updateDistrictMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<District> }) =>
      districtsApi.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["districts"] });
      toast.success("Đã cập nhật quận/huyện");
      setIsDistrictFormOpen(false);
      setEditingDistrict(null);
    },
    onError: () => toast.error("Failed to update district"),
  });

  const deleteDistrictMutation = useMutation({
    mutationFn: (id: string) => districtsApi.delete(id),
    onSuccess: () => {
        queryClient.invalidateQueries({ queryKey: ["districts"] });
        queryClient.invalidateQueries({ queryKey: ["provinces"] });
      toast.success("Đã xóa quận/huyện");
      setDeleteItem(null);
    },
    onError: () => toast.error("Failed to delete district"),
  });

  // Province handlers
  const openCreateProvince = () => {
    setEditingProvince(null);
    setProvinceForm({
      code: "",
      name: "",
      nameEn: "",
      sortOrder: provinces.length + 1,
      isActive: true,
    });
    setIsProvinceFormOpen(true);
  };

  const openEditProvince = (province: Province) => {
    setEditingProvince(province);
    setProvinceForm({
      code: province.code,
      name: province.name,
      nameEn: province.nameEn || "",
      sortOrder: province.sortOrder,
      isActive: province.isActive,
    });
    setIsProvinceFormOpen(true);
  };

  const handleProvinceSubmit = () => {
    if (editingProvince) {
      updateProvinceMutation.mutate({
        id: editingProvince.id,
        data: provinceForm,
      });
    } else {
      createProvinceMutation.mutate(provinceForm);
    }
  };

  // District handlers
  const openCreateDistrict = (provinceId: string) => {
    setEditingDistrict(null);
    setSelectedProvinceId(provinceId);
    // Logic for sortOrder depends on fetching districts, which we might not have here.
    // Default to 1 or try to find max order if districts are loaded?
    // Since we fetch districts on expand, we might not have them.
    // Let's set default to 1.
    setDistrictForm({
      provinceId,
      code: "",
      name: "",
      nameEn: "",
      sortOrder: 1,
      isActive: true,
    });
    setIsDistrictFormOpen(true);
  };

  const openEditDistrict = (district: District) => {
    setEditingDistrict(district);
    setSelectedProvinceId(district.provinceId);
    setDistrictForm({
      provinceId: district.provinceId,
      code: district.code,
      name: district.name,
      nameEn: district.nameEn || "",
      sortOrder: district.sortOrder,
      isActive: district.isActive,
    });
    setIsDistrictFormOpen(true);
  };

  const handleDistrictSubmit = () => {
    if (editingDistrict) {
      updateDistrictMutation.mutate({
        id: editingDistrict.id,
        data: districtForm,
      });
    } else {
      createDistrictMutation.mutate(districtForm);
    }
  };

  const handleDelete = () => {
    if (!deleteItem) return;
    if (deleteItem.type === "province") {
      deleteProvinceMutation.mutate(deleteItem.item.id);
    } else {
      deleteDistrictMutation.mutate(deleteItem.item.id);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Tỉnh & Quận/Huyện</h1>
          <p className="text-muted-foreground">
            Quản lý địa điểm trên nền tảng
          </p>
        </div>
        <Button onClick={openCreateProvince}>
          <Plus className="mr-2 h-4 w-4" />
          Thêm tỉnh
        </Button>
      </div>

      <Card>
        <CardContent className="p-0">
          {isLoading ? (
            <div className="space-y-4 p-6">
              {Array.from({ length: 3 }).map((_, i) => (
                <Skeleton key={i} className="h-16 w-full" />
              ))}
            </div>
          ) : (
            <div className="divide-y">
              {provinces.map((province) => (
                <ProvinceRow
                    key={province.id}
                    province={province}
                    onEditProvince={openEditProvince}
                    onDeleteProvince={(p) => setDeleteItem({ type: "province", item: p })}
                    onAddDistrict={openCreateDistrict}
                    onEditDistrict={openEditDistrict}
                    onDeleteDistrict={(d) => setDeleteItem({ type: "district", item: d })}
                />
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Province Form Dialog */}
      <Dialog open={isProvinceFormOpen} onOpenChange={setIsProvinceFormOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {editingProvince ? "Sửa tỉnh" : "Tạo tỉnh"}
            </DialogTitle>
          </DialogHeader>

          <div className="space-y-4">
            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label>Code</Label>
                <Input
                  placeholder="e.g., HCM"
                  value={provinceForm.code}
                  onChange={(e) =>
                    setProvinceForm({ ...provinceForm, code: e.target.value })
                  }
                />
              </div>
              <div className="space-y-2">
                <Label>Name</Label>
                <Input
                  placeholder="e.g., Hồ Chí Minh"
                  value={provinceForm.name}
                  onChange={(e) =>
                    setProvinceForm({ ...provinceForm, name: e.target.value })
                  }
                />
              </div>
            </div>
            
            <div className="space-y-2">
                <Label>Name (EN)</Label>
                <Input
                  placeholder="e.g., Ho Chi Minh City"
                  value={provinceForm.nameEn}
                  onChange={(e) =>
                    setProvinceForm({ ...provinceForm, nameEn: e.target.value })
                  }
                />
            </div>

            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label>Sort Order</Label>
                <Input
                  type="number"
                  value={provinceForm.sortOrder}
                  onChange={(e) =>
                    setProvinceForm({
                      ...provinceForm,
                      sortOrder: parseInt(e.target.value) || 0,
                    })
                  }
                />
              </div>
              <div className="flex items-center gap-2 pt-6">
                <Switch
                  checked={provinceForm.isActive}
                  onCheckedChange={(checked) =>
                    setProvinceForm({ ...provinceForm, isActive: checked })
                  }
                />
                <Label>Active</Label>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setIsProvinceFormOpen(false)}
              disabled={createProvinceMutation.isPending || updateProvinceMutation.isPending}
            >
              Hủy
            </Button>
            <Button 
              onClick={handleProvinceSubmit}
              disabled={createProvinceMutation.isPending || updateProvinceMutation.isPending}
            >
              {(createProvinceMutation.isPending || updateProvinceMutation.isPending) && (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              )}
              {editingProvince ? "Cập nhật" : "Tạo"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* District Form Dialog */}
      <Dialog open={isDistrictFormOpen} onOpenChange={setIsDistrictFormOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {editingDistrict ? "Sửa quận/huyện" : "Tạo quận/huyện"}
            </DialogTitle>
          </DialogHeader>

          <div className="space-y-4">
            <div className="space-y-2">
              <Label>Tỉnh</Label>
              <Select
                value={districtForm.provinceId}
                onValueChange={(value) =>
                  setDistrictForm({ ...districtForm, provinceId: value })
                }
                disabled={!!selectedProvinceId}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Chọn tỉnh" />
                </SelectTrigger>
                <SelectContent>
                  {provinces.map((p) => (
                    <SelectItem key={p.id} value={p.id}>
                      {p.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label>Code</Label>
                <Input
                  placeholder="e.g., Q1"
                  value={districtForm.code}
                  onChange={(e) =>
                    setDistrictForm({ ...districtForm, code: e.target.value })
                  }
                />
              </div>
              <div className="space-y-2">
                <Label>Name</Label>
                <Input
                  placeholder="e.g., Quận 1"
                  value={districtForm.name}
                  onChange={(e) =>
                    setDistrictForm({ ...districtForm, name: e.target.value })
                  }
                />
              </div>
            </div>
            
            <div className="space-y-2">
                <Label>Name (EN)</Label>
                <Input
                  placeholder="e.g., District 1"
                  value={districtForm.nameEn}
                  onChange={(e) =>
                    setDistrictForm({ ...districtForm, nameEn: e.target.value })
                  }
                />
            </div>

            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label>Sort Order</Label>
                <Input
                  type="number"
                  value={districtForm.sortOrder}
                  onChange={(e) =>
                    setDistrictForm({
                      ...districtForm,
                      sortOrder: parseInt(e.target.value) || 0,
                    })
                  }
                />
              </div>
              <div className="flex items-center gap-2 pt-6">
                <Switch
                  checked={districtForm.isActive}
                  onCheckedChange={(checked) =>
                    setDistrictForm({ ...districtForm, isActive: checked })
                  }
                />
                <Label>Active</Label>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setIsDistrictFormOpen(false)}
              disabled={createDistrictMutation.isPending || updateDistrictMutation.isPending}
            >
              Hủy
            </Button>
            <Button 
              onClick={handleDistrictSubmit}
              disabled={createDistrictMutation.isPending || updateDistrictMutation.isPending}
            >
              {(createDistrictMutation.isPending || updateDistrictMutation.isPending) && (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              )}
              {editingDistrict ? "Cập nhật" : "Tạo"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <AlertDialog open={!!deleteItem} onOpenChange={() => setDeleteItem(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>
              Xóa {deleteItem?.type === "province" ? "tỉnh" : "quận/huyện"}
            </AlertDialogTitle>
            <AlertDialogDescription>
              Bạn có chắc muốn xóa &quot;{(deleteItem?.item as Province | District)?.name}&quot;?
              {deleteItem?.type === "province" &&
                " Điều này sẽ xóa tất cả quận/huyện trong tỉnh này."}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={deleteProvinceMutation.isPending || deleteDistrictMutation.isPending}>
              Hủy
            </AlertDialogCancel>
            <AlertDialogAction 
              onClick={handleDelete}
              disabled={deleteProvinceMutation.isPending || deleteDistrictMutation.isPending}
            >
              {(deleteProvinceMutation.isPending || deleteDistrictMutation.isPending) && (
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

function ProvinceRow({
    province,
    onEditProvince,
    onDeleteProvince,
    onAddDistrict,
    onEditDistrict,
    onDeleteDistrict
}: {
    province: Province;
    onEditProvince: (p: Province) => void;
    onDeleteProvince: (p: Province) => void;
    onAddDistrict: (provinceId: string) => void;
    onEditDistrict: (d: District) => void;
    onDeleteDistrict: (d: District) => void;
}) {
    const [isOpen, setIsOpen] = useState(false);

    const { data: districtsData, isLoading } = useQuery({
        queryKey: ["districts", province.id],
        queryFn: () => districtsApi.getAll(province.id, true),
        enabled: isOpen,
    });

    const districts = districtsData?.data || [];

    return (
        <Collapsible
            open={isOpen}
            onOpenChange={setIsOpen}
        >
            <div className="flex items-center justify-between p-4 hover:bg-muted/50">
            <CollapsibleTrigger className="flex flex-1 items-center gap-3">
                <ChevronRight
                className={`h-4 w-4 transition-transform ${
                    isOpen
                    ? "rotate-90"
                    : ""
                }`}
                />
                <MapPin className="h-4 w-4 text-muted-foreground" />
                <div className="text-left">
                <div className="flex items-center gap-2">
                    <p className="font-medium">{province.name}</p>
                    {province.nameEn && <span className="text-xs text-muted-foreground">({province.nameEn})</span>}
                </div>
                <p className="text-sm text-muted-foreground">
                    {province.code} • {province._count?.districts || 0} districts
                </p>
                </div>
            </CollapsibleTrigger>
            <div className="flex items-center gap-2">
                <Badge variant={province.isActive ? "default" : "secondary"}>
                {province.isActive ? "Hoạt động" : "Ẩn"}
                </Badge>
                <Button
                variant="ghost"
                size="icon"
                onClick={(e) => {
                    e.stopPropagation();
                    onEditProvince(province);
                }}
                >
                <Pencil className="h-4 w-4" />
                </Button>
                <Button
                variant="ghost"
                size="icon"
                onClick={(e) => {
                    e.stopPropagation();
                    onDeleteProvince(province);
                }}
                >
                <Trash2 className="h-4 w-4 text-destructive" />
                </Button>
            </div>
            </div>

            <CollapsibleContent>
            <div className="border-t bg-muted/30 p-4">
                <div className="mb-3 flex items-center justify-between">
                <p className="text-sm font-medium">Quận/Huyện</p>
                <Button
                    size="sm"
                    variant="outline"
                    onClick={() => onAddDistrict(province.id)}
                >
                    <Plus className="mr-1 h-3 w-3" />
                    Thêm quận/huyện
                </Button>
                </div>
                
                {isLoading ? (
                    <div className="flex justify-center p-4">
                        <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
                    </div>
                ) : (
                    <Table>
                    <TableHeader>
                        <TableRow>
                        <TableHead>Code</TableHead>
                        <TableHead>Name</TableHead>
                        <TableHead className="w-24">Order</TableHead>
                        <TableHead className="w-24">Status</TableHead>
                        <TableHead className="w-24">Actions</TableHead>
                        </TableRow>
                    </TableHeader>
                    <TableBody>
                        {districts.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={5} className="text-center text-muted-foreground">
                                    Chưa có quận/huyện nào
                                </TableCell>
                            </TableRow>
                        ) : (
                            districts.map((district) => (
                            <TableRow key={district.id}>
                                <TableCell className="font-mono">
                                {district.code}
                                </TableCell>
                                <TableCell>
                                    <div>{district.name}</div>
                                    {district.nameEn && <div className="text-xs text-muted-foreground">{district.nameEn}</div>}
                                </TableCell>
                                <TableCell>{district.sortOrder}</TableCell>
                                <TableCell>
                                <Badge
                                    variant={
                                    district.isActive ? "default" : "secondary"
                                    }
                                >
                                    {district.isActive ? "Hoạt động" : "Ẩn"}
                                </Badge>
                                </TableCell>
                                <TableCell>
                                <div className="flex items-center gap-1">
                                    <Button
                                    variant="ghost"
                                    size="icon"
                                    className="h-8 w-8"
                                    onClick={() => onEditDistrict(district)}
                                    >
                                    <Pencil className="h-3 w-3" />
                                    </Button>
                                    <Button
                                    variant="ghost"
                                    size="icon"
                                    className="h-8 w-8"
                                    onClick={() => onDeleteDistrict(district)}
                                    >
                                    <Trash2 className="h-3 w-3 text-destructive" />
                                    </Button>
                                </div>
                                </TableCell>
                            </TableRow>
                            ))
                        )}
                    </TableBody>
                    </Table>
                )}
            </div>
            </CollapsibleContent>
        </Collapsible>
    );
}
