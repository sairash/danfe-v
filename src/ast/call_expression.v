module ast

import os

fn print_reserved_function(process_id string, args []Node, new_line bool) ! {
	for arg in args {
		eval_output := arg.eval(process_id)!

		output_str := match eval_output {
			string { eval_output }
			int, f64 { eval_output.str() }
		}

		print('${output_str}')
	}
	if new_line {
		print('\n')
	}
}

fn input_reserved_function(process_id string, arg Node) !EvalOutput {
	eval_output := arg.eval(process_id)!

	output_str := match eval_output {
		string { eval_output }
		int, f64 { eval_output.str() }
	}

	print(output_str)
	return os.get_line()
}
