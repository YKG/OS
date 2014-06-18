nasm -o $1.com $1.asm
sudo mount -o loop pm.img /mnt/floppy
sudo cp $1.com /mnt/floppy
sudo umount /mnt/floppy

