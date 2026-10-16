---
name: pdf-parsing
description: >-
  Extract and inspect text in PDF files using macOS PDFKit. Use when a user asks
  to parse, search, or read a local PDF, especially when command-line PDF tools
  are unavailable.
---

# PDF Parsing

## Purpose and boundary

Read local PDF content into searchable text using macOS PDFKit. This skill covers text extraction and inspection, not PDF editing or document interpretation.

## Responsibilities

- Extract selectable text page by page, preserving page boundaries.
- Save large extraction output to a temporary text file before searching or reading excerpts.
- Identify scanned/image-only PDFs when extraction produces no useful text.

## Non-goals

- Modifying, converting, or annotating PDFs.
- Treating extracted text as authoritative when layout, tables, or diagrams affect meaning.

## Design guardrail

Use built-in PDFKit before installing tools or dependencies. Keep the original PDF unchanged. Inspect relevant page context after searching; extraction can flatten tables and distort reading order.

## Typical flow

1. Set `PDF` to the input file path and extract each page with PDFKit:

   ```bash
   PDF="/path/to/document.pdf"
   TEXT="$(mktemp -t pdf-text)"
   swift -e 'import PDFKit; import Foundation; let url = URL(fileURLWithPath: CommandLine.arguments[1]); guard let document = PDFDocument(url: url) else { fatalError("Could not open PDF") }; for index in 0..<document.pageCount { print("\n--- PAGE \(index + 1) ---\n\(document.page(at: index)?.string ?? "")") }' "$PDF" > "$TEXT"
   printf 'Extracted text: %s\n' "$TEXT"
   ```

2. Search the extracted text for relevant terms with `rg -n`, then inspect matching page sections from the text file.
3. Check extraction completeness against the PDF: page markers should cover all pages, and relevant tables or command examples should retain their values and order.
4. If pages yield no meaningful text, treat the PDF as scanned and switch to OCR; do not mistake empty extraction for an empty document.

## Maintenance

PDFKit is an Apple framework and this workflow requires macOS with Swift installed. Keep this dependency-free path as the default; add an OCR workflow only when scanned PDFs are a recurring need.
