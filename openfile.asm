
.386
data segment use16
in_page_offset dd 0 ;每一页内的行的偏移地址
_offset dw 0 ;文件偏移地址
file_offset db 0,0,0,0
page_num dw ?
end_page_num dw ?
bytes_num dw ?   ;储存 ax 的数值
bytes_num_ dd ? ;储存整个eax的数值
file_size db 4 dup(?)
row dw ?
handle dw ?
s db "00000000: 00 00 00 00|00 00 00 00|00 00 00 00|00 00 00 00 ", 16 dup("."),0Dh, 0Ah, '$'
hex db 2 dup(0), 0Dh, 0Ah, '$'; 8位字符转化hex过度数组
hex2 db 4 dup(0), 0Dh, 0Ah, '$' ;32位偏移地址转化hex过度数组
open_cond db "Can not open file!", 0Dh, 0Ah, '$'
filename db 100 dup(' ')
input_w db "Please input filename:",0Dh, 0Ah, '$'
buffer1 db 100 ;每次输入的最大数
		db ? ;实际输入的数量
		db 100 dup(' ') ;总量
buffer2 db 255
	   db ?
	   db 255 dup(' ')
	   
;PageUp : 4800h
;PageDown : 5000h
;Home : 4B00h
;end : 4D00h
;esc : 011Bh
   
data ends

code segment use16
assume cs:code, ds:data
main:
mov ax, data
mov ds, ax
mov ah, 09h
mov dx, offset input_w
int 21h

mov ah, 0Ah
mov dx, offset buffer1 ;输入文件名
int 21h
;赋值给filename 
mov bx, offset buffer1+2
mov di, 0
mov cl, buffer1[1]
next:
mov dl, [bx]
mov filename[di], dl
inc di 
inc bx
loop next
;整理filename使di-98位为0,99位为'$'
mov filename[di], 0
mov filename[99], '$'
inc di
chan_file:
mov filename[di], 0
inc di
cmp di, 99
jne chan_file

call read_file;读取内容并判断是否读取成功
;实现翻页

mov ah, 42h
mov al, 2
mov bx, handle
xor cx, cx
xor dx, dx
int 21h
;filesize<=65535时，dx为0debug是要及时看 程序结束会自动清理缓存

mov word ptr file_size[0], ax
mov word ptr file_size[2], dx 
mov eax, dword ptr file_size

mov bytes_num_, eax

;dx:ax依旧为大小
mov bx, 256  
div bx
mov page_num, ax ;页数是否加一，取决于ah是否为零
mov end_page_num, dx

mov ax, dx
mov cl, 16
div cl 
cmp ah, 0
jne add_1
mov row, ax ;行数
jmp _next
add_1:
add ax, 1
mov row, ax
_next:
call read_file
;下输出固定的16行这里bx值为偏移地址hex2[4]
mov bx, page_num
cmp bx, 0
je show_1_page
call show_256bytes_page;移动到buffer2
jmp xunhuan_
show_1_page:
call show_only_one_page

xunhuan_:
mov ah, 0
int 16h
mov bx, page_num
cmp bx, 0
je final_;只有一页直接跳转final
cmp ax, 5000h
je pagedown_f
cmp ax, 4800h
je PageUp_f
cmp ax, 4D00h
je end_f
cmp ax, 4B00h
je home_f
jmp final_


home_f:
call clear_the_page
mov ah, 42h
mov al, 0
mov bx, handle
mov cx, 0000h
mov dx, 0000h
int 21h
mov eax, dword ptr file_offset 
mov eax, 0
mov dword ptr file_offset, eax      
call show_256bytes_page    
jmp final_

PageUp_f:
cmp dword ptr file_offset, 0
je sub_null_

mov eax, dword ptr file_offset
sub eax, 256
mov dword ptr file_offset, eax
call clear_the_page
call move_file_pointer_
call show_256bytes_page
sub_null_:
jmp final_

pagedown_f:
mov edx, bytes_num_
sub edx, 256
cmp dword ptr file_offset, edx
jnb add_null_
mov eax, dword ptr file_offset
add eax, 256
mov dword ptr file_offset, eax 

call clear_the_page
call move_file_pointer_
call show_256bytes_page
jmp final_
add_null_:
call clear_the_page 
mov edx, bytes_num_
sub edx, dword ptr end_page_num
mov dword ptr file_offset, edx

mov ah, 42h
mov al, 0
mov bx, handle
mov cx, offset [file_offset]+2
mov dx, offset file_offset
int 21h 
call show_end_page
jmp final_

end_f:
call clear_the_page 
mov edx, bytes_num_
sub edx, dword ptr end_page_num
mov dword ptr file_offset, edx

mov ah, 42h
mov al, 0
mov bx, handle
mov cx, offset [file_offset]+2
mov dx, offset file_offset
int 21h 
call show_end_page
jmp final_


final_:
cmp ax, 011Bh
jne xunhuan_


done1:
mov ah, 3Eh
mov bx, handle
int 21h

mov ah, 4ch
int 21h


show_only_one_page: ;单独一页
mov ah, 3fh
mov bx, handle
mov cx, offset [file_size]+2
mov dx, data
mov ds, dx
mov dx, offset buffer2
int 21h ; 提取出end_page_num字节文件到buffer2
mov bx, ax
mov buffer2[bx], '$' ;加上字符串结束标志

mov dl, 0Fh
mov ax, offset [file_size]+2
div dl
mov ah, 0;商在al中
cmp ax, 0
jne add_row_null
add ax, 1
add_row_null:
push ax
mov row, ax
mov bx, offset buffer2

mov in_page_offset, 0
show_this_page2:
call one_row_init ;每行16个字符8位的转换 输出16行的page
add in_page_offset, 16
sub row, 1
cmp row, 0
jne show_this_page2
pop ax
mov cx, ax
call _color
ret

show_end_page:
mov ebx, bytes_num_ ;这里要换成总de _offset也得该
sub ebx, dword ptr end_page_num
mov dword ptr file_offset, ebx
call move_file_pointer_
mov ah, 3fh
mov bx, handle
mov cx, end_page_num
mov dx, data
mov ds, dx
mov dx, offset buffer2
int 21h; 提取出end_page_num字节文件到buffer2
mov bx, ax
mov buffer2[bx], '$' ;加上字符串结束标志

;重新算row
mov ax, end_page_num
mov dl, 16
div dl
mov ah, 0
mov row, ax 

push row

cmp row, 0
jne row_row
mov row, 1
row_row:
add row, 1
mov bx, offset buffer2
mov edx, dword ptr file_offset
mov in_page_offset, edx 
show_this_page1:
call one_row_init 
add in_page_offset, 1
sub row, 1
cmp row, 0
jne show_this_page1
pop row
add row, 1
mov cx, row
call _color
ret

clear_the_page:
mov ax, 03h
int 10h
ret


move_file_pointer:
mov ah, 42h
mov al, 0
mov bx, handle
mov cx, 0
mov dx, _offset
int 21h      
ret
move_file_pointer_:
mov ah, 42h
mov al, 0
mov bx, handle
mov cx, word ptr [file_offset]+2
mov dx, word ptr file_offset
int 21h      
ret

show_256bytes_page:
mov ah, 3fh
mov bx, handle
mov cx, 256
mov dx, data
mov ds, dx
mov dx, offset buffer2
int 21h ;提取出256字节文件到buffer2
mov bx, ax
mov buffer2[bx], '$' ;加上字符串结束标志

mov bx, 16
mov row, bx
mov bx, offset buffer2

mov edx, dword ptr file_offset
mov in_page_offset, edx  
show_this_page:
call one_row_init ;每行16个字符8位的转换 输出16行的page 现在每页固定256个字符
add in_page_offset, 16
sub row, 1
cmp row, 0
jne show_this_page
mov cx, 16
call _color
ret
_color: ;cx “接口”
mov ax, 0B800h
mov ds, ax

mov si, 0
add si, 42
_1:
mov dh, 0fh
mov dl, '|'
mov word ptr ds:[si], dx
add si, 24
mov word ptr ds:[si], dx
add si, 24
mov word ptr ds:[si], dx
add si, 112
loop _1

mov ax, data
mov ds,ax
ret

read_file:
;读取文件部分内容 return cf && handle
done:
mov ax, 03h
int 10h
mov ah, 3Dh
mov al, 0
mov dx, offset filename
int 21h; ax = file handle
mov handle, ax
;判断打开文件是否成功
jnc succ
jc fail
fail:
mov ah, 02h
mov dl, 0Dh
int 21h
mov ah, 02h
mov dl, 0Ah
int 21h
mov ah, 09h
mov dx, offset open_cond;错误提示
int 21h
mov ah, 4ch ;错误则提前结束
mov al, 0
int 21h
succ:
ret

one_row_init:;实现了show_one_row
push bx
call _32byte_hex 
mov si, 0
offsett:
mov dl, hex2[si]
mov s[si], dl
inc si
cmp si, 8
jne offsett
pop bx
mov si, 10 
show_one_row:
mov dl, [bx]
call _8byte_hex
mov al, hex[0]
mov s[si], al
inc si
mov al, hex[1]
mov s[si], al
add si, 2
inc bx
cmp si, 58
jne show_one_row
 
sub bx, 16
latter_:
mov dl, [bx]
cmp dl, 0Dh
je sig1  ;处理换行符
cmp dl, 0Ah
je sig2
mov s[si], dl
jmp sig0
sig1:
mov dl, '\'
mov s[si], dl
jmp sig0
sig2:
mov dl, 'n'
mov s[si], dl
jmp sig0
sig0: 
inc si
inc bx
cmp si, 74
jne latter_
mov ah, 09h
mov dx, offset s
int 21h
ret

_32byte_hex:
    mov eax, in_page_offset ;页内_offset 
    mov cx, 8
    mov di, 0
again1:
    push cx
    mov cl, 4
    rol eax, cl
	push eax
	and eax, 0000000Fh
    cmp eax, 10
    jb is_digit1
is_alpha1:
    sub al,10
    add al,'A'
    jmp finish_4bits1
is_digit1:
    add al, '0'
finish_4bits1:
    mov hex2[di],al
    pop eax
    pop cx
    add di,1
    sub cx,1
    jnz again1
ret

_8byte_hex:  ;函数不能以数字开始
    mov al, dl
    mov cx, 2
    mov di, 0
again:
    push cx
    mov cl, 4
    rol al, cl
	push ax
	and al, 0Fh
    cmp al, 10
    jb is_digit
is_alpha:
    sub al,10
    add al,'A'
    jmp finish_4bits
is_digit:
    add al, '0'
finish_4bits:
    mov hex[di],al
    pop ax
    pop cx
    add di,1
    sub cx,1
    jnz again
ret
code ends
end main