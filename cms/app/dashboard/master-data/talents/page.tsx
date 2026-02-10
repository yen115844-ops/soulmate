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
import { talentCategoriesApi, talentsApi } from "@/lib/api/master-data";
import { Talent, TalentCategory } from "@/types";

export default function TalentsPage() {
  const queryClient = useQueryClient();
  const [activeTab, setActiveTab] = useState("talents");
  const [isCategoryFormOpen, setIsCategoryFormOpen] = useState(false);
  const [isTalentFormOpen, setIsTalentFormOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState<TalentCategory | null>(null);
  const [editingTalent, setEditingTalent] = useState<Talent | null>(null);
  const [deleteItem, setDeleteItem] = useState<{ type: "category" | "talent"; item: TalentCategory | Talent } | null>(null);

  const [categoryForm, setCategoryForm] = useState({
    code: "",
    name: "",
    displayOrder: 0,
    isActive: true,
  });

  const [talentForm, setTalentForm] = useState({
    categoryId: "",
    name: "",
    icon: "",
    displayOrder: 0,
    isActive: true,
  });

  const { data: categoriesData, isLoading: categoriesLoading } = useQuery({
    queryKey: ["talent-categories"],
    queryFn: () => talentCategoriesApi.getAll(true),
  });

  const { data: talentsData, isLoading: talentsLoading } = useQuery({
    queryKey: ["talents"],
    queryFn: () => talentsApi.getAll(undefined, true),
  });

  const categories = categoriesData?.data || [];
  const talents = talentsData?.data || [];

  // Category mutations
  const createCategoryMutation = useMutation({
    mutationFn: (data: Partial<TalentCategory>) => talentCategoriesApi.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["talent-categories"] });
      toast.success("Đã tạo danh mục");
      setIsCategoryFormOpen(false);
    },
    onError: () => toast.error("Failed to create category"),
  });

  const updateCategoryMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<TalentCategory> }) =>
      talentCategoriesApi.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["talent-categories"] });
      toast.success("Đã cập nhật danh mục");
      setIsCategoryFormOpen(false);
      setEditingCategory(null);
    },
    onError: () => toast.error("Failed to update category"),
  });

  const deleteCategoryMutation = useMutation({
    mutationFn: (id: string) => talentCategoriesApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["talent-categories"] });
      toast.success("Đã xóa danh mục");
      setDeleteItem(null);
    },
    onError: () => toast.error("Failed to delete category"),
  });

  // Talent mutations
  const createTalentMutation = useMutation({
    mutationFn: (data: Partial<Talent>) => talentsApi.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["talents"] });
      toast.success("Đã tạo tài năng");
      setIsTalentFormOpen(false);
    },
    onError: () => toast.error("Failed to create talent"),
  });

  const updateTalentMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<Talent> }) =>
      talentsApi.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["talents"] });
      toast.success("Đã cập nhật tài năng");
      setIsTalentFormOpen(false);
      setEditingTalent(null);
    },
    onError: () => toast.error("Failed to update talent"),
  });

  const deleteTalentMutation = useMutation({
    mutationFn: (id: string) => talentsApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["talents"] });
      toast.success("Đã xóa tài năng");
      setDeleteItem(null);
    },
    onError: () => toast.error("Failed to delete talent"),
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

  const openEditCategory = (category: TalentCategory) => {
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

  // Talent handlers
  const openCreateTalent = () => {
    setEditingTalent(null);
    setTalentForm({
      categoryId: categories[0]?.id || "",
      name: "",
      icon: "",
      displayOrder: talents.length + 1,
      isActive: true,
    });
    setIsTalentFormOpen(true);
  };

  const openEditTalent = (talent: Talent) => {
    setEditingTalent(talent);
    setTalentForm({
      categoryId: talent.categoryId || "",
      name: talent.name,
      icon: talent.icon || "",
      displayOrder: talent.displayOrder,
      isActive: talent.isActive,
    });
    setIsTalentFormOpen(true);
  };

  const handleTalentSubmit = () => {
    if (editingTalent) {
      updateTalentMutation.mutate({
        id: editingTalent.id,
        data: talentForm,
      });
    } else {
      createTalentMutation.mutate(talentForm);
    }
  };

  const handleDelete = () => {
    if (!deleteItem) return;
    if (deleteItem.type === "category") {
      deleteCategoryMutation.mutate(deleteItem.item.id);
    } else {
      deleteTalentMutation.mutate(deleteItem.item.id);
    }
  };

  const getCategoryName = (categoryId: string) => {
    return categories.find((c) => c.id === categoryId)?.name || "Unknown";
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Tài năng</h1>
          <p className="text-muted-foreground">
            Quản lý danh mục và mục tài năng cho đối tác
          </p>
        </div>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList>
          <TabsTrigger value="talents">Tài năng</TabsTrigger>
          <TabsTrigger value="categories">Danh mục</TabsTrigger>
        </TabsList>

        <TabsContent value="talents" className="space-y-4">
          <div className="flex justify-end">
            <Button onClick={openCreateTalent}>
              <Plus className="mr-2 h-4 w-4" />
              Add Talent
            </Button>
          </div>

          <Card>
            <CardContent className="p-0">
              {talentsLoading ? (
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
                      <TableHead>Name</TableHead>
                      <TableHead>Category</TableHead>
                      <TableHead className="w-24">Order</TableHead>
                      <TableHead className="w-24">Status</TableHead>
                      <TableHead className="w-24">Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {talents.map((item) => (
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
                              onClick={() => openEditTalent(item)}
                            >
                              <Pencil className="h-4 w-4" />
                            </Button>
                            <Button
                              variant="ghost"
                              size="icon"
                              onClick={() =>
                                setDeleteItem({ type: "talent", item })
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
                      <TableHead>Code</TableHead>
                      <TableHead>Name</TableHead>
                      <TableHead>Items</TableHead>
                      <TableHead className="w-24">Order</TableHead>
                      <TableHead className="w-24">Status</TableHead>
                      <TableHead className="w-24">Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {categories.map((category) => (
                      <TableRow key={category.id}>
                        <TableCell className="font-mono">{category.code}</TableCell>
                        <TableCell className="font-medium">{category.name}</TableCell>
                        <TableCell>
                          {talents.filter((t) => t.categoryId === category.id).length} items
                        </TableCell>
                        <TableCell>{category.displayOrder}</TableCell>
                        <TableCell>
                          <Badge variant={category.isActive ? "default" : "secondary"}>
                            {category.isActive ? "Active" : "Inactive"}
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
              {editingCategory ? "Edit Category" : "Create Category"}
            </DialogTitle>
          </DialogHeader>

          <div className="space-y-4">
            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label>Code</Label>
                <Input
                  placeholder="e.g., music"
                  value={categoryForm.code}
                  onChange={(e) =>
                    setCategoryForm({ ...categoryForm, code: e.target.value })
                  }
                />
              </div>
              <div className="space-y-2">
                <Label>Name</Label>
                <Input
                  placeholder="e.g., Music"
                  value={categoryForm.name}
                  onChange={(e) =>
                    setCategoryForm({ ...categoryForm, name: e.target.value })
                  }
                />
              </div>
            </div>

            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label>Display Order</Label>
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
                <Label>Active</Label>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button 
              variant="outline" 
              onClick={() => setIsCategoryFormOpen(false)}
              disabled={createCategoryMutation.isPending || updateCategoryMutation.isPending}
            >
              Cancel
            </Button>
            <Button 
              onClick={handleCategorySubmit}
              disabled={createCategoryMutation.isPending || updateCategoryMutation.isPending}
            >
              {(createCategoryMutation.isPending || updateCategoryMutation.isPending) && (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              )}
              {editingCategory ? "Update" : "Create"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Talent Form Dialog */}
      <Dialog open={isTalentFormOpen} onOpenChange={setIsTalentFormOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {editingTalent ? "Edit Talent" : "Create Talent"}
            </DialogTitle>
          </DialogHeader>

          <div className="space-y-4">
            <div className="space-y-2">
              <Label>Category</Label>
              <Select
                value={talentForm.categoryId}
                onValueChange={(value) =>
                  setTalentForm({ ...talentForm, categoryId: value })
                }
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select category" />
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
                  placeholder="e.g., Singing"
                  value={talentForm.name}
                  onChange={(e) =>
                    setTalentForm({ ...talentForm, name: e.target.value })
                  }
                />
              </div>
              <div className="space-y-2">
                <Label>Icon (emoji)</Label>
                <Input
                  placeholder="e.g., 🎤"
                  value={talentForm.icon}
                  onChange={(e) =>
                    setTalentForm({ ...talentForm, icon: e.target.value })
                  }
                />
              </div>
            </div>

            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label>Display Order</Label>
                <Input
                  type="number"
                  value={talentForm.displayOrder}
                  onChange={(e) =>
                    setTalentForm({
                      ...talentForm,
                      displayOrder: parseInt(e.target.value) || 0,
                    })
                  }
                />
              </div>
              <div className="flex items-center gap-2 pt-6">
                <Switch
                  checked={talentForm.isActive}
                  onCheckedChange={(checked) =>
                    setTalentForm({ ...talentForm, isActive: checked })
                  }
                />
                <Label>Active</Label>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button 
              variant="outline" 
              onClick={() => setIsTalentFormOpen(false)}
              disabled={createTalentMutation.isPending || updateTalentMutation.isPending}
            >
              Cancel
            </Button>
            <Button 
              onClick={handleTalentSubmit}
              disabled={createTalentMutation.isPending || updateTalentMutation.isPending}
            >
              {(createTalentMutation.isPending || updateTalentMutation.isPending) && (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              )}
              {editingTalent ? "Update" : "Create"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <AlertDialog open={!!deleteItem} onOpenChange={() => setDeleteItem(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>
              Xóa {deleteItem?.type === "category" ? "danh mục" : "tài năng"}
            </AlertDialogTitle>
            <AlertDialogDescription>
              Bạn có chắc muốn xóa &quot;{(deleteItem?.item as TalentCategory | Talent)?.name}&quot;?
              {deleteItem?.type === "category" &&
                " Điều này sẽ xóa tất cả tài năng trong danh mục này."}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={deleteCategoryMutation.isPending || deleteTalentMutation.isPending}>
              Hủy
            </AlertDialogCancel>
            <AlertDialogAction 
              onClick={handleDelete}
              disabled={deleteCategoryMutation.isPending || deleteTalentMutation.isPending}
            >
              {(deleteCategoryMutation.isPending || deleteTalentMutation.isPending) && (
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
