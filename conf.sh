nasm -o pm2.com pm2.asm
sudo mount -o loop a.img /mnt/floppy
sudo cp pm2.com /mnt/floppy
sudo umount /mnt/floppy

