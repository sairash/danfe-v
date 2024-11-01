module ast

import os

fn print_reserved_function(process_id string, args []Node, new_line bool) ! {
	for arg in args {
		eval_output := arg.eval(process_id)!


		print('${eval_output.get_as_string()}')
	}
	if new_line {
		print('\n')
	}
}

fn input_reserved_function(process_id string, arg Node) !EvalOutput {
	eval_output := arg.eval(process_id)!

	print(eval_output.get_as_string())
	return os.get_line()
}
