;输入任意数(<=65535最终版）
.386
data segment use16
buffer1 db 6 
	   db ?  
	   db 6 dup("0")  
buffer2 db 6 
	   db ?  
	   db 6 dup("0")     
s db 5 dup("0"),0Dh,0Ah,'$'   ;第一次缓存

x dd 0
s2 db 8 dup(0),0Dh,0Ah,'$'   ;储存16进制数
s3 db 32 dup(0), 0Dh, 0Ah, '$'  ;储存2进制数
s4 db 10 dup(' '), 0Dh, 0Ah, '$' ;储存十进制数
s5 db 5 dup("0"),0Dh,0Ah,'$'  ;第二次缓存
data ends
code segment use16
assume cs:code, ds:data
main:
mov ax, 3
int 10h
   mov ax, data
   mov ds, ax ;
   call input_s 
   mov ah, 4Ch
   int 21h
input_s: ;输入缓存并得出最终结果函数
   mov ah, 0Ah
   mov dx, offset buffer1  ;输入指定的缓存区 接下来要取出并赋值起来备用
   int 21h
mov ah, 2
mov dl, 0Dh
int 21h
mov ah, 2
mov dl,0Ah
int 21h 

xor cx, cx
mov cl, buffer1[1]
jcxz dones
        
mov bx, offset buffer1+2
agains:
mov dl, [bx]
mov s[di], dl
inc di    ;赋值到相应的地址

inc bx
loop agains ;cx-1

;将输入的不满五个元素数组s进行转化相当于左移cl位
mov cl, buffer1[1]
cmp cl, 5
jne trans
je dones
trans:
mov ch, 0
mov bx, cx
mov si, 4
sub bx, 1
translis:
mov dl, s[bx]
mov s[si], dl
mov s[bx], '0'
sub si, 1
sub bx, 1
sub cl, 1
cmp cl, 0
je dones
jne translis


dones: 
mov bx, 0
   mov eax, 0
   mov edx, 0
next:
   mov dl, s[bx]  
   cmp dl, 0Dh    ;定义数组s貌似没有0
   je done
   imul eax, eax, 10 
   sub dl, '0'
   add eax, edx
   inc bx
   jmp next
done:
   mov [x], eax;间接寻址
   mov di, 0
   mov ah, 0Ah
   mov dx, offset buffer2  ;输入指定的缓存区 接下来要取出并赋值起来备用
   int 21h

mov ah, 2
mov dl, 0Dh
int 21h
mov ah, 2
mov dl,0Ah
int 21h  

xor cx, cx
mov cl, buffer2[1]
jcxz dones6
        
mov bx, offset buffer2+2
agains6:
mov dl, [bx]
mov s5[di], dl
inc di    ;赋值到相应的地址

inc bx
loop agains6 ;cx-1

;将输入的不满五个元素数组s5进行转化相当于左移cl位
mov cl, buffer2[1]
cmp cl, 5  ;cl值是5
jne trans6
je dones6

trans6:
mov ch, 0
mov bx, cx
mov si, 4
sub bx, 1
translis6:
mov dl, s5[bx]
mov s5[si], dl
mov s5[bx], '0'
sub si, 1
sub bx, 1
sub cl, 1
cmp cl, 0
je dones6
jne translis6
dones6: 
mov bx, 0
   mov eax, 0
   mov edx, 0
next6:
   mov dl, s5[bx]  
   cmp dl, 0Dh    
   je done6
   imul eax, eax, 10 
   sub dl, '0'
   add eax, edx
   inc bx
   jmp next6
done6:
   mul x;一个乘数已经在eax中了  而后值返回到eax十六进制中 

push eax
;s再次转化 ‘ ’代‘0’
mov si, 0
mov dl, s[si]
cmp dl, '0'
je change
jne fin
change:
mov al, ' '
mov s[si], al
inc si
mov dl, s[si]
cmp dl, '0'
je change
jne fin
fin:
;s再次转化 ‘ ’代‘0’
mov si, 0
mov dl, s5[si]
cmp dl, '0'
je change1
jne fin1
change1:
mov al, ' '
mov s5[si], al
inc si
mov dl, s5[si]
cmp dl, '0'
je change1
jne fin1
fin1:


;逐个输出s, s5
mov si, 0
mov cl, 5
topp:
mov ah, 2
mov dl, s[si]; 循环即可
int 21h
add si, 1
sub cl, 1
cmp cl, 0
je top
jne topp
top:
mov ah, 2
mov dl, '*'
int 21h

mov si, 0
mov cl, 5
topp2:
mov ah, 2
mov dl, s5[si]; 循环即可
int 21h
add si, 1
sub cl, 1
cmp cl, 0
je top2
jne topp2
top2:
mov ah, 2
mov dl, '='
int 21h
mov ah, 2
mov dl, 0Dh
int 21h
mov ah, 2
mov dl,0Ah
int 21h 
;开始调用三个进制函数
pop eax 
push eax
call bytes10   ;函数之间会互相影响导致结果出错 所以要push 函数本身没有问题
pop eax
push eax
call bytes16
pop eax
call bytes2
mov ah, 4Ch
int 21h 
ret   
   
   
bytes10: ;生成eax十进制
    ;堆栈法
  mov di, 0; 数组s的下标
  mov cx, 0; 统计push的次数
again2:
  mov edx, 0; 被除数为EDX:EAX
  mov ebx, 10
  div ebx; EAX=商, EDX=余数
  add dl, '0'
  push dx
  inc cx
  cmp eax, 0
  jne again2
pop_again:
  pop dx
  mov s4[di], dl
  inc di
  dec cx
  jnz pop_again

  mov ah, 9
  mov dx, offset s4
  int 21h
  ret
bytes16:;生成eax16进制
    mov cx, 8
    mov di, 0
again:
    push cx
    mov cl, 4
    rol eax, cl
	push eax
	and eax, 0000000Fh
    cmp eax, 10
    jb is_digit
is_alpha:
    sub al,10
    add al,'A'
    jmp finish_4bits
is_digit:
    add al, '0'
finish_4bits:
    mov s2[di],al  
    pop eax
    pop cx
    add di,1
    sub cx,1
    jnz again
	
    mov ah, 9
    mov dx, offset s2
    int 21h
    ret

bytes2:;生成eax二进制
  mov bx, 0; 数组s3的下标
  mov cx, 32; 循环次数
  mov edx, eax
next1:
  mov eax, edx
  rol eax, 1
  mov edx, eax
  and al, 1 
            
  add al, '0'  ;注意此处转换成字符的方式 踩了很多次坑了
  add  s3[bx], al

  add bx, 1
  sub cx, 1 ; cx = cx-1
  jnz next1
  mov ah, 9
  mov dx, offset s3
  int 21h
  ret

code ends
end main