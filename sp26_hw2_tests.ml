open Util.Assert
open X86
open Ll
module Backend = Llbackend.Backend
module Driver = Llbackend.Driver
open Llbackend.Backend

let ex_tests_with_path =
  (* Format: each test is a pair consisting of
     - an LLVM IR file
     - the expected return code
     Note that return codes are truncated to one byte. *)
  [ "sp26_hw2_tests/ntz.ll", 6L ]

let io_tests_with_path =
  (* Format: each io test is a triple consisting of
     - an LLVM IR file
     - a list of command ling arguments
     - the expected output (not including trailing newline) *)
  [ 

    "sp26_hw2_tests/demo_test.ll", ["a"; "b"; "c"], "c\nb\na" ; 
    
  (* Raheem Idowu's tests *)

    "sp26_hw2_tests/satsuma.ll", ["12"; "1"; "7"], "Sorting your numbers!\n1\n7\n12";
    "sp26_hw2_tests/satsuma.ll", [], "1 to 15 numbers please!";

    "sp26_hw2_tests/satsuma.ll", 
      ["67"; "67"; "67"; "67"; "67"; "67"; "67"; "67"; "67"; "67"; "67"; "67"; "67"; "67"; "67"; "67"], 
    "1 to 15 numbers please!";

    "sp26_hw2_tests/satsuma.ll", 
      ["10"; "41"; "23"; "-1"; "80"; "-10"], 
    "Sorting your numbers!\n-10\n-1\n10\n23\n41\n80";

  ]
