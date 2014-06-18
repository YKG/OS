nasm -f elf -o kernel.o kernel.asm
ld -s -Ttext 0x30400 -o KERNEL.BIN kernel.o
sudo rm   /mnt/floppy/kernel* 
sudo cp KERNEL.BIN /mnt/floppy
