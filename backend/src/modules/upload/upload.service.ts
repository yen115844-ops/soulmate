import {
    BadRequestException,
    Injectable,
    Logger,
    NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
    existsSync,
    mkdirSync,
    readFileSync,
    statSync,
    unlinkSync,
    writeFileSync,
} from 'fs';
import { basename, join } from 'path';
import sharp from 'sharp';

// Magic bytes for common image formats
const IMAGE_MAGIC_BYTES: Record<
  string,
  { bytes: number[]; offset?: number }[]
> = {
  'image/jpeg': [{ bytes: [0xff, 0xd8, 0xff] }],
  'image/png': [{ bytes: [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a] }],
  'image/gif': [{ bytes: [0x47, 0x49, 0x46, 0x38] }],
  'image/webp': [
    { bytes: [0x52, 0x49, 0x46, 0x46], offset: 0 },
    { bytes: [0x57, 0x45, 0x42, 0x50], offset: 8 },
  ],
};

@Injectable()
export class UploadService {
  private readonly logger = new Logger(UploadService.name);
  private readonly uploadDir = join(process.cwd(), 'uploads');
  private readonly apiPrefix: string;

  constructor(private readonly configService: ConfigService) {
    const rawPrefix = this.configService.get<string>('API_PREFIX', 'api');
    this.apiPrefix = rawPrefix.replace(/^\/+|\/+$/g, '') || 'api';

    // Ensure upload directory exists
    if (!existsSync(this.uploadDir)) {
      mkdirSync(this.uploadDir, { recursive: true });
    }
  }

  /**
   * Validate file magic bytes match the claimed mime type
   */
  validateMagicBytes(file: Express.Multer.File): void {
    const filePath = this.resolveFilePath(file);
    if (!existsSync(filePath)) return;

    const buffer = readFileSync(filePath);
    if (buffer.length < 12) {
      this.deleteFile(file.filename);
      throw new BadRequestException('File is too small to be a valid image');
    }

    let isValid = false;
    for (const [, signatures] of Object.entries(IMAGE_MAGIC_BYTES)) {
      const allMatch = signatures.every((sig) => {
        const offset = sig.offset || 0;
        return sig.bytes.every((byte, i) => buffer[offset + i] === byte);
      });
      if (allMatch) {
        isValid = true;
        break;
      }
    }

    if (!isValid) {
      this.deleteFile(file.filename);
      throw new BadRequestException(
        'File content does not match a valid image format. Only JPEG, PNG, GIF, and WebP are allowed.',
      );
    }
  }

  /**
   * Optimize image in-place to reduce payload while preserving visual quality.
   */
  async optimizeImage(
    file: Express.Multer.File,
    options?: { maxWidth?: number; maxHeight?: number; quality?: number },
  ): Promise<{ size: number }> {
    const filePath = this.resolveFilePath(file);
    if (!existsSync(filePath)) {
      throw new NotFoundException('Uploaded file not found for optimization');
    }

    const maxWidth = options?.maxWidth ?? 1600;
    const maxHeight = options?.maxHeight ?? 1600;
    const quality = options?.quality ?? 82;

    // GIF optimization is skipped to avoid breaking animation frames.
    const lowerMime = (file.mimetype || '').toLowerCase();
    if (lowerMime.includes('gif')) {
      return { size: statSync(filePath).size };
    }

    let pipeline = sharp(filePath).rotate().resize({
      width: maxWidth,
      height: maxHeight,
      fit: 'inside',
      withoutEnlargement: true,
    });

    if (lowerMime.includes('png')) {
      pipeline = pipeline.png({
        quality,
        compressionLevel: 9,
        adaptiveFiltering: true,
      });
    } else if (lowerMime.includes('webp')) {
      pipeline = pipeline.webp({ quality });
    } else {
      pipeline = pipeline.jpeg({ quality, mozjpeg: true });
    }

    const optimized = await pipeline.toBuffer();
    writeFileSync(filePath, optimized);
    file.size = optimized.length;

    return { size: optimized.length };
  }

  /**
   * Get the public URL for an uploaded file
   */
  getFileUrl(filename: string): string {
    return `/${this.apiPrefix}/upload/files/${filename}`;
  }

  /**
   * Get the absolute file path (for serving)
   */
  getFilePath(filename: string): string {
    // Prevent path traversal
    const sanitized = filename.replace(/[^a-zA-Z0-9._-]/g, '');
    const filePath = join(this.uploadDir, sanitized);
    if (!existsSync(filePath)) {
      throw new NotFoundException('File not found');
    }
    return filePath;
  }

  /**
   * Delete a file from storage
   */
  deleteFile(filename: string): boolean {
    try {
      const filePath = join(this.uploadDir, filename);
      if (existsSync(filePath)) {
        unlinkSync(filePath);
        this.logger.log(`Deleted file: ${filename}`);
        return true;
      }
      return false;
    } catch (error) {
      this.logger.error(`Error deleting file ${filename}:`, error);
      return false;
    }
  }

  /**
   * Delete a file by URL path like /api/upload/files/{filename}
   */
  deleteFileByUrl(url?: string | null): boolean {
    const filename = this.extractFilenameFromUrl(url);
    if (!filename) return false;
    return this.deleteFile(filename);
  }

  /**
   * Process uploaded files — validate magic bytes and return URLs
   */
  processUploadedFiles(files: Express.Multer.File[]): string[] {
    for (const file of files) {
      this.validateMagicBytes(file);
    }
    return files.map((file) => this.getFileUrl(file.filename));
  }

  private resolveFilePath(file: Express.Multer.File): string {
    const filePath = (file as Express.Multer.File & { path?: string }).path;
    if (filePath && existsSync(filePath)) {
      return filePath;
    }
    return join(this.uploadDir, file.filename);
  }

  private extractFilenameFromUrl(url?: string | null): string | null {
    if (!url) return null;
    const marker = `/${this.apiPrefix}/upload/files/`;
    const normalized = url.trim();

    if (!normalized.includes(marker)) return null;

    const raw = normalized.split(marker).pop();
    if (!raw) return null;

    // Ignore query/hash segments and sanitize.
    const cleaned = raw.split('?')[0].split('#')[0];
    const base = basename(cleaned);
    const sanitized = base.replace(/[^a-zA-Z0-9._-]/g, '');
    return sanitized || null;
  }
}
