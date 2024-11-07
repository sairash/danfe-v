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

fn assert_print(emote string, test_type string, function_name string) {
	println('${emote} ${test_type}: ${function_name}')
}

fn assert_reserved_function(process_id string, arg []Node, func_name string) !EvalOutput {
	if arg.len < 2 {
		return error_gen('eval', 'assert', errors_df.ErrorArgumentsMisMatch{
			func_name:       func_name
			expected_amount: '>= 1'
			found_amount:    '${arg.len}'
		})
	}

	assert_type := arg[0].eval(process_id)!.get_as_string()

	function_name := arg[1].eval(process_id)!.get_as_string()

	if assert_type == "end" {
		assert_print("🟩", "END   ", function_name)
		return i64(1)
	}else if assert_type == "start" {
		assert_print("🟢", "Start ", function_name)
		return i64(1)
	}


	if arg.len < 3 && arg.len > 4 {
		return error_gen('eval', 'assert', errors_df.ErrorArgumentsMisMatch{
			func_name:       func_name
			expected_amount: '3 | 4'
			found_amount:    '${arg.len}'
		})
	}

	if arg.len == 3 {
		second_value := arg[2].eval(process_id) or { 
			if assert_type != "error" {
				return err
			}
			assert_print("❎", "PASS  ", function_name)
			return i64(1)
		}

		if !second_value.is_true() && assert_type != "missmatch" {
			return error_gen('eval', 'assert_mis_match', errors_df.ErrorAssert{
				function_name: function_name
				output:        second_value.get_as_string()
				expected:      ''
			})
		}
	} else if arg.len == 4 {
		second_value := arg[2].eval(process_id) or { 
			if assert_type != "error" {
				return err
			}
			assert_print("❎", "PASS  ", function_name)
			return i64(1)
		 }
		third_value := arg[3].eval(process_id) or { 
			if assert_type != "error" {
				return err
			}
			assert_print("❎", "PASS  ", function_name)
			return i64(1)
		}
		if second_value != third_value  && assert_type != "missmatch" {
			return error_gen('eval', 'assert_missmatch', errors_df.ErrorAssert{
				function_name: function_name
				output:        second_value.get_as_string()
				expected:      third_value.get_as_string()
			})
		}
	}

	if assert_type == "print" {
		assert_print("✅", "PASS  ", function_name)
	}

	return i64(1)
}
