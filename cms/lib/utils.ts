import { PaginatedData, PaginatedResponse, PaginationMeta } from "@/types";
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

/**
 * Extract paginated data from API response
 * Handles multiple backend formats:
 *  1. Wrapped with meta:  { data: { data: [], meta: { total, page, ... } } }
 *  2. Flat pagination:    { data: { data: [], total, page, limit, totalPages } }
 *  3. Unwrapped array:    { data: [], meta: { ... } }
 */
export function extractPaginatedData<T>(
  response: PaginatedResponse<T> | undefined
): { data: T[]; meta: PaginationMeta | undefined } {
  if (!response) {
    return { data: [], meta: undefined };
  }

  // Check if data is wrapped (has nested data array)
  if (response.data && typeof response.data === 'object' && !Array.isArray(response.data) && 'data' in response.data) {
    const nested = response.data as unknown as Record<string, unknown>;

    // Format 1: { data: { data: [], meta: { ... } } }
    if ('meta' in nested) {
      const paginatedData = response.data as PaginatedData<T>;
      return {
        data: paginatedData.data || [],
        meta: paginatedData.meta,
      };
    }

    // Format 2: { data: { data: [], total, page, limit, totalPages } }
    if ('total' in nested || 'page' in nested) {
      return {
        data: (Array.isArray(nested.data) ? nested.data : []) as T[],
        meta: {
          total: (nested.total as number) ?? 0,
          page: (nested.page as number) ?? 1,
          limit: (nested.limit as number) ?? 10,
          totalPages: (nested.totalPages as number) ?? 1,
        },
      };
    }
  }

  // Unwrapped format
  return {
    data: Array.isArray(response.data) ? response.data : [],
    meta: response.meta,
  };
}
