用GDB 调试 内核

http://groups.google.com/group/osfromscratch/browse_thread/thread/b993d6b3bc657190/3395149ab070beae?lnk=gst&q=bochs+C#3395149ab070beae


下面是我根据本 Group 里面的各位牛人以及网络上一些其它资料整理出来的简明教程： 

        1. 编译 bochs 前 
                $ ./configure --enable-gdb-stub 
        2. 修改 Makefile 
                 i. 将 CFLAGS 加入 -g 选项，以便加入调试符号 
                        CFLAGS          = -I include/ -I include/sys/ -c -g 
-fno-builtin -Wall 
                ii. 由于加了调试符号之后 kernel.bin 太大，所以将其 strip 之后在拷贝入磁盘映像。将这一行 
                        sudo cp -fv kernel.bin /mnt/floppy 
                    改为 
                        strip kernel.bin -o kernel.bin.stripped 
                        sudo cp -fv kernel.bin.stripped 
/mnt/floppy/kernel.bin 
                如此一来，在 bochs 虚拟机里面执行的 kernel.bin 是 strip 之后的， 
                过会儿用来交给 gdb 的 kernel.bin 是带调试符号的。 
        3. 编译内核 
                $ make image 
        4. 修改 bochsrc，加入这么一行： 
                gdbstub: enabled=1, port=1234, text_base=0, data_base=0, 
bss_base=0 
        5. 启动内核 
                $ bochs -q -f bochsrc.gdb       # 注意必须用加入了 --enable-gdb-stub 
编译选项的 bochs 
        6. 打开另一控制台，用 gdb 调试 
                $ gdb 
        7. 在 gdb 中调试 
                (gdb) file kernel.bin  ← 注意这里的 kernel.bin 必须是加入了 -g 
编译选项的带调试符号的内核 
                Reading symbols from 
/home/forrest/local/src/osfs/oranges/phases/chapter11/a/kernel.bin...done. 
                (gdb) target remote localhost:1234 
                Remote debugging using localhost:1234 
                0x0000fff0 in ?? () 
                (gdb) b start.c:26 
                Breakpoint 1 at 0x14a6: file kernel/start.c, line 26. 
                (gdb) c 
                Continuing. 

                Breakpoint 1, cstart () at kernel/start.c:26 
                26 
disp_str("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n-----\"cstart\" begins-----\n"); 
                (gdb) n 
                29              memcpy( &gdt, 
/* New GDT */ 
                (gdb) 
        8. 由于每次都需要执行 file kernel.bin 和 target remote localhost:1234 
两个命令，所以可以建立一个 .gdbinit 文件，比如： 
                $ vi .gdbinit 
                file kernel.bin 
                target remote localhost:1234 
                set disassembly-flavor intel 
                b start.c:26 
                b start.c:37 
                b start.c:40 
           这样下次直接执行 gdb 这个文件里的命令即可自动执行。 
        9. 在 .gdbinit 中添加自定义函数，比如： 
                define lsproc 
                  set $count = 16 
                  set $idx = 0 
                  printf "The first %d TASKS/PROCS:\n",$count 
                  while($idx < $count) 
                    if(proc_table[$idx].p_flags != 0x20) 
                      if($idx < 5) 
                        printf "[%2d] TASK: %8s",$idx,proc_table[$idx].name 
                        printf "\t p_flags: %8Xh\n",proc_table[$idx].p_flags 
                      else 
                        printf "[%2d] PROC: %8s",$idx,proc_table[$idx].name 
                        printf "\t p_flags: %8Xh\n",proc_table[$idx].p_flags 
                      end 
                    end 
                    set $idx++ 
                  end 
                end 
           这样在 gdb 中可直接调用 lsproc： 
                (gdb) lsproc 
                The first 16 TASKS/PROCS: 
                [ 0] TASK:      TTY      p_flags:        4h 
                [ 1] TASK:      SYS      p_flags:        4h 
                [ 2] TASK:       HD      p_flags:        4h 
                [ 3] TASK:       FS      p_flags:        4h 
                [ 4] TASK:       MM      p_flags:        4h 
                [ 5] PROC:     INIT      p_flags:        Ch 
                [ 6] PROC:    TestA      p_flags:        0h 
                [ 7] PROC:    TestB      p_flags:        0h 
                [ 8] PROC:    TestC      p_flags:        0h 
                [ 9] PROC:   INIT_9      p_flags:        4h 
                [10] PROC:  INIT_10      p_flags:        4h 
           用 help 命令可查看所有自定义函数的列表： 
                (gdb) help user-defined 
                User-defined commands. 
                The commands in this class are those defined by the user. 
                Use the "define" command to define a command. 

                List of commands: 

                lsproc -- User-defined 

                Type "help" followed by command name for full documentation. 
                Type "apropos word" to search for commands related to 
"word". 
                Command name abbreviations are allowed if unambiguous. 

        REFs: 

http://bochs.sourceforge.net/doc/docbook/user/debugging-with-gdb.html 
                http://narmy.cn/linux/read.php/118.htm 
                http://wangfei.me/?p=44 

http://www.oldlinux.org/oldlinux/viewthread.php?tid=3809&extra=page%3D2 

http://www.cs.princeton.edu/courses/archive/fall09/cos318/precepts/bo... 
                http://sourceware.org/gdb/current/onlinedocs/ 
                （这里的 REF 可能不全，如果我用了你的资料但却没有列在这里，请一定跟我联系） 

Y²* 
* 

