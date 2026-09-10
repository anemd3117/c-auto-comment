# C/C++ / Python / JavaScript Smart Build & Auto Comment

Portable VS Code tooling that validates or runs supported source files and adds beginner-friendly Korean learning comments automatically.

## v0.0.15

This release fixes Python Auto Comment failures on external Windows PCs where Python is installed but the launcher/interpreter is not available through PATH.

### Why this change was necessary

Some external Windows PCs have a working Python installation such as `%LOCALAPPDATA%\Programs\Python\Launcher\py.exe`, while `py`, `python`, and `python3` are missing from the VS Code extension host PATH. The previous runtime resolver could therefore report Python as missing even though Python itself worked from an absolute path.

v0.0.15 now discovers those installed files directly and verifies the real interpreter with `sys.executable`.

### Previous Todo Tree compatibility work

VS Code 1.122 changed its internal ripgrep layout. The legacy `Gruntfuggly.todo-tree` extension still relies on VS Code internals and can fail with:

```text
Todo-Tree: Failed to find vscode-ripgrep
```

Installing `rg.exe` system-wide or repairing PATH does not reliably solve that upstream extension bug.

### What v0.0.15 does

- removes `Gruntfuggly.todo-tree` when present
- installs the actively maintained `FanaticPythoner.better-todo-tree`
- uses Better Todo Tree's packaged ripgrep binary
- removes the old external ripgrep override from VS Code settings
- removes any `better-todo-tree.ripgrep.ripgrep` override so Better Todo Tree uses its packaged/default ripgrep automatically
- no longer writes an empty ripgrep path into VS Code settings
- no longer installs or repairs external ripgrep just for Todo Tree
- discovers `%LOCALAPPDATA%\Programs\Python\Launcher\py.exe` even when it is not on PATH
- scans normal per-user and Program Files Python installation directories
- validates each candidate by executing Python and reading `sys.executable`
- normalizes compile/run commands to the verified interpreter absolute path instead of depending on `py`/`python` command names
- repairs User PATH with both the discovered launcher directory and interpreter directory
- keeps Microsoft Python and Pylance setup
- keeps cleanup of unsupported Tabnine and legacy IntelliCode extensions
- keeps the lazy GCC / Python / Node runtime bootstrap
- keeps path-independent VS Code and debugger configuration

## One-click installation on Windows

```powershell
git clone https://github.com/anemd3117/c-auto-comment.git
cd c-auto-comment
.\install-extension.bat
```

For an existing clone:

```powershell
git pull origin main
.\install-extension.bat
```

The installer now performs:

```text
VS Code host
  -> detect/install VS Code
  -> remove broken legacy Todo Tree
  -> install Better Todo Tree
  -> use Better Todo Tree packaged ripgrep
  -> install Python + Pylance VS Code support if missing
  -> clean unsupported legacy AI extensions
  -> download the matching prebuilt Auto Comment VSIX
  -> install and verify the exact extension version
```

Language runtimes remain lazy:

```text
C/C++ first use
  -> detect GCC/G++
  -> install MSYS2 UCRT64 toolchain only if missing

Python first use
  -> validate pymanager / py / python / python3
  -> install Python only if no working runtime exists

JavaScript first use
  -> detect Node.js
  -> install Node.js LTS only if missing
```

## Extension commands

- **F6** — Compile and Auto Comment
- **Compile and Auto Comment**
- **Run and Auto Comment**
- **Add Comments to Current File**

## Encoding policy

Operational/setup messages use English UTF-8. Generated learning comments remain Korean.

## License

MIT
