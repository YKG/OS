#nasm boot.asm -o boot.bin
#dd if=boot.bin of=a.img bs=512 count=1 conv=notrunc
nasm loader.asm -o LOADER.BIN
./mount.sh
./cp.sh
./umount.sh

