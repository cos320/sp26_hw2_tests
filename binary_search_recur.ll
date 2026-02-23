; Author: Arnav Ambre, recursive binary search
; Takes in a list of up to 10 sorted numbers as well as a target number and
; checks to see if the target number is present in the list using recursive
; binary search.

declare void @ll_puts(i8*)
declare i64 @atoi(i8*)

; Array to be sorted, will be populated with user arguments and must be sorted
@arr = global [10 x i64] [i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0]
@error = global [55 x i8] c"Please input the target number, and then 1-10 numbers!\00"
@welcome = global [35 x i8] c"Running recursive binary search...\00"
@found = global [18 x i8] c"Target was found!\00"
@not_found = global [24 x i8] c"Target was not found...\00"
@input_not_sorted = global [35 x i8] c"Input array not in sorted order...\00"

; Helper recursive function to run binary search for the target integer in arr.
define i1 @binary_search_recur(i64 %left, i64 %right, i64 %target) {
  %left_gt_right = icmp sgt i64 %left, %right
  br i1 %left_gt_right, label %target_not_found, label %run_recur
run_recur:
  %diff = sub i64 %right, %left
  %half_diff = ashr i64 %diff, 1
  %mid = add i64 %left, %half_diff

  %curr_elem_ptr = getelementptr [10 x i64], [10 x i64]* @arr, i32 0, i64 %mid
  %curr_elem = load i64, i64* %curr_elem_ptr

  ; Check if the current middle element equals the target.
  %curr_elem_eq_target = icmp eq i64 %curr_elem, %target
  br i1 %curr_elem_eq_target, label %target_found, label %consider_right
consider_right:
  %curr_elem_lt_target = icmp slt i64 %curr_elem, %target
  br i1 %curr_elem_lt_target, label %recur_right, label %recur_left
recur_right:
  ; Recurse on the right subarray.
  %next_left = add i64 %mid, 1
  %result_right_half = call i1 @binary_search_recur(i64 %next_left, i64 %right, i64 %target)
  ret i1 %result_right_half
recur_left:
  ; Recurse on the left subarray.
  %next_right = sub i64 %mid, 1
  %result_left_half = call i1 @binary_search_recur(i64 %left, i64 %next_right, i64 %target)
  ret i1 %result_left_half
target_not_found:
  ret i1 0
target_found:
  ret i1 1
}

; Starts the recursive binary search for the target integer in arr.
define i1 @binary_search(i64 %target, i64 %num_elements) {
  %max_idx = sub i64 %num_elements, 1
  %target_found = call i1 @binary_search_recur(i64 0, i64 %max_idx, i64 %target)

  ret i1 %target_found
}

define i64 @main(i64 %argc, i8** %argv) {
  ; Check if the user passed in too many arguments.
  %too_many_args = icmp sgt i64 %argc, 12
  br i1 %too_many_args, label %invalid_input, label %else
invalid_input:
  %error_ptr = getelementptr [55 x i8], [55 x i8]* @error, i32 0, i32 0
  call void @ll_puts(i8* %error_ptr)
  ret i64 0
else:
  ; Check if the user passed in too few arguments.
  %too_few_args = icmp slt i64 %argc, 3
  br i1 %too_few_args, label %invalid_input, label %good_input
good_input:
  %welcome_ptr = getelementptr [35 x i8], [35 x i8]* @welcome, i32 0, i32 0
  call void @ll_puts(i8* %welcome_ptr)

  ; Get the target
  %target_string_ptr = getelementptr i8*, i8** %argv, i32 1
  %target_string = load i8*, i8** %target_string_ptr
  %target = call i64 @atoi(i8* %target_string)

  ; Number of array elements
  %num_elements = sub i64 %argc, 2

  ; Iterate through the array passed in
  %first_arg_ptr = getelementptr i8*, i8** %argv, i64 2
  %first_arg = load i8*, i8** %first_arg_ptr
  %prev_arg_int = call i64 @atoi(i8* %first_arg)

  %arg_idx_ptr = alloca i64
  store i64 1, i64* %arg_idx_ptr
  br label %store_arr_elements
store_arr_elements:
  %arg_idx_prev = load i64, i64* %arg_idx_ptr
  %arg_idx = add i64 %arg_idx_prev, 1
  store i64 %arg_idx, i64* %arg_idx_ptr

  %curr_arg_ptr = getelementptr i8*, i8** %argv, i64 %arg_idx
  %curr_arg = load i8*, i8** %curr_arg_ptr
  %curr_arg_int = call i64 @atoi(i8* %curr_arg)

  ; Check if the array is in sorted order so far. If not, print an error msg.
  %curr_arg_ge_prev_arg = icmp sge i64 %curr_arg_int, %prev_arg_int
  br i1 %curr_arg_ge_prev_arg, label %put_arg_in_arr, label %args_not_sorted
put_arg_in_arr:
  %arr_idx = sub i64 %arg_idx, 2
  %curr_arr_ptr = getelementptr [10 x i64], [10 x i64]* @arr, i32 0, i64 %arr_idx
  store i64 %curr_arg_int, i64* %curr_arr_ptr

  %num_elements_added = add i64 %arr_idx, 1
  %all_elems_added = icmp eq i64 %num_elements_added, %num_elements
  br i1 %all_elems_added, label %run_search, label %store_arr_elements
run_search:
  ; Run the binary search on the array for the target element.
  %target_found = call i1 @binary_search(i64 %target, i64 %num_elements)
  br i1 %target_found, label %print_target_found, label %print_target_not_found
args_not_sorted:
  %input_not_sorted_ptr = getelementptr [35 x i8], [35 x i8]* @input_not_sorted, i32 0, i32 0
  call void @ll_puts(i8* %input_not_sorted_ptr)
  br label %exit
print_target_found:
  %found_ptr = getelementptr [18 x i8], [18 x i8]* @found, i32 0, i32 0
  call void @ll_puts(i8* %found_ptr)
  br label %exit
print_target_not_found:
  %not_found_ptr = getelementptr [24 x i8], [24 x i8]* @not_found, i32 0, i32 0
  call void @ll_puts(i8* %not_found_ptr)
  br label %exit
exit:
  ret i64 0
}