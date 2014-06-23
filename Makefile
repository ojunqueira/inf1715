
all:
	./mini0 test/testa.m0
	gcc -o test/testa test/main.c test/testa.s

clean:
	rm test/*.o test/*.icg test/*.s test/testa

