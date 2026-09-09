# C/C++ / Python / JavaScript Smart Build & Auto Comment

Portable VS Code tooling that validates or runs supported source files and adds beginner-friendly Korean learning comments automatically.

## v0.0.11

This release focuses on Python portability and lower startup/install latency on external Windows PCs.

- Python is now a first-class bootstrap component.
- Python detection validates a real working runtime instead of trusting only a `python.exe` name.
- Supports `pymanager`, `py`, `python`, and `python3` launchers.
- Missing Python is installed through the official Python Install Manager workflow on Windows.
- `.py` and `.pyw` files are detected by file extension even when a fresh VS Code installation reports the document as plain text.
- The one-click installer now prepares only VS Code. GCC, Node.js, and Python are installed lazily only when that language needs them.
- Executable discovery is cached to avoid repeatedly starting PowerShell just to refresh PATH.
- The extension no longer activates on every VS Code startup. It activates only for supported languages or Auto Comment commands.
- Re-running the installer skips the VSIX download when the exact version is already installed.
- Operational logs remain English UTF-8. Generated learning comments remain Korean.

## One-click installation on Windows

```powershell
git clone https://github.com/anemd3117/c-auto-comment.git
cd c-auto-comment
.\install-extension.bat
```

Initial installation is intentionally lightweight:

```text
Installer
  -> detect/install VS Code only
  -> download prebuilt VSIX
  -> install and verify extension
```

Language runtimes are prepared only when needed:

```text
Open/run C or C++
  -> detect GCC/G++
  -> install MSYS2 UCRT64 toolchain only if missing

Open/run Python
  -> validate pymanager / py / python / python3
  -> install Python only if no working runtime exists

Open/run JavaScript
  -> detect Node.js
  -> install Node.js LTS only if missing
```

This avoids forcing every external PC to install or scan every development stack during setup.

## Python behavior

For Python files, Auto Comment checks for a **working interpreter**, not just a command name. This helps avoid false positives from broken PATH entries or Windows app execution aliases.

The extension validates Python before compiling with:

```text
python -c "import sys; print(sys.executable)"
```

or the equivalent launcher form for `py` / `pymanager`.

If Python is missing on Windows, the bootstrap uses the Python Install Manager and then retries runtime discovery.

## Extension commands

- **F6** — Compile and Auto Comment
- **Compile and Auto Comment** — validates/builds the current file, then comments it
- **Run and Auto Comment** — validates/builds, comments, then runs it
- **Add Comments to Current File** — comments without compiling

## Encoding policy

Operational/setup messages use English UTF-8. Generated learning comments are intentionally Korean.

## License

MIT
