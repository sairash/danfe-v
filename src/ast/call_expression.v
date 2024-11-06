module ast

import os
import errors_df
import strconv

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
	return eval_output.get_token_type()
}

fn len_reserved_function(process_id string, arg Node) !EvalOutput {
	eval_output := arg.eval(process_id)!
	return match eval_output {
		Table, string {
			i64(eval_output.len)
		}
		else {
			return error_gen('eval', 'call_exp', errors_df.ErrorCantFindExpectedToken{'Array | String | Table in len()'})
		}
	}
}

fn int_reserved_function(process_id string, arg Node) !EvalOutput {
	eval_output := arg.eval(process_id)!
	return match eval_output {
		i64 {
			eval_output
		}
		f64 {
			i64(eval_output)
		}
		string {
			i64(strconv.atoi(eval_output)!)
		}
		else {
			error_gen('eval', 'call_exp', errors_df.ErrorCantFindExpectedToken{'F64 | String | int|'})
		}
	}
}

