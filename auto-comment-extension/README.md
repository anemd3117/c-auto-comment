# Auto Comment After Run

Portable VS Code extension for C/C++, Python, and JavaScript learning workflows.

## v0.0.18

This version adds safer multilingual language recovery.

- first comment operation opens a language picker
- the selected BCP 47 locale is stored in VS Code global state
- later comment operations reuse the saved language automatically
- the language choice survives VS Code restarts and project changes
- changing the language stores the previous locale as history
- `Auto Comment: Undo Last Language Change` restores the previous language immediately
- recognized Auto Comment-generated comments in the active editor are retranslated after a change or undo
- reset now asks for confirmation and clears both current and previous language history
- built-in translated catalogs cover Korean, English, Japanese, Simplified Chinese, Traditional Chinese, French, German, Spanish, Portuguese, Russian, Arabic, Hindi, and Vietnamese
- custom BCP 47 locale input is supported for additional languages
- unsupported custom locales fall back to English rather than failing
- external-PC Python/PATH repair remains enabled
- legacy Todo Tree is still replaced by Better Todo Tree

Commands:

- Compile and Auto Comment
- Run and Auto Comment
- Add Comments to Current File
- Auto Comment: Change Comment Language
- Auto Comment: Undo Last Language Change
- Auto Comment: Reset Comment Language
