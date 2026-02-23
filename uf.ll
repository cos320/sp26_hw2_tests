; Jishnu Roychoudhury (team: Colin)
; Union find with path compression but no union by rank
; Takes pairs of elements as args, unions them, then prints root of each 0..7

declare i8* @ll_ltoa(i64)
declare i64 @atoi(i8*)
declare void @ll_puts(i8*)
declare void @puts(i8*)

@parent = global [8 x i64] [i64 0, i64 1, i64 2, i64 3, i64 4, i64 5, i64 6, i64 7]
@error = global [26 x i8] c"pairs of elements please!\00"

; find root of x, then compress the path from x to root
define i64 @find(i64 %x) {
  %cur_ptr = alloca i64
  store i64 %x, i64* %cur_ptr
  br label %loop
loop:
  %cur = load i64, i64* %cur_ptr
  %parent_ptr = getelementptr [8 x i64], [8 x i64]* @parent, i32 0, i64 %cur
  %parent_val = load i64, i64* %parent_ptr
  ; cur == parent[cur] means we found the root
  %is_root = icmp eq i64 %cur, %parent_val
  br i1 %is_root, label %compress_setup, label %go_up

go_up:
  store i64 %parent_val, i64* %cur_ptr
  br label %loop

compress_setup:
  ; walk from x back to root, flattening every node to point at root
  %root = load i64, i64* %cur_ptr
  %walk_ptr = alloca i64
  store i64 %x, i64* %walk_ptr
  br label %compress
compress:
  %walk = load i64, i64* %walk_ptr
  %cond = icmp eq i64 %walk, %root
  br i1 %cond, label %done, label %do_compress

do_compress:
  %walk_parent_ptr = getelementptr [8 x i64], [8 x i64]* @parent, i32 0, i64 %walk
  ; save old parent, set parent[walk] = root, advance to old parent
  %old_parent = load i64, i64* %walk_parent_ptr
  store i64 %root, i64* %walk_parent_ptr
  store i64 %old_parent, i64* %walk_ptr
  br label %compress

done:
  ret i64 %root
}

; parent[find(y)] = find(x), no rank
define void @union(i64 %x, i64 %y) {
  %root_x = call i64 @find(i64 %x)
  %root_y = call i64 @find(i64 %y)
  %same = icmp eq i64 %root_x, %root_y
  br i1 %same, label %exit, label %do_union

do_union:
  %root_y_ptr = getelementptr [8 x i64], [8 x i64]* @parent, i32 0, i64 %root_y
  store i64 %root_x, i64* %root_y_ptr
  br label %exit

exit:
  ret void
}

define i64 @main(i64 %argc, i8** %argv) {
  ; reject odd number of args
  %num_args = sub i64 %argc, 1
  %low_bit = and i64 %num_args, 1
  %1 = icmp eq i64 %low_bit, 1
  br i1 %1, label %invalid, label %start
invalid:
  %2 = getelementptr [26 x i8], [26 x i8]* @error, i32 0, i32 0
  call void @ll_puts(i8* %2)
  ret i64 1

start:
  ; read pairs of args and union them
  %i_ptr = alloca i64
  store i64 1, i64* %i_ptr
  br label %union_loop
union_loop:
  %i = load i64, i64* %i_ptr
  %cond = icmp sgt i64 %i, %num_args
  br i1 %cond, label %print_setup, label %do_pair

do_pair:
  %a_ptr = getelementptr i8*, i8** %argv, i64 %i
  %a_str = load i8*, i8** %a_ptr
  %a = call i64 @atoi(i8* %a_str)
  %i_plus_one = add i64 %i, 1
  %b_ptr = getelementptr i8*, i8** %argv, i64 %i_plus_one
  %b_str = load i8*, i8** %b_ptr
  %b = call i64 @atoi(i8* %b_str)
  call void @union(i64 %a, i64 %b)
  ; advance by 2 to next pair
  %i_new = add i64 %i, 2
  store i64 %i_new, i64* %i_ptr
  br label %union_loop

print_setup:
  ; print root of each element 0..7
  store i64 0, i64* %i_ptr
  br label %print_loop
print_loop:
  %i2 = load i64, i64* %i_ptr
  %current_root = call i64 @find(i64 %i2)
  %current_root_str = call i8* @ll_ltoa(i64 %current_root)
  call void @puts(i8* %current_root_str)
  %i2_new = add i64 %i2, 1
  store i64 %i2_new, i64* %i_ptr
  %cond2 = icmp eq i64 %i2_new, 8
  br i1 %cond2, label %exit, label %print_loop

exit:
  ret i64 0
}
