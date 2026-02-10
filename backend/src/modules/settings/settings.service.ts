import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../database/prisma/prisma.service';
import { AppSettingsResponseDto } from './dto';

@Injectable()
export class SettingsService {
  private readonly logger = new Logger(SettingsService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Get single setting value by key. Returns null if not found.
   */
  async getValue(key: string): Promise<string | null> {
    const row = await this.prisma.appSetting.findUnique({
      where: { key },
    });
    return row?.value ?? null;
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

## 6. Liên hệ
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
    }
    this.logger.log(`Updated ${keys.length} app settings: ${keys.join(', ')}`);
    return this.getAll();
  }
}
