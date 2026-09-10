# Auto Comment After Run

Portable VS Code extension for C/C++, Python, and JavaScript learning workflows.

Version 0.0.16 fixes external Windows PCs where Python exists but VS Code or another runner still reports that Python is not installed or is not available on PATH.

- Python is verified during installer setup instead of waiting for first use
- the standard per-user Python Launcher is discovered outside PATH
- the real interpreter is validated with `sys.executable`
- both launcher and interpreter directories are persisted to User PATH
- VS Code `python.defaultInterpreterPath` is set to the verified absolute interpreter path
- Auto Comment continues to use the verified absolute interpreter path directly
- legacy Todo Tree is replaced by Better Todo Tree
- Python and Pylance support extensions are kept installed
- GCC and Node.js remain lazy

After installation, fully restart VS Code so the extension host and new terminals inherit the repaired environment.

Commands:

- Compile and Auto Comment
- Run and Auto Comment
- Add Comments to Current File
