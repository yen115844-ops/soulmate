"use client";

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Separator } from "@/components/ui/separator";
import { Skeleton } from "@/components/ui/skeleton";
import { SidebarTrigger } from "@/components/ui/sidebar";
import { notificationsApi } from "@/lib/api/notifications";
import { Notification, NotificationType } from "@/types";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { formatDistanceToNow } from "date-fns";
import { vi } from "date-fns/locale";
import { Bell, CheckCheck, Moon, Sun } from "lucide-react";
import Link from "next/link";
import { useState } from "react";
import { useTheme } from "next-themes";

interface AppHeaderProps {
  title?: string;
}

// Notification type icon/label
function getNotificationTypeInfo(type: NotificationType) {
  const map: Record<NotificationType, string> = {
    [NotificationType.BOOKING]: "📅",
    [NotificationType.CHAT]: "💬",
    [NotificationType.PAYMENT]: "💰",
    [NotificationType.SYSTEM]: "🔔",
    [NotificationType.SAFETY]: "🛡️",
    [NotificationType.REVIEW]: "⭐",
  };
  return map[type] || "📌";
}

export function AppHeader({ title }: AppHeaderProps) {
  const { setTheme } = useTheme();
  const queryClient = useQueryClient();
  const [notificationsOpen, setNotificationsOpen] = useState(false);

  // Fetch unread count
  const { data: unreadData } = useQuery({
    queryKey: ["notification-unread-count"],
    queryFn: () => notificationsApi.getUnreadCount(),
    refetchInterval: 60000, // Refetch every minute
  });

  // Fetch recent notifications only when dropdown opens
  const { data: notificationsData, isLoading: notificationsLoading } = useQuery({
    queryKey: ["header-notifications"],
    queryFn: () => notificationsApi.getMyNotifications({ limit: 10 }),
    enabled: notificationsOpen,
  });

  const markAllReadMutation = useMutation({
    mutationFn: () => notificationsApi.markAllAsRead(),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["notification-unread-count"] });
      queryClient.invalidateQueries({ queryKey: ["header-notifications"] });
    },
  });

  const unreadCount = (unreadData as any)?.unreadCount ?? 0;
  const rawNotifications =
    (notificationsData as any)?.data ?? (notificationsData as any)?.data?.data;
  const notifications: Notification[] = Array.isArray(rawNotifications)
    ? rawNotifications
    : [];
  const meta = (notificationsData as any)?.meta || {};
  const displayUnreadCount = meta.unreadCount ?? unreadCount;

  return (
    <header className="sticky top-0 z-50 flex h-14 shrink-0 items-center gap-2 border-b bg-background px-4">
      <SidebarTrigger className="-ml-1" />
      <Separator orientation="vertical" className="mr-2 h-4" />

      {title && <h1 className="text-lg font-semibold">{title}</h1>}

      <div className="ml-auto flex items-center gap-2">
        {/* Notifications dropdown */}
        <DropdownMenu open={notificationsOpen} onOpenChange={setNotificationsOpen}>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="icon" className="relative">
              <Bell className="h-5 w-5" />
              {unreadCount > 0 && (
                <span className="absolute -right-1 -top-1 flex h-4 w-4 min-w-4 items-center justify-center rounded-full bg-destructive px-1 text-[10px] font-medium text-destructive-foreground">
                  {unreadCount > 99 ? "99+" : unreadCount}
                </span>
              )}
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-80">
            <div className="flex items-center justify-between px-2 py-2">
              <h4 className="font-semibold">Thông báo</h4>
              {displayUnreadCount > 0 && (
                <Button
                  variant="ghost"
                  size="sm"
                  className="h-auto py-1 text-xs"
                  onClick={() => markAllReadMutation.mutate()}
                  disabled={markAllReadMutation.isPending}
                >
                  <CheckCheck className="mr-1 h-3 w-3" />
                  Đánh dấu đã đọc
                </Button>
              )}
            </div>
            <Separator />
            <ScrollArea className="h-[300px]">
              {notificationsLoading ? (
                <div className="space-y-2 p-2">
                  {Array.from({ length: 3 }).map((_, i) => (
                    <div key={i} className="flex gap-3 rounded-lg p-2">
                      <Skeleton className="h-10 w-10 shrink-0 rounded-full" />
                      <div className="flex-1 space-y-2">
                        <Skeleton className="h-4 w-full" />
                        <Skeleton className="h-3 w-3/4" />
                      </div>
                    </div>
                  ))}
                </div>
              ) : notifications.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-8 text-center">
                  <Bell className="mb-2 h-10 w-10 text-muted-foreground" />
                  <p className="text-sm text-muted-foreground">
                    Không có thông báo
                  </p>
                </div>
              ) : (
                <div className="space-y-0">
                  {notifications.map((notif) => (
                    <DropdownMenuItem
                      key={notif.id}
                      asChild
                      className="flex cursor-pointer flex-col items-start gap-0.5 p-3"
                    >
                      <Link
                        href="/dashboard/notifications"
                        className="flex w-full gap-3 text-left"
                      >
                        <Avatar className="h-9 w-9 shrink-0">
                          {notif.imageUrl ? (
                            <AvatarImage src={notif.imageUrl} />
                          ) : null}
                          <AvatarFallback className="text-xs">
                            {getNotificationTypeInfo(notif.type)}
                          </AvatarFallback>
                        </Avatar>
                        <div className="min-w-0 flex-1">
                          <p
                            className={`text-sm ${!notif.isRead ? "font-semibold" : ""}`}
                          >
                            {notif.title}
                          </p>
                          <p className="line-clamp-2 text-xs text-muted-foreground">
                            {notif.body}
                          </p>
                          <p className="mt-1 text-xs text-muted-foreground">
                            {formatDistanceToNow(new Date(notif.createdAt), {
                              addSuffix: true,
                              locale: vi,
                            })}
                          </p>
                        </div>
                      </Link>
                    </DropdownMenuItem>
                  ))}
                </div>
              )}
            </ScrollArea>
            <Separator />
            <DropdownMenuItem asChild>
              <Link
                href="/dashboard/notifications"
                className="flex w-full justify-center py-2"
              >
                Xem tất cả thông báo
              </Link>
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>

        {/* Theme toggle */}
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="icon">
              <Sun className="h-5 w-5 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
              <Moon className="absolute h-5 w-5 rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
              <span className="sr-only">Chuyển giao diện</span>
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuItem onClick={() => setTheme("light")}>
              Sáng
            </DropdownMenuItem>
            <DropdownMenuItem onClick={() => setTheme("dark")}>
              Tối
            </DropdownMenuItem>
            <DropdownMenuItem onClick={() => setTheme("system")}>
              Theo hệ thống
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </header>
  );
}
