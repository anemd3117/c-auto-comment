const vscode = require('vscode');
const cp = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');
const crypto = require('crypto');

// 공통 한글 변수/식별자 -> 영어 매핑 딕셔너리
const KOREAN_IDENTIFIER_MAP = {
    '넓이': 'area',
    '높이': 'height',
    '가로': 'width',
    '세로': 'height',
    '밑변': 'base',
    '빗변': 'hypotenuse',
    '반지름': 'radius',
    '지름': 'diameter',
    '면적': 'area',
    '합': 'sum',
    '총합': 'total',
    '평균': 'average',
    '이름': 'name',
    '나이': 'age',
    '점수': 'score',
    '결과': 'result',
    '개수': 'count',
    '최댓값': 'maxValue',
    '최대값': 'maxValue',
    '최솟값': 'minValue',
    '최소값': 'minValue',
    '인덱스': 'index',
    '임시': 'temp',
    '값': 'value',
    '번호': 'number'
};

/**
 * VS Code 확장 활성화 진입점
 * @param {vscode.ExtensionContext} context
 */
function activate(context) {
    // 1. 컴파일 성공 직후 즉시 주석 추가 (F6 또는 상단 버튼)
    const compileAndCommentCommand = vscode.commands.registerCommand(
        'autoCommentAfterRun.compileAndComment',
        compileAndComment
    );

    // 2. 컴파일 -> 주석 추가 -> VS Code 통합 터미널에서 실행
    const runAndCommentCommand = vscode.commands.registerCommand(
        'autoCommentAfterRun.runAndComment',
        runAndComment
    );

    // 3. 현재 열린 파일에 컴파일 없이 즉시 주석 추가
    const commentOnlyCommand = vscode.commands.registerCommand(
        'autoCommentAfterRun.commentCurrentFile',
        commentCurrentFile
    );

    // 4. VS Code 자체 빌드 작업(Ctrl+Shift+B, gcc 빌드 등) 완료 이벤트 감지
    // 사용자가 tasks.json을 통해 빌드해도 빌드 성공 시 자동 주석 실행!
    const taskEndDisposable = vscode.tasks.onDidEndTaskProcess(async (event) => {
        if (event.exitCode === 0) {
            const taskName = (event.execution.task.name || '').toLowerCase();
            if (taskName.includes('build') || taskName.includes('compile') || taskName.includes('gcc') || taskName.includes('c/c++') || taskName.includes('c:')) {
                const editor = vscode.window.activeTextEditor;
                if (editor) {
                    const doc = editor.document;
                    const lang = doc.languageId || path.extname(doc.fileName).slice(1);
                    const updated = await addComments(editor, lang);
                    if (updated) {
                        vscode.window.showInformationMessage(`[Auto Comment] 컴파일 성공! ${path.basename(doc.fileName)}에 학습용 주석이 자동 추가되었습니다.`);
                    }
                }
            }
        }
    });

    context.subscriptions.push(compileAndCommentCommand);
    context.subscriptions.push(runAndCommentCommand);
    context.subscriptions.push(commentOnlyCommand);
    context.subscriptions.push(taskEndDisposable);
}

function isHeaderFile(filePath) {
    const ext = path.extname(filePath).toLowerCase();
    return ext === '.h' || ext === '.hpp' || ext === '.hxx';
}

/**
 * 컴파일(빌드) 검증 후 즉시 학습용 한글 주석 추가
 */
async function compileAndComment() {
    const editor = vscode.window.activeTextEditor;
    if (!editor) {
        vscode.window.showWarningMessage("주석을 추가할 활성 파일이 열려있지 않습니다.");
        return;
    }

    const document = editor.document;
    const filePath = document.fileName;
    const language = document.languageId || path.extname(filePath).slice(1);
    const workspaceFolder = vscode.workspace.getWorkspaceFolder(document.uri);
    const workspacePath = workspaceFolder ? workspaceFolder.uri.fsPath : path.dirname(filePath);

    await document.save();
    const command = getCompileCommand(language, filePath, workspacePath);

    if (!command) {
        vscode.window.showWarningMessage('지원하지 않는 언어입니다: ' + language);
        return;
    }

    const output = vscode.window.createOutputChannel('Auto Comment');
    output.clear();
    output.show(true);
    output.appendLine('[컴파일 검증 시작] 파일: ' + filePath);
    output.appendLine('[명령어] ' + command.displayCommand);

    try {
        const compileResult = await spawnAndCapture(command.executable, command.args, workspacePath);
        if (compileResult.output) {
            output.appendLine(compileResult.output);
        }

        if (compileResult.exitCode !== 0) {
            vscode.window.showErrorMessage('컴파일 에러가 발생했습니다 (코드: ' + compileResult.exitCode + '). 출력 창을 확인하세요.');
            return;
        }

        output.appendLine('[컴파일 성공] 학습용 한글 주석을 생성합니다...');
        const updated = await addComments(editor, language);
        if (updated) {
            vscode.window.showInformationMessage('컴파일 완료! 학습용 한글 주석이 코드에 추가되었습니다.');
        } else {
            vscode.window.showInformationMessage('컴파일 완료! 이미 모든 줄에 주석이 작성되어 있습니다.');
        }
    } catch (error) {
        const msg = error && error.message ? error.message : String(error);
        output.appendLine('[에러] ' + msg);
        vscode.window.showErrorMessage('컴파일 중 오류가 발생했습니다: ' + msg);
    } finally {
        if (command.outputPath) {
            removeTemporaryExecutable(command.outputPath);
        }
    }
}

/**
 * 컴파일 -> 주석 추가 -> VS Code 통합 터미널에서 대화형 실행
 */
async function runAndComment() {
    const editor = vscode.window.activeTextEditor;
    if (!editor) {
        vscode.window.showWarningMessage("실행할 파일이 열려있지 않습니다.");
        return;
    }

    const document = editor.document;
    const filePath = document.fileName;

    // 헤더 파일은 실행 파일이 아니므로 컴파일 문법 검증 및 주석 추가로 자동 전환
    if (isHeaderFile(filePath)) {
        vscode.window.showInformationMessage("헤더 파일(.h)은 단독 실행 파일이 아니므로 문법 검증 및 주석 추가만 진행합니다.");
        return compileAndComment();
    }

    const language = document.languageId || path.extname(filePath).slice(1);
    const workspaceFolder = vscode.workspace.getWorkspaceFolder(document.uri);
    const workspacePath = workspaceFolder ? workspaceFolder.uri.fsPath : path.dirname(filePath);

    await document.save();
    const command = getCompileCommand(language, filePath, workspacePath);

    if (!command) {
        vscode.window.showWarningMessage('지원하지 않는 언어입니다: ' + language);
        return;
    }

    const output = vscode.window.createOutputChannel('Auto Comment');
    output.clear();
    output.show(true);
    output.appendLine('[컴파일 및 실행 시작] 파일: ' + filePath);

    try {
        // 1. 컴파일 단계
        const compileResult = await spawnAndCapture(command.executable, command.args, workspacePath);
        if (compileResult.output) {
            output.appendLine(compileResult.output);
        }

        if (compileResult.exitCode !== 0) {
            vscode.window.showErrorMessage('컴파일 실패 (코드: ' + compileResult.exitCode + '). 출력 창의 에러 메시지를 확인하세요.');
            return;
        }

        // 2. 컴파일 성공 즉시 주석 먼저 추가!
        output.appendLine('[컴파일 성공] 주석을 추가합니다...');
        await addComments(editor, language);

        // 3. 통합 터미널에서 프로그램 실행 (scanf 등의 키보드 입력을 원활히 처리)
        let terminal = vscode.window.terminals.find(t => t.name === 'Auto Comment Run');
        if (!terminal) {
            terminal = vscode.window.createTerminal('Auto Comment Run');
        }
        terminal.show(true);

        const runCmd = command.runCommandString || (command.outputPath ? '& "' + command.outputPath + '"' : '');
        if (runCmd) {
            terminal.sendText(runCmd);
            vscode.window.showInformationMessage('컴파일 완료 및 주석 추가 완료! 터미널에서 프로그램을 실행합니다.');
        }
    } catch (error) {
        const msg = error && error.message ? error.message : String(error);
        output.appendLine('[에러] ' + msg);
        vscode.window.showErrorMessage('오류 발생: ' + msg);
    }
}

/**
 * 현재 활성 파일에 바로 학습용 주석 추가
 */
async function commentCurrentFile() {
    const editor = vscode.window.activeTextEditor;
    if (!editor) {
        vscode.window.showWarningMessage("주석을 추가할 파일이 열려있지 않습니다.");
        return;
    }

    const language = editor.document.languageId || path.extname(editor.document.fileName).slice(1);
    const updated = await addComments(editor, language);
    vscode.window.showInformationMessage(
        updated ? "현재 파일에 학습용 한글 주석을 추가했습니다." : "추가할 주석이 없거나 이미 주석이 작성되어 있습니다."
    );
}

/**
 * 언어별 컴파일 명령 구성
 */
function getCompileCommand(language, filePath, workspacePath) {
    const quotedFile = quote(filePath);
    const isHeader = isHeaderFile(filePath);

    if (language === 'c' || language === 'cpp' || language === 'c_header' || isHeader) {
        const compiler = (language === 'cpp' || filePath.endsWith('.hpp')) ? 'g++' : 'gcc';
        const ucrtPath = 'C:/msys64/ucrt64/bin/' + compiler + '.exe';
        const executable = (process.platform === 'win32' && fs.existsSync(ucrtPath))
            ? ucrtPath
            : compiler;

        // 헤더 파일인 경우: main() 링크 에러를 방지하기 위해 -fsyntax-only (문법 검증) 수행
        if (isHeader) {
            return {
                executable,
                args: ['-fsyntax-only', '-finput-charset=UTF-8', '-fexec-charset=UTF-8', filePath],
                outputPath: null,
                runCommandString: null,
                displayCommand: compiler + ' -fsyntax-only ' + quotedFile
            };
        }

        // 일반 C/C++ 소스 파일인 경우
        const outputPath = path.join(
            os.tmpdir(),
            'auto-comment-' + crypto.randomUUID() + '.exe'
        );
        const quotedOutput = quote(outputPath);

        return {
            executable,
            args: ['-x', language === 'cpp' ? 'c++' : 'c', '-finput-charset=UTF-8', '-fexec-charset=UTF-8', filePath, '-o', outputPath],
            outputPath,
            runCommandString: '& ' + quotedOutput,
            displayCommand: compiler + ' -x ' + (language === 'cpp' ? 'c++' : 'c') + ' ' + quotedFile + ' -o ' + quotedOutput
        };
    }

    if (language === 'python') {
        return {
            executable: 'python',
            args: ['-m', 'py_compile', filePath],
            outputPath: null,
            runCommandString: 'python ' + quotedFile,
            displayCommand: 'python -m py_compile ' + quotedFile
        };
    }

    if (language === 'javascript') {
        return {
            executable: 'node',
            args: ['--check', filePath],
            outputPath: null,
            runCommandString: 'node ' + quotedFile,
            displayCommand: 'node --check ' + quotedFile
        };
    }

    return null;
}

function removeTemporaryExecutable(filePath) {
    try {
        if (filePath && fs.existsSync(filePath)) {
            fs.rmSync(filePath, { force: true });
        }
    } catch {
        // 임시 파일 정리 무시
    }
}

function spawnAndCapture(executable, args, cwd) {
    return new Promise((resolve) => {
        const child = cp.spawn(executable, args, {
            cwd,
            windowsHide: true,
            encoding: 'utf8'
        });
        let output = '';

        child.stdout?.on('data', (data) => { output += data.toString(); });
        child.stderr?.on('data', (data) => { output += data.toString(); });
        child.on('error', (error) => resolve({ exitCode: 1, output: error.message }));
        child.on('close', (code) => resolve({ exitCode: code ?? 1, output }));
    });
}

/**
 * 소스 코드 각 줄에 맞춤형 한글 학습 주석 추가
 */
async function addComments(editor, language) {
    let original = editor.document.getText();
    const filePath = editor.document.fileName;
    const ext = path.extname(filePath).toLowerCase();
    const isHeaderOrC = ['.c', '.h', '.cpp', '.hpp', '.hxx'].includes(ext) || language === 'c' || language === 'cpp' || language === 'c_header';

    // 1. 문자열 리터럴("...")을 보존하면서 한글 식별자 -> 영어 식별자 변환
    const stringLiterals = [];
    let maskedContent = original.replace(/"(?:\\.|[^"\\])*"/g, (match) => {
        const token = `__STR_LITERAL_${stringLiterals.length}__`;
        stringLiterals.push(match);
        return token;
    });

    let renamed = false;
    for (const [kor, eng] of Object.entries(KOREAN_IDENTIFIER_MAP)) {
        const regex = new RegExp(`(?<![a-zA-Z0-9_가-힣])${kor}(?![a-zA-Z0-9_가-힣])`, 'g');
        if (regex.test(maskedContent)) {
            maskedContent = maskedContent.replace(regex, eng);
            renamed = true;
        }
    }

    original = maskedContent.replace(/__STR_LITERAL_(\d+)__/g, (_, idx) => stringLiterals[Number(idx)]);

    const lines = original.split(/\r?\n/);
    const commentPrefix = isHeaderOrC ? '//' : (language === 'python' ? '#' : '//');
    const result = [];
    let changed = renamed;

    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        const trimmed = line.trim();
        const indentation = line.match(/^\s*/)[0];

        // 빈 줄이거나 단순 괄호인 경우 그대로 유지
        if (!trimmed || trimmed === '{' || trimmed === '}') {
            result.push(line);
            continue;
        }

        // 이미 해당 줄에 주석이 있는 경우 건너뛰기 (C/C++에서는 //, /*만 주석이고 #은 전처리기이므로 제외)
        const isCommentLine = isHeaderOrC
            ? (trimmed.startsWith('//') || trimmed.startsWith('/*'))
            : (trimmed.startsWith('#') || trimmed.startsWith('//'));

        if (isCommentLine) {
            result.push(line);
            continue;
        }

        // 이전 줄이 이미 해당 줄을 설명하는 주석인지 확인
        const prevLine = i > 0 ? lines[i - 1].trim() : '';
        const prevIsComment = isHeaderOrC
            ? (prevLine.startsWith('//') || prevLine.startsWith('/*'))
            : (prevLine.startsWith('#') || prevLine.startsWith('//'));

        if (prevIsComment) {
            result.push(line);
            continue;
        }

        const explanation = explainLine(trimmed, language, ext);
        if (explanation) {
            result.push(indentation + commentPrefix + ' ' + explanation);
            changed = true;
        }
        result.push(line);
    }

    if (changed) {
        const fullRange = new vscode.Range(
            editor.document.positionAt(0),
            editor.document.positionAt(editor.document.getText().length)
        );
        const edit = new vscode.WorkspaceEdit();
        edit.replace(editor.document.uri, fullRange, result.join('\n'));
        await vscode.workspace.applyEdit(edit);
        await editor.document.save();
    }
    return changed;
}

/**
 * 코드 구문 분석 및 초보자 친화적 한글 설명 반환
 */
function explainLine(line, language, ext) {
    const trimmed = (line || '').trim();
    if (!trimmed || trimmed.startsWith('//') || trimmed.startsWith('/*') || trimmed === '{' || trimmed === '}') {
        return '';
    }

    const isHeaderOrC = ['.c', '.h', '.cpp', '.hpp', '.hxx'].includes(ext) || language === 'c' || language === 'cpp' || language === 'c_header';

    if (isHeaderOrC) {
        // 1. 헤더 가드 및 전처리기
        if (/^#pragma\s+once/i.test(trimmed)) {
            return '헤더 파일이 컴파일 중 여러 번 중복 포함(include)되는 것을 방지합니다.';
        }
        if (/^#ifndef\s+[A-Za-z0-9_]+/i.test(trimmed)) {
            return '헤더 중복 포함 방지(인클루드 가드): 해당 매크로가 정의되지 않았을 때만 아래 코드를 포함합니다.';
        }
        if (/^#define\s+[A-Za-z0-9_]+$/i.test(trimmed)) {
            return '헤더 중복 포함 방지 플래그를 정의하여 중복 컴파일을 차단합니다.';
        }
        if (/^#endif\b/i.test(trimmed)) {
            return '조건부 컴파일 전처리기(#ifndef / #ifdef / #if)의 끝을 나타냅니다.';
        }

        // 2. 표준 라이브러리 및 헤더 include
        if (/^#include\s*<stdio\.h>/i.test(trimmed)) {
            return 'printf와 scanf 등 표준 입출력 함수를 사용하기 위해 표준 입출력 헤더를 포함합니다.';
        }
        if (/^#include\s*<stdlib\.h>/i.test(trimmed)) {
            return '동적 메모리 할당(malloc) 및 유틸리티 함수를 사용하기 위해 헤더를 포함합니다.';
        }
        if (/^#include\s*<string\.h>/i.test(trimmed)) {
            return '문자열 복사, 비교 등 문자열 조작 함수를 사용하기 위해 헤더를 포함합니다.';
        }
        if (/^#include\s*<math\.h>/i.test(trimmed)) {
            return '제곱근, 거듭제곱 등 수학 연산 함수를 사용하기 위해 헤더를 포함합니다.';
        }
        if (/^#include\s*<stdbool\.h>/i.test(trimmed)) {
            return 'C 언어에서 bool(true, false) 타입을 사용하기 위해 헤더를 포함합니다.';
        }
        if (/^#include\s*<time\.h>/i.test(trimmed)) {
            return '시간 측정 및 날짜/시간 처리를 위해 시간 헤더를 포함합니다.';
        }
        if (/^#include\s*<[^>]+>/i.test(trimmed)) {
            return '프로그램에 필요한 C 표준 라이브러리 헤더 파일을 포함합니다.';
        }
        if (/^#include\s*"[^"]+"/i.test(trimmed)) {
            return '프로젝트 내부에서 작성한 사용자 정의 헤더 파일을 포함합니다.';
        }

        // 3. 매크로 상수 및 전처리기
        if (/^#define\s+[A-Za-z0-9_]+\s+.+/i.test(trimmed)) {
            return '상수나 매크로를 정의하여 가독성을 높이고 일괄 변경을 용이하게 합니다.';
        }

        // 4. 구조체 및 typedef
        if (/^typedef\s+struct\b/i.test(trimmed)) {
            return '연관된 여러 데이터를 하나로 묶는 구조체를 정의하고 새 타입명을 부여합니다.';
        }
        if (/^\}\s*[A-Za-z0-9_]+\s*;/i.test(trimmed)) {
            return '구조체 정의를 마치고 새로운 자료형 타입명으로 등록합니다.';
        }
        if (/^struct\s+[A-Za-z0-9_]+(\s*\{)?$/i.test(trimmed)) {
            return '사용자 정의 데이터 타입인 구조체를 선언합니다.';
        }
        if (/^typedef\s+[^;]+;/i.test(trimmed)) {
            return '기존 자료형에 직관적인 새 이름을 부여하는 타입 재정의(typedef)입니다.';
        }
        if (/^extern\s+/i.test(trimmed)) {
            return '다른 소스 파일에 정의된 전역 변수 또는 함수를 현재 파일에서 참조할 수 있게 선언합니다.';
        }

        // 5. 입출력 함수 호출 (함수 선언보다 먼저 평가)
        if (trimmed.startsWith('scanf(') || trimmed.includes('scanf(')) {
            return '키보드(표준 입력)로부터 서식에 맞추어 데이터를 입력받아 변수에 저장합니다.';
        }
        if (trimmed.startsWith('printf(') || trimmed.includes('printf(')) {
            return '서식 문자열에 맞추어 화면에 텍스트와 변수 값을 출력합니다.';
        }

        // 6. 함수 선언 (프로토타입) 및 정의
        if (/\bmain\s*\(/.test(trimmed)) {
            return '프로그램 실행이 시작되는 메인(main) 함수입니다.';
        }
        if (/^(void|int|float|double|char|long|short|bool|size_t|[A-Za-z0-9_]+_t)\s+(\*+\s*)?[A-Za-z0-9_]+\s*\([^;{}]*\)\s*;/i.test(trimmed)) {
            return '다른 파일이나 함수에서 호출할 수 있도록 함수의 반환형과 매개변수를 미리 선언하는 함수 원형(프로토타입)입니다.';
        }
        if (/^(void|int|float|double|char|long|short|bool|size_t|[A-Za-z0-9_]+_t)\s+(\*+\s*)?[A-Za-z0-9_]+\s*\([^;{}]*\)\s*\{?$/i.test(trimmed)) {
            return '특정 기능을 수행하는 함수의 본문을 정의합니다.';
        }

        // 7. 변수 선언 및 배열
        if (/char\s+[a-zA-Z0-9_]+\[\d+\]/.test(trimmed)) {
            return '문자열을 저장하기 위한 문자형(char) 배열을 선언합니다.';
        }
        if (/^\s*(int|float|double|char|long|short|bool)\b[^;]*;/.test(trimmed)) {
            return '데이터를 저장하고 처리하기 위한 변수를 선언합니다.';
        }

        // 8. 제어문
        if (/^\s*if\s*\(/.test(trimmed)) {
            return '주어진 조건식이 참(True)인지 판별하여 조건에 맞을 때 실행합니다.';
        }
        if (/^\s*else\s+if\s*\(/.test(trimmed)) {
            return '앞선 조건이 거짓일 때 새로운 조건식을 검사하여 분기합니다.';
        }
        if (/^\s*else\b/.test(trimmed)) {
            return '위의 모든 조건이 만족되지 않을 때 기본으로 실행되는 블록입니다.';
        }
        if (/^\s*for\s*\(/.test(trimmed)) {
            return '초기식, 조건식, 증감식에 따라 정해진 횟수만큼 반복 실행합니다.';
        }
        if (/^\s*while\s*\(/.test(trimmed)) {
            return '조건식이 참인 동안 내부 코드 블록을 계속 반복 실행합니다.';
        }
        // 9. 반환문 (return)
        if (/^return\s*\(?\s*0\s*\)?\s*;?$/i.test(trimmed)) {
            return '프로그램이 성공적으로 완료되었음을 운영체제에 알리고 0을 반환합니다.';
        }
        if (/^return\s*;?$/i.test(trimmed)) {
            return '함수의 실행을 즉시 종료하고 호출한 곳으로 돌아갑니다.';
        }
        if (/^return\b/i.test(trimmed)) {
            return '함수의 실행을 마치고 결과값을 호출한 곳으로 반환합니다.';
        }
    }

    if (language === 'python') {
        if (line.startsWith('import ') || line.startsWith('from ')) return '필요한 외부 라이브러리나 모듈을 불러옵니다.';
        if (line.startsWith('def ')) return '특정 작업을 수행하는 사용자 정의 함수를 정의합니다.';
        if (line.includes('input(')) return '사용자로부터 키보드 입력을 받아 문자열로 저장합니다.';
        if (line.includes('print(')) return '화면에 문자열이나 계산 결과를 출력합니다.';
        if (line.startsWith('if ')) return '조건을 검사하여 참일 때 하위 코드를 실행합니다.';
        if (line.startsWith('elif ')) return '앞선 조건이 아닐 때 새로운 조건을 검사합니다.';
        if (line.startsWith('else:')) return '위 조건들이 모두 거짓일 때 실행할 기본 블록입니다.';
        if (line.startsWith('for ')) return '시퀀스(리스트, 범위 등)의 항목을 하나씩 순회하며 반복합니다.';
        if (line.startsWith('while ')) return '조건이 참인 동안 반복을 계속 수행합니다.';
        if (line.startsWith('return ')) return '함수 실행을 종료하고 결과값을 반환합니다.';
    }

    if (language === 'javascript') {
        if (line.startsWith('const ') || line.startsWith('let ')) return '값을 저장할 변수를 선언합니다.';
        if (line.startsWith('function ')) return '작업을 수행할 함수를 정의합니다.';
        if (line.includes('console.log(')) return '브라우저 콘솔이나 터미널에 메시지를 출력합니다.';
        if (line.startsWith('if (')) return '조건식을 평가하여 분기 실행합니다.';
        if (line.startsWith('return ')) return '함수의 결과값을 반환하고 종료합니다.';
    }

    return '';
}

function quote(value) {
    return '"' + value.replace(/\x22/g, '\\x22') + '"';
}

function deactivate() {}

module.exports = {
    activate,
    deactivate,
    compileAndComment,
    runAndComment,
    commentCurrentFile,
    addComments,
    explainLine,
    getCompileCommand
};
