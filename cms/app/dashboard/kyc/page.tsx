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
import { Textarea } from "@/components/ui/textarea";
import { GetKycParams, kycApi } from "@/lib/api/kyc";
import { KycStatus, KycVerification } from "@/types";

// Status badge
function KycStatusBadge({ status }: { status: KycStatus }) {
  const variants: Record<KycStatus, { variant: "default" | "secondary" | "destructive" | "outline"; label: string }> = {
    [KycStatus.VERIFIED]: { variant: "default", label: "Đã xác minh" },
    [KycStatus.PENDING]: { variant: "secondary", label: "Chờ duyệt" },
    [KycStatus.REJECTED]: { variant: "destructive", label: "Từ chối" },
    [KycStatus.NONE]: { variant: "outline", label: "Chưa nộp" },
  };

  const config = variants[status] || { variant: "outline", label: status };
  return <Badge variant={config.variant}>{config.label}</Badge>;
}

export default function KycPage() {
  const queryClient = useQueryClient();
  const [globalFilter, setGlobalFilter] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("PENDING");
  const [page, setPage] = useState(1);
  const [limit] = useState(10);
  const [selectedKyc, setSelectedKyc] = useState<KycVerification | null>(null);
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

  // Fetch KYC list from API
  const { data: kycData, isLoading } = useQuery({
    queryKey: ["kyc", queryParams],
    queryFn: () => kycApi.getKycList(queryParams),
  });

  // Fetch KYC stats
  const { data: stats, isLoading: statsLoading } = useQuery({
    queryKey: ["kyc-stats"],
    queryFn: () => kycApi.getKycStats(),
  });

  // Review KYC mutation
  const reviewMutation = useMutation({
    mutationFn: async ({ id, status, rejectionReason }: { id: string; status: KycStatus; rejectionReason?: string }) => {
      return kycApi.reviewKyc(id, { status, rejectionReason });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["kyc"] });
      queryClient.invalidateQueries({ queryKey: ["kyc-stats"] });
      toast.success(
        reviewDialog.action === "approve"
          ? "Đã duyệt KYC thành công"
          : "Đã từ chối KYC"
      );
      setReviewDialog({ open: false, action: null });
      setSelectedKyc(null);
      setRejectionReason("");
    },
    onError: () => {
      toast.error("Xử lý KYC thất bại");
    },
  });

  const columns: ColumnDef<KycVerification>[] = [
    {
      accessorKey: "user",
      header: "Người dùng",
      cell: ({ row }) => {
        const kyc = row.original;
        return (
          <div className="flex items-center gap-3">
            <Avatar>
              <AvatarImage src={kyc.user?.profile?.avatarUrl} />
              <AvatarFallback>
                {kyc.user?.profile?.fullName?.charAt(0) || "U"}
              </AvatarFallback>
            </Avatar>
            <div>
              <p className="font-medium">{kyc.user?.profile?.fullName}</p>
              <p className="text-sm text-muted-foreground">{kyc.user?.email}</p>
            </div>
          </div>
        );
      },
    },
    {
      accessorKey: "idCardName",
      header: "Tên trên CCCD",
    },
    {
      accessorKey: "idCardNumber",
      header: "Số CCCD",
      cell: ({ row }) => (
        <span className="font-mono">{row.getValue("idCardNumber")}</span>
      ),
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
      accessorKey: "faceMatchScore",
      header: "Khớp khuôn mặt",
      cell: ({ row }) => {
        const scoreValue = row.getValue("faceMatchScore");
        const score = typeof scoreValue === 'string' ? parseFloat(scoreValue) : (scoreValue as number) || 0;
        const color = score >= 0.9 ? "text-green-600" : score >= 0.7 ? "text-yellow-600" : "text-red-600";
        return <span className={`font-medium ${color}`}>{(score * 100).toFixed(0)}%</span>;
      },
    },
    {
      accessorKey: "status",
      header: "Trạng thái",
      cell: ({ row }) => <KycStatusBadge status={row.getValue("status")} />,
    },
    {
      id: "actions",
      cell: ({ row }) => {
        const kyc = row.original;
        return (
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" className="h-8 w-8 p-0">
                <MoreHorizontal className="h-4 w-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuLabel>Thao tác</DropdownMenuLabel>
              <DropdownMenuItem onClick={() => setSelectedKyc(kyc)}>
                <Eye className="mr-2 h-4 w-4" />
                Xem chi tiết
              </DropdownMenuItem>
              {kyc.status === KycStatus.PENDING && (
                <>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem
                    onClick={() => {
                      setSelectedKyc(kyc);
                      setReviewDialog({ open: true, action: "approve" });
                    }}
                  >
                    <CheckCircle className="mr-2 h-4 w-4" />
                    Duyệt
                  </DropdownMenuItem>
                  <DropdownMenuItem
                    onClick={() => {
                      setSelectedKyc(kyc);
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

  const { data: kycList, meta } = extractPaginatedData(kycData);

  const table = useReactTable({
    data: kycList,
    columns,
    getCoreRowModel: getCoreRowModel(),
    manualPagination: true,
    pageCount: meta?.totalPages || 0,
  });

  const handleReview = () => {
    if (!selectedKyc || !reviewDialog.action) return;

    reviewMutation.mutate({
      id: selectedKyc.id,
      status: reviewDialog.action === "approve" ? KycStatus.VERIFIED : KycStatus.REJECTED,
      rejectionReason: reviewDialog.action === "reject" ? rejectionReason : undefined,
    });
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Xác minh KYC</h1>
        <p className="text-muted-foreground">
          Duyệt và xác minh giấy tờ định danh người dùng
        </p>
      </div>

      {/* Stats */}
      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Tổng hồ sơ nộp
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
            placeholder="Tìm theo tên, email, CCCD..."
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
                        Không tìm thấy hồ sơ KYC.
                      </TableCell>
                    </TableRow>
                  )}
                </TableBody>
              </Table>

              <Pagination
                page={page}
                totalPages={meta?.totalPages || 1}
                total={meta?.total || 0}
                itemLabel="hồ sơ"
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
              {reviewDialog.action === "approve" ? "Duyệt KYC" : "Từ chối KYC"}
            </DialogTitle>
            <DialogDescription>
              {reviewDialog.action === "approve"
                ? "Bạn có chắc muốn duyệt hồ sơ KYC này?"
                : "Vui lòng nhập lý do từ chối."}
            </DialogDescription>
          </DialogHeader>

          {reviewDialog.action === "reject" && (
            <div className="space-y-2">
              <Label>Lý do từ chối</Label>
              <Textarea
                placeholder="Nhập lý do từ chối..."
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

      {/* KYC Detail Dialog */}
      <Dialog
        open={!!selectedKyc && !reviewDialog.open}
        onOpenChange={(open) => !open && setSelectedKyc(null)}
      >
        <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Chi tiết xác minh KYC</DialogTitle>
          </DialogHeader>
          {selectedKyc && (
            <div className="space-y-6">
              {/* User Info */}
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <Avatar className="h-12 w-12">
                    <AvatarImage src={selectedKyc.user?.profile?.avatarUrl} />
                    <AvatarFallback>
                      {selectedKyc.user?.profile?.fullName?.charAt(0)}
                    </AvatarFallback>
                  </Avatar>
                  <div>
                    <p className="font-medium">{selectedKyc.user?.profile?.fullName}</p>
                    <p className="text-sm text-muted-foreground">
                      {selectedKyc.user?.email}
                    </p>
                  </div>
                </div>
                <KycStatusBadge status={selectedKyc.status} />
              </div>

              {/* ID Card Info */}
              <div className="grid gap-4 md:grid-cols-2">
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Tên trên CCCD</p>
                  <p className="font-medium">{selectedKyc.idCardName}</p>
                </div>
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Số CCCD</p>
                  <p className="font-mono">{selectedKyc.idCardNumber}</p>
                </div>
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Ngày sinh</p>
                  <p>{selectedKyc.idCardDob ? format(new Date(selectedKyc.idCardDob), "dd/MM/yyyy") : "N/A"}</p>
                </div>
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Giới tính</p>
                  <p>{selectedKyc.idCardGender}</p>
                </div>
                <div className="md:col-span-2">
                  <p className="text-sm font-medium text-muted-foreground">Địa chỉ</p>
                  <p>{selectedKyc.idCardAddress}</p>
                </div>
              </div>

              {/* Images */}
              <div>
                <p className="mb-3 text-sm font-medium text-muted-foreground">
                  Tài liệu đã nộp
                </p>
                <div className="grid gap-4 md:grid-cols-3">
                  <div className="space-y-2">
                    <p className="text-sm">Mặt trước CCCD</p>
                    <div className="aspect-[16/10] overflow-hidden rounded-lg border bg-muted">
                      {selectedKyc.idCardFrontUrl?.trim() ? (
                        <img
                          src={selectedKyc.idCardFrontUrl}
                          alt="ID Front"
                          className="h-full w-full object-cover"
                        />
                      ) : (
                        <div className="flex h-full items-center justify-center">
                          <ImageIcon className="h-8 w-8 text-muted-foreground" />
                        </div>
                      )}
                    </div>
                  </div>
                  <div className="space-y-2">
                    <p className="text-sm">Mặt sau CCCD</p>
                    <div className="aspect-[16/10] overflow-hidden rounded-lg border bg-muted">
                      {selectedKyc.idCardBackUrl?.trim() ? (
                        <img
                          src={selectedKyc.idCardBackUrl}
                          alt="ID Back"
                          className="h-full w-full object-cover"
                        />
                      ) : (
                        <div className="flex h-full items-center justify-center">
                          <ImageIcon className="h-8 w-8 text-muted-foreground" />
                        </div>
                      )}
                    </div>
                  </div>
                  <div className="space-y-2">
                    <p className="text-sm">Ảnh chân dung</p>
                    <div className="aspect-square overflow-hidden rounded-lg border bg-muted">
                      {selectedKyc.selfieUrl?.trim() ? (
                        <img
                          src={selectedKyc.selfieUrl}
                          alt="Selfie"
                          className="h-full w-full object-cover"
                        />
                      ) : (
                        <div className="flex h-full items-center justify-center">
                          <ImageIcon className="h-8 w-8 text-muted-foreground" />
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              </div>

              {/* AI Scores */}
              <div>
                <p className="mb-3 text-sm font-medium text-muted-foreground">
                  Điểm xác minh AI
                </p>
                <div className="grid gap-4 md:grid-cols-3">
                  <Card>
                    <CardContent className="pt-4">
                      <p className="text-sm text-muted-foreground">Điểm liveness</p>
                      <p className="text-2xl font-bold">
                        {(parseFloat(String(selectedKyc.livenessScore || 0)) * 100).toFixed(0)}%
                      </p>
                    </CardContent>
                  </Card>
                  <Card>
                    <CardContent className="pt-4">
                      <p className="text-sm text-muted-foreground">Khớp khuôn mặt</p>
                      <p className="text-2xl font-bold">
                        {(parseFloat(String(selectedKyc.faceMatchScore || 0)) * 100).toFixed(0)}%
                      </p>
                    </CardContent>
                  </Card>
                  <Card>
                    <CardContent className="pt-4">
                      <p className="text-sm text-muted-foreground">Độ tin cậy OCR</p>
                      <p className="text-2xl font-bold">
                        {(parseFloat(String(selectedKyc.ocrConfidence || 0)) * 100).toFixed(0)}%
                      </p>
                    </CardContent>
                  </Card>
                </div>
              </div>

              {/* Rejection Reason */}
              {selectedKyc.status === KycStatus.REJECTED && selectedKyc.rejectionReason && (
                <div className="rounded-lg border border-destructive/50 bg-destructive/10 p-4">
                  <p className="text-sm font-medium text-destructive">Lý do từ chối</p>
                  <p className="mt-1">{selectedKyc.rejectionReason}</p>
                </div>
              )}

              {/* Actions for pending */}
              {selectedKyc.status === KycStatus.PENDING && (
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
                    Duyệt
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
