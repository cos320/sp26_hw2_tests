; Daniel Yang (test for yanda-hw2)
; Simulates a pushdown automaton for balanced brackets
; Takes in a sequence of up to 16 numbers 0 (open bracket) or
; 1 (close bracket) and outputs 0 (reject) or 1 (accept)

declare i64 @atoi(i8*)
declare void @ll_puts(i8*)

; Defines a transition rule in the PDA
%Transition = type {
    i64, ; new_state
    i64, ; stack_action
    i64  ; push_symbol
}

; Fixed-size stack
%Stack = type {
    i64,       ; top (next slot)
    [16 x i64] ; stack data
}

; Pushdown Automata
; States:        0 = error, 1 = running
; Stack actions: 0 = no-op, 1 = push, 2 = pop
; Stack symbols: 0 = stack bottom, 1 = open bracket
; Input symbols: 0 = open bracket, 1 = close bracket
; transition[state][input][stack] -> rule
%PDA = type {
    i64,                           ; current_state 
    i64,                           ; input_len
    [16 x i64],                    ; input
    [2 x [2 x [2 x %Transition]]], ; transitions
    [2 x i64]                      ; accept
}

define void @stack_push(%Stack* %stack, i64 %symbol) {
    %top_ptr = getelementptr %Stack, %Stack* %stack, i64 0, i32 0
    %top = load i64, i64* %top_ptr
    ; store new symbol
    %slot_ptr = getelementptr %Stack, %Stack* %stack, i64 0, i32 1, i64 %top
    store i64 %symbol, i64* %slot_ptr
    ; increment top
    %new_top = add i64 %top, 1
    store i64 %new_top, i64* %top_ptr
    ret void
}

define void @stack_pop(%Stack* %stack) {
    %top_ptr = getelementptr %Stack, %Stack* %stack, i64 0, i32 0
    %top = load i64, i64* %top_ptr
    ; decrement top
    %new_top = sub i64 %top, 1
    store i64 %new_top, i64* %top_ptr
    ret void
}

define i64 @stack_peek(%Stack* %stack) {
    %top_ptr = getelementptr %Stack, %Stack* %stack, i64 0, i32 0
    %top = load i64, i64* %top_ptr
    ; check for empty stack
    %cmp = icmp eq i64 %top, 0
    br i1 %cmp, label %empty, label %normal
empty:
    ret i64 -1
normal:
    %access = sub i64 %top, 1
    %data_ptr = getelementptr %Stack, %Stack* %stack, i64 0, i32 1, i64 %access
    %val = load i64, i64* %data_ptr
    ret i64 %val
}

define %Transition* @get_transition(%PDA* %pda, i64 %state, i64 %input_sym, i64 %stack_sym) {
    %trans_ptr = getelementptr %PDA, %PDA* %pda, i64 0, i32 3, i64 %state, i64 %input_sym, i64 %stack_sym
    ret %Transition* %trans_ptr
}

; Applies any applicable stack actions and returns the next state
define i64 @apply_transition(%Stack* %stack, %Transition* %transition) {
    %action_ptr = getelementptr %Transition, %Transition* %transition, i64 0, i32 1
    %action = load i64, i64* %action_ptr
    ; 3 possible stack actions (no-op, push, pop)
    %cmp0 = icmp eq i64 %action, 0
    br i1 %cmp0, label %return, label %else0
else0:
    %cmp1 = icmp eq i64 %action, 1
    br i1 %cmp1, label %push, label %pop
push:
    %sym_ptr = getelementptr %Transition, %Transition* %transition, i64 0, i32 2
    %sym = load i64, i64* %sym_ptr
    call void @stack_push(%Stack* %stack, i64 %sym)
    br label %return
pop:
    call void @stack_pop(%Stack* %stack)
    br label %return
return:
    %state_ptr = getelementptr %Transition, %Transition* %transition, i64 0, i32 0
    %state = load i64, i64* %state_ptr
    ret i64 %state
}

define i64 @run_pda(%PDA* %pda, %Stack* %stack) {
    ; push $ (stack bottom)
    call void @stack_push(%Stack* %stack, i64 0)
    %state_ptr = getelementptr %PDA, %PDA* %pda, i64 0, i32 0
    %idx_ptr = alloca i64
    store i64 0, i64* %idx_ptr
    %len_ptr = getelementptr %PDA, %PDA* %pda, i64 0, i32 1
    %input_len = load i64, i64* %len_ptr
    br label %loop_cond
loop_cond:
    ; loop until no more symbols
    %idx = load i64, i64* %idx_ptr
    %cmp_done = icmp sge i64 %idx, %input_len
    br i1 %cmp_done, label %validate, label %loop_body
loop_body:
    ; retrieve and apply transition
    %state = load i64, i64* %state_ptr
    %sym_ptr = getelementptr %PDA, %PDA* %pda, i64 0, i32 2, i64 %idx
    %input_sym = load i64, i64* %sym_ptr
    %stack_sym = call i64 @stack_peek(%Stack* %stack)
    %transition = call %Transition* @get_transition(%PDA* %pda, i64 %state, i64 %input_sym, i64 %stack_sym)
    %new_state = call i64 @apply_transition(%Stack* %stack, %Transition* %transition)
    store i64 %new_state, i64* %state_ptr
    %new_idx = add i64 %idx, 1
    store i64 %new_idx, i64* %idx_ptr
    br label %loop_cond
validate:
    ; accept iff accepting state and stack is empty
    %final_state = load i64, i64* %state_ptr
    %accept_ptr = getelementptr %PDA, %PDA* %pda, i64 0, i32 4, i64 %final_state
    %is_accept = load i64, i64* %accept_ptr
    %cmp_accept = icmp eq i64 %is_accept, 1
    br i1 %cmp_accept, label %check_stack, label %reject
check_stack:
    %stack_top = call i64 @stack_peek(%Stack* %stack)
    %cmp_stack = icmp eq i64 %stack_top, 0
    br i1 %cmp_stack, label %accept, label %reject
accept:
    ret i64 1
reject:
    ret i64 0
}

; Helper function for setting transitions - also takes 7 arguments
; transition[state][input][stack_symbol] = { new_state, action, push_symbol }
define void @set_transition(%PDA* %pda, i64 %state, i64 %input, i64 %stack, i64 %new_state, i64 %action, i64 %push) {
    %t_state = getelementptr %PDA, %PDA* %pda, i64 0, i32 3, i64 %state, i64 %input, i64 %stack, i32 0
    store i64 %new_state, i64* %t_state
    %t_action = getelementptr %PDA, %PDA* %pda, i64 0, i32 3, i64 %state, i64 %input, i64 %stack, i32 1
    store i64 %action, i64* %t_action
    %t_push = getelementptr %PDA, %PDA* %pda, i64 0, i32 3, i64 %state, i64 %input, i64 %stack, i32 2
    store i64 %push, i64* %t_push
    ret void
}

@acceptString = global [7 x i8] c"accept\00"
@rejectString = global [7 x i8] c"reject\00"

define i64 @main(i64 %argc, i8** %argv) {
    %pda = alloca %PDA
    %stack = alloca %Stack
    ; stack.top = 0
    %top_ptr = getelementptr %Stack, %Stack* %stack, i64 0, i32 0
    store i64 0, i64* %top_ptr
    ; pda.current_state = 1
    %state_ptr = getelementptr %PDA, %PDA* %pda, i64 0, i32 0
    store i64 1, i64* %state_ptr
    ; read input
    %len_ptr = getelementptr %PDA, %PDA* %pda, i64 0, i32 1
    %input_len = sub i64 %argc, 1
    store i64 %input_len, i64* %len_ptr
    %i_ptr = alloca i64
    store i64 0, i64* %i_ptr
    br label %read_loop
read_loop:
    ; break if i >= input_len
    %i = load i64, i64* %i_ptr
    %cmp_read = icmp sge i64 %i, %input_len
    br i1 %cmp_read, label %read_done, label %read_body
read_body:
    ; read next argument
    %argv_idx = add i64 %i, 1
    %arg_ptr = getelementptr i8*, i8** %argv, i64 %argv_idx
    %arg = load i8*, i8** %arg_ptr
    %val = call i64 @atoi(i8* %arg)
    ; store in input array
    %input_slot = getelementptr %PDA, %PDA* %pda, i64 0, i32 2, i64 %i
    store i64 %val, i64* %input_slot
    ; increment
    %next_i = add i64 %i, 1
    store i64 %next_i, i64* %i_ptr
    br label %read_loop
read_done:
    ; main transition table
    ; States:        0 = error, 1 = running
    ; Stack actions: 0 = no-op, 1 = push, 2 = pop
    ; Stack symbols: 0 = stack bottom, 1 = open bracket
    ; 0 (error) -> error (0, 0, 0)
    call void @set_transition(%PDA* %pda, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0)
    call void @set_transition(%PDA* %pda, i64 0, i64 0, i64 1, i64 0, i64 0, i64 0)
    call void @set_transition(%PDA* %pda, i64 0, i64 1, i64 0, i64 0, i64 0, i64 0)
    call void @set_transition(%PDA* %pda, i64 0, i64 1, i64 1, i64 0, i64 0, i64 0)
    ; 1 (running), 0 (open), 0 (bottom)   -> valid push open (1, 1, 1)
    call void @set_transition(%PDA* %pda, i64 1, i64 0, i64 0, i64 1, i64 1, i64 1)
    ; 1 (running), 0 (open), 1 (open)     -> valid push open (1, 1, 1)
    call void @set_transition(%PDA* %pda, i64 1, i64 0, i64 1, i64 1, i64 1, i64 1)
    ; 1 (running), 1 (closed), 0 (bottom) -> error (0, 0, 0)
    call void @set_transition(%PDA* %pda, i64 1, i64 1, i64 0, i64 0, i64 0, i64 0)
    ; 1 (running), 1 (closed), 1 (open)   -> valid pop (1, 2, 0)
    call void @set_transition(%PDA* %pda, i64 1, i64 1, i64 1, i64 1, i64 2, i64 0)

    ; acceptance array
    ; 0 = reject, 1 = accept
    %acc0 = getelementptr %PDA, %PDA* %pda, i64 0, i32 4, i64 0
    store i64 0, i64* %acc0
    %acc1 = getelementptr %PDA, %PDA* %pda, i64 0, i32 4, i64 1
    store i64 1, i64* %acc1

    ; simulate PDA
    %result = call i64 @run_pda(%PDA* %pda, %Stack* %stack)
    %cmp_final = icmp eq i64 %result, 1
    br i1 %cmp_final, label %accept, label %reject
accept:
    %acceptStr = getelementptr [7 x i8], [7 x i8]* @acceptString, i32 0, i32 0
    call void @ll_puts(i8* %acceptStr)
    ret i64 0
reject:
    %rejectStr = getelementptr [7 x i8], [7 x i8]* @rejectString, i32 0, i32 0
    call void @ll_puts(i8* %rejectStr)
    ret i64 0
}
