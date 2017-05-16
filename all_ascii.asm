data segment
;abc dw 0 ;情报：abc占用的是前四个地址指向的内容 后续对前四个地址的改动会影响abc的值
data ends

code segment
assume cs :code, ds:data
main:
mov ax, 3
int 10h ;清屏并将屏幕设置成为80*25模式
    mov ax, 0B800h ;段首地址
    mov ds, ax
	mov cl, 0
	mov dl, 0
	mov di, 0
	mov si, 0
difs:
    mov ax, di
    mov cx, 4
    
again:
    push cx
    mov cl, 4
    rol ax, cl
    push ax
    and ax, 000Fh
    cmp ax,10
    jb is_digit
is_alpha:
    sub al,10
    add al,'A'
    jmp finish_4bits
is_digit:
    add al, '0'
finish_4bits:

    mov ah, 0Ah

    mov word ptr ds:[si],ax ;这里word ptr 和数字输出（不输出ascii有关系）
    pop ax
    pop cx
    add si,2
    sub cx,1
    jnz again
	
	sub si, 8
	mov word ptr ds:[si], 0020h
	add si, 2
	mov dh, 0Ch
	mov word ptr ds:[si], dx ;si = 2
	add si, 158

	mov ax, di
	add ax, 1
	mov bl, 25
	div bl  ;取余判断
	sub ah, 0
	jz xunhuan
	jnz feixun
xunhuan:
    sub si, 3986 ;每25行返回到第一行
feixun:
	add dl, 1
	add di, 1
	cmp di, 256
	jb difs
	
	mov ah, 1
	int 21h  ;等待键盘输入getchar()
    mov ah,4Ch
    int 21h  
code ends
end main