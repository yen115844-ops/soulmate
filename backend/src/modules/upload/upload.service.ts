import { Injectable, Logger } from '@nestjs/common';
import { existsSync, mkdirSync, unlinkSync } from 'fs';
import { join } from 'path';

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
   * Get the public URL for an uploaded file
   */
  getFileUrl(filename: string): string {
    // In production, this would be a CDN URL or cloud storage URL
    return `/uploads/${filename}`;
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
   * Process uploaded files and return URLs
   */
  processUploadedFiles(files: Express.Multer.File[]): string[] {
    return files.map((file) => this.getFileUrl(file.filename));
  }
}
