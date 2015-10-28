open SyntaxTree

exception UnboundVarError of string

let rec var_lookup v v_tables : type_ * var * int =
	match v_tables with
	| [] -> raise (UnboundVarError ("Unbound variable " ^ v ^ "\n"))
	| (v_table :: vs) 	->	if Hashtbl.mem !v_table v then Hashtbl.find !v_table v else var_lookup v vs

let rec generate_nullary_op op v_tables : type_ * string = 
	match op with
	| Prompt 	-> 	(String, "")
and generate_unary_op (op, e) v_tables : type_ * string =
	match op with 
	| Print		-> 	let (t, e') = generate_expr e v_tables in
					(Void, 
					(match t with
					| Int 		->	e' ^ "\tlea format_int(%rip), %rdi\n" ^ "\tpop %rsi\n" ^ "\tcall _printf\n"
					| Real 		-> 	""
					| Char 		-> 	""
					| String 	-> 	""
					| Bool 		->	""
					| Void 		->	""
					))
	| Neg 		->	(Int, "")
	| Not 		->	(Bool, "")

and generate_binary_op (op, e1, e2) v_tables : type_ * string = 
	let (t1, e1') = generate_expr e1 v_tables 
	and (t2, e2') = generate_expr e2 v_tables in
	(match op with
	| Add 		-> 	(match (t1, t2) with
					| (Int, Int)		->	(Int, e1' ^ e2' ^ "\tpop %r8\n" ^ "\tpop %rax\n" ^ "\tadd %r8, %rax\n" ^ "\tpush %rax\n")
					| (Real, Real)		->	(Real, "")
					| (Real, Int) 		->	(Real, "")
					| (Int, Real) 		-> 	(Real, "")
					| (String, String)	->	(String, "")
					| _ 				->	(Void, "")
					)
	| Sub 		-> 	(match (t1, t2) with
					| (Int, Int)		->	(Int, e1' ^ e2' ^ "\tpop %r8\n" ^ "\tpop %rax\n" ^ "\tsub %r8, %rax\n" ^ "\tpush %rax\n")
					| (Real, Real)		->	(Real, "")
					| (Real, Int) 		->	(Real, "")
					| (Int, Real) 		-> 	(Real, "")
					| _ 				->	(Void, "")
					)
	| Mul 		-> 	(match (t1, t2) with
					| (Int, Int)		->	(Int, e1' ^ e2' ^ "\tpop %r8\n" ^ "\tpop %rax\n" ^ "\timul %r8, %rax\n" ^ "\tpush %rax\n")
					| (Real, Real)		->	(Real, "")
					| (Real, Int) 		->	(Real, "")
					| (Int, Real) 		-> 	(Real, "")
					| _ 				->	(Void, "")
					)
	| Div 		-> 	(match (t1, t2) with
					| (Int, Int)		->	(Int, e1' ^ e2' ^ "\tpop %r8\n" ^ "\tpop %rax\n" ^ "\tcqto\n" ^ "\tidiv %r8\n" ^ "\tpush %rax\n")
					| (Real, Real)		->	(Real, "")
					| (Real, Int) 		->	(Real, "")
					| (Int, Real) 		-> 	(Real, "")
					| _ 				->	(Void, "")
					)
	| Eq 		-> 	(Void, "")
	| Neq 		->	(Void, "")
	| Gt 		-> 	(Void, "")
	| Geq		->	(Void, "")
	| Lt 		-> 	(Void, "")
	| Leq 		-> 	(Void, "")
	| And 		->	(Void, "")
	| Or 		-> 	(Void, "")
	)

and generate_expr expr v_tables : type_ * string = 
	match expr with
	| Var v 				-> 	let (t, var, offset) = var_lookup v v_tables in
								if offset = -1 then (t, "\tmovabsq (" ^ var ^ "), %rax\n" ^ "\tpush %rax\n")
								else (Void, "")
	| Int i 				-> 	(Int, "\tpush $" ^ Int32.to_string i ^ "\n")
	| Real r 				-> 	(Real, "")
	| Char c 				-> 	(Char, "")
	| String s 				-> 	(String, "")
	| Bool true 			-> 	(Bool, "")
	| Bool false			->	(Bool, "")
	| NullaryOp op			-> 	generate_nullary_op op v_tables
	| UnaryOp (op, e) 		-> 	generate_unary_op (op, e) v_tables
	| BinaryOp (op, e1, e2)	->	generate_binary_op (op, e1, e2) v_tables
	| Assign (v, e)			->	let (t', e') = generate_expr e v_tables
								and (t, var, offset) = var_lookup v v_tables in
								if offset = -1 then 
								(match t' with
								| Int 	->	(t', e' ^ "\tpop %rax\n" ^ "\tmovabsq %rax, (" ^ v ^ ")\n")
								| _ 	->	(Void, "")
								)
								else (Void, "")
	| FunCall (v, ps) 		->	(Void, "")

let rec generate_block block v_tables : string = 
	let v_table : ((var, (type_ * var * int)) Hashtbl.t) ref = ref (Hashtbl.create 10) in
	let v_tables = v_table :: v_tables 
	and block_array = Array.of_list block
	and result = ref "" in
	for i = 0 to (Array.length block_array) - 1 do 
		result := !result ^ 
		(match block_array.(i) with
		| Expr e 					-> 	snd (generate_expr e v_tables)
		| Return e  				-> 	""
		| Local s 					-> 	""
		| If_Then_Else (e, b1, b2)	-> 	""
		| While (e, b)				-> 	""
		| For (e1, e2, e3, b)		-> 	""
		| Block b 					-> 	generate_block b v_tables
		)
	done;
	!result

let generate_program program v_tables : string = 
	let v_table : ((var, (type_ * var * int)) Hashtbl.t) ref = ref (Hashtbl.create 10) in
	let v_tables = v_table :: v_tables 
	and program_array = Array.of_list program
	and result = ref "" in
	for i = 0 to (Array.length program_array) - 1 do 
		result := !result ^ 
		(match program_array.(i) with
		| Global (Declare (t, v)) 			->	Hashtbl.add !v_table v (t, v, -1);
												v ^ ": " ^ 
												(match t with
												| Void 		->	"\t.8byte"
												| Int 		->	"\t.long"
												| Real 		->	"\t.double"
												| Char 		-> 	""
												| Bool 		-> 	""
												| String 	-> 	"\t.string"
												) ^ "\n"
		| Global (DeclareAssign (t, v, e))	-> 	Hashtbl.add !v_table v (t, v, -1);
												v ^ ": " ^ 
												(match (t, e) with
												| (Int, Int i)			->	"\t.long " ^ Int32.to_string i
												| (Real, Real r) 		->	"\t.double " ^ string_of_float r
												| (Char, Char c) 		-> 	""
												| (Bool, Bool b)		-> 	""
												| (String, String s)	-> 	"\t.string \"" ^ s ^ "\\0\""
												| _ 					-> 	""
												) ^ "\n"
		| Function (t, v, ps, b) 			-> 	""
		| Main b 							-> 	"\t.section __TEXT,__text,regular,pure_instructions\n" ^ "\t.globl _main" ^ "\n_main:\n" ^ "\tpush $0\n" ^ generate_block b v_tables ^ "\tmov $0, %rdi\n\tcall _exit"
		)
	done;
	!result

let rec sort_program global func iterate : program =
	match iterate with
	| [] -> global @ func
	| ((Global s) :: xs) 	-> 	sort_program (global @ [(Global s)]) func xs
	| (x :: xs) 			-> 	sort_program global (func @ [x]) xs

let static_data : string = 
	"\t.data\n"

let prefix : string = 
	"\t.section __TEXT,__cstring,cstring_literals\n" ^ 
	"format_int:\n" ^ 
	"\t.string \"%d\\0\"\n"

let generate program : string = 
	let v_tables : (((var, (type_ * var * int)) Hashtbl.t) ref) list = [] in
	prefix ^ "\n" ^
	static_data ^
	generate_program (sort_program [] [] program) v_tables ^ 
	"\n"