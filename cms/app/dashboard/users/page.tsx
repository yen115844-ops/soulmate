"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
    ColumnDef,
    ColumnFiltersState,
    SortingState,
    flexRender,
    getCoreRowModel,
    getFilteredRowModel,
    getSortedRowModel,
    useReactTable
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
import { GetUsersParams, UserStats, usersApi } from "@/lib/api/users";
import { extractPaginatedData } from "@/lib/utils";
import { KycStatus, User, UserRole, UserStatus } from "@/types";

// Status badge component
function StatusBadge({ status }: { status: UserStatus }) {
  const variants: Record<UserStatus, { variant: "default" | "secondary" | "destructive" | "outline"; label: string }> = {
    [UserStatus.ACTIVE]: { variant: "default", label: "Hoạt động" },
    [UserStatus.PENDING]: { variant: "secondary", label: "Chờ duyệt" },
    [UserStatus.SUSPENDED]: { variant: "outline", label: "Tạm khóa" },
    [UserStatus.BANNED]: { variant: "destructive", label: "Cấm" },
  };

  const { variant, label } = variants[status] || { variant: "secondary", label: status };

  return <Badge variant={variant}>{label}</Badge>;
}

// KYC Status badge
function KycBadge({ status }: { status: KycStatus }) {
  const variants: Record<KycStatus, { variant: "default" | "secondary" | "destructive" | "outline"; label: string }> = {
    [KycStatus.VERIFIED]: { variant: "default", label: "Đã xác minh" },
    [KycStatus.PENDING]: { variant: "secondary", label: "Chờ duyệt" },
    [KycStatus.REJECTED]: { variant: "destructive", label: "Từ chối" },
    [KycStatus.NONE]: { variant: "outline", label: "Chưa nộp" },
  };

  const { variant, label } = variants[status] || { variant: "outline", label: status };

  return <Badge variant={variant}>{label}</Badge>;
}

export default function UsersPage() {
  const queryClient = useQueryClient();
  const [sorting, setSorting] = useState<SortingState>([]);
  const [columnFilters, setColumnFilters] = useState<ColumnFiltersState>([]);
  const [globalFilter, setGlobalFilter] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [roleFilter, setRoleFilter] = useState<string>("all");
  const [page, setPage] = useState(1);
  const [limit] = useState(10);
  
  // Dialog states
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [actionDialog, setActionDialog] = useState<{
    open: boolean;
    action: "suspend" | "ban" | "activate" | null;
  }>({ open: false, action: null });

  // Build query params
  const queryParams: GetUsersParams = {
    page,
    limit,
    ...(statusFilter !== "all" && { status: statusFilter as UserStatus }),
    ...(roleFilter !== "all" && { role: roleFilter as UserRole }),
    ...(globalFilter && { search: globalFilter }),
  };

  // Fetch users from API
  const { data: usersData, isLoading } = useQuery({
    queryKey: ["users", queryParams],
    queryFn: () => usersApi.getUsers(queryParams),
  });

  // Fetch user stats
  const { data: statsData, isLoading: statsLoading } = useQuery({
    queryKey: ["user-stats"],
    queryFn: () => usersApi.getUserStats(),
  });

  // Update user status mutation
  const updateStatusMutation = useMutation({
    mutationFn: async ({ id, status }: { id: string; status: UserStatus }) => {
      return usersApi.updateUserStatus(id, { status });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["users"] });
      queryClient.invalidateQueries({ queryKey: ["user-stats"] });
      toast.success("Cập nhật trạng thái người dùng thành công");
      setActionDialog({ open: false, action: null });
      setSelectedUser(null);
    },
    onError: () => {
      toast.error("Cập nhật trạng thái thất bại");
    },
  });

  // Table columns
  const columns: ColumnDef<User>[] = [
    {
      accessorKey: "profile.fullName",
      header: ({ column }) => (
        <Button
          variant="ghost"
          onClick={() => column.toggleSorting(column.getIsSorted() === "asc")}
        >
          Người dùng
          <ArrowUpDown className="ml-2 h-4 w-4" />
        </Button>
      ),
      cell: ({ row }) => {
        const user = row.original;
        return (
          <div className="flex items-center gap-3">
            <Avatar>
              <AvatarImage src={user.profile?.avatarUrl} />
              <AvatarFallback>
                {user.profile?.fullName?.charAt(0) || "U"}
              </AvatarFallback>
            </Avatar>
            <div>
              <p className="font-medium">{user.profile?.fullName || "N/A"}</p>
              <p className="text-sm text-muted-foreground">{user.email}</p>
            </div>
          </div>
        );
      },
    },
    {
      accessorKey: "phone",
      header: "Số điện thoại",
      cell: ({ row }) => row.getValue("phone") || "N/A",
    },
    {
      accessorKey: "role",
      header: "Vai trò",
      cell: ({ row }) => {
        const role = row.getValue("role") as UserRole;
        const roleLabel = role === UserRole.PARTNER ? "Đối tác" : "Người dùng";
        return (
          <Badge variant={role === UserRole.PARTNER ? "default" : "secondary"}>
            {roleLabel}
          </Badge>
        );
      },
    },
    {
      accessorKey: "status",
      header: "Trạng thái",
      cell: ({ row }) => <StatusBadge status={row.getValue("status")} />,
    },
    {
      accessorKey: "kycStatus",
      header: "KYC",
      cell: ({ row }) => <KycBadge status={row.getValue("kycStatus")} />,
    },
    {
      accessorKey: "createdAt",
      header: ({ column }) => (
        <Button
          variant="ghost"
          onClick={() => column.toggleSorting(column.getIsSorted() === "asc")}
        >
          Tham gia
          <ArrowUpDown className="ml-2 h-4 w-4" />
        </Button>
      ),
      cell: ({ row }) => format(new Date(row.getValue("createdAt")), "dd/MM/yyyy"),
    },
    {
      id: "actions",
      cell: ({ row }) => {
        const user = row.original;
        return (
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" className="h-8 w-8 p-0">
                <MoreHorizontal className="h-4 w-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuLabel>Thao tác</DropdownMenuLabel>
              <DropdownMenuItem onClick={() => setSelectedUser(user)}>
                <Eye className="mr-2 h-4 w-4" />
                Xem chi tiết
              </DropdownMenuItem>
              <DropdownMenuSeparator />
              {user.status !== UserStatus.ACTIVE && (
                <DropdownMenuItem
                  onClick={() => {
                    setSelectedUser(user);
                    setActionDialog({ open: true, action: "activate" });
                  }}
                >
                  <CheckCircle className="mr-2 h-4 w-4" />
                  Kích hoạt
                </DropdownMenuItem>
              )}
              {user.status !== UserStatus.SUSPENDED && (
                <DropdownMenuItem
                  onClick={() => {
                    setSelectedUser(user);
                    setActionDialog({ open: true, action: "suspend" });
                  }}
                >
                  <XCircle className="mr-2 h-4 w-4" />
                  Tạm khóa
                </DropdownMenuItem>
              )}
              {user.status !== UserStatus.BANNED && (
                <DropdownMenuItem
                  onClick={() => {
                    setSelectedUser(user);
                    setActionDialog({ open: true, action: "ban" });
                  }}
                  className="text-destructive"
                >
                  <Ban className="mr-2 h-4 w-4" />
                  Cấm người dùng
                </DropdownMenuItem>
              )}
            </DropdownMenuContent>
          </DropdownMenu>
        );
      },
    },
  ];

  const { data: users, meta } = extractPaginatedData(usersData);
  const stats: UserStats | undefined = statsData?.data;

  const table = useReactTable({
    data: users,
    columns,
    onSortingChange: setSorting,
    onColumnFiltersChange: setColumnFilters,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    manualPagination: true,
    pageCount: meta?.totalPages || 0,
    state: {
      sorting,
      columnFilters,
    },
  });

  const handleStatusAction = () => {
    if (!selectedUser || !actionDialog.action) return;

    const statusMap = {
      activate: UserStatus.ACTIVE,
      suspend: UserStatus.SUSPENDED,
      ban: UserStatus.BANNED,
    };

    updateStatusMutation.mutate({
      id: selectedUser.id,
      status: statusMap[actionDialog.action],
    });
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Quản lý người dùng</h1>
        <p className="text-muted-foreground">
          Quản lý tất cả người dùng trên nền tảng
        </p>
      </div>

      {/* Stats */}
      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Tổng người dùng
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
              Chờ duyệt
            </CardTitle>
          </CardHeader>
          <CardContent>
            {statsLoading ? (
              <Skeleton className="h-8 w-16" />
            ) : (
              <div className="text-2xl font-bold text-yellow-600">
                {stats?.pending || 0}
              </div>
            )}
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Bị cấm
            </CardTitle>
          </CardHeader>
          <CardContent>
            {statsLoading ? (
              <Skeleton className="h-8 w-16" />
            ) : (
              <div className="text-2xl font-bold text-red-600">
                {stats?.banned || 0}
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
            placeholder="Tìm người dùng..."
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
        <Select value={roleFilter} onValueChange={setRoleFilter}>
          <SelectTrigger className="w-[150px]">
            <SelectValue placeholder="Vai trò" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Tất cả vai trò</SelectItem>
            <SelectItem value={UserRole.USER}>Người dùng</SelectItem>
            <SelectItem value={UserRole.PARTNER}>Đối tác</SelectItem>
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
                        Không tìm thấy người dùng.
                      </TableCell>
                    </TableRow>
                  )}
                </TableBody>
              </Table>

              <Pagination
                page={page}
                totalPages={meta?.totalPages || 1}
                total={meta?.total || 0}
                itemLabel="người dùng"
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
              {actionDialog.action === "activate" && "Kích hoạt người dùng"}
              {actionDialog.action === "suspend" && "Tạm khóa người dùng"}
              {actionDialog.action === "ban" && "Cấm người dùng"}
            </DialogTitle>
            <DialogDescription>
              {actionDialog.action === "activate" &&
                "Người dùng sẽ được kích hoạt và có thể sử dụng nền tảng."}
              {actionDialog.action === "suspend" &&
                "Tài khoản người dùng sẽ bị tạm khóa."}
              {actionDialog.action === "ban" &&
                "Người dùng sẽ bị cấm vĩnh viễn khỏi nền tảng. Thao tác này cần cẩn trọng."}
            </DialogDescription>
          </DialogHeader>
          <div className="py-4">
            <p>
              Bạn có chắc muốn {actionDialog.action === "activate" ? "kích hoạt" : actionDialog.action === "suspend" ? "tạm khóa" : "cấm"}{" "}
              <strong>{selectedUser?.profile?.fullName || selectedUser?.email}</strong>?
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

      {/* User Detail Dialog */}
      <Dialog
        open={!!selectedUser && !actionDialog.open}
        onOpenChange={(open) => !open && setSelectedUser(null)}
      >
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Chi tiết người dùng</DialogTitle>
          </DialogHeader>
          {selectedUser && (
            <div className="grid gap-4">
              <div className="flex items-center gap-4">
                <Avatar className="h-16 w-16">
                  <AvatarImage src={selectedUser.profile?.avatarUrl} />
                  <AvatarFallback className="text-lg">
                    {selectedUser.profile?.fullName?.charAt(0) || "U"}
                  </AvatarFallback>
                </Avatar>
                <div>
                  <h3 className="text-lg font-semibold">
                    {selectedUser.profile?.fullName || "N/A"}
                  </h3>
                  <p className="text-muted-foreground">{selectedUser.email}</p>
                </div>
              </div>

              <div className="grid gap-4 md:grid-cols-2">
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Số điện thoại</p>
                  <p>{selectedUser.phone || "N/A"}</p>
                </div>
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Vai trò</p>
                  <Badge
                    variant={
                      selectedUser.role === UserRole.PARTNER
                        ? "default"
                        : "secondary"
                    }
                  >
                    {selectedUser.role === UserRole.PARTNER ? "Đối tác" : "Người dùng"}
                  </Badge>
                </div>
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Trạng thái</p>
                  <StatusBadge status={selectedUser.status} />
                </div>
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Trạng thái KYC</p>
                  <KycBadge status={selectedUser.kycStatus} />
                </div>
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Giới tính</p>
                  <p>{selectedUser.profile?.gender || "N/A"}</p>
                </div>
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Địa điểm</p>
                  <p>{selectedUser.profile?.city || "N/A"}</p>
                </div>
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Tham gia</p>
                  <p>{format(new Date(selectedUser.createdAt), "dd/MM/yyyy HH:mm")}</p>
                </div>
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Cập nhật lần cuối</p>
                  <p>{format(new Date(selectedUser.updatedAt), "dd/MM/yyyy HH:mm")}</p>
                </div>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
