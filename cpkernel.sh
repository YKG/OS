nasm -f elf -o kernel.o kernel.asm
gcc -c -o start.o start.c
ld -s -Ttext 0x30400 -o KERNEL.BIN kernel.o start.o
./mount.sh
sudo rm   /mnt/floppy/kernel* 
sudo cp KERNEL.BIN /mnt/floppy
./umount.sh
