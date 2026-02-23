%list = type {%list*, i8*}

declare i8* @ll_malloc(i64, i64)

declare void @ll_puts(i8*)

declare i64 @strcmp(i8*, i8*)


define %list* @add(%list* %head, i8* %value) {
    %new = call i8* @ll_malloc(i64 1, i64 16)
    %new_list = bitcast i8* %new to %list*
    %new_list_next_ptr = getelementptr %list, %list* %new_list, i32 0, i32 0
    %new_list_value_ptr = getelementptr %list, %list* %new_list, i32 0, i32 1
    store %list* %head, %list** %new_list_next_ptr
    store i8* %value, i8** %new_list_value_ptr
    ret %list* %new_list
}

define i1 @search(%list* %head, i8* %value) {
    %is_null = icmp eq %list* %head, null
    br i1 %is_null, label %end, label %normal
    end:
        ret i1 0
    normal:
        %head_val_ptr = getelementptr %list, %list* %head, i32 0, i32 1
        %head_val = load i8*, i8** %head_val_ptr
        %res = call i64 @strcmp(i8* %head_val, i8* %value)
        %res_is_zero = icmp eq i64 %res, 0
        br i1 %res_is_zero, label %found, label %not_found
    found:
        ret i1 1
    not_found:
        %head_next_ptr = getelementptr %list, %list* %head, i32 0, i32 0
        %head_next = load %list*, %list** %head_next_ptr
        %answer = call i1 @search(%list* %head_next, i8* %value)
        ret i1 %answer
}

@s0 = global [10 x i8] c"seventeen\00"
@s1 = global [9 x i8] c"daybreak\00"
@s2 = global [8 x i8] c"furnace\00"
@s3 = global [5 x i8] c"nine\00"
@s4 = global [7 x i8] c"benign\00"
@s5 = global [11 x i8] c"homecoming\00"
@s6 = global [4 x i8] c"one\00"

@found = global [7 x i8] c"found!\00"
@not_found = global [10 x i8] c"not found\00"


define i64 @main(i64 %argc, i8** %argv) {
    %arg_1_ptr = getelementptr i8*, i8** %argv, i32 1
    %arg_1 = load i8*, i8** %arg_1_ptr
    %s0_ptr = bitcast [10 x i8]* @s0 to i8*
    %list_1 = call %list* @add(%list* null, i8* %s0_ptr)
    %s1_ptr = bitcast [9 x i8]* @s1 to i8*
    %list_2 = call %list* @add(%list* %list_1, i8* %s1_ptr)
    %s2_ptr = bitcast [8 x i8]* @s2 to i8*
    %list_3 = call %list* @add(%list* %list_2, i8* %s2_ptr)
    %s3_ptr = bitcast [5 x i8]* @s3 to i8*
    %list_4 = call %list* @add(%list* %list_3, i8* %s3_ptr)
    %s4_ptr = bitcast [7 x i8]* @s4 to i8*
    %list_5 = call %list* @add(%list* %list_4, i8* %s4_ptr)
    %s5_ptr = bitcast [11 x i8]* @s5 to i8*
    %list_6 = call %list* @add(%list* %list_5, i8* %s5_ptr)
    %s6_ptr = bitcast [4 x i8]* @s6 to i8*
    %list_7 = call %list* @add(%list* %list_6, i8* %s6_ptr)
    %out = call i1 @search(%list* %list_7, i8* %arg_1)
    br i1 %out, label %found, label %not_found 
    found:
        %output1 = bitcast [7 x i8]* @found to i8*
        call void @ll_puts(i8* %output1)
        ret i64 0
    not_found:
        %output2 = bitcast [10 x i8]* @not_found to i8*
        call void @ll_puts(i8* %output2)
        ret i64 1
}