# C/C++ / Python / JavaScript Smart Build & Auto Comment

Portable VS Code tooling that validates or runs supported source files and adds beginner-friendly learning comments automatically.

## v0.0.17 — multilingual first-run comment language

Auto Comment no longer assumes the user is Korean.

The first time the user actually generates comments, Auto Comment opens a language picker. The selected language is stored in VS Code global state and is reused automatically for every later comment operation, even after VS Code is restarted or another project is opened.

```text
First comment operation
  -> no saved comment language
  -> show language picker
  -> user chooses a language
  -> save the BCP 47 locale in VS Code globalState
  -> generate comments in that language

Later F6 / Run / Comment Current File
  -> read the saved locale
  -> do not ask again
  -> generate comments in the saved language automatically
```

### Built-in translated comment catalogs

v0.0.17 ships translated learning-comment catalogs for:

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

This keeps the locale system open-ended: new language catalogs can be added without changing the compiler/runtime logic.

### Language management

The selection is remembered automatically. Users can change it at any time from the Command Palette:

```text
Auto Comment: Change Comment Language
Auto Comment: Reset Comment Language
```

Reset removes the saved preference. The next comment operation opens the first-run language picker again.

Known Auto Comment-generated comments can also be recognized across bundled languages, so changing the selected language does not require changing compiler or runtime settings.

## Python / external-PC portability

The v0.0.16 external-PC repair remains enabled:

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
- **Auto Comment: Reset Comment Language**

## Encoding policy

Operational/setup messages use English UTF-8. Generated learning comments use the language selected by the user.

## License

MIT
