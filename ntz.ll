; Count # of trailing zeros
; Algorithm from Hacker's Delight by Henry S. Warren, Jr (Fig 5-23).

define i64 @main(i64 %argc, i8** %argv) {
  %count = alloca i64
  %x = alloca i64
  store i64 0, i64* %count

  %input = add i64 320, 0 ; hard-coded input
  %not_in = xor i64 %input, -1
  %in_minus_1 = sub i64 %input, 1
  %init = and i64 %not_in, %in_minus_1

  ; init = ~in & (in - 1).  This operation effectively flips the
  ; trailing 0's of in, and zeros out all other bits.

  store i64 %init, i64* %x
  br label %loop
loop:
  %old_x = load i64, i64* %x
  %old_count = load i64, i64* %count
  %is_zero = icmp eq i64 %old_x, 0
  br i1 %is_zero, label %exit, label %body
 
body:
  %new_x = lshr i64 %old_x, 1
  %new_count = add i64 %old_count, 1
  store i64 %new_count, i64* %count
  store i64 %new_x, i64* %x
  br label %loop

exit:
  ret i64 %old_count
}