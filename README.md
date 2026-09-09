# C/C++ / Python / JavaScript Smart Build & Auto Comment

Portable VS Code tooling that validates or runs supported source files and adds beginner-friendly Korean learning comments automatically.

## v0.0.12

This release adds the external-PC VS Code repairs discovered during real installation testing.

- ripgrep is now a first-class bootstrap component.
- Existing WinGet ripgrep installs are discovered even when the `rg` alias is missing.
- ripgrep is copied to a stable per-user location:
  `%LOCALAPPDATA%\Programs\ripgrep\rg.exe`
- That stable directory is added to the user PATH.
- Todo Tree is installed if missing and configured directly with:
  `todo-tree.ripgrep.ripgrep`
- Microsoft Python and Pylance extensions are installed if missing.
- Unsupported/failing Tabnine and legacy IntelliCode extensions are removed when present.
- The obsolete `tabnine.experimentalAutoImports` setting is removed.
- VS Code user settings are backed up before the Todo Tree repair is applied.
- The repository debugger configuration no longer hardcodes `C:\msys64\...`.
- Python runtime bootstrap and lazy dependency loading from v0.0.11 are preserved.

## One-click installation on Windows

```powershell
git clone https://github.com/anemd3117/c-auto-comment.git
cd c-auto-comment
.\install-extension.bat
```

The installer now performs:

```text
VS Code host
  -> detect/install VS Code
  -> detect/install ripgrep
  -> normalize rg.exe to a stable per-user path
  -> repair Todo Tree
  -> install Python + Pylance VS Code support
  -> clean unsupported legacy AI extensions
  -> download the matching prebuilt Auto Comment VSIX
  -> install and verify the exact extension version
```

Language runtimes remain lazy:

```text
Open/run C or C++
  -> detect GCC/G++
  -> install MSYS2 UCRT64 toolchain only if missing

Open/run Python
  -> validate pymanager / py / python / python3
  -> install Python runtime only if no working interpreter exists

Open/run JavaScript
  -> detect Node.js
  -> install Node.js LTS only if missing
```

## Todo Tree / ripgrep behavior

The installer does not depend on WinGet's command alias being healthy.

If ripgrep is already present under the WinGet package store but `rg` is not on PATH, the bootstrap discovers the actual executable and copies it to:

```text
%LOCALAPPDATA%\Programs\ripgrep\rg.exe
```

Todo Tree is then pointed directly to that stable executable using:

```json
"todo-tree.ripgrep.ripgrep": "<resolved stable rg.exe path>"
```

This avoids version-specific WinGet package paths in VS Code settings.

## Python behavior

For Python files, Auto Comment validates a working interpreter instead of trusting only a command name.

Supported launchers include:

- `pymanager`
- `py`
- `python`
- `python3`

If no working Python runtime exists on Windows, the bootstrap uses the Python Install Manager and retries runtime discovery.

## Extension commands

- **F6** — Compile and Auto Comment
- **Compile and Auto Comment** — validates/builds the current file, then comments it
- **Run and Auto Comment** — validates/builds, comments, then runs it
- **Add Comments to Current File** — comments without compiling

## Encoding policy

Operational/setup messages use English UTF-8. Generated learning comments are intentionally Korean.

## License

MIT
