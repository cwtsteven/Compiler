open SyntaxTree
open TestHelper

let parse = Compiler.parse_with_op

let valid_testcases = [
"tc301" ; "tc302" ; "tc303" ; "tc304"; "tc305"
]
	

let rec test_valid_cases testcases = 
	match testcases with
	| [] -> ()
	| (filename :: xs) -> let content = ref "" in
									  read_file ("testing/valid/" ^ filename) content;
									  let content2 = ref "" in
									  read_file ("testing/valid/" ^ filename ^ "a") content2;
									  print_string ("case " ^ filename ^ ": ");
									  let result = parse !content
									  and expected = parse !content2 in
									  (if result = expected 
									  then print_string "\tpassed"
									  else print_string "\t\tfailed.");
									  print_string "\n";
									  test_valid_cases xs

let test = 
	print_string "\n------- Constant Propagation Test -------\n";
	test_valid_cases valid_testcases;
	print_string "Done.\n"