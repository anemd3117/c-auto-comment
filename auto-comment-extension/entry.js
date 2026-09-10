const vscode = require('vscode');
const path = require('path');
const core = require('./extension');
const {
    LANGUAGE_OPTIONS,
    normalizeLocale,
    getLanguageLabel,
    hasBuiltInCatalog,
    translateGeneratedComment
} = require('./localization');

const LANGUAGE_STATE_KEY = 'autoCommentAfterRun.commentLanguage';
let extensionContext = null;

function detectLanguage(document) {
    const ext = path.extname(document.fileName || '').toLowerCase();
    if (ext === '.c') return 'c';
    if (ext === '.h') return 'c_header';
    if (['.cpp', '.cc', '.cxx', '.hpp', '.hh', '.hxx'].includes(ext)) return 'cpp';
    if (ext === '.py' || ext === '.pyw') return 'python';
    if (['.js', '.mjs', '.cjs'].includes(ext)) return 'javascript';
    return document.languageId || ext.replace(/^\./, '');
}

async function saveLocale(context, locale) {
    await context.globalState.update(LANGUAGE_STATE_KEY, locale);
}

function getSavedLocale(context) {
    const saved = context.globalState.get(LANGUAGE_STATE_KEY);
    return typeof saved === 'string' && saved.trim() ? normalizeLocale(saved.trim()) : null;
}

async function pickCommentLanguage(context) {
    const items = LANGUAGE_OPTIONS.map((item) => ({
        label: item.nativeName,
        description: `${item.englishName} • ${item.locale}`,
        detail: item.note || undefined,
        locale: item.locale
    }));

    items.push({
        label: '$(globe) Other / Custom language or locale',
        description: 'BCP 47 locale, for example: nl-NL, tr-TR, th-TH',
        detail: 'If a translation catalog is not bundled yet, English is used as a safe fallback.',
        locale: '__custom__'
    });

    const selected = await vscode.window.showQuickPick(items, {
        title: 'Auto Comment — Choose your comment language',
        placeHolder: 'Choose once. Auto Comment will remember this language for future comments.',
        matchOnDescription: true,
        matchOnDetail: true,
        ignoreFocusOut: true
    });

    if (!selected) {
        return null;
    }

    let locale = selected.locale;
    if (locale === '__custom__') {
        const value = await vscode.window.showInputBox({
            title: 'Auto Comment — Custom comment language',
            prompt: 'Enter a BCP 47 language/locale code',
            placeHolder: 'Examples: nl-NL, tr-TR, th-TH, id-ID, pl-PL',
            validateInput: (input) => {
                const value = String(input || '').trim();
                if (!value) return 'Enter a language or locale code.';
                if (!/^[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*$/.test(value)) {
                    return 'Use a BCP 47 style code such as en-US, ja-JP, es-MX, or nl-NL.';
                }
                return null;
            },
            ignoreFocusOut: true
        });

        if (!value) {
            return null;
        }
        locale = normalizeLocale(value);
    }

    await saveLocale(context, locale);

    if (!hasBuiltInCatalog(locale)) {
        vscode.window.showWarningMessage(
            `Auto Comment saved ${locale}. A built-in translation catalog is not bundled for this locale yet, so generated comments will use English until that catalog is added.`
        );
    } else {
        vscode.window.showInformationMessage(`Auto Comment language set to ${getLanguageLabel(locale)}.`);
    }

    return locale;
}

async function ensureCommentLanguage(context) {
    return getSavedLocale(context) || pickCommentLanguage(context);
}

async function changeCommentLanguage() {
    if (!extensionContext) return;
    await pickCommentLanguage(extensionContext);
}

async function resetCommentLanguage() {
    if (!extensionContext) return;
    await extensionContext.globalState.update(LANGUAGE_STATE_KEY, undefined);
    vscode.window.showInformationMessage('Auto Comment language preference was reset. You will be asked again the next time comments are generated.');
}

async function translateEditorComments(editor, locale) {
    if (!editor || !locale) return false;

    const document = editor.document;
    const original = document.getText();
    const lines = original.split(/\r?\n/);
    let changed = false;

    const result = lines.map((line) => {
        const match = line.match(/^(\s*)(\/\/|#)(\s+)(.*)$/);
        if (!match) return line;

        const translated = translateGeneratedComment(match[4], locale);
        if (!translated || translated === match[4]) return line;

        changed = true;
        return `${match[1]}${match[2]}${match[3]}${translated}`;
    });

    if (!changed) return false;

    const range = new vscode.Range(
        document.positionAt(0),
        document.positionAt(original.length)
    );
    const edit = new vscode.WorkspaceEdit();
    edit.replace(document.uri, range, result.join('\n'));
    await vscode.workspace.applyEdit(edit);
    await document.save();
    return true;
}

async function runWithLanguage(action) {
    if (!extensionContext) return;

    const locale = await ensureCommentLanguage(extensionContext);
    if (!locale) {
        vscode.window.showInformationMessage('Auto Comment was cancelled because no comment language was selected.');
        return;
    }

    await action();

    const editor = vscode.window.activeTextEditor;
    if (editor) {
        await translateEditorComments(editor, locale);
    }
}

async function compileAndComment() {
    return runWithLanguage(() => core.compileAndComment());
}

async function runAndComment() {
    return runWithLanguage(() => core.runAndComment());
}

async function commentCurrentFile() {
    return runWithLanguage(() => core.commentCurrentFile());
}

function activate(context) {
    extensionContext = context;

    const compileCommand = vscode.commands.registerCommand(
        'autoCommentAfterRun.compileAndComment',
        compileAndComment
    );

    const runCommand = vscode.commands.registerCommand(
        'autoCommentAfterRun.runAndComment',
        runAndComment
    );

    const commentCommand = vscode.commands.registerCommand(
        'autoCommentAfterRun.commentCurrentFile',
        commentCurrentFile
    );

    const changeLanguageCommand = vscode.commands.registerCommand(
        'autoCommentAfterRun.changeCommentLanguage',
        changeCommentLanguage
    );

    const resetLanguageCommand = vscode.commands.registerCommand(
        'autoCommentAfterRun.resetCommentLanguage',
        resetCommentLanguage
    );

    const taskEndDisposable = vscode.tasks.onDidEndTaskProcess(async (event) => {
        if (event.exitCode !== 0) return;

        const taskName = (event.execution.task.name || '').toLowerCase();
        const looksLikeBuild = taskName.includes('build') ||
            taskName.includes('compile') ||
            taskName.includes('gcc') ||
            taskName.includes('c/c++') ||
            taskName.includes('c:');

        if (!looksLikeBuild) return;

        const editor = vscode.window.activeTextEditor;
        if (!editor) return;

        const locale = await ensureCommentLanguage(context);
        if (!locale) return;

        const language = detectLanguage(editor.document);
        await core.addComments(editor, language);
        await translateEditorComments(editor, locale);
    });

    context.subscriptions.push(
        compileCommand,
        runCommand,
        commentCommand,
        changeLanguageCommand,
        resetLanguageCommand,
        taskEndDisposable
    );
}

function deactivate() {
    extensionContext = null;
    if (typeof core.deactivate === 'function') {
        core.deactivate();
    }
}

module.exports = {
    activate,
    deactivate,
    compileAndComment,
    runAndComment,
    commentCurrentFile,
    changeCommentLanguage,
    resetCommentLanguage,
    translateEditorComments
};
