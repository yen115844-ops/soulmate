"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
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
import {
  statisticsApi,
  type StatisticsReport,
  type StatsOverview,
} from "@/lib/api/statistics";
import { useQuery } from "@tanstack/react-query";
import { format, subDays } from "date-fns";
import {
  Calendar,
  DollarSign,
  TrendingUp,
  Users,
  UserCheck,
  ShieldCheck,
  Briefcase,
} from "lucide-react";
import { useMemo, useState } from "react";
import {
  AreaChart,
  Area,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from "recharts";

const BOOKING_STATUS_LABELS: Record<string, string> = {
  PENDING: "Chờ xử lý",
  CONFIRMED: "Đã xác nhận",
  PAID: "Đã thanh toán",
  IN_PROGRESS: "Đang thực hiện",
  COMPLETED: "Hoàn thành",
  CANCELLED: "Đã hủy",
  DISPUTED: "Tranh chấp",
};

const CHART_COLORS = [
  "var(--chart-1)",
  "var(--chart-2)",
  "var(--chart-3)",
  "var(--chart-4)",
  "var(--chart-5)",
  "#22c55e",
  "#ef4444",
  "#f59e0b",
];

function formatCurrency(amount: number) {
  if (amount >= 1_000_000_000)
    return `₫${(amount / 1_000_000_000).toFixed(1)}B`;
  if (amount >= 1_000_000) return `₫${(amount / 1_000_000).toFixed(1)}M`;
  if (amount >= 1_000) return `₫${(amount / 1_000).toFixed(0)}K`;
  return new Intl.NumberFormat("vi-VN", {
    style: "currency",
    currency: "VND",
    maximumFractionDigits: 0,
  }).format(amount);
}

function formatNumber(n: number) {
  return new Intl.NumberFormat("vi-VN").format(n);
}

function StatCard({
  title,
  value,
  sub,
  icon: Icon,
}: {
  title: string;
  value: string;
  sub?: string;
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
        {sub && (
          <p className="text-xs text-muted-foreground mt-1">{sub}</p>
        )}
      </CardContent>
    </Card>
  );
}

function useReport(from: string, to: string, groupBy: "day" | "week" | "month") {
  return useQuery({
    queryKey: ["statistics-report", from, to, groupBy],
    queryFn: () =>
      statisticsApi.getFullReport({ from, to, groupBy }).then((r) => {
        const data = (r as { data?: StatisticsReport }).data ?? r;
        return data as StatisticsReport;
      }),
    enabled: !!from && !!to,
  });
}

export default function StatisticsPage() {
  const defaultTo = format(new Date(), "yyyy-MM-dd");
  const defaultFrom = format(subDays(new Date(), 30), "yyyy-MM-dd");
  const [from, setFrom] = useState(defaultFrom);
  const [to, setTo] = useState(defaultTo);
  const [groupBy, setGroupBy] = useState<"day" | "week" | "month">("day");

  const { data: report, isLoading, isError, error } = useReport(from, to, groupBy);

  const overview = report?.overview;
  const revenueChart = report?.revenueChart ?? [];
  const bookingsByStatus = report?.bookingsByStatus ?? [];
  const bookingsByServiceType = report?.bookingsByServiceType ?? [];
  const userGrowth = report?.userGrowth ?? [];
  const partnerGrowth = report?.partnerGrowth ?? [];
  const kycBreakdown = report?.kycBreakdown ?? [];
  const topPartners = report?.topPartnersByRevenue ?? [];
  const dateRange = report?.dateRange;

  const pieData = useMemo(
    () =>
      bookingsByStatus
        .filter((x) => x.count > 0)
        .map((x) => ({
          name: BOOKING_STATUS_LABELS[x.status] ?? x.status,
          value: x.count,
        })),
    [bookingsByStatus]
  );

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold">Thống kê chi tiết</h1>
          <p className="text-muted-foreground">
            Xem tổng quan và báo cáo theo khoảng thời gian
          </p>
        </div>
      </div>

      {/* Bộ lọc */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Calendar className="h-4 w-4" />
            Khoảng thời gian
          </CardTitle>
        </CardHeader>
        <CardContent className="flex flex-wrap gap-4">
          <div className="flex flex-col gap-2">
            <Label>Từ ngày</Label>
            <input
              type="date"
              value={from}
              onChange={(e) => setFrom(e.target.value)}
              className="flex h-9 w-[180px] rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors"
            />
          </div>
          <div className="flex flex-col gap-2">
            <Label>Đến ngày</Label>
            <input
              type="date"
              value={to}
              onChange={(e) => setTo(e.target.value)}
              className="flex h-9 w-[180px] rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors"
            />
          </div>
          <div className="flex flex-col gap-2">
            <Label>Nhóm theo</Label>
            <Select
              value={groupBy}
              onValueChange={(v: "day" | "week" | "month") => setGroupBy(v)}
            >
              <SelectTrigger className="w-[140px]">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="day">Theo ngày</SelectItem>
                <SelectItem value="week">Theo tuần</SelectItem>
                <SelectItem value="month">Theo tháng</SelectItem>
              </SelectContent>
            </Select>
          </div>
          {dateRange && (
            <p className="text-sm text-muted-foreground self-end">
              Dữ liệu: {format(new Date(dateRange.from), "dd/MM/yyyy")} –{" "}
              {format(new Date(dateRange.to), "dd/MM/yyyy")}
            </p>
          )}
        </CardContent>
      </Card>

      {isError && (
        <Card className="border-destructive">
          <CardContent className="py-4 text-destructive">
            {(error as Error)?.message ?? "Không tải được báo cáo."}
          </CardContent>
        </Card>
      )}

      {isLoading && (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          {Array.from({ length: 8 }).map((_, i) => (
            <Skeleton key={i} className="h-28 rounded-lg" />
          ))}
        </div>
      )}

      {report && overview && (
        <>
          {/* Tổng quan */}
          <div>
            <h2 className="text-lg font-semibold mb-4">Tổng quan kỳ</h2>
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
              <StatCard
                title="Người dùng"
                value={formatNumber(overview.users.total)}
                sub={`Hoạt động: ${formatNumber(overview.users.active)} · Chờ: ${formatNumber(overview.users.pending)}`}
                icon={Users}
              />
              <StatCard
                title="Đối tác"
                value={formatNumber(overview.partners.total)}
                sub={`Đang hoạt động: ${formatNumber(overview.partners.active)} · Sẵn sàng: ${formatNumber(overview.partners.available)}`}
                icon={UserCheck}
              />
              <StatCard
                title="Đặt chỗ"
                value={formatNumber(overview.bookings.total)}
                sub={`Hoàn thành: ${formatNumber(overview.bookings.completed)} · Hủy: ${formatNumber(overview.bookings.cancelled)}`}
                icon={Briefcase}
              />
              <StatCard
                title="Doanh thu (phí nền tảng)"
                value={formatCurrency(overview.bookings.totalRevenue)}
                sub={`Điểm TB đối tác: ${Number(overview.partners.averageRating).toFixed(1)}`}
                icon={DollarSign}
              />
              <StatCard
                title="KYC chờ duyệt"
                value={formatNumber(overview.kyc.pending)}
                sub={`Đã xác minh: ${formatNumber(overview.kyc.verified)} · Từ chối: ${formatNumber(overview.kyc.rejected)}`}
                icon={ShieldCheck}
              />
            </div>
          </div>

          <Tabs defaultValue="revenue" className="space-y-4">
            <TabsList className="grid w-full grid-cols-5 lg:w-auto lg:inline-grid">
              <TabsTrigger value="revenue">Doanh thu</TabsTrigger>
              <TabsTrigger value="bookings">Đặt chỗ</TabsTrigger>
              <TabsTrigger value="growth">Tăng trưởng</TabsTrigger>
              <TabsTrigger value="kyc">KYC</TabsTrigger>
              <TabsTrigger value="top-partners">Top đối tác</TabsTrigger>
            </TabsList>

            <TabsContent value="revenue" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <TrendingUp className="h-4 w-4" />
                    Doanh thu (phí nền tảng) theo thời gian
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  {revenueChart.length === 0 ? (
                    <p className="text-muted-foreground text-center py-8">
                      Không có dữ liệu doanh thu trong kỳ
                    </p>
                  ) : (
                    <div className="h-[320px]">
                      <ResponsiveContainer width="100%" height="100%">
                        <AreaChart data={revenueChart}>
                          <CartesianGrid strokeDasharray="3 3" />
                          <XAxis
                            dataKey="date"
                            tickFormatter={(v) =>
                              groupBy === "month"
                                ? format(new Date(v + "-01"), "MM/yyyy")
                                : format(new Date(v), "dd/MM")}
                          />
                          <YAxis
                            tickFormatter={(v) =>
                              v >= 1e6 ? `${v / 1e6}M` : v >= 1e3 ? `${v / 1e3}K` : v}
                          />
                          <Tooltip
                            formatter={(value: number | undefined) => [formatCurrency(value ?? 0), "Doanh thu"]}
                            labelFormatter={(label) =>
                              typeof label === "string"
                                ? format(new Date(label), "dd/MM/yyyy")
                                : label}
                          />
                          <Area
                            type="monotone"
                            dataKey="revenue"
                            stroke="var(--primary)"
                            fill="var(--primary)"
                            fillOpacity={0.3}
                          />
                        </AreaChart>
                      </ResponsiveContainer>
                    </div>
                  )}
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="bookings" className="space-y-4">
              <div className="grid gap-4 lg:grid-cols-2">
                <Card>
                  <CardHeader>
                    <CardTitle>Đặt chỗ theo trạng thái</CardTitle>
                  </CardHeader>
                  <CardContent>
                    {pieData.length === 0 ? (
                      <p className="text-muted-foreground text-center py-8">
                        Không có đặt chỗ trong kỳ
                      </p>
                    ) : (
                      <div className="h-[280px]">
                        <ResponsiveContainer width="100%" height="100%">
                          <PieChart>
                            <Pie
                              data={pieData}
                              dataKey="value"
                              nameKey="name"
                              cx="50%"
                              cy="50%"
                              outerRadius={90}
                              label={({ name, percent }) =>
                                `${name} ${((percent ?? 0) * 100).toFixed(0)}%`}
                            >
                              {pieData.map((_, i) => (
                                <Cell key={i} fill={CHART_COLORS[i % CHART_COLORS.length]} />
                              ))}
                            </Pie>
                            <Tooltip formatter={(v: number | undefined) => [formatNumber(v ?? 0), "Số lượng"]} />
                          </PieChart>
                        </ResponsiveContainer>
                      </div>
                    )}
                  </CardContent>
                </Card>
                <Card>
                  <CardHeader>
                    <CardTitle>Đặt chỗ theo trạng thái (cột)</CardTitle>
                  </CardHeader>
                  <CardContent>
                    {bookingsByStatus.length === 0 ? (
                      <p className="text-muted-foreground text-center py-8">
                        Không có dữ liệu
                      </p>
                    ) : (
                      <div className="h-[280px]">
                        <ResponsiveContainer width="100%" height="100%">
                          <BarChart
                            data={bookingsByStatus.map((x) => ({
                              ...x,
                              name: BOOKING_STATUS_LABELS[x.status] ?? x.status,
                            }))}
                          >
                            <CartesianGrid strokeDasharray="3 3" />
                            <XAxis dataKey="name" tick={{ fontSize: 11 }} />
                            <YAxis />
                            <Tooltip formatter={(v: number | undefined) => [formatNumber(v ?? 0), "Số lượng"]} />
                            <Bar dataKey="count" fill="var(--chart-1)" radius={4} />
                          </BarChart>
                        </ResponsiveContainer>
                      </div>
                    )}
                  </CardContent>
                </Card>
              </div>
              <Card>
                <CardHeader>
                  <CardTitle>Đặt chỗ theo loại dịch vụ</CardTitle>
                </CardHeader>
                <CardContent>
                  {bookingsByServiceType.length === 0 ? (
                    <p className="text-muted-foreground text-center py-6">
                      Không có dữ liệu trong kỳ
                    </p>
                  ) : (
                    <div className="overflow-x-auto">
                      <Table>
                        <TableHeader>
                          <TableRow>
                            <TableHead>Loại dịch vụ</TableHead>
                            <TableHead className="text-right">Số đặt chỗ</TableHead>
                            <TableHead className="text-right">Tổng giá trị</TableHead>
                          </TableRow>
                        </TableHeader>
                        <TableBody>
                          {bookingsByServiceType.map((row) => (
                            <TableRow key={row.serviceType}>
                              <TableCell className="font-medium capitalize">
                                {row.serviceType}
                              </TableCell>
                              <TableCell className="text-right">
                                {formatNumber(row.count)}
                              </TableCell>
                              <TableCell className="text-right">
                                {formatCurrency(row.totalAmount)}
                              </TableCell>
                            </TableRow>
                          ))}
                        </TableBody>
                      </Table>
                    </div>
                  )}
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="growth" className="space-y-4">
              <div className="grid gap-4 lg:grid-cols-2">
                <Card>
                  <CardHeader>
                    <CardTitle>Tăng trưởng người dùng mới</CardTitle>
                  </CardHeader>
                  <CardContent>
                    {userGrowth.length === 0 ? (
                      <p className="text-muted-foreground text-center py-8">
                        Không có dữ liệu trong kỳ
                      </p>
                    ) : (
                      <div className="h-[280px]">
                        <ResponsiveContainer width="100%" height="100%">
                          <BarChart data={userGrowth}>
                            <CartesianGrid strokeDasharray="3 3" />
                            <XAxis
                              dataKey="date"
                              tickFormatter={(v) =>
                                groupBy === "month"
                                  ? format(new Date(v + "-01"), "MM/yyyy")
                                  : format(new Date(v), "dd/MM")}
                            />
                            <YAxis />
                            <Tooltip
                              formatter={(v: number | undefined) => [formatNumber(v ?? 0), "Người dùng mới"]}
                              labelFormatter={(label) =>
                                typeof label === "string"
                                  ? format(new Date(label), "dd/MM/yyyy")
                                  : label}
                            />
                            <Bar dataKey="count" fill="var(--chart-2)" radius={4} />
                          </BarChart>
                        </ResponsiveContainer>
                      </div>
                    )}
                  </CardContent>
                </Card>
                <Card>
                  <CardHeader>
                    <CardTitle>Tăng trưởng đối tác mới</CardTitle>
                  </CardHeader>
                  <CardContent>
                    {partnerGrowth.length === 0 ? (
                      <p className="text-muted-foreground text-center py-8">
                        Không có dữ liệu trong kỳ
                      </p>
                    ) : (
                      <div className="h-[280px]">
                        <ResponsiveContainer width="100%" height="100%">
                          <BarChart data={partnerGrowth}>
                            <CartesianGrid strokeDasharray="3 3" />
                            <XAxis
                              dataKey="date"
                              tickFormatter={(v) =>
                                groupBy === "month"
                                  ? format(new Date(v + "-01"), "MM/yyyy")
                                  : format(new Date(v), "dd/MM")}
                            />
                            <YAxis />
                            <Tooltip
                              formatter={(v: number | undefined) => [formatNumber(v ?? 0), "Đối tác mới"]}
                              labelFormatter={(label) =>
                                typeof label === "string"
                                  ? format(new Date(label), "dd/MM/yyyy")
                                  : label}
                            />
                            <Bar dataKey="count" fill="var(--chart-3)" radius={4} />
                          </BarChart>
                        </ResponsiveContainer>
                      </div>
                    )}
                  </CardContent>
                </Card>
              </div>
            </TabsContent>

            <TabsContent value="kyc" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle>Phân bố KYC</CardTitle>
                </CardHeader>
                <CardContent>
                  {kycBreakdown.length === 0 ? (
                    <p className="text-muted-foreground text-center py-8">
                      Không có dữ liệu
                    </p>
                  ) : (
                    <div className="h-[280px]">
                      <ResponsiveContainer width="100%" height="100%">
                        <BarChart
                          layout="vertical"
                          data={kycBreakdown.map((x) => ({ ...x, name: x.label }))}
                          margin={{ left: 80 }}
                        >
                          <CartesianGrid strokeDasharray="3 3" />
                          <XAxis type="number" />
                          <YAxis type="category" dataKey="name" width={70} />
                          <Tooltip formatter={(v: number | undefined) => [formatNumber(v ?? 0), "Số lượng"]} />
                          <Bar dataKey="count" fill="var(--chart-4)" radius={4} />
                        </BarChart>
                      </ResponsiveContainer>
                    </div>
                  )}
                </CardContent>
              </Card>
              <Card>
                <CardHeader>
                  <CardTitle>Chi tiết KYC</CardTitle>
                </CardHeader>
                <CardContent>
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Trạng thái</TableHead>
                        <TableHead className="text-right">Số lượng</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {kycBreakdown.map((row) => (
                        <TableRow key={row.status}>
                          <TableCell>{row.label}</TableCell>
                          <TableCell className="text-right">
                            {formatNumber(row.count)}
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="top-partners" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle>Top đối tác theo doanh thu (kỳ đã chọn)</CardTitle>
                </CardHeader>
                <CardContent>
                  {topPartners.length === 0 ? (
                    <p className="text-muted-foreground text-center py-8">
                      Không có đặt chỗ hoàn thành trong kỳ
                    </p>
                  ) : (
                    <div className="overflow-x-auto">
                      <Table>
                        <TableHeader>
                          <TableRow>
                            <TableHead>#</TableHead>
                            <TableHead>Đối tác</TableHead>
                            <TableHead className="text-right">Số đặt chỗ</TableHead>
                            <TableHead className="text-right">Tổng doanh thu</TableHead>
                            <TableHead className="text-right">Phí nền tảng</TableHead>
                          </TableRow>
                        </TableHeader>
                        <TableBody>
                          {topPartners.map((row, i) => (
                            <TableRow key={row.partnerId}>
                              <TableCell className="font-medium">{i + 1}</TableCell>
                              <TableCell>{row.fullName}</TableCell>
                              <TableCell className="text-right">
                                {formatNumber(row.bookingCount)}
                              </TableCell>
                              <TableCell className="text-right">
                                {formatCurrency(row.totalRevenue)}
                              </TableCell>
                              <TableCell className="text-right">
                                {formatCurrency(row.platformFee)}
                              </TableCell>
                            </TableRow>
                          ))}
                        </TableBody>
                      </Table>
                    </div>
                  )}
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>
        </>
      )}

      {!report && !isLoading && !isError && (
        <p className="text-muted-foreground text-center py-8">
          Chọn khoảng thời gian và đợi tải báo cáo.
        </p>
      )}
    </div>
  );
}
