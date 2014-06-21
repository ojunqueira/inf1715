#include <stdio.h>

int sum (int a, int b);
int sub (int a, int b);
int mul (int a, int b);
int div (int a, int b);

int main (void) {
    int a = 10;
    int b = 5;
    printf("Soma %d + %d = %d\n", a, b, sum(a,b));
    printf("Subtrai %d - %d = %d\n", a, b, sub(a,b));
    printf("Multiplica %d * %d = %d\n", a, b, mul(a,b));
    printf("Divide %d / %d = %d\n", a, b, div(a,b));
    return 0;
}
