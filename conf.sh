nasm -o $1.com $1.asm
sudo mount -o loop a.img /mnt/floppy
sudo cp $1.com /mnt/floppy
sudo umount /mnt/floppy

