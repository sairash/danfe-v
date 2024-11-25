module ast

import token
import strconv
import errors_df
import rand
import grammer
import os

__global identifier_assignment_tracker = map[string][]string{}

__global identifier_value_map = map[string]EvalOutput{}

__global program_state_map = map[string]ProgramStateStore{}

__global server_url_function_map = EvalOutput{}

__global base_dir_path = os.dir(os.executable())

struct Table {
mut:
	table  map[string]EvalOutput
	len    int
	is_arr bool
}

type EvalOutput = string | i64 | f64 | Table | FunctionStore

pub fn add_args_to_table(full_module_ string, args []string) {
	if '${full_module_}.__args__' in identifier_value_map {
		return
	}

	mut arg_table := Table{
		table:  {}
		is_arr: false
		len:    args.len
	}
	for k, v in args {
		arg_table.table[v] = i64(k)
	}
	identifier_value_map['${full_module_}.__args__'] = arg_table
}

fn delete_process_memory(process_id string) {
	for _, var_name in identifier_assignment_tracker[process_id] {
		unsafe {
			identifier_value_map.delete(var_name)
		}
	}
	identifier_assignment_tracker.delete(process_id)
}

fn to_int_f64_or_str(value string) EvalOutput {
	mut has_decimal := false
	mut has_non_numeric := false

	for _, ch in value {
		if ch == `.` {
			if has_decimal {
				has_non_numeric = true
				break
			}
			has_decimal = true
		} else if !ch.is_digit() {
			has_non_numeric = true
			break
		}
	}

	if has_non_numeric {
		return value
	} else if has_decimal {
		return value.f64()
	} else {
		return value.i64()
	}
}

pub fn (evl EvalOutput) get_token_type() string {
	return match evl {
		string {
			'string'
		}
		i64 {
			'int'
		}
		f64 {
			'float'
		}
		Table {
			if evl.is_arr {
				return 'array'
			}
			'table'
		}
		FunctionStore {
			'function'
		}
	}
}

pub fn (evl EvalOutput) get_indexed_value(value EvalOutput, name_of_var string) !(EvalOutput, string) {
	match evl {
		Table {
			if evl.is_arr {
				match value {
					i64 {
						if value < evl.len {
							return evl.table['${value}'] or {
								return error_gen('eval', 'get_indexed_value', errors_df.ErrorArrayOutOfRange{
									total_len:     evl.len
									trying_to_get: '${value}'
									name_of_var:   name_of_var
								})
							}, '${value}'
						}
						return error_gen('eval', 'get_indexed_value', errors_df.ErrorArrayOutOfRange{
							total_len:     evl.len
							trying_to_get: '${value}'
							name_of_var:   name_of_var
						})
					}
					else {
						return error_gen('eval', 'get_indexed_value', errors_df.ErrorArrayOutOfRange{
							total_len:     evl.len
							trying_to_get: value.get_as_string()
							name_of_var:   name_of_var
						})
					}
				}
			}
			return evl.table[value.get_as_string()] or { return i64(0), value.get_as_string() }, value.get_as_string()
		}
		string {
			match value {
				i64 {
					if value < evl.len {
						return evl[value].ascii_str(), '${value}'
					}
				}
				else {}
			}
			return error_gen('eval', 'string_get_indexed_value', errors_df.ErrorArrayOutOfRange{
				total_len:     evl.len
				trying_to_get: value.get_as_string()
				name_of_var:   name_of_var
			})
		}
		else {}
	}
	return error_gen('eval', 'get_indexed_value', errors_df.ErrorCannotUseIndexKeyOn{
		name_of_var: name_of_var
	})
}

pub fn (mut evl EvalOutput) update_indexed_value(indexes []Node, node Node, name_of_var string, process_id []string, insert_op string) !EvalOutput {
	mut value := EvalOutput(i64(1))

	match node {
		FunctionStore {
			value = EvalOutput(node)
		}
		else {
			value = node.eval(process_id)!
		}
	}

	mut evaluation := evl
	mut name := name_of_var

	for i := 0; i < indexes.len - 1; i++ {
		evaluation, name = evaluation.get_indexed_value(indexes[i].eval(process_id)!,
			name_of_var)!
	}

	last_index := indexes[indexes.len - 1].eval(process_id)!
	if (insert_op == '<<' || insert_op == '>>') && evaluation is Table {
		if (evaluation as Table).is_arr && last_index != EvalOutput(i64(-1)) {
			evaluation, name = evaluation.get_indexed_value(last_index, name_of_var)!
		} else if !(evaluation as Table).is_arr {
			if last_index.get_as_string() in (evaluation as Table).table {
				evaluation, name = evaluation.get_indexed_value(last_index, name_of_var)!
			}
		}
	}

	match mut evaluation {
		Table {
			if evaluation.is_arr {
				if insert_op == '<<' {
					evaluation.table['${evaluation.len}'] = value
					evaluation.len = evaluation.len + 1
					return i64(1)
				} else if insert_op == '>>' {
					if evaluation.len <= 0 {
						return error_gen('eval', 'pop_value', errors_df.ErrorArrayOutOfRange{
							total_len:     evaluation.len
							trying_to_get: '${value}'
							name_of_var:   name
						})
					}

					unsafe {
						evaluation.len = evaluation.len - 1
						value_to_reutrn := evaluation.table['${evaluation.len}']
						evaluation.table.delete('${evaluation.len}')
						return value_to_reutrn
					}
				}
				match last_index {
					i64 {
						if last_index < evaluation.len {
							evaluation.table['${last_index}'] = value
							evaluation.len = evaluation.table.keys().len
							return i64(1)
						}
						return error_gen('eval', 'update_indexed_value', errors_df.ErrorArrayOutOfRange{
							total_len:     evaluation.len
							trying_to_get: '${value}'
							name_of_var:   name
						})
					}
					string {
						evaluation.table[last_index] = value
						evaluation.len = evaluation.table.keys().len
						evaluation.is_arr = false
						return i64(1)
					}
					else {
						return error_gen('eval', 'update_indexed_value', errors_df.ErrorArrayOutOfRange{
							total_len:     evaluation.len
							trying_to_get: value.get_as_string()
							name_of_var:   name
						})
					}
				}
			}

			if insert_op == '<<' {
				// Randomly adds a key to the map with the table
				evaluation.table[gen_process_id('')] = value
				evaluation.len = evaluation.len + 1
				return i64(1)
			} else if insert_op == '>>' {
				if evaluation.len <= 0 {
					return error_gen('eval', 'pop_value', errors_df.ErrorArrayOutOfRange{
						total_len:     evaluation.len
						trying_to_get: '${value}'
						name_of_var:   name
					})
				}

				last_key := evaluation.table.keys()[evaluation.len - 1]
				unsafe {
					evaluation.len = evaluation.len - 1
					value_to_reutrn := Table{
						table:  {
							'0': last_key
							'1': evaluation.table[last_key]
						}
						is_arr: true
						len:    2
					}
					evaluation.table.delete(last_key)
					return value_to_reutrn
				}
			}
			evaluation.table[last_index.get_as_string()] = value
			evaluation.len = evaluation.table.keys().len
			return i64(1)
		}
		else {}
	}

	return error_gen('eval', 'update_indexed_value', errors_df.ErrorCannotUseIndexKeyOn{
		name_of_var: name
	})
}

pub fn (evl EvalOutput) is_empty() bool {
	match evl {
		string {
			return evl == ''
		}
		i64 {
			return evl == 0
		}
		f64 {
			return evl == 0
		}
		Table {
			return evl.len == 0
		}
		FunctionStore {
			return false
		}
	}
}

fn (evl EvalOutput) is_true() bool {
	return match evl {
		string {
			evl != ''
		}
		i64 {
			evl != i64(0)
		}
		f64 {
			evl != f64(0.0)
		}
		Table {
			evl.len != 0
		}
		FunctionStore {
			return false
		}
	}
}

fn is_condition_met(process_id []string, condition ?Node) !bool {
	cond_eval := condition or { return true }
		.eval(process_id)!

	return cond_eval.is_true()
}

pub fn (evl EvalOutput) get_as_string() string {
	output_str := match evl {
		string {
			evl
		}
		i64, f64 {
			evl.str()
		}
		Table {
			if evl.is_arr {
				if evl.len == 0 {
					return '[]'
				}
				mut ops := '['
				for _, val in evl.table {
					ops += '${val.get_as_string()}, '
				}
				ops = ops[..ops.len - 2]
				ops += ']'
				return ops
			}
			if evl.len == 0 {
				return '[]'
			}
			mut ops := '['
			for key, val in evl.table {
				ops += '${key} => ${val.get_as_string()}, '
			}
			ops = ops[..ops.len - 2]
			ops += ']'
			return ops
		}
		FunctionStore {
			if evl.parameters.len == 0 {
				return 'function () {}'
			}

			mut ret_string := 'function ( '
			for parm in evl.parameters {
				ret_string += '${parm.token.value}, '
			}
			ret_string = ret_string[..ret_string.len - 2]
			ret_string += ') { FunctionBlock }'
			return ret_string
		}
	}

	return output_str
}

pub fn gen_process_id(process_id string) string {
	return if process_id != '' { process_id } else { rand.ascii(14) }
}

fn gen_map_key(from []string, process_id []string, sep_value []string) []string {
	mut ret_processes := []string{}
	from_joined := from.join('.')
	value_joined := sep_value[..sep_value.len - 1].join('.')
	last_value := sep_value[sep_value.len - 1]

	for _, process in process_id {
		mut join_val := '${from_joined}${if process != '' {
			'.' + process
		} else {
			''
		}}${if value_joined != '' {
			'.' + value_joined
		} else {
			''
		}}'
		ret_processes << join_val
		join_val += '.${last_value}'
		ret_processes << join_val
	}
	return ret_processes
}

fn match_identifier_with_reserved(identifier string, from []string) Identifier {
	mut ret_ident := token.Identifier{
		value:     identifier
		sep_value: identifier.split('.')
		reserved:  ''
	}

	for key, value in grammer.reserved_symbols {
		if identifier == key || identifier in value {
			ret_ident.reserved = key
		}
	}

	return Identifier{
		token: ret_ident
		from:  from
	}
}

fn remove_space(string_value string) string {
	return string_value.replace(' ', '').replace('\n', '').replace('\t', '')
}

fn replace_identifier_in_string(string_value string, from []string, process_id []string) !string {
	mut ret_string := ''
	mut start_index := 0
	mut cur_index := 0
	mut last_index := 0
	for {
		cur_index = string_value.index_after('%i{', cur_index)

		if cur_index == -1 {
			break
		}

		last_index = string_value.index_after('}', cur_index)

		if last_index == -1 {
			return error_gen('eval', 'replace_with_ident', errors_df.ErrorNeededAfterInit{
				init_token:     '%i{'
				expected_token: '}'
			})
		}

		ident := match_identifier_with_reserved(remove_space(string_value[cur_index + 3..last_index]),
			from)

		if ident.token.reserved != '' {
			return error_gen('eval', 'replace_with_ident', errors_df.ErrorOnlyAllowed{
				value: '"identifer" cannot use "Reserved Key" "${ident.token.value}"'
			})
		}

		ret_string += string_value[start_index..cur_index] +
			'${ident.eval(process_id)!.get_as_string()}'

		cur_index = last_index + 1
		start_index = cur_index
	}

	ret_string += string_value[start_index..string_value.len]
	return ret_string
}

enum ProgramState {
	@none
	break_
	continue_
	return_
}

struct ProgramStateStore {
	hint  ProgramState
	value EvalOutput
}

pub struct FunctionStore {
pub mut:
	parameters []Identifier
	body       []Node
	scope      string
}

fn (fs FunctionStore) eval(process_id []string) !EvalOutput {
	return i64(1)
}

fn (fs FunctionStore) execute_with_eval_output_as_arguments(arguments []EvalOutput, process_id []string) !EvalOutput {
	if fs.parameters.len != arguments.len {
		return error_gen('eval', 'call_exp', errors_df.ErrorMismatch{
			expected: '${fs.parameters.len} parameters'
			found:    '${arguments.len} parameters were passed'
		})
	}

	for i := 0; i < fs.parameters.len; i++ {
		fs.parameters[i].set_value(process_id, FunctionDeclared{}, true, arguments[i],
			true)!
	}

	for val in fs.body {
		val.eval(process_id)!

		for process in process_id {
			if process in program_state_map {
				program_store := program_state_map[process]
				match program_store.hint {
					.return_ {
						program_state_map.delete(process)
						return program_store.value
					}
					else {}
				}
				break
			}
		}
	}

	return i64(0)
}

fn (fs FunctionStore) execute(ce CallExpression, process_id []string) !EvalOutput {
	if fs.parameters.len != ce.arguments.len {
		return error_gen('eval', 'call_exp', errors_df.ErrorMismatch{
			expected: '${fs.parameters.len} parameters for function ${(ce.base as Identifier).from}.${(ce.base as Identifier).token.value}(${fs.parameters.map(it.token.value).join(', ')})'
			found:    '${ce.arguments.len} parameters were passed'
		})
	}

	for i := 0; i < fs.parameters.len; i++ {
		fs.parameters[i].set_value(process_id, ce.arguments[i], true, '', false)!
	}

	for val in fs.body {
		val.eval(process_id)!

		for process in process_id {
			if process in program_state_map {
				program_store := program_state_map[process]
				match program_store.hint {
					.return_ {
						program_state_map.delete(process)
						return program_store.value
					}
					else {}
				}
				break
			}
		}
	}

	return i64(1)
}

pub fn set_if_module_not_already_init(full_module_ string, module_ string) bool {
	if '${full_module_}.__module__' in identifier_value_map {
		return false
	}

	identifier_value_map['${full_module_}.__module__'] = module_

	return true
}

pub interface Node {
	eval(process_id []string) !EvalOutput
}

fn check_eval_name(output EvalOutput) string {
	match output {
		string {
			return 'str'
		}
		else {
			return 'num'
		}
	}
	return ''
}

fn error_gen(while string, extra_info string, error_data errors_df.ErrorInterface) errors_df.DfError {
	return errors_df.DfError{
		while:    while
		when:     extra_info
		path:     ''
		cur_line: 0
		cur_col:  0
		error:    error_data
	}
}

pub struct Chunk {
pub mut:
	body  []Node
	range []i64
}

pub enum LitrealType {
	integer
	floating_point
	str
	boolean
	null
}

pub struct Litreal {
pub mut:
	hint  LitrealType
	value string
	from  []string @[required]
}

fn (li Litreal) eval(process_id []string) !EvalOutput {
	match li.hint {
		.integer {
			return EvalOutput(li.value.i64())
		}
		.floating_point {
			return EvalOutput(strconv.atof64(li.value)!)
		}
		.str {
			return replace_identifier_in_string(li.value, li.from, process_id)!
		}
		.boolean {
			if li.value == 'true' {
				return i64(1)
			}
			return i64(0)
		}
		.null {
			return i64(0)
		}
	}
	return error_gen('eval', 'litreal', errors_df.ErrorUnsupported{})
}

pub struct Binary {
pub mut:
	operator string
	left     Node
	right    Node
}

fn (bi Binary) eval(process_id []string) !EvalOutput {
	left_eval := bi.left.eval(process_id)!
	right_eval := bi.right.eval(process_id)!

	if (left_eval is f64 && right_eval is f64) || (left_eval is i64 && right_eval is i64) {
		if bi.operator in num_ops {
			return num_ops[bi.operator](left_eval, right_eval)
		} else {
			// Unsupported operator
			return error_gen('eval', 'binary', errors_df.ErrorBinaryOperationUnsupported{
				type_of_value: 'num'
				supported:     num_ops.keys()
				found:         bi.operator
			})
		}
	} else if left_eval is string {
		match right_eval {
			string {
				if bi.operator != '+' {
					return error_gen('eval', 'binary', errors_df.ErrorBinaryOperationUnsupported{
						type_of_value: 'str'
						supported:     ['+']
						found:         bi.operator
					})
				}
				return '${left_eval as string}${right_eval as string}'
			}
			i64 {
				if bi.operator != '*' {
					return error_gen('eval', 'binary', errors_df.ErrorBinaryOperationUnsupported{
						type_of_value: 'str'
						supported:     ['+']
						found:         bi.operator
					})
				}
				return errors_df.gen_letter(left_eval, right_eval)
			}
			else {
				return error_gen('eval', 'binary', errors_df.ErrorEvalTypeMisMatch{
					left:  check_eval_name(left_eval)
					right: check_eval_name(right_eval)
					op:    bi.operator
				})
			}
		}
	}

	return error_gen('eval', 'binary', errors_df.ErrorUnsupported{})
}

pub struct Logical {
pub mut:
	operator string
	left     Node
	right    Node
}

fn (lo Logical) eval(process_id []string) !EvalOutput {
	left_eval := lo.left.eval(process_id)!
	right_eval := lo.right.eval(process_id)!

	if lo.operator in num_ops {
		return num_ops[lo.operator](left_eval, right_eval)
	}

	return error_gen('eval', 'logical', errors_df.ErrorUnexpectedToken{
		token: lo.operator
	})
}

pub struct IndexExpression {
pub mut:
	base    Identifier
	indexes []Node
}

fn (ie IndexExpression) eval(process_id []string) !EvalOutput {
	mut output_val := ie.base.eval(process_id)!
	mut name_of_var := ie.base.token.value
	for index in ie.indexes {
		output_val, name_of_var = output_val.get_indexed_value(index.eval(process_id)!,
			name_of_var)!
	}

	return output_val
}

pub struct TableKey {
pub mut:
	key   Litreal
	value Node
}

fn (tk TableKey) eval(process_id []string) !EvalOutput {
	return tk.value.eval(process_id)!
}

pub struct TableConstructorExpression {
pub mut:
	fields []Node
}

fn (te TableConstructorExpression) eval(process_id []string) !EvalOutput {
	mut set_array := false
	mut table := Table{
		table:  {}
		is_arr: true
		len:    0
	}
	mut i := 0
	for field in te.fields {
		match field {
			TableKey {
				if !table.is_arr || !set_array {
					set_array = true
					table.is_arr = false
					table.table['${field.key.value}'] = field.value.eval(process_id)!
					i++
				} else {
					return error_gen('eval', 'index_expression', errors_df.ErrorHaveToUseKeyInTable{})
				}
			}
			else {
				if table.is_arr || !set_array {
					set_array = true
					table.is_arr = true
					table.table['${i}'] = field.eval(process_id)!
					i++
				} else {
					return error_gen('eval', 'index_expression', errors_df.ErrorHaveToUseKeyInTable{})
				}
			}
		}
	}

	table.len = i
	return table
}

pub struct DelStatement {
pub mut:
	variable Identifier
}

fn (ds DelStatement) eval(process_id []string) !EvalOutput {
	processes := gen_map_key(ds.variable.from, process_id, ds.variable.token.sep_value)

	if processes.len > 0 {
		identifier_value_map.delete(processes[0])
		return i64(1)
	}
	return i64(0)
}

pub struct VBlock {
pub mut:
	v_code string
	from   []string
}

fn (vb VBlock) eval(process_id []string) !EvalOutput {
	res := os.execute_opt('v -e \'${replace_identifier_in_string(vb.v_code, vb.from, process_id)!.replace('return(',
		'print(')}\'')!

	return to_int_f64_or_str(res.output)

	// mut cmd := os.Command{
	// 	path: 'v -e \'${replace_identifier_in_string(vb.v_code, vb.from, process_id)!.replace('return(',
	// 		'println(')}\''
	// }

	// cmd.start()!
	// for !cmd.eof {
	// 	line := cmd.read_line()
	// 	if line != '' {
	// 		ret_val += line
	// 	}
	// }
	// cmd.close()!
}

pub struct ImportStatement {
pub mut:
	path         string
	module_      string
	from_path    string // path of parent
	from_module_ []string
}

fn (im ImportStatement) eval(process_id []string) !EvalOutput {
	return '${im.from_module_.join('.')}.${im.module_}'
}

pub struct Identifier {
pub mut:
	token token.Identifier
	from  []string
}

fn (i Identifier) eval(process_id []string) !EvalOutput {
	processes := gen_map_key(i.from, process_id, i.token.sep_value)
	for process in processes {
		if process in identifier_value_map {
			unsafe {
				return identifier_value_map[process]
			}
		}
	}

	return error_gen('eval', 'identifier', errors_df.ErrorUndefinedToken{ token: i.token.value })
}

fn (i Identifier) assign(process_id []string, process string, value EvalOutput) {
	if process_id.len > 0 && process_id[process_id.len - 1] != '' {
		identifier_assignment_tracker[process_id[process_id.len - 1]] << process
	}
	identifier_value_map[process] = value
	return
}

fn (i Identifier) set_value(process_id []string, node Node, force bool, eval_output EvalOutput, use_eval bool) ! {
	processes := gen_map_key(i.from, process_id, i.token.sep_value)

	if !force {
		mut didnt_find_in_any := true
		for cur_process := 0; cur_process <= processes.len - 1; cur_process++ {
			if processes[cur_process] in identifier_value_map
				|| '${processes[cur_process]}.__module__' in identifier_value_map {
				didnt_find_in_any = false
				break
			}
		}

		if didnt_find_in_any {
			return error_gen('eval', 'identifier', errors_df.ErrorTryingToSetOnUndefined{
				token: i.token.value
			})
		}
	}

	mut value := eval_output

	if !use_eval {
		match node {
			FunctionStore {
				value = EvalOutput(node)
			}
			else {
				value = node.eval(process_id)!
			}
		}
	}

	for process in processes.reverse() {
		if process in identifier_value_map {
			identifier_value_map[process] = value
			return
		}

		if force {
			i.assign(process_id, process, value)
			return
		}
	}

	if processes.len > 0 {
		i.assign(process_id, processes[processes.len - 1], value)
	}
}

pub struct AssignmentStatement {
pub mut:
	hint     string @[required]
	variable Node
	init     Node
}

fn (asss AssignmentStatement) eval(process_id []string) !EvalOutput {
	var_ := asss.variable
	match var_ {
		Identifier {
			if var_.token.reserved != '' {
				return error_gen('eval', 'assignment', errors_df.ErrorTryingToUseReservedIdentifier{
					identifier: var_.token.value
				})
			}
			match asss.hint {
				'=' {}
				'?=' {
					if !var_.eval(process_id)!.is_empty() {
						return i64(0)
					}
				}
				'<<', '>>' {
					mut eval_output := var_.eval(process_id)!
					ident_token := eval_output.get_token_type()
					if ident_token == 'table' || ident_token == 'array' {
						return eval_output.update_indexed_value([
							Node(Litreal{
								hint:  .integer
								value: '-1'
								from:  var_.from
							}),
						], asss.init, var_.from.join('.'), process_id, asss.hint)
					}
					return error_gen('eval', 'push', errors_df.ErrorUnexpectedToken{
						token: asss.hint
					})
				}
				else {
					return error_gen('eval', 'assignment', errors_df.ErrorUnexpectedToken{
						token: asss.hint
					})
				}
			}

			var_.set_value(process_id, asss.init, false, '', false)!
			return i64(1)
		}
		IndexExpression {
			match asss.hint {
				'<<', '>>', '=' {}
				else {
					return error_gen('eval', 'insert', errors_df.ErrorUnexpectedToken{
						token: asss.hint
					})
				}
			}
			mut eval_output := var_.base.eval(process_id)!
			return eval_output.update_indexed_value(var_.indexes, asss.init, var_.base.from.join('.'),
				process_id, asss.hint)
		}
		else {}
	}

	return error_gen('eval', 'assignment', errors_df.ErrorCanAssignToIdenifiersArrayAndTablesOnly{})
}

pub struct UnaryExpression {
pub mut:
	operator string
	argument Node
}

fn (unary_ &UnaryExpression) eval(process_id []string) !EvalOutput {
	match unary_.operator {
		'-' {
			argument_evalualted := unary_.argument.eval(process_id)!
			match argument_evalualted {
				i64 {
					return argument_evalualted * -1
				}
				f64 {
					return argument_evalualted * -1
				}
				else {
					return error_gen('eval', 'unary', errors_df.ErrorNeededAfterInit{'-', argument_evalualted.get_token_type()})
				}
			}
		}
		'!' {
			return if !is_condition_met(process_id, unary_.argument)! { i64(1) } else { i64(0) }
		}
		else {
			return error_gen('eval', 'unary', errors_df.ErrorUnexpectedToken{unary_.operator})
		}
	}
}

pub enum Conditions {
	if_clause
	else_if_clause
	else_clause
}

pub struct ConditionClause {
pub mut:
	hint      Conditions
	condition ?Node
	body      []Node
}

fn (cond &ConditionClause) eval(process_id []string) !EvalOutput {
	if cond.hint != Conditions.else_clause && cond.condition == none {
		return error_gen('eval', 'condition', errors_df.ErrorNoConditionsProvided{
			token: '${cond.hint}'
		})
	}

	if is_condition_met(process_id, cond.condition)! {
		if cond.body.len == 1 {
			return Table{
				table:  {
					'0': 'value'
					'1': cond.body[0].eval(process_id)!
				}
				is_arr: false
			}
		}
		for val in cond.body {
			val.eval(process_id)!
		}

		return Table{
			table:  {
				'0': 'value'
				'1': i64(1)
			}
			is_arr: false
		}
	}

	return Table{
		table:  {
			'0': 'continue'
		}
		is_arr: false
	}
}

pub struct IfStatement {
pub mut:
	clauses []Node
}

fn (if_statement IfStatement) eval(process_id []string) !EvalOutput {
	for clause in if_statement.clauses {
		ret_value := clause.eval(process_id)! as Table
		if ret_value.table['0'] or { break } as string == 'value' {
			return ret_value.table['1'] or { break }
		}
	}

	return i64(0)
}

pub struct BreakStatement {}

fn (br BreakStatement) eval(process_id []string) !EvalOutput {
	if process_id.len > 0 {
		program_state_map[process_id[process_id.len - 1]] = ProgramStateStore{
			hint:  ProgramState.break_
			value: i64(0)
		}
		return i64(1)
	}
	return i64(0)
}

pub struct ReturnStatement {
pub mut:
	value Node
}

fn (rt ReturnStatement) eval(process_id []string) !EvalOutput {
	if process_id.len > 0 {
		program_state_map[process_id[process_id.len - 1]] = ProgramStateStore{
			hint:  ProgramState.return_
			value: rt.value.eval(process_id)!
		}
		return i64(1)
	}
	return i64(0)
}

pub struct ContinueStatement {}

fn (br ContinueStatement) eval(process_id []string) !EvalOutput {
	if process_id.len > 0 {
		program_state_map[process_id[process_id.len - 1]] = ProgramStateStore{
			hint:  ProgramState.continue_
			value: i64(0)
		}
		return i64(1)
	}

	return i64(0)
}

pub struct ForStatement {
pub mut:
	condition ?Node
	body      []Node
}

fn (for_st ForStatement) eval(process_id []string) !EvalOutput {
	new_process_id := gen_process_id(process_id[process_id.len - 1])
	mut all_processes := process_id.clone()
	all_processes << new_process_id

	identifier_assignment_tracker[new_process_id] = []
	defer {
		delete_process_memory(new_process_id)
	}

	for {
		if is_condition_met(all_processes, for_st.condition)! {
			for st in for_st.body {
				if new_process_id !in program_state_map {
					st.eval(all_processes)!
				} else {
					break
				}
			}
		} else {
			program_state_map.delete(new_process_id)
			break
		}

		match program_state_map[new_process_id].hint {
			.return_ {
				break
			}
			.continue_ {
				program_state_map.delete(new_process_id)
			}
			.break_ {
				program_state_map.delete(new_process_id)
				break
			}
			.@none {}
		}
	}

	return i64(1)
}

pub struct FunctionDeclaration {
pub mut:
	name       Identifier
	parameters []Identifier
	body       []Node
	scope      string @[required]
	prev_scope string @[required]
}

pub fn (fd FunctionDeclaration) eval(process_id []string) !EvalOutput {
	if fd.name.token.reserved != '' {
		return error_gen('eval', 'function_declaration', errors_df.ErrorTryingToUseReservedIdentifier{
			identifier: fd.name.token.value
		})
	}

	mut new_processes := process_id.clone()
	new_processes << fd.prev_scope

	processes := gen_map_key(fd.name.from, new_processes, fd.name.token.sep_value)

	if processes[processes.len - 1] in identifier_value_map {
		return error_gen('eval', 'function_declaration', errors_df.ErrorFunctionAlreadyDeclared{
			function_name: '${fd.name.token.value}'
		})
	}

	identifier_value_map[processes[processes.len - 1]] = FunctionStore{
		parameters: fd.parameters
		body:       fd.body
		scope:      fd.scope
	}

	return i64(1)
}

pub struct FunctionDeclared {}

fn (fdd FunctionDeclared) eval(process_id []string) !EvalOutput {
	return i64(1)
}

pub struct CallExpression {
pub mut:
	call_path string @[required]
	base      Node // Identifier and Indexed Expression
	arguments []Node
}

fn (ce CallExpression) eval(process_id []string) !EvalOutput {
	new_process_id := gen_process_id('')
	mut all_processes := process_id.clone()
	all_processes << new_process_id

	identifier_assignment_tracker[new_process_id] = []
	defer {
		delete_process_memory(new_process_id)
	}

	base := ce.base
	match base {
		IndexExpression {
			function_from_value := base.eval(process_id)!
			match function_from_value {
				FunctionStore {

					processes := gen_map_key(base.base.from, process_id, base.base.token.sep_value)
					mut in_process := ""
					for process in processes {
						if process in identifier_value_map {
							in_process = process
							break
						}
					}

					program_state_map[new_process_id] = ProgramStateStore{
						hint:  .@none
						value: in_process
					}

					return function_from_value.execute(ce, all_processes)
				}
				else {
					return error_gen('eval', 'call_exp', errors_df.ErrorTryingToCallNonFunctionIdentifier{})
				}
			}
		}
		Identifier {
			map_all_processes := gen_map_key(base.from, all_processes, base.token.sep_value)

			match base.token.reserved {
				'' {
					if base.token.value in std_functions {
						unsafe {
							x := std_functions[base.token.value]

							if ce.call_path == '${base_dir_path}${x.path}' {
								return x.func(all_processes, ce.arguments)
							}
						}
					}
					for process in map_all_processes {
						if process in identifier_value_map {
							unsafe {
								func := identifier_value_map[process]
								match func {
									FunctionStore {
										all_processes << func.scope
										return func.execute(ce, all_processes)
									}
									else {
										return error_gen('eval', 'call_exp', errors_df.ErrorTryingToCallNonFunctionIdentifier{})
									}
								}
							}
						}
					}

					return error_gen('eval', 'call_exp', errors_df.ErrorUndefinedToken{
						token: base.token.value
					})
				}
				else {
					if base.token.reserved in default_call_operations {
						return default_call_operations[base.token.reserved](all_processes,
							base, ce.arguments)
					}

					return error_gen('eval', 'call_exp', errors_df.ErrorUndefinedToken{
						token: base.token.value
					})
				}
			}
		}
		else {
			return error_gen('eval', 'call_exp', errors_df.ErrorTryingToCallNonFunctionIdentifier{})
		}
	}

	// for args in ce.arguments {
	// 	args.eval()!
	// }

	return i64(1)
	// return error_gen('eval', 'call_exp', errors_df.ErrorUnsupported{})
}

// type Stat = Node
