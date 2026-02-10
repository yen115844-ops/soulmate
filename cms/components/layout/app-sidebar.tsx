"use client";

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import {
    Collapsible,
    CollapsibleContent,
    CollapsibleTrigger,
} from "@/components/ui/collapsible";
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
    Sidebar,
    SidebarContent,
    SidebarFooter,
    SidebarGroup,
    SidebarGroupContent,
    SidebarGroupLabel,
    SidebarHeader,
    SidebarMenu,
    SidebarMenuButton,
    SidebarMenuItem,
    SidebarMenuSub,
    SidebarMenuSubButton,
    SidebarMenuSubItem,
} from "@/components/ui/sidebar";
import { useAuthStore } from "@/stores/auth-store";
import {
    BarChart3,
    Bell,
    Briefcase,
    Calendar,
    ChevronDown,
    Database,
    FileText,
    Globe,
    Heart,
    LayoutDashboard,
    LogOut,
    MapPin,
    Settings,
    ShieldCheck,
    Sparkles,
    UserCheck,
    Users,
} from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";

const mainMenuItems = [
  { title: "Tổng quan", icon: LayoutDashboard, href: "/dashboard" },
  { title: "Thống kê", icon: BarChart3, href: "/dashboard/statistics" },
  { title: "Người dùng", icon: Users, href: "/dashboard/users" },
  { title: "Đối tác", icon: UserCheck, href: "/dashboard/partners" },
  { title: "Đặt chỗ", icon: Calendar, href: "/dashboard/bookings" },
  { title: "Xác minh KYC", icon: ShieldCheck, href: "/dashboard/kyc" },
  { title: "Thông báo", icon: Bell, href: "/dashboard/notifications" },
];

const masterDataItems = [
  { title: "Loại dịch vụ", icon: Briefcase, href: "/dashboard/master-data/service-types" },
  { title: "Tỉnh & Quận/Huyện", icon: MapPin, href: "/dashboard/master-data/locations" },
  { title: "Sở thích", icon: Heart, href: "/dashboard/master-data/interests" },
  { title: "Tài năng", icon: Sparkles, href: "/dashboard/master-data/talents" },
  { title: "Ngôn ngữ", icon: Globe, href: "/dashboard/master-data/languages" },
];

export function AppSidebar() {
  const pathname = usePathname();
  const { user, logout } = useAuthStore();

  const isActive = (href: string) => {
    if (href === "/dashboard") {
      return pathname === "/dashboard";
    }
    return pathname.startsWith(href);
  };

  return (
    <Sidebar>
      <SidebarHeader className="border-b">
        <div className="flex items-center gap-2 px-4 py-3">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary text-primary-foreground">
            <span className="text-lg font-bold">M</span>
          </div>
          <div className="flex flex-col">
            <span className="text-sm font-semibold">Mate Social</span>
            <span className="text-xs text-muted-foreground">Quản trị CMS</span>
          </div>
        </div>
      </SidebarHeader>

      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupLabel>Menu chính</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              {mainMenuItems.map((item) => (
                <SidebarMenuItem key={item.href}>
                  <SidebarMenuButton
                    asChild
                    isActive={isActive(item.href)}
                  >
                    <Link href={item.href}>
                      <item.icon className="h-4 w-4" />
                      <span>{item.title}</span>
                    </Link>
                  </SidebarMenuButton>
                </SidebarMenuItem>
              ))}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>

        <SidebarGroup>
          <SidebarGroupLabel>Dữ liệu gốc</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              <Collapsible defaultOpen className="group/collapsible">
                <SidebarMenuItem>
                  <CollapsibleTrigger asChild>
                    <SidebarMenuButton>
                      <Database className="h-4 w-4" />
                      <span>Dữ liệu gốc</span>
                      <ChevronDown className="ml-auto h-4 w-4 transition-transform group-data-[state=open]/collapsible:rotate-180" />
                    </SidebarMenuButton>
                  </CollapsibleTrigger>
                  <CollapsibleContent>
                    <SidebarMenuSub>
                      {masterDataItems.map((item) => (
                        <SidebarMenuSubItem key={item.href}>
                          <SidebarMenuSubButton
                            asChild
                            isActive={isActive(item.href)}
                          >
                            <Link href={item.href}>
                              <item.icon className="h-4 w-4" />
                              <span>{item.title}</span>
                            </Link>
                          </SidebarMenuSubButton>
                        </SidebarMenuSubItem>
                      ))}
                    </SidebarMenuSub>
                  </CollapsibleContent>
                </SidebarMenuItem>
              </Collapsible>
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>

        <SidebarGroup>
          <SidebarGroupLabel>Hệ thống</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              <SidebarMenuItem>
                <SidebarMenuButton
                  asChild
                  isActive={isActive("/dashboard/terms")}
                >
                  <Link href="/dashboard/terms">
                    <FileText className="h-4 w-4" />
                    <span>Điều khoản</span>
                  </Link>
                </SidebarMenuButton>
              </SidebarMenuItem>
              <SidebarMenuItem>
                <SidebarMenuButton
                  asChild
                  isActive={isActive("/dashboard/settings")}
                >
                  <Link href="/dashboard/settings">
                    <Settings className="h-4 w-4" />
                    <span>Cài đặt</span>
                  </Link>
                </SidebarMenuButton>
              </SidebarMenuItem>
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>

      <SidebarFooter className="border-t">
        <SidebarMenu>
          <SidebarMenuItem>
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <SidebarMenuButton className="w-full">
                  <Avatar className="h-6 w-6">
                    <AvatarImage src={user?.profile?.avatarUrl} />
                    <AvatarFallback>
                      {user?.profile?.fullName?.charAt(0) || "A"}
                    </AvatarFallback>
                  </Avatar>
                  <span className="truncate">
                    {user?.profile?.fullName || user?.email || "Admin"}
                  </span>
                  <ChevronDown className="ml-auto h-4 w-4" />
                </SidebarMenuButton>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="start" className="w-56">
                <DropdownMenuItem onClick={() => logout()}>
                  <LogOut className="mr-2 h-4 w-4" />
                  <span>Đăng xuất</span>
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarFooter>
    </Sidebar>
  );
}
