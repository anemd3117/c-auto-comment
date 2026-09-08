// printf와 scanf 등 표준 입출력 함수를 사용하기 위해 표준 입출력 헤더를 포함합니다.
#include <stdio.h>

// 프로그램 실행이 시작되는 메인(main) 함수입니다.
int main()
{
    // 데이터를 저장하고 처리하기 위한 변수를 선언합니다.
    int width, height;
    // 키보드(표준 입력)로부터 서식에 맞추어 데이터를 입력받아 변수에 저장합니다.
    scanf("%d %d", &width, &height);
    // 서식 문자열에 맞추어 화면에 텍스트와 변수 값을 출력합니다.
    printf("width: %d\nheight: %d\n", width, height);
    // 프로그램이 성공적으로 완료되었음을 운영체제에 알리고 0을 반환합니다.
    return 0;
}