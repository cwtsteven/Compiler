let to32 = Int32.of_int

let read_file filename buf = 
	let file = open_in (filename ^ ".txt") in
	try
		while true do
			buf := !buf ^ input_line file
		done
	with
	| End_of_file -> close_in file