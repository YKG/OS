#xxd -u -a -g 1 -c 16 -s 0x2600 -l 512 a.img
xxd -u -a -g 1 -c 16 -s $1 -l 512 a.img
