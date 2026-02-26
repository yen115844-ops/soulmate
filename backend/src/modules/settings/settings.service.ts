import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../database/prisma/prisma.service';
import { AppSettingsResponseDto } from './dto';

interface CacheEntry {
  value: string | null;
  expiresAt: number;
}

@Injectable()
export class SettingsService {
  private readonly logger = new Logger(SettingsService.name);
  private readonly cache = new Map<string, CacheEntry>();
  private readonly CACHE_TTL_MS = 60_000; // 1 minute

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Invalidate a setting from cache (call after update)
   */
  invalidateCache(key?: string) {
    if (key) {
      this.cache.delete(key);
    } else {
      this.cache.clear();
    }
  }

  /**
   * Get single setting value by key. Returns null if not found. Cached with TTL.
   */
  async getValue(key: string): Promise<string | null> {
    const now = Date.now();
    const cached = this.cache.get(key);
    if (cached && cached.expiresAt > now) {
      return cached.value;
    }

    const row = await this.prisma.appSetting.findUnique({
      where: { key },
    });
    const value = row?.value ?? null;
    this.cache.set(key, { value, expiresAt: now + this.CACHE_TTL_MS });
    return value;
  }

  /**
   * Get multiple setting values by keys. Returns Record<key, value> (only existing keys).
   */
  async getValues(keys: string[]): Promise<Record<string, string>> {
    if (keys.length === 0) return {};
    const rows = await this.prisma.appSetting.findMany({
      where: { key: { in: keys } },
    });
    const result: Record<string, string> = {};
    for (const row of rows) {
      result[row.key] = row.value;
    }
    return result;
  }

  /**
   * Get setting as number. Returns default if not found or invalid.
   */
  async getNumber(key: string, defaultValue: number): Promise<number> {
    const v = await this.getValue(key);
    if (v == null) return defaultValue;
    const n = parseInt(v, 10);
    return Number.isNaN(n) ? defaultValue : n;
  }

  /**
   * Get setting as boolean. "true", "1", "yes" => true; others => false.
   */
  async getBool(key: string, defaultValue: boolean): Promise<boolean> {
    const v = await this.getValue(key);
    if (v == null) return defaultValue;
    const lower = v.toLowerCase();
    return lower === 'true' || lower === '1' || lower === 'yes';
  }

  /**
   * Get all app settings as items and as key-value map (for CMS form binding).
   */
  async getAll(): Promise<AppSettingsResponseDto> {
    const rows = await this.prisma.appSetting.findMany({
      orderBy: { key: 'asc' },
    });
    const items = rows.map((r) => ({
      id: r.id,
      key: r.key,
      value: r.value,
      description: r.description ?? undefined,
    }));
    const values: Record<string, string> = {};
    for (const item of rows) {
      values[item.key] = item.value;
    }
    return { items, values };
  }

  /**
   * Get terms content by type. Returns default content if not found.
   */
  async getTermsContent(type: 'terms_of_service' | 'terms_and_conditions'): Promise<string> {
    const content = await this.getValue(type);
    if (content) return content;
    // Default content if not in DB
    return type === 'terms_of_service'
      ? this.getDefaultTermsOfService()
      : this.getDefaultTermsAndConditions();
  }

  /**
   * Get privacy policy content. Returns default content if not found.
   */
  async getPrivacyPolicyContent(): Promise<string> {
    const content = await this.getValue('privacy_policy');
    if (content) return content;
    return this.getDefaultPrivacyPolicy();
  }

  private getDefaultPrivacyPolicy(): string {
    return `# Chính sách bảo mật Mate Social

Cập nhật lần cuối: 01/01/2026

## 1. Giới thiệu

Mate Social ("chúng tôi", "của chúng tôi") cam kết bảo vệ quyền riêng tư của bạn. Chính sách bảo mật này giải thích cách chúng tôi thu thập, sử dụng, lưu trữ và bảo vệ thông tin cá nhân của bạn khi bạn sử dụng ứng dụng Mate Social.

## 2. Thông tin chúng tôi thu thập

Chúng tôi thu thập các loại thông tin sau:

a) Thông tin bạn cung cấp:
- Họ tên, ngày sinh, giới tính
- Số điện thoại, email
- Ảnh đại diện, ảnh xác minh danh tính
- Thông tin thanh toán (qua Apple/Google cho gói Premium)
- Nội dung tin nhắn, đánh giá

b) Thông tin tự động thu thập:
- Địa chỉ IP, loại thiết bị
- Vị trí địa lý (với sự đồng ý của bạn)
- Thông tin sử dụng ứng dụng
- Cookies và công nghệ theo dõi tương tự

c) Thông tin từ bên thứ ba:
- Thông tin từ mạng xã hội (nếu bạn đăng nhập qua MXH)
- Thông tin xác minh danh tính

## 3. Mục đích sử dụng thông tin

Chúng tôi sử dụng thông tin của bạn để:
- Cung cấp và cải thiện dịch vụ
- Xác minh danh tính và bảo mật tài khoản
- Xử lý thanh toán và giao dịch
- Gửi thông báo về dịch vụ
- Hỗ trợ khách hàng
- Phân tích và cải thiện trải nghiệm người dùng
- Phát hiện và ngăn chặn gian lận
- Tuân thủ quy định pháp luật

## 4. Chia sẻ thông tin

Chúng tôi có thể chia sẻ thông tin của bạn với:

- Người tham gia hoạt động: Tên, ảnh đại diện để kết nối hoạt động
- Đối tác thanh toán: Thông tin cần thiết để xử lý giao dịch Premium
- Nhà cung cấp dịch vụ: Bên thứ ba hỗ trợ vận hành ứng dụng
- Cơ quan pháp luật: Khi được yêu cầu theo quy định pháp luật

Chúng tôi không bán thông tin cá nhân của bạn cho bên thứ ba.

## 5. Bảo mật thông tin

Chúng tôi áp dụng các biện pháp bảo mật để bảo vệ thông tin của bạn:
- Mã hóa dữ liệu truyền tải (SSL/TLS)
- Mã hóa dữ liệu lưu trữ
- Xác thực hai yếu tố
- Kiểm soát truy cập nghiêm ngặt
- Giám sát bảo mật 24/7
- Đào tạo nhân viên về bảo mật

Tuy nhiên, không có phương pháp truyền tải qua Internet nào an toàn 100%.

## 6. Quyền của bạn

Bạn có các quyền sau đối với dữ liệu cá nhân:
- Quyền truy cập: Xem thông tin chúng tôi lưu trữ về bạn
- Quyền chỉnh sửa: Cập nhật thông tin không chính xác
- Quyền xóa: Yêu cầu xóa dữ liệu cá nhân
- Quyền hạn chế xử lý: Giới hạn cách chúng tôi sử dụng dữ liệu
- Quyền di chuyển dữ liệu: Nhận bản sao dữ liệu của bạn
- Quyền phản đối: Từ chối một số hoạt động xử lý dữ liệu

Để thực hiện các quyền này, liên hệ privacy@matesocial.vn

## 7. Lưu trữ dữ liệu

- Chúng tôi lưu trữ dữ liệu trong thời gian cần thiết để cung cấp dịch vụ
- Sau khi xóa tài khoản, dữ liệu sẽ được xóa trong vòng 30 ngày
- Một số dữ liệu có thể được giữ lại để tuân thủ pháp luật
- Dữ liệu được lưu trữ trên máy chủ tại Việt Nam

## 8. Thông tin trẻ em

Mate Social không dành cho người dưới 18 tuổi. Chúng tôi không cố ý thu thập thông tin từ trẻ em. Nếu phát hiện đã thu thập thông tin từ người dưới 18 tuổi, chúng tôi sẽ xóa ngay lập tức.

## 9. Cookies và công nghệ theo dõi

Chúng tôi sử dụng cookies và công nghệ tương tự để:
- Ghi nhớ thông tin đăng nhập
- Hiểu cách bạn sử dụng ứng dụng
- Cải thiện trải nghiệm người dùng
- Cung cấp quảng cáo phù hợp

Bạn có thể quản lý cookies trong cài đặt thiết bị.

## 10. Thay đổi chính sách

Chúng tôi có thể cập nhật chính sách này định kỳ. Khi có thay đổi quan trọng, chúng tôi sẽ thông báo qua ứng dụng hoặc email. Việc tiếp tục sử dụng dịch vụ sau khi thay đổi đồng nghĩa với việc bạn chấp nhận chính sách mới.

## 11. Liên hệ

Nếu bạn có câu hỏi về chính sách bảo mật này, vui lòng liên hệ:

Cán bộ bảo vệ dữ liệu (DPO)
- Email: privacy@matesocial.vn
- Hotline: 1900 1234
- Địa chỉ: Tầng 10, Tòa nhà ABC, Quận 1, TP.HCM
`;
  }

  private getDefaultTermsOfService(): string {
    return `# Điều khoản sử dụng Mate Social

## 1. Giới thiệu
Chào mừng bạn đến với Mate Social. Bằng việc truy cập và sử dụng ứng dụng Mate Social, bạn đồng ý tuân thủ các điều khoản và điều kiện sau đây.

Mate Social là nền tảng kết nối người dùng với các Partner (người đồng hành) để cung cấp các dịch vụ đồng hành xã hội như: cafe, ăn tối, xem phim, đi dạo, tham dự sự kiện, v.v.

## 2. Điều kiện sử dụng
Để sử dụng Mate Social, bạn cần:
- Từ 18 tuổi trở lên
- Cung cấp thông tin chính xác, đầy đủ khi đăng ký
- Không sử dụng dịch vụ cho mục đích bất hợp pháp
- Không vi phạm quyền của người khác
- Tuân thủ pháp luật Việt Nam

Chúng tôi có quyền từ chối hoặc chấm dứt tài khoản của bạn nếu vi phạm các điều khoản này.

## 3. Tài khoản người dùng
- Bạn chịu trách nhiệm bảo mật thông tin đăng nhập của mình
- Không được chia sẻ tài khoản với người khác
- Thông báo ngay cho chúng tôi nếu phát hiện truy cập trái phép
- Một người chỉ được sở hữu một tài khoản
- Tài khoản không hoạt động trong 12 tháng có thể bị vô hiệu hóa

## 4. Dịch vụ và thanh toán
- Giá dịch vụ được hiển thị rõ ràng trước khi đặt lịch
- Thanh toán được thực hiện qua các phương thức được hỗ trợ
- Phí hủy đặt lịch áp dụng theo chính sách được công bố
- Tiền hoàn trả sẽ được xử lý trong vòng 1-3 ngày làm việc
- Mate Social thu phí dịch vụ trên mỗi giao dịch theo chính sách hiện hành

## 5. Quy tắc ứng xử
Khi sử dụng Mate Social, bạn cam kết:
- Tôn trọng người khác
- Không có hành vi quấy rối, đe dọa
- Không đăng tải nội dung không phù hợp
- Không yêu cầu hoặc cung cấp dịch vụ bất hợp pháp
- Giữ an toàn cho bản thân và người khác
- Báo cáo các hành vi vi phạm qua kênh hỗ trợ

## 6. Nội dung do người dùng tạo và hành vi không chấp nhận (EULA – User-Generated Content)
Ứng dụng Mate Social cho phép người dùng tạo và chia sẻ nội dung (tin nhắn, đánh giá, ảnh, thông tin hồ sơ). Chúng tôi **không dung thứ** mọi nội dung phản cảm, xúc phạm, bạo lực, kỳ thị, quấy rối hoặc vi phạm pháp luật, cũng như mọi hành vi lạm dụng, lừa đảo hoặc gây hại cho người khác.

- **Bạn cam kết** không đăng tải, gửi hoặc chia sẻ nội dung vi phạm các chuẩn mực trên. Vi phạm có thể dẫn đến **cảnh cáo, tạm khóa tài khoản hoặc khóa vĩnh viễn** tùy mức độ, và có thể bị báo cáo cho cơ quan chức năng khi cần thiết.
- **Cơ chế báo cáo**: Nếu bạn phát hiện nội dung hoặc hành vi vi phạm, vui lòng sử dụng tính năng **Báo cáo** trong ứng dụng (trên hồ sơ người dùng, trong tin nhắn hoặc đặt lịch) hoặc liên hệ qua email/hotline hỗ trợ. Chúng tôi sẽ xem xét và xử lý trong thời gian sớm nhất.

Bằng việc sử dụng dịch vụ, bạn xác nhận đã đọc, hiểu và đồng ý với các điều khoản này.

## 7. Liên hệ
Nếu bạn có câu hỏi về các điều khoản này, vui lòng liên hệ:
- Email: legal@matesocial.vn
- Hotline: 1900 1234`;
  }

  private getDefaultTermsAndConditions(): string {
    return `# Điều kiện sử dụng Mate Social

## 1. Điều kiện chung
Việc sử dụng dịch vụ Mate Social đồng nghĩa với việc bạn chấp nhận đầy đủ các điều kiện sử dụng được quy định dưới đây. Vui lòng đọc kỹ trước khi sử dụng.

## 2. Điều kiện về độ tuổi
- Người dùng phải từ đủ 18 tuổi trở lên mới được sử dụng dịch vụ
- Bằng việc đăng ký, bạn xác nhận rằng mình đáp ứng điều kiện về độ tuổi
- Chúng tôi có quyền yêu cầu xác minh độ tuổi bất cứ lúc nào

## 3. Điều kiện về thông tin
- Bạn cam kết cung cấp thông tin chính xác, trung thực và đầy đủ
- Thông tin sai lệch có thể dẫn đến việc tài khoản bị khóa
- Bạn có trách nhiệm cập nhật thông tin khi có thay đổi

## 4. Điều kiện sử dụng dịch vụ
- Dịch vụ được cung cấp "nguyên trạng" theo khả năng hiện có
- Chúng tôi không đảm bảo dịch vụ không bị gián đoạn hoặc không có lỗi
- Bạn chịu trách nhiệm về việc sử dụng dịch vụ đúng mục đích
- Vi phạm điều kiện có thể dẫn đến chấm dứt tài khoản

## 5. Điều kiện thanh toán
- Thanh toán phải được thực hiện đúng hạn theo thông báo
- Phí dịch vụ và thuế (nếu có) được tính theo chính sách hiện hành
- Không hoàn lại phí đã thanh toán trừ khi có quy định khác
- Tranh chấp thanh toán sẽ được giải quyết theo quy định pháp luật

## 6. Điều kiện hủy và hoàn tiền
- Chính sách hủy đặt lịch áp dụng theo thời gian quy định
- Hoàn tiền được xử lý trong vòng 1-7 ngày làm việc
- Một số trường hợp có thể không được hoàn tiền theo chính sách

## 7. Giới hạn trách nhiệm
- Mate Social là nền tảng kết nối, không chịu trách nhiệm trực tiếp về chất lượng dịch vụ của Partner
- Chúng tôi không chịu trách nhiệm về thiệt hại gián tiếp
- Trách nhiệm tối đa không vượt quá số tiền bạn đã thanh toán trong 12 tháng gần nhất

## 8. Liên hệ
Mọi thắc mắc về điều kiện sử dụng, vui lòng liên hệ:
- Email: legal@matesocial.vn
- Hotline: 1900 1234`;
  }

  /**
   * Update multiple settings by key. Creates if key does not exist.
   */
  async updateValues(values: Record<string, string>): Promise<AppSettingsResponseDto> {
    const keys = Object.keys(values);
    for (const key of keys) {
      const value = String(values[key]);
      await this.prisma.appSetting.upsert({
        where: { key },
        update: { value },
        create: { key, value },
      });
      this.invalidateCache(key);
    }
    this.logger.log(`Updated ${keys.length} app settings: ${keys.join(', ')}`);
    return this.getAll();
  }
}
