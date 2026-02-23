; Find the first, up to, 10 divisors of a positive number (not 0)
; stores the first 10 divisors in an array and then 
; prints them

declare i64 @atoi(i8*)
declare i8* @ll_ltoa(i64)
declare void @ll_puts(i8*)

@divisors = global [10 x i64] [i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0]

; Returns 1 if a is divisible by b and 0 otherwise
define i1 @is_divisible(i64 %a, i64 %b) {

  %cur = alloca i64
  store i64 %a, i64* %cur
  br label %divisLoopGuard

; Compare cur with 0
divisLoopGuard:
  %cur_val = load i64, i64* %cur
  %continue = icmp sgt i64 %cur_val, 0

  br i1 %continue, label %divisLoop, label %divisFinish

; cur -= divider
divisLoop:
  %t1 = load i64, i64* %cur
  %t2 = sub i64 %t1, %b
  store i64 %t2, i64* %cur
  br label %divisLoopGuard

; if cur == 0 return 1, else 0
divisFinish:
  %final_val = load i64, i64* %cur
  %is_divis = icmp eq i64 %final_val, 0

  br i1 %is_divis, label %exitGood, label %exitBad

exitGood:
  ret i1 1

exitBad:
  ret i1 0

}


define i64 @main(i64 %argc, i8** %argv) {

  %print_idx = alloca i64
  store i64 0, i64* %print_idx

  %counter = alloca i64
  store i64 0, i64* %counter

  %arr_idx = alloca i64
  store i64 0, i64* %arr_idx

  %target_str_ptr = getelementptr i8*, i8** %argv, i32 1
  %target_str = load i8*, i8** %target_str_ptr
  %target = call i64 @atoi(i8* %target_str)

  br label %countLoopGuard


countLoopGuard:
  ; increment counter
  %old_counter_val = load i64, i64* %counter
  %new_counter_val = add i64 %old_counter_val, 1
  store i64 %new_counter_val, i64* %counter

  ; check if counter <= target
  %counter_cnd = icmp sle i64 %new_counter_val, %target

  ; check if idx < 10
  %arr_idx_val = load i64, i64* %arr_idx
  %arr_cnd = icmp slt i64 %arr_idx_val, 10

  ; check if counter <= target AND idx < 10
  %combined_cnd = and i1 %counter_cnd, %arr_cnd
  br i1 %combined_cnd, label %countLoop, label %printLoop


countLoop:
  ; check if divisible
  %is_div = call i1 @is_divisible(i64 %target, i64 %new_counter_val)
  br i1 %is_div, label %found_divisor, label %countLoopGuard

found_divisor:

  ; divisors[arr_idx_val] = new_counter_val
  %arr_pos = getelementptr [10 x i64], [10 x i64]* @divisors, i64 0, i64 %arr_idx_val
  store i64 %new_counter_val, i64* %arr_pos
  
  ; arr_idx++
  %new_arr_idx_val = add i64 %arr_idx_val, 1
  store i64 %new_arr_idx_val, i64* %arr_idx

  br label %countLoopGuard


printLoop:
  ; i = 0
  %i = load i64, i64* %print_idx
  
  ; print(divisors[i])
  %curr_divisor_ptr = getelementptr [10 x i64], [10 x i64]* @divisors, i64 0, i64 %i
  %curr_divisor = load i64, i64* %curr_divisor_ptr
  %curr_divisor_str = call i8* @ll_ltoa(i64 %curr_divisor)
  call void @ll_puts(i8* %curr_divisor_str)

  ; i++
  %new_i = add i64 %i, 1
  store i64 %new_i, i64* %print_idx
  
  ; i < arr_idx 
  %last_arr_idx = load i64, i64* %arr_idx
  %continue_print = icmp slt i64 %new_i, %last_arr_idx

  br i1 %continue_print, label %printLoop, label %exit


exit:
  ret i64 0

}