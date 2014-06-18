nasm -o gate.com gate.asm
sudo mount -o loop a.img /mnt/floppy
sudo cp gate.com /mnt/floppy
sudo umount /mnt/floppy

