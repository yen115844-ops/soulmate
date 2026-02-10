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
  const [expandedProvinces, setExpandedProvinces] = useState<string[]>([]);
  const [isProvinceFormOpen, setIsProvinceFormOpen] = useState(false);
  const [isDistrictFormOpen, setIsDistrictFormOpen] = useState(false);
  const [editingProvince, setEditingProvince] = useState<Province | null>(null);
  const [editingDistrict, setEditingDistrict] = useState<District | null>(null);
  const [selectedProvinceId, setSelectedProvinceId] = useState<string | null>(null);
  const [deleteItem, setDeleteItem] = useState<{ type: "province" | "district"; item: Province | District } | null>(null);

  const [provinceForm, setProvinceForm] = useState({
    code: "",
    name: "",
    displayOrder: 0,
    isActive: true,
  });

  const [districtForm, setDistrictForm] = useState({
    provinceId: "",
    code: "",
    name: "",
    displayOrder: 0,
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
      queryClient.invalidateQueries({ queryKey: ["provinces"] });
      toast.success("Đã cập nhật quận/huyện");
      setIsDistrictFormOpen(false);
      setEditingDistrict(null);
    },
    onError: () => toast.error("Failed to update district"),
  });

  const deleteDistrictMutation = useMutation({
    mutationFn: (id: string) => districtsApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["provinces"] });
      toast.success("Đã xóa quận/huyện");
      setDeleteItem(null);
    },
    onError: () => toast.error("Failed to delete district"),
  });

  const toggleProvince = (id: string) => {
    setExpandedProvinces((prev) =>
      prev.includes(id) ? prev.filter((p) => p !== id) : [...prev, id]
    );
  };

  // Province handlers
  const openCreateProvince = () => {
    setEditingProvince(null);
    setProvinceForm({
      code: "",
      name: "",
      displayOrder: provinces.length + 1,
      isActive: true,
    });
    setIsProvinceFormOpen(true);
  };

  const openEditProvince = (province: Province) => {
    setEditingProvince(province);
    setProvinceForm({
      code: province.code,
      name: province.name,
      displayOrder: province.displayOrder,
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
    const province = provinces.find((p) => p.id === provinceId);
    setDistrictForm({
      provinceId,
      code: "",
      name: "",
      displayOrder: (province?.districts?.length || 0) + 1,
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
      displayOrder: district.displayOrder,
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
                <Collapsible
                  key={province.id}
                  open={expandedProvinces.includes(province.id)}
                  onOpenChange={() => toggleProvince(province.id)}
                >
                  <div className="flex items-center justify-between p-4 hover:bg-muted/50">
                    <CollapsibleTrigger className="flex flex-1 items-center gap-3">
                      <ChevronRight
                        className={`h-4 w-4 transition-transform ${
                          expandedProvinces.includes(province.id)
                            ? "rotate-90"
                            : ""
                        }`}
                      />
                      <MapPin className="h-4 w-4 text-muted-foreground" />
                      <div className="text-left">
                        <p className="font-medium">{province.name}</p>
                        <p className="text-sm text-muted-foreground">
                          {province.code} • {province.districts?.length || 0} districts
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
                          openEditProvince(province);
                        }}
                      >
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={(e) => {
                          e.stopPropagation();
                          setDeleteItem({ type: "province", item: province });
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
                          onClick={() => openCreateDistrict(province.id)}
                        >
                          <Plus className="mr-1 h-3 w-3" />
                          Thêm quận/huyện
                        </Button>
                      </div>
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
                          {province.districts?.map((district) => (
                            <TableRow key={district.id}>
                              <TableCell className="font-mono">
                                {district.code}
                              </TableCell>
                              <TableCell>{district.name}</TableCell>
                              <TableCell>{district.displayOrder}</TableCell>
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
                                    onClick={() => openEditDistrict(district)}
                                  >
                                    <Pencil className="h-3 w-3" />
                                  </Button>
                                  <Button
                                    variant="ghost"
                                    size="icon"
                                    className="h-8 w-8"
                                    onClick={() =>
                                      setDeleteItem({
                                        type: "district",
                                        item: district,
                                      })
                                    }
                                  >
                                    <Trash2 className="h-3 w-3 text-destructive" />
                                  </Button>
                                </div>
                              </TableCell>
                            </TableRow>
                          ))}
                        </TableBody>
                      </Table>
                    </div>
                  </CollapsibleContent>
                </Collapsible>
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
                  placeholder="e.g., Ho Chi Minh City"
                  value={provinceForm.name}
                  onChange={(e) =>
                    setProvinceForm({ ...provinceForm, name: e.target.value })
                  }
                />
              </div>
            </div>

            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label>Display Order</Label>
                <Input
                  type="number"
                  value={provinceForm.displayOrder}
                  onChange={(e) =>
                    setProvinceForm({
                      ...provinceForm,
                      displayOrder: parseInt(e.target.value) || 0,
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
                  placeholder="e.g., District 1"
                  value={districtForm.name}
                  onChange={(e) =>
                    setDistrictForm({ ...districtForm, name: e.target.value })
                  }
                />
              </div>
            </div>

            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label>Display Order</Label>
                <Input
                  type="number"
                  value={districtForm.displayOrder}
                  onChange={(e) =>
                    setDistrictForm({
                      ...districtForm,
                      displayOrder: parseInt(e.target.value) || 0,
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
