import { BadRequestException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { existsSync, mkdirSync, readFileSync, unlinkSync } from 'fs';
import { join } from 'path';

// Magic bytes for common image formats
const IMAGE_MAGIC_BYTES: Record<string, { bytes: number[]; offset?: number }[]> = {
  'image/jpeg': [{ bytes: [0xff, 0xd8, 0xff] }],
  'image/png': [{ bytes: [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a] }],
  'image/gif': [{ bytes: [0x47, 0x49, 0x46, 0x38] }],
  'image/webp': [{ bytes: [0x52, 0x49, 0x46, 0x46], offset: 0 }, { bytes: [0x57, 0x45, 0x42, 0x50], offset: 8 }],
};

@Injectable()
export class UploadService {
  private readonly logger = new Logger(UploadService.name);
  private readonly uploadDir = join(process.cwd(), 'uploads');

  constructor() {
    // Ensure upload directory exists
    if (!existsSync(this.uploadDir)) {
      mkdirSync(this.uploadDir, { recursive: true });
    }
  }

  /**
   * Validate file magic bytes match the claimed mime type
   */
  validateMagicBytes(file: Express.Multer.File): void {
    const filePath = join(this.uploadDir, file.filename);
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
   * Get the public URL for an uploaded file
   */
  getFileUrl(filename: string): string {
    return `/api/upload/files/${filename}`;
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
   * Process uploaded files — validate magic bytes and return URLs
   */
  processUploadedFiles(files: Express.Multer.File[]): string[] {
    for (const file of files) {
      this.validateMagicBytes(file);
    }
    return files.map((file) => this.getFileUrl(file.filename));
  }
}
