; determine parity of input number with mutual recursion
; expects an index 0 through 6 as input
; return 1 for odd, 0 for even; -1 for invalid argument

@nums = global [7 x i64] [i64 0, i64 1, i64 2, i64 4, i64 5, i64 7, i64 50]

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
  %index = call i64 @atoi(i8* %arg)
  ; index must be within bounds [0, 6] of nums global array
  %index_neg = icmp slt i64 %index, 0
  %index_large = icmp sge i64 %index, 7
  %out_of_bounds = or i1 %index_neg, %index_large
  br i1 %out_of_bounds, label %invalid, label %valid
valid:
  %val_ptr = getelementptr [7 x i64], [7 x i64]* @nums, i64 0, i64 %index
  %n = load i64, i64* %val_ptr
  %parity = call i64 @is_even(i64 %n)
  %parity_str = call i8* @ll_ltoa(i64 %parity)
  call void @ll_puts(i8* %parity_str)
  ret i64 %parity
}
