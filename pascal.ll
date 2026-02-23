; pascal's triangle row sum: Hita Gupta
; (The answer is just 2^n but this code constructs the triangle row by row)

; row_t contains info about the row's length and its data
%row_t = type { i64, [20 x i64] }

declare i64 @atoi(i8*)
declare i8* @ll_ltoa(i64)
declare void @ll_puts(i8*)

; given prev (row i-1) and cur (row i), fills cur's data
; cur.data[0] = 1, cur.data[i] = 1
; cur.data[j] = prev.data[j-1] + prev.data[j] for j in 1,...,i-1
define void @build_row(%row_t* %prev, %row_t* %cur, i64 %i) {
  ; cur.data[0] = 1
  %cur_first = getelementptr %row_t, %row_t* %cur, i32 0, i32 1, i64 0
  store i64 1, i64* %cur_first

  ; cur.data[i] = 1
  %cur_last = getelementptr %row_t, %row_t* %cur, i32 0, i32 1, i64 %i
  store i64 1, i64* %cur_last

  ; j goes from 1 to i-1: cur.data[j] = prev.data[j-1] + prev.data[j]
  %j = alloca i64
  store i64 1, i64* %j
  %i_minus_1 = sub i64 %i, 1
  br label %cond

cond:
  %j_val = load i64, i64* %j
  %j_past_end = icmp sgt i64 %j_val, %i_minus_1
  br i1 %j_past_end, label %done, label %body

body:
  %j_minus_1 = sub i64 %j_val, 1
  %prev_left_ptr = getelementptr %row_t, %row_t* %prev, i32 0, i32 1, i64 %j_minus_1
  %prev_left = load i64, i64* %prev_left_ptr
  %prev_right_ptr = getelementptr %row_t, %row_t* %prev, i32 0, i32 1, i64 %j_val
  %prev_right = load i64, i64* %prev_right_ptr
  %cur_j_val = add i64 %prev_left, %prev_right
  %cur_j_ptr = getelementptr %row_t, %row_t* %cur, i32 0, i32 1, i64 %j_val
  store i64 %cur_j_val, i64* %cur_j_ptr
  %j_next = add i64 %j_val, 1
  store i64 %j_next, i64* %j
  br label %cond

done:
  ret void
}

; sums row.data[0] to row.data[row.len] and returns the total
define i64 @sum_row(%row_t* %row) {
  %len_ptr = getelementptr %row_t, %row_t* %row, i32 0, i32 0
  %len = load i64, i64* %len_ptr

  %acc = alloca i64
  %i = alloca i64
  store i64 0, i64* %acc
  store i64 0, i64* %i
  br label %cond

cond:
  %i_val = load i64, i64* %i
  %past_end = icmp sgt i64 %i_val, %len
  br i1 %past_end, label %done, label %body

body:
  %elem_ptr = getelementptr %row_t, %row_t* %row, i32 0, i32 1, i64 %i_val
  %elem = load i64, i64* %elem_ptr
  %acc_val = load i64, i64* %acc
  %new_acc = add i64 %acc_val, %elem
  store i64 %new_acc, i64* %acc
  %i_next = add i64 %i_val, 1
  store i64 %i_next, i64* %i
  br label %cond

done:
  %total = load i64, i64* %acc
  ret i64 %total
}

define i64 @main(i64 %argc, i8** %argv) {
  %arg1_ptr = getelementptr i8*, i8** %argv, i64 1
  %arg1 = load i8*, i8** %arg1_ptr
  %n = call i64 @atoi(i8* %arg1)

  ; allocate two row_t structs, prev and cur
  %prev = alloca %row_t
  %cur = alloca %row_t

  ; prev.len = 0, prev.data[0] = 1 (row 0 = [1])
  %prev_len_ptr = getelementptr %row_t, %row_t* %prev, i32 0, i32 0
  store i64 0, i64* %prev_len_ptr
  %prev_first = getelementptr %row_t, %row_t* %prev, i32 0, i32 1, i64 0
  store i64 1, i64* %prev_first

  ; if n == 0, we are are done
  %is_zero = icmp eq i64 %n, 0
  br i1 %is_zero, label %finish, label %loop_init

loop_init:
  %i = alloca i64
  store i64 1, i64* %i
  br label %loop_cond

loop_cond:
  %i_val = load i64, i64* %i
  %i_past_n = icmp sgt i64 %i_val, %n
  br i1 %i_past_n, label %loop_done, label %loop_body

loop_body:
  ; build row i into cur from prev, then updates cur.len
  call void @build_row(%row_t* %prev, %row_t* %cur, i64 %i_val)
  %cur_len_ptr = getelementptr %row_t, %row_t* %cur, i32 0, i32 0
  store i64 %i_val, i64* %cur_len_ptr

  ; copy cur into prev for next iteration
  %copy_i = alloca i64
  store i64 0, i64* %copy_i
  br label %copy_cond

copy_cond:
  %copy_i_val = load i64, i64* %copy_i
  %copy_done = icmp sgt i64 %copy_i_val, %i_val
  br i1 %copy_done, label %copy_end, label %copy_body

copy_body:
  %src_ptr = getelementptr %row_t, %row_t* %cur, i32 0, i32 1, i64 %copy_i_val
  %src_val = load i64, i64* %src_ptr
  %dst_ptr = getelementptr %row_t, %row_t* %prev, i32 0, i32 1, i64 %copy_i_val
  store i64 %src_val, i64* %dst_ptr
  %copy_i_next = add i64 %copy_i_val, 1
  store i64 %copy_i_next, i64* %copy_i
  br label %copy_cond

copy_end:
  ; also update prev.len
  store i64 %i_val, i64* %prev_len_ptr
  %i_next = add i64 %i_val, 1
  store i64 %i_next, i64* %i
  br label %loop_cond

loop_done:
  %ans = call i64 @sum_row(%row_t* %prev)
  %ans_str = call i8* @ll_ltoa(i64 %ans)
  call void @ll_puts(i8* %ans_str)
  ret i64 0

finish:
  %ans0 = call i64 @sum_row(%row_t* %prev)
  %ans0_str = call i8* @ll_ltoa(i64 %ans0)
  call void @ll_puts(i8* %ans0_str)
  ret i64 0
}
