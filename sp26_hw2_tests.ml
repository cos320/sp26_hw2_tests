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
  [ "sp26_hw2_tests/ntz.ll", 6L]

let io_tests_with_path =
  (* Format: each io test is a triple consisting of
     - an LLVM IR file
     - a list of command line arguments
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

    (* Ben Aepli and Vedant Badoni's tests *)
    "sp26_hw2_tests/skip_list.ll", ["5"], "failure...";
    "sp26_hw2_tests/skip_list.ll", ["100"], "success!";
    "sp26_hw2_tests/skip_list.ll", ["10000"], "success!";
    "sp26_hw2_tests/skip_list.ll", ["1000000"], "success!";

    (* Will Grace tests *)
    "sp26_hw2_tests/even_odd.ll", [], "-1";
    "sp26_hw2_tests/even_odd.ll", ["-18"], "-1";
    "sp26_hw2_tests/even_odd.ll", ["0"], "0";
    "sp26_hw2_tests/even_odd.ll", ["1"], "1";
    "sp26_hw2_tests/even_odd.ll", ["2"], "0";
    "sp26_hw2_tests/even_odd.ll", ["4"], "0";
    "sp26_hw2_tests/even_odd.ll", ["5"], "1";
    "sp26_hw2_tests/even_odd.ll", ["100"], "0";

    (* Ayush's tests *)
    (* "sp26_hw2_tests/fenwick.ll", ["1"; "2"; "3"; "0"; "2"], "6";
    "sp26_hw2_tests/fenwick.ll", ["10"; "23"; "43"; "78"; "292"; "2"; "21"; "34"; "2"; "6"], "436";
    "sp26_hw2_tests/fenwick.ll", ["10"; "10"; "10"; "10"; "1"; "2"], "20";
    "sp26_hw2_tests/fenwick.ll", ["-1"; "-2"; "0"; "1"], "-3"; *)

    (* Arnav's tests *)
    (
      "sp26_hw2_tests/binary_search_recur.ll",
      [],
      "Please input the target number, and then 1-10 numbers!"
    );
    (
      "sp26_hw2_tests/binary_search_recur.ll",
      ["1"; "6"; "9"; "-3"; "1"],
      "Running recursive binary search...\nInput array not in sorted order..."
    );
    (
      "sp26_hw2_tests/binary_search_recur.ll",
      ["7"; "7"],
      "Running recursive binary search...\nTarget was found!"
    );
    (
      "sp26_hw2_tests/binary_search_recur.ll",
      ["45"; "12"; "34"; "45"; "56"; "67"; "78"; "89"; "90"],
      "Running recursive binary search...\nTarget was found!"
    );
    (
      "sp26_hw2_tests/binary_search_recur.ll",
      ["-23"; "-34"; "-30"; "-24"; "-14"; "-9"; "0"; "34"],
      "Running recursive binary search...\nTarget was not found..."
    );
    (
      "sp26_hw2_tests/binary_search_recur.ll",
      ["91"; "38953"; "853980291"; "8934384378437987"],
      "Running recursive binary search...\nTarget was not found..."
    );
  ]
