# Auto Comment After Run

Portable VS Code extension for C/C++, Python, and JavaScript learning workflows.

## v0.0.17

This version adds persistent multilingual learning comments.

- first comment operation opens a language picker
- the selected BCP 47 locale is stored in VS Code global state
- later comment operations reuse the saved language automatically
- the language choice survives VS Code restarts and project changes
- users can change or reset the language from the Command Palette
- built-in translated catalogs cover Korean, English, Japanese, Simplified Chinese, Traditional Chinese, French, German, Spanish, Portuguese, Russian, Arabic, Hindi, and Vietnamese
- custom BCP 47 locale input is supported for additional languages
- unsupported custom locales fall back to English rather than failing
- existing generated comments from bundled languages can be recognized and translated when the active language changes
- external-PC Python/PATH repair from v0.0.16 remains enabled
- legacy Todo Tree is still replaced by Better Todo Tree

Commands:

- Compile and Auto Comment
- Run and Auto Comment
- Add Comments to Current File
- Auto Comment: Change Comment Language
- Auto Comment: Reset Comment Language
