
ASM		= nasm
CC		= gcc -c -g -fno-builtin -Wall 
LD		= ld
BOOTER		= boot/boot.bin
LOADER		= boot/loader.bin
KERNEL		= kernel/kernel.bin
TARGETS		= $(BOOTER) $(LOADER) $(KERNEL)
ASM_LOADER_ARGS	= -I boot/include/ # 后面的"/"务必加上！还得我花了好多时间！
ASM_KERNEL_ARGS	= -g -f elf
OBJS		= kernel/kernel.o kernel/start.o lib/string.o lib/kliba.o
LD_KERNEL_ARGS	= -g -Ttext 0x030400  # 把 -s 去掉才能用于gdb调试


.PHONY: everything clean realclean image building
####################################################################################
# Makefile 的格式要求很严格，和动作在一行的是依赖(必须在一行)，
# 下面的都是命令，命令不能放在与动作同行，
# 不能错行，命令前面必须有TAB
####################################################################################

everything: $(TARGETS)

all: realclean everything clean
	
clean:	
	rm $(OBJS)

realclean: clean	
	rm $(TARGETS)

image: all building
	
buildimg:
	dd if=$(BOOTER) of=a.img bs=512 count=1 conv=notrunc
	sudo mount -o loop a.img /mnt/floppy/
	sudo cp -fv $(LOADER) /mnt/floppy/
#	sudo cp -fv $(KERNEL) /mnt/floppy/
	strip $(KERNEL) -o $(KERNEL).stripped 
	sudo cp -fv $(KERNEL).stripped /mnt/floppy/
	sudo umount /mnt/floppy/

###########################################################################
# 累死我了！终于找到问题出处，这里不能直接把命令最后的 $(OBJS) 用 $< 代替！
# $< 应该只是用依赖文件的第一个替换！不包括第二个及以后
###########################################################################
$(KERNEL): $(OBJS)	
	$(LD) $(LD_KERNEL_ARGS) -o $@ $(OBJS)

$(LOADER): boot/loader.asm boot/include/pm.inc boot/include/lib.inc
	$(ASM) $(ASM_LOADER_ARGS) -o $@ $<

$(BOOTER): boot/boot.asm
	$(ASM) -o $@ $<	

kernel/start.o: kernel/start.c
	$(CC) -o $@ $<

kernel/kernel.o: kernel/kernel.asm
	$(ASM) $(ASM_KERNEL_ARGS) -o $@ $<

lib/kliba.o: lib/kliba.asm
	$(ASM) $(ASM_KERNEL_ARGS) -o $@ $<

lib/string.o: lib/string.asm
	$(ASM) $(ASM_KERNEL_ARGS) -o $@ $<
