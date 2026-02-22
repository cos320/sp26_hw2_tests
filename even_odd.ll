; determine parity of input number with mutual recursion
; expects one non-negative integer as input
; return 1 for odd, 0 for even; -1 for invalid argument (no argument or negative)

declare i64 @atoi(i8*)
declare i8* @ll_ltoa(i64)
declare void @ll_puts(i8*)

define i64 @is_even(i64 %n) {
  %eq_zero = icmp eq i64 %n, 0
  br i1 %eq_zero, label %is_even, label %recurse_odd
is_even:
  ret i64 0
recurse_odd:
  %r = sub i64 %n, 1
  %parity = call i64 @is_odd(i64 %r)
  ret i64 %parity
}

define i64 @is_odd(i64 %n) {
  %eq_zero = icmp eq i64 %n, 0
  br i1 %eq_zero, label %is_odd, label %recurse_even
is_odd:
  ret i64 1
recurse_even:
  %r = sub i64 %n, 1
  %parity = call i64 @is_even(i64 %r)
  ret i64 %parity
}

define i64 @main(i64 %argc, i8** %argv) {
  %has_arg = icmp sge i64 %argc, 2
  br i1 %has_arg, label %process_arg, label %invalid
invalid:
  %output_str = call i8* @ll_ltoa(i64 -1)
  call void @ll_puts(i8* %output_str)
  ret i64 -1
process_arg:
  %arg_ptr = getelementptr i8*, i8** %argv, i64 1
  %arg = load i8*, i8** %arg_ptr
  %n = call i64 @atoi(i8* %arg)
  %negative = icmp slt i64 %n, 0
  br i1 %negative, label %invalid, label %valid
valid:
  %parity = call i64 @is_even(i64 %n)
  %parity_str = call i8* @ll_ltoa(i64 %parity)
  call void @ll_puts(i8* %parity_str)
  ret i64 %parity
}
