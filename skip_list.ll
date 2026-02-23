; Authors: Ben Aepli and Vedant Badoni
; Provides an implementation of a skip list.
; Tests by inserting a lot of integers and then removing them.

%Node = type {
    i8*, ; data
    %Node*, ; next
    %Node* ; down
}

; Returns a negative number if the first argument is less than the second argument,
; Returns 0 for equality, and a positive number if the first argument is greater.
; Requires transitivity of equality to avoid leaking.
%CompareFunc = type i64(i8*, i8*)*

%SkipList = type {
    %CompareFunc,
    %Node*, ; head
    i64, ; levels
    %Node**, ; searchArray
    i64 ; random
}

declare i64* @ll_malloc(i64, i64)
declare void @ll_puts(i8*)
declare i8* @ll_ltoa(i64)
declare void @free(i8*)
declare i64 @atoi(i8*)

define i64 @skipList_impl_safeCompare(%CompareFunc %func, i8* %nodeData, i8* %searchKey) {
    %cmp = icmp eq i8* %nodeData, null
    br i1 %cmp, label %safe, label %normal
safe:
    ret i64 -1
normal:
    %1 = call i64 %func(i8* %nodeData, i8* %searchKey)
    ret i64 %1
}

define i64 @skipList_impl_xorshift64(i64 %input) {
    %state = alloca i64
    store i64 %input, i64* %state
    ; state ^= state << 13
    %shift1 = shl i64 %input, 13
    %val1 = xor i64 %input, %shift1
    ; state ^= state >> 7
    %shift2 = lshr i64 %val1, 7
    %val2 = xor i64 %val1, %shift2
    ; state ^= state << 17
    %shift3 = shl i64 %val2, 17
    %val3 = xor i64 %val2, %shift3
    ret i64 %val3
}

define i64 @skipList_impl_nodeSize() {
    %sizePtr = getelementptr %Node, %Node* null, i32 1
    %sizeStored = alloca %Node*
    store %Node* %sizePtr, %Node** %sizeStored
    %casted = bitcast %Node** %sizeStored to i64*
    %size = load i64, i64* %casted
    ret i64 %size
}

; allocates a new node. note: ll_malloc uses calloc, so this is zero initialized.
define %Node* @skipList_impl_allocNode() {
    %size = call i64 @skipList_impl_nodeSize()
    %ptr = call i64* @ll_malloc(i64 1, i64 %size)
    %result = bitcast i64* %ptr to %Node*
    ret %Node* %result
}

define %SkipList* @skipList_impl_allocList() {
    %sizePtr = getelementptr %SkipList, %SkipList* null, i32 1
    %sizeStored = alloca %SkipList*
    store %SkipList* %sizePtr, %SkipList** %sizeStored
    %casted = bitcast %SkipList** %sizeStored to i64*
    %size = load i64, i64* %casted

    %ptr = call i64* @ll_malloc(i64 1, i64 %size)
    %result = bitcast i64* %ptr to %SkipList*
    ret %SkipList* %result
}

; Allocates the search array for a given list.
define void @skipList_impl_allocLevels(%SkipList* %list) {
    %levelsAddress = getelementptr %SkipList, %SkipList* %list, i32 0, i32 2
    %levels = load i64, i64* %levelsAddress
    %ptr = call i64* @ll_malloc(i64 %levels, i64 8)
    %result = bitcast i64* %ptr to %Node**
    %searchArrayAddress = getelementptr %SkipList, %SkipList* %list, i32 0, i32 3

    %old = load %Node**, %Node*** %searchArrayAddress
    %oldCast = bitcast %Node** %old to i8*
    call void @free(i8* %oldCast)

    store %Node** %result, %Node*** %searchArrayAddress
    ret void
}

; Initializes a skip list using a comparison function.
define %SkipList* @skipList_init(%CompareFunc %compareFunc) {
    %sentinel = call %Node* @skipList_impl_allocNode()

    %addressStored = alloca %Node*
    store %Node* %sentinel, %Node** %addressStored
    %addressPtr = bitcast %Node** %addressStored to i64*
    %seed = load i64, i64* %addressPtr
    %initial = call i64 @skipList_impl_xorshift64(i64 %seed)

    %list = call %SkipList* @skipList_impl_allocList()
    %compareAddress = getelementptr %SkipList, %SkipList* %list, i32 0, i32 0
    store %CompareFunc %compareFunc, %CompareFunc* %compareAddress
    %headAddress = getelementptr %SkipList, %SkipList* %list, i32 0, i32 1
    store %Node* %sentinel, %Node** %headAddress
    %levelsAddress = getelementptr %SkipList, %SkipList* %list, i32 0, i32 2
    store i64 1, i64* %levelsAddress
    %randomAddress = getelementptr %SkipList, %SkipList* %list, i32 0, i32 4
    store i64 %initial, i64* %randomAddress
    call void @skipList_impl_allocLevels(%SkipList* %list)

    ret %SkipList* %list
}

; Returns true if the node was found. In this case, puts the corresponding node
; into the found pointer. Sets the traversed levels to the number of
; nodes in the search path that have been populated.
define i1 @skipList_impl_find(%SkipList* %list, i8* %target, %Node** %found, i64* %traversedLevels) {
    %headAddress = getelementptr %SkipList, %SkipList* %list, i32 0, i32 1
    %head = load %Node*, %Node** %headAddress
    %current = alloca %Node*
    store %Node* %head, %Node** %current ; Node* current = list->head;

    %searchArrayAddress = getelementptr %SkipList, %SkipList* %list, i32 0, i32 3
    %searchArray = load %Node**, %Node*** %searchArrayAddress

    %levels = alloca i64
    store i64 0, i64* %levels ; levels = 0

    %next = alloca %Node*
    %comparison = alloca i64

    %compareAddress = getelementptr %SkipList, %SkipList* %list, i32 0, i32 0
    %compareFunc = load %CompareFunc, %CompareFunc* %compareAddress

    store i64 0, i64* %traversedLevels
    store %Node* null, %Node** %found
    br label %outerCondition

outerCondition:
    %1 = load %Node*, %Node** %current
    %2 = icmp eq %Node* %1, null
    br i1 %2, label %outerEnd, label %innerCondition

innerCondition:
    %3 = load %Node*, %Node** %current
    %4  = getelementptr %Node, %Node* %3, i32 0, i32 1
    %5 = load %Node*, %Node** %4
    store %Node* %5, %Node** %next ; next = current->next

    %6 = icmp eq %Node* %5, null
    br i1 %6, label %innerEnd, label %innerSecond

innerSecond:
    %7 = load %Node*, %Node** %next
    %8 = getelementptr %Node, %Node* %7, i32 0, i32 0
    %9 = load i8*, i8** %8
    %10 = call i64 @skipList_impl_safeCompare (%CompareFunc %compareFunc, i8* %9, i8* %target)
    store i64 %10, i64* %comparison

    %11 = icmp eq i64 %10, 0
    br i1 %11, label %innerFound, label %innerThird

innerFound:
    %12 = load %Node*, %Node** %next
    store %Node* %12, %Node** %found ; *found = next
    ret i1 1

innerThird:
    %13 = load i64, i64* %comparison
    %14 = icmp slt i64 %10, 0
    br i1 %14, label %innerFourth, label %innerEnd

innerFourth:
    %15 = load %Node*, %Node** %next
    store %Node* %15, %Node** %current
    br label %innerCondition

innerEnd:
    %16 = load i64, i64* %levels
    %17 = getelementptr %Node*, %Node** %searchArray, i64 %16
    %18 = load %Node*, %Node** %current
    store %Node* %18, %Node** %17 ; searchArray[levels] = current

    %19 = load %Node*, %Node** %current
    %downAddress = getelementptr %Node, %Node* %18, i32 0, i32 2
    %down = load %Node*, %Node** %downAddress
    store %Node* %down, %Node** %current ; current = current->down

    %20 = load i64, i64* %levels
    %21 = add i64 %20, 1
    store i64 %21, i64* %levels ; levels += 1

    store i64 %21, i64* %traversedLevels

    br label %outerCondition

outerEnd:
    ret i1 0
}

; Returns the inserted value that matches the provided comparison function if it exists, or
; nullptr on non-existence.
define i8* @skipList_find(%SkipList* %list, i8* %target) {
    %levels = alloca i64
    %found = alloca %Node*
    %result = call i1 @skipList_impl_find(%SkipList* %list, i8* %target, %Node** %found, i64* %levels)
    br i1 %result, label %ifFound, label %notFound

ifFound:
    %node = load %Node*, %Node** %found
    %dataAddress = getelementptr %Node, %Node* %node, i32 0, i32 0
    %data = load i8*, i8** %dataAddress
    ret i8* %data

notFound:
    ret i8* null
}

; Inserts a value into the skip list, overwriting it if it already exists.
define void @skipList_insert(%SkipList* %list, i8* %value) {
    %searchArrayAddress = getelementptr %SkipList, %SkipList* %list, i32 0, i32 3
    %searchArray = load %Node**, %Node*** %searchArrayAddress

    %levels = alloca i64
    %found = alloca %Node*

    %insertUp = alloca i1
    %downNode = alloca %Node*

    %result = call i1 @skipList_impl_find(%SkipList* %list, i8* %value, %Node** %found, i64* %levels)
    br i1 %result, label %ifFound, label %notFound

ifFound:
    %1 = load %Node*, %Node** %found
    %2 = getelementptr %Node, %Node* %1, i32 0, i32 0
    store i8* %value, i8** %2
    ret void

notFound:
    store i1 1, i1* %insertUp
    store %Node* null, %Node** %downNode

    br label %outerLoop

outerLoop:
    %3 = load i1, i1* %insertUp
    br i1 %3, label %outerSecond, label %outerEnd

outerSecond:
    %4 = load i64, i64* %levels
    %5 = icmp sgt i64 %4, 0
    br i1 %5, label %outerMain, label %outerEnd

outerMain:
     %6 = load i64, i64* %levels
     %7 = sub i64 %6, 1
     store i64 %7, i64* %levels

     %8 = getelementptr %Node*, %Node** %searchArray, i64 %7
     %previous = load %Node*, %Node** %8

     ; new Node(value, previous->next, downNode)
     %newNode = call %Node* @skipList_impl_allocNode()
     %dataAddress = getelementptr %Node, %Node* %newNode, i32 0, i32 0
     store i8* %value, i8** %dataAddress
     %nextAddress = getelementptr %Node, %Node* %newNode, i32 0, i32 1
     %9 = getelementptr %Node, %Node* %previous, i32 0, i32 1
     %10 = load %Node*, %Node** %9
     store %Node* %10, %Node** %nextAddress
     %11 = load %Node*, %Node** %downNode
     %downAddress = getelementptr %Node, %Node* %newNode, i32 0, i32 2
     store %Node* %11, %Node** %downAddress

     %previousNext = getelementptr %Node, %Node* %previous, i32 0, i32 1
     store %Node* %newNode, %Node** %previousNext

     store %Node* %newNode, %Node** %downNode
     %randomAddress = getelementptr %SkipList, %SkipList* %list, i32 0, i32 4
     %12 = load i64, i64* %randomAddress
     %13 = call i64 @skipList_impl_xorshift64(i64 %12)
     store i64 %13, i64* %randomAddress
     %14 = icmp sgt i64 %13, 0
     store i1 %14, i1* %insertUp
     br label %outerLoop

outerEnd:
    %15 = load i1, i1* %insertUp
    br i1 %15, label %createNewHead, label %finalReturn

createNewHead:
    %finalNode = call %Node* @skipList_impl_allocNode()
    %finalData = getelementptr %Node, %Node* %finalNode, i32 0, i32 0
    store i8* %value, i8** %finalData
    %16 = load %Node*, %Node** %downNode
    %finalDown = getelementptr %Node, %Node* %finalNode, i32 0, i32 2
    store %Node* %16, %Node** %finalDown

    %newHead = call %Node* @skipList_impl_allocNode()
    %headNextAddress = getelementptr %Node, %Node* %newHead, i32 0, i32 1
    store %Node* %finalNode, %Node** %headNextAddress
    %listHead = getelementptr %SkipList, %SkipList* %list, i32 0, i32 1
    %oldHead = load %Node*, %Node** %listHead
    %headDownAddress = getelementptr %Node, %Node* %newHead, i32 0, i32 2
    store %Node* %oldHead, %Node** %headDownAddress

    store %Node* %newHead, %Node** %listHead
    %listLevels = getelementptr %SkipList, %SkipList* %list, i32 0, i32 2
    %17 = load i64, i64* %listLevels
    %18 = add i64 %17, 1
    store i64 %18, i64* %listLevels

    call void @skipList_impl_allocLevels(%SkipList* %list)
    br label %finalReturn

finalReturn:
    ret void
}

; Removes a value from the skip list if it exists.
; Returns the removed data.
define i8* @skipList_remove(%SkipList* %list, i8* %value) {
    %compareAddress = getelementptr %SkipList, %SkipList* %list, i32 0, i32 0
    %compareFunc = load %CompareFunc, %CompareFunc* %compareAddress

    %listHead = getelementptr %SkipList, %SkipList* %list, i32 0, i32 1
    %listLevels = getelementptr %SkipList, %SkipList* %list, i32 0, i32 2
    %current = alloca %Node*
    %1 = load %Node*, %Node** %listHead
    store %Node* %1, %Node** %current

    %next = alloca %Node*
    %comparison = alloca i64
    %resultPayload = alloca i8*
    store i8* null, i8** %resultPayload

    %head = alloca %Node*
    %levels = alloca i64

    br label %outerCondition

outerCondition:
    %2 = load %Node*, %Node** %current
    %3 = icmp eq %Node* %2, null
    br i1 %3, label %outerEnd, label %innerCondition

innerCondition:
    %4 = load %Node*, %Node** %current
    %5  = getelementptr %Node, %Node* %4, i32 0, i32 1
    %6 = load %Node*, %Node** %5
    store %Node* %6, %Node** %next
    %7 = icmp eq %Node* %6, null
    br i1 %7, label %innerEnd, label %innerSecond

innerSecond:
    %8 = load %Node*, %Node** %next
    %9 = getelementptr %Node, %Node* %8, i32 0, i32 0
    %10 = load i8*, i8** %9
    %11 = call i64 @skipList_impl_safeCompare (%CompareFunc %compareFunc, i8* %10, i8* %value)
    store i64 %11, i64* %comparison

    %12 = icmp eq i64 %11, 0
    br i1 %12, label %innerFound, label %innerThird

innerFound:
    %13 = load %Node*, %Node** %next
    %nextDataAddress = getelementptr %Node, %Node* %13, i32 0, i32 0
    %nextData = load i8*, i8** %nextDataAddress
    store i8* %nextData, i8** %resultPayload

    %nextNextAddress = getelementptr %Node, %Node* %13, i32 0, i32 1
    %nextNext = load %Node*, %Node** %nextNextAddress
    %14 = load %Node*, %Node** %current
    %currentNextAddress = getelementptr %Node, %Node* %14, i32 0, i32 1
    store %Node* %nextNext, %Node** %currentNextAddress

    %nextCast = bitcast %Node* %13 to i8*
    call void @free(i8* %nextCast)

    br label %innerEnd

innerThird:
    %15 = load i64, i64* %comparison
    %16 = icmp slt i64 %15, 0
    br i1 %16, label %innerFourth, label %innerEnd

innerFourth:
    %17 = load %Node*, %Node** %next
    store %Node* %17, %Node** %current
    br label %innerCondition

innerEnd:
    %18 = load %Node*, %Node** %current
    %19 = getelementptr %Node, %Node* %18, i32 0, i32 2
    %20 = load %Node*, %Node** %19
    store %Node* %20, %Node** %current
    br label %outerCondition

outerEnd:
    %21 = load %Node*, %Node** %listHead
    store %Node* %21, %Node** %head
    %22 = load i64, i64* %listLevels
    store i64 %22, i64* %levels
    br label %levelCondition

levelCondition:
    %23 = load %Node*, %Node** %head
    %headNextAddress = getelementptr %Node, %Node* %23, i32 0, i32 1
    %headNext = load %Node*, %Node** %headNextAddress
    %24 = icmp eq %Node* %headNext, null
    br i1 %24, label %levelSecond, label %levelEnd

levelSecond:
    %25 = load %Node*, %Node** %head
    %headDownAddress = getelementptr %Node, %Node* %25, i32 0, i32 2
    %26 = load %Node*, %Node** %headDownAddress
    %27 = icmp ne %Node* %26, null
    br i1 %27, label %levelMain, label %levelEnd

levelMain:
    %old = load %Node*, %Node** %head
    %28 = getelementptr %Node, %Node* %25, i32 0, i32 2
    %29 = load %Node*, %Node** %28
    store %Node* %29, %Node** %head

    %oldCast = bitcast %Node* %old to i8*
    call void @free(i8* %oldCast)

    %30 = load i64, i64* %levels
    %31 = sub i64 %30, 1
    store i64 %31, i64* %levels
    br label %levelCondition

levelEnd:
    %32 = load %Node*, %Node** %head
    %33 = load i64, i64* %levels
    store %Node* %32, %Node** %listHead
    store i64 %33, i64* %listLevels
    call void @skipList_impl_allocLevels(%SkipList* %list)

    %result = load i8*, i8** %resultPayload
    ret i8* %result
}

define i64 @castFromPointer(i8* %i) {
    %stored = alloca i8*
    store i8* %i, i8** %stored
    %casted = bitcast i8** %stored to i64*
    %size = load i64, i64* %casted
    ret i64 %size
}

define i8* @castToPointer(i64 %i) {
    %stored = alloca i64
    store i64 %i, i64* %stored
    %casted = bitcast i64* %stored to i8**
    %size = load i8*, i8** %casted
    ret i8* %size
}

define i64 @compareInts(i8* %fstPointer, i8* %sndPointer) {
    %fst = call i64 @castFromPointer(i8* %fstPointer)
    %snd = call i64 @castFromPointer(i8* %sndPointer)
    %diff = sub i64 %fst, %snd
    ret i64 %diff
}

@successString = global [9 x i8] c"success!\00"
@errorString = global [11 x i8]  c"failure...\00"

; The first argument to the program must be an integer greater than 10.
define i64 @main(i64 %argc, i8** %argv) {
    %argument = getelementptr i8*, i8** %argv, i32 1
    %count = load i8*, i8** %argument
    %arg = call i64 @atoi(i8* %count)
    %insertCount = mul i64 %arg, 2

    %list = call %SkipList* @skipList_init(%CompareFunc @compareInts)

    %i = alloca i64
    store i64 1, i64* %i
    br label %insertCondition

insertCondition:
    %1 = load i64, i64* %i
    %2 = icmp sle i64 %1, %insertCount
    br i1 %2, label %insertMain, label %insertEnd

insertMain:
    %3 = load i64, i64* %i
    %4 = call i8* @castToPointer(i64 %3)
    call void @skipList_insert(%SkipList* %list, i8* %4)
    %5 = add i64 %3, 1
    store i64 %5, i64* %i
    br label %insertCondition

insertEnd:
    %6 = call i8* @castToPointer(i64 10)
    %found = call i8* @skipList_find(%SkipList* %list, i8* %6)
    %7 = icmp eq i8* %found, null
    br i1 %7, label %failure, label %searchMissing

searchMissing:
    %8 = add i64 %insertCount, 1
    %9 = call i8* @castToPointer(i64 %8)
    %notFound = call i8* @skipList_find(%SkipList* %list, i8* %9)
    %10 = icmp ne i8* %notFound, null
    br i1 %10, label %failure, label %removeAll

removeAll:
    store i64 1, i64* %i
    br label %removeCondition

removeCondition:
    %11 = load i64, i64* %i
    %12 = icmp sle i64 %11, %arg
    br i1 %12, label %removeMain, label %searchRemoved

removeMain:
    %13 = load i64, i64* %i
    %14 = call i8* @castToPointer(i64 %13)
    %ignored = call i8* @skipList_remove(%SkipList* %list, i8* %14)
    %15 = add i64 %13, 1
    store i64 %15, i64* %i
    br label %removeCondition

searchRemoved:
    %16 = call i8* @castToPointer(i64 10)
    %removed = call i8* @skipList_find(%SkipList* %list, i8* %16)
    %17 = icmp ne i8* %removed, null
    br i1 %17, label %failure, label %searchExists

searchExists:
    %18 = add i64 %arg, 2
    %19 = call i8* @castToPointer(i64 %18)
    %stillExists = call i8* @skipList_find(%SkipList* %list, i8* %19)
    %20 = icmp eq i8* %stillExists, null
    br i1 %20, label %failure, label %success

success:
    %successStr = getelementptr [9 x i8], [9 x i8]* @successString, i32 0, i32 0
    call void @ll_puts(i8* %successStr)
    ret i64 0

failure:
    %errorStr = getelementptr [11 x i8], [11 x i8]* @errorString, i32 0, i32 0
    call void @ll_puts(i8* %errorStr)
    ret i64 1
}
