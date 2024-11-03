module ast

import os
import errors_df

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

fn type_of_value_reserved_function(process_id string, arg Node) !EvalOutput {
	eval_output := arg.eval(process_id)!
	return match eval_output {
		string {
			'string'
		}
		int {
			'int'
		}
		f64 {
			'float'
		}
		Table {
			if eval_output.is_arr {
				return 'array'
			}
			'table'
		}
	}
}

fn len_reserved_function(process_id string, arg Node) !EvalOutput {
	eval_output := arg.eval(process_id)!
	return match eval_output {
		Table, string {
			eval_output.len
		}
		else {
			error_gen('eval', 'call_exp', errors_df.ErrorCantFindExpectedToken{'Array | String | Table in len()'})
		}
	}
}
