; Raheem Idowu (satsuma test)
; Take in a list of up to 15 numbers and print them out in sorted order
; Uses lists, a helper function (sort) and a nested loop (bubble sort)

declare void @ll_puts(i8*)
declare i8* @ll_ltoa(i64)
declare i64 @atoi(i8*)
declare void @puts(i8*)

@data = global [15 x i64] [i64 10, i64 -5, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0]
@error = global [24 x i8] c"1 to 15 numbers please!\00"
@welcome = global [22 x i8] c"Sorting your numbers!\00"

define void @swap(i64* %a, i64* %b) {
  %a_val = load i64, i64* %a
  %b_val = load i64, i64* %b
  store i64 %a_val, i64* %b
  store i64 %b_val, i64* %a
  ret void
}

define void @sort(i64 %sz) {
  %sz_minus_one = sub i64 %sz, 1
  %swapped_ptr = alloca i64
  %i_ptr = alloca i64
  br label %outer_loop
outer_loop:
  store i64 0, i64* %i_ptr
  store i64 0, i64* %swapped_ptr
  br label %loop
loop:
  %i = load i64, i64* %i_ptr
  
  %i_plus_one = add i64 %i, 1
  %a = getelementptr [15 x i64], [15 x i64]* @data, i32 0, i64 %i
  %b = getelementptr [15 x i64], [15 x i64]* @data, i32 0, i64 %i_plus_one
  %a_val = load i64, i64* %a
  %b_val = load i64, i64* %b
  %should_swap = icmp sgt i64 %a_val, %b_val
  br i1 %should_swap, label %do_swap, label %after_swap

do_swap:
  call void @swap(i64* %a, i64* %b) 
  store i64 1, i64* %swapped_ptr
  br label %after_swap

after_swap:
  %i_new = add i64 %i, 1
  store i64 %i_new, i64* %i_ptr
  %cond2 = icmp eq i64 %i_new, %sz_minus_one
  br i1 %cond2, label %finish_outer_loop, label %loop

finish_outer_loop:
  %swapped = load i64, i64* %swapped_ptr
  %cond3 = icmp eq i64 %swapped, 1
  br i1 %cond3, label %outer_loop, label %exit

exit:
  ret void
}

define i64 @main(i64 %argc, i8** %argv) {
  %1 = icmp sgt i64 %argc, 16
  br i1 %1, label %invalid, label %else
invalid:
  %2 = getelementptr [24 x i8], [24 x i8]* @error, i32 0, i32 0
  call void @ll_puts(i8* %2)
  ret i64 0
else:
  %3 = icmp eq i64 %argc, 1 
  br i1 %3, label %invalid, label %good
good:
  %4 = getelementptr [22 x i8], [22 x i8]* @welcome, i32 0, i32 0
  call void @ll_puts(i8* %4)
  
  %count = sub i64 %argc, 1

  ; Iterate through all of them
  %i_ptr = alloca i64
  store i64 0, i64* %i_ptr
  br label %cast_loop
cast_loop:
  %i_old = load i64, i64* %i_ptr
  %i = add i64 %i_old, 1
  store i64 %i, i64* %i_ptr

  %current_string_ptr = getelementptr i8*, i8** %argv, i64 %i
  %current_string = load i8*, i8** %current_string_ptr
  %current_string_int = call i64 @atoi(i8* %current_string)
  
  %array_index = sub i64 %i, 1
  %current_array_ptr = getelementptr [15 x i64], [15 x i64]* @data, i32 0, i64 %array_index
  store i64 %current_string_int, i64* %current_array_ptr

  %cond = icmp eq i64 %i, %count
  br i1 %cond, label %setup_print_loop, label %cast_loop
setup_print_loop:
  call void @sort(i64 %count)
  store i64 0, i64* %i_ptr
  br label %print_loop
print_loop:
  
  %i2 = load i64, i64* %i_ptr

  %current_number_ptr = getelementptr [15 x i64], [15 x i64]* @data, i32 0, i64 %i2
  %current_number = load i64, i64* %current_number_ptr
  %current_number_str = call i8* @ll_ltoa(i64 %current_number)
  call void @puts(i8* %current_number_str)

  %i_new = add i64 %i2, 1
  store i64 %i_new, i64* %i_ptr
  
  %cond2 = icmp eq i64 %i_new, %count
  br i1 %cond2, label %exit, label %print_loop
exit:
  ret i64 0
}
