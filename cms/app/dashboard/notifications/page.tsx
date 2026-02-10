"use client";

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
    DropdownMenuCheckboxItem,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Pagination } from "@/components/ui/pagination";
import { ScrollArea } from "@/components/ui/scroll-area";
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
import { Textarea } from "@/components/ui/textarea";
import {
    GetNotificationsParams,
    notificationsApi,
    SendNotificationDto,
} from "@/lib/api/notifications";
import { usersApi } from "@/lib/api/users";
import { Notification, NotificationStats, NotificationType, User } from "@/types";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { formatDistanceToNow } from "date-fns";
import { vi } from "date-fns/locale";
import {
    Bell,
    Calendar,
    CheckCircle2,
    ChevronDown,
    Clock,
    MailCheck,
    MailX,
    MessageSquare,
    MoreHorizontal,
    Plus,
    Search,
    Send,
    Trash2,
    Users,
    XCircle,
} from "lucide-react";
import { useEffect, useState } from "react";
import { toast } from "sonner";

const SEARCH_DEBOUNCE_MS = 400;

function useDebouncedValue<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);
  useEffect(() => {
    const timer = setTimeout(() => setDebouncedValue(value), delay);
    return () => clearTimeout(timer);
  }, [value, delay]);
  return debouncedValue;
}

// Notification type badge
function NotificationTypeBadge({ type }: { type: NotificationType }) {
  const variants: Record<
    NotificationType,
    { variant: "default" | "secondary" | "destructive" | "outline"; className?: string; label: string }
  > = {
    [NotificationType.BOOKING]: { variant: "default", className: "bg-blue-500", label: "Đặt chỗ" },
    [NotificationType.CHAT]: { variant: "default", className: "bg-purple-500", label: "Chat" },
    [NotificationType.PAYMENT]: { variant: "default", className: "bg-green-500", label: "Thanh toán" },
    [NotificationType.SYSTEM]: { variant: "secondary", label: "Hệ thống" },
    [NotificationType.SAFETY]: { variant: "destructive", label: "An toàn" },
    [NotificationType.REVIEW]: { variant: "outline", className: "border-yellow-500 text-yellow-600", label: "Đánh giá" },
  };

  const config = variants[type] || { variant: "secondary", label: type };
  return (
    <Badge variant={config.variant} className={config.className}>
      {config.label}
    </Badge>
  );
}

// Stat card component
function StatCard({
  title,
  value,
  description,
  icon: Icon,
}: {
  title: string;
  value: string | number;
  description?: string;
  icon: React.ComponentType<{ className?: string }>;
}) {
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">
          {title}
        </CardTitle>
        <Icon className="h-4 w-4 text-muted-foreground" />
      </CardHeader>
      <CardContent>
        <div className="text-2xl font-bold">{value}</div>
        {description && (
          <p className="text-xs text-muted-foreground">{description}</p>
        )}
      </CardContent>
    </Card>
  );
}

function StatCardSkeleton() {
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <Skeleton className="h-4 w-24" />
        <Skeleton className="h-4 w-4" />
      </CardHeader>
      <CardContent>
        <Skeleton className="h-8 w-20" />
        <Skeleton className="mt-1 h-3 w-32" />
      </CardContent>
    </Card>
  );
}

// Send notification dialog
function SendNotificationDialog({
  open,
  onOpenChange,
  isBroadcast = false,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  isBroadcast?: boolean;
}) {
  const queryClient = useQueryClient();
  const [formData, setFormData] = useState<SendNotificationDto>({
    title: "",
    body: "",
    type: NotificationType.SYSTEM,
    sendPush: true,
    userIds: [],
  });
  const [selectedUsers, setSelectedUsers] = useState<User[]>([]);
  const [userSearch, setUserSearch] = useState("");
  const [recipientsOpen, setRecipientsOpen] = useState(false);
  const debouncedSearch = useDebouncedValue(userSearch, SEARCH_DEBOUNCE_MS);

  // Fetch users when recipients dropdown is opened, với search đã debounce để tránh gọi API mỗi lần gõ
  const { data: usersData, isLoading: usersLoading } = useQuery({
    queryKey: ["users-for-recipients", debouncedSearch],
    queryFn: () => usersApi.getUsers({ search: debouncedSearch.trim() || undefined, limit: 100 }),
    enabled: !isBroadcast && recipientsOpen,
  });

  const users: User[] = (usersData as any)?.data?.data || (usersData as any)?.data || [];
  const selectedUserIds = new Set(selectedUsers.map((u) => u.id));
  const toggleUser = (user: User) => {
    setSelectedUsers((prev) =>
      prev.some((u) => u.id === user.id)
        ? prev.filter((u) => u.id !== user.id)
        : [...prev, user]
    );
  };
  const selectAllVisible = () => {
    const toAdd = users.filter((u) => !selectedUsers.some((s) => s.id === u.id));
    setSelectedUsers((prev) => [...prev, ...toAdd]);
  };
  const clearSelection = () => setSelectedUsers([]);

  // Send mutation
  const sendMutation = useMutation({
    mutationFn: (data: SendNotificationDto) =>
      isBroadcast
        ? notificationsApi.broadcastNotification(data)
        : notificationsApi.sendNotification(data),
    onSuccess: (response) => {
      const result = (response as any)?.data || response;
      toast.success(
        isBroadcast
          ? `Đã gửi broadcast đến ${result.sentCount} người dùng`
          : `Đã gửi thông báo đến ${result.sentCount} người dùng`
      );
      queryClient.invalidateQueries({ queryKey: ["notifications"] });
      queryClient.invalidateQueries({ queryKey: ["notification-stats"] });
      onOpenChange(false);
      resetForm();
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || "Gửi thông báo thất bại");
    },
  });

  const resetForm = () => {
    setFormData({
      title: "",
      body: "",
      type: NotificationType.SYSTEM,
      sendPush: true,
      userIds: [],
    });
    setSelectedUsers([]);
    setUserSearch("");
    setRecipientsOpen(false);
  };

  const handleSend = () => {
    if (!formData.title.trim() || !formData.body.trim()) {
      toast.error("Vui lòng nhập tiêu đề và nội dung");
      return;
    }

    if (!isBroadcast && selectedUsers.length === 0) {
      toast.error("Vui lòng chọn ít nhất một người nhận");
      return;
    }

    sendMutation.mutate({
      ...formData,
      userIds: isBroadcast ? undefined : selectedUsers.map((u) => u.id),
    });
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle>
            {isBroadcast ? "Gửi thông báo broadcast" : "Gửi thông báo"}
          </DialogTitle>
          <DialogDescription>
            {isBroadcast
              ? "Gửi thông báo đến tất cả người dùng đang hoạt động"
              : "Gửi thông báo đến người dùng cụ thể"}
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="title">Tiêu đề *</Label>
            <Input
              id="title"
              placeholder="Tiêu đề thông báo"
              value={formData.title}
              onChange={(e) =>
                setFormData({ ...formData, title: e.target.value })
              }
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="body">Nội dung *</Label>
            <Textarea
              id="body"
              placeholder="Nội dung thông báo"
              rows={3}
              value={formData.body}
              onChange={(e) =>
                setFormData({ ...formData, body: e.target.value })
              }
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>Loại</Label>
              <Select
                value={formData.type}
                onValueChange={(value) =>
                  setFormData({ ...formData, type: value as NotificationType })
                }
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {Object.values(NotificationType).map((type) => (
                    <SelectItem key={type} value={type}>
                      {type}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label>Gửi push</Label>
              <div className="flex items-center space-x-2 pt-2">
                <Switch
                  checked={formData.sendPush}
                  onCheckedChange={(checked) =>
                    setFormData({ ...formData, sendPush: checked })
                  }
                />
                <span className="text-sm text-muted-foreground">
                  {formData.sendPush ? "Có" : "Không"}
                </span>
              </div>
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="imageUrl">URL ảnh (tùy chọn)</Label>
            <Input
              id="imageUrl"
              placeholder="https://example.com/image.png"
              value={formData.imageUrl || ""}
              onChange={(e) =>
                setFormData({ ...formData, imageUrl: e.target.value || undefined })
              }
            />
          </div>

          {!isBroadcast && (
            <div className="space-y-2">
              <Label>Người nhận *</Label>
              <DropdownMenu open={recipientsOpen} onOpenChange={setRecipientsOpen}>
                <DropdownMenuTrigger asChild>
                  <Button
                    variant="outline"
                    role="combobox"
                    className="w-full justify-between font-normal"
                  >
                    <span className="truncate">
                      {selectedUsers.length === 0
                        ? "Chọn một hoặc nhiều người dùng..."
                        : `Đã chọn ${selectedUsers.length} người dùng`}
                    </span>
                    <ChevronDown className="ml-2 h-4 w-4 shrink-0 opacity-50" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="start" className="w-[var(--radix-dropdown-menu-trigger-width)] p-0">
                  <div className="p-2 border-b">
                    <Input
                      placeholder="Tìm theo tên hoặc email..."
                      value={userSearch}
                      onChange={(e) => setUserSearch(e.target.value)}
                      className="h-8"
                      onClick={(e) => e.stopPropagation()}
                    />
                    <div className="flex gap-1 mt-2">
                      <Button
                        variant="ghost"
                        size="sm"
                        className="h-7 text-xs flex-1"
                        onClick={(e) => {
                          e.preventDefault();
                          selectAllVisible();
                        }}
                      >
                        Chọn tất cả
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        className="h-7 text-xs flex-1"
                        onClick={(e) => {
                          e.preventDefault();
                          clearSelection();
                        }}
                      >
                        Xóa chọn
                      </Button>
                    </div>
                  </div>
                  <DropdownMenuSeparator />
                  <ScrollArea className="h-[200px]">
                    {usersLoading ? (
                      <div className="flex items-center justify-center py-6">
                        <Skeleton className="h-4 w-24" />
                      </div>
                    ) : users.length === 0 ? (
                      <div className="py-6 text-center text-sm text-muted-foreground">
                        Không tìm thấy người dùng
                      </div>
                    ) : (
                      users.map((user) => (
                        <DropdownMenuCheckboxItem
                          key={user.id}
                          checked={selectedUserIds.has(user.id)}
                          onSelect={(e) => {
                            e.preventDefault();
                            toggleUser(user);
                          }}
                        >
                          <div className="flex items-center gap-2 min-w-0">
                            <Avatar className="h-6 w-6 shrink-0">
                              <AvatarImage src={user.profile?.avatarUrl} />
                              <AvatarFallback className="text-xs">
                                {user.profile?.fullName?.charAt(0) || user.email?.charAt(0) || "?"}
                              </AvatarFallback>
                            </Avatar>
                            <div className="min-w-0 flex-1 truncate">
                              <p className="text-sm font-medium truncate">
                                {user.profile?.fullName || "No Name"}
                              </p>
                              <p className="text-xs text-muted-foreground truncate">
                                {user.email}
                              </p>
                            </div>
                          </div>
                        </DropdownMenuCheckboxItem>
                      ))
                    )}
                  </ScrollArea>
                </DropdownMenuContent>
              </DropdownMenu>

              {selectedUsers.length > 0 && (
                <div className="flex flex-wrap gap-2">
                  {selectedUsers.map((user) => (
                    <Badge
                      key={user.id}
                      variant="secondary"
                      className="gap-1 pr-1"
                    >
                      {user.profile?.fullName || user.email}
                      <button
                        type="button"
                        onClick={() =>
                          setSelectedUsers((prev) => prev.filter((u) => u.id !== user.id))
                        }
                        className="rounded-full hover:bg-muted ml-0.5 p-0.5"
                      >
                        <XCircle className="h-3 w-3" />
                      </button>
                    </Badge>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Hủy
          </Button>
          <Button onClick={handleSend} disabled={sendMutation.isPending}>
            {sendMutation.isPending ? (
              "Đang gửi..."
            ) : (
              <>
                <Send className="mr-2 h-4 w-4" />
                {isBroadcast ? "Gửi broadcast" : "Gửi"}
              </>
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

export default function NotificationsPage() {
  const queryClient = useQueryClient();
  const [filters, setFilters] = useState<GetNotificationsParams>({
    page: 1,
    limit: 10,
    sortBy: "createdAt",
    sortOrder: "desc",
  });
  const [searchQuery, setSearchQuery] = useState("");
  const [sendDialogOpen, setSendDialogOpen] = useState(false);
  const [broadcastDialogOpen, setBroadcastDialogOpen] = useState(false);

  // Fetch stats
  const { data: stats, isLoading: statsLoading } = useQuery({
    queryKey: ["notification-stats"],
    queryFn: () => notificationsApi.getStats(),
  });

  // Fetch notifications
  const { data: notificationsData, isLoading: notificationsLoading } = useQuery({
    queryKey: ["notifications", filters],
    queryFn: () => notificationsApi.getNotifications(filters),
  });

  // Delete mutation
  const deleteMutation = useMutation({
    mutationFn: (id: string) => notificationsApi.deleteNotification(id),
    onSuccess: () => {
      toast.success("Đã xóa thông báo");
      queryClient.invalidateQueries({ queryKey: ["notifications"] });
      queryClient.invalidateQueries({ queryKey: ["notification-stats"] });
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || "Xóa thông báo thất bại");
    },
  });

  const notifications: Notification[] =
    (notificationsData as any)?.data?.data ||
    (notificationsData as any)?.data ||
    [];
  const meta = (notificationsData as any)?.data?.meta ||
    (notificationsData as any)?.meta || {
      page: 1,
      limit: 10,
      total: 0,
      totalPages: 0,
    };

  const handleSearch = () => {
    setFilters({ ...filters, search: searchQuery, page: 1 });
  };

  const handleFilterChange = (key: string, value: any) => {
    setFilters({ ...filters, [key]: value === "all" ? undefined : value, page: 1 });
  };

  const notificationStats: NotificationStats = (stats as any) || {
    total: 0,
    unread: 0,
    read: 0,
    byType: [],
    today: 0,
    thisWeek: 0,
    thisMonth: 0,
  };

  const pushQueue = notificationStats.pushQueue;
  const hasPushError = pushQueue?.lastError || (pushQueue?.failedCount ?? 0) > 0;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Thông báo</h1>
          <p className="text-muted-foreground">
            Quản lý và gửi thông báo đến người dùng
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => setSendDialogOpen(true)}>
            <Plus className="mr-2 h-4 w-4" />
            Gửi cho người dùng
          </Button>
          <Button onClick={() => setBroadcastDialogOpen(true)}>
            <Users className="mr-2 h-4 w-4" />
            Gửi broadcast
          </Button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {statsLoading ? (
          Array.from({ length: 4 }).map((_, i) => <StatCardSkeleton key={i} />)
        ) : (
          <>
            <StatCard
              title="Tổng thông báo"
              value={notificationStats.total.toLocaleString()}
              description={`${notificationStats.today} hôm nay`}
              icon={Bell}
            />
            <StatCard
              title="Chưa đọc"
              value={notificationStats.unread.toLocaleString()}
              description={`${notificationStats.read} đã đọc`}
              icon={MailX}
            />
            <StatCard
              title="Tuần này"
              value={notificationStats.thisWeek.toLocaleString()}
              icon={Calendar}
            />
            <StatCard
              title="Tháng này"
              value={notificationStats.thisMonth.toLocaleString()}
              icon={Clock}
            />
          </>
        )}
      </div>

      {/* Push queue status / last error (production VPS) */}
      {!statsLoading && pushQueue && (
        <Card className={hasPushError ? "border-destructive/50 bg-destructive/5" : "border-muted"}>
          <CardHeader className="pb-2">
            <CardTitle className="text-base flex items-center gap-2">
              <Send className="h-4 w-4" />
              Trạng thái hàng đợi push
            </CardTitle>
          </CardHeader>
          <CardContent className="pt-0 text-sm text-muted-foreground">
            <div className="flex flex-wrap gap-4">
              <span>Đang chờ: {pushQueue.waitingCount}</span>
              <span>Thất bại: {pushQueue.failedCount}</span>
              {pushQueue.lastErrorAt && (
                <span>Lỗi gần nhất: {new Date(pushQueue.lastErrorAt).toLocaleString("vi-VN")}</span>
              )}
            </div>
            {pushQueue.lastError && (
              <p className="mt-2 rounded-md bg-destructive/10 p-2 font-mono text-destructive text-xs break-all">
                {pushQueue.lastError}
              </p>
            )}
          </CardContent>
        </Card>
      )}

      {/* Filters */}
      <Card>
        <CardHeader>
          <CardTitle>Danh sách thông báo</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-wrap gap-4 mb-4">
            <div className="flex gap-2 flex-1 min-w-[300px]">
              <Input
                placeholder="Tìm theo tiêu đề, nội dung hoặc người dùng..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && handleSearch()}
              />
              <Button variant="secondary" onClick={handleSearch}>
                <Search className="h-4 w-4" />
              </Button>
            </div>

            <Select
              value={filters.type || "all"}
              onValueChange={(value) => handleFilterChange("type", value)}
            >
              <SelectTrigger className="w-[150px]">
                <SelectValue placeholder="Loại" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Tất cả loại</SelectItem>
                {Object.values(NotificationType).map((type) => (
                  <SelectItem key={type} value={type}>
                    {type}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>

            <Select
              value={filters.isRead === undefined ? "all" : String(filters.isRead)}
              onValueChange={(value) =>
                handleFilterChange(
                  "isRead",
                  value === "all" ? undefined : value === "true"
                )
              }
            >
              <SelectTrigger className="w-[150px]">
                <SelectValue placeholder="Trạng thái đọc" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Tất cả</SelectItem>
                <SelectItem value="true">Đã đọc</SelectItem>
                <SelectItem value="false">Chưa đọc</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Table */}
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Người dùng</TableHead>
                  <TableHead>Loại</TableHead>
                  <TableHead>Tiêu đề</TableHead>
                  <TableHead>Trạng thái</TableHead>
                  <TableHead>Thời gian</TableHead>
                  <TableHead className="w-[50px]"></TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {notificationsLoading ? (
                  Array.from({ length: 5 }).map((_, i) => (
                    <TableRow key={i}>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <Skeleton className="h-8 w-8 rounded-full" />
                          <div>
                            <Skeleton className="h-4 w-24 mb-1" />
                            <Skeleton className="h-3 w-32" />
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>
                        <Skeleton className="h-5 w-16" />
                      </TableCell>
                      <TableCell>
                        <Skeleton className="h-4 w-40 mb-1" />
                        <Skeleton className="h-3 w-56" />
                      </TableCell>
                      <TableCell>
                        <Skeleton className="h-5 w-12" />
                      </TableCell>
                      <TableCell>
                        <Skeleton className="h-4 w-20" />
                      </TableCell>
                      <TableCell>
                        <Skeleton className="h-8 w-8" />
                      </TableCell>
                    </TableRow>
                  ))
                ) : notifications.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} className="text-center py-8">
                      <MessageSquare className="h-8 w-8 mx-auto text-muted-foreground mb-2" />
                      <p className="text-muted-foreground">Không có thông báo</p>
                    </TableCell>
                  </TableRow>
                ) : (
                  notifications.map((notification) => (
                    <TableRow key={notification.id}>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <Avatar className="h-8 w-8">
                            <AvatarImage
                              src={notification.user?.profile?.avatarUrl}
                            />
                            <AvatarFallback>
                              {notification.user?.profile?.fullName?.charAt(0) ||
                                notification.user?.email?.charAt(0) ||
                                "U"}
                            </AvatarFallback>
                          </Avatar>
                          <div className="min-w-0">
                            <p className="font-medium text-sm truncate max-w-[150px]">
                              {notification.user?.profile?.fullName || "Unknown"}
                            </p>
                            <p className="text-xs text-muted-foreground truncate max-w-[150px]">
                              {notification.user?.email}
                            </p>
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>
                        <NotificationTypeBadge type={notification.type} />
                      </TableCell>
                      <TableCell>
                        <div className="max-w-[300px]">
                          <p className="font-medium text-sm truncate">
                            {notification.title}
                          </p>
                          <p className="text-xs text-muted-foreground truncate">
                            {notification.body}
                          </p>
                        </div>
                      </TableCell>
                      <TableCell>
                        {notification.isRead ? (
                          <Badge
                            variant="outline"
                            className="border-green-500 text-green-600"
                          >
                            <CheckCircle2 className="h-3 w-3 mr-1" />
                            Đã đọc
                          </Badge>
                        ) : (
                          <Badge variant="secondary">
                            <MailCheck className="h-3 w-3 mr-1" />
                            Chưa đọc
                          </Badge>
                        )}
                      </TableCell>
                      <TableCell>
                        <span className="text-sm text-muted-foreground">
                          {formatDistanceToNow(new Date(notification.createdAt), {
                            addSuffix: true,
                            locale: vi,
                          })}
                        </span>
                      </TableCell>
                      <TableCell>
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" size="icon">
                              <MoreHorizontal className="h-4 w-4" />
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="end">
                            <DropdownMenuItem
                              className="text-destructive"
                              onClick={() =>
                                deleteMutation.mutate(notification.id)
                              }
                            >
                              <Trash2 className="mr-2 h-4 w-4" />
                              Xóa
                            </DropdownMenuItem>
                          </DropdownMenuContent>
                        </DropdownMenu>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>

          <Pagination
            page={filters.page || 1}
            totalPages={meta.totalPages || 1}
            total={meta.total || 0}
            itemLabel="thông báo"
            onPageChange={(page) => setFilters({ ...filters, page })}
            showWhenSinglePage={false}
          />
        </CardContent>
      </Card>

      {/* Dialogs */}
      <SendNotificationDialog
        open={sendDialogOpen}
        onOpenChange={setSendDialogOpen}
        isBroadcast={false}
      />
      <SendNotificationDialog
        open={broadcastDialogOpen}
        onOpenChange={setBroadcastDialogOpen}
        isBroadcast={true}
      />
    </div>
  );
}
