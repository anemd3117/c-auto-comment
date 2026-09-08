const fs = require('fs');
const path = require('path');

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

function explainLine(line, ext) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('//') || trimmed.startsWith('/*') || trimmed.startsWith('# [') || trimmed === '{' || trimmed === '}') {
        return '';
    }

    const isHeaderOrC = ['.c', '.h', '.cpp', '.hpp'].includes(ext);

    if (isHeaderOrC) {
        // 1. 헤더 가드 및 전처리기
        if (trimmed.startsWith('#pragma once')) {
            return '헤더 파일이 컴파일 중 여러 번 중복 포함(include)되는 것을 방지합니다.';
        }
        if (/^#ifndef\s+[A-Za-z0-9_]+/.test(trimmed)) {
            return '헤더 중복 포함 방지(인클루드 가드): 해당 매크로가 정의되지 않았을 때만 아래 코드를 포함합니다.';
        }
        if (/^#define\s+[A-Za-z0-9_]+$/.test(trimmed)) {
            return '헤더 중복 포함 방지 플래그를 정의하여 중복 컴파일을 차단합니다.';
        }
        if (trimmed === '#endif') {
            return '조건부 컴파일 전처리기(#ifndef / #ifdef / #if)의 끝을 나타냅니다.';
        }

        // 2. 표준 라이브러리 및 사용자 헤더 include
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
        if (/^#include\s*<[^>]+>/.test(trimmed)) {
            return '프로그램에 필요한 C 표준 라이브러리 헤더 파일을 포함합니다.';
        }
        if (/^#include\s*"[^"]+"/.test(trimmed)) {
            return '프로젝트 내부에서 작성한 사용자 정의 헤더 파일을 포함합니다.';
        }

        // 3. 매크로 상수
        if (/^#define\s+[A-Za-z0-9_]+\s+.+/.test(trimmed)) {
            return '상수나 매크로를 정의하여 가독성을 높이고 일괄 변경을 용이하게 합니다.';
        }

        // 4. 구조체 및 typedef (헤더/소스 공통)
        if (/^typedef\s+struct\b/.test(trimmed)) {
            return '연관된 여러 데이터를 하나로 묶는 구조체를 정의하고 새 타입명을 부여합니다.';
        }
        if (/^\}\s*[A-Za-z0-9_]+\s*;/.test(trimmed)) {
            return '구조체 정의를 마치고 새로운 자료형 타입명으로 등록합니다.';
        }
        if (/^struct\s+[A-Za-z0-9_]+(\s*\{)?$/.test(trimmed)) {
            return '사용자 정의 데이터 타입인 구조체를 선언합니다.';
        }
        if (/^typedef\s+[^;]+;/.test(trimmed)) {
            return '기존 자료형에 직관적인 새 이름을 부여하는 타입 재정의(typedef)입니다.';
        }
        if (/^extern\s+/.test(trimmed)) {
            return '다른 소스 파일에 정의된 전역 변수 또는 함수를 현재 파일에서 참조할 수 있게 선언합니다.';
        }

        // 5. 입출력 함수 호출
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
        if (/^(void|int|float|double|char|long|short|bool|size_t|[A-Za-z0-9_]+_t)\s+(\*+\s*)?[A-Za-z0-9_]+\s*\([^;{}]*\)\s*;/.test(trimmed)) {
            return '다른 파일이나 함수에서 호출할 수 있도록 함수의 반환형과 매개변수를 미리 선언하는 함수 원형(프로토타입)입니다.';
        }
        if (/^(void|int|float|double|char|long|short|bool|size_t|[A-Za-z0-9_]+_t)\s+(\*+\s*)?[A-Za-z0-9_]+\s*\([^;{}]*\)\s*\{?$/.test(trimmed)) {
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
        if (/^return\s*\(?\s*0\s*\)?\s*;?$/.test(trimmed)) {
            return '프로그램이 성공적으로 완료되었음을 운영체제에 알리고 0을 반환합니다.';
        }
        if (/^return\s*;?$/.test(trimmed)) {
            return '함수의 실행을 즉시 종료하고 호출한 곳으로 돌아갑니다.';
        }
        if (/^return\b/.test(trimmed)) {
            return '함수의 실행을 마치고 결과값을 호출한 곳으로 반환합니다.';
        }
    }

    return '';
}

function processFile(targetFilePath) {
    if (!fs.existsSync(targetFilePath)) {
        console.error(`[AutoComment] 파일을 찾을 수 없습니다: ${targetFilePath}`);
        process.exit(1);
    }

    const ext = path.extname(targetFilePath).toLowerCase();
    const isHeaderOrC = ['.c', '.h', '.cpp', '.hpp'].includes(ext);
    let content = fs.readFileSync(targetFilePath, 'utf8');

    // 1. 문자열 리터럴("...")을 보존하면서 한글 식별자 -> 영어 식별자 변환
    const stringLiterals = [];
    let maskedContent = content.replace(/"(?:\\.|[^"\\])*"/g, (match) => {
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
            console.log(`[AutoComment] 한글 식별자 변환: '${kor}' -> '${eng}'`);
        }
    }

    content = maskedContent.replace(/__STR_LITERAL_(\d+)__/g, (_, idx) => stringLiterals[Number(idx)]);

    // 2. 학습용 주석 추가
    const lines = content.split(/\r?\n/);
    const result = [];
    let commentCount = 0;

    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        const trimmed = line.trim();
        const indentation = line.match(/^\s*/)[0];

        if (!trimmed || trimmed === '{' || trimmed === '}') {
            result.push(line);
            continue;
        }

        // 이미 주석인 줄 (C/C++에서는 //와 /*만 주석, 파이썬에서만 #이 주석)
        const isCommentLine = isHeaderOrC
            ? (trimmed.startsWith('//') || trimmed.startsWith('/*'))
            : (trimmed.startsWith('#') || trimmed.startsWith('//'));

        if (isCommentLine) {
            result.push(line);
            continue;
        }

        // 바로 윗 줄이 이미 주석인 경우 중복 추가 방지
        const prevLine = i > 0 ? lines[i - 1].trim() : '';
        const prevIsComment = isHeaderOrC
            ? (prevLine.startsWith('//') || prevLine.startsWith('/*'))
            : (prevLine.startsWith('#') || prevLine.startsWith('//'));

        if (prevIsComment) {
            result.push(line);
            continue;
        }

        const explanation = explainLine(trimmed, ext);
        if (explanation) {
            result.push(`${indentation}// ${explanation}`);
            commentCount++;
        }
        result.push(line);
    }

    fs.writeFileSync(targetFilePath, result.join('\r\n'), 'utf8');
    console.log(`[AutoComment] 완료: ${path.basename(targetFilePath)} (${commentCount}개 주석 추가됨)`);
}

// CLI 진입점
const target = process.argv[2];
if (!target) {
    console.log('사용법: node auto_comment.js <파일경로>');
    process.exit(0);
}

processFile(target);
