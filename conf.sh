nasm -o ldt.com ldt.asm
sudo mount -o loop a.img /mnt/floppy
sudo cp ldt.com /mnt/floppy
sudo umount /mnt/floppy

