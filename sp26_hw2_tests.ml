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
  [ "sp26_hw2_tests/demo_test.ll", ["a"; "b"; "c"], "c\nb\na" ]
