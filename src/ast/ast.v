module ast

import token
import strconv
import errors_df
import rand

type EvalOutput = string | int | f64

pub fn (evl EvalOutput) is_empty() bool {
	match evl {
		string {
			return evl == ''
		}
		int {
			return evl == 0
		}
		f64 {
			return evl == 0
		}
	}
}

fn gen_process_id(process_id string) string {
	return if process_id != '' { process_id } else { rand.ascii(14) }
}

fn gen_map_key(from string, process_id string, value string) string {
	return '${from}${if process_id != '' {
		'.' + process_id
	} else {
		''
	}}.${value}'
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

struct FunctionStore {
	parameters []Identifier
	body       []Node
}

fn (fs FunctionStore) execute(ce CallExpression, process_id string) !EvalOutput {
	if fs.parameters.len != ce.arguments.len {
		return error_gen('eval', 'call_exp', errors_df.ErrorMismatch{
			expected: '${fs.parameters.len} parameters for function ${ce.base.from}.${ce.base.token.value}(${fs.parameters.map(it.token.value).join(', ')})'
			found:    '${ce.arguments.len} parameters were passed'
		})
	}

	for i := 0; i < fs.parameters.len; i++ {
		fs.parameters[i].set_value(process_id, ce.arguments[i].eval(process_id)!, true)
	}

	for val in fs.body {
		val.eval(process_id)!
		program_store := program_state_map[process_id]
		match program_store.hint {
			.return_ {
				program_state_map.delete(process_id)
				return program_store.value
			}
			else {}
		}
	}

	return 0
}

__global identifier_value_map = map[string]EvalOutput{}

__global function_value_map = map[string]FunctionStore{}

__global program_state_map = map[string]ProgramStateStore{}


pub fn set_if_module_not_already_init(full_module_ string,  module_ string) bool {
	if "${full_module_}.__module__" in identifier_value_map {
		return false
	}

	identifier_value_map["${full_module_}.__module__"] = module_
	
	return true
}

pub interface Node {
	eval(process_id string) !EvalOutput
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
}

fn (li Litreal) eval(process_id string) !EvalOutput {
	match li.hint {
		.integer {
			return EvalOutput(li.value.int())
		}
		.floating_point {
			return EvalOutput(strconv.atof64(li.value)!)
		}
		.str {
			return li.value
		}
		.boolean {
			if li.value == 'true' {
				return 1
			}
			return 0
		}
		.null {
			return 0
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

fn (bi Binary) eval(process_id string) !EvalOutput {
	left_eval := bi.left.eval(process_id)!
	right_eval := bi.right.eval(process_id)!

	if (left_eval is f64 && right_eval is f64) || (left_eval is int && right_eval is int) {
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
			int {
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

fn (lo Logical) eval(process_id string) !EvalOutput {
	left_eval := lo.left.eval(process_id)!
	right_eval := lo.right.eval(process_id)!

	if lo.operator in num_ops {
		return num_ops[lo.operator](left_eval, right_eval)
	}

	return error_gen('eval', 'logical', errors_df.ErrorUnexpectedToken{
		token: lo.operator
	})
}

pub struct ImportStatement {
pub mut:
	path string
	module_ string
	from_path  string // path of parent
	from_module_  string
}

fn (im ImportStatement) eval(process_id string) !EvalOutput {
	return '${im.from_module_}.${im.module_}'
	// return error_gen('eval', 'call_exp', errors_df.ErrorUnsupported{})
}

pub struct Identifier {
pub mut:
	token token.Identifier
	from  string
}

fn (i Identifier) eval(process_id string) !EvalOutput {
	return identifier_value_map[gen_map_key(i.from, process_id, i.token.value)] or {
		if process_id != '' && '${i.from}.${i.token.value}' in identifier_value_map {
			unsafe {
				return identifier_value_map['${i.from}.${i.token.value}']
			}
		}
		return error_gen('eval', 'identifier', errors_df.ErrorUndefinedToken{ token: i.token.value })
	}
	// return error_gen('eval', 'call_exp', errors_df.ErrorUnsupported{})
}

fn (i Identifier) set_value(process_id string, output EvalOutput, force bool) {
	if gen_map_key(i.from, process_id, i.token.value) in identifier_value_map || force {
		identifier_value_map[gen_map_key(i.from, process_id, i.token.value)] = output
		return
	}

	if '${i.from}.${i.token.value}' in identifier_value_map {
		identifier_value_map['${i.from}.${i.token.value}'] = output
		return
	}

	identifier_value_map[gen_map_key(i.from, process_id, i.token.value)] = output
}

pub struct AssignmentStatement {
pub mut:
	hint     string @[required]
	variable Identifier
	init     Node
}

fn (asss AssignmentStatement) eval(process_id string) !EvalOutput {
	if asss.variable.token.reserved != '' {
		return error_gen('eval', 'assignment', errors_df.ErrorTryingToUseReservedIdentifier{
			identifier: asss.variable.token.value
		})
	}

	match asss.hint {
		'=' {}
		'?=' {
			if !asss.variable.eval(process_id)!.is_empty() {
				return 0
			}
		}
		else {
			return error_gen('eval', 'assignment', errors_df.ErrorUnexpectedToken{
				token: asss.hint
			})
		}
	}

	asss.variable.set_value(process_id, asss.init.eval(process_id)!, false)
	return 1
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

fn is_condition_met(process_id string, condition ?Node) !bool {
	cond_eval := condition or { return true }
		.eval(process_id)!

	match cond_eval {
		string {
			return cond_eval != ''
		}
		int {
			return cond_eval == 1
		}
		f64 {
			return cond_eval == 1.0
		}
	}
}

fn (cond &ConditionClause) eval(process_id string) !EvalOutput {
	if cond.hint != Conditions.else_clause && cond.condition == none {
		return error_gen('eval', 'condition', errors_df.ErrorNoConditionsProvided{
			token: '${cond.hint}'
		})
	}

	if is_condition_met(process_id, cond.condition)! {
		for val in cond.body {
			val.eval(process_id)!
		}

		return 1
	}

	return 0
}

pub struct IfStatement {
pub mut:
	clauses []Node
}

fn (if_statement IfStatement) eval(process_id string) !EvalOutput {
	for clause in if_statement.clauses {
		if clause.eval(process_id)! as int == 1 {
			break
		}
	}

	return 1
}

pub struct BreakStatement {}

fn (br BreakStatement) eval(process_id string) !EvalOutput {
	program_state_map[process_id] = ProgramStateStore{
		hint:  ProgramState.break_
		value: 0
	}
	return 1
}

pub struct ReturnStatement {
pub mut:
	value Node
}

fn (rt ReturnStatement) eval(process_id string) !EvalOutput {
	program_state_map[process_id] = ProgramStateStore{
		hint:  ProgramState.return_
		value: rt.value.eval(process_id)!
	}
	return 1
}

pub struct ContinueStatement {}

fn (br ContinueStatement) eval(process_id string) !EvalOutput {
	program_state_map[process_id] = ProgramStateStore{
		hint:  ProgramState.continue_
		value: 0
	}
	return 1
}

pub struct ForStatement {
pub mut:
	condition ?Node
	body      []Node
}

fn (for_st ForStatement) eval(process_id string) !EvalOutput {
	new_process_id := gen_process_id(process_id)
	for {
		if is_condition_met(new_process_id, for_st.condition)! {
			for st in for_st.body {
				if new_process_id !in program_state_map {
					st.eval(new_process_id)!
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

	return 0
}

pub struct FunctionDeclaration {
pub mut:
	name       Identifier
	parameters []Identifier
	body       []Node
}

fn (fd FunctionDeclaration) eval(process_id string) !EvalOutput {
	if fd.name.token.reserved != '' {
		return error_gen('eval', 'function_declaration', errors_df.ErrorTryingToUseReservedIdentifier{
			identifier: fd.name.token.value
		})
	}

	if '${fd.name.from}.${fd.name}' in function_value_map {
		return error_gen('eval', 'function_declaration', errors_df.ErrorFunctionAlreadyDeclared{
			function_name: '${fd.name.token.value}'
		})
	}

	function_value_map[gen_map_key(fd.name.from, process_id, fd.name.token.value)] = FunctionStore{
		parameters: fd.parameters
		body:       fd.body
	}

	return 1
}

pub struct CallExpression {
pub mut:
	base      Identifier
	arguments []Node
}

fn (ce CallExpression) eval(process_id string) !EvalOutput {
	new_process_id := gen_process_id(process_id)
	match ce.base.token.reserved {
		'print' {
			print_reserved_function(new_process_id, ce.arguments, false)!
		}
		'println' {
			print_reserved_function(new_process_id, ce.arguments, true)!
		}
		'input' {
			if ce.arguments.len != 1 {
				return error_gen('eval', 'input_eval', errors_df.ErrorArgumentsMisMatch{
					func_name:       ce.base.token.value
					expected_amount: '1'
					found_amount:    '${ce.arguments.len}'
				})
			}
			return input_reserved_function(new_process_id, ce.arguments[0])
		}
		'' {
			return function_value_map[gen_map_key(ce.base.from, process_id, ce.base.token.value)] or {
				return function_value_map[gen_map_key(ce.base.from, '', ce.base.token.value)] or {
					return error_gen('eval', 'call_exp', errors_df.ErrorUndefinedToken{
						token: ce.base.token.value
					})
				}.execute(ce, new_process_id)
			}.execute(ce, new_process_id)
		}
		else {
			return error_gen('eval', 'call_exp', errors_df.ErrorUndefinedToken{
				token: ce.base.token.value
			})
		}
	}
	// for args in ce.arguments {
	// 	args.eval()!
	// }

	return EvalOutput(0)
	// return error_gen('eval', 'call_exp', errors_df.ErrorUnsupported{})
}

// type Stat = Node
