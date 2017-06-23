# learning-Assembly
for c language \\\
all_ascii.asm: 按规则输出0000-00FF所有的ASCII码值\\\
chan_bytes.asm:两个小于65535的数相乘按照固定的格式输出其十进制二进制以及十六进制结果\\\
openfile.asm: 打开文件并将内容使用16进制输出到屏幕上将文件偏移地址（32位）也使用16进制输出  '|'前景色0fh高亮显示--pagedown:下一页 pageup：下一页 home：第一页 end:最后一页
openfile_final.asm:事实上openfile.asm 写的有问题，调用中断int 21h 09h直接printf是错误的，文件里会有一些ASCII字符组合导致换行。这里mov ah, 0B800h面向地址直接写入
