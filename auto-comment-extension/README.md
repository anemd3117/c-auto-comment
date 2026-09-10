# Auto Comment After Run

Portable VS Code extension for C/C++, Python, and JavaScript learning workflows.

Version 0.0.14 fixes the installer error introduced in v0.0.13 while keeping the Todo Tree compatibility repair:

- removes the legacy Gruntfuggly Todo Tree extension
- installs maintained Better Todo Tree
- removes any Better Todo Tree ripgrep override and lets the extension use its packaged ripgrep by default
- avoids the empty-string PowerShell parameter binding failure from v0.0.13
- keeps Python + Pylance support repair
- keeps lazy runtime discovery for GCC, Python, and Node.js
- keeps path-independent setup and UTF-8 operational logs

Commands:

- Compile and Auto Comment
- Run and Auto Comment
- Add Comments to Current File
