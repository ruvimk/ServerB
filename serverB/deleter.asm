.386 
.model flat, stdcall 
option casemap:none 
include ..\include\include.inc 
include ..\include\rslib.inc 
include ..\include\i2str.asm 
include ..\include\str2i.asm 
includelib ..\lib\str.lib 
includelib ..\lib\rslib.lib 
.data 
.data? 
CmdLine                             DB  1024 dup (?) 
CommandLine                         DWORD ? 
file_to_delete                      DWORD ? 
.code 
start: 

call main 

ret 

main proc 
	enter 0, 0 
	
	call GetCommandLine 
	mov dword ptr [CommandLine], eax 
	
	mov ebx, eax 
	mov eax, offset CmdLine 
	call StringCopy 
	
	mov ebx, eax 
	
	@@: 
		mov al, byte ptr [ebx] 
		inc ebx 
		cmp al, 32 
		jz @B 
		cmp al, 9 
		jz @B 
		dec ebx 
	@@: 
		mov al, byte ptr [ebx] 
		cmp al, 32 
		jz @F 
		cmp al, 9 
		jz @F 
		cmp al, 0 
		jz @F 
		inc ebx 
		jmp @B 
	@@: 
		mov al, byte ptr [ebx] 
		inc ebx 
		cmp al, 32 
		jz @B 
		cmp al, 9 
		jz @B 
		dec ebx 
	@@: 
	cmp al, 0 
	jz finish 
	
	mov eax, ebx 
	mov dword ptr [file_to_delete], eax 
	
	lp1: 
		push dword ptr [file_to_delete] 
		call DeleteFile 
		cmp eax, 0 
		jnz lp1s 
		
		call GetLastError 
		mov ebx, offset CmdLine 
		sub ebx, 4 
		mov dword ptr [ebx], eax 
		
		push dword ptr 250 
		call Sleep 
		
		jmp lp1 
	lp1s: 
	
	jmp finish 
	
	finish: 
	
	xor eax, eax 
	
	leave 
	ret 
main endp 

end start 