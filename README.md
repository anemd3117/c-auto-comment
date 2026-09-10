# C/C++ / Python / JavaScript Smart Build & Auto Comment

Portable VS Code tooling that validates or runs supported source files and adds beginner-friendly learning comments automatically.

## v0.0.18 — multilingual language history and undo

Auto Comment asks for the comment language on the first real comment operation, stores that BCP 47 locale in VS Code global state, and reuses it automatically afterward.

v0.0.18 adds safer recovery when a user chooses the wrong language:

```text
Choose language A
  -> save A as current language

Change to language B
  -> keep A as previous language
  -> save B as current language

Auto Comment: Undo Last Language Change
  -> restore A immediately
  -> keep B as the previous value so the user can switch back again if needed
  -> translate recognized Auto Comment-generated comments in the active file to the restored language

Auto Comment: Reset Comment Language
  -> show a confirmation dialog
  -> clear both current and previous language history
  -> ask for a language again on the next comment operation
```

### Built-in translated comment catalogs

Auto Comment ships translated learning-comment catalogs for:

- Korean — `ko-KR`
- English — `en-US`, with `en-GB` alias
- Japanese — `ja-JP`
- Chinese Simplified — `zh-CN`
- Chinese Traditional — `zh-TW`
- French — `fr-FR`
- German — `de-DE`
- Spanish (Mexico) — `es-MX`
- Spanish (Spain) — `es-ES`
- Portuguese (Brazil) — `pt-BR`
- Portuguese (Portugal) — `pt-PT`
- Russian — `ru-RU`
- Arabic — `ar-SA`
- Hindi — `hi-IN`
- Vietnamese — `vi-VN`

The picker also provides **Other / Custom language or locale**. Any BCP 47-style locale can be saved, such as `nl-NL`, `tr-TR`, `th-TH`, `id-ID`, or `pl-PL`. If a native catalog is not bundled yet, comments safely fall back to English instead of failing.

### Language management

The selection is remembered automatically. Users can manage it at any time from the Command Palette:

```text
Auto Comment: Change Comment Language
Auto Comment: Undo Last Language Change
Auto Comment: Reset Comment Language
```

Changing or undoing the language immediately retranslates recognized Auto Comment-generated comments in the active file. Reset is destructive to the saved language history, so v0.0.18 asks for confirmation first.

## Python / external-PC portability

The external-PC repair remains enabled:

- verifies Python during installer setup
- discovers the standard per-user Python Launcher outside PATH
- discovers installed `python.exe` runtimes and validates them with `sys.executable`
- installs Python only when no working runtime exists
- adds both launcher and interpreter directories to User PATH
- configures VS Code `python.defaultInterpreterPath` to the verified absolute interpreter
- Auto Comment itself keeps an absolute-path Python fallback

After installation, fully restart VS Code so its extension host and terminals inherit any repaired environment variables.

## Todo Tree compatibility

The installer removes the legacy `Gruntfuggly.todo-tree` extension and installs `FanaticPythoner.better-todo-tree`, which uses its packaged ripgrep by default.

## Existing installation

```powershell
cd C:\Users\user\c-auto-comment
git pull origin main
.\install-extension.bat
```

## Fresh installation

```powershell
git clone https://github.com/anemd3117/c-auto-comment.git
cd c-auto-comment
.\install-extension.bat
```

## Extension commands

- **F6** — Compile and Auto Comment
- **Compile and Auto Comment**
- **Run and Auto Comment**
- **Add Comments to Current File**
- **Auto Comment: Change Comment Language**
- **Auto Comment: Undo Last Language Change**
- **Auto Comment: Reset Comment Language**

## Encoding policy

Operational/setup messages use English UTF-8. Generated learning comments use the language selected by the user.

## License

MIT
