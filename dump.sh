#xxd -u -a -g 1 -c 16 -s 0x2600 -l 512 a.img
# 0x200	   第 1扇区  FAT1
# 0x2600   第19扇区  根目录区
# 0x4200   第33扇区  数据区
xxd -u -a -g 1 -c 16 -s $1 -l 512 a.img
