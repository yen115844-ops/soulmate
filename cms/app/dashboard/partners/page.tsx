"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
    ColumnDef,
    SortingState,
    flexRender,
    getCoreRowModel,
    getSortedRowModel,
    useReactTable,
} from "@tanstack/react-table";
import { format } from "date-fns";
import {
    ArrowUpDown,
    Ban,
    CheckCircle,
    Eye,
    Loader2,
    MoreHorizontal,
    Search,
    Star,
    XCircle,
} from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
} from "@/components/ui/dialog";
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuLabel,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Input } from "@/components/ui/input";
import { Pagination } from "@/components/ui/pagination";
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from "@/components/ui/table";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { GetPartnersParams, partnersApi } from "@/lib/api/partners";
import { extractPaginatedData } from "@/lib/utils";
import { PartnerProfile, User, UserStatus } from "@/types";

interface PartnerWithUser extends PartnerProfile {
  user: User;
}

// Status badge component
function StatusBadge({ status }: { status: UserStatus | undefined }) {
  const variants: Record<UserStatus, { variant: "default" | "secondary" | "destructive" | "outline"; label: string }> = {
    [UserStatus.ACTIVE]: { variant: "default", label: "Hoạt động" },
    [UserStatus.PENDING]: { variant: "secondary", label: "Chờ duyệt" },
    [UserStatus.SUSPENDED]: { variant: "outline", label: "Tạm khóa" },
    [UserStatus.BANNED]: { variant: "destructive", label: "Cấm" },
  };

  const config = status ? variants[status] : null;
  const { variant, label } = config || { variant: "secondary" as const, label: status || "Chưa rõ" };

  return <Badge variant={variant}>{label}</Badge>;
}

export default function PartnersPage() {
  const queryClient = useQueryClient();
  const [sorting, setSorting] = useState<SortingState>([]);
  const [globalFilter, setGlobalFilter] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [availableFilter, setAvailableFilter] = useState<string>("all");
  const [page, setPage] = useState(1);
  const [limit] = useState(10);
  const [selectedPartner, setSelectedPartner] = useState<PartnerWithUser | null>(null);
  const [actionDialog, setActionDialog] = useState<{
    open: boolean;
    action: "activate" | "suspend" | "ban" | null;
  }>({ open: false, action: null });

  // Build query params
  const queryParams: GetPartnersParams = {
    page,
    limit,
    ...(statusFilter !== "all" && { status: statusFilter as UserStatus }),
    ...(availableFilter !== "all" && { isAvailable: availableFilter === "available" }),
    ...(globalFilter && { search: globalFilter }),
  };

  // Fetch partners from API
  const { data: partnersData, isLoading } = useQuery({
    queryKey: ["partners", queryParams],
    queryFn: () => partnersApi.getPartners(queryParams),
  });

  // Fetch partner stats
  const { data: stats, isLoading: statsLoading } = useQuery({
    queryKey: ["partner-stats"],
    queryFn: () => partnersApi.getPartnerStats(),
  });

  // Update partner status mutation
  const updateStatusMutation = useMutation({
    mutationFn: async ({ id, status }: { id: string; status: UserStatus }) => {
      return partnersApi.updatePartnerStatus(id, { status });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["partners"] });
      queryClient.invalidateQueries({ queryKey: ["partner-stats"] });
      toast.success("Cập nhật trạng thái đối tác thành công");
      setActionDialog({ open: false, action: null });
      setSelectedPartner(null);
    },
    onError: () => {
      toast.error("Cập nhật trạng thái thất bại");
    },
  });

  const columns: ColumnDef<PartnerWithUser>[] = [
    {
      accessorKey: "user.profile.fullName",
      header: ({ column }) => (
        <Button
          variant="ghost"
          onClick={() => column.toggleSorting(column.getIsSorted() === "asc")}
        >
          Đối tác
          <ArrowUpDown className="ml-2 h-4 w-4" />
        </Button>
      ),
      cell: ({ row }) => {
        const partner = row.original;
        return (
          <div className="flex items-center gap-3">
            <Avatar>
              <AvatarImage src={partner.user.profile?.avatarUrl} />
              <AvatarFallback>
                {partner.user.profile?.fullName?.charAt(0) || "P"}
              </AvatarFallback>
            </Avatar>
            <div>
              <div className="flex items-center gap-2">
                <p className="font-medium">{partner.user.profile?.fullName}</p>
                {partner.isVerified && (
                  <Badge variant="default" className="h-5 px-1.5">
                    <CheckCircle className="mr-1 h-3 w-3" />
                    {partner.verificationBadge}
                  </Badge>
                )}
              </div>
              <p className="text-sm text-muted-foreground">{partner.user.email}</p>
            </div>
          </div>
        );
      },
    },
    {
      accessorKey: "serviceTypes",
      header: "Dịch vụ",
      cell: ({ row }) => {
        const services = row.getValue("serviceTypes") as string[];
        return (
          <div className="flex flex-wrap gap-1">
            {services.slice(0, 2).map((s) => (
              <Badge key={s} variant="secondary" className="text-xs">
                {s}
              </Badge>
            ))}
            {services.length > 2 && (
              <Badge variant="outline" className="text-xs">
                +{services.length - 2}
              </Badge>
            )}
          </div>
        );
      },
    },
    {
      accessorKey: "hourlyRate",
      header: ({ column }) => (
        <Button
          variant="ghost"
          onClick={() => column.toggleSorting(column.getIsSorted() === "asc")}
        >
          Giá/giờ
          <ArrowUpDown className="ml-2 h-4 w-4" />
        </Button>
      ),
      cell: ({ row }) => {
        const rate = row.getValue("hourlyRate") as number;
        return new Intl.NumberFormat("vi-VN", {
          style: "currency",
          currency: "VND",
        }).format(rate);
      },
    },
    {
      accessorKey: "averageRating",
      header: "Đánh giá",
      cell: ({ row }) => {
        const ratingValue = row.getValue("averageRating");
        const rating = typeof ratingValue === 'string' ? parseFloat(ratingValue) : (ratingValue as number) || 0;
        const reviews = row.original.totalReviews;
        return (
          <div className="flex items-center gap-1">
            <Star className="h-4 w-4 fill-yellow-400 text-yellow-400" />
            <span>{rating.toFixed(1)}</span>
            <span className="text-muted-foreground">({reviews})</span>
          </div>
        );
      },
    },
    {
      accessorKey: "completedBookings",
      header: "Bookings",
      cell: ({ row }) => {
        const completed = row.original.completedBookings;
        const total = row.original.totalBookings;
        return (
          <div>
            <p className="font-medium">{completed}</p>
            <p className="text-xs text-muted-foreground">/ {total} tổng</p>
          </div>
        );
      },
    },
    {
      accessorKey: "isAvailable",
      header: "Sẵn sàng",
      cell: ({ row }) => {
        const available = row.getValue("isAvailable") as boolean;
        return (
          <Badge variant={available ? "default" : "secondary"}>
            {available ? "Sẵn sàng" : "Ngoại tuyến"}
          </Badge>
        );
      },
    },
    {
      id: "status",
      header: "Trạng thái",
      cell: ({ row }) => {
        const status = row.original.user?.status;
        return <StatusBadge status={status} />;
      },
    },
    {
      id: "actions",
      cell: ({ row }) => {
        const partner = row.original;
        return (
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" className="h-8 w-8 p-0">
                <MoreHorizontal className="h-4 w-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuLabel>Thao tác</DropdownMenuLabel>
              <DropdownMenuItem onClick={() => setSelectedPartner(partner)}>
                <Eye className="mr-2 h-4 w-4" />
                Xem chi tiết
              </DropdownMenuItem>
              <DropdownMenuSeparator />
              {partner.user?.status !== UserStatus.ACTIVE && (
                <DropdownMenuItem
                  onClick={() => {
                    setSelectedPartner(partner);
                    setActionDialog({ open: true, action: "activate" });
                  }}
                >
                  <CheckCircle className="mr-2 h-4 w-4" />
                  Kích hoạt
                </DropdownMenuItem>
              )}
              {partner.user?.status !== UserStatus.SUSPENDED && (
                <DropdownMenuItem
                  onClick={() => {
                    setSelectedPartner(partner);
                    setActionDialog({ open: true, action: "suspend" });
                  }}
                >
                  <XCircle className="mr-2 h-4 w-4" />
                  Tạm khóa
                </DropdownMenuItem>
              )}
              {partner.user?.status !== UserStatus.BANNED && (
                <DropdownMenuItem
                  onClick={() => {
                    setSelectedPartner(partner);
                    setActionDialog({ open: true, action: "ban" });
                  }}
                  className="text-destructive"
                >
                  <Ban className="mr-2 h-4 w-4" />
                  Cấm đối tác
                </DropdownMenuItem>
              )}
            </DropdownMenuContent>
          </DropdownMenu>
        );
      },
    },
  ];

  const { data: partners, meta } = extractPaginatedData(partnersData);

  const table = useReactTable({
    data: partners,
    columns,
    onSortingChange: setSorting,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
    manualPagination: true,
    pageCount: meta?.totalPages || 0,
    state: { sorting },
  });

  const handleStatusAction = () => {
    if (!selectedPartner || !actionDialog.action) return;

    const statusMap = {
      activate: UserStatus.ACTIVE,
      suspend: UserStatus.SUSPENDED,
      ban: UserStatus.BANNED,
    };

    updateStatusMutation.mutate({
      id: selectedPartner.id,
      status: statusMap[actionDialog.action],
    });
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Quản lý đối tác</h1>
        <p className="text-muted-foreground">
          Quản lý và xác minh đối tác trên nền tảng
        </p>
      </div>

      {/* Stats */}
      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Tổng đối tác
            </CardTitle>
          </CardHeader>
          <CardContent>
            {statsLoading ? (
              <Skeleton className="h-8 w-16" />
            ) : (
              <div className="text-2xl font-bold">{stats?.total || 0}</div>
            )}
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Hoạt động
            </CardTitle>
          </CardHeader>
          <CardContent>
            {statsLoading ? (
              <Skeleton className="h-8 w-16" />
            ) : (
              <div className="text-2xl font-bold text-green-600">
                {stats?.active || 0}
              </div>
            )}
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Sẵn sàng hiện tại
            </CardTitle>
          </CardHeader>
          <CardContent>
            {statsLoading ? (
              <Skeleton className="h-8 w-16" />
            ) : (
              <div className="text-2xl font-bold text-blue-600">
                {stats?.available || 0}
              </div>
            )}
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Điểm TB
            </CardTitle>
          </CardHeader>
          <CardContent>
            {statsLoading ? (
              <Skeleton className="h-8 w-16" />
            ) : (
              <div className="flex items-center gap-1 text-2xl font-bold">
                <Star className="h-5 w-5 fill-yellow-400 text-yellow-400" />
                {parseFloat(String(stats?.averageRating || 0)).toFixed(1)}
              </div>
            )}
          </CardContent>
        </Card>
         
      </div>

      {/* Filters */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center">
        <div className="relative flex-1 md:max-w-sm">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Tìm đối tác..."
            value={globalFilter}
            onChange={(e) => setGlobalFilter(e.target.value)}
            className="pl-9"
          />
        </div>
        <Select value={statusFilter} onValueChange={setStatusFilter}>
          <SelectTrigger className="w-[150px]">
            <SelectValue placeholder="Trạng thái" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Tất cả trạng thái</SelectItem>
            <SelectItem value={UserStatus.ACTIVE}>Hoạt động</SelectItem>
            <SelectItem value={UserStatus.PENDING}>Chờ duyệt</SelectItem>
            <SelectItem value={UserStatus.SUSPENDED}>Tạm khóa</SelectItem>
            <SelectItem value={UserStatus.BANNED}>Bị cấm</SelectItem>
          </SelectContent>
        </Select>
        <Select value={availableFilter} onValueChange={setAvailableFilter}>
          <SelectTrigger className="w-[150px]">
            <SelectValue placeholder="Sẵn sàng" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Tất cả</SelectItem>
            <SelectItem value="available">Sẵn sàng</SelectItem>
            <SelectItem value="offline">Ngoại tuyến</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {/* Table */}
      <Card>
        <CardContent className="p-0">
          {isLoading ? (
            <div className="space-y-4 p-6">
              {Array.from({ length: 5 }).map((_, i) => (
                <Skeleton key={i} className="h-16 w-full" />
              ))}
            </div>
          ) : (
            <>
              <Table>
                <TableHeader>
                  {table.getHeaderGroups().map((headerGroup) => (
                    <TableRow key={headerGroup.id}>
                      {headerGroup.headers.map((header) => (
                        <TableHead key={header.id}>
                          {header.isPlaceholder
                            ? null
                            : flexRender(
                                header.column.columnDef.header,
                                header.getContext()
                              )}
                        </TableHead>
                      ))}
                    </TableRow>
                  ))}
                </TableHeader>
                <TableBody>
                  {table.getRowModel().rows?.length ? (
                    table.getRowModel().rows.map((row) => (
                      <TableRow key={row.id}>
                        {row.getVisibleCells().map((cell) => (
                          <TableCell key={cell.id}>
                            {flexRender(
                              cell.column.columnDef.cell,
                              cell.getContext()
                            )}
                          </TableCell>
                        ))}
                      </TableRow>
                    ))
                  ) : (
                    <TableRow>
                      <TableCell
                        colSpan={columns.length}
                        className="h-24 text-center"
                      >
                        Không tìm thấy đối tác.
                      </TableCell>
                    </TableRow>
                  )}
                </TableBody>
              </Table>

              <Pagination
                page={page}
                totalPages={meta?.totalPages || 1}
                total={meta?.total || 0}
                itemLabel="đối tác"
                onPageChange={setPage}
              />
            </>
          )}
        </CardContent>
      </Card>

      {/* Action Confirmation Dialog */}
      <Dialog
        open={actionDialog.open}
        onOpenChange={(open) => setActionDialog({ open, action: null })}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {actionDialog.action === "activate" && "Kích hoạt đối tác"}
              {actionDialog.action === "suspend" && "Tạm khóa đối tác"}
              {actionDialog.action === "ban" && "Cấm đối tác"}
            </DialogTitle>
            <DialogDescription>
              {actionDialog.action === "activate" &&
                "Đối tác sẽ được kích hoạt và có thể nhận đặt chỗ."}
              {actionDialog.action === "suspend" &&
                "Tài khoản đối tác sẽ bị tạm khóa."}
              {actionDialog.action === "ban" &&
                "Đối tác sẽ bị cấm vĩnh viễn khỏi nền tảng. Thao tác này cần cẩn trọng."}
            </DialogDescription>
          </DialogHeader>
          <div className="py-4">
            <p>
              Bạn có chắc muốn {actionDialog.action === "activate" ? "kích hoạt" : actionDialog.action === "suspend" ? "tạm khóa" : "cấm"}{" "}
              <strong>{selectedPartner?.user.profile?.fullName || selectedPartner?.user.email}</strong>?
            </p>
          </div>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setActionDialog({ open: false, action: null })}
            >
              Hủy
            </Button>
            <Button
              variant={actionDialog.action === "ban" ? "destructive" : "default"}
              onClick={handleStatusAction}
              disabled={updateStatusMutation.isPending}
            >
              {updateStatusMutation.isPending && (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              )}
              Xác nhận
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Partner Detail Dialog */}
      <Dialog
        open={!!selectedPartner && !actionDialog.open}
        onOpenChange={(open) => !open && setSelectedPartner(null)}
      >
        <DialogContent className="max-w-3xl">
          <DialogHeader>
            <DialogTitle>Chi tiết đối tác</DialogTitle>
          </DialogHeader>
          {selectedPartner && (
            <Tabs defaultValue="profile" className="w-full">
              <TabsList className="grid w-full grid-cols-3">
                <TabsTrigger value="profile">Hồ sơ</TabsTrigger>
                <TabsTrigger value="stats">Thống kê</TabsTrigger>
                <TabsTrigger value="services">Dịch vụ</TabsTrigger>
              </TabsList>

              <TabsContent value="profile" className="space-y-4">
                <div className="flex items-center gap-4">
                  <Avatar className="h-20 w-20">
                    <AvatarImage src={selectedPartner.user.profile?.avatarUrl} />
                    <AvatarFallback className="text-xl">
                      {selectedPartner.user.profile?.fullName?.charAt(0)}
                    </AvatarFallback>
                  </Avatar>
                  <div>
                    <div className="flex items-center gap-2">
                      <h3 className="text-xl font-semibold">
                        {selectedPartner.user.profile?.fullName}
                      </h3>
                      {selectedPartner.isVerified && (
                        <Badge>
                          <CheckCircle className="mr-1 h-3 w-3" />
                          {selectedPartner.verificationBadge}
                        </Badge>
                      )}
                    </div>
                    <p className="text-muted-foreground">{selectedPartner.user.email}</p>
                    <div className="mt-1 flex items-center gap-1">
                      <Star className="h-4 w-4 fill-yellow-400 text-yellow-400" />
                      <span>{parseFloat(String(selectedPartner.averageRating || 0)).toFixed(1)}</span>
                      <span className="text-muted-foreground">
                        ({selectedPartner.totalReviews} đánh giá)
                      </span>
                    </div>
                  </div>
                </div>

                <div className="grid gap-4 md:grid-cols-2">
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">Số điện thoại</p>
                    <p>{selectedPartner.user.phone}</p>
                  </div>
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">Giới tính</p>
                    <p>{selectedPartner.user.profile?.gender}</p>
                  </div>
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">Địa điểm</p>
                    <p>{selectedPartner.user.profile?.city}</p>
                  </div>
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">Kinh nghiệm</p>
                    <p>{selectedPartner.experienceYears} năm</p>
                  </div>
                </div>

                {selectedPartner.introduction && (
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">Giới thiệu</p>
                    <p className="mt-1">{selectedPartner.introduction}</p>
                  </div>
                )}
              </TabsContent>

              <TabsContent value="stats" className="space-y-4">
                <div className="grid gap-4 md:grid-cols-3">
                  <Card>
                    <CardHeader className="pb-2">
                      <CardTitle className="text-sm">Tổng đặt chỗ</CardTitle>
                    </CardHeader>
                    <CardContent>
                      <p className="text-2xl font-bold">{selectedPartner.totalBookings}</p>
                    </CardContent>
                  </Card>
                  <Card>
                    <CardHeader className="pb-2">
                      <CardTitle className="text-sm">Hoàn thành</CardTitle>
                    </CardHeader>
                    <CardContent>
                      <p className="text-2xl font-bold text-green-600">
                        {selectedPartner.completedBookings}
                      </p>
                    </CardContent>
                  </Card>
                  <Card>
                    <CardHeader className="pb-2">
                      <CardTitle className="text-sm">Đã hủy</CardTitle>
                    </CardHeader>
                    <CardContent>
                      <p className="text-2xl font-bold text-red-600">
                        {selectedPartner.cancelledBookings}
                      </p>
                    </CardContent>
                  </Card>
                  <Card>
                    <CardHeader className="pb-2">
                      <CardTitle className="text-sm">Tỷ lệ phản hồi</CardTitle>
                    </CardHeader>
                    <CardContent>
                      <p className="text-2xl font-bold">
                        {parseFloat(String(selectedPartner.responseRate || 0)).toFixed(0)}%
                      </p>
                    </CardContent>
                  </Card>
                  <Card>
                    <CardHeader className="pb-2">
                      <CardTitle className="text-sm">Thời gian phản hồi</CardTitle>
                    </CardHeader>
                    <CardContent>
                      <p className="text-2xl font-bold">
                        {selectedPartner.responseTime ?? "N/A"} min
                      </p>
                    </CardContent>
                  </Card>
                  <Card>
                    <CardHeader className="pb-2">
                      <CardTitle className="text-sm">Hoạt động gần nhất</CardTitle>
                    </CardHeader>
                    <CardContent>
                      <p className="text-lg">
                        {selectedPartner.lastActiveAt 
                          ? format(new Date(selectedPartner.lastActiveAt), "dd/MM HH:mm")
                          : "N/A"}
                      </p>
                    </CardContent>
                  </Card>
                </div>
              </TabsContent>

              <TabsContent value="services" className="space-y-4">
                <div className="grid gap-4 md:grid-cols-2">
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">Giá theo giờ</p>
                    <p className="text-xl font-bold">
                      {new Intl.NumberFormat("vi-VN", {
                        style: "currency",
                        currency: "VND",
                      }).format(selectedPartner.hourlyRate)}
                    </p>
                  </div>
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">Số giờ tối thiểu</p>
                    <p className="text-xl font-bold">{selectedPartner.minimumHours} giờ</p>
                  </div>
                </div>

                <div>
                  <p className="text-sm font-medium text-muted-foreground">Loại dịch vụ</p>
                  <div className="mt-2 flex flex-wrap gap-2">
                    {selectedPartner.serviceTypes.map((service) => (
                      <Badge key={service} variant="secondary">
                        {service}
                      </Badge>
                    ))}
                  </div>
                </div>
              </TabsContent>
            </Tabs>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
