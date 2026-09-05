---
name: markitdown
description: A Python utility for converting various file formats (PDF, Word, Excel, PowerPoint, etc.) to Markdown. Use this skill to install and use MarkItDown for document conversion.
---

# MarkItDown

MarkItDown is a lightweight Python utility by Microsoft for converting various files to Markdown for use with LLMs.

## Capabilities

Converts the following formats to Markdown:
- PDF
- PowerPoint (.pptx)
- Word (.docx)
- Excel (.xlsx)
- Images (EXIF & OCR)
- Audio (Transcription)
- HTML
- Text formats (CSV, JSON, XML)
- YouTube URLs
- ZIP files

## Installation

To use MarkItDown, you first need to install it. It requires Python 3.10+.

```bash
pip install "markitdown[all]"
```

## Usage

### Command Line

Convert a file and print to stdout:
```bash
markitdown path-to-file.pdf
```

Convert a file and save to output:
```bash
markitdown path-to-file.pdf -o document.md
```

Pipe content:
```bash
cat path-to-file.pdf | markitdown
```

### Python API

```python
from markitdown import MarkItDown

md = MarkItDown()
result = md.convert("test.xlsx")
print(result.text_content)
```

## Microsoft Document Intelligence

For better PDF extraction, use Azure Document Intelligence:

```bash
markitdown path-to-file.pdf -o document.md -d -e "<endpoint>"
```
