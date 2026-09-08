// 헤더 파일이 컴파일 중 여러 번 중복 포함(include)되는 것을 방지합니다.
#pragma once
// 헤더 중복 포함 방지(인클루드 가드): 해당 매크로가 정의되지 않았을 때만 아래 코드를 포함합니다.
#ifndef TEST_H
// 헤더 중복 포함 방지 플래그를 정의하여 중복 컴파일을 차단합니다.
#define TEST_H

// printf와 scanf 등 표준 입출력 함수를 사용하기 위해 표준 입출력 헤더를 포함합니다.
#include <stdio.h>

// 상수나 매크로를 정의하여 가독성을 높이고 일괄 변경을 용이하게 합니다.
#define MAX_BUFFER_SIZE 1024

// 연관된 여러 데이터를 하나로 묶는 구조체를 정의하고 새 타입명을 부여합니다.
typedef struct {
    // 데이터를 저장하고 처리하기 위한 변수를 선언합니다.
    int id;
    // 문자열을 저장하기 위한 문자형(char) 배열을 선언합니다.
    char name[32];
// 구조체 정의를 마치고 새로운 자료형 타입명으로 등록합니다.
} Student;

// 다른 파일이나 함수에서 호출할 수 있도록 함수의 반환형과 매개변수를 미리 선언하는 함수 원형(프로토타입)입니다.
int calculateTotal(int kor, int eng, int math);
// 다른 파일이나 함수에서 호출할 수 있도록 함수의 반환형과 매개변수를 미리 선언하는 함수 원형(프로토타입)입니다.
void printStudentInfo(Student s);

// 조건부 컴파일 전처리기(#ifndef / #ifdef / #if)의 끝을 나타냅니다.
#endif
