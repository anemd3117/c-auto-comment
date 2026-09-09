# C/C++ Smart Build & Auto Comment

Portable VS Code tooling for C/C++ learners. The project validates or compiles C/C++ files and adds beginner-friendly Korean learning comments automatically.

## v0.0.10

This release removes the remaining target-PC path coupling.

- The target PC no longer builds the VSIX with `npx`
- The installer downloads the prebuilt VSIX from the matching GitHub Release
- Newly installed Node.js no longer has to appear in the parent CMD session before installation can continue
- GCC, MSYS2, Node.js, and VS Code are discovered dynamically from the current system
- MSYS2 is no longer required to exist at a fixed `C:\msys64` location
- The extension host refreshes the Windows Machine/User PATH after automatic dependency installation
- The batch file is only a small launcher for the PowerShell installer
- VSIX installation is verified with `code --list-extensions --show-versions`
- Windows CI rejects known machine-specific paths and installer-side `npx` dependencies
- Operational logs remain English UTF-8; generated learning comments remain Korean

Automatic installs use Windows Package Manager (winget) and MSYS2 pacman.

## One-click installation on Windows

```powershell
git clone https://github.com/anemd3117/c-auto-comment.git
cd c-auto-comment
.\install-extension.bat
```

The installer:

1. Reads the extension version from `package.json`.
2. Detects or installs the required development tools.
3. Resolves the actual VS Code CLI path.
4. Downloads the prebuilt VSIX from the matching GitHub Release into the Windows temp directory.
5. Installs the VSIX using the resolved VS Code CLI.
6. Verifies that the exact extension version is installed.

The target PC does **not** need to package the VSIX locally.

## Portable workspace mode

You can also use the repository without installing the VSIX:

```powershell
git clone https://github.com/anemd3117/c-auto-comment.git
code c-auto-comment
```

Open a `.c`, `.cpp`, `.h`, or `.hpp` file and press **Ctrl+Shift+B**. The smart build task can bootstrap missing GCC/G++ and Node.js dependencies and refresh PATH before retrying.

## Extension commands

- **F6** — Compile and Auto Comment
- **Compile and Auto Comment** — validates/builds the current file, then comments it
- **Run and Auto Comment** — builds, comments, then runs the program
- **Add Comments to Current File** — comments without compiling

## Project structure

```text
.vscode/
  settings.json
  tasks.json
scripts/
  bootstrap.ps1
  install.ps1
  smart_build.ps1
  auto_comment.js
auto-comment-extension/
  bootstrap.ps1
  extension.js
  package.json
install-extension.bat
```

## Encoding policy

Operational logs and setup messages use English with UTF-8. Generated learning comments are intentionally Korean.

## License

MIT
