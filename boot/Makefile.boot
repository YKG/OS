
ASM		= nasm
TARGET		= boot.bin LOADER.BIN
LOADER_ARGS	= -I include/	# 后面的/务必加上！还得我花了好多时间！

.PHONY: everything

# Makefile 的格式要求很严格，和动作在一行的是依赖(必须在一行)，
# 下面的都是命令，命令不能放在与动作同行，
# 不能错行，命令前面必须有TAB
everything: $(TARGET)
	
clean:	
	rm $(TARGET)
	ls
	

boot.bin: boot.asm
	$(ASM) -o $@ $<	

LOADER.BIN: loader.asm include/pm.inc include/lib.inc
	$(ASM) $(LOADER_ARGS) -o $@ $<

