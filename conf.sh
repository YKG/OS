nasm -f elf -g -o foo.o foo.asm
gcc -c -g -o bar.o bar.c
ld -g -o foobar foo.o bar.o

