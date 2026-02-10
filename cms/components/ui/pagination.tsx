"use client";

import { Button } from "@/components/ui/button";
import { ChevronLeft, ChevronRight } from "lucide-react";

export interface PaginationProps {
  page: number;
  totalPages: number;
  total: number;
  itemLabel?: string;
  onPageChange: (page: number) => void;
  /** Show pagination even when only 1 page. Default: false */
  showWhenSinglePage?: boolean;
}

export function Pagination({
  page,
  totalPages,
  total,
  itemLabel = "mục",
  onPageChange,
  showWhenSinglePage = false,
}: PaginationProps) {
  if (!showWhenSinglePage && totalPages <= 1) {
    return null;
  }

  const currentPage = Math.max(1, Math.min(page, totalPages));
  const displayTotal = Math.max(0, total);

  return (
    <div className="flex flex-col gap-4 px-4 py-4 sm:flex-row sm:items-center sm:justify-between">
      <p className="text-sm text-muted-foreground">
        Trang {currentPage} / {totalPages || 1}
        {displayTotal > 0 && (
          <span className="ml-1">({displayTotal.toLocaleString()} {itemLabel})</span>
        )}
      </p>
      <div className="flex items-center gap-2">
        <Button
          variant="outline"
          size="sm"
          onClick={() => onPageChange(Math.max(1, currentPage - 1))}
          disabled={currentPage <= 1}
        >
          <ChevronLeft className="mr-1 h-4 w-4" />
          Trước
        </Button>
        <span className="min-w-[2rem] text-center text-sm text-muted-foreground">
          {currentPage}
        </span>
        <Button
          variant="outline"
          size="sm"
          onClick={() => onPageChange(Math.min(totalPages, currentPage + 1))}
          disabled={currentPage >= (totalPages || 1)}
        >
          Sau
          <ChevronRight className="ml-1 h-4 w-4" />
        </Button>
      </div>
    </div>
  );
}
