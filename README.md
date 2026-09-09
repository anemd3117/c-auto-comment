# C/C++ Smart Build & Auto Comment

Portable VS Code tooling for C/C++ learners. The project validates or compiles C/C++ files and adds beginner-friendly Korean learning comments automatically.

## v0.0.8

This release keeps the external-PC portability work from v0.0.7 and fixes the Windows batch installer success-code handling.

- Fixes false `VSIX packaging failed with exit code .` errors after a successful VSIX build
- English UTF-8 setup/build/diagnostic logs
- Automatic dependency detection
- Automatic MSYS2 + UCRT64 GCC/G++ installation on Windows when missing
- Automatic Node.js LTS installation when missing
- Automatic VS Code installation when the one-click installer needs it
- No user-specific `C:\Users\...` paths
- No fixed compiler path in workspace configuration
- Runtime compiler discovery from PATH and common MSYS2 locations
- GitHub Actions builds the VSIX and publishes it to the matching GitHub Release
- Korean comments generated in source files remain unchanged

Automatic installs use trusted package managers: Windows Package Manager (winget) and MSYS2 pacman.

## One-click installation on Windows

```powershell
git clone https://github.com/anemd3117/c-auto-comment.git
cd c-auto-comment
.\install-extension.bat
```

The installer checks the machine, installs missing development dependencies, builds the current VSIX if necessary, and installs it into VS Code.

## Portable workspace mode

You can also use the repository without installing the VSIX:

```powershell
git clone https://github.com/anemd3117/c-auto-comment.git
code c-auto-comment
```

Open a `.c`, `.cpp`, `.h`, or `.hpp` file and press **Ctrl+Shift+B**. The smart build task will:

1. Detect GCC/G++.
2. Install the MSYS2 UCRT64 toolchain if it is missing.
3. Compile source files or syntax-check header files.
4. Detect/install Node.js when the comment engine needs it.
5. Add beginner-friendly Korean comments after a successful build.

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
