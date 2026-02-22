; Ayush Jain LLVM test
; Take in n numbers in command line
; First n - 2 form an array, last 2 form index range
; Sum all values in that index range using fenwick tree

; No guardrail for out of bounds, will give non deterministic for unsafe inputs

declare void @ll_puts(i8*)
declare i8* @ll_ltoa(i64)
declare i64 @atoi(i8*)

define void @tree_add(i64* %arr, i64 %n, i64 %p_idx, i64 %val) {
    %i = alloca i64
    store i64 %p_idx, i64* %i
    br label %tree_cond

tree_cond:
    %idx = load i64, i64* %i
    %cond = icmp sle i64 %idx, %n
    br i1 %cond, label %tree_body, label %tree_end

tree_body:
    %curr_ptr = getelementptr i64, i64* %arr, i64 %idx
    %curr_val = load i64, i64* %curr_ptr
    %nxt = add i64 %curr_val, %val
    store i64 %nxt, i64* %curr_ptr

    %neg = sub i64 0, %idx
    %low = and i64 %idx, %neg
    %new_idx = add i64 %idx, %low
    store i64 %new_idx, i64* %i
    br label %tree_cond

tree_end:
    ret void
}

define i64 @tree_sum(i64* %arr, i64 %p_idx) {
    %i = alloca i64
    %sum = alloca i64
    store i64 %p_idx, i64* %i
    store i64 0, i64* %sum
    br label %sum_cond

sum_cond:
    %idx = load i64, i64* %i
    %cond = icmp sgt i64 %idx, 0
    br i1 %cond, label %sum_body, label %sum_end

sum_body:
    %ptr = getelementptr i64, i64* %arr, i64 %idx
    %curr = load i64, i64* %ptr
    %val = load i64, i64* %sum
    %new_sum = add i64 %val, %curr
    store i64 %new_sum, i64* %sum

    %neg = sub i64 0, %idx
    %low = and i64 %idx, %neg
    %new_idx = sub i64 %idx, %low
    store i64 %new_idx, i64* %i
    br label %sum_cond

sum_end:
    %ans = load i64, i64* %sum
    ret i64 %ans
}

define i64 @main(i64 %argc, i8** %argv) {
    %tree = alloca [20 x i64]
    %zero_i = alloca i64
    
    %k = sub i64 %argc, 3
    store i64 0, i64* %zero_i
    br label %zero_cond

zero_cond:
    %zero_idx = load i64, i64* %zero_i
    %cond_z = icmp sle i64 %zero_idx, %k
    br i1 %cond_z, label %zero_loop, label %zeroed

zero_loop:
    %z_ptr = getelementptr [20 x i64], [20 x i64]* %tree, i64 0, i64 %zero_idx
    store i64 0, i64* %z_ptr
    %new_z = add i64 %zero_idx, 1
    store i64 %new_z, i64* %zero_i
    br label %zero_cond

zeroed:
    %i = alloca i64
    store i64 0, i64* %i
    br label %build_cond

build_cond:
    %idx = load i64, i64* %i
    %cond = icmp slt i64 %idx, %k
    br i1 %cond, label %build_loop, label %build_end

build_loop:
    %shifted_idx = add i64 %idx, 1
    %num_ptrptr = getelementptr i8*, i8** %argv, i64 %shifted_idx
    %num_str = load i8*, i8** %num_ptrptr
    %val = call i64 @atoi(i8* %num_str)

    %tree_ptr = getelementptr [20 x i64], [20 x i64]* %tree, i64 0, i64 0
    call void @tree_add(i64* %tree_ptr, i64 %k, i64 %shifted_idx, i64 %val)

    store i64 %shifted_idx, i64* %i
    br label %build_cond

build_end:
    %argc_i2 = sub i64 %argc, 2
    %argc_i1 = sub i64 %argc, 1

    %l_ptrptr = getelementptr i8*, i8** %argv, i64 %argc_i2
    %l_str = load i8*, i8** %l_ptrptr
    %l_idx = call i64 @atoi(i8* %l_str)

    %r_ptrptr = getelementptr i8*, i8** %argv, i64 %argc_i1
    %r_str = load i8*, i8** %r_ptrptr
    %r_idx = call i64 @atoi(i8* %r_str)

    %tree_ptr1 = getelementptr [20 x i64], [20 x i64]* %tree, i64 0, i64 0
    %r_shifted = add i64 %r_idx, 1
    %sum_r = call i64 @tree_sum(i64* %tree_ptr1, i64 %r_shifted)
    %sum_l = call i64 @tree_sum(i64* %tree_ptr1, i64 %l_idx)

    %ans = sub i64 %sum_r, %sum_l
    %ans_string = call i8* @ll_ltoa(i64 %ans)
    call void @ll_puts(i8* %ans_string)

    ret i64 0
}
