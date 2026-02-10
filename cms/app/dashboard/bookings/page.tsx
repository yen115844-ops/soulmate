"use client";

import { extractPaginatedData } from "@/lib/utils";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  ColumnDef,
  flexRender,
  getCoreRowModel,
  getPaginationRowModel,
  getSortedRowModel,
  SortingState,
  useReactTable,
} from "@tanstack/react-table";
import { format } from "date-fns";
import {
  ArrowUpDown,
  Calendar as CalendarIcon,
  CheckCircle,
  Clock,
  Eye,
  Loader2,
  MapPin,
  MoreHorizontal,
  RefreshCcw,
  Search,
  XCircle,
} from "lucide-react";
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
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
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
import { Label } from "@/components/ui/label";
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
import { Textarea } from "@/components/ui/textarea";
import { bookingsApi, BookingStats, GetBookingsParams } from "@/lib/api/bookings";
import { Booking, BookingStatus } from "@/types";

// Status badge component
function BookingStatusBadge({ status }: { status: BookingStatus }) {
  const variants: Record<
    BookingStatus,
    { variant: "default" | "secondary" | "destructive" | "outline"; label: string; className?: string }
  > = {
    [BookingStatus.PENDING]: { variant: "secondary", label: "Chờ xử lý" },
    [BookingStatus.CONFIRMED]: { variant: "outline", label: "Đã xác nhận", className: "border-blue-500 text-blue-500" },
    [BookingStatus.PAID]: { variant: "default", label: "Đã thanh toán" },
    [BookingStatus.IN_PROGRESS]: { variant: "default", label: "Đang thực hiện", className: "bg-blue-500" },
    [BookingStatus.COMPLETED]: { variant: "default", label: "Hoàn thành", className: "bg-green-500" },
    [BookingStatus.CANCELLED]: { variant: "destructive", label: "Đã hủy" },
    [BookingStatus.DISPUTED]: { variant: "destructive", label: "Tranh chấp", className: "bg-orange-500" },
  };

  const config = variants[status] || { variant: "secondary", label: status };

  return (
    <Badge variant={config.variant} className={config.className}>
      {config.label}
    </Badge>
  );
}

export default function BookingsPage() {
  const queryClient = useQueryClient();
  const [sorting, setSorting] = useState<SortingState>([]);
  const [globalFilter, setGlobalFilter] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [selectedBooking, setSelectedBooking] = useState<Booking | null>(null);
  const [page, setPage] = useState(1);
  const [statusUpdateData, setStatusUpdateData] = useState<{
    booking: Booking;
    newStatus: BookingStatus;
  } | null>(null);
  const [cancelReason, setCancelReason] = useState("");

  // Build query params
  const queryParams: GetBookingsParams = {
    page,
    limit: 10,
    search: globalFilter || undefined,
    status: statusFilter !== "all" ? (statusFilter as BookingStatus) : undefined,
    sortBy: sorting[0]?.id || "createdAt",
    sortOrder: sorting[0]?.desc ? "desc" : "asc",
  };

  // Fetch bookings from API
  const { data: bookingsData, isLoading, refetch } = useQuery({
    queryKey: ["bookings", queryParams],
    queryFn: () => bookingsApi.getBookings(queryParams),
  });

  // Fetch stats from API
  const { data: stats } = useQuery({
    queryKey: ["booking-stats"],
    queryFn: () => bookingsApi.getBookingStats(),
  });

  // Update status mutation
  const updateStatusMutation = useMutation({
    mutationFn: ({ id, status, reason }: { id: string; status: BookingStatus; reason?: string }) =>
      bookingsApi.updateBookingStatus(id, { status, reason }),
    onSuccess: () => {
      toast.success("Cập nhật trạng thái đặt chỗ thành công");
      queryClient.invalidateQueries({ queryKey: ["bookings"] });
      queryClient.invalidateQueries({ queryKey: ["booking-stats"] });
      setStatusUpdateData(null);
      setCancelReason("");
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || "Cập nhật trạng thái thất bại");
    },
  });

  const handleStatusUpdate = () => {
    if (!statusUpdateData) return;

    const { booking, newStatus } = statusUpdateData;
    updateStatusMutation.mutate({
      id: booking.id,
      status: newStatus,
      reason: newStatus === BookingStatus.CANCELLED ? cancelReason : undefined,
    });
  };

  const columns: ColumnDef<Booking>[] = [
    {
      accessorKey: "bookingCode",
      header: "Mã",
      cell: ({ row }) => (
        <span className="font-mono font-medium">{row.getValue("bookingCode")}</span>
      ),
    },
    {
      accessorKey: "user",
      header: "Khách",
      cell: ({ row }) => {
        const booking = row.original;
        return (
          <div className="flex items-center gap-2">
            <Avatar className="h-8 w-8">
              <AvatarImage src={booking.user?.profile?.avatarUrl} />
              <AvatarFallback>
                {booking.user?.profile?.fullName?.charAt(0) || "U"}
              </AvatarFallback>
            </Avatar>
            <span className="text-sm">{booking.user?.profile?.fullName}</span>
          </div>
        );
      },
    },
    {
      accessorKey: "partner",
      header: "Đối tác",
      cell: ({ row }) => {
        const booking = row.original;
        return (
          <div className="flex items-center gap-2">
            <Avatar className="h-8 w-8">
              <AvatarImage src={booking.partner?.profile?.avatarUrl} />
              <AvatarFallback>
                {booking.partner?.profile?.fullName?.charAt(0) || "P"}
              </AvatarFallback>
            </Avatar>
            <span className="text-sm">{booking.partner?.profile?.fullName}</span>
          </div>
        );
      },
    },
    {
      accessorKey: "serviceType",
      header: "Dịch vụ",
      cell: ({ row }) => (
        <Badge variant="secondary" className="capitalize">
          {row.getValue("serviceType")}
        </Badge>
      ),
    },
    {
      accessorKey: "date",
      header: ({ column }) => (
        <Button
          variant="ghost"
          onClick={() => column.toggleSorting(column.getIsSorted() === "asc")}
        >
          Ngày
          <ArrowUpDown className="ml-2 h-4 w-4" />
        </Button>
      ),
      cell: ({ row }) => {
        const booking = row.original;
        // Handle both string and Date formats
        const formatTime = (time: string | Date | undefined) => {
          if (!time) return "--:--";
          if (typeof time === "string") {
            // If it's an ISO date string, extract time
            if (time.includes("T")) {
              return format(new Date(time), "HH:mm");
            }
            return time;
          }
          return format(new Date(time), "HH:mm");
        };
        
        return (
          <div className="text-sm">
            <p>{booking.date ? format(new Date(booking.date), "dd/MM/yyyy") : "N/A"}</p>
            <p className="text-muted-foreground">
              {formatTime(booking.startTime)} - {formatTime(booking.endTime)}
            </p>
          </div>
        );
      },
    },
    {
      accessorKey: "totalAmount",
      header: ({ column }) => (
        <Button
          variant="ghost"
          onClick={() => column.toggleSorting(column.getIsSorted() === "asc")}
        >
          Số tiền
          <ArrowUpDown className="ml-2 h-4 w-4" />
        </Button>
      ),
      cell: ({ row }) => {
        const amount = row.getValue("totalAmount") as number;
        return new Intl.NumberFormat("vi-VN", {
          style: "currency",
          currency: "VND",
        }).format(amount);
      },
    },
    {
      accessorKey: "status",
      header: "Trạng thái",
      cell: ({ row }) => <BookingStatusBadge status={row.getValue("status")} />,
    },
    {
      id: "actions",
      cell: ({ row }) => {
        const booking = row.original;
        const canConfirm = booking.status === BookingStatus.PENDING;
        const canCancel = [BookingStatus.PENDING, BookingStatus.CONFIRMED, BookingStatus.PAID].includes(booking.status);
        const canComplete = booking.status === BookingStatus.IN_PROGRESS;

        return (
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" className="h-8 w-8 p-0">
                <MoreHorizontal className="h-4 w-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuLabel>Thao tác</DropdownMenuLabel>
              <DropdownMenuItem onClick={() => setSelectedBooking(booking)}>
                <Eye className="mr-2 h-4 w-4" />
                Xem chi tiết
              </DropdownMenuItem>
              <DropdownMenuSeparator />
              {canConfirm && (
                <DropdownMenuItem
                  onClick={() => setStatusUpdateData({ booking, newStatus: BookingStatus.CONFIRMED })}
                >
                  <CheckCircle className="mr-2 h-4 w-4 text-blue-500" />
                  Xác nhận
                </DropdownMenuItem>
              )}
              {canComplete && (
                <DropdownMenuItem
                  onClick={() => setStatusUpdateData({ booking, newStatus: BookingStatus.COMPLETED })}
                >
                  <CheckCircle className="mr-2 h-4 w-4 text-green-500" />
                  Hoàn thành
                </DropdownMenuItem>
              )}
              {canCancel && (
                <DropdownMenuItem
                  onClick={() => setStatusUpdateData({ booking, newStatus: BookingStatus.CANCELLED })}
                  className="text-destructive"
                >
                  <XCircle className="mr-2 h-4 w-4" />
                  Hủy
                </DropdownMenuItem>
              )}
            </DropdownMenuContent>
          </DropdownMenu>
        );
      },
    },
  ];

  const { data: bookings, meta } = extractPaginatedData(bookingsData);

  const table = useReactTable({
    data: bookings,
    columns,
    onSortingChange: setSorting,
    getCoreRowModel: getCoreRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    getSortedRowModel: getSortedRowModel(),
    state: { sorting },
  });

  // Extract stats from API response (handles { success, data, timestamp } wrapper)
  const statsData = stats?.data || stats;
  const displayStats: BookingStats = (statsData as BookingStats) || {
    total: 0,
    pending: 0,
    confirmed: 0,
    paid: 0,
    inProgress: 0,
    completed: 0,
    cancelled: 0,
    disputed: 0,
    todayCount: 0,
    monthlyRevenue: 0,
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Quản lý đặt chỗ</h1>
          <p className="text-muted-foreground">
            Xem và quản lý tất cả đặt chỗ trên nền tảng
          </p>
        </div>
        <Button variant="outline" onClick={() => refetch()} disabled={isLoading}>
          <RefreshCcw className={`mr-2 h-4 w-4 ${isLoading ? "animate-spin" : ""}`} />
          Làm mới
        </Button>
      </div>

      {/* Stats */}
      <div className="grid gap-4 md:grid-cols-4 lg:grid-cols-7">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Tổng
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{displayStats.total}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Chờ xử lý
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-yellow-600">{displayStats.pending}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Đang thực hiện
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-blue-600">{displayStats.inProgress}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Hoàn thành
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-600">{displayStats.completed}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Đã hủy
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-red-600">{displayStats.cancelled}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Tranh chấp
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-orange-600">{displayStats.disputed}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Doanh thu tháng
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-lg font-bold">
              {new Intl.NumberFormat("vi-VN", {
                style: "currency",
                currency: "VND",
                notation: "compact",
              }).format(displayStats.monthlyRevenue)}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center">
        <div className="relative flex-1 md:max-w-sm">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Tìm đặt chỗ..."
            value={globalFilter}
            onChange={(e) => setGlobalFilter(e.target.value)}
            className="pl-9"
          />
        </div>
        <Select value={statusFilter} onValueChange={(v) => { setStatusFilter(v); setPage(1); }}>
          <SelectTrigger className="w-[180px]">
            <SelectValue placeholder="Trạng thái" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Tất cả trạng thái</SelectItem>
            <SelectItem value={BookingStatus.PENDING}>Chờ xử lý</SelectItem>
            <SelectItem value={BookingStatus.CONFIRMED}>Đã xác nhận</SelectItem>
            <SelectItem value={BookingStatus.PAID}>Đã thanh toán</SelectItem>
            <SelectItem value={BookingStatus.IN_PROGRESS}>Đang thực hiện</SelectItem>
            <SelectItem value={BookingStatus.COMPLETED}>Hoàn thành</SelectItem>
            <SelectItem value={BookingStatus.CANCELLED}>Đã hủy</SelectItem>
            <SelectItem value={BookingStatus.DISPUTED}>Tranh chấp</SelectItem>
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
                        Không tìm thấy đặt chỗ.
                      </TableCell>
                    </TableRow>
                  )}
                </TableBody>
              </Table>

              <Pagination
                page={page}
                totalPages={meta?.totalPages || 1}
                total={meta?.total || 0}
                itemLabel="đặt chỗ"
                onPageChange={setPage}
              />
            </>
          )}
        </CardContent>
      </Card>

      {/* Status Update Confirmation Dialog */}
      <AlertDialog
        open={!!statusUpdateData}
        onOpenChange={(open) => {
          if (!open) {
            setStatusUpdateData(null);
            setCancelReason("");
          }
        }}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>
              {statusUpdateData?.newStatus === BookingStatus.CANCELLED
                ? "Hủy đặt chỗ"
                : statusUpdateData?.newStatus === BookingStatus.CONFIRMED
                ? "Xác nhận đặt chỗ"
                : "Hoàn thành đặt chỗ"}
            </AlertDialogTitle>
            <AlertDialogDescription>
              Bạn có chắc muốn{" "}
              {statusUpdateData?.newStatus === BookingStatus.CANCELLED
                ? "hủy"
                : statusUpdateData?.newStatus === BookingStatus.CONFIRMED
                ? "xác nhận"
                : "hoàn thành"}{" "}
              đặt chỗ <strong>{statusUpdateData?.booking.bookingCode}</strong>?
            </AlertDialogDescription>
          </AlertDialogHeader>

          {statusUpdateData?.newStatus === BookingStatus.CANCELLED && (
            <div className="space-y-2">
              <Label>Lý do hủy</Label>
              <Textarea
                placeholder="Nhập lý do hủy..."
                value={cancelReason}
                onChange={(e) => setCancelReason(e.target.value)}
              />
            </div>
          )}

          <AlertDialogFooter>
            <AlertDialogCancel>Hủy</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleStatusUpdate}
              disabled={updateStatusMutation.isPending}
            >
              {updateStatusMutation.isPending && (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              )}
              Xác nhận
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {/* Booking Detail Dialog */}
      <Dialog
        open={!!selectedBooking}
        onOpenChange={(open) => !open && setSelectedBooking(null)}
      >
        <DialogContent className="max-w-3xl">
          <DialogHeader>
            <DialogTitle>Chi tiết đặt chỗ</DialogTitle>
          </DialogHeader>
          {selectedBooking && (
            <Tabs defaultValue="info" className="w-full">
              <TabsList className="grid w-full grid-cols-3">
                <TabsTrigger value="info">Thông tin</TabsTrigger>
                <TabsTrigger value="participants">Người tham gia</TabsTrigger>
                <TabsTrigger value="payment">Thanh toán</TabsTrigger>
              </TabsList>
              <TabsContent value="info" className="space-y-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-muted-foreground">Mã đặt chỗ</p>
                    <p className="font-mono text-lg font-bold">
                      {selectedBooking.bookingCode}
                    </p>
                  </div>
                  <BookingStatusBadge status={selectedBooking.status} />
                </div>

                <div className="grid gap-4 md:grid-cols-2">
                  <div className="flex items-center gap-3">
                    <CalendarIcon className="h-5 w-5 text-muted-foreground" />
                    <div>
                      <p className="text-sm text-muted-foreground">Ngày</p>
                      <p>{format(new Date(selectedBooking.date), "dd/MM/yyyy")}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <Clock className="h-5 w-5 text-muted-foreground" />
                    <div>
                      <p className="text-sm text-muted-foreground">Giờ</p>
                      <p>
                        {selectedBooking.startTime} - {selectedBooking.endTime} (
                        {selectedBooking.durationHours}h)
                      </p>
                    </div>
                  </div>
                </div>

                <div className="flex items-start gap-3">
                  <MapPin className="mt-1 h-5 w-5 text-muted-foreground" />
                  <div>
                    <p className="text-sm text-muted-foreground">Địa điểm gặp mặt</p>
                    <p>{selectedBooking.meetingLocation || "Chưa chỉ định"}</p>
                  </div>
                </div>

                <div>
                  <p className="text-sm text-muted-foreground">Loại dịch vụ</p>
                  <Badge variant="secondary" className="mt-1 capitalize">
                    {selectedBooking.serviceType}
                  </Badge>
                </div>

                {selectedBooking.userNote && (
                  <div>
                    <p className="text-sm text-muted-foreground">Ghi chú khách</p>
                    <p className="mt-1 rounded bg-muted p-2 text-sm">
                      {selectedBooking.userNote}
                    </p>
                  </div>
                )}

                <div>
                  <p className="text-sm text-muted-foreground">Tạo lúc</p>
                  <p>{format(new Date(selectedBooking.createdAt), "dd/MM/yyyy HH:mm")}</p>
                </div>
              </TabsContent>

              <TabsContent value="participants" className="space-y-4">
                <div className="grid gap-4 md:grid-cols-2">
                  <Card>
                    <CardHeader className="pb-2">
                      <CardTitle className="text-sm">Khách hàng</CardTitle>
                    </CardHeader>
                    <CardContent>
                      <div className="flex items-center gap-3">
                        <Avatar>
                          <AvatarImage src={selectedBooking.user?.profile?.avatarUrl} />
                          <AvatarFallback>
                            {selectedBooking.user?.profile?.fullName?.charAt(0)}
                          </AvatarFallback>
                        </Avatar>
                        <div>
                          <p className="font-medium">
                            {selectedBooking.user?.profile?.fullName}
                          </p>
                          <p className="text-sm text-muted-foreground">
                            {selectedBooking.user?.email}
                          </p>
                        </div>
                      </div>
                    </CardContent>
                  </Card>

                  <Card>
                    <CardHeader className="pb-2">
                      <CardTitle className="text-sm">Đối tác</CardTitle>
                    </CardHeader>
                    <CardContent>
                      <div className="flex items-center gap-3">
                        <Avatar>
                          <AvatarImage src={selectedBooking.partner?.profile?.avatarUrl} />
                          <AvatarFallback>
                            {selectedBooking.partner?.profile?.fullName?.charAt(0)}
                          </AvatarFallback>
                        </Avatar>
                        <div>
                          <p className="font-medium">
                            {selectedBooking.partner?.profile?.fullName}
                          </p>
                          <p className="text-sm text-muted-foreground">
                            {selectedBooking.partner?.email}
                          </p>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                </div>
              </TabsContent>

              <TabsContent value="payment" className="space-y-4">
                <div className="space-y-3">
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Giá/giờ</span>
                    <span>
                      {new Intl.NumberFormat("vi-VN", {
                        style: "currency",
                        currency: "VND",
                      }).format(selectedBooking.hourlyRate)}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Thời lượng</span>
                    <span>{selectedBooking.totalHours} giờ</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Tạm tính</span>
                    <span>
                      {new Intl.NumberFormat("vi-VN", {
                        style: "currency",
                        currency: "VND",
                      }).format(selectedBooking.subtotal)}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Phí dịch vụ (15%)</span>
                    <span>
                      {new Intl.NumberFormat("vi-VN", {
                        style: "currency",
                        currency: "VND",
                      }).format(selectedBooking.serviceFee)}
                    </span>
                  </div>
                  <div className="border-t pt-3">
                    <div className="flex justify-between text-lg font-bold">
                      <span>Tổng cộng</span>
                      <span>
                        {new Intl.NumberFormat("vi-VN", {
                          style: "currency",
                          currency: "VND",
                        }).format(selectedBooking.totalAmount)}
                      </span>
                    </div>
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
