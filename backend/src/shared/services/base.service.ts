import { Injectable, Logger } from '@nestjs/common';
import { PaginatedResponseDto, PaginationDto } from '../../common/dto/pagination.dto';
import { PrismaService } from '../../database/prisma/prisma.service';

/**
 * Base service with common CRUD operations
 * Extend this class for specific model services
 */
@Injectable()
export abstract class BaseService<
  T,
  CreateDto,
  UpdateDto,
> {
  protected readonly logger = new Logger(this.constructor.name);

  constructor(protected readonly prisma: PrismaService) {}

  /**
   * Get the Prisma model delegate for the entity
   * Must be implemented by child classes
   */
  protected abstract get model(): any;

  /**
   * Get default include relations for queries
   * Override in child classes as needed
   */
  protected get defaultInclude(): Record<string, any> | undefined {
    return undefined;
  }

  /**
   * Get default select fields for queries
   * Override in child classes as needed
   */
  protected get defaultSelect(): Record<string, any> | undefined {
    return undefined;
  }

  /**
   * Create a new record
   */
  async create(data: CreateDto): Promise<T> {
    return this.model.create({
      data,
      include: this.defaultInclude,
    });
  }

  /**
   * Find all records with pagination
   */
  async findAll(
    paginationDto: PaginationDto,
    where?: Record<string, any>,
    orderBy?: Record<string, any>,
  ): Promise<PaginatedResponseDto<T>> {
    const { page = 1, limit = 10 } = paginationDto;
    const skip = (page - 1) * limit;

    const [data, total] = await Promise.all([
      this.model.findMany({
        where,
        skip,
        take: limit,
        orderBy: orderBy || { createdAt: 'desc' },
        include: this.defaultInclude,
      }),
      this.model.count({ where }),
    ]);

    const totalPages = Math.ceil(total / limit);

    return {
      data,
      meta: {
        total,
        page,
        limit,
        totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1,
      },
    };
  }

  /**
   * Find one record by ID
   */
  async findById(id: string): Promise<T | null> {
    return this.model.findUnique({
      where: { id },
      include: this.defaultInclude,
    });
  }

  /**
   * Find one record by conditions
   */
  async findOne(where: Record<string, any>): Promise<T | null> {
    return this.model.findFirst({
      where,
      include: this.defaultInclude,
    });
  }

  /**
   * Update a record by ID
   */
  async update(id: string, data: UpdateDto): Promise<T> {
    return this.model.update({
      where: { id },
      data,
      include: this.defaultInclude,
    });
  }

  /**
   * Delete a record by ID (hard delete)
   */
  async delete(id: string): Promise<T> {
    return this.model.delete({
      where: { id },
    });
  }

  /**
   * Soft delete a record by ID
   * Requires the model to have a deletedAt field
   */
  async softDelete(id: string): Promise<T> {
    return this.model.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }

  /**
   * Restore a soft deleted record
   */
  async restore(id: string): Promise<T> {
    return this.model.update({
      where: { id },
      data: { deletedAt: null },
    });
  }

  /**
   * Check if a record exists
   */
  async exists(where: Record<string, any>): Promise<boolean> {
    const count = await this.model.count({ where });
    return count > 0;
  }

  /**
   * Count records matching conditions
   */
  async count(where?: Record<string, any>): Promise<number> {
    return this.model.count({ where });
  }
}
