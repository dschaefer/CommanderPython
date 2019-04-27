!source "defs.ah"

    * = $0800

basic:
    !byte 0
    !word end_of_basic
    !word 10
    !byte token_SYS
    !pet "2560" ; address of start
end_of_basic:
    !byte 0, 0, 0

;   The direct page
;       make sure it's aligned on page boundary for performance
    !align $ff, 0
direct_page:
    !zone direct_page
    dp_basic_stack+1 = * - direct_page
    !word 0
    dp_python_stack+1 = * - direct_page
    !word $cfff
    dp_object_stack+1 = * - direct_page
    !word $c7ff
    dp_pc = * - direct_page
    !24 0
    ; fill out to the end of the direct page
    !align $ff, 0, 0

;   The entry point
start:
    !zone start
    ; enter native mode and switch to python stack
    +cpu_native
    +ai16

    ; set up the direct page
    lda #direct_page
    tcd

    ; switch call stacks
    tsc
    sta dp_basic_stack
    lda dp_python_stack
    tcs

    ; initialize the object store
    jsr objects_init

    ; run python
    jsr python_main

    ; restore call stack    
    lda dp_basic_stack
    tcs

    ; restore direct page
    lda #0
    tcd

    ; restore data bank
    +a8
    pha
    plb

    ; back to basic
    +cpu_emu
    rts

!source "tables.s"
!source "util.s"
!source "memory.s"
!source "string.s"
!source "code.s"

python_main:
    !zone python_main
    .fp = 0
    +pushptra ~.fp, 0, _test_main
    jsr code_run
    +popa ~.fp, 3
    +checkfp .fp
    rts

_test_welcome:
    !word type_string << 8 | 1
    !word ++ - +
+
    !pet petscii_LOWERCASE, "Welcome to Python!", $d, $0
++

_test_print:
    !word type_string << 8 | 1
    !word ++ - +
+
    !pet "print", 0
++

_test_main:
    !word type_code << 8 | 1
    !word ++ - +
+
    !word ++++ - +++
+++
    !byte opcode_load, 0
    !byte opcode_load, 1
    !byte opcode_call_function, 1
++++
    !24 _test_welcome
    !24 _test_print
++
