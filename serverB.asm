;; Copyright (C) 2011 By Ruvim Kondratyev 
;; Application Name: ServerB 
;; Application Version: ServerB/3.97 
;; Date Released: Fri, 12 Aug 2011 

PORT_NUMBER equ 81 

.386 
.model flat, stdcall 
option casemap:none 
include include\include.inc 
include include\rslib.inc 
include include\i2str.asm 
include include\str2i.asm 
include include\ns_fxns2.asm
includelib lib\str.lib 
includelib lib\rslib.lib 
extern replace   : near 
;; PROLOGUE and EPILOGUE are settings for the enter and leave instructions and local variables. 
;; OPTION PROLOGUE:PrologueDef
;; OPTION EPILOGUE:EpilogueDef

;; This line determines whether temporary input/output files are deleted or not: 
;; jmp do_not_delete_files_for_now 
.data 
ApplicationName                            db "ServerB", 0 
ApplicationVersion                         db "ServerB/3.97", 0 
base_directory                             db "serverB", 47, "anyhost", 47, "public_html", 0 
log_filename                               db "serverB", 47, "log.txt", 0 
deleter_path                               db "serverB", 47, "deleter.exe", 0 
could_not_delete_exec                      db "Could not delete the executable file: ", 0 
nl                                         db 13, 10, 0 
logging                                    dd 1 
.data? 
ofstruct                                   DB  SIZEOF OFSTRUCT     dup (?) 
time                                       DB  SIZEOF SYSTEMTIME   dup (?) 
method                                     DB  512 dup (?) 
string1                                    DB  512 dup (?) 
string2                                    DB  512 dup (?) 
string01                                   DB  512 dup (?) 
string02                                   DB  512 dup (?) 
remote_ip                                  DB  512 dup (?) 
time_string_1                              DB  512 dup (?) 
some_string                                DB  512 dup (?) 
exec_string                                DB  512 dup (?) 
cmd_string                                 DB  512 dup (?) 
request_uri                                DB  512 dup (?) 
query_string                               DB  512 dup (?) 
script_name                                DB  512 dup (?) 
main_socket                                DWORD ? 
rNumber                                    DWORD ? 
socket01                                   DWORD ? 
time1                                      DWORD ? 
e1                                         DWORD ? 
e2                                         DWORD ? 
e3                                         DWORD ? 
e4                                         DWORD ? 
wd                                         DB  SIZEOF WSADATA dup (?) 
TempSock                                   DWORD ? 
sBuffer                                    DB  4096 dup (?) 
rBuffer                                    DB  4096 dup (?) 
eBuffer                                    DB  4096 dup (?) 
bSent                                      DWORD ? 
bReceived                                  DWORD ? 
r                                          DWORD ? 
n                                          DWORD ? 
save1cc_index                              DWORD ? 
save1cc_count                              DWORD ? 
save1cc_point                              DWORD ? 
content_length                             DWORD ? 
hLog                                       DWORD ? 
p_exec                                     DWORD ? 
current_request                            DWORD ? 
hStdI                                      DWORD ? 
hStdO                                      DWORD ? 
sa1                                        DB  SIZEOF sockaddr_in dup (?) 
pBuffer                                    DWORD ? 
lBuffer                                    DWORD ? 
thePort                                    DWORD ? 
CmdLine                                    DWORD ? 
app_start_esp1                             DWORD ? 
.const 
BUFFER_SIZE                                equ  1024 * 1024 * 16 
.code 
start: 

mov dword ptr [lBuffer], BUFFER_SIZE 

call GetCommandLine 
mov dword ptr [CmdLine], eax 

mov ebx, eax 

@@: 
	mov al, byte ptr [ebx] 
	inc ebx 
	cmp al, 32 
	jz @B 
	dec ebx 
@@: 
	mov al, byte ptr [ebx] 
	cmp al, 32 
	jz @F 
	cmp al, 0 
	jz @F 
	inc ebx 
	jmp @B 
@@: 
	mov al, byte ptr [ebx] 
	cmp al, 32 
	jnz @F 
	inc ebx 
	jmp @B 
@@: 
push ebx 
call str2i 
cmp eax, 0 
jnz @F 
	mov eax, PORT_NUMBER 
@@: 
mov dword ptr [thePort], eax 

call main 

xor eax, eax 

ret 

ServerB_log: 
	enter 0, 0 
	
	mov eax, dword ptr [logging] 
	cmp eax, 0 
	jnz @F 
		leave 
		ret 4 
	@@: 
	
	mov eax, dword ptr [ebp+8] 
	push eax 
	call app_log 
	
	leave 
ret 4 

work_until_exit: 
	
	@@: 
	call check_if_exit 
	
	push dword ptr 250 
	call Sleep 
	
	jmp @B 
	
	ret 
;; endp 

main: 
	local_size                         equ  16 + 16 + 4 + 4 + 4 ;; + SIZEOF WSADATA 
	enter local_size, 0 
	bRead                              equ  ebp - (16 + 16 + 4 + 4 + 4) 
	hFile                              equ  ebp - (16 + 16 + 4 + 4) 
	socket1                            equ  ebp - (16 + 16 + 4) 
	h                                  equ  16 
		h_name                             equ  0 
		h_alias                            equ  4 
		h_addr                             equ  8 
		h_len                              equ  10 
		h_list                             equ  12 
	sa                                 equ  32 
		sin_family                         equ  0 
		sin_port                           equ  2 
		sin_addr                           equ  4 
			w1                                 equ  0 
			w2                                 equ  2 
			b1                                 equ  0 
			b2                                 equ  1 
			b3                                 equ  2 
			b4                                 equ  3 
	;; .....  
	
	
	push dword ptr [lBuffer] 
	push dword ptr 0 
	call GlobalAlloc 
	mov dword ptr [pBuffer], eax 
	cmp eax, 0 
	jz err 
	cmp eax, -1 
	jz err 
	
	
	;; Start the exit watch thread. 
	push dword ptr 0 
	push dword ptr 0 
	push dword ptr 0 
	push dword ptr offset work_until_exit 
	push dword ptr 4096 
	push dword ptr 0 
	call CreateThread 
	
	
	;; Open the log file handle. 
	push dword ptr 2 
	push dword ptr space(SIZEOF OFSTRUCT) 
	push dword ptr offset log_filename 
	call OpenFile 
	mov dword ptr [hLog], eax 
	cmp eax, 0 
	jnz continue002 
	
	push dword ptr 2 or 1000h 
	push dword ptr space(SIZEOF OFSTRUCT) 
	push dword ptr offset log_filename 
	call OpenFile 
	mov dword ptr [hLog], eax 
	
	continue002: 
	
	
	inc dword ptr [rNumber] 
	
	inc dword ptr [current_request] 
	
	
	push dword ptr STD_INPUT_HANDLE 
	call GetStdHandle 
	mov dword ptr [hStdI], eax 
	
	push dword ptr STD_OUTPUT_HANDLE 
	call GetStdHandle 
	mov dword ptr [hStdO], eax 
	
	
	;; WSAStartup(0202h, addr wd); 
	;mov eax, ebp 
	;sub eax, wd 
	;push eax 
	;push dword ptr 0202h 
	;call WSAStartup 
	invoke WSAStartup, 0202h, addr wd  ; eax 
	;; if (eax != 0) goto err; 
	
	push eax  ;; save 
	
	call WSAGetLastError 
	mov dword ptr [e1], eax 
	
	pop eax   ;; restore 
	
	mov ebx, string("Error 1 occurred. ") 
	cmp eax, 0 
	jnz err 
	
	;; socket1= socket(AF_INET, SOCK_STREAM, IPPROTO_TCP); 
	;push byte ptr IPPROTO_TCP 
	;push byte ptr SOCK_STREAM 
	;push byte ptr AF_INET 
	;call socket 
	invoke socket, AF_INET, SOCK_STREAM, IPPROTO_TCP 
	cmp eax, INVALID_SOCKET 
	jz err2 
	mov dword ptr [socket1], eax 
	mov dword ptr [main_socket], eax 
	jmp continue1 
	
	err2: 
	push dword ptr offset time 
	call GetLocalTime 
	mov ebx, offset time 
	xor eax, eax 
	mov ax, word ptr [ebx+14] 
	mov dword ptr [time1], eax 
	lp001err2: 
		invoke socket, AF_INET, SOCK_STREAM, IPPROTO_TCP 
		cmp eax, INVALID_SOCKET 
		jz lp001err2over1 
		
		mov dword ptr [socket1], eax 
		jmp continue1 
		
		lp001err2over1: 
		
		push dword ptr offset time 
		call GetLocalTime 
		xor eax, eax 
		mov ebx, offset time 
		mov ax, word ptr [ebx+14] 
		sub eax, 3 
		cmp eax, dword ptr [time1] 
		jnl lp001err2 
	lp001err2s: 
	
	call WSAGetLastError 
	mov dword ptr [e2], eax 
	
	mov ebx, string("Error 2 occurred. ") 
	jmp err 
	
	continue1: 
	
	mov word ptr [ebp - (sa - sin_family)], AF_INET 
	mov ax, word ptr [thePort] 
	xchg al, ah 
	mov word ptr [ebp - (sa - sin_port)], ax 
	mov dword ptr [ebp - (sa - sin_addr)], INADDR_ANY 
	
	push dword ptr 16 
	mov eax, ebp 
	sub eax, sa 
	push eax 
	push dword ptr [socket1] 
	call bind 
		mov ebx, string("Error 3 occurred. ") 
		
		push eax  ;; save 
		
		call WSAGetLastError 
		mov dword ptr [e3], eax 
		
		pop eax   ;; restore 
		
		cmp eax, SOCKET_ERROR 
		jnz no_error_3_01 
		
		push dword ptr SD_BOTH 
		push dword ptr [socket1] 
		call shutdown 
		
		push dword ptr [socket1] 
		call closesocket 
		
		mov eax, dword ptr [e3] 
		cmp eax, 10048 
		jnz err 
		
		push dword ptr 0 
		push dword ptr offset ApplicationName 
		push dword ptr string("The specified port is already in use. ") 
		push dword ptr 0 
		call MessageBox 
		
		push dword ptr string("Error:  Port already in use. ", 13, 10) 
		call StdOut 
		
		jmp err 
	;; .....  
	
	no_error_3_01: 
	
	push dword ptr 1 
	push dword ptr [socket1] 
	call listen 
	
	call WSAGetLastError 
	mov dword ptr [e4], eax 
	
	lp01: 
		
		mov dword ptr [TempSock], SOCKET_ERROR 
		lp1: 
			cmp dword ptr [TempSock], SOCKET_ERROR 
			jnz lp1s 
			
			call check_if_exit 
			
			push dword ptr 0 
			push dword ptr 0 
			push dword ptr [socket1] 
			call accept 
			;invoke accept, [socket1], 0, 0 
			mov dword ptr [TempSock], eax 
			
			jmp lp1 
		lp1s: 
		
		;invoke StdOut, string("CC!", 13, 10) 
		
		push dword ptr 0 
		push dword ptr 0 
		push dword ptr 0 
		push dword ptr offset serve 
		push dword ptr 16344    ; 8172 
		push dword ptr 0 
		call CreateThread 
		
		lp2: 
			cmp dword ptr [TempSock], 0 
			jnz lp2 
		;; Wait for the new thread to get the socket identifier, before going on. 
		
	jmp lp01 
	
	
	push dword ptr [hLog] 
	call CloseHandle 
	
	
	leave 
	ret 
	err: 
			call GetLastError 
			mov [time1], eax 
		push ebx 
		call StdOut 
			call WSAGetLastError 
			invoke dw2a, eax, offset string1 
			push dword ptr offset string1 
			push dword ptr string(13, 10, 13, 10, "WSA Error Number: ") 
			call StdOut 
			call StdOut 
			push dword ptr string(" ", 13, 10, "Windows Error Number: ") 
			call StdOut 
				invoke dw2a, [time1], offset string1 
			push dword ptr offset string1 
			call StdOut 
		push dword ptr SD_BOTH 
		push dword ptr [socket1] 
		call shutdown 
			call WSACleanup 
	push dword ptr [socket1] 
	call closesocket 
		push dword ptr [pBuffer] 
		call GlobalFree 
			push dword ptr string(13, 10, 13, 10, "WSA Error History: ", 13, 10, "Error 1: ") 
			call StdOut 
				invoke dw2a, [e1], offset string1 
				push dword ptr offset string1 
				call StdOut 
			push dword ptr string(13, 10, "Error 2: ") 
			call StdOut 
				invoke dw2a, [e2], offset string1 
				push dword ptr offset string1 
				call StdOut 
			push dword ptr string(13, 10, "Error 3: ") 
			call StdOut 
				invoke dw2a, [e3], offset string1 
				push dword ptr offset string1 
				call StdOut 
			push dword ptr string(13, 10, "Error 4: ") 
			call StdOut 
				invoke dw2a, [e4], offset string1 
				push dword ptr offset string1 
				call StdOut 
			push dword ptr [hLog] 
			call CloseHandle 
		leave 
		ret 
check_if_exit: 
	push dword ptr VK_CONTROL 
	call GetKeyState 
		and eax, -2 
		cmp eax, 0 
		jz exit_not2 
	push dword ptr VK_MENU 
	call GetKeyState 
		and eax, -2 
		cmp eax, 0 
		jz exit_not2 
	push dword ptr 69 
	call GetKeyState 
		and eax, -2 
		cmp eax, 0 
		jz exit_not 
	push dword ptr offset exit_do 
	ret 
		exit_not: 
	push dword ptr 76 
	call GetKeyState 
		and eax, -2 
		cmp eax, 0 
		jz exit_not2 
	push dword ptr MB_YESNO 
	push dword ptr offset ApplicationName 
	push dword ptr string("Do you want logging enabled? ") 
	push dword ptr 0 
	call MessageBox 
	cmp eax, IDYES 
	jnz @F 
		mov dword ptr [logging], 1 
	@@: 
	cmp eax, IDNO 
	jnz @F 
		mov dword ptr [logging], 0 
	@@: 
		exit_not2: 
			ret 
	exit_do: 
		push dword ptr MB_YESNO 
		push dword ptr string("ServerB") 
		push dword ptr string("Are you sure you want to exit ServerB? ") 
		push dword ptr 0 
		call MessageBox 
	cmp eax, IDYES 
	jnz exit_not 
		; push dword ptr SD_BOTH 
		; push dword ptr [socket1] 
		; call shutdown 
		; push dword ptr [socket1] 
		; call closesocket 
			push dword ptr SD_BOTH 
			push dword ptr [main_socket] 
			call shutdown 
			push dword ptr [main_socket] 
			call closesocket 
	call WSACleanup 
		push dword ptr [pBuffer] 
		call GlobalFree 
			push dword ptr string("Exitting...  ") 
			call StdOut 
		push dword ptr [hLog] 
		call CloseHandle 
	push dword ptr 0 
	call ExitProcess 
		ret 
;; endp 


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;; serve()    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 

serve: 
	mov eax, dword ptr [rNumber] 
	mov ecx, eax 
	mov eax, dword ptr [TempSock] 
	inc dword ptr [rNumber] 
	mov dword ptr [TempSock], 0 
	
	xchg eax, ecx 
	
	;; Wait for our turn. 
	@@: 
	cmp eax, dword ptr [current_request] 
	jz @F 
	jmp @B 
	@@: 
	
	xchg eax, ecx 
	
	push ebp 
	mov ebp, esp 
	sub esp, 36 + 512 + 4096 + 16 + 12 + 32 + 1024 + 4 
	sock1                 equ  ebp - 4 
	rN                    equ  ebp - 20 
	
	fh1                   equ  ebp - 8 
	
	hI                    equ  ebp - 12 
	hO                    equ  ebp - 16 
	
	bR                    equ  ebp - 24 
	fh1_close             equ  ebp - 28 
	
	local_count           equ  ebp - 32 
	
	local_point           equ  ebp - 36 
	
	local_string1         equ  ebp - (36 + 512) 
	local_buffer          equ  ebp - (36 + 512 + 4096) 
	local_method          equ  ebp - (36 + 512 + 4096 + 16) 
	
	hO2                   equ  ebp - (36 + 512 + 4096 + 16) - 4 
	pExit                 equ  ebp - (36 + 512 + 4096 + 16) - 8 
	
	send_body             equ  ebp - (36 + 512 + 4096 + 16) - 12 
	
	s_a_1                 equ  ebp - (36 + 512 + 4096 + 16) - 12 - 32 + 0 
	s_a_2                 equ  ebp - (36 + 512 + 4096 + 16) - 12 - 32 + SIZEOF SECURITY_ATTRIBUTES 
	
	local_file_to_delete  equ  ebp - (36 + 512 + 4096 + 16) - 12 - 32 - 512 
	remote_addr           equ  ebp - (36 + 512 + 4096 + 16) - 12 - 32 - 1024 
	remote_host           equ  ebp - (36 + 512 + 4096 + 16) - 12 - 32 - 1536 
	
	from_sBuffer          equ  ebp - (36 + 512 + 4096 + 16) - 12 - 32 - 1536 - 4 
		mov dword ptr [sock1], eax 
		mov eax, ecx 
		mov dword ptr [rN], eax 
		
		mov dword ptr [hI], 0 
		mov dword ptr [hO], 0 
		
		mov dword ptr [hO2], 0 
		
		mov dword ptr [local_point], 0 
		
		lea ebx, [local_file_to_delete] 
		mov dword ptr [ebx], 0 
		
		push dword ptr offset string01 
		push dword ptr [rN] 
		call i2str 
		mov edx, eax 
		mov eax, string() 
		mov ebx, string("serverB_input_") 
		call StringCopy 
		mov ebx, edx 
		call StringCat 
		mov ebx, string(".txt") 
		call StringCat 
		lea ebx, [s_a_1] 
			mov dword ptr [ebx+00], SIZEOF SECURITY_ATTRIBUTES 
			mov dword ptr [ebx+04], 0 
			mov dword ptr [ebx+08], 1 
		push dword ptr 0 
		push dword ptr 128                          ;; FILE_ATTRIBUTE_NORMAL 
		push dword ptr 2                            ;; CREATE_ALWAYS 
		push ebx 
		push dword ptr 1 or 2 or 4 
		push dword ptr GENERIC_READ or GENERIC_WRITE 
		push eax 
		call CreateFile 
		mov dword ptr [hI], eax 
		
		push dword ptr offset string01 
		push dword ptr [rN] 
		call i2str 
		mov edx, eax 
		mov eax, string() 
		mov ebx, string("serverB_output_") 
		call StringCopy 
			mov dword ptr [ebp-8], eax 
		mov ebx, edx 
		call StringCat 
		mov ebx, string(".txt") 
		call StringCat 
		lea ebx, [s_a_2] 
			mov dword ptr [ebx+00], SIZEOF SECURITY_ATTRIBUTES 
			mov dword ptr [ebx+04], 0 
			mov dword ptr [ebx+08], 1 
		push dword ptr 0 
		push dword ptr 128 
		push dword ptr 2 
		push ebx 
		push dword ptr 1 or 2 or 4 
		push dword ptr GENERIC_READ or GENERIC_WRITE 
		push eax 
		call CreateFile 
		mov dword ptr [hO], eax 
		
		call GetSysTimeString 
		push eax 
		call ServerB_log 
		
		push dword ptr string(9, "#", 9, "New Request", 59, 32, "Request Number", 58, 32) 
		call ServerB_log 
		push dword ptr offset string01 
		push dword ptr [rN] 
		call i2str 
		push eax 
		call ServerB_log 
		push dword ptr string(13, 10) 
		call ServerB_log 
		
		call GetSysTimeString 
		push eax 
		call ServerB_log 
		
		push dword ptr string(9) 
		call ServerB_log 
		push dword ptr offset string01 
		push dword ptr [rN] 
		call i2str 
		mov edx, eax 
		push eax 
		call ServerB_log 
		push dword ptr string(9, "Current Standard Input Filename: serverB_input_") 
		call ServerB_log 
		push edx 
		call ServerB_log 
		push dword ptr string(".txt", 13, 10) 
		call ServerB_log 
		
		call GetSysTimeString 
		push eax 
		call ServerB_log 
		
		push dword ptr string(9) 
		call ServerB_log 
		push dword ptr offset string01 
		push dword ptr [rN] 
		call i2str 
		mov edx, eax 
		push eax 
		call ServerB_log 
		push dword ptr string(9, "Current Standard Output Filename: serverB_output_") 
		call ServerB_log 
		push edx 
		call ServerB_log 
		push dword ptr string(".txt", 13, 10) 
		call ServerB_log 
		
		call GetSysTimeString 
		push eax 
		call ServerB_log 
		
		push dword ptr string(9) 
		call ServerB_log 
		
		push dword ptr offset string01 
		push dword ptr [rN] 
		call i2str 
		
		push dword ptr offset string01 
		call ServerB_log 
		
		push dword ptr string(9, "Peer IP Address: ") 
		call ServerB_log 
		
		
		;; Get peer IP address: 
		
		invoke getpeername, [sock1], offset sa1, integer(SIZEOF sockaddr_in) 
		
		xor eax, eax 
		mov ebx, offset sa1 
		mov al, byte ptr [ebx+4] 
		push dword ptr offset string01 
		push eax 
		call i2str 
		mov eax, offset string02 
		mov ebx, offset string01 
		call StringCopy 
		mov ebx, string(46) 
		call StringCat 
		
		xor eax, eax 
		mov ebx, offset sa1 
		mov al, byte ptr [ebx+5] 
		push dword ptr offset string01 
		push eax 
		call i2str 
		mov eax, offset string02 
		mov ebx, offset string01 
		call StringCat 
		mov ebx, string(46) 
		call StringCat 
		
		xor eax, eax 
		mov ebx, offset sa1 
		mov al, byte ptr [ebx+6] 
		push dword ptr offset string01 
		push eax 
		call i2str 
		mov eax, offset string02 
		mov ebx, offset string01 
		call StringCat 
		mov ebx, string(46) 
		call StringCat 
		
		xor eax, eax 
		mov ebx, offset sa1 
		mov al, byte ptr [ebx+7] 
		push dword ptr offset string01 
		push eax 
		call i2str 
		mov eax, offset string02 
		mov ebx, offset string01 
		call StringCat 
		
		push dword ptr offset string02 
		call ServerB_log 
		
		mov eax, offset remote_ip 
		mov ebx, offset string02 
		call StringCopy 
		
		lea eax, [remote_addr] 
		call StringCopy 
		
		push eax 
		call gethostbyname 
			cmp eax, 0 
			jz getting_host_lbl1 
		mov ebx, eax 
		mov eax, dword ptr [ebx+00] 
		mov ebx, eax 
		lea eax, [remote_host] 
		call StringCopy 
		
		jmp getting_host_lbl2 
		
		getting_host_lbl1: 
		
		lea eax, [remote_host] 
		lea ebx, [remote_addr] 
		call StringCopy 
		
		jmp getting_host_lbl2 
		
		getting_host_lbl2: 
		
		;; Log WSAGetLastError() 
		;call WSAGetLastError 
		;push dword ptr offset string01 
		;push eax 
		;call i2str 
		;push dword ptr string(32, 60, "WSA getpeername() error code: ") 
		;call ServerB_log 
		;push dword ptr offset string01 
		;call ServerB_log 
		;push dword ptr string(62, 32) 
		;call ServerB_log 
		
		jmp serve_continue1 
		
		
		sock1lp1: 
		mov eax, ebp 
		sub eax, 12 
		invoke ioctlsocket, [sock1], FIONREAD, eax 
		mov eax, dword ptr [ebp-12] 
		cmp eax, 0 
		jz sock1lp1 
		
		;push dword ptr offset time 
		;call GetLocalTime 
		;mov ebx, offset time 
		;xor eax, eax 
		;mov ax, word ptr [ebx+14] 
		;mov dword ptr [time1], eax 
		;lp002: 
		;	push dword ptr offset time 
		;	call GetLocalTime 
		;	xor eax, eax 
		;	mov ebx, offset time 
		;	mov ax, word ptr [ebx+14] 
		;	sub eax, 500 
		;	cmp eax, dword ptr [time1] 
		;	jnl lp002 
		;lp002s: 
		
		
		
		serve_continue1: 
		
		invoke StdOut, string("Client Connected!", 13, 10) 
		
		invoke StdOut, string("Receiving Data...") 
		
		mov eax, dword ptr [hI] 
		mov dword ptr [fh1], eax 
		
		mov dword ptr [n], 0 
		
		mov dword ptr [save1cc_index], 0 
		mov dword ptr [save1cc_count], 0 
		mov dword ptr [save1cc_point], 0 
		
		
		;; Log "\r\n" 
		push dword ptr string(13, 10) 
		call ServerB_log 
		
		;; Log "time	# Receiving Header...  \r\n" 
		call GetSysTimeString 
		push eax 
		call ServerB_log 
		push dword ptr string(9) 
		call ServerB_log 
		push dword ptr offset string01 
		push dword ptr [rN] 
		call i2str 
		push dword ptr offset string01 
		call ServerB_log 
		push dword ptr string(9, "Receiving Header...  ", 13, 10) 
		call ServerB_log 
		
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;; save1          ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		
		save1: 
			cmp dword ptr [n], 2 
			jnl save1s 
			
			invoke recv, [sock1], offset sBuffer, 1, 0 
			cmp eax, 0 
			jz save1s 
			cmp eax, SOCKET_ERROR 
			jz h_err1 
			mov dword ptr [bR], eax 
			
			invoke WriteFile, [fh1], offset sBuffer, [bR], offset e3, 0 
			
			mov al, byte ptr [sBuffer] 
			cmp al, 13 
			jnz @F 
				inc dword ptr [r] 
				jmp save1c 
			@@: 
			mov al, byte ptr [sBuffer] 
			cmp al, 10 
			jnz @F 
				inc dword ptr [n] 
				jmp save1c 
			@@: 
			mov al, byte ptr [sBuffer] 
			cmp al, 67 
			jz save1cc 
			cmp al, 99 
			jz save1cc 
			cmp dword ptr [save1cc_index], -1 
			jz save1ccc 
				mov dword ptr [r], 0 
				mov dword ptr [n], 0 
				jmp save1cc 
				jmp save1c 
			save1cc: 
				cmp dword ptr [save1cc_index], -1 
				jz save1ccc 
				
				mov ebx, string("Content-Length:") 
				mov eax, dword ptr [save1cc_index] 
				add ebx, eax 
				mov al, byte ptr [ebx] 
				cmp al, 97 
				jl @F 
				cmp al, 122 
				jg @F 
				sub al, 32 
				@@: 
				mov ah, byte ptr [sBuffer] 
				cmp ah, 97 
				jl @F 
				cmp ah, 122 
				jg @F 
				sub ah, 32 
				@@: 
				cmp al, 0 
				jz save1ccc 
				cmp al, ah 
				jnz save1cc_nz 
				inc dword ptr [save1cc_index] 
				jmp save1c 
				save1cc_nz: 
					mov dword ptr [save1cc_index], 0 
					jmp save1c 
			save1ccc: 
				mov dword ptr [save1cc_index], -1 
				
				cmp dword ptr [save1cc_count], 0 
				jnz save1ccc_n0 
					mov ebx, offset string02 
					mov eax, dword ptr [save1cc_point] 
					add ebx, eax 
					
					mov al, byte ptr [sBuffer] 
					cmp al, 13 
					jz @F 
					cmp al, 10 
					jz @F 
					;cmp al, 32 
					;jz @F 
					;cmp al, 9 
					;jz @F 
					
					mov byte ptr [ebx], al 
					
					inc dword ptr [save1cc_point] 
					
					jmp save1c 
					
					@@: 
					mov byte ptr [ebx], 0 
					
					inc dword ptr [save1cc_count] 
					
					jmp save1c 
				save1ccc_n0: 
					
					
					jmp save1c 
				@@: 
				
				jmp save1c 
			save1c: 
			
			;push dword ptr string("save1cc_index", 61, 32) 
			;call ServerB_log 
			;push dword ptr offset string01 
			;push dword ptr [save1cc_index] 
			;call i2str 
			;push eax 
			;call ServerB_log 
			;push dword ptr string(59, 32, "save1cc_count", 61, 32) 
			;call ServerB_log 
			;push dword ptr offset string01 
			;push dword ptr [save1cc_count] 
			;call i2str 
			;push eax 
			;call ServerB_log 
			;push dword ptr string(59, 32, "save1cc_point", 61, 32) 
			;call ServerB_log 
			;push dword ptr offset string01 
			;push dword ptr [save1cc_point] 
			;call i2str 
			;push eax 
			;call ServerB_log 
			;push dword ptr string(59, 32, "ASCII", 61, 32) 
			;call ServerB_log 
			;push dword ptr offset string01 
			;xor eax, eax 
			;mov al, byte ptr [sBuffer] 
			;push eax 
			;call i2str 
			;push eax 
			;call ServerB_log 
			;mov ebx, string(59, 32, "text", 61, 32) 
			;mov al, byte ptr [sBuffer] 
			;cmp al, 13 
			;jz @F 
			;cmp al, 10 
			;jz @F 
			;push ebx 
			;call ServerB_log 
			;mov byte ptr [sBuffer+1], 0 
			;push dword ptr offset sBuffer 
			;call ServerB_log 
			;@@: 
			;push dword ptr string(59, 32, 13, 10) 
			;call ServerB_log 
			
			jmp save1 
		save1s: 
		
		;; Take all the spaces (and tabs) out from the beginning of the string. 
		mov ebx, offset string02 
		dec ebx 
		@@: 
		inc ebx 
		mov al, byte ptr [ebx] 
		cmp al, 32 
		jz @B 
		cmp al, 9 
		jz @B 
		@@: 
		mov eax, offset string02 
		call StringCopy 
		
		;; Parse the integer string. 
		push dword ptr offset string02 
		call str2i 
		push dword ptr offset string02 
		push eax 
		call i2str 
		
		mov eax, offset string01 
		mov ebx, offset string02 
		call StringCopy 
		
		push dword ptr string(13, 10) 
		call StdOut 
		
		mov ebx, string(48) 
		
		cmp dword ptr [save1cc_point], 0 
		jg @F 
			mov eax, offset string02 
			call StringCopy 
		@@: 
		
		push dword ptr offset string02 
		call str2i 
		mov dword ptr [content_length], eax 
		
		call GetSysTimeString 
		push eax 
		call ServerB_log 
		
		push dword ptr string(9) 
		call ServerB_log 
		
		mov eax, string() 
		push eax 
		push eax 
		push dword ptr [rN] 
		call i2str 
		call ServerB_log 
		
		push dword ptr string(9, "Request Header  ", 45, 62, "  Content-Length: ") 
		call ServerB_log 
		
		push dword ptr offset string02 
		call ServerB_log 
		
		push dword ptr string(13, 10) 
		call ServerB_log 
		
		
		call GetSysTimeString 
		push eax 
		call ServerB_log 
		push dword ptr string(9) 
		call ServerB_log 
		push dword ptr offset string01 
		push dword ptr [rN] 
		call i2str 
		push eax 
		call ServerB_log 
		push dword ptr string(9, "Receiving the rest of the request...  ", 13, 10) 
		call ServerB_log 
		
		
		xor ecx, ecx  ;; IMPORTANT!!! 
		
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;; save2          ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		
		pusha 
			push dword ptr offset string01 
			push ecx 
			call i2str 
			push eax 
			push dword ptr string(13) 
			call StdOut 
			call StdOut 
			push dword ptr string("    bytes received, so far. ") 
			call StdOut 
		popa 
		
		save2: 
			mov eax, dword ptr [content_length] 
			cmp eax, ecx 
			jng save2s 
			
			push ecx  ;; store ecx 
			
			sub eax, ecx 
			cmp eax, 4096 
			jnl save2over1 
			
			invoke recv, [sock1], [pBuffer], [lBuffer], 0 
			cmp eax, 0 
			jz save2s 
			cmp eax, SOCKET_ERROR 
			jz h_err1 
			
			invoke WriteFile, [fh1], [pBuffer], eax, offset e3, 0 
			
			pop ecx 
			
			jmp save2s 
			
			save2over1: 
			
			invoke recv, [sock1], [pBuffer], [lBuffer], 0 
				pop ecx 
			cmp eax, 0 
			jz save2s 
			cmp eax, SOCKET_ERROR 
			jz h_err1 
			
				push ecx 
			invoke WriteFile, [fh1], [pBuffer], eax, offset e3, 0 
			pop ecx  ;; load ecx 
			
			mov eax, dword ptr [e3] 
			add ecx, eax 
			
			pusha 
				push dword ptr offset string01 
				push ecx 
				call i2str 
				push eax 
				push dword ptr string(13) 
				call StdOut 
				call StdOut 
				push dword ptr string("    bytes received, so far. ") 
				call StdOut 
			popa 
			
			jmp save2 
		save2s: 
		
		pusha 
			push dword ptr offset string01 
			push ecx 
			call i2str 
			push eax 
			push dword ptr string(13) 
			call StdOut 
			call StdOut 
			push dword ptr string("    bytes received, so far. ") 
			call StdOut 
		popa 
		
		push dword ptr string(13, 10) 
		call StdOut 
		
		push dword ptr 0 
		push dword ptr [fh1] 
		call set_pointer 
		mov dword ptr [fh1], 0 
		
		call GetSysTimeString 
		push eax 
		call ServerB_log 
		push dword ptr string(9) 
		call ServerB_log 
		push dword ptr offset string01 
		push dword ptr [rN] 
		call i2str 
		push eax 
		call ServerB_log 
		push dword ptr string(9, "Request received. Processing...  ", 13, 10) 
		call ServerB_log 
		
		jmp respond1 
		
		jmp over000101010101001 
		h_err1: 
			mov eax, dword ptr [local_point] 
			cmp eax, 0 
			jz @F 
				mov ebx, eax 
				add ebx, SIZEOF STARTUPINFO 
				mov eax, dword ptr [ebx+00] 
				
				push dword ptr 0 
				push eax 
				call TerminateProcess 
			@@: 
			
			call GetSysTimeString 
			push eax 
			call ServerB_log 
			push dword ptr string(9) 
			call ServerB_log 
			push dword ptr offset string01 
			push dword ptr [rN] 
			call i2str 
			push eax 
			call ServerB_log 
			push dword ptr string(32, "h_err1 error occurred. ") 
			call ServerB_log 
			
			push dword ptr string("WSA Error Code: ") 
			call ServerB_log 
			push dword ptr offset string01 
			push eax 
			call i2str 
			push eax 
			call ServerB_log 
			push dword ptr string(13, 10) 
			call ServerB_log 
			
			call clean_up_files 
			
			cmp dword ptr [local_point], 0 
			jz @F 
				push dword ptr [local_point] 
				call GlobalFree 
				mov dword ptr [local_point], 0 
			@@: 
			
			jmp lp001a1s 
			
			leave 
			
			invoke ExitThread, 0 
			
			ret 
		h_cls1: 
			call GetSysTimeString 
			push eax 
			call ServerB_log 
			push dword ptr string(9) 
			call ServerB_log 
			push dword ptr offset string01 
			push dword ptr [rN] 
			call i2str 
			push eax 
			call ServerB_log 
			push dword ptr string(32, "h_cls1 error occurred. ") 
			call ServerB_log 
			
			push dword ptr string("WSA Error Code: ") 
			call ServerB_log 
			push dword ptr offset string01 
			push eax 
			call i2str 
			push eax 
			call ServerB_log 
			push dword ptr string(13, 10) 
			call ServerB_log 
			
			jmp lp001a1s 
			
			leave 
			
			invoke ExitThread, 0 
			
			ret 
		over000101010101001: 
		
		;invoke StdOut, string(13, 10, 13, 10) 
		
		;push dword ptr [hFile] 
		;call CloseHandle 
		;;invoke CloseHandle, [hFile] 
		
		;;mov eax, dword ptr [ebp-8] 
		;mov ebx, string("HTTP/1.0 401 Access Denied", 13, 10, "WWW-Authenticate: Basic realm=", 34, "Hello, user.", 34, 13, 10, 13, 10) 
		;;mov ebx, string("HTTP/1.0 200 OK", 13, 10, "Content-type: text/html", 13, 10, 13, 10) 
		;;call StringCopy 
		;;mov ebx, eax 
		;;call StringLength 
		;;mov ecx, eax 
		;; .....  
		;;push dword ptr 0 
		;;push dword ptr ecx 
		;;push dword ptr [ebp-8] 
		;;push dword ptr [sock1] 
		;;call send 
		;invoke send, [sock1], [ebp-8], ecx, 0 
		
		;mov dword ptr [ebp-8], offset sBuffer 
		
		respond1: 
		
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;; respond:         ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		
		mov eax, dword ptr [hI] 
		mov dword ptr [e2], eax 
		mov dword ptr [e4], integer() 
		invoke ReadFile, [e2], offset sBuffer, 4095, [e4], 0 
		mov eax, dword ptr [e4] 
		mov ebx, eax 
		mov eax, dword ptr [ebx] 
		mov ebx, eax 
		add ebx, offset sBuffer 
		mov byte ptr [ebx], 0 
		push dword ptr 0 
		push dword ptr [e2] 
		call set_pointer 
		mov dword ptr [e2], 0 
		
		; push dword ptr offset sBuffer 
		; call ServerB_log 
		; push dword ptr string (13, 10) 
		; call ServerB_log 
		
		; mov eax, [the_direction] 
		; push dword ptr offset string01 
		; push eax 
		; call i2str 
		
		; push dword ptr offset string01 
		; call ServerB_log 
		; push dword ptr string (13, 10) 
		; call ServerB_log 
		
		mov ebx, offset sBuffer 
		call skip_to_space 
		mov byte ptr [ebx], 0 
		push ebx 
			
			; mov eax, ebx 
			; sub eax, offset sBuffer 
			; push dword ptr offset string01 
			; push eax 
			; call i2str 
			
			; push dword ptr offset string01 
			; call ServerB_log 
			; push dword ptr string (13, 10) 
			; call ServerB_log 
			
			mov eax, offset method 
			mov ebx, offset sBuffer 
			call StringCopy 
			
			; push eax 
			; push dword ptr offset method 
			; call ServerB_log 
			; push dword ptr string (13, 10) 
			; call ServerB_log 
			; pop eax 
			
		pop ebx 
		inc ebx 
		call skip_to_non_space 
		mov eax, offset sBuffer 
		call StringCopy 
		
		
			; push eax 
			; push dword ptr offset sBuffer 
			; call ServerB_log 
			; push dword ptr string (13, 10) 
			; call ServerB_log 
			; pop eax 
		
		
		mov ebx, eax 
		call skip_to_next 
		dec ebx 
		mov byte ptr [ebx], 0 
		
		;invoke StdOut, string("File name: ") 
		;invoke StdIn, offset sBuffer, 512 
		;mov ebx, offset sBuffer 
		;call replace_new_with_null 
		
		invoke StdOut, string(9, "Method: ", 34) 
		invoke StdOut, offset method 
		invoke StdOut, string(34, 13, 10) 
		
		invoke StdOut, string(9, "File Requested: ", 34) 
		invoke StdOut, offset sBuffer 
		invoke StdOut, string(34, 13, 10) 
		
		;; Log the request method. 
		call GetSysTimeString 
		push eax 
		call ServerB_log 
		push dword ptr string(9) 
		call ServerB_log 
		push dword ptr offset string01 
		push dword ptr [rN] 
		call i2str 
		push eax 
		call ServerB_log 
		push dword ptr string(9, "Method: ") 
		call ServerB_log 
		push dword ptr offset method 
		call ServerB_log 
		push dword ptr string(13, 10) 
		call ServerB_log 
		
		;; Log the file requested. 
		call GetSysTimeString 
		push eax 
		call ServerB_log 
		push dword ptr string(9) 
		call ServerB_log 
		push dword ptr offset string01 
		push dword ptr [rN] 
		call i2str 
		push eax 
		call ServerB_log 
		push dword ptr string(9, "Path: ") 
		call ServerB_log 
		push dword ptr offset sBuffer 
		call ServerB_log 
		push dword ptr string(13, 10) 
		call ServerB_log 
		
		mov eax, integer() 
		mov dword ptr [e3], eax 
		mov ebx, eax 
		mov dword ptr [ebx], 0 
		invoke OpenFile, string("server1s.txt"), addr ofstruct, 0 
		mov dword ptr [e4], eax 
		invoke ReadFile, [e4], [e3], 1, integer(), 0 
		invoke CloseHandle, [e4] 
		
		mov eax, dword ptr [e3] 
		mov ebx, eax 
		mov al, [ebx] 
		cmp al, 66 
		jz block_1 
		cmp al, 98 
		jz block_1 
		
		;invoke StdIn, string(0), 0 
		
		mov eax, integer() 
		mov dword ptr [e3], eax 
		invoke OpenFile, string("server1s.txt"), addr ofstruct, 0 
		mov dword ptr [e4], eax 
		invoke ReadFile, [e4], [e3], 1, integer(), 0 
		invoke CloseHandle, [e4] 
		
		mov eax, dword ptr [e3] 
		mov ebx, eax 
		mov al, [ebx] 
		cmp al, 66 
		jz block_1 
		cmp al, 98 
		jz block_1 
		
		invoke StdOut, string(9, "Data prepared. Sending data...  ", 13, 10) 
		
		mov eax, offset request_uri 
		mov ebx, offset sBuffer 
		call StringCopy 
		
		;; Trim everything after the "?" (if there is one), including the "?" 
		mov eax, offset sBuffer 
		mov ebx, eax 
		@@: 
			mov al, byte ptr [ebx] 
			cmp al, 63     ;; ("?") 
			jz @F 
			cmp al, 0 
			jz @F 
			inc ebx 
			jmp @B 
		@@: 
		mov byte ptr [ebx], 0 
		
		inc ebx 
		mov eax, offset query_string 
		call StringCopy 
		
		mov ebx, offset query_string 
		mov edx, string("HTTP/1") 
		@@: 
			mov eax, edx 
			call strcmp 
			cmp eax, 0 
			jz @F 
			
			mov al, byte ptr [ebx] 
			cmp al, 0 
			jz @F 
			
			inc ebx 
			jmp @B 
		@@: 
			dec ebx 
			mov al, byte ptr [ebx] 
			cmp al, 32 
			jz @B 
			cmp al, 9 
			jz @B 
			cmp al, 13 
			jz @B 
			cmp al, 10 
			jz @B 
		@@: 
		inc ebx 
		mov byte ptr [ebx], 0 
		
		push dword ptr offset sBuffer 
		call GetFileAttributes 
		test eax, FILE_ATTRIBUTE_DIRECTORY ;; 0x16 
		jz file_checked_is_not_a_directory 
			
			;; Otherwise it is a folder. Need to replace this with index.html, etc. 
			
			mov eax, offset string () 
			mov ebx, offset base_directory 
			call StringCopy 
			mov ebx, offset sBuffer 
			call StringCat 
			
			mov ebx, string ("index.html") 
			call StringCat 
			
			push eax 
			push ebx 
			
			push eax 
			call ServerB_log 
			push dword ptr string (13, 10) 
			call ServerB_log 
			
			pop ebx 
			pop eax 
			push eax 
			push ebx 
			
			push eax 
			call GetFileAttributes 
			cmp eax, INVALID_FILE_ATTRIBUTES 
			jnz found_default_file 
			
			pop ebx 
			pop eax 
			
			;; TODO: Check for more file types, such as index.php, etc. 
			
			jmp done_searching_default_files 
			
			found_default_file: 
			pop ebx 
			pop eax 
			mov eax, offset sBuffer 
			call StringCat 
			
		file_checked_is_not_a_directory: 
		done_searching_default_files: 
		
		;; Copy the script_name field. 
		mov eax, offset script_name 
		mov ebx, offset sBuffer 
		call StringCopy 
		
		;; Don't want to let the client be able to access just any file on our machine. 
		mov eax, string() 
		mov ebx, offset base_directory 
		call StringCopy 
		mov ebx, eax 
		mov eax, offset sBuffer 
		call SquishString 
		
		;; Log the file to be sent. 
		call GetSysTimeString 
		push eax 
		call ServerB_log 
		push dword ptr string(9) 
		call ServerB_log 
		push dword ptr offset string01 
		push dword ptr [rN] 
		call i2str 
		push eax 
		call ServerB_log 
		push dword ptr string(9, "Local File Address: ") 
		call ServerB_log 
		push dword ptr offset sBuffer 
		call ServerB_log 
		push dword ptr string(13, 10) 
		call ServerB_log 
		
		invoke StdOut, string(9, 9, "Host access filename: ") 
		invoke StdOut, offset sBuffer 
		invoke StdOut, string(13, 10) 
		
		invoke StdOut, string(9, 9, 9, "Base directory: ") 
		invoke StdOut, offset base_directory 
		invoke StdOut, string(13, 10) 
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		
		
		push dword ptr 0 
		push dword ptr space(SIZEOF OFSTRUCT) 
		push dword ptr offset sBuffer 
		call OpenFile 
		cmp eax, 0 
		jz err_404 
		cmp eax, -1 
		jz err_404 
		mov dword ptr [fh1], eax 
		
		mov ebx, offset some_string 
		xor eax, eax 
		mov dword ptr [ebx+0], eax 
		mov dword ptr [ebx+4], eax 
		mov dword ptr [ebx+8], eax 
		
		push dword ptr 0 
		push dword ptr integer() 
		push dword ptr 16 
		push dword ptr offset some_string 
		push dword ptr [fh1] 
		call ReadFile 
		
		push dword ptr [fh1] 
		call CloseHandle 
		
		mov dword ptr [fh1], 0 
		
		;; replace char 58 with char 0 in (some_string) 
		mov ebx, offset some_string 
		@@: 
			mov al, byte ptr [ebx] 
			cmp al, 58 
			jz @F 
			cmp al, 0 
			jz @F 
			inc ebx 
			jmp @B 
		@@: 
		mov byte ptr [ebx], 0 
		
		
		;; lc some_string 
		mov ebx, offset some_string 
		@@: 
			mov al, byte ptr [ebx] 
			cmp al, 0 
			jz @F 
			call lc_al 
			mov byte ptr [ebx], al 
			inc ebx 
			jmp @B 
		@@: 
		
		mov ebx, offset some_string 
		
		;; The reason these letters (i.e. "MZ") are in lower case is that we lower-cased the buffer, earlier. 
		cmp word ptr [ebx], "zm"     ;; "mz" backwards. 
		jz direct_exec 
		cmp word ptr [ebx], "ed"     ;; "de" backwards; assumed to be a DOS application. 
		jz dos_exec 
		cmp word ptr [ebx], "mz" 
		jz direct_exec 
		cmp word ptr [ebx], "de" 
		jz dos_exec 
		
		mov eax, string("file") 
		call simple_compare 
		cmp eax, 0 
		jz send_the_data1 
		
		mov eax, string("lfile") 
		call simple_compare 
		cmp eax, 0 
		jz send_the_data 
		
		
		xor eax, eax 
		lea ebx, [some_string] 
		mov dword ptr [ebx+00], eax 
		mov dword ptr [ebx+04], eax 
		mov dword ptr [ebx+08], eax 
		mov dword ptr [ebx+12], eax 
		
		push dword ptr 0 
		push dword ptr space(SIZEOF OFSTRUCT) 
		push dword ptr offset sBuffer 
		call OpenFile 
		mov dword ptr [fh1], eax 
		cmp eax, 0 
		jz err_404 
		cmp eax, -1 
		jz err_404 
		
		push dword ptr 0 
		push dword ptr integer() 
		push dword ptr 510 
		push dword ptr offset some_string 
		push dword ptr [fh1] 
		call ReadFile 
		
		push dword ptr [fh1] 
		call CloseHandle 
		
		mov dword ptr [fh1], 0 
		
		xor ecx, ecx 
		mov ebx, offset some_string 
		@@: 
			mov al, byte ptr [ebx+ecx] 
			cmp al, 33 
			jz @F 
			cmp al, 0 
			jz send_the_data 
			inc ecx 
			cmp ecx, 10 
			jl @B 
			jmp send_the_data 
		@@: 
		inc ecx 
		add ebx, ecx 
		mov eax, ebx 
		mov dword ptr [p_exec], eax 
		mov eax, dword ptr [p_exec] 
		mov ebx, eax 
		@@: 
			mov al, byte ptr [ebx] 
			cmp al, 13 
			jz @F 
			cmp al, 10 
			jz @F 
			cmp al, 0 
			jz @F 
			inc ebx 
			jmp @B 
		@@: 
		mov byte ptr [ebx], 0 
		
		push dword ptr string("Executable: ") 
		call StdOut 
		push dword ptr [p_exec] 
		call StdOut 
		push dword ptr string(13, 10) 
		call StdOut 
		
		
		mov eax, dword ptr [p_exec] 
		mov ebx, eax 
		mov eax, offset exec_string 
		call StringCopy 
		
		mov eax, dword ptr [p_exec] 
		mov ebx, eax 
		mov al, byte ptr [ebx] 
		cmp al, 34 
		jz find_exec_over1 
		
		@@: 
			mov al, byte ptr [ebx] 
			cmp al, 32 
			jnz @F 
			cmp al, 9 
			jnz @F 
			cmp al, 0 
			jz @F 
			inc ebx 
			jmp @B 
		@@: 
		mov eax, ebx 
		mov dword ptr [p_exec], eax 
		@@: 
			mov al, byte ptr [ebx] 
			cmp al, 13 
			jz @F 
			cmp al, 10 
			jz @F 
			cmp al, 0 
			jz @F 
			inc ebx 
			jmp @B 
		@@: 
		mov byte ptr [ebx], 0 
		
		jmp find_exec_over2 
		
		find_exec_over1: 
		
		inc ebx 
		@@: 
			mov al, byte ptr [ebx] 
			cmp al, 34 
			jz @F 
			cmp al, 0 
			jz err_500                ;; Command-line string too large. 
			inc ebx 
			jmp @B 
		@@: 
		inc ebx 
		mov byte ptr [ebx], 0 
		
		jmp find_exec_over2 
		
		find_exec_over2: 
		
		
		;; Now check to see if the executable module filename file exists. 
		
		push dword ptr 0 
		push dword ptr space(SIZEOF OFSTRUCT) 
		push dword ptr [p_exec] 
		call OpenFile 
		cmp eax, 0 
		jz @F 
		cmp eax, -1 
		jz @F 
		jmp @_over02 
		@@: 
		jmp @_over01 
		@_over01: 
		
		mov eax, dword ptr [p_exec] 
		mov ebx, eax 
		mov al, byte ptr [ebx] 
		cmp al, 47 
		jnz @F 
		cmp al, 92 
		jnz @F 
		jmp send_the_data 
		@@: 
		
		jmp send_the_data 
		
		@_over02: 
		
		mov eax, dword ptr [p_exec] 
		mov ebx, eax 
		mov al, byte ptr [ebx] 
		cmp al, 92 
		jnz @F 
			mov ebx, offset sBuffer 
			call replace_47_with_92 
		@@: 
		
		push eax 
		call CloseHandle 
		
		push dword ptr [p_exec] 
		call StdOut 
		push dword ptr string(32, "EXEC OK", 13, 10) 
		call StdOut 
		
		mov eax, offset exec_string 
		mov ebx, offset cmd_string 
		xchg eax, ebx 
		call StringCopy 
		mov ebx, string(32) 
		call StringCat 
		mov ebx, offset sBuffer 
		call StringCat 
		mov ebx, string(32) 
		call StringCat 
		lea ebx, [remote_addr] 
		call StringCat 
		
		push dword ptr string("Command Line: ") 
		call StdOut 
		push dword ptr offset cmd_string 
		call StdOut 
		push dword ptr string(13, 10) 
		call StdOut 
		
		push dword ptr 0 
		push dword ptr 0 
		push dword ptr 0 
		push dword ptr [hI] 
		call SetFilePointer 
		
		push dword ptr 0 
		push dword ptr 0 
		push dword ptr 0 
		push dword ptr [hO] 
		call SetFilePointer 
		
		push dword ptr [hO] 
		call SetEndOfFile 
		
		push dword ptr [hI] 
		push dword ptr STD_INPUT_HANDLE 
		call SetStdHandle 
		
		push dword ptr [hO2] 
		push dword ptr STD_OUTPUT_HANDLE 
		call SetStdHandle 
		
		call set_env 
		
		push dword ptr [hO2] 
		push dword ptr [hI] 
		push dword ptr offset cmd_string 
			push dword ptr offset cmd_string 
			call get_app 
			push eax 
		call app_start 
		cmp eax, 0 
		jz err_500 
		
		call clr_env 
		
		inc dword ptr [current_request] 
		
		mov dword ptr [local_point], eax 
		
		mov eax, edx 
		mov dword ptr [hO2], eax 
		
		push dword ptr [hStdI] 
		push dword ptr STD_INPUT_HANDLE 
		call SetStdHandle 
		
		push dword ptr [hStdO] 
		push dword ptr STD_OUTPUT_HANDLE 
		call SetStdHandle 
		
		push dword ptr 0 
		push dword ptr 0 
		push dword ptr 0 
		push dword ptr [hO] 
		call SetFilePointer 
		
		mov dword ptr [fh1_close], 0 
		
		jmp send_the_data2 
		
		
		get_from_sBuffer: 
			push dword ptr 0 
			push dword ptr integer() 
			push dword ptr SIZEOF rBuffer - 1 
			push dword ptr offset rBuffer 
			push dword ptr [hI] 
			call ReadFile 
			mov ebx, integer() 
			mov eax, dword ptr [ebx-4] 
			mov ebx, offset rBuffer 
			add ebx, eax 
			mov byte ptr [ebx], 0 
			
			push dword ptr 0 
			push dword ptr [hI] 
			call set_pointer 
			
			push dword ptr string(0) 
			push dword ptr string(13, 10, 32) 
			push dword ptr offset rBuffer 
			call replace 
			
			push dword ptr string(0) 
			push dword ptr string(13, 10, 9) 
			push dword ptr offset rBuffer 
			call replace 
			
			mov eax, offset rBuffer 
			mov ebx, eax 
			@@: 
				mov al, byte ptr [ebx] 
				cmp al, 10 
				jz @F 
				inc ebx 
				jmp @B 
			@@: 
			mov eax, ebx 
		ret 
		find_header: 
			enter 4, 0 
			push ebx 
			
			mov eax, dword ptr [ebp+8] 
			mov ebx, eax 
			
			@@: 
				mov al, byte ptr [ebx] 
				cmp al, 10 
				jz @F 
				inc ebx 
				jmp @B 
			@@: 
			inc ebx 
			
			; @@: 
				; mov al, byte ptr [ebx] 
				; inc ebx 
				; cmp al, 13 
				; jz @B 
				; cmp al, 10 
				; jz @B 
				; cmp al, 9 
				; jz @B 
				; cmp al, 32 
				; jz @B 
				; dec ebx 
				; jmp @F 
			; @@: 
			
			fh_lp1: 
				mov eax, dword ptr [ebp+12] 
				call strcmp2 
				cmp eax, 0 
				jz fh_lp1z 
				jmp fh_lp1n 
			fh_lp1n: 
				@@: 
					mov al, byte ptr [ebx] 
					cmp al, 10 
					jz @F 
					cmp al, 0 
					jz fh_lp1e 
					inc ebx 
					jmp @B 
				@@: inc ebx 
				mov al, byte ptr [ebx] 
				cmp al, 13 
				jz fh_lp1e 
				cmp al, 10 
				jz fh_lp1e 
				cmp al, 0 
				jz fh_lp1e 
				jmp fh_lp1 
			fh_lp1z: 
				@@: 
					mov al, byte ptr [ebx] 
					cmp al, 58 
					jz @F 
					cmp al, 0 
					jz fh_lp1e 
					cmp al, 13 
					jz fh_lp1e 
					cmp al, 10 
					jz fh_lp1e 
					inc ebx 
					jmp @B 
				@@: inc ebx 
				@@: 
					mov al, byte ptr [ebx] 
					inc ebx 
					cmp al, 32 
					jz @B 
					cmp al, 9 
					jz @B 
					; cmp al, 13 
					; jz @B 
					; cmp al, 10 
					; jz @B 
					dec ebx 
				@@: 
				mov eax, ebx 
				mov dword ptr [ebp-4], eax 
				jmp fh_lp1s 
			fh_lp1e: 
				mov eax, string(0) 
				mov dword ptr [ebp-4], eax 
				jmp fh_lp1s 
			fh_lp1s: 
			
			mov eax, dword ptr [ebp-4] 
			mov ebx, eax 
			
			mov eax, string() 
			call StringCopy 
			
			mov dword ptr [ebp-4], eax 
			
			mov ebx, eax 
			fh_lp2: 
				mov al, byte ptr [ebx] 
				cmp al, 13 
				jz fh_lp2s 
				cmp al, 10 
				jz fh_lp2s 
				cmp al, 0 
				jz fh_lp2f 
				inc ebx 
				jmp fh_lp2 
			fh_lp2s: 
				; mov al, byte ptr [ebx] 
				; inc ebx 
				; cmp al, 13 
				; jz fh_lp2s 
				; cmp al, 10 
				; jz fh_lp2s 
				; cmp al, 32 
				; jz fh_lp2 
				; cmp al, 9 
				; jz fh_lp2 
				; dec ebx 
				; mov byte ptr [ebx], 0 
				jmp fh_lp2f 
			fh_lp2f: 
			mov byte ptr [ebx], 0 
			
			; push dword ptr string(0) 
			; push dword ptr string(13, 10, 32) 
			; push dword ptr [ebp-4] 
			; call replace 
			
			; push dword ptr string(0) 
			; push dword ptr string(13, 10, 9) 
			; push dword ptr [ebp-4] 
			; call replace 
			
			; push dword ptr string(0) 
			; push dword ptr string(13, 10) 
			; push dword ptr [ebp-4] 
			; call replace 
			
			;; return [ebp-4] 
			mov eax, dword ptr [ebp-4] 
			
			pop ebx 
			leave 
		ret 8 
		set_env: 
			pusha 
			
			push dword ptr string() 
			push dword ptr [content_length] 
			call i2str 
			push eax 
			push dword ptr string("CONTENT_LENGTH") 
			call SetEnvironmentVariable 
			
			push dword ptr offset base_directory 
			push dword ptr string("DOCUMENT_ROOT") 
			call SetEnvironmentVariable 
			
			call get_from_sBuffer 
			mov dword ptr [from_sBuffer], eax 
			
			mov ebx, offset rBuffer 
			@@: 
				mov al, byte ptr [ebx] 
				cmp al, 10 
				jz @F 
				inc ebx 
				jmp @B 
			@@: dec ebx 
			@@: 
				mov al, byte ptr [ebx] 
				cmp al, 13 
				jnz @F 
				dec ebx 
				jmp @B 
			@@: 
				mov al, byte ptr [ebx] 
				dec ebx 
				cmp al, 32 
				jz @B 
				cmp al, 9 
				jz @B 
			@@: 
				mov al, byte ptr [ebx] 
				cmp al, 32 
				jz @F 
				cmp al, 9 
				jz @F 
				dec ebx 
				jmp @B 
			@@: 
			inc ebx 
			push ebx 
			call get_english_word 
			push eax 
			push dword ptr string("SERVER_PROTOCOL") 
			call SetEnvironmentVariable 
			
			push dword ptr string("From:") 
			push dword ptr [from_sBuffer] 
			call find_header 
			push eax 
			push dword ptr string("HTTP_FROM") 
			call SetEnvironmentVariable 
			
			push dword ptr string("Accept:") 
			push dword ptr [from_sBuffer] 
			call find_header 
			push eax 
			push dword ptr string("HTTP_ACCEPT") 
			call SetEnvironmentVariable 
			
			push dword ptr string("Content-Type:") 
			push dword ptr [from_sBuffer] 
			call find_header 
			push eax 
			push dword ptr string("CONTENT_TYPE") 
			call SetEnvironmentVariable 
			
			push dword ptr string("Cookie:") 
			push dword ptr [from_sBuffer] 
			call find_header 
			push eax 
			push dword ptr string("HTTP_COOKIE") 
			call SetEnvironmentVariable 
			
			push dword ptr string("Referer:") 
			push dword ptr [from_sBuffer] 
			call find_header 
			push eax 
			push dword ptr string("HTTP_REFERER") 
			call SetEnvironmentVariable 
			
			;; If "Referrer:" is set, use that for HTTP_REFERRER; use the default field for that, otherwise. 
			push dword ptr string("Referrer:") 
			push dword ptr [from_sBuffer] 
			call find_header 
			mov edx, string("Referer:") 
			mov ebx, eax 
			cmp byte ptr [ebx], 0 
			jnz @F 
				push edx 
				push dword ptr [from_sBuffer] 
				call find_header 
			@@: 
			push eax 
			push dword ptr string("HTTP_REFERRER") 
			call SetEnvironmentVariable 
			
			push dword ptr string("User-Agent:") 
			push dword ptr [from_sBuffer] 
			call find_header 
			push eax 
			push dword ptr string("HTTP_USER_AGENT") 
			call SetEnvironmentVariable 
			
			push dword ptr offset query_string 
			push dword ptr string("QUERY_STRING") 
			call SetEnvironmentVariable 
			
			lea eax, [remote_addr] 
			push eax 
			push dword ptr string("REMOTE_ADDR") 
			call SetEnvironmentVariable 
			
			lea eax, [remote_host] 
			push eax 
			push dword ptr string("REMOTE_HOST") 
			call SetEnvironmentVariable 
			
			; lea eax, [local_method] 
			; push eax 
			; push dword ptr string("REQUEST_METHOD") 
			; call SetEnvironmentVariable 
			
			push dword ptr offset request_uri 
			push dword ptr string("REQUEST_URI") 
			call SetEnvironmentVariable 
			
			push dword ptr offset script_name 
			push dword ptr string("SCRIPT_NAME") 
			call SetEnvironmentVariable 
			
			mov eax, string() 
			mov ebx, offset base_directory 
			call StringCopy 
			mov ebx, offset script_name 
			call StringCat 
			
			push eax 
			push dword ptr string("SCRIPT_FILENAME") 
			call SetEnvironmentVariable 
			
			push dword ptr string() 
			push dword ptr [thePort] 
			call i2str 
			push eax 
			push dword ptr string("SERVER_PORT") 
			call SetEnvironmentVariable 
			
			push dword ptr offset ApplicationVersion 
			push dword ptr string("SERVER_SOFTWARE") 
			call SetEnvironmentVariable 
			
			push dword ptr offset rBuffer 
			call get_english_word 
			push eax 
			push dword ptr string("REQUEST_METHOD") 
			call SetEnvironmentVariable 
			
			popa 
		ret 
		clr_env: 
			enter 0, 0 
			pusha 
			
			push dword ptr 0 
			push dword ptr string("DOCUMENT_ROOT") 
			call SetEnvironmentVariable 
			
			push dword ptr 0 
			push dword ptr string("HTTP_COOKIE") 
			call SetEnvironmentVariable 
			
			push dword ptr 0 
			push dword ptr string("HTTP_REFERER") 
			call SetEnvironmentVariable 
			
			push dword ptr 0 
			push dword ptr string("HTTP_REFERRER") 
			call SetEnvironmentVariable 
			
			push dword ptr 0 
			push dword ptr string("HTTP_USER_AGENT") 
			call SetEnvironmentVariable 
			
			push dword ptr 0 
			push dword ptr string("QUERY_STRING") 
			call SetEnvironmentVariable 
			
			push dword ptr 0 
			push dword ptr string("REMOTE_ADDR") 
			call SetEnvironmentVariable 
			
			push dword ptr 0 
			push dword ptr string("REMOTE_HOST") 
			call SetEnvironmentVariable 
			
			push dword ptr 0 
			push dword ptr string("REQUEST_METHOD") 
			call SetEnvironmentVariable 
			
			push dword ptr 0 
			push dword ptr string("REQUEST_URI") 
			call SetEnvironmentVariable 
			
			push dword ptr 0 
			push dword ptr string("SCRIPT_NAME") 
			call SetEnvironmentVariable 
			
			push dword ptr 0 
			push dword ptr string("SCRIPT_FILENAME") 
			call SetEnvironmentVariable 
			
			push dword ptr 0 
			push dword ptr string("SERVER_PORT") 
			call SetEnvironmentVariable 
			
			push dword ptr 0 
			push dword ptr string("SERVER_SOFTWARE") 
			call SetEnvironmentVariable 
			
			push dword ptr 0 
			push dword ptr string("CONTENT_LENGTH") 
			call SetEnvironmentVariable 
			
			push dword ptr 0 
			push dword ptr string("CONTENT_TYPE") 
			call SetEnvironmentVariable 
			
			push dword ptr 0 
			push dword ptr string("SERVER_PROTOCOL") 
			call SetEnvironmentVariable 
			
			push dword ptr 0 
			push dword ptr string("HTTP_FROM") 
			call SetEnvironmentVariable 
			
			push dword ptr 0 
			push dword ptr string("HTTP_ACCEPT") 
			call SetEnvironmentVariable 
			
			popa 
			leave 
		ret 
		
		
		send_the_data1: 
		
		push dword ptr 0 
		push dword ptr [hI] 
		call set_pointer 
		
		lea eax, [local_string1] 
		push dword ptr 0 
		push dword ptr integer() 
		push dword ptr 16 
		push eax 
		push dword ptr [hI] 
		call ReadFile 
		
		push dword ptr 0 
		push dword ptr [hI] 
		call set_pointer 
		
		lea ebx, [local_string1] 
		mov edx, ebx 
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
		mov byte ptr [ebx], 0 
		
		mov ebx, edx 
		
		@@: 
			mov al, byte ptr [ebx] 
			cmp al, 0 
			jz @F 
			call lc_al 
			mov byte ptr [ebx], al 
			inc ebx 
			jmp @B 
		@@: 
		
		mov ebx, edx 
		
		mov eax, string("put") 
		call simple_compare 
		cmp eax, 0 
		jz perform_put 
		
		mov eax, string("delete") 
		call simple_compare 
		cmp eax, 0 
		jz perform_delete 
		
		mov eax, string("head") 
		call simple_compare 
		cmp eax, 0 
		jz @F 
			mov dword ptr [send_body], 1 
		@@: 
		mov dword ptr [send_body], eax 
		
		push dword ptr string("No special method found; sending data. ", 13, 10) 
		call StdOut 
		
		jmp send_the_data 
		
		
		check_if_method_bad: 
		
		push dword ptr 0 
		push dword ptr [hI] 
		call set_pointer 
		
		lea eax, [local_string1] 
		push dword ptr 0 
		push dword ptr integer() 
		push dword ptr 16 
		push eax 
		push dword ptr [hI] 
		call ReadFile 
		
		push dword ptr 0 
		push dword ptr [hI] 
		call set_pointer 
		
		lea ebx, [local_string1] 
		mov edx, ebx 
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
		mov byte ptr [ebx], 0 
		
		mov ebx, edx 
		
		@@: 
			mov al, byte ptr [ebx] 
			cmp al, 0 
			jz @F 
			call lc_al 
			mov byte ptr [ebx], al 
			inc ebx 
			jmp @B 
		@@: 
		
		mov ebx, edx 
		
		mov eax, string("put") 
		call StringCompare 
		cmp eax, 0 
		jz err_405 
		
		mov eax, string("delete") 
		call StringCompare 
		cmp eax, 0 
		jz err_405 
		
		mov eax, string("head") 
		call StringCompare 
		cmp eax, 0 
		jz @F 
			mov eax, 1 
		@@: 
		mov dword ptr [send_body], eax 
		
		lea eax, [local_method] 
		call StringLength 
		cmp eax, 16 
		jnl err_400 
		
		lea eax, [local_method] 
		lea ebx, [local_string1] 
		call StringCopy 
		
		ret 
		
		
		
		
		direct_exec: 
		
		mov eax, offset exec_string 
		mov ebx, offset sBuffer 
		call StringCopy 
		
		direct_exec_lp1: 
			mov eax, offset exec_string 
			mov ebx, string(".exe") 
			call StringCat 
			
			push dword ptr 1 
			push dword ptr offset exec_string 
			push dword ptr offset sBuffer 
			call CopyFile 
			cmp eax, 0 
			jz direct_exec_lp1 
		
		mov eax, offset exec_string 
		mov ebx, string(32) 
		call StringCat 
		lea ebx, [remote_addr] 
		call StringCat 
		
		push dword ptr [hI] 
		push dword ptr STD_INPUT_HANDLE 
		call SetStdHandle 
		
		push dword ptr [hO] 
		push dword ptr STD_OUTPUT_HANDLE 
		call SetStdHandle 
		
		call set_env 
		
		push dword ptr [hO] 
		push dword ptr [hI] 
		push dword ptr offset exec_string 
			push dword ptr offset exec_string 
			call get_app 
			push eax 
		call app_start 
		cmp eax, 0 
		jz err_500 
		
		call clr_env 
		
		inc dword ptr [current_request] 
		
		mov dword ptr [local_point], eax 
		
		mov eax, edx 
		mov dword ptr [hO2], eax 
		
		push dword ptr [hStdI] 
		push dword ptr STD_INPUT_HANDLE 
		call SetStdHandle 
		
		push dword ptr [hStdO] 
		push dword ptr STD_OUTPUT_HANDLE 
		call SetStdHandle 
		
		push dword ptr offset exec_string 
		call get_app 
		mov ebx, eax 
		lea eax, [local_file_to_delete] 
		call StringCopy 
		
		mov dword ptr [fh1_close], 0 
		
		jmp send_the_data2 
		
		dos_exec: 
		
		mov eax, offset exec_string 
		mov ebx, offset sBuffer 
		call StringCopy 
		
		dos_exec_lp1: 
			mov eax, offset exec_string 
			mov ebx, string(".com") 
			call StringCat 
			
			push dword ptr 1 
			push dword ptr offset exec_string 
			push dword ptr offset sBuffer 
			call CopyFile 
			cmp eax, 0 
			jz dos_exec_lp1 
		
		mov eax, offset exec_string 
		mov ebx, string(32) 
		call StringCat 
		lea ebx, [remote_addr] 
		call StringCat 
		
		push dword ptr [hI] 
		push dword ptr STD_INPUT_HANDLE 
		call SetStdHandle 
		
		push dword ptr [hO] 
		push dword ptr STD_OUTPUT_HANDLE 
		call SetStdHandle 
		
		call set_env 
		
		push dword ptr [hO] 
		push dword ptr [hI] 
		push dword ptr offset exec_string 
			push dword ptr offset exec_string 
			call get_app 
			push eax 
		call app_start 
		cmp eax, 0 
		jz err_500 
		
		call clr_env 
		
		inc dword ptr [current_request] 
		
		mov dword ptr [local_point], eax 
		
		mov eax, edx 
		mov dword ptr [hO2], eax 
		
		push dword ptr [hStdI] 
		push dword ptr STD_INPUT_HANDLE 
		call SetStdHandle 
		
		push dword ptr [hStdO] 
		push dword ptr STD_OUTPUT_HANDLE 
		call SetStdHandle 
		
		push dword ptr offset exec_string 
		call get_app 
		mov ebx, eax 
		lea eax, [local_file_to_delete] 
		call StringCopy 
		
		mov dword ptr [fh1_close], 0 
		
		jmp send_the_data2 
		
		
		send_the_data: 
		
		invoke OpenFile, offset sBuffer, space(SIZEOF OFSTRUCT), 0 
		push eax 
		invoke GetFileSize, eax, 0 
		mov dword ptr [bR], eax 
		pop eax 
		invoke CloseHandle, eax 
		
		push dword ptr offset string1 
		push dword ptr [bR] 
		call i2str 
		
		invoke StdOut, string("Send queue:    ") 
		invoke StdOut, offset string1 
		invoke StdOut, string("    bytes  ", 13, 10) 
		
		invoke OpenFile, offset sBuffer, space(SIZEOF OFSTRUCT), 0 
		mov dword ptr [fh1], eax 
		mov dword ptr [fh1_close], eax 
		
		mov ebx, string("HTTP/1.0 200 OK", 13, 10, "Content-Length: ") 
		mov eax, ebx 
		call StringLength 
		
		push dword ptr 0 
		push eax 
		push ebx 
		push dword ptr [sock1] 
		call send 
		
		mov ebx, offset string1 
		mov eax, ebx 
		call StringLength 
		
		push dword ptr 0 
		push eax 
		push ebx 
		push dword ptr [sock1] 
		call send 
		
		mov ebx, string(13, 10, 13, 10) 
		mov eax, ebx 
		call StringLength 
		
		push dword ptr 0 
		push eax 
		push ebx 
		push dword ptr [sock1] 
		call send 
		
		inc dword ptr [current_request] 
		
		cmp dword ptr [send_body], 0 
		jnz lp001a1s2 
		
		mov dword ptr [local_point], 0 
		
		jmp send_the_data2_cont 
		
		send_the_data2: 
		
		mov eax, dword ptr [hO2] 
		mov dword ptr [fh1], eax 
		
		lea eax, [local_string1] 
		lea ebx, [bR] 
		push dword ptr 0 
		push dword ptr ebx 
		push dword ptr 5 
		push dword ptr eax 
		push dword ptr [fh1] 
		call ReadFile 
		
		lea ebx, [local_string1] 
		mov byte ptr [ebx+5], 0 
		
		mov eax, string("HTTP", 47) 
		call simple_compare 
			mov ebx, string("HTTP/1.0 200 OK", 13, 10) 
		mov dword ptr [bSent], 0 
		cmp eax, 0 
		jz @F 
			
			mov eax, ebx 
			call StringLength 
			
			mov dword ptr [bSent], eax 
			
			push dword ptr 0 
			push eax 
			push ebx 
			push dword ptr [sock1] 
			call send 
			cmp eax, SOCKET_ERROR 
			jz lp07s 
		@@: 
		
		lea ebx, [local_string1] 
		push dword ptr 0 
		push dword ptr [bR] 
		push ebx 
		push dword ptr [sock1] 
		call send 
		cmp eax, SOCKET_ERROR 
		jz lp07s 
		
		send_the_data2_cont: 
		
		call GetSysTimeString 
		push eax 
		call ServerB_log 
		
		push dword ptr string(9) 
		call ServerB_log 
		
		lea eax, [local_string1] 
		push eax 
		push dword ptr [rN] 
		call i2str 
		
		push eax 
		call ServerB_log 
		
		push dword ptr string(9) 
		call ServerB_log 
		
		push dword ptr string("Send queue: ") 
		call ServerB_log 
		
		lea eax, [local_string1] 
		push eax 
		push dword ptr [bR] 
		call i2str 
		
		; push eax 
		push dword ptr string("unknown") 
		call ServerB_log 
		
		push dword ptr string("; sending data...  ", 13, 10) 
		call ServerB_log 
		
		
		mov eax, dword ptr [bR] 
		add dword ptr [bSent], eax 
		
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;; Sending Data ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		
		;; And waiting for the application to finish. 
		lp07: 
			push dword ptr VK_ESCAPE 
			call GetKeyState 
			mov ebx, string("Escape key pressed; cancelling request service. ", 13, 10) 
			mov ecx, eax 
			xor eax, eax 
			inc eax 
			shl eax, 15 
			test eax, ecx 
			jz @F 
				push ebx 
				call StdOut 
				jmp lp07s 
			@@: 
			
			lp001a1: 
				push dword ptr VK_ESCAPE 
				call GetKeyState 
				mov ebx, string("Escape key pressed; cancelling request service. ", 13, 10) 
				mov ecx, eax 
				xor eax, eax 
				inc eax 
				shl eax, 15 
				test eax, ecx 
				jz @F 
					push ebx 
					call StdOut 
					jmp lp07s 
				@@: 
				
				lea ebx, [local_buffer] 
				lea ecx, [bR] 
				invoke ReadFile, [fh1], ebx, 4096, ecx, 0 
				; cmp dword ptr [bR], 0 
				; jz lp001a1s 
				
				lea ebx, [local_buffer] 
				push dword ptr 0 
				push dword ptr [bR] 
				push dword ptr ebx 
				push dword ptr [sock1] 
				call send 
				;invoke send, [sock1], [ebp-8], ecx, 0 
				add dword ptr [bSent], eax 
				
				cmp eax, SOCKET_ERROR 
				jz h_err1 
				
				cmp dword ptr [bR], 0 
				jz lp001a1s 
				
				lea ebx, [local_string1] 
				push ebx 
				push dword ptr [bSent] 
				call i2str 
				invoke StdOut, string(13, "Sent           ") 
				lea ebx, [local_string1] 
				invoke StdOut, ebx 
				invoke StdOut, string("    bytes ") 
				
				jmp lp001a1 
			lp001a1s: 
			
			mov eax, dword ptr [local_point] 
			cmp eax, 0 
			jz lp07s 
			
			mov ebx, eax 
			add ebx, SIZEOF STARTUPINFO 
			mov eax, dword ptr [ebx+00] 
			
			lea ebx, [pExit] 
			push ebx 
			push eax 
			call GetExitCodeProcess 
			cmp eax, 0 
			jz lp07s 
			
			mov eax, dword ptr [pExit] 
			cmp eax, STILL_ACTIVE 
			jnz lp07s 
			
			jmp lp07 
		lp07s: 
		
		mov eax, dword ptr [local_point] 
		cmp eax, 0 
		jz @F 
			mov ebx, eax 
			add ebx, SIZEOF STARTUPINFO 
			mov eax, dword ptr [ebx+00] 
			
			push dword ptr 0 
			push eax 
			call TerminateProcess 
		@@: 
		
		call clean_up_files 
		
		push dword ptr [local_point] 
		call GlobalFree 
		mov dword ptr [local_point], 0 
		
		jmp lp001a1s2 
		
		
		clean_up_files: 
		
		;; Clean up the files. 
		
		push dword ptr [fh1_close] 
		call CloseHandle 
		
		push dword ptr [hI] 
		call CloseHandle 
		
		push dword ptr [hO] 
		call CloseHandle 
		
		push dword ptr [hO2] 
		call CloseHandle 
		
		;jmp do_not_delete_files_for_now 
		
		push dword ptr string("Not deleting files, for now. ") 
		call StdOut 
		
		lea ebx, [local_string1] 
		push ebx 
		push dword ptr [rN] 
		call i2str 
		mov edx, eax 
		
		mov eax, string() 
		mov ebx, string("serverB_input_") 
		call StringCopy 
		mov ebx, edx 
		call StringCat 
		mov ebx, string(".txt") 
		call StringCat 
		push eax 
		call DeleteFile 
		
		lea ebx, [local_string1] 
		push ebx 
		push dword ptr [rN] 
		call i2str 
		mov edx, eax 
		
		mov eax, string() 
		mov ebx, string("serverB_output_") 
		call StringCopy 
		mov ebx, edx 
		call StringCat 
		mov ebx, string(".txt") 
		call StringCat 
		push eax 
		call DeleteFile 
		
		do_not_delete_files_for_now: 
		
		lea eax, [local_file_to_delete] 
		push eax 
		call DeleteFile 
		cmp eax, 0 
		jnz @F 
			mov eax, dword ptr [local_point] 
			cmp eax, 0 
			jz @F 
			mov ebx, eax 
			mov eax, dword ptr [ebx+SIZEOF STARTUPINFO] 
			push dword ptr 0 
			push eax 
			call TerminateProcess 
			lea eax, [local_file_to_delete] 
			push eax 
			call DeleteFile 
			cmp eax, 0 
			jnz @F 
				push dword ptr offset could_not_delete_exec 
				call ServerB_log 
				lea eax, [local_file_to_delete] 
				push eax 
				call ServerB_log 
				push dword ptr offset nl 
				call ServerB_log 
				
				lea eax, [local_file_to_delete] 
				push eax 
				call to_be_deleted 
		@@: 
		
		ret 
		
		lp001a1s2: 
		
		
		invoke StdOut, string(13, 10) 
		
		invoke StdOut, string(9, "Data sent. ", 13, 10) 
		
		
		call GetSysTimeString 
		push eax 
		call ServerB_log 
		push dword ptr string(9) 
		call ServerB_log 
		lea ebx, [local_string1] 
		push ebx 
		push dword ptr [rN] 
		call i2str 
		push eax 
		call ServerB_log 
		push dword ptr string(9, "Data sent. ", 40) 
		call ServerB_log 
		lea ebx, [local_string1] 
		push ebx 
		push dword ptr [bSent] 
		call i2str 
		push eax 
		call ServerB_log 
		push dword ptr string(" bytes", 41, 13, 10) 
		call ServerB_log 
		
		
		jmp continue00101 
		
		
		perform_put: 
			
			call put_delete_prepare 
			
			mov eax, ebx 
			mov dword ptr [local_point], eax 
			
			pusha 
				push dword ptr string("Putting file ") 
				call StdOut 
			popa 
			pusha 
				push ebx 
				call StdOut 
				push dword ptr string(13, 10) 
				call StdOut 
				
				push dword ptr [fh1_close] 
				call CloseHandle 
			popa 
			
			push dword ptr 0 
			push dword ptr 128 
			push dword ptr 2 
			push dword ptr 0 
			push dword ptr 1 or 2 or 4 
			push dword ptr GENERIC_READ or GENERIC_WRITE 
			push ebx 
			call CreateFile 
			cmp eax, 0 
			jz err_500 
			cmp eax, -1 
			jz err_500 
			mov dword ptr [fh1], eax 
			mov dword ptr [fh1_close], eax 
			
			mov ebx, string("file:") 
			mov eax, ebx 
			call StringLength 
			push dword ptr 0 
			push dword ptr integer() 
			push eax 
			push ebx 
			push dword ptr [fh1] 
			call WriteFile 
			
			mov dword ptr [local_count], 0 
			
			put_lp1: 
				cmp dword ptr [local_count], 2 
				jnl put_lp1s 
				
				mov ecx, integer() 
				push ecx 
				lea eax, [local_string1] 
				push dword ptr 0 
				push ecx 
				push dword ptr 1 
				push eax 
				push dword ptr [hI] 
				call ReadFile 
				pop ecx 
				
				lea ebx, [local_string1] 
				mov al, byte ptr [ebx] 
				cmp al, 10 
				jnz @F 
				inc dword ptr [local_count] 
				jmp put_lp1 
				@@: 
					cmp al, 13 
					jz @F 
					mov dword ptr [local_count], 0 
					mov ebx, ecx 
					mov eax, dword ptr [ebx] 
					cmp eax, 0 
					jz err_400 
				jmp put_lp1 
				@@: jmp put_lp1 
			put_lp1s: 
			
			put_lp2: 
				
				lea eax, [local_count] 
				lea ebx, [local_buffer] 
				push dword ptr 0 
				push eax 
				push dword ptr 4096 
				push ebx 
				push dword ptr [hI] 
				call ReadFile 
				
				mov eax, dword ptr [local_count] 
				cmp eax, 0 
				jz put_lp2s 
				
				lea ebx, [local_buffer] 
				push dword ptr 0 
				push dword ptr integer() 
				push dword ptr [local_count] 
				push ebx 
				push dword ptr [fh1] 
				call WriteFile 
				
				jmp put_lp2 
			put_lp2s: 
			
			call GetLastError 
			push dword ptr string() 
			push eax 
			call i2str 
			push eax 
			push dword ptr string("Last Error: ") 
			call StdOut 
			call StdOut 
			push dword ptr string(13, 10) 
			call StdOut 
			
			mov eax, string("HTTP/1.0 200 OK", 13, 10, "Content-Type: text/plain", 13, 10, "Content-Length: ") 
			mov ebx, eax 
			call StringLength 
			push dword ptr 0 
			push eax 
			push ebx 
			push dword ptr [sock1] 
			call send 
			
			mov eax, string() 
			mov ebx, string("Success! The file ") 
			call StringCopy 
			xchg eax, ebx 
			mov eax, dword ptr [local_point] 
			xchg eax, ebx 
			call StringCat 
			mov ebx, string(" has been PUT. ", 13, 10) 
			call StringCat 
			
			mov dword ptr [local_count], eax 
			
			call StringLength 
			push dword ptr string() 
			push eax 
			call i2str 
			mov ebx, eax 
			call StringLength 
			push dword ptr 0 
			push eax 
			push ebx 
			push dword ptr [sock1] 
			call send 
			
			mov ebx, string(13, 10, "Server: ") 
			mov eax, ebx 
			call StringLength 
			push dword ptr 0 
			push eax 
			push ebx 
			push dword ptr [sock1] 
			call send 
			
			mov ebx, offset ApplicationVersion 
			mov eax, ebx 
			call StringLength 
			push dword ptr 0 
			push eax 
			push ebx 
			push dword ptr [sock1] 
			call send 
			
			mov ebx, string(13, 10, 13, 10) 
			mov eax, ebx 
			call StringLength 
			push dword ptr 0 
			push eax 
			push ebx 
			push dword ptr [sock1] 
			call send 
			
			mov eax, dword ptr [local_count] 
			
			mov ebx, eax 
			call StringLength 
			push dword ptr 0 
			push eax 
			push ebx 
			push dword ptr [sock1] 
			call send 
			
			mov dword ptr [local_point], 0 
			
		jmp lp001a1s 
		perform_delete: 
			
			call put_delete_prepare 
			
			mov eax, ebx 
			mov dword ptr [local_count], eax 
			
			pusha 
				push dword ptr string("Deleting file ") 
				call StdOut 
			popa 
			pusha 
				push dword ptr [local_count] 
				call StdOut 
				push dword ptr string(13, 10) 
				call StdOut 
			popa 
			
			push dword ptr [local_count] 
			call DeleteFile 
			
			mov ebx, string("HTTP/1.0 200 OK", 13, 10, "Content-Type: text/plain", 13, 10, "Content-Length: ") 
			mov eax, ebx 
			call StringLength 
			push dword ptr 0 
			push eax 
			push ebx 
			push dword ptr [sock1] 
			call send 
			
			lea eax, [local_buffer] 
			mov ebx, string("Success! The file ") 
			call StringCopy 
			mov ebx, dword ptr [local_count] 
			call StringCat 
			mov ebx, string(" was deleted. ", 13, 10) 
			call StringCat 
			
			pusha 
				push eax 
				call StdOut 
			popa 
			
			call StringLength 
			lea ebx, [local_string1] 
			push ebx 
			push eax 
			call i2str 
			mov ebx, eax 
			call StringLength 
			push dword ptr 0 
			push eax 
			push ebx 
			push dword ptr [sock1] 
			call send 
			
			mov ebx, string(13, 10, "Server: ") 
			mov eax, ebx 
			call StringLength 
			push dword ptr 0 
			push eax 
			push ebx 
			push dword ptr [sock1] 
			call send 
			
			mov ebx, offset ApplicationVersion 
			mov eax, ebx 
			call StringLength 
			push dword ptr 0 
			push eax 
			push ebx 
			push dword ptr [sock1] 
			call send 
			
			mov ebx, string(13, 10, 13, 10) 
			mov eax, ebx 
			call StringLength 
			push dword ptr 0 
			push eax 
			push ebx 
			push dword ptr [sock1] 
			call send 
			
			lea ebx, [local_buffer] 
			mov eax, ebx 
			call StringLength 
			push dword ptr 0 
			push eax 
			push ebx 
			push dword ptr [sock1] 
			call send 
			
		jmp lp001a1s 
		
		put_delete_prepare: 
			
			push dword ptr 0 
			push dword ptr [hI] 
			call set_pointer 
			
			mov ecx, integer() 
			
			@@: 
			push ecx 
			lea eax, [local_string1] 
			push dword ptr 0 
			push ecx 
			push dword ptr 1 
			push eax 
			push dword ptr [hI] 
			call ReadFile 
			pop ecx 
			
			lea ebx, [local_string1] 
			mov al, byte ptr [ebx] 
			cmp al, 32 
			jz @F 
			cmp al, 9 
			jz @F 
			jmp @B 
			@@: 
			
			lea eax, [local_string1] 
			push dword ptr 0 
			push dword ptr integer() 
			push dword ptr 510 
			push eax 
			push dword ptr [hI] 
			call ReadFile 
			
			push dword ptr 0 
			push dword ptr [hI] 
			call set_pointer 
			
			lea ebx, [local_string1] 
			
			mov edx, ebx 
			
			@@: 
				mov al, byte ptr [ebx] 
				inc ebx 
				cmp al, 32 
				jz @B 
				cmp al, 9 
				jz @B 
			@@: 
			
			dec ebx 
			
			mov edx, ebx 
			
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
			
			mov byte ptr [ebx], 0 
			
			mov eax, string() 
			mov ebx, offset base_directory 
			call StringCopy 
			mov ebx, edx 
			call StringCat 
			
			mov ebx, eax 
			
		ret 
		
		
		
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;                                                                    ;;;;; 
		;;;;;;;  ||||||||                                                  |||||   ;;;;; 
		;;;;;;;  ||          ||  ||||   ||  ||||      ||||     ||  ||||   ||   ||  ;;;;; 
		;;;;;;;  ||          || ||  ||  || ||  ||    ||  ||    || ||  ||  ||       ;;;;; 
		;;;;;;;  ||||||||    ||||   ||  ||||   ||    ||  ||    ||||   ||   |||||   ;;;;; 
		;;;;;;;  ||          |||        |||          ||  ||    |||             ||  ;;;;; 
		;;;;;;;  ||          ||         ||           ||  ||    ||         ||   ||  ;;;;; 
		;;;;;;;  ||||||||    ||         ||            ||||     ||          |||||   ;;;;; 
		;;;;;;;                                                                    ;;;;; 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;;;;;; HTTP Errors   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
		
		err_400: 
			mov ebx, string("HTTP/1.0 400 Bad Request", 13, 10, "Content-Type: text/plain", 13, 10, "Content-Length: 50", 13, 10, 13, 10) 
			mov eax, ebx 
			call StringLength 
			push dword ptr 0 
			push eax 
			push ebx 
			push dword ptr [sock1] 
			call send 
			
			mov ebx, string("Error 400:  Your client has issued a bad request. ") 
			mov eax, ebx 
			call StringLength 
			push dword ptr 0 
			push eax 
			push ebx 
			push dword ptr [sock1] 
			call send 
			
		jmp lp001a1s 
		err_404: 
			lea ebx, [method] 
			@@: 
				mov al, byte ptr [ebx] 
				cmp al, 0 
				jz @F 
				call lc_al 
				mov byte ptr [ebx], al 
				inc ebx 
				jmp @B 
			@@: 
			
			lea eax, [method] 
			mov ebx, string("put") 
			call simple_compare 
			cmp eax, 0 
			jz send_the_data1 
			
			push dword ptr string("HTTP/1.0 404 Not Found", 13, 10) 
			call StdOut 
			
			mov ebx, string("HTTP/1.0 404 Not Found", 13, 10, "Content-Type: text/plain", 13, 10, "Content-Length: 28", 13, 10, 13, 10) 
			mov eax, ebx 
			call StringLength 
			push dword ptr 0 
			push eax 
			push ebx 
			push dword ptr [sock1] 
			call send 
			
			mov ebx, string("Error 404:  File Not Found. ") 
			mov eax, ebx 
			call StringLength 
			push dword ptr 0 
			push eax 
			push ebx 
			push dword ptr [sock1] 
			call send 
			
		jmp lp001a1s 
		err_405: 
			mov ebx, string("HTTP/1.0 405 Forbidden", 13, 10, "Content-Type: text/plain", 13, 10, "Content-Length: 32", 13, 10, 13, 10) 
			mov eax, ebx 
			call StringLength 
			push dword ptr 0 
			push eax 
			push ebx 
			push dword ptr [sock1] 
			call send 
			
			mov ebx, string("Error 405:  Action Not Allowed. ") 
			mov eax, ebx 
			call StringLength 
			push dword ptr 0 
			push eax 
			push ebx 
			push dword ptr [sock1] 
			call send 
			
		jmp lp001a1s 
		err_411: 
			mov ebx, string("HTTP/1.0 200 Length Required", 13, 10, "Content-Type: text/plain", 13, 10, "Content-Length: 29", 13, 10, 13, 10) 
			mov eax, ebx 
			call StringLength 
			push dword ptr 0 
			push eax 
			push ebx 
			push dword ptr [sock1] 
			call send 
			
			mov ebx, string("Error 411:  Length Required. ") 
			mov eax, ebx 
			call StringLength 
			push dword ptr 0 
			push eax 
			push ebx 
			push dword ptr [sock1] 
			call send 
			
		jmp lp001a1s 
		err_500: 
			call GetLastError 
			push dword ptr string() 
			push eax 
			call i2str 
			push eax 
			push dword ptr string("Windows System Error Code: ") 
			call StdOut 
			call StdOut 
			push dword ptr string(13, 10) 
			call StdOut 
			
			mov ebx, string("HTTP/1.0 500 Internal Server Error", 13, 10, "Content-Type: text/plain", 13, 10, "Content-Length: 35", 13, 10, 13, 10) 
			mov eax, ebx 
			call StringLength 
			push dword ptr 0 
			push eax 
			push ebx 
			push dword ptr [sock1] 
			call send 
			
			mov ebx, string("Error 500:  Internal Server Error. ") 
			mov eax, ebx 
			call StringLength 
			push dword ptr 0 
			push eax 
			push ebx 
			push dword ptr [sock1] 
			call send 
			
		jmp lp001a1s 
		
		
		block_1: 
			invoke StdOut, string(9, "Service blocked. ", 13, 10) 
			
		continue00101: 
		
		invoke StdOut, string(9, "Finished servicing request. ", 13, 10) 
		
		;; Clean up the network. 
		
		push dword ptr SD_BOTH 
		push dword ptr [sock1] 
		call shutdown 
		
		push dword ptr [sock1] 
		call closesocket 
		
		mov dword ptr [bSent], 0 
		
		call GetSysTimeString 
		push eax 
		call ServerB_log 
		push dword ptr string(9) 
		call ServerB_log 
		lea ebx, [local_string1] 
		push ebx 
		push dword ptr [rN] 
		call i2str 
		push eax 
		call ServerB_log 
		push dword ptr string(9, "Finished servicing request. ", 13, 10) 
		call ServerB_log 
		
		mov eax, dword ptr [current_request] 
		cmp eax, dword ptr [rN] 
		jg @F 
			
			mov eax, dword ptr [rN] 
			inc eax 
			mov dword ptr [current_request], eax 
			
		@@: 
		
	leave 
	
	invoke ExitThread, 0 
	
	ret 
;; .....  


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;           ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;           ;;;;;;;; FINISH! ;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;           ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;           ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 

_wait: 
	enter 12, 0 
	pushad 
	mov dword ptr [ebp-4], 0 
	mov dword ptr [ebp-8], eax 
	_wait_lp1: 
		mov eax, dword ptr [ebp-8] 
		cmp dword ptr [ebp-4], eax 
		jz _wait_lp1s 
		
		invoke GetLocalTime, offset time 
		xor eax, eax 
		mov ebx, offset time 
		mov ax, word ptr [ebx+14] 
		mov dword ptr [ebp-12], eax 
		_wait_lp2: 
			invoke GetLocalTime, offset time 
			xor eax, eax 
			mov ebx, offset time 
			mov ax, word ptr [ebx+14] 
			cmp eax, dword ptr [ebp-12] 
			jnz _wait_lp2s 
			jmp _wait_lp2 
		_wait_lp2s: 
		
		inc dword ptr [ebp-4] 
		
		jmp _wait_lp1 
	_wait_lp1s: 
	
	popad 
	leave 
	ret 
;; endp 

GetSysTimeString proc 
	push ebp 
	mov ebp, esp 
	sub esp, 512 + SIZEOF SYSTEMTIME 
	
	time01                                equ  ebp - (512 + SIZEOF SYSTEMTIME) 
	
	lea eax, [ebp-512] 
	mov ebx, string(0) 
	call StringCopy 
	
	lea eax, [time01] 
	push eax 
	call GetSystemTime 
	
	
	;; The day of week. 
	lea ebx, [time01] 
	xor eax, eax 
	mov ax, word ptr [ebx+4] 
	
	mov ebx, string("Sun", 0, "Mon", 0, "Tue", 0, "Wed", 0, "Thu", 0, "Fri", 0, "Sat", 0) 
	
	mov cx, 4 
	mul cx 
	add ebx, eax 
	
	lea eax, [ebp-512] 
	
	call StringCat 
	
	mov ebx, string(44, 32) 
	call StringCat 
	
	
	;; The day of month. 
	lea ebx, [ebp-512] 
	mov eax, ebx 
	call StringLength 
	add ebx, eax 
	mov edx, ebx 
	
	xor eax, eax 
	lea ebx, [time01] 
	mov ax, word ptr [ebx+6] 
	
	push edx 
	push eax 
	call i2str 
	
	push eax 
	call check_number_1 
	
	lea eax, [ebp-512] 
	mov ebx, string(32) 
	call StringCat 
	
	
	;; The month. 
	xor eax, eax 
	lea ebx, [time01] 
	mov ax, word ptr [ebx+2] 
	
	dec ax   ;; The month origin is at 1. We decrement the number to lower the origin to 0. 
	
	mov ebx, string("Jan", 0, "Feb", 0, "Mar", 0, "Apr", 0, "May", 0, "Jun", 0, "Jul", 0, "Aug", 0, "Sep", 0, "Oct", 0, "Nov", 0, "Dec", 0) 
	
	mov cx, 4 
	mul cx 
	add ebx, eax 
	lea eax, [ebp-512] 
	call StringCat 
	
	mov ebx, string(32) 
	call StringCat 
	
	
	;; The year. 
	lea ebx, [ebp-512] 
	mov eax, ebx 
	call StringLength 
	add eax, ebx 
	mov edx, eax 
	
	xor eax, eax 
	lea ebx, [time01] 
	mov ax, word ptr [ebx+0] 
	
	push edx 
	push eax 
	call i2str 
	
	lea eax, [ebp-512] 
	mov ebx, string(32) 
	call StringCat 
	
	
	;; The hour. 
	lea eax, [ebp-512] 
	mov ebx, eax 
	call StringLength 
	add eax, ebx 
	mov edx, eax 
	
	xor eax, eax 
	lea ebx, [time01] 
	mov ax, word ptr [ebx+8] 
	
	push edx 
	push eax 
	call i2str 
	
	push eax 
	call check_number_1 
	
	lea eax, [ebp-512] 
	mov ebx, string(58) 
	call StringCat 
	
	
	;; The minute. 
	lea eax, [ebp-512] 
	mov ebx, eax 
	call StringLength 
	add eax, ebx 
	mov edx, eax 
	
	xor eax, eax 
	lea ebx, [time01] 
	mov ax, word ptr [ebx+10] 
	
	push edx 
	push eax 
	call i2str 
	
	push eax 
	call check_number_1 
	
	lea eax, [ebp-512] 
	mov ebx, string(58) 
	call StringCat 
	
	
	;; The second. 
	lea eax, [ebp-512] 
	mov ebx, eax 
	call StringLength 
	add eax, ebx 
	mov edx, eax 
	
	xor eax, eax 
	lea ebx, [time01] 
	mov ax, word ptr [ebx+12] 
	
	push edx 
	push eax 
	call i2str 
	
	push eax 
	call check_number_1 
	
	lea eax, [ebp-512] 
	mov ebx, string(32) 
	call StringCat 
	
	
	mov ebx, string("GMT") 
	call StringCat 
	
	
	mov ebx, eax 
	mov eax, offset time_string_1 
	call StringCopy 
	
	
	mov esp, ebp 
	pop ebp 
	ret 
	check_number_1: 
		ret 4 
		mov eax, dword ptr [esp+4] 
		mov ebx, eax 
		call StringLength 
		cmp eax, 2 
		jl @F 
			xor eax, eax 
			
			ret 4 
		@@: 
		
		mov eax, ebx 
		mov ebx, string(48) 
		call SquishString 
		
		push eax 
		call check_number_1 
		
		ret 4 
GetSysTimeString endp 

app_log proc 
	push ebp 
	mov ebp, esp 
	sub esp, 8 
	pusha 
	
	mov eax, dword ptr [hLog] 
	mov dword ptr [ebp-4], eax 
	cmp eax, 0 
	jnz continue001 
	
	push dword ptr 2 
	push dword ptr space(SIZEOF OFSTRUCT) 
	push dword ptr offset log_filename 
	call OpenFile 
	mov dword ptr [ebp-4], eax 
	
	cmp eax, 0 
	jnz continue001 
	
	push dword ptr 2 or 1000h 
	push dword ptr space(SIZEOF OFSTRUCT) 
	push dword ptr offset log_filename 
	call OpenFile 
	mov dword ptr [ebp-4], eax 
	
	cmp eax, 0 
	jz app_log_err 
	
	continue001: 
	
	push dword ptr FILE_END 
	push dword ptr 0 
	push dword ptr 0 
	push dword ptr [ebp-4] 
	call SetFilePointer 
	
	mov eax, dword ptr [ebp+8] 
	call StringLength 
	mov ecx, eax 
	push eax  ;; save len 
	
	lea eax, [ebp-8] 
	push dword ptr 0 
	push eax 
	push ecx 
	push dword ptr [ebp+8] 
	push dword ptr [ebp-4] 
	call WriteFile 
	cmp eax, 0 
	jz app_log_err 
	
	cmp dword ptr [hLog], 0 
	jnz @F 
	
	push dword ptr [ebp-4] 
	call CloseHandle 
	
	@@: 
	
	pop eax  ;; load len 
	cmp eax, dword ptr [ebp-8] 
	jnz app_log_err 
	
	popa 
	xor eax, eax 
	leave 
	ret 4 
	
	app_log_err: 
	popa 
	call GetLastError 
	leave 
	ret 
app_log endp 

lc_al proc 
	
	cmp al, 64 
	jng @F 
	
	cmp al, 90 
	jg @F 
	
	add al, 32 
	
	@@: 
	
	ret 
lc_al endp 

set_pointer proc  ;; params:  hFile:HANDLE, iPtr:DWORD 
	push ebp 
	mov ebp, esp 
	
	push dword ptr 0 
	push dword ptr 0 
	push dword ptr [ebp+12] 
	push dword ptr [ebp+8] 
	call SetFilePointer 
	
	mov esp, ebp 
	pop ebp 
	ret 8 
set_pointer endp 

simple_compare proc 
	enter 4, 0 
	pusha 
		
		mov edx, ebx 
		mov ebx, eax 
		
		xor eax, eax 
		inc eax 
		
		@@: 
			call put_eax 
			mov al, byte ptr [ebx] 
			xchg ebx, edx 
			mov ah, byte ptr [ebx] 
			xchg ebx, edx 
			inc ebx 
			inc edx 
			cmp al, 0 
			jz @F 
			cmp ah, 0 
			jz @F 
			sub al, ah 
			jnz @F 
			and ah, 0 
			jmp @B 
		@@: 
		mov dword ptr [ebp-4], eax 
		
	popa 
	mov eax, dword ptr [ebp-4] 
	leave 
	
	jmp finishf 
	
	finishf: 
	
	ret 
simple_compare endp 

put_eax: ret 
	pusha 
		push dword ptr string() 
		push eax 
		call i2str 
		push eax 
		call StdOut 
		push dword ptr string(13, 10) 
		call StdOut 
	popa 
	ret 
;; endp 

;; app_start() - params: exec_filename, command_line, h_input, h_output 
app_start: 
	;; The '     + 4' is sort of extra; it's referenced as [ebp-(28+24+12)-4] and used for 
	;; the offset of the start of the request body. 
	enter 28 + 24 + 12     + 4, 0 
	push esi 
	
	; push dword ptr 0 
	; push dword ptr integer() 
	; push dword ptr SIZEOF eBuffer - 1 
	; push dword ptr offset eBuffer 
	; push dword ptr [ebp+16] 
	; call ReadFile 
	; mov ebx, integer() 
	; mov eax, dword ptr [ebx-4] 
	; mov ebx, offset eBuffer 
	; add ebx, eax 
	; mov byte ptr [ebx], 0 
	
	; push dword ptr 0 
	; push dword ptr [ebp+16] 
	; call set_pointer 
	
	; push dword ptr 0 
	; push dword ptr offset ApplicationName 
	; push dword ptr offset eBuffer 
	; push dword ptr 0 
	; call MessageBoxA 
	
	;; Find the offset of the request body start. 
		push dword ptr 0 
		push dword ptr [ebp+16] 
		call set_pointer 
		
		mov dword ptr [ebp-(28+24+12)-4], 0 
		
		;; esp -= 4 
		;; [esp]= the character 
		push dword ptr 0 
		
		xor esi, esi 
		app_start_lp1A: 
			jmp @F 
				app_start_lp1Ar: 
				cmp byte ptr [esp], 13 
				jz @F 
				xor esi, esi 
			@@: 
			mov eax, esp 
			push dword ptr 0 
			push dword ptr integer() 
			push dword ptr 1 
			push dword ptr eax 
			push dword ptr [ebp+16] 
			call ReadFile 
			
			mov ebx, integer() 
			cmp dword ptr [ebx-4], 0 
			jz app_start_lp1As 
			
			inc dword ptr [ebp-(28+24+12)-4] 
			
			cmp byte ptr [esp], 10 
			jnz app_start_lp1Ar 
			
			inc esi 
			
			cmp esi, 2 
			jnl app_start_lp1As 
			
			jmp app_start_lp1A 
		app_start_lp1As: 
		add esp, 4 
	;; .....  
	
	mov eax, offset base_directory 
	call StringLength 
	add eax, 16 
	push eax 
	push dword ptr 0 
	call GlobalAlloc 
	mov dword ptr [ebp-8], eax 
	
	mov ebx, string("C:") 
	call StringCopy 
	mov ebx, offset base_directory 
	call StringCat 
	mov dword ptr [ebp-8], eax 
	
	lea ebx, [ebp-(28+24)] 
	mov dword ptr [ebx+00], 12 
	mov dword ptr [ebx+04], 0 
	mov dword ptr [ebx+08], 1 
	mov dword ptr [ebx+12], 12 
	mov dword ptr [ebx+16], 0 
	mov dword ptr [ebx+20], 1 
	
	mov eax, dword ptr [ebp+16] 
	push dword ptr 0 
	push eax 
	call GetFileSize 
	cmp eax, -1 
	jnz @F 
		xor eax, eax 
	@@: 
	pusha 
		push dword ptr string("Standard Input Pipe Size: ") 
		call ServerB_log 
	popa 
	pusha 
		sub eax, dword ptr [ebp-(28+24+12)-4] 
		push dword ptr string() 
		push eax 
		call i2str 
		push eax 
		call ServerB_log 
		push dword ptr string(13, 10) 
		call ServerB_log 
	popa 
	inc eax 
	xor eax, eax 
	push eax 
	lea eax, [ebp-(28+24)+00] 
	push eax 
	lea eax, [ebp-28+04] 
	push eax 
	lea eax, [ebp-28+00] 
	push eax 
	call CreatePipe 
	cmp eax, 0 
	jz app_start_err 
	cmp eax, -1 
	jz app_start_err 
	
	push dword ptr 0 
	push dword ptr HANDLE_FLAG_INHERIT 
	push dword ptr [ebp-28+04] 
	call SetHandleInformation 
	
	push dword ptr 0 
	lea eax, [ebp-(28+24)+12] 
	push eax 
	lea eax, [ebp-28+12] 
	push eax 
	lea eax, [ebp-28+08] 
	push eax 
	call CreatePipe 
	cmp eax, 0 
	jz app_start_err 
	cmp eax, -1 
	jz app_start_err 
	
	push dword ptr 0 
	push dword ptr HANDLE_FLAG_INHERIT 
	push dword ptr [ebp-28+08] 
	call SetHandleInformation 
	
	push dword ptr string("Standard Input Handle For Child Process: ") 
	call ServerB_log 
	mov eax, dword ptr [ebp-28+00] 
	push dword ptr string() 
	push eax 
	call i2str 
	push eax 
	call ServerB_log 
	push dword ptr string(13, 10) 
	call ServerB_log 
	
	push dword ptr string("Standard Output Handle For Child Process: ") 
	call ServerB_log 
	mov eax, dword ptr [ebp-28+12] 
	push dword ptr string() 
	push eax 
	call i2str 
	push eax 
	call ServerB_log 
	push dword ptr string(13, 10) 
	call ServerB_log 
	
	push dword ptr SIZEOF STARTUPINFO + SIZEOF PROCESS_INFORMATION + 32 
	push dword ptr 0 
	call GlobalAlloc 
	mov dword ptr [ebp-4], eax 
	
	mov ebx, eax 
	mov dword ptr [ebx+00], SIZEOF STARTUPINFO 
	mov dword ptr [ebx+04], 0 
	mov dword ptr [ebx+08], 0 
	mov dword ptr [ebx+12], 0 
	mov dword ptr [ebx+16], CW_USEDEFAULT 
	mov dword ptr [ebx+20], CW_USEDEFAULT 
	mov dword ptr [ebx+24], CW_USEDEFAULT 
	mov dword ptr [ebx+28], CW_USEDEFAULT 
	mov dword ptr [ebx+32], 0 
	mov dword ptr [ebx+36], 0 
	mov dword ptr [ebx+40], 0 
	
	mov dword ptr [ebx+44], 100h or 1 
	
	mov word ptr [ebx+48], SW_HIDE 
	mov word ptr [ebx+50], 0 
	mov dword ptr [ebx+52], 0 
	
	mov eax, dword ptr [ebp-4] 
	mov ebx, eax 
	mov eax, dword ptr [ebp-28+00] 
	mov dword ptr [ebx+56], eax 
	
	mov eax, dword ptr [ebp-4] 
	mov ebx, eax 
	mov eax, dword ptr [ebp-28+12] 
	mov dword ptr [ebx+60], eax 
	
	lea ebx, [ebp-12] 
	push dword ptr DUPLICATE_SAME_ACCESS 
	push dword ptr 1 
	push dword ptr 0 
	push ebx 
		push eax 
			call GetCurrentProcess 
		pop ebx 
	push eax 
	push ebx 
	push eax 
	call DuplicateHandle 
	mov ebx, string("ServerB:  Error making error handle. ", 13, 10) 
	cmp eax, 0 
	jnz @F 
		push ebx 
		call ServerB_log 
	@@: 
	cmp eax, -1 
	jnz @F 
		push ebx 
		call ServerB_log 
	@@: 
	
	mov eax, dword ptr [ebp+16] 
	mov dword ptr [ebp-56], eax 
	
	mov eax, dword ptr [ebp-04] 
	mov ebx, eax 
	mov eax, dword ptr [ebp-12] 
	mov dword ptr [ebx+64], eax 
	
	lea eax, [ebx+SIZEOF STARTUPINFO] 
	push eax 
	push ebx 
	push dword ptr [ebp-8] 
	push dword ptr 0 
	push dword ptr CREATE_NO_WINDOW 
	push dword ptr 1 
	push dword ptr 0 
	push dword ptr 0 
	push dword ptr [ebp+12] 
	push dword ptr [ebp+08] 
	call CreateProcess 
	cmp eax, 0 
	jz app_start_err 
	
	push dword ptr [ebp-28+00] 
	call CloseHandle 
	
	push dword ptr [ebp-28+12] 
	call CloseHandle 
	
	push dword ptr [ebp-12] 
	call CloseHandle 
	
	push dword ptr 4096 
	push dword ptr 0 
	call GlobalAlloc 
	mov dword ptr [ebp-64], eax 
	
	;; Reserve 4 bytes on the stack. 
	push dword ptr 0 
	
	push dword ptr 1 or 1000h 
	push dword ptr space(SIZEOF OFSTRUCT) 
	push dword ptr string(92, "input.txt") 
	call OpenFile 
	mov dword ptr [esp], eax 
	
	mov eax, esp 
	mov ecx, ebp 
	sub ecx, eax 
	xchg eax, ecx 
	mov dword ptr [app_start_esp1], eax 
	
	;; Set the file pointer to [ebp-(28+24+12)-4]. 
	push dword ptr [ebp-(28+24+12)-4] 
	push dword ptr [ebp-56] 
	call set_pointer 
	
	app_start_lp1: 
		
		push dword ptr 0 
			lea eax, [ebp-60] 
		push eax 
		push dword ptr 4096 
		push dword ptr [ebp-64] 
		push dword ptr [ebp-56] 
		call ReadFile 
		cmp eax, 0 
		jz app_start_io_err 
		
		cmp dword ptr [ebp-60], 0 
		jz app_start_lp1s 
		
		push dword ptr 0 
		push dword ptr integer() 
		push dword ptr [ebp-60] 
		push dword ptr [ebp-64] 
		push dword ptr [ebp-28+4] 
		call WriteFile 
		
		mov eax, dword ptr [esp] 
		push dword ptr 0 
		push dword ptr integer() 
		push dword ptr [ebp-60] 
		push dword ptr [ebp-64] 
		push eax 
		call WriteFile 
		
		jmp app_start_lp1 
	app_start_lp1s: 
	push dword ptr [ebp-64] 
	call GlobalFree 
	
	push dword ptr [ebp-28+4] 
	call CloseHandle 
	
	call CloseHandle 
	
	mov eax, dword ptr [ebp-28+08] 
	mov edx, eax 
	
	jmp app_start_finish 
	
	app_start_io_err: 
	call GetLastError 
	push dword ptr string() 
	push eax 
	call i2str 
	push eax 
	mov eax, string() 
	mov ebx, string("An IO error occurred. ", 13, 10, 13, 10, "Windows System Error Code: ") 
	call StringCopy 
	pop ebx 
	call StringCat 
	mov ebx, string(13, 10, "Memory Location: ") 
	call StringCat 
	push eax 
	push dword ptr string() 
	push dword ptr [ebp-64] 
	call i2str 
	mov ebx, eax 
	pop eax 
	call StringCat 
	mov ebx, string(13, 10, "ESP, relative to EBP, after OpenFile(): ") 
	call StringCat 
	push eax 
	push dword ptr string() 
	push dword ptr [app_start_esp1] 
	call i2str 
	mov ebx, eax 
	pop eax 
	call StringCat 
	push dword ptr 0 
	push dword ptr offset ApplicationName 
	push eax 
	push dword ptr 0 
	call MessageBoxA 
	
	app_start_err: 
		call GetLastError 
		pusha 
			push dword ptr string("Windows System Error Code: ") 
			call ServerB_log 
		popa 
		push dword ptr string() 
		push eax 
		call i2str 
		push eax 
		call ServerB_log 
		push dword ptr string(13, 10) 
		call ServerB_log 
		
		push dword ptr [ebp-4] 
		call GlobalFree 
		mov dword ptr [ebp-4], 0 
		
		xor edx, edx 
	jmp app_start_finish 
	
	app_start_finish: 
	
	mov eax, edx 
	mov dword ptr [ebp-12], eax 
	
	push dword ptr [ebp-8] 
	call GlobalFree 
	
	mov eax, dword ptr [ebp-12] 
	mov edx, eax 
	
	mov eax, dword ptr [ebp-4] 
	
	pop esi 
	leave 
ret 16 

get_app: 
	enter 4, 0 
	
	mov eax, dword ptr [ebp+8] 
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
	mov eax, string() 
	call StringCopy 
	mov dword ptr [ebp-4], eax 
	
	mov ebx, eax 
	
	mov al, byte ptr [ebx] 
	cmp al, 34 
	jz get_app_use_34 
	
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
	mov byte ptr [ebx], 0 
	
	jmp get_app_finish 
	
	get_app_use_34: 
	
	@@: 
		mov al, byte ptr [ebx] 
		cmp al, 34 
		jz @F 
		inc ebx 
		jmp @B 
	@@: 
	inc ebx 
	mov byte ptr [ebx], 0 
	
	jmp get_app_finish 
	
	get_app_finish: 
	
	mov eax, dword ptr [ebp-4] 
	leave 
ret 4 

to_be_deleted: 
	enter 16, 0 
	
	mov eax, dword ptr [ebp+8] 
	call StringLength 
	cmp eax, 4 
	jg @F 
		leave 
		ret 4 
	@@: 
	
	mov eax, string() 
	mov ebx, offset deleter_path 
	call StringCopy 
	mov ebx, string(" ") 
	call StringCat 
	mov ebx, eax 
	mov eax, dword ptr [ebp+8] 
	xchg eax, ebx 
	call StringCat 
	
	pusha 
		push dword ptr 2 or 1000h 
		push dword ptr space(SIZEOF OFSTRUCT) 
		push dword ptr string("deleter.txt") 
		call OpenFile 
		mov dword ptr [ebp-8], eax 
		
		cmp eax, 0 
		jz @F 
		cmp eax, -1 
		jz @F 
		
		jmp d_over1 
		
		@@: 
			push dword ptr string("Error making file deleter.txt", 13, 10) 
			call ServerB_log 
		d_over1: 
	popa 
	
	push dword ptr [ebp-8] 
	push dword ptr [ebp-8] 
	push eax 
	push dword ptr offset deleter_path 
	call app_start 
	
	mov dword ptr [ebp-4], eax 
	
	push edx 
	call CloseHandle 
	
	push dword ptr [ebp-4] 
	call GlobalFree 
	
	leave 
ret 4 

replace_47_with_92: 
	enter 0, 0 
	
	r_lp1: 
		mov al, byte ptr [ebx] 
		cmp al, 47 
		jz r_lp1a 
		cmp al, 0 
		jz r_lp1s 
		
		inc ebx 
		jmp r_lp1 
	r_lp1a: 
		mov dword ptr [ebx], 92 
		inc ebx 
		jmp r_lp1 
	r_lp1s: 
	
	leave 
ret 

get_english_word proc 
	enter 0, 0 
	pusha 
	
	mov eax, dword ptr [ebp+8] 
	mov edx, eax 
	
	mov eax, string() 
	mov ebx, eax 
	mov dword ptr [ebp-4], eax 
	
	@@: 
		mov al, byte ptr [edx] 
		mov byte ptr [ebx], al 
		cmp al, 32 
		jz @F 
		cmp al, 9 
		jz @F 
		cmp al, 13 
		jz @F 
		cmp al, 10 
		jz @F 
		cmp al, 0 
		jz @F 
		inc ebx 
		inc edx 
		jmp @B 
	@@: 
	mov byte ptr [ebx], 0 
	
	popa 
	leave 
	ret 4 
get_english_word endp 

uc proc 
	enter 0, 0 
	pusha 
	
	mov eax, dword ptr [ebp+8] 
	
	mov ebx, eax 
	uc_lp2: 
		mov al, byte ptr [ebx] 
		cmp al, 97 
		jl uc_lp2o 
		cmp al, 97 + 26 
		jnl uc_lp2o 
		sub al, 32 
		mov byte ptr [ebx], al 
	uc_lp2o: 
		cmp al, 0 
		jz uc_lp2s 
		inc ebx 
		jmp uc_lp2 
	uc_lp2s: 
	
	popa 
	leave 
	ret 4 
uc endp 

strcmp proc 
	enter 0, 0 
	pusha 
	
	mov edx, ebx 
	mov ebx, eax 
	
	xor eax, eax 
	sc_lp1: 
		mov al, byte ptr [ebx] 
		cmp al, 0 
		jz sc_lp1s 
		sub al, byte ptr [edx] 
		jnz sc_lp1s 
		
		inc ebx 
		inc edx 
		jmp sc_lp1 
	sc_lp1s: 
	
	mov dword ptr [ebp-4], eax 
	
	popa 
	leave 
	ret 0 
strcmp endp 

strcmp2 proc 
	enter 0, 0 
	pusha 
	
	push ebx 
		mov ebx, eax 
		mov eax, string() 
		call StringCopy 
		push eax 
		call uc 
	pop ebx 
	
	xchg eax, ebx 
	
	push ebx 
		mov ebx, eax 
		mov eax, string() 
		call StringCopy 
		push eax 
		call uc 
	pop ebx 
	
	xchg eax, ebx 
	
	mov edx, ebx 
	mov ebx, eax 
	
	xor eax, eax 
	sc_lp1: 
		mov al, byte ptr [ebx] 
		cmp al, 0 
		jz sc_lp1s 
		sub al, byte ptr [edx] 
		jnz sc_lp1s 
		
		inc ebx 
		inc edx 
		jmp sc_lp1 
	sc_lp1s: 
	
	mov dword ptr [ebp-4], eax 
	
	popa 
	leave 
	ret 0 
strcmp2 endp 

end start 