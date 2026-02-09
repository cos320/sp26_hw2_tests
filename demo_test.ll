declare void @ll_puts(i8*)

; Print arguments in reverse order
define i64 @main(i64 %argc, i8** %argv) {
  ; allocate storage for an index into the argv array, starting at the end
  %counter = alloca i64
  store i64 %argc, i64* %counter
  br label %loop

loop:
  ; decrement counter
  %old_counter_val = load i64, i64* %counter
  %counter_val = sub i64 %old_counter_val, 1
  store i64 %counter_val, i64* %counter

  ; print argument at counter position
  %arg_pos = getelementptr i8*, i8** %argv, i64 %counter_val
  %arg = load i8*, i8** %arg_pos
  call i64 @ll_puts(i8* %arg)

  %done = icmp sgt i64 %counter_val, 1
  br i1 %done, label %loop, label %exit

exit:
  ret i64 0
}