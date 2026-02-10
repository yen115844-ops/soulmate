"use client";

import dynamic from "next/dynamic";
import { useTheme } from "next-themes";
import { useEffect, useState } from "react";
import { visit } from "unist-util-visit";
import type { Element } from "hast";
import "@uiw/react-md-editor/markdown-editor.css";
import "@uiw/react-markdown-preview/markdown.css";

const MDEditor = dynamic(() => import("@uiw/react-md-editor"), { ssr: false });

/** Rehype plugin: fix empty img src to avoid browser reload */
function rehypeFixEmptyImgSrc() {
  return (tree: import("hast").Root) => {
    visit(tree, "element", (node: Element) => {
      if (node.tagName === "img" && node.properties) {
        const src = node.properties.src;
        if (typeof src === "string" && src.trim() === "") {
          node.properties.src = undefined;
        }
      }
    });
  };
}

interface MarkdownEditorProps {
  value: string;
  onChange: (value?: string) => void;
  placeholder?: string;
  minHeight?: number;
  className?: string;
}

export function MarkdownEditor({
  value,
  onChange,
  placeholder = "Viết nội dung Markdown ở đây...",
  minHeight = 450,
  className = "",
}: MarkdownEditorProps) {
  const { resolvedTheme } = useTheme();
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);
  const colorMode = mounted && resolvedTheme === "dark" ? "dark" : "light";

  return (
    <div className={className} data-color-mode={colorMode}>
      <MDEditor
        value={value}
        onChange={onChange}
        preview="live"
        hideToolbar={false}
        enableScroll={true}
        visibleDragbar={false}
        height={minHeight}
        textareaProps={{
          placeholder,
        }}
        previewOptions={{
          disallowedElements: ["script", "style"],
          rehypePlugins: [rehypeFixEmptyImgSrc],
        }}
      />
    </div>
  );
}
