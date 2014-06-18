nasm -f elf -o kernel.o kernel.asm
nasm -f elf -o string.o string.asm
nasm -f elf -o kliba.o kliba.asm
gcc -c -o start.o start.c
ld -s -Ttext 0x30400 -o KERNEL.BIN kernel.o start.o string.o kliba.o
./mount.sh
sudo rm   /mnt/floppy/kernel* 
sudo cp KERNEL.BIN /mnt/floppy
./umount.sh
