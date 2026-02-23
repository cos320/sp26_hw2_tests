; hw2wh test: largest element in an array
; Uses argv as array of string args; parses each with atoi and finds max.

declare i64 @atoi(i8*)
declare i8* @ll_ltoa(i64)
declare void @ll_puts(i8*)

; Helper: return the larger of two i64 values.
define i64 @max_i64(i64 %a, i64 %b) {
  %a_ge_b = icmp sge i64 %a, %b
  br i1 %a_ge_b, label %return_a, label %return_b
return_a:
  ret i64 %a
return_b:
  ret i64 %b
}

define i64 @main(i64 %argc, i8** %argv) {
  %i = alloca i64
  %max = alloca i64

  %need_args = icmp slt i64 %argc, 2
  br i1 %need_args, label %no_input, label %init

no_input:
  ; optional: we print 0 as "no elements"
  %zero_str = call i8* @ll_ltoa(i64 0)
  call void @ll_puts(i8* %zero_str)
  ret i64 0

init:
  ; max = atoi(argv[1]), i = 2
  %argv_1_ptr = getelementptr i8*, i8** %argv, i64 1
  %arg1 = load i8*, i8** %argv_1_ptr
  %first = call i64 @atoi(i8* %arg1)
  store i64 %first, i64* %max
  store i64 2, i64* %i
  br label %loop

loop:
  %cur_i = load i64, i64* %i
  %done = icmp sge i64 %cur_i, %argc
  br i1 %done, label %exit_loop, label %body

body:
  ; elem = atoi(argv[cur_i])
  %arg_i_ptr = getelementptr i8*, i8** %argv, i64 %cur_i
  %arg_i = load i8*, i8** %arg_i_ptr
  %elem = call i64 @atoi(i8* %arg_i)
  ; max = max_i64(max, elem)
  %old_max = load i64, i64* %max
  %new_max = call i64 @max_i64(i64 %old_max, i64 %elem)
  store i64 %new_max, i64* %max
  %next_i = add i64 %cur_i, 1
  store i64 %next_i, i64* %i
  br label %loop

exit_loop:
  %result = load i64, i64* %max
  %result_str = call i8* @ll_ltoa(i64 %result)
  call void @ll_puts(i8* %result_str)
  ret i64 0
}
