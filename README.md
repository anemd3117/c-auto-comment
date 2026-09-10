# C/C++ / Python / JavaScript Smart Build & Auto Comment

Portable VS Code tooling that validates or runs supported source files and adds beginner-friendly Korean learning comments automatically.

## v0.0.16

This release fixes external-PC cases where Python is installed but VS Code or another runner still reports that Python is not installed or is not available on PATH.

### Python repair strategy

The installer now verifies Python during setup instead of waiting for first use.

- discovers the standard per-user Python Launcher outside PATH
- discovers installed `python.exe` runtimes and validates them with `sys.executable`
- installs Python through the Python Install Manager only when no working runtime exists
- permanently adds both the Python launcher directory and verified interpreter directory to User PATH
- configures VS Code `python.defaultInterpreterPath` to the verified absolute `python.exe` path
- Auto Comment itself continues to execute Python through the verified absolute interpreter path
- a full VS Code restart is required after setup so existing extension-host and terminal processes inherit the repaired PATH

This covers both Auto Comment and other VS Code components that still invoke `python` through PATH.

### Todo Tree compatibility

The installer removes the legacy `Gruntfuggly.todo-tree` extension and installs `FanaticPythoner.better-todo-tree`, which uses its packaged ripgrep by default.

## Existing installation

```powershell
cd C:\Users\user\c-auto-comment
git pull origin main
.\install-extension.bat
```

After installation, fully close all VS Code windows and reopen VS Code.

## Fresh installation

```powershell
git clone https://github.com/anemd3117/c-auto-comment.git
cd c-auto-comment
.\install-extension.bat
```

## Runtime behavior

C/C++ and JavaScript remain lazy. GCC/G++ or Node.js are prepared only when their language is first used. Python is now verified during installer setup because external VS Code runners may require a working PATH before Auto Comment activates.

## Extension commands

- **F6** — Compile and Auto Comment
- **Compile and Auto Comment**
- **Run and Auto Comment**
- **Add Comments to Current File**

## Encoding policy

Operational/setup messages use English UTF-8. Generated learning comments remain Korean.

## License

MIT
