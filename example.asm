.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Mistery Blocks",0
area_width EQU 640
area_height EQU 480
area DD 0

chars DB ",-./,-./"
state DW 0, 0, 0, 0, 0, 0, 0, 0


counter DD 0 ; numara evenimentele de tip timer
counterOK DD 0

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc
include faces.inc

button_x1 EQU 10
button_y1 EQU 10

button_x2 EQU 120
button_y2 EQU 10

button_x3 EQU 230
button_y3 EQU 10

button_x4 EQU 340
button_y4 EQU 10

button_x5 EQU 10
button_y5 EQU 120

button_x6 EQU 120
button_y6 EQU 120

button_x7 EQU 230
button_y7 EQU 120

button_x8 EQU 340
button_y8 EQU 120



button_size EQU 80 

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_block
	cmp eax, 'Z'
	jg make_block
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
	
make_block:
	cmp eax, ','
	jl make_digit
	cmp eax, '/'
	jg make_digit
	sub eax, ','
	lea esi, faces
	jmp draw_text

make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text

	
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

line_horizontal macro x, y, len, color
local bucla_line
	mov eax, y ; EAX = y
	mov ebx, area_width
	mul ebx ;EAX = y * area_width
	add eax, x ;EAX = y * area_width + x
	shl eax, 2 ;EAX = (y * area_width + x) * 4
	add eax, area
	mov ecx, len
	
bucla_line:
	mov dword ptr[eax], color
	add eax, 4
	loop bucla_line

endm


line_vertical macro x, y, len, color
local bucla_line
	mov eax, y ; EAX = y
	mov ebx, area_width
	mul ebx ;EAX = y * area_width
	add eax, x ;EAX = y * area_width + x
	shl eax, 2 ;EAX = (y * area_width + x) * 4
	add eax, area
	mov ecx, len
	
	
bucla_line:
	mov dword ptr[eax], color
	add eax, 4*area_width
	loop bucla_line
	
endm
	


; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	jmp afisare_litere
	
	
	

evt_click:
; ',' ; '-' ; '.' ; '/' - codificarea fetelor



button_1:
	mov eax, [ebp+arg2]
	cmp eax, button_x1
	jl button_2
	cmp eax, button_x1+button_size
	jg button_2
	
	mov eax, [ebp+arg3]
	cmp eax, button_y1
	jl button_2
	cmp eax, button_y1+button_size
	jg button_2 
	
	;s-a dat click in buttonul 1
	
	mov dx, state[0]
	cmp dx, 1
	je button_2 
	
	mov edx, 1
	mov state[0], dx
	make_text_macro ',', area, button_x1+button_size/2-5, button_y1+button_size/2-10
	
	
button_2:
	mov eax, [ebp+arg2]
	cmp eax, button_x2
	jl button_3
	cmp eax, button_x2+button_size
	jg button_3

	mov eax, [ebp+arg3]
	cmp eax, button_y2
	jl button_3
	cmp eax, button_y2+button_size
	jg button_3
	
	;s-a dat click in buttonul 2
	
	mov dx, state[1]
	cmp dx, 1
	je button_3
	
	mov edx, 1
	mov state[1], dx
	
	make_text_macro '-', area, button_x2+button_size/2-5, button_y2+button_size/2-10
	
button_3:
	mov eax, [ebp+arg2]
	cmp eax, button_x3
	jl button_4
	cmp eax, button_x3+button_size
	jg button_4
	
	mov eax, [ebp+arg3]
	cmp eax, button_y3
	jl button_4
	cmp eax, button_y3+button_size
	jg button_4
	
	;s-a dat click in buttonul 3
	
	mov dx, state[2]
	cmp dx, 1
	je button_4
	
	mov edx, 1
	mov state[2], dx
	
	make_text_macro '.', area, button_x3+button_size/2-5, button_y3+button_size/2-10
	
button_4:
	mov eax, [ebp+arg2]
	cmp eax, button_x4
	jl button_5
	cmp eax, button_x4+button_size
	jg button_5
	
	mov eax, [ebp+arg3]
	cmp eax, button_y4
	jl button_5
	cmp eax, button_y4+button_size
	jg button_5
	
	;s-a dat click in buttonul 4
	
	mov dx, state[3]
	cmp dx, 1
	je button_5
	
	mov edx, 1
	mov state[3], dx
	
	make_text_macro '/', area, button_x4+button_size/2-5, button_y4+button_size/2-10
	
button_5:
	mov eax, [ebp+arg2]
	cmp eax, button_x5
	jl button_6
	cmp eax, button_x5+button_size
	jg button_6
	
	mov eax, [ebp+arg3]
	cmp eax, button_y5
	jl button_6
	cmp eax, button_y5+button_size
	jg button_6
	
	;s-a dat click in buttonul 5
	
	mov dx, state[4]
	cmp dx, 1
	je button_6
	
	mov edx, 1
	mov state[4], dx
	
	make_text_macro '/', area, button_x5+button_size/2-5, button_y5+button_size/2-10

button_6:
	mov eax, [ebp+arg2]
	cmp eax, button_x6
	jl button_7
	cmp eax, button_x6+button_size
	jg button_7
	
	mov eax, [ebp+arg3]
	cmp eax, button_y6
	jl button_7
	cmp eax, button_y6+button_size
	jg button_7
	
	;s-a dat click in buttonul 6
	
	mov dx, state[5]
	cmp dx, 1
	je button_7
	
	mov edx, 1
	mov state[5], dx
	
	make_text_macro '.', area, button_x6+button_size/2-5, button_y6+button_size/2-10
	
button_7:
	mov eax, [ebp+arg2]
	cmp eax, button_x7
	jl button_8
	cmp eax, button_x7+button_size
	jg button_8
	
	mov eax, [ebp+arg3]
	cmp eax, button_y7
	jl button_8
	cmp eax, button_y7+button_size
	jg button_8
	
	;s-a dat click in buttonul 7
	
	mov dx, state[6]
	cmp dx, 1
	je button_8
	
	mov edx, 1
	mov state[6], dx
	
	make_text_macro '-', area, button_x7+button_size/2-5, button_y7+button_size/2-10
	
button_8:
	mov eax, [ebp+arg2]
	cmp eax, button_x8
	jl button_fail
	cmp eax, button_x8+button_size
	jg button_fail
	
	mov eax, [ebp+arg3]
	cmp eax, button_y8
	jl button_fail
	cmp eax, button_y8+button_size
	jg button_fail
	
	;s-a dat click in buttonul 8
	
	mov dx, state[7]
	cmp dx, 1
	je button_fail
	
	mov edx, 1
	mov state[7], dx
	
	make_text_macro ',', area, button_x8+button_size/2-5, button_y8+button_size/2-10
	
	

button_fail: 
	
mov eax, 8
mov cx, 0

top: 

mov dx, state[eax-1]
cmp dx, 1
jne skip

add cx, dx

; cmp cx, 1
; je mutprim

; cmp cx, 2
; je mutaldoilea

; mutprim:

; mov bh, chars[eax]


; mutaldoilea:

; mov bl, chars[eax]

skip:
dec eax
cmp eax, 0
je top

cmp cx, 2
jne afisare_litere

;suma pe state pt a afla nr carduri gasite , daca suma = 2 astept 1 sec, dupa resetez sirul de state

; comparare:
	 
	 ;compar simbolurile de la cele 2 carduri
	 ; cmp bh, bl
	 ; jne reset
	
	

reset:	
	
	mov eax, 8

	top1: 
	
	mov state[eax-1], 0
	dec eax
	cmp eax, 0
	jne top1
	
	make_text_macro 26, area, button_x1+button_size/2-5, button_y1+button_size/2-10
	make_text_macro 26, area, button_x2+button_size/2-5, button_y2+button_size/2-10
	make_text_macro 26, area, button_x3+button_size/2-5, button_y3+button_size/2-10
	make_text_macro 26, area, button_x4+button_size/2-5, button_y4+button_size/2-10
	make_text_macro 26, area, button_x5+button_size/2-5, button_y5+button_size/2-10
	make_text_macro 26, area, button_x6+button_size/2-5, button_y6+button_size/2-10
	make_text_macro 26, area, button_x7+button_size/2-5, button_y7+button_size/2-10
	make_text_macro 26, area, button_x8+button_size/2-5, button_y8+button_size/2-10
	
	;mov counterOK, 0

	

evt_timer:
	inc counter
timer1:
	inc counterOK
	cmp counterOK, 5
	je reset
	
afisare_litere:
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, counter
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 620, 10
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 610, 10
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 600, 10
	
	;scriem un mesaj
	; make_text_macro 'P', area, 110, 100

	
	line_horizontal button_x1, button_y1, button_size, 0
	line_horizontal button_x1, button_y1+button_size, button_size, 0
	line_vertical button_x1, button_y1, button_size, 0
	line_vertical button_x1+button_size, button_y1, button_size, 0
	
	line_horizontal button_x2, button_y2, button_size, 0
	line_horizontal button_x2, button_y2+button_size, button_size, 0
	line_vertical button_x2, button_y2, button_size, 0
	line_vertical button_x2+button_size, button_y2, button_size, 0
	
	line_horizontal button_x3, button_y3, button_size, 0
	line_horizontal button_x3, button_y3+button_size, button_size, 0
	line_vertical button_x3, button_y3, button_size, 0
	line_vertical button_x3+button_size, button_y3, button_size, 0
	
	line_horizontal button_x4, button_y4, button_size, 0
	line_horizontal button_x4, button_y4+button_size, button_size, 0
	line_vertical button_x4, button_y4, button_size, 0
	line_vertical button_x4+button_size, button_y4, button_size, 0
	
	line_horizontal button_x5, button_y5, button_size, 0
	line_horizontal button_x5, button_y5+button_size, button_size, 0
	line_vertical button_x5, button_y5, button_size, 0
	line_vertical button_x5+button_size, button_y5, button_size, 0
	
	line_horizontal button_x6, button_y6, button_size, 0
	line_horizontal button_x6, button_y6+button_size, button_size, 0
	line_vertical button_x6, button_y6, button_size, 0
	line_vertical button_x6+button_size, button_y6, button_size, 0

	line_horizontal button_x7, button_y7, button_size, 0
	line_horizontal button_x7, button_y7+button_size, button_size, 0
	line_vertical button_x7, button_y7, button_size, 0
	line_vertical button_x7+button_size, button_y7, button_size, 0
	
	line_horizontal button_x8, button_y8, button_size, 0
	line_horizontal button_x8, button_y8+button_size, button_size, 0
	line_vertical button_x8, button_y8, button_size, 0
	line_vertical button_x8+button_size, button_y8, button_size, 0
	
	
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
