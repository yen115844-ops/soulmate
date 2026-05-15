import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Tiêu chuẩn an toàn trẻ em & chống CSAE | MiMate",
  description:
    "Tiêu chuẩn công khai của MiMate về phòng chống bóc lột và xâm hại tình dục trẻ em (CSAE), báo cáo và xử lý vi phạm.",
  openGraph: {
    title: "Tiêu chuẩn an toàn trẻ em & chống CSAE | MiMate",
    description:
      "Cam kết không dung túng CSAE; biện pháp kỹ thuật, vận hành và kênh báo cáo của MiMate.",
  },
};

export default function ChildSafetyPage() {
  return (
    <div className="min-h-screen bg-background">
      <header className="border-b">
        <div className="container mx-auto px-4 py-4">
          <h1 className="text-lg font-semibold">
            Tiêu chuẩn an toàn trẻ em &amp; chống CSAE
          </h1>
          <p className="text-sm text-muted-foreground mt-1">MiMate (Mate Social)</p>
        </div>
      </header>

      <main className="container mx-auto px-4 py-8 max-w-3xl text-foreground">
        <p className="text-sm text-muted-foreground mb-8">
          Trang này là tài liệu công khai theo yêu cầu của các nền tảng phân phối ứng dụng
          (ví dụ Google Play) về tiêu chuẩn ứng dụng nhằm ngăn chặn hành vi bóc lột và xâm hại
          tình dục trẻ em (Child Sexual Abuse and Exploitation — CSAE). Cập nhật lần cuối:{" "}
          <time dateTime="2026-05-15">15/05/2026</time>.
        </p>

        <section className="space-y-4 mb-10">
          <h2 className="text-base font-semibold">1. Cam kết chung</h2>
          <p className="text-sm leading-relaxed text-muted-foreground">
            MiMate là nền tảng kết nối hoạt động xã hội lành mạnh. Chúng tôi không dung túng
            bất kỳ nội dung, hành vi hoặc mối quan hệ nào liên quan đến lạm dục, khai thác hoặc
            gợi ý tình dục đối với trẻ em hoặc vị thành niên. Mọi báo cáo liên quan đến an toàn
            trẻ em được ưu tiên xử lý.
          </p>
        </section>

        <section className="space-y-4 mb-10">
          <h2 className="text-base font-semibold">2. Đối tượng sử dụng &amp; độ tuổi</h2>
          <p className="text-sm leading-relaxed text-muted-foreground">
            Ứng dụng được thiết kế cho người trưởng thành theo độ tuổi tối thiểu được ghi nhận trên
            cửa hàng ứng dụng và trong Điều khoản sử dụng. Chúng tôi không chấp nhận hồ sơ hoặc
            tương tác nhằm mục đích tiếp cận trẻ em; hành vi grooming, yêu cầu ảnh/video nhạy cảm
            hoặc gặp gỡ có tính chất tình dục với người chưa đủ tuổi thành niên bị cấm và sẽ bị
            xử lý nghiêm.
          </p>
        </section>

        <section className="space-y-4 mb-10">
          <h2 className="text-base font-semibold">3. Biện pháp phòng ngừa CSAE</h2>
          <ul className="list-disc pl-5 space-y-2 text-sm leading-relaxed text-muted-foreground">
            <li>
              <strong className="text-foreground">Xác minh &amp; hồ sơ:</strong> các lớp xác thực
              (ví dụ selfie/liveness) và quy tắc cộng đồng nhằm giảm tài khoản ẩn danh lạm dụng.
            </li>
            <li>
              <strong className="text-foreground">Kiểm soát nội dung:</strong> kiểm duyệt, lọc
              và can thiệp đối với tin nhắn, hình ảnh và bài đăng công khai khi phát hiện vi phạm
              hoặc theo báo cáo của người dùng.
            </li>
            <li>
              <strong className="text-foreground">Báo cáo &amp; chặn:</strong> người dùng có thể
              báo cáo hồ sơ, tin nhắn và nội dung không phù hợp; có thể chặn người dùng khác để
              ngăn liên lạc tiếp.
            </li>
            <li>
              <strong className="text-foreground">An toàn khi gặp mặt:</strong> tính năng SOS và
              tài liệu hướng dẫn an toàn nhằm hỗ trợ người dùng trong tình huống khẩn cấp hoặc
              hoạt động ngoài đời thực.
            </li>
            <li>
              <strong className="text-foreground">Đào tạo nội bộ:</strong> đội kiểm duyệt và hỗ trợ
              được hướng dẫn ưu tiên các báo cáo liên quan đến trẻ em, CSAE và bạo lực.
            </li>
          </ul>
        </section>

        <section className="space-y-4 mb-10">
          <h2 className="text-base font-semibold">4. Phản hồi báo cáo &amp; thực thi</h2>
          <p className="text-sm leading-relaxed text-muted-foreground">
            Khi nhận báo cáo liên quan CSAE hoặc an toàn trẻ em, chúng tôi xem xét theo mức độ
            khẩn cấp, có thể khóa tài khoản, gỡ nội dung, giới hạn tính năng và bảo lưu dữ liệu
            cần thiết theo pháp luật hiện hành. Trong trường hợp có dấu hiệu hình sự hoặc theo
            yêu cầu cơ quan có thẩm quyền, chúng tôi phối hợp cung cấp thông tin theo quy trình pháp
            lý.
          </p>
        </section>

        <section className="space-y-4 mb-10">
          <h2 className="text-base font-semibold">5. Cách báo cáo (ưu tiên an toàn trẻ em)</h2>
          <p className="text-sm leading-relaxed text-muted-foreground">
            Nếu bạn phát hiện nội dung hoặc hành vi nghi ngờ liên quan đến trẻ em hoặc CSAE trên
            MiMate:
          </p>
          <ul className="list-decimal pl-5 space-y-2 text-sm leading-relaxed text-muted-foreground">
            <li>
              Dùng chức năng <strong className="text-foreground">Báo cáo</strong> trong ứng dụng
              (hồ sơ, chat, bài đăng) và chọn lý do phù hợp, mô tả chi tiết nếu có thể.
            </li>
            <li>
              Gửi email đến kênh hỗ trợ được công bố tại{" "}
              <Link href="/support" className="text-primary underline underline-offset-2">
                trung tâm hỗ trợ
              </Link>{" "}
              với tiêu đề gợi ý: <em>[An toàn trẻ em / CSAE]</em> để đội ngũ ưu tiên tiếp nhận.
            </li>
          </ul>
        </section>

        <section className="space-y-4 mb-10">
          <h2 className="text-base font-semibold">6. Minh bạch &amp; cập nhật</h2>
          <p className="text-sm leading-relaxed text-muted-foreground">
            Chúng tôi có thể cập nhật trang này khi luật pháp, chính sách nền tảng hoặc tính năng
            sản phẩm thay đổi. Phiên bản mới có hiệu lực khi được đăng tại URL này. Các tài liệu
            liên quan:{" "}
            <Link href="/privacy-policy" className="text-primary underline underline-offset-2">
              Chính sách bảo mật
            </Link>
            ,{" "}
            <Link href="/terms-of-service" className="text-primary underline underline-offset-2">
              Điều khoản sử dụng
            </Link>
            .
          </p>
        </section>

        <section className="rounded-lg border bg-muted/30 p-4 text-sm text-muted-foreground">
          <p>
            <strong className="text-foreground">Lưu ý pháp lý:</strong> Trang này mô tả tiêu
            chuẩn và quy trình vận hành của MiMate; không thay thế tư vấn pháp lý. Trường hợp
            khẩn cấp hoặc tội phạm, vui lòng liên hệ ngay cơ quan chức năng tại địa phương bạn.
          </p>
        </section>
      </main>
    </div>
  );
}
