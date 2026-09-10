# Auto Comment After Run

Portable VS Code extension for C/C++, Python, and JavaScript learning workflows.

Version 0.0.15 fixes Python runtime resolution on external Windows PCs where Python works by absolute path but is missing from PATH:

- removes the legacy Gruntfuggly Todo Tree extension
- installs maintained Better Todo Tree
- removes any Better Todo Tree ripgrep override and lets the extension use its packaged ripgrep by default
- avoids the empty-string PowerShell parameter binding failure from v0.0.13
- discovers the standard per-user Python Launcher outside PATH
- validates the real interpreter through `sys.executable`
- uses the verified interpreter absolute path for Python validation and execution
- repairs User PATH with the launcher and interpreter directories
- keeps Python + Pylance support repair
- keeps lazy runtime discovery for GCC, Python, and Node.js
- keeps path-independent setup and UTF-8 operational logs

Commands:

- Compile and Auto Comment
- Run and Auto Comment
- Add Comments to Current File
