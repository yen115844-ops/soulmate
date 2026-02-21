"use client";

import { extractPaginatedData } from "@/lib/utils";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
    ColumnDef,
    flexRender,
    getCoreRowModel,
    useReactTable,
} from "@tanstack/react-table";
import { format } from "date-fns";
import {
    CheckCircle,
    Eye,
    Image as ImageIcon,
    Loader2,
    MoreHorizontal,
    Search,
    ShieldCheck,
    XCircle
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
import { Label } from "@/components/ui/label";
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
import { Textarea } from "@/components/ui/textarea";
import { GetKycParams, kycApi } from "@/lib/api/kyc";
import { KycStatus, KycVerification } from "@/types";

// Status badge
function VerificationStatusBadge({ status }: { status: KycStatus }) {
  const variants: Record<KycStatus, { variant: "default" | "secondary" | "destructive" | "outline"; label: string }> = {
    [KycStatus.VERIFIED]: { variant: "default", label: "Đã xác minh" },
    [KycStatus.PENDING]: { variant: "secondary", label: "Chờ duyệt" },
    [KycStatus.REJECTED]: { variant: "destructive", label: "Từ chối" },
    [KycStatus.NONE]: { variant: "outline", label: "Chưa nộp" },
  };

  const config = variants[status] || { variant: "outline", label: status };
  return <Badge variant={config.variant}>{config.label}</Badge>;
}

// Liveness score badge
function LivenessScoreBadge({ score }: { score?: number }) {
  if (score === undefined || score === null) return <span className="text-muted-foreground">-</span>;
  
  const percentage = (score * 100).toFixed(0);
  const color = score >= 0.85 ? "text-green-600 bg-green-50" 
    : score >= 0.70 ? "text-yellow-600 bg-yellow-50" 
    : "text-red-600 bg-red-50";
  
  return (
    <span className={`px-2 py-1 rounded-full text-xs font-medium ${color}`}>
      {percentage}%
    </span>
  );
}

export default function VerificationPage() {
  const queryClient = useQueryClient();
  const [globalFilter, setGlobalFilter] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("PENDING");
  const [page, setPage] = useState(1);
  const [limit] = useState(10);
  const [selectedVerification, setSelectedVerification] = useState<KycVerification | null>(null);
  const [reviewDialog, setReviewDialog] = useState<{
    open: boolean;
    action: "approve" | "reject" | null;
  }>({ open: false, action: null });
  const [rejectionReason, setRejectionReason] = useState("");

  // Build query params
  const queryParams: GetKycParams = {
    page,
    limit,
    ...(statusFilter !== "all" && { status: statusFilter as KycStatus }),
    ...(globalFilter && { search: globalFilter }),
  };

  // Fetch verification list from API
  const { data: verificationData, isLoading } = useQuery({
    queryKey: ["verifications", queryParams],
    queryFn: () => kycApi.getKycList(queryParams),
  });

  // Fetch stats
  const { data: stats, isLoading: statsLoading } = useQuery({
    queryKey: ["verification-stats"],
    queryFn: () => kycApi.getKycStats(),
  });

  // Review mutation
  const reviewMutation = useMutation({
    mutationFn: async ({ id, status, rejectionReason }: { id: string; status: KycStatus; rejectionReason?: string }) => {
      return kycApi.reviewKyc(id, { status, rejectionReason });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["verifications"] });
      queryClient.invalidateQueries({ queryKey: ["verification-stats"] });
      toast.success(
        reviewDialog.action === "approve"
          ? "Đã duyệt xác minh thành công"
          : "Đã từ chối xác minh"
      );
      setReviewDialog({ open: false, action: null });
      setSelectedVerification(null);
      setRejectionReason("");
    },
    onError: () => {
      toast.error("Xử lý xác minh thất bại");
    },
  });

  const columns: ColumnDef<KycVerification>[] = [
    {
      accessorKey: "user",
      header: "Người dùng",
      cell: ({ row }) => {
        const verification = row.original;
        return (
          <div className="flex items-center gap-3">
            <Avatar>
              <AvatarImage src={verification.user?.profile?.avatarUrl} />
              <AvatarFallback>
                {verification.user?.profile?.fullName?.charAt(0) || "U"}
              </AvatarFallback>
            </Avatar>
            <div>
              <p className="font-medium">{verification.user?.profile?.fullName}</p>
              <p className="text-sm text-muted-foreground">{verification.user?.email}</p>
            </div>
          </div>
        );
      },
    },
    {
      accessorKey: "submittedAt",
      header: "Nộp lúc",
      cell: ({ row }) => {
        const date = row.getValue("submittedAt") as string;
        return date ? format(new Date(date), "dd/MM/yyyy HH:mm") : "N/A";
      },
    },
    {
      accessorKey: "livenessScore",
      header: "Điểm Liveness",
      cell: ({ row }) => {
        const score = row.getValue("livenessScore") as number;
        return <LivenessScoreBadge score={score} />;
      },
    },
    {
      accessorKey: "isAutoVerified",
      header: "Tự động duyệt",
      cell: ({ row }) => {
        const isAuto = row.getValue("isAutoVerified") as boolean;
        return isAuto ? (
          <Badge variant="outline" className="text-green-600 border-green-600">
            <ShieldCheck className="w-3 h-3 mr-1" />
            Tự động
          </Badge>
        ) : (
          <span className="text-muted-foreground text-sm">Cần xem xét</span>
        );
      },
    },
    {
      accessorKey: "status",
      header: "Trạng thái",
      cell: ({ row }) => <VerificationStatusBadge status={row.getValue("status")} />,
    },
    {
      id: "actions",
      cell: ({ row }) => {
        const verification = row.original;
        return (
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" className="h-8 w-8 p-0">
                <MoreHorizontal className="h-4 w-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuLabel>Thao tác</DropdownMenuLabel>
              <DropdownMenuItem onClick={() => setSelectedVerification(verification)}>
                <Eye className="mr-2 h-4 w-4" />
                Xem chi tiết
              </DropdownMenuItem>
              {verification.status === KycStatus.PENDING && (
                <>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem
                    onClick={() => {
                      setSelectedVerification(verification);
                      setReviewDialog({ open: true, action: "approve" });
                    }}
                  >
                    <CheckCircle className="mr-2 h-4 w-4" />
                    Duyệt
                  </DropdownMenuItem>
                  <DropdownMenuItem
                    onClick={() => {
                      setSelectedVerification(verification);
                      setReviewDialog({ open: true, action: "reject" });
                    }}
                    className="text-destructive"
                  >
                    <XCircle className="mr-2 h-4 w-4" />
                    Từ chối
                  </DropdownMenuItem>
                </>
              )}
            </DropdownMenuContent>
          </DropdownMenu>
        );
      },
    },
  ];

  const { data: verificationList, meta } = extractPaginatedData(verificationData);

  const table = useReactTable({
    data: verificationList,
    columns,
    getCoreRowModel: getCoreRowModel(),
    manualPagination: true,
    pageCount: meta?.totalPages || 0,
  });

  const handleReview = () => {
    if (!selectedVerification || !reviewDialog.action) return;

    reviewMutation.mutate({
      id: selectedVerification.id,
      status: reviewDialog.action === "approve" ? KycStatus.VERIFIED : KycStatus.REJECTED,
      rejectionReason: reviewDialog.action === "reject" ? rejectionReason : undefined,
    });
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Xác minh danh tính</h1>
        <p className="text-muted-foreground">
          Duyệt ảnh selfie và kết quả liveness check để cấp huy hiệu tick xanh
        </p>
      </div>

      {/* Stats */}
      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Tổng yêu cầu
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
        <Card className="border-yellow-200 bg-yellow-50 dark:border-yellow-900 dark:bg-yellow-950">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-yellow-700 dark:text-yellow-300">
              Chờ duyệt
            </CardTitle>
          </CardHeader>
          <CardContent>
            {statsLoading ? (
              <Skeleton className="h-8 w-16" />
            ) : (
              <div className="text-2xl font-bold text-yellow-700 dark:text-yellow-300">
                {stats?.pending || 0}
              </div>
            )}
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Đã xác minh
            </CardTitle>
          </CardHeader>
          <CardContent>
            {statsLoading ? (
              <Skeleton className="h-8 w-16" />
            ) : (
              <div className="text-2xl font-bold text-green-600">{stats?.verified || 0}</div>
            )}
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Từ chối
            </CardTitle>
          </CardHeader>
          <CardContent>
            {statsLoading ? (
              <Skeleton className="h-8 w-16" />
            ) : (
              <div className="text-2xl font-bold text-red-600">{stats?.rejected || 0}</div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center">
        <div className="relative flex-1 md:max-w-sm">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Tìm theo tên, email..."
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
            <SelectItem value="all">Tất cả</SelectItem>
            <SelectItem value={KycStatus.PENDING}>Chờ duyệt</SelectItem>
            <SelectItem value={KycStatus.VERIFIED}>Đã xác minh</SelectItem>
            <SelectItem value={KycStatus.REJECTED}>Từ chối</SelectItem>
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
                        Không tìm thấy yêu cầu xác minh nào.
                      </TableCell>
                    </TableRow>
                  )}
                </TableBody>
              </Table>

              <Pagination
                page={page}
                totalPages={meta?.totalPages || 1}
                total={meta?.total || 0}
                itemLabel="yêu cầu"
                onPageChange={setPage}
              />
            </>
          )}
        </CardContent>
      </Card>

      {/* Review Dialog */}
      <Dialog
        open={reviewDialog.open}
        onOpenChange={(open) => {
          setReviewDialog({ open, action: null });
          setRejectionReason("");
        }}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {reviewDialog.action === "approve" ? "Duyệt xác minh" : "Từ chối xác minh"}
            </DialogTitle>
            <DialogDescription>
              {reviewDialog.action === "approve"
                ? "Người dùng sẽ nhận được huy hiệu tick xanh sau khi duyệt."
                : "Vui lòng nhập lý do từ chối để người dùng có thể cải thiện."}
            </DialogDescription>
          </DialogHeader>

          {reviewDialog.action === "reject" && (
            <div className="space-y-2">
              <Label>Lý do từ chối</Label>
              <Textarea
                placeholder="VD: Ảnh không rõ mặt, ánh sáng yếu..."
                value={rejectionReason}
                onChange={(e) => setRejectionReason(e.target.value)}
              />
            </div>
          )}

          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setReviewDialog({ open: false, action: null })}
              disabled={reviewMutation.isPending}
            >
              Hủy
            </Button>
            <Button
              variant={reviewDialog.action === "reject" ? "destructive" : "default"}
              onClick={handleReview}
              disabled={reviewMutation.isPending || (reviewDialog.action === "reject" && !rejectionReason)}
            >
              {reviewMutation.isPending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              {reviewDialog.action === "approve" ? "Duyệt" : "Từ chối"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Detail Dialog */}
      <Dialog
        open={!!selectedVerification && !reviewDialog.open}
        onOpenChange={(open) => !open && setSelectedVerification(null)}
      >
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Chi tiết xác minh</DialogTitle>
          </DialogHeader>
          {selectedVerification && (
            <div className="space-y-6">
              {/* User Info */}
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <Avatar className="h-12 w-12">
                    <AvatarImage src={selectedVerification.user?.profile?.avatarUrl} />
                    <AvatarFallback>
                      {selectedVerification.user?.profile?.fullName?.charAt(0)}
                    </AvatarFallback>
                  </Avatar>
                  <div>
                    <p className="font-medium">{selectedVerification.user?.profile?.fullName}</p>
                    <p className="text-sm text-muted-foreground">
                      {selectedVerification.user?.email}
                    </p>
                  </div>
                </div>
                <VerificationStatusBadge status={selectedVerification.status} />
              </div>

              {/* Selfie Image */}
              <div>
                <p className="mb-3 text-sm font-medium text-muted-foreground">
                  Ảnh Selfie
                </p>
                <div className="max-w-xs mx-auto">
                  <div className="aspect-[3/4] overflow-hidden rounded-lg border bg-muted">
                    {selectedVerification.selfieUrl?.trim() ? (
                      <img
                        src={selectedVerification.selfieUrl}
                        alt="Selfie"
                        className="h-full w-full object-cover"
                      />
                    ) : (
                      <div className="flex h-full items-center justify-center">
                        <ImageIcon className="h-12 w-12 text-muted-foreground" />
                      </div>
                    )}
                  </div>
                </div>
              </div>

              {/* Liveness Info */}
              <div>
                <p className="mb-3 text-sm font-medium text-muted-foreground">
                  Kết quả Liveness Check
                </p>
                <div className="grid gap-4 md:grid-cols-2">
                  <Card>
                    <CardContent className="pt-4">
                      <p className="text-sm text-muted-foreground">Điểm Liveness</p>
                      <div className="flex items-center gap-2 mt-1">
                        <p className="text-2xl font-bold">
                          {selectedVerification.livenessScore 
                            ? `${(selectedVerification.livenessScore * 100).toFixed(0)}%`
                            : 'N/A'}
                        </p>
                        {selectedVerification.livenessScore && (
                          <span className={`text-sm ${
                            selectedVerification.livenessScore >= 0.85 
                              ? 'text-green-600' 
                              : selectedVerification.livenessScore >= 0.70 
                                ? 'text-yellow-600' 
                                : 'text-red-600'
                          }`}>
                            {selectedVerification.livenessScore >= 0.85 
                              ? '(Rất tốt)' 
                              : selectedVerification.livenessScore >= 0.70 
                                ? '(Khá)' 
                                : '(Không đạt)'}
                          </span>
                        )}
                      </div>
                    </CardContent>
                  </Card>
                  <Card>
                    <CardContent className="pt-4">
                      <p className="text-sm text-muted-foreground">Tự động xác minh</p>
                      <p className="text-lg font-semibold mt-1">
                        {selectedVerification.isAutoVerified ? (
                          <span className="text-green-600">Có (score ≥ 85%)</span>
                        ) : (
                          <span className="text-yellow-600">Cần xem xét thủ công</span>
                        )}
                      </p>
                    </CardContent>
                  </Card>
                </div>
              </div>

              {/* Metadata */}
              <div className="grid gap-4 md:grid-cols-2 text-sm">
                <div>
                  <p className="text-muted-foreground">Ngày gửi</p>
                  <p className="font-medium">
                    {selectedVerification.submittedAt 
                      ? format(new Date(selectedVerification.submittedAt), "dd/MM/yyyy HH:mm")
                      : 'N/A'}
                  </p>
                </div>
                <div>
                  <p className="text-muted-foreground">Thiết bị</p>
                  <p className="font-medium truncate">
                    {selectedVerification.deviceInfo || 'Không có thông tin'}
                  </p>
                </div>
              </div>

              {/* Rejection Reason */}
              {selectedVerification.status === KycStatus.REJECTED && selectedVerification.rejectionReason && (
                <div className="rounded-lg border border-destructive/50 bg-destructive/10 p-4">
                  <p className="text-sm font-medium text-destructive">Lý do từ chối</p>
                  <p className="mt-1">{selectedVerification.rejectionReason}</p>
                </div>
              )}

              {/* Actions for pending */}
              {selectedVerification.status === KycStatus.PENDING && (
                <div className="flex justify-end gap-2">
                  <Button
                    variant="destructive"
                    onClick={() => setReviewDialog({ open: true, action: "reject" })}
                  >
                    <XCircle className="mr-2 h-4 w-4" />
                    Từ chối
                  </Button>
                  <Button
                    onClick={() => setReviewDialog({ open: true, action: "approve" })}
                  >
                    <CheckCircle className="mr-2 h-4 w-4" />
                    Duyệt & cấp tick xanh
                  </Button>
                </div>
              )}
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
