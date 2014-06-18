
ASM		= nasm
CC		= gcc -c
LD		= ld
BOOTER		= boot/boot.bin
LOADER		= boot/loader.bin
KERNEL		= kernel.bin
TARGETS		= $(BOOTER) $(LOADER) $(KERNEL)
ASM_BOOTER_ARGS	= -I boot/include/ # 后面的"/"务必加上！还得我花了好多时间！
ASM_LOADER_ARGS	= -I boot/include/ # 后面的"/"务必加上！还得我花了好多时间！
ASM_KERNEL_ARGS	= -f elf
CC_KERNEL_ARGS	= -I include/
OBJS		= kernel/kernel.o kernel/start.o kernel/i8259.o kernel/protect.o lib/string.o lib/kliba.o kernel/main.o kernel/syscall.o kernel/proc.o kernel/clock.o 
LD_KERNEL_ARGS	= -s -Ttext 0x030400


.PHONY: all everything clean realclean image building
####################################################################################
# Makefile 的格式要求很严格，和动作在一行的是依赖(必须在一行)，
# 下面的都是命令，命令不能放在与动作同行，
# 不能错行，命令前面必须有TAB
####################################################################################

everything: $(TARGETS)	

all: realclean everything 

clean:	
	rm $(OBJS)

realclean: clean
	rm $(TARGETS)

image: all building
	
buildimg:
	dd if=$(BOOTER) of=a.img bs=512 count=1 conv=notrunc
	sudo mount -o loop a.img /mnt/floppy/
	sudo cp -fv $(LOADER) /mnt/floppy/
	sudo cp -fv $(KERNEL) /mnt/floppy/
	sudo umount /mnt/floppy/

###########################################################################
# 累死我了！终于找到问题出处，这里不能直接把命令最后的 $(OBJS) 用 $< 代替！
# $< 应该只是用依赖文件的第一个替换！不包括第二个及以后
###########################################################################
$(KERNEL): $(OBJS)	
	$(LD) $(LD_KERNEL_ARGS) -o $@ $(OBJS)

$(LOADER): boot/loader.asm boot/include/pm.inc.asm boot/include/fat12hdr.inc.asm boot/include/lib.inc.asm 
	$(ASM) $(ASM_LOADER_ARGS) -o $@ $<

$(BOOTER): boot/boot.asm boot/include/fat12hdr.inc.asm
	$(ASM) $(ASM_BOOTER_ARGS) -o $@ $<	

kernel/start.o: kernel/start.c include/const.h include/type.h include/proto.h include/global.h include/string.h
	$(CC) $(CC_KERNEL_ARGS)   -o $@ $<

kernel/protect.o: kernel/protect.c include/const.h include/type.h include/proto.h include/global.h
	$(CC) $(CC_KERNEL_ARGS)   -o $@ $<

kernel/i8259.o: kernel/i8259.c include/const.h include/type.h include/proto.h include/global.h
	$(CC) $(CC_KERNEL_ARGS)   -o $@ $<

kernel/main.o: kernel/main.c include/const.h include/type.h include/proto.h include/global.h include/string.h
	$(CC) $(CC_KERNEL_ARGS)   -o $@ $<

kernel/proc.o: kernel/proc.c include/const.h include/type.h include/proto.h include/global.h include/string.h
	$(CC) $(CC_KERNEL_ARGS)   -o $@ $<

kernel/clock.o: kernel/clock.c include/const.h include/type.h include/proto.h include/global.h include/string.h
	$(CC) $(CC_KERNEL_ARGS)   -o $@ $<

kernel/kernel.o: kernel/kernel.asm
	$(ASM) $(ASM_KERNEL_ARGS) -o $@ $<

kernel/syscall.o: kernel/syscall.asm
	$(ASM) $(ASM_KERNEL_ARGS) -o $@ $<

lib/kliba.o: lib/kliba.asm
	$(ASM) $(ASM_KERNEL_ARGS) -o $@ $<

lib/string.o: lib/string.asm
	$(ASM) $(ASM_KERNEL_ARGS) -o $@ $<




