all:
	as main.s -o main.o
	ld main.o -o main
	sudo ./main