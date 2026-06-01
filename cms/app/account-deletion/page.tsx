import type { Metadata } from "next";
import Link from "next/link";

import { Button } from "@/components/ui/button";

export const metadata: Metadata = {
  title: "Yêu cầu xóa tài khoản | MiMate",
  description:
    "Trang chính thức để người dùng MiMate gửi yêu cầu xóa tài khoản và xem cách xử lý dữ liệu liên quan.",
  openGraph: {
    title: "Yêu cầu xóa tài khoản | MiMate",
    description:
      "Hướng dẫn xóa tài khoản MiMate, liên hệ hỗ trợ và thông tin xử lý dữ liệu sau khi xóa.",
  },
};

export default function AccountDeletionPage() {
  return (
    <div className="min-h-screen bg-background">
      <header className="border-b">
        <div className="container mx-auto px-4 py-4">
          <h1 className="text-lg font-semibold">Yêu cầu xóa tài khoản</h1>
          <p className="text-sm text-muted-foreground mt-1">MiMate (Mate Social)</p>
        </div>
      </header>

      <main className="container mx-auto px-4 py-8 max-w-3xl text-foreground">
        <p className="text-sm text-muted-foreground mb-8 leading-relaxed">
          Trang này cung cấp cách thức chính thức để bạn yêu cầu xóa tài khoản MiMate. Nếu
          bạn đang gửi link này cho Google Play Console, hãy dùng chính URL của trang này
          trong mục Account deletion link.
        </p>

        <section className="space-y-4 mb-10">
          <h2 className="text-base font-semibold">1. Cách xóa tài khoản trong ứng dụng</h2>
          <p className="text-sm leading-relaxed text-muted-foreground">
            Nếu bạn vẫn đăng nhập được, mở ứng dụng MiMate rồi vào <strong>Hồ sơ</strong> →
            <strong> Cài đặt</strong> → <strong>Xóa tài khoản</strong>. Hệ thống sẽ yêu cầu
            xác nhận bằng mật khẩu trước khi xử lý xóa.
          </p>
        </section>

        <section className="space-y-4 mb-10">
          <h2 className="text-base font-semibold">2. Nếu không thể truy cập ứng dụng</h2>
          <p className="text-sm leading-relaxed text-muted-foreground">
            Bạn có thể gửi email đến bộ phận hỗ trợ để yêu cầu xóa tài khoản. Vui lòng ghi rõ
            email hoặc số điện thoại đã dùng để đăng ký tài khoản để chúng tôi xác minh và
            xử lý nhanh hơn.
          </p>
          <div className="flex flex-wrap gap-3">
            <Button asChild>
              <a href="mailto:ngocbinhan8888@gmail.com?subject=Yeu%20cau%20xoa%20tai%20khoan%20MiMate">
                Gửi email yêu cầu xóa tài khoản
              </a>
            </Button>
            <Button variant="outline" asChild>
              <Link href="/support">Trang hỗ trợ</Link>
            </Button>
          </div>
        </section>

        <section className="space-y-4 mb-10">
          <h2 className="text-base font-semibold">3. Dữ liệu sau khi xóa</h2>
          <p className="text-sm leading-relaxed text-muted-foreground">
            Khi yêu cầu hợp lệ được xác nhận, tài khoản sẽ được xử lý xóa theo cơ chế của hệ
            thống: phiên đăng nhập bị thu hồi, thông tin cá nhân được ẩn danh và dữ liệu gắn
            với tài khoản sẽ không còn được sử dụng cho mục đích vận hành bình thường của ứng
            dụng.
          </p>
        </section>

        <section className="space-y-4 mb-10">
          <h2 className="text-base font-semibold">4. Thông tin liên hệ</h2>
          <p className="text-sm leading-relaxed text-muted-foreground">
            Email hỗ trợ: <a className="text-primary underline underline-offset-2" href="mailto:ngocbinhan8888@gmail.com">ngocbinhan8888@gmail.com</a>
          </p>
          <p className="text-sm leading-relaxed text-muted-foreground">
            Nếu cần hỗ trợ thêm, bạn có thể xem <Link href="/support" className="text-primary underline underline-offset-2">trang hỗ trợ chính thức</Link> của MiMate.
          </p>
        </section>
      </main>
    </div>
  );
}