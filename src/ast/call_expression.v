module ast

fn print_reserved_function(args []Node, new_line bool) ! {
	for arg in args {
		eval_output := arg.eval()!

		output_str := match eval_output {
			string { eval_output }
			int, f64 { eval_output.str() }
		}

		if new_line {
			println("$output_str ")
		} else {
			print("$output_str ")
		}
	}
}
