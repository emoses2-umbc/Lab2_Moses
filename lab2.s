.section .data
prompt1:      .ascii "Enter string 1: "
prompt1_len = . - prompt1
prompt2:      .ascii "Enter string 2: "
prompt2_len = . - prompt2
msg_label:    .ascii "Hamming distance: "
msg_label_len = . - msg_label
newline:      .ascii "\n"

.section .bss
buf1:    .space 256
buf2:    .space 256
num_buf: .space 10

.section .text
.global _start

_start:
    # --- print prompt 1 ---
    movl $4,          %eax
    movl $1,          %ebx
    movl $prompt1,    %ecx
    movl $prompt1_len,%edx
    int  $0x80

    # --- read string 1 into buf1 ---
    movl $3,    %eax
    movl $0,    %ebx
    movl $buf1, %ecx
    movl $256,  %edx
    int  $0x80

    # --- strip newline from buf1 ---
    movl $buf1, %esi
strip1:
    movb (%esi), %al
    cmpb $10, %al
    je   strip1_done
    cmpb $0, %al
    je   strip1_done
    incl %esi
    jmp  strip1
strip1_done:
    movb $0, (%esi)

    # --- print prompt 2 ---
    movl $4,          %eax
    movl $1,          %ebx
    movl $prompt2,    %ecx
    movl $prompt2_len,%edx
    int  $0x80

    # --- read string 2 into buf2 ---
    movl $3,    %eax
    movl $0,    %ebx
    movl $buf2, %ecx
    movl $256,  %edx
    int  $0x80

    # --- strip newline from buf2 ---
    movl $buf2, %esi
strip2:
    movb (%esi), %al
    cmpb $10, %al
    je   strip2_done
    cmpb $0, %al
    je   strip2_done
    incl %esi
    jmp  strip2
strip2_done:
    movb $0, (%esi)

    # --- measure length of buf1 -> store on stack ---
    movl $buf1, %esi
    movl $0,    %ecx
len1_loop:
    movb (%esi), %al
    cmpb $0, %al
    je   len1_done
    incl %ecx
    incl %esi
    jmp  len1_loop
len1_done:
    pushl %ecx              # stack: [len1]

    # --- measure length of buf2 -> store on stack ---
    movl $buf2, %esi
    movl $0,    %ecx
len2_loop:
    movb (%esi), %al
    cmpb $0, %al
    je   len2_done
    incl %ecx
    incl %esi
    jmp  len2_loop
len2_done:
    pushl %ecx              # stack: [len2] [len1]

    # --- pick the smaller length into ecx ---
    popl %edx               # edx = len2
    popl %ecx               # ecx = len1
    cmpl %ecx, %edx
    jge  pick_done          # if len2 >= len1, ecx (len1) is smaller or equal
    movl %edx, %ecx         # else len2 is smaller
pick_done:
                            # ecx = min length

    # --- hamming loop ---
    movl $0, %eax           # eax = distance
    movl $0, %edi           # edi = index i

hamming_loop:
    cmpl %ecx, %edi
    je   print_answer

    movl $buf1, %esi
    addl %edi,  %esi
    movzbl (%esi), %ebx     # ebx = buf1[i]

    movl $buf2, %esi
    addl %edi,  %esi
    movzbl (%esi), %edx     # edx = buf2[i]

    cmpl %ebx, %edx
    je   no_diff
    incl %eax
no_diff:
    incl %edi
    jmp  hamming_loop

    # --- print result ---
print_answer:
    pushl %eax              # save distance

    movl $4,             %eax
    movl $1,             %ebx
    movl $msg_label,     %ecx
    movl $msg_label_len, %edx
    int  $0x80

    popl %eax               # restore distance

    # --- convert eax to ascii digits in num_buf ---
    movl $num_buf, %edi
    addl $9, %edi
    movl $0, %ecx

    cmpl $0, %eax
    jne  cvt_loop
    movb $'0', (%edi)
    movl %edi, %esi
    movl $1,   %ecx
    jmp  print_digits

cvt_loop:
    cmpl $0, %eax
    je   cvt_done
    movl $0,  %edx
    movl $10, %ebx
    divl %ebx
    addb $'0', %dl
    movb %dl, (%edi)
    decl %edi
    incl %ecx
    jmp  cvt_loop
cvt_done:
    incl %edi
    movl %edi, %esi

print_digits:
    movl %ecx, %edx
    movl %esi, %ecx
    movl $4,   %eax
    movl $1,   %ebx
    int  $0x80

    movl $4,       %eax
    movl $1,       %ebx
    movl $newline, %ecx
    movl $1,       %edx
    int  $0x80

    movl $1, %eax
    movl $0, %ebx
    int  $0x80
