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
    DialogFooter,
    DialogHeader,
    DialogTitle,
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
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { interestCategoriesApi, interestsApi } from "@/lib/api/master-data";
import { Interest, InterestCategory } from "@/types";

export default function InterestsPage() {
  const queryClient = useQueryClient();
  const [activeTab, setActiveTab] = useState("interests");
  const [isCategoryFormOpen, setIsCategoryFormOpen] = useState(false);
  const [isInterestFormOpen, setIsInterestFormOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState<InterestCategory | null>(null);
  const [editingInterest, setEditingInterest] = useState<Interest | null>(null);
  const [deleteItem, setDeleteItem] = useState<{ type: "category" | "interest"; item: InterestCategory | Interest } | null>(null);

  const [categoryForm, setCategoryForm] = useState({
    code: "",
    name: "",
    displayOrder: 0,
    isActive: true,
  });

  const [interestForm, setInterestForm] = useState({
    categoryId: "",
    name: "",
    icon: "",
    displayOrder: 0,
    isActive: true,
  });

  const { data: categoriesData, isLoading: categoriesLoading } = useQuery({
    queryKey: ["interest-categories"],
    queryFn: () => interestCategoriesApi.getAll(true),
  });

  const { data: interestsData, isLoading: interestsLoading } = useQuery({
    queryKey: ["interests"],
    queryFn: () => interestsApi.getAll(undefined, true),
  });

  const categories = categoriesData?.data || [];
  const interests = interestsData?.data || [];

  // Category mutations
  const createCategoryMutation = useMutation({
    mutationFn: (data: Partial<InterestCategory>) => interestCategoriesApi.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["interest-categories"] });
      toast.success("Đã tạo danh mục");
      setIsCategoryFormOpen(false);
    },
    onError: () => toast.error("Tạo danh mục thất bại"),
  });

  const updateCategoryMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<InterestCategory> }) =>
      interestCategoriesApi.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["interest-categories"] });
      toast.success("Đã cập nhật danh mục");
      setIsCategoryFormOpen(false);
      setEditingCategory(null);
    },
    onError: () => toast.error("Cập nhật danh mục thất bại"),
  });

  const deleteCategoryMutation = useMutation({
    mutationFn: (id: string) => interestCategoriesApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["interest-categories"] });
      toast.success("Đã xóa danh mục");
      setDeleteItem(null);
    },
    onError: () => toast.error("Xóa danh mục thất bại"),
  });

  // Interest mutations
  const createInterestMutation = useMutation({
    mutationFn: (data: Partial<Interest>) => interestsApi.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["interests"] });
      toast.success("Đã tạo sở thích");
      setIsInterestFormOpen(false);
    },
    onError: () => toast.error("Tạo sở thích thất bại"),
  });

  const updateInterestMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<Interest> }) =>
      interestsApi.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["interests"] });
      toast.success("Đã cập nhật sở thích");
      setIsInterestFormOpen(false);
      setEditingInterest(null);
    },
    onError: () => toast.error("Cập nhật sở thích thất bại"),
  });

  const deleteInterestMutation = useMutation({
    mutationFn: (id: string) => interestsApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["interests"] });
      toast.success("Đã xóa sở thích");
      setDeleteItem(null);
    },
    onError: () => toast.error("Xóa sở thích thất bại"),
  });

  // Category handlers
  const openCreateCategory = () => {
    setEditingCategory(null);
    setCategoryForm({
      code: "",
      name: "",
      displayOrder: categories.length + 1,
      isActive: true,
    });
    setIsCategoryFormOpen(true);
  };

  const openEditCategory = (category: InterestCategory) => {
    setEditingCategory(category);
    setCategoryForm({
      code: category.code,
      name: category.name,
      displayOrder: category.displayOrder,
      isActive: category.isActive,
    });
    setIsCategoryFormOpen(true);
  };

  const handleCategorySubmit = () => {
    if (editingCategory) {
      updateCategoryMutation.mutate({
        id: editingCategory.id,
        data: categoryForm,
      });
    } else {
      createCategoryMutation.mutate(categoryForm);
    }
  };

  // Interest handlers
  const openCreateInterest = () => {
    setEditingInterest(null);
    setInterestForm({
      categoryId: categories[0]?.id || "",
      name: "",
      icon: "",
      displayOrder: interests.length + 1,
      isActive: true,
    });
    setIsInterestFormOpen(true);
  };

  const openEditInterest = (interest: Interest) => {
    setEditingInterest(interest);
    setInterestForm({
      categoryId: interest.categoryId || "",
      name: interest.name,
      icon: interest.icon || "",
      displayOrder: interest.displayOrder,
      isActive: interest.isActive,
    });
    setIsInterestFormOpen(true);
  };

  const handleInterestSubmit = () => {
    if (editingInterest) {
      updateInterestMutation.mutate({
        id: editingInterest.id,
        data: interestForm,
      });
    } else {
      createInterestMutation.mutate(interestForm);
    }
  };

  const handleDelete = () => {
    if (!deleteItem) return;
    if (deleteItem.type === "category") {
      deleteCategoryMutation.mutate(deleteItem.item.id);
    } else {
      deleteInterestMutation.mutate(deleteItem.item.id);
    }
  };

  const getCategoryName = (categoryId: string) => {
    return categories.find((c) => c.id === categoryId)?.name || "Unknown";
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Sở thích</h1>
          <p className="text-muted-foreground">
            Quản lý danh mục và mục sở thích
          </p>
        </div>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList>
          <TabsTrigger value="interests">Sở thích</TabsTrigger>
          <TabsTrigger value="categories">Danh mục</TabsTrigger>
        </TabsList>

        <TabsContent value="interests" className="space-y-4">
          <div className="flex justify-end">
            <Button onClick={openCreateInterest}>
              <Plus className="mr-2 h-4 w-4" />
              Thêm sở thích
            </Button>
          </div>

          <Card>
            <CardContent className="p-0">
              {interestsLoading ? (
                <div className="space-y-4 p-6">
                  {Array.from({ length: 5 }).map((_, i) => (
                    <Skeleton key={i} className="h-12 w-full" />
                  ))}
                </div>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead className="w-16">Biểu tượng</TableHead>
                      <TableHead>Tên</TableHead>
                      <TableHead>Danh mục</TableHead>
                      <TableHead className="w-24">Thứ tự</TableHead>
                      <TableHead className="w-24">Trạng thái</TableHead>
                      <TableHead className="w-24">Thao tác</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {interests.map((item) => (
                      <TableRow key={item.id}>
                        <TableCell className="text-2xl">{item.icon}</TableCell>
                        <TableCell className="font-medium">{item.name}</TableCell>
                        <TableCell>
                          <Badge variant="outline">
                            {getCategoryName(item.categoryId || "")}
                          </Badge>
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
                              onClick={() => openEditInterest(item)}
                            >
                              <Pencil className="h-4 w-4" />
                            </Button>
                            <Button
                              variant="ghost"
                              size="icon"
                              onClick={() =>
                                setDeleteItem({ type: "interest", item })
                              }
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
        </TabsContent>

        <TabsContent value="categories" className="space-y-4">
          <div className="flex justify-end">
            <Button onClick={openCreateCategory}>
              <Plus className="mr-2 h-4 w-4" />
              Thêm danh mục
            </Button>
          </div>

          <Card>
            <CardContent className="p-0">
              {categoriesLoading ? (
                <div className="space-y-4 p-6">
                  {Array.from({ length: 3 }).map((_, i) => (
                    <Skeleton key={i} className="h-12 w-full" />
                  ))}
                </div>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Mã</TableHead>
                      <TableHead>Tên</TableHead>
                      <TableHead>Mục</TableHead>
                      <TableHead className="w-24">Thứ tự</TableHead>
                      <TableHead className="w-24">Trạng thái</TableHead>
                      <TableHead className="w-24">Thao tác</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {categories.map((category) => (
                      <TableRow key={category.id}>
                        <TableCell className="font-mono">{category.code}</TableCell>
                        <TableCell className="font-medium">{category.name}</TableCell>
                        <TableCell>
                          {interests.filter((i) => i.categoryId === category.id).length} items
                        </TableCell>
                        <TableCell>{category.displayOrder}</TableCell>
                        <TableCell>
                          <Badge variant={category.isActive ? "default" : "secondary"}>
                            {category.isActive ? "Hoạt động" : "Ẩn"}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center gap-2">
                            <Button
                              variant="ghost"
                              size="icon"
                              onClick={() => openEditCategory(category)}
                            >
                              <Pencil className="h-4 w-4" />
                            </Button>
                            <Button
                              variant="ghost"
                              size="icon"
                              onClick={() =>
                                setDeleteItem({ type: "category", item: category })
                              }
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
        </TabsContent>
      </Tabs>

      {/* Category Form Dialog */}
      <Dialog open={isCategoryFormOpen} onOpenChange={setIsCategoryFormOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {editingCategory ? "Sửa danh mục" : "Tạo danh mục"}
            </DialogTitle>
          </DialogHeader>

          <div className="space-y-4">
            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label>Code</Label>
                <Input
                  placeholder="e.g., entertainment"
                  value={categoryForm.code}
                  onChange={(e) =>
                    setCategoryForm({ ...categoryForm, code: e.target.value })
                  }
                />
              </div>
              <div className="space-y-2">
                <Label>Name</Label>
                <Input
                  placeholder="e.g., Entertainment"
                  value={categoryForm.name}
                  onChange={(e) =>
                    setCategoryForm({ ...categoryForm, name: e.target.value })
                  }
                />
              </div>
            </div>

            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label>Thứ tự hiển thị</Label>
                <Input
                  type="number"
                  value={categoryForm.displayOrder}
                  onChange={(e) =>
                    setCategoryForm({
                      ...categoryForm,
                      displayOrder: parseInt(e.target.value) || 0,
                    })
                  }
                />
              </div>
              <div className="flex items-center gap-2 pt-6">
                <Switch
                  checked={categoryForm.isActive}
                  onCheckedChange={(checked) =>
                    setCategoryForm({ ...categoryForm, isActive: checked })
                  }
                />
                <Label>Hoạt động</Label>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button 
              variant="outline" 
              onClick={() => setIsCategoryFormOpen(false)}
              disabled={createCategoryMutation.isPending || updateCategoryMutation.isPending}
            >
              Hủy
            </Button>
            <Button 
              onClick={handleCategorySubmit}
              disabled={createCategoryMutation.isPending || updateCategoryMutation.isPending}
            >
              {(createCategoryMutation.isPending || updateCategoryMutation.isPending) && (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              )}
              {editingCategory ? "Cập nhật" : "Tạo"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Interest Form Dialog */}
      <Dialog open={isInterestFormOpen} onOpenChange={setIsInterestFormOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {editingInterest ? "Sửa sở thích" : "Tạo sở thích"}
            </DialogTitle>
          </DialogHeader>

          <div className="space-y-4">
            <div className="space-y-2">
              <Label>Danh mục</Label>
              <Select
                value={interestForm.categoryId}
                onValueChange={(value) =>
                  setInterestForm({ ...interestForm, categoryId: value })
                }
              >
                <SelectTrigger>
                  <SelectValue placeholder="Chọn danh mục" />
                </SelectTrigger>
                <SelectContent>
                  {categories.map((c) => (
                    <SelectItem key={c.id} value={c.id}>
                      {c.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label>Name</Label>
                <Input
                  placeholder="e.g., Movies"
                  value={interestForm.name}
                  onChange={(e) =>
                    setInterestForm({ ...interestForm, name: e.target.value })
                  }
                />
              </div>
              <div className="space-y-2">
                <Label>Icon (emoji)</Label>
                <Input
                  placeholder="e.g., 🎬"
                  value={interestForm.icon}
                  onChange={(e) =>
                    setInterestForm({ ...interestForm, icon: e.target.value })
                  }
                />
              </div>
            </div>

            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label>Thứ tự hiển thị</Label>
                <Input
                  type="number"
                  value={interestForm.displayOrder}
                  onChange={(e) =>
                    setInterestForm({
                      ...interestForm,
                      displayOrder: parseInt(e.target.value) || 0,
                    })
                  }
                />
              </div>
              <div className="flex items-center gap-2 pt-6">
                <Switch
                  checked={interestForm.isActive}
                  onCheckedChange={(checked) =>
                    setInterestForm({ ...interestForm, isActive: checked })
                  }
                />
                <Label>Hoạt động</Label>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button 
              variant="outline" 
              onClick={() => setIsInterestFormOpen(false)}
              disabled={createInterestMutation.isPending || updateInterestMutation.isPending}
            >
              Hủy
            </Button>
            <Button 
              onClick={handleInterestSubmit}
              disabled={createInterestMutation.isPending || updateInterestMutation.isPending}
            >
              {(createInterestMutation.isPending || updateInterestMutation.isPending) && (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              )}
              {editingInterest ? "Cập nhật" : "Tạo"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <AlertDialog open={!!deleteItem} onOpenChange={() => setDeleteItem(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>
              Xóa {deleteItem?.type === "category" ? "danh mục" : "sở thích"}
            </AlertDialogTitle>
            <AlertDialogDescription>
              Bạn có chắc muốn xóa &quot;{(deleteItem?.item as InterestCategory | Interest)?.name}&quot;?
              {deleteItem?.type === "category" &&
                " Điều này sẽ xóa tất cả sở thích trong danh mục này."}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={deleteCategoryMutation.isPending || deleteInterestMutation.isPending}>
              Hủy
            </AlertDialogCancel>
            <AlertDialogAction 
              onClick={handleDelete}
              disabled={deleteCategoryMutation.isPending || deleteInterestMutation.isPending}
            >
              {(deleteCategoryMutation.isPending || deleteInterestMutation.isPending) && (
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
