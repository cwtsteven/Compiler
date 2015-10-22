open SyntaxTree
open TestHelper

let parse content = 
content
|> Lexing.from_string
|> Parser.program Lexer.read
|> ConstantFolding.constant_folding

let valid_testcases = [
("tc201", [Global(DeclareAssign(Int, "a", Int (to32 8)))]) ;
("tc202", [Global(DeclareAssign(Bool, "a", Bool true))]) ; 
("tc203", [Global(DeclareAssign(String, "a", String "I am so excited!"))]) ; 
("tc204", [Global(DeclareAssign(Bool, "a", Bool false))]) ; 
("tc205", [Global(DeclareAssign(Real, "a", Real 6.2))]) ; 
("tc206", [Main[Local(DeclareAssign(Int, "a", Int (to32 5))); If_Then_Else(Bool true, [Expr(UnaryOp(Print, Var "a"))], [])]])
]
	

let rec test_valid_cases testcases = 
	match testcases with
	| [] -> ()
	| ((filename, expected) :: xs) -> let content = ref "" in
									  read_file ("testing/valid/" ^ filename) content;
									  print_string ("case " ^ filename ^ ": ");
									  let result = parse !content in
									  (if result = expected 
									  then print_string "passed"
									  else print_string "failed.");
									  print_string "\n";
									  test_valid_cases xs

let test = 
	print_string "\n------- Constant Folding Test -------\n";
	test_valid_cases valid_testcases;
	print_string "Done.\n"