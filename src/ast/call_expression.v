module ast

import os
import errors_df
import strconv
import rand
import lexer
import token

__global all_p_server = []string{}


fn print_reserved_function(process_id []&Process, args []Node, new_line bool) ! {
	for arg in args {
		eval_output := arg.eval(process_id)!

		print('${eval_output.get_as_string()}')
	}
	if new_line {
		print('\n')
	}
}

fn input_reserved_function(process_id []&Process, arg Node) !EvalOutput {
	eval_output := arg.eval(process_id)!

	print(eval_output.get_as_string())
	return os.get_line()
}

fn type_of_value_reserved_function(process_id []&Process, arg Node) !EvalOutput {
	eval_output := arg.eval(process_id)!
	return eval_output.get_token_type()
}

fn len_reserved_function(process_id []&Process, arg Node) !EvalOutput {
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

fn int_reserved_function(process_id []&Process, arg Node) !EvalOutput {
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

fn assert_reserved_function(process_id []&Process, arg []Node, func_name string) !EvalOutput {
	if arg.len < 2 {
		return error_gen('eval', 'assert', errors_df.ErrorArgumentsMisMatch{
			func_name:       func_name
			expected_amount: '>= 1'
			found_amount:    '${arg.len}'
		})
	}

	assert_type := arg[0].eval(process_id)!.get_as_string()

	function_name := arg[1].eval(process_id)!.get_as_string()

	if assert_type == 'end' {
		assert_print('🟩', 'END   ', '${function_name} \n')
		return i64(1)
	} else if assert_type == 'start' {
		assert_print('🟢', 'START ', function_name)
		return i64(1)
	} else if assert_type == 'info' {
		assert_print('🛈', 'INFO  ', function_name)
		return i64(1)
	} else if assert_type == 'success' {
		assert_print('👌', '', function_name)
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
			if assert_type != 'error' {
				return err
			}
			assert_print('❎', 'PASS  ', function_name)
			return i64(1)
		}

		if !second_value.is_true() && assert_type != 'mismatch' {
			return error_gen('eval', 'assert_mis_match', errors_df.ErrorAssert{
				function_name: function_name
				output:        second_value.get_as_string()
				expected:      ''
			})
		}
	} else if arg.len == 4 {
		second_value := arg[2].eval(process_id) or {
			if assert_type != 'error' {
				return err
			}
			assert_print('❎', 'PASS  ', function_name)
			return i64(1)
		}
		third_value := arg[3].eval(process_id) or {
			if assert_type != 'error' {
				return err
			}
			assert_print('❎', 'PASS  ', function_name)
			return i64(1)
		}
		if second_value != third_value && assert_type != 'mismatch' {
			return error_gen('eval', 'assert_mismatch', errors_df.ErrorAssert{
				function_name: function_name
				output:        second_value.get_as_string()
				expected:      third_value.get_as_string()
			})
		}
	}

	if assert_type == 'print' || assert_type == 'mismatch' {
		assert_print('✅', 'PASS  ', function_name)
	}

	return i64(1)
}

const default_call_operations = {
	'print':    fn (process_id []&Process, base Identifier, arguments []Node) !EvalOutput {
		print_reserved_function(process_id, arguments, false)!
		return i64(1)
	}
	'println':  fn (process_id []&Process, base Identifier, arguments []Node) !EvalOutput {
		print_reserved_function(process_id, arguments, true)!
		return i64(1)
	}
	'assert':   fn (process_id []&Process, base Identifier, arguments []Node) !EvalOutput {
		if '-t' in (identifier_value_map['main.__args__'] or { return i64(0) } as Table).table {
			return assert_reserved_function(process_id, arguments, base.token.value)
		}
		return i64(1)
	}
	'input':    fn (process_id []&Process, base Identifier, arguments []Node) !EvalOutput {
		if arguments.len != 1 {
			return error_gen('eval', 'input', errors_df.ErrorArgumentsMisMatch{
				func_name:       base.token.value
				expected_amount: '1'
				found_amount:    '${arguments.len}'
			})
		}
		return input_reserved_function(process_id, arguments[0])
	}
	'typeof':   fn (process_id []&Process, base Identifier, arguments []Node) !EvalOutput {
		if arguments.len != 1 {
			return error_gen('eval', 'typeof', errors_df.ErrorArgumentsMisMatch{
				func_name:       base.token.value
				expected_amount: '1'
				found_amount:    '${arguments.len}'
			})
		}

		return type_of_value_reserved_function(process_id, arguments[0])
	}
	'len':      fn (process_id []&Process, base Identifier, arguments []Node) !EvalOutput {
		if arguments.len != 1 {
			return error_gen('eval', 'len', errors_df.ErrorArgumentsMisMatch{
				func_name:       base.token.value
				expected_amount: '1'
				found_amount:    '${arguments.len}'
			})
		}
		return len_reserved_function(process_id, arguments[0])
	}
	'int':      fn (process_id []&Process, base Identifier, arguments []Node) !EvalOutput {
		if arguments.len != 1 {
			return error_gen('eval', 'int', errors_df.ErrorArgumentsMisMatch{
				func_name:       base.token.value
				expected_amount: '1'
				found_amount:    '${arguments.len}'
			})
		}
		return int_reserved_function(process_id, arguments[0])
	}
	'float':    fn (process_id []&Process, base Identifier, arguments []Node) !EvalOutput {
		if arguments.len != 1 {
			return error_gen('eval', 'float', errors_df.ErrorArgumentsMisMatch{
				func_name:       base.token.value
				expected_amount: '1'
				found_amount:    '${arguments.len}'
			})
		}
		eval_output := arguments[0].eval(process_id)!
		return match eval_output {
			i64 {
				f64(eval_output)
			}
			f64 {
				eval_output
			}
			string {
				strconv.atof64(eval_output)!
			}
			else {
				error_gen('eval', 'call_exp', errors_df.ErrorCantFindExpectedToken{'F64 | String | int|'})
			}
		}
	}
	'chr':      fn (process_id []&Process, base Identifier, arguments []Node) !EvalOutput {
		if arguments.len != 1 {
			return error_gen('eval', 'string', errors_df.ErrorArgumentsMisMatch{
				func_name:       base.token.value
				expected_amount: '1'
				found_amount:    '${arguments.len}'
			})
		}
		eval_output := arguments[0].eval(process_id)!
		return match eval_output {
			i64 {
				rune(eval_output).str()
			}
			string {
				if eval_output.len > 1 {
					error_gen('eval', 'call_exp', errors_df.ErrorCustomError{'The string length should be > 0 and < 2'})
				}
				i64(eval_output[0])
			}
			else {
				error_gen('eval', 'call_exp', errors_df.ErrorCantFindExpectedToken{'|int|'})
			}
		}
	}
	'string':   fn (process_id []&Process, base Identifier, arguments []Node) !EvalOutput {
		if arguments.len != 1 {
			return error_gen('eval', 'string', errors_df.ErrorArgumentsMisMatch{
				func_name:       base.token.value
				expected_amount: '1'
				found_amount:    '${arguments.len}'
			})
		}
		eval_output := arguments[0].eval(process_id)!
		return '${eval_output.get_as_string()}'
	}
	'panic':    fn (process_id []&Process, base Identifier, arguments []Node) !EvalOutput {
		if arguments.len != 1 {
			return error_gen('eval', 'string', errors_df.ErrorArgumentsMisMatch{
				func_name:       base.token.value
				expected_amount: '1'
				found_amount:    '${arguments.len}'
			})
		}
		eval_output := arguments[0].eval(process_id)!

		return error_gen('system', 'panic', errors_df.ErrorCustomError{eval_output.get_as_string()})
	}
	'rand_str': fn (process_id []&Process, base Identifier, arguments []Node) !EvalOutput {
		mut length := 10

		if arguments.len > 1 {
			return error_gen('eval', 'rand', errors_df.ErrorArgumentsMisMatch{
				func_name:       base.token.value
				expected_amount: '1'
				found_amount:    '${arguments.len}'
			})
		} else if arguments.len == 1 {
			eval_length := arguments[0].eval(process_id)!
			match eval_length {
				i64 {
					if eval_length >= max_int || eval_length <= min_int {
						return error_gen('eval', 'int_unable_to_convert', errors_df.ErrorI64ToIntConvert{})
					}

					length = int(eval_length)
				}
				else {
					return error_gen('eval', 'rand', errors_df.ErrorMismatch{
						expected: 'int'
						found:    '${eval_length.get_token_type()}'
					})
				}
			}
		}
		return rand.string(length)
	}
	'rand_int': fn (process_id []&Process, base Identifier, arguments []Node) !EvalOutput {
		rand_int := rand.i64()
		return if rand_int < 0 { rand_int * -1 } else { rand_int }
	}
	'table':    fn (process_id []&Process, base Identifier, arguments []Node) !EvalOutput {
		if arguments.len > 1 {
			return error_gen('eval', 'rand', errors_df.ErrorArgumentsMisMatch{
				func_name:       base.token.value
				expected_amount: '1'
				found_amount:    '${arguments.len}'
			})
		}
		eval_output := arguments[0].eval(process_id)!
		return match eval_output {
			string {
				small_danfe_table_parser(eval_output)!
			}
			else {
				error_gen('eval', 'call_exp', errors_df.ErrorCantFindExpectedToken{'String'})
			}
		}
	}
}


struct DataTypeParser {
mut:
	lex        lexer.Lex
	cur_token  token.Token
	next_token token.Token
}

fn (mut dtp DataTypeParser) next() ! {
	dtp.cur_token = dtp.next_token
	dtp.next_token = dtp.lex.next()!
}

fn (mut dtp DataTypeParser) parse_table() !EvalOutput {
	if dtp.cur_token.get_value() != '[' {
		return error(errors_df.gen_custom_error_message('parsing', 'eval_parse_factor',
			'', 0, 0, errors_df.ErrorUnexpectedToken{
			token: "${dtp.cur_token.get_value()}, \"[\" is required"
		}))
	}
	dtp.next()!
	mut ast_table := Table{
		table:  {}
		is_arr: true
		len:    0
	}

	for {
		match dtp.cur_token.token_type {
			token.Punctuation {
				if dtp.cur_token.get_value() == ']' {
					dtp.next()!
					return ast_table
				}
			}
			token.EOL {
				dtp.next()!
			}
			else {}
		}

		mut key := '${ast_table.len + 1}'

		if dtp.next_token.token_type is token.Operator {
			if dtp.next_token.get_value() == '=>' {
				parsed_factor := dtp.parse_factor()!
				dtp.next()!
				if parsed_factor is string {
					key = parsed_factor
					ast_table.is_arr = false
				} else {
					break
				}
			}
		}

		ast_table.table[key] = dtp.parse_factor()!
		ast_table.len++

		match dtp.cur_token.token_type {
			token.Seperator, token.EOL {
				dtp.next()!
			}
			token.Punctuation {}
			else {
				break
			}
		}
	}

	return error(errors_df.gen_custom_error_message('parsing', 'eval_parse_table', '',
		0, 0, errors_df.ErrorUnexpectedToken{
		token: dtp.cur_token.get_value()
	}))
}

fn (mut dtp DataTypeParser) parse_factor() !EvalOutput {
	cur_type := dtp.cur_token
	token_type := cur_type.token_type

	match token_type {
		token.String {
			dtp.next()!
			return token_type.value
		}
		token.Identifier {
			dtp.next()!
			return token_type.value
		}
		token.Numeric {
			dtp.next()!
			if token_type.hint == .i64 {
				return token_type.value.i64()
			}
			return token_type.value.f64()
		}
		token.Punctuation {
			if token_type.value == '[' {
				return dtp.parse_table()
			}
			return token_type.value
		}
		token.EOF {}
		token.EOL {}
		token.Comment {}
		else {
			return cur_type.get_value()
		}
	}

	return error(errors_df.gen_custom_error_message('parsing', 'eval_parse_factor', '',
		0, 0, errors_df.ErrorUnexpectedToken{
		token: cur_type.get_value()
	}))
}

fn small_danfe_table_parser(value string) !EvalOutput {
	mut dtp := DataTypeParser{
		lex: lexer.Lex{
			x:               0
			file_data:       value
			file_path:       'tmp/sai/123'
			return_path:     ''
			can_import:      true
			file_len:        value.len
			cur_col:         1
			cur_line:        1
			bracket_balance: []
		}
	}

	dtp.next()!
	dtp.next()!

	return dtp.parse_table()
}
