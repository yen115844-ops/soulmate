import { PaginatedData, PaginatedResponse, PaginationMeta } from "@/types";
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

/**
 * Extract paginated data from API response
 * Handles both wrapped ({ data: { data: [], meta: {} } }) and unwrapped ({ data: [], meta: {} }) formats
 */
export function extractPaginatedData<T>(
  response: PaginatedResponse<T> | undefined
): { data: T[]; meta: PaginationMeta | undefined } {
  if (!response) {
    return { data: [], meta: undefined };
  }

  // Check if data is wrapped (has nested data and meta)
  if (response.data && typeof response.data === 'object' && 'data' in response.data && 'meta' in response.data) {
    const paginatedData = response.data as PaginatedData<T>;
    return {
      data: paginatedData.data || [],
      meta: paginatedData.meta,
    };
  }

  // Unwrapped format
  return {
    data: Array.isArray(response.data) ? response.data : [],
    meta: response.meta,
  };
}
