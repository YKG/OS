这个里面的文件和d目录下面的完全一样

唯一的区别是，boot.asm 中的 DestOffset 变成了 0000h
              idt3.asm 中的 org 0100h 注释了，默认为 org 0h
