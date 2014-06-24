
#include <stdio.h>

void printInt(int n) {
    printf("%d\n", n);
}

int main() {
    int ok;
    
    printf("Serie de Fibonacci!\n");
    
    ok = testa();
    
    if (ok == 42) {
        printf("Mini-0 retornou %d como esperado!\n", ok);
    } else {
        printf("Mini-0 retornou %d\n", ok);
    }
    return 0;
}

