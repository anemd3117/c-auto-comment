# Auto Comment After Run

Portable VS Code extension for C/C++, Python, and JavaScript learning workflows.

Version 0.0.13 fixes the recurring Todo Tree / vscode-ripgrep problem on newer VS Code versions:

- removes the legacy Gruntfuggly Todo Tree extension
- installs maintained Better Todo Tree
- uses Better Todo Tree's packaged ripgrep instead of relying on VS Code internals or shell PATH
- keeps Python + Pylance support repair
- keeps lazy runtime discovery for GCC, Python, and Node.js
- keeps path-independent setup and UTF-8 operational logs

Commands:

- Compile and Auto Comment
- Run and Auto Comment
- Add Comments to Current File
