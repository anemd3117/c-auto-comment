# C/C++ 스마트 빌드 & 학습용 자동 주석 시스템 (Auto Comment)

> **C/C++ 초보자 및 학습자를 위한 VS Code 자동 주석 & 스마트 빌드 도구**  
> 소스 파일(`.c`)과 헤더 파일(`.h`)의 컴파일 검증 및 구문 분석을 통해 초보자 친화적인 **학습용 한글 주석을 자동으로 생성**하고, 한글 변수명을 표준 영어 식별자로 자동 변환합니다.

---

## 🌟 주요 기능 (Key Features)

1. **헤더 파일(`.h`, `.hpp`) 완벽 지원**:
   - `main()` 함수가 없는 헤더 파일도 `-fsyntax-only`로 문법 검증 후 에러 없이 주석 생성
   - `#pragma once`, `#ifndef`, `#define`, `#endif` (인클루드 가드)
   - `struct`, `typedef`, 함수 원형(프로토타입), 매크로 상수 설명 지원
2. **C 소스 파일(`.c`, `.cpp`) 및 return 구문 지원**:
   - `#include <stdio.h>` 등 표준/사용자 헤더 include 구문 주석화
   - `return 0;`, `return (0);`, `return;`, `return a + b;` 등 다양한 반환문 패턴 인식
   - `scanf`, `printf`, 조건문(`if`/`else`), 반복문(`for`/`while`) 상세 해설 주석 추가
3. **한글 변수 자동 영문화 & 출력 문자열 보호**:
   - `int 가로, 세로, 넓이;` ➡️ `int width, height, area;` 자동 치환
   - `printf("가로: %d\n", width);`처럼 따옴표 내부의 출력 한글 텍스트는 100% 안전하게 보존
4. **외부 PC 완벽 이식성**:
   - Git 클론 후 원클릭 설치 스크립트 제공
   - 확장 프로그램 미설치 환경에서도 VS Code 내장 태스크(`Ctrl+Shift+B`)로 100% 동작하는 무설치 포터블 모드 탑재

---

## 💻 외부 PC에서 1분 만에 설치 및 실행하기 (Quick Start)

### 방법 1. Git 클론 & 원클릭 설치 (가장 추천 ⭐)

외부 PC의 터미널(Git Bash, CMD, PowerShell)에서 아래 명령어를 순서대로 실행합니다:

```bash
# 1. 저장소 다운로드
git clone https://github.com/anemd3117/c-auto-comment.git
cd c-auto-comment

# 2. VS Code 확장 원클릭 설치 (더블클릭 실행 가능)
.\install-extension.bat

# 3. VS Code로 프로젝트 열기
code .
```

설치 후 VS Code 에디터 우측 상단의 주석 버튼이나 단축키를 바로 사용하시면 됩니다:
- ⌨️ **`F6`** : 컴파일 문법 검증 후 즉시 주석 추가
- 💬 **현재 파일 즉시 주석 버튼** : 컴파일 없이 에디터 파일에 즉시 주석 부여
- ▶️ **실행 및 자동 주석 버튼** : 컴파일 ➡️ 주석 추가 ➡️ 터미널에서 실행(scanf 입력 가능)

---

### 방법 2. 확장 프로그램 없이 바로 쓰는 무설치 포터블 모드

별도의 확장을 설치하지 않고도, 프로젝트 폴더만 열면 즉시 동작합니다:

```bash
git clone https://github.com/anemd3117/c-auto-comment.git
code c-auto-comment
```

- 소스 파일(`.c`) 또는 헤더 파일(`.h`)을 열고 **`Ctrl + Shift + B`** (기본 빌드 단축키)만 누르면:
  1. 헤더 파일은 문법 검사(`-fsyntax-only`)
  2. C 소스 파일은 `output/*.exe`로 안전 컴파일
  3. 성공 시 에디터 파일에 **학습용 한글 주석이 즉시 자동 반영 및 저장**됩니다.

---

## 📁 프로젝트 구조 (Directory Structure)

```text
├── .vscode/
│   ├── tasks.json               # 스마트 빌드 및 프로세스 연동 설정
│   └── settings.json            # UTF-8 및 자동화 터미널 프로필 설정
├── scripts/
│   ├── smart_build.ps1          # 소스/헤더 자동 판별 빌드 스크립트
│   └── auto_comment.js          # 한글 식별자 변환 및 주석 파싱 엔진
├── auto-comment-extension/      # VS Code 공식 확장 프로그램 소스
│   ├── extension.js             # 확장 진입점 및 정규식 엔진
│   ├── package.json             # 단축키(F6) 및 UI 버튼 바인딩
│   └── auto-comment-after-run-0.0.6.vsix  # 사전 패키징된 배포용 VSIX
└── install-extension.bat        # 외부 PC 원클릭 설치 배치 파일
```

---

## 📜 라이선스 (License)
MIT License
