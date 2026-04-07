# Advanced Bash Archive Unpacker

A Command Line Interface (CLI) utility built in Bash for automated, recursive, and secure archive extraction on Linux systems.

## 🚀 Overview
This tool was developed to solve the challenge of managing multiple archive formats across complex directory structures. Unlike standard tools that rely on file extensions, this script performs deep content inspection to ensure accurate processing.

## ✨ Key Features
- [cite_start]**Content-Based Detection:** Uses `file -b` (Magic Bytes) to identify ZIP, GZ, BZ2, and COMPRESS formats, ignoring misleading file extensions[cite: 134, 151].
- [cite_start]**Recursive Processing:** Supports a `-r` flag to traverse nested directories and unpack archives at every level[cite: 148, 149].
- [cite_start]**Data Integrity:** Implements the "Keep Original Intact" principle by using stream redirection (`-c`) to prevent the deletion of source archives[cite: 134].
- [cite_start]**Collision Prevention:** Automatically appends a `.unpacked` suffix to extracted files to avoid overwriting existing data[cite: 134].
- **Robust Path Handling:** Engineered with `IFS` management and `null delimiters` (`-print0`) to safely handle filenames containing spaces or newlines.
- [cite_start]**Verbose Reporting:** Optional `-v` flag for real-time execution logs and detailed summary of processed files[cite: 145, 147].

## 🛠 Usage
### Synopsis
```bash
./unpack.sh [-r] [-v] file [files...]
