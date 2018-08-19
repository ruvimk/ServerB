.code 

_set_direction: 
jmp set_direction 

_skip_to_char: 
jmp skip_to_char 

_skip_to_non_char: 
jmp skip_to_non_char 

_skip_to_space: 
jmp skip_to_space 

_skip_to_non_space: 
jmp skip_to_non_space 

_skip_to_new: 
jmp skip_to_new 

_look_for_header: 
jmp look_for_header 

_new_local: 
jmp new_local 

_compare_no_case: 
jmp compare_no_case 

_compare_char_no_case: 
jmp compare_char_no_case 

_higher_al_and_ah_case: 
jmp higher_al_and_ah_case 

_higher_al_case: 
jmp higher_al_case 

_skip_to_next: 
jmp skip_to_next 

_replace_new_with_null: 
jmp replace_new_with_null 


skip_to_char: 
	; ;; ebx= ptr; ah= the char; 
	mov edx, ebx ;; debug 
	skip_to_char_lp1: 
		mov al, [ebx] 
		
		; ;; debug 
		; push eax 
		; push eax 
		
		; mov cl, al 
		; xor eax, eax 
		; mov al, cl 
		
		; push dword ptr offset string01 
		; push eax 
		; call i2str 
		
		; push dword ptr offset string01 
		; call ServerB_log 
		; push dword ptr string (13, 10) 
		; call ServerB_log 
		
		; pop eax 
		
		; mov cl, ah 
		; xor eax, eax 
		; mov al, cl 
		
		; push dword ptr offset string01 
		; push eax 
		; call i2str 
		
		; push dword ptr offset string01 
		; call ServerB_log 
		; push dword ptr string (13, 10) 
		; call ServerB_log 
		
		; pop eax ;; end debug 
		
		cmp al, ah 
		jz skip_to_char_lp1s 
		
		cmp al, 0 
		jz skip_to_char_lp1z 
		
		push eax ;; save before dislace 
		
		mov eax, 1 
		call displace_direction 
		
		pop eax ;; restore after displace 
		
		;inc ebx 
		jmp skip_to_char_lp1 
	skip_to_char_lp1s: 
		mov al, 1 
		ret 0 
	skip_to_char_lp1z: 
		or al, -1 
		ret 0 
;; end #block 

skip_to_non_char: 
	;; ebx= ptr; ah= the char; 
	skip_to_non_char_lp1: 
		mov al, [ebx] 
		
		cmp al, ah 
		jnz skip_to_non_char_lp1n 
		
		cmp al, 0 
		jz skip_to_non_char_lp1z 
		
		push eax ;; save before displace 
		
		mov eax, 1 
		call displace_direction 
		
		pop eax ;; restore after displace 
		
		;inc ebx 
		jmp skip_to_non_char_lp1 
	skip_to_non_char_lp1n: 
		and al, 0 
		ret 0 
	skip_to_non_char_lp1z: 
		or al, -1 
		ret 0 
;; end #block 

skip_to_space: 
	;; ebx= ptr; 
	mov ah, 32 
	call skip_to_char 
	ret 0 
;; end #block 

skip_to_next: 
	;; ebx= ptr; 
	enter 8, 0 
	pushad 
	cmp byte ptr [ebx], 34 
	jnz n_34 
	jz i_34 
	n_34: 
		mov edx, ebx  ;; back ebx 
		mov ah, 34 
		call skip_to_char 
		mov dword ptr [ebp-8], ebx 
		mov ebx, edx 
		mov ah, 32 
		call skip_to_char 
		cmp ebx, dword ptr [ebp-8] 
		jg g_34 
		jmp g_32 
		g_32: 
			call skip_to_non_space 
			jmp g_c 
		g_34: 
			mov ebx, dword ptr [ebp-8] 
			jmp g_c 
		g_c: 
		jmp finish 
	i_34: 
		mov eax, 1 
		call displace_direction 
		;inc ebx 
		mov ah, 34 
		call skip_to_char 
		cmp al, -1 
		jz null1 
		mov eax, 1 
		call displace_direction 
		;inc ebx 
		call skip_to_non_space 
		cmp al, -1 
		jz null1 
		jmp finish 
	finish: 
	mov [ebp-8], ebx 
	popad 
	mov ebx, [ebp-8] 
	leave 
	xor eax, eax 
	ret 0 
	null1: 
			mov [ebp-8], ebx 
		popad 
	mov ebx, [ebp-8] 
		leave 
		and eax, -1 
		ret 0 
;; end #block 

skip_to_non_space: 
	;; ebx= ptr; 
	mov ah, 32 
	call skip_to_non_char 
	ret 0 
;; end #block 

skip_to_new: 
	;; ebx= ptr; 
	enter 8, 0 
	
	mov [ebp-4], ebx 
	
	mov ah, 13 
	call skip_to_char 
	
	mov [ebp-8], ebx 
	
	mov ebx, [ebp-4] 
	
	mov ah, 10 
	call skip_to_char 
	
	mov ah, 1 
	
	cmp ebx, dword ptr [ebp-8] 
	jl skip_to_new_lbl1 
	jmp skip_to_new_lbl2 
	
	skip_to_new_lbl1: 
		jmp skip_to_new_lbl3 
	skip_to_new_lbl2: 
		mov ebx, [ebp-8] 
		jmp skip_to_new_lbl3 
	skip_to_new_lbl3: 
	
	mov al, [ebx] 
	cmp al, 13 
	jz skip_to_new_lbl4 
	cmp al, 10 
	jz skip_to_new_lbl4 
	cmp al, 0 
	jz skip_to_new_lbl5 
	
	;inc ebx 
	push eax 
	mov eax, 1 
	call displace_direction 
	pop eax 
	jmp skip_to_new_lbl5 
	
	skip_to_new_lbl4: 
	
	xchg eax, ebx 
	push eax 
	mov eax, 1 
	call displace_direction 
	xchg eax, ebx 
	pop ebx 
	;inc ah 
	
	push eax 
	mov eax, 1 
	call displace_direction 
	pop eax 
	;inc ebx 
	
	jmp skip_to_new_lbl3 
	
	skip_to_new_lbl5: 
	
	leave 
	ret 0 
;; end #block 

look_for_header: 
	;; ebx= &header, eax= &field, /* old: edx= default type { 0 = NULL | 1 = "default" } */ 
	;; ebx= ptr; eax= str; /* (used to be) edx= return type */; 
	enter 12, 0 
	mov dword ptr [ebp-8], eax 
	mov dword ptr [ebp-12], ebx 
	xor eax, eax 
	and ch, 0 
	lbl_put01_lp1a: 
		push ebx 
		mov eax, ebx 
		mov ebx, dword ptr [ebp-8] 
		call compare_no_case 
		pop ebx 
		cmp eax, 0 
		jnz lbl_put01_lp1as 
		call skip_to_new 
		cmp ch, 1 
		jnz lbl_put01_lp1af1 
		cmp eax, 0 
		jnz lbl_put01_lp1af1 
		jmp lbl_put01_lp1a 
		lbl_put01_lp1af1: 
		xor ebx, ebx 
		mov dword ptr [ebp-4], ebx 
		mov eax, -1 
		jmp lbl_put01_lp1af 
	lbl_put01_lp1as: 
		mov ah, 58 
		call skip_to_char 
		;inc ebx 
		mov eax, 1 
		call displace_direction 
		call skip_to_non_space 
		mov dword ptr [ebp-4], ebx 
		mov dword ptr [ebp-8], ebx 
		mov ah, 13 
		call skip_to_char 
		push dword ptr [ebp-8] 
		mov dword ptr [ebp-8], ebx 
		pop ebx 
		mov ah, 10 
		call skip_to_char 
		cmp ebx, dword ptr [ebp-8] 
		jl lbl_put01_lp1as_1 
			mov ebx, dword ptr [ebp-8] 
			jmp lbl_put01_lp1as_c 
		lbl_put01_lp1as_1: 
			jmp lbl_put01_lp1as_c 
		lbl_put01_lp1as_c: 
		;; old: mov byte ptr [ebx], 0 
		xor eax, eax 
		jmp lbl_put01_lp1af 
	lbl_put01_lp1af: 
	mov ebx, dword ptr [ebp-12] 
	mov eax, dword ptr [ebp-4] 
	leave 
	ret 4 
;; end #block 

replace_new_with_null: 
	enter 8, 0 
	mov dword ptr [ebp-4], eax 
	mov dword ptr [ebp-8], ebx 
	
	replace_new_with_null_lp1: 
		mov al, byte ptr [ebx] 
		cmp al, 13 
		jz replace_new_with_null_n 
		cmp al, 10 
		jz replace_new_with_null_n 
		cmp al, 0 
		jz replace_new_with_null_z 
		call displace_direction 
		;inc ebx 
		jmp replace_new_with_null_lp1 
	replace_new_with_null_n: 
		xor eax, eax 
		mov byte ptr [ebx], al 
		call displace_direction 
		;inc ebx 
		jmp replace_new_with_null_lp1 
	replace_new_with_null_z: 
		jmp replace_new_with_null_lp1s 
	replace_new_with_null_lp1s: 
	
	leave 
	ret 0 
;; end #block 

new_local: 
	;; eax= count; 
	;; Allocates memory for the current procedure. 
	;; eax= Number of bytes of memory to allocate, on the stack. 
	;; Warning: It is dangerous to call this function between stack dependances. 
	;;              This function reserves memory at the stack, meaning everything 
	;;              pushed to the stack, prior to this point, will not be directly available. 
	;;              To retrieve a value that has been pushed to the stack before 
	;;              calling this function, do the following: 
	;;              ebx= esp + <number of bytes allocated by this function> 
	;;             	// That would put the previous esp to ebx. 
	;;              To pop (to eax) a value pushed right before the function call, with ebx being (esp + <.....>): 
	;;              eax= [ebx] 
	;;              To pop a value pushed before that: 
	;;              eax= [ebx+4] 
	;;              To pop a value even before that: 
	;;              eax= [ebx+8] 
	;;              And so on.....  
	;;       It's best to call this function before using the stack, however, to undo this function, do: 
	;;              add esp, <number of bytes allocated by this function> 
	;;          You must only undo this function when esp equals the value it was right after calling this function, though; 
	;;          other wise you might get into trouble. 
	mov ecx, eax 
	dec esp 
	xor eax, eax 
	new_local_lp1: 
		jecxz new_local_lp1s 
		mov byte ptr [esp], al 
		dec esp 
		dec ecx 
		jmp new_local_lp1 
	new_local_lp1s: 
	mov eax, esp 
	ret 0 
;; end #function 

compare_no_case: 
	;; compare_no_case /* strcmp(a, b), but without case sensitivity and length limits */. 
	;; eax= string1; ebx= string2; 
	enter 8, 0 
	pushad 
	mov dword ptr [ebp-4], eax 
	mov dword ptr [ebp-8], ebx 
	
	mov edx, ebx 
	mov ebx, eax 
	
	compare_no_case_lp1: 
		mov al, [ebx] 
		mov ah, [edx] 
		
		;; If al or ah is zero, return true. 
		cmp al, 0 
		jz compare_no_case_lp1z 
		cmp ah, 0 
		jz compare_no_case_lp1z 
		
		;; Else, compare the characters or letters. 
		call compare_char_no_case 
		
		;; If false, return false. 
		cmp eax, 0 
		jz compare_no_case_lp1s 
		
		;; Otherwise, continue. 
		mov eax, 1 
		call displace_direction 
		xchg ebx, edx 
		call displace_direction 
		xchg ebx, edx 
		;inc ebx 
		;inc edx 
		jmp compare_no_case_lp1 
	compare_no_case_lp1s: 
		jmp compare_no_case_over1 
	compare_no_case_lp1z: 
		mov eax, 2 
		jmp compare_no_case_over1 
	compare_no_case_lp1f: 
		mov eax, 1 
		jmp compare_no_case_over1 
	compare_no_case_over1: 
	
	mov [ebp-4], eax 
	popad 
	mov eax, [ebp-4] 
	leave 
	ret 0 
	;; Returns 0 if not equal. Else, 1 if equal and the lengths match, 2 otherwise. 
;; endp 

compare_char_no_case: 
	;; Compares al to ah; if both al and ah are letters, they're equal as long as they're the same letter. 
	call higher_al_and_ah_case 
	cmp al, ah 
	jz compare_char_no_case_over1 
	jmp compare_char_no_case_over2 
	compare_char_no_case_over1: 
		mov eax, 1 
	ret 
	compare_char_no_case_over2: 
		xor eax, eax 
	ret 0 
	;; Returns TRUE if al and ah are equal, else returns FALSE. 
;; endp 

higher_al_and_ah_case: 
	call higher_al_case 
	xchg al, ah 
	call higher_al_case 
	xchg al, ah 
	ret 0 
;; endp 

higher_al_case: 
	;; If al is a lower-case letter, turns it into a capital letter. 
	cmp al, 97 
	jl higher_al_case_over1 
		cmp al, 123 
		jnl higher_al_case_over2 
			sub al, 32 
			jmp higher_al_case_over1 
		higher_al_case_over2: 
		jmp higher_al_case_over1 
	higher_al_case_over1: 
	ret 0 
;; endp 

displace_direction: 
	cmp dword ptr [the_direction], 0 
	jnz displace_direction_ff 
	jmp displace_direction_rr 
	displace_direction_ff: 
		add ebx, eax 
		
		jmp displace_direction_finish 
	displace_direction_rr: 
		sub ebx, eax 
		
		jmp displace_direction_finish 
	displace_direction_finish: 
	ret 0 
;; endp 

set_direction: 
	sub esp, 4 
	mov [esp], al 
	xor eax, eax 
	mov al, [esp] 
	add esp, 4 
	mov dword ptr [the_direction], eax 
	ret 0 
;; endp 


.data 
the_direction                  dd  1 
