"use client";

/**
 * Simple Markdown-like renderer for terms content.
 * Supports: # ## ### headers, - lists, paragraphs, line breaks.
 */
export function TermsContent({ content }: { content: string }) {
  if (!content?.trim()) {
    return (
      <p className="text-muted-foreground">Nội dung đang được cập nhật.</p>
    );
  }

  const lines = content.split("\n");
  const elements: React.ReactNode[] = [];
  let listItems: string[] = [];
  let key = 0;

  const flushList = () => {
    if (listItems.length > 0) {
      elements.push(
        <ul key={key++} className="list-disc pl-6 space-y-1 my-3">
          {listItems.map((item, i) => (
            <li key={i} className="text-muted-foreground">
              {item.trim()}
            </li>
          ))}
        </ul>
      );
      listItems = [];
    }
  };

  const flushParagraph = (text: string) => {
    if (text.trim()) {
      elements.push(
        <p key={key++} className="text-muted-foreground my-3 leading-relaxed">
          {text.trim()}
        </p>
      );
    }
  };

  let paragraphBuffer = "";

  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed) {
      flushList();
      if (paragraphBuffer) {
        flushParagraph(paragraphBuffer);
        paragraphBuffer = "";
      }
      continue;
    }

    if (trimmed.startsWith("### ")) {
      flushList();
      if (paragraphBuffer) {
        flushParagraph(paragraphBuffer);
        paragraphBuffer = "";
      }
      elements.push(
        <h3 key={key++} className="text-lg font-semibold mt-6 mb-2">
          {trimmed.slice(4)}
        </h3>
      );
    } else if (trimmed.startsWith("## ")) {
      flushList();
      if (paragraphBuffer) {
        flushParagraph(paragraphBuffer);
        paragraphBuffer = "";
      }
      elements.push(
        <h2 key={key++} className="text-xl font-semibold mt-8 mb-2">
          {trimmed.slice(3)}
        </h2>
      );
    } else if (trimmed.startsWith("# ")) {
      flushList();
      if (paragraphBuffer) {
        flushParagraph(paragraphBuffer);
        paragraphBuffer = "";
      }
      elements.push(
        <h1 key={key++} className="text-2xl font-bold mt-6 mb-2">
          {trimmed.slice(2)}
        </h1>
      );
    } else if (trimmed.startsWith("- ")) {
      if (paragraphBuffer) {
        flushParagraph(paragraphBuffer);
        paragraphBuffer = "";
      }
      listItems.push(trimmed.slice(2));
    } else {
      flushList();
      if (paragraphBuffer) paragraphBuffer += " " + trimmed;
      else paragraphBuffer = trimmed;
    }
  }

  flushList();
  if (paragraphBuffer) flushParagraph(paragraphBuffer);

  return <div className="prose prose-sm max-w-none">{elements}</div>;
}
