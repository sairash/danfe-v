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

pub fn gen_process_id() string {
	return rand.ascii(14)
}

enum ProgramState {
	@none
	break_
	continue_
}


__global identifier_value_map = map[string]EvalOutput{}


__global program_state_map = map[string]ProgramState{}

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
			return EvalOutput(strconv.atof_quick(li.value))
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

pub struct Identifier {
pub mut:
	token token.Identifier
	from  string
}

fn (i Identifier) eval(process_id string) !EvalOutput {
	return identifier_value_map['${i.from}${if process_id != '' {
		'.' + process_id
	} else {
		''
	}}.${i.token.value}'] or {
		if process_id != '' && '${i.from}.${i.token.value}' in identifier_value_map {
			unsafe {
				return identifier_value_map['${i.from}.${i.token.value}']
			}
		}
		return error_gen('eval', 'identifier', errors_df.ErrorUndefinedToken{ token: i.token.value })
	}
	// return error_gen('eval', 'call_exp', errors_df.ErrorUnsupported{})
}

fn (i Identifier) set_value(process_id string, output EvalOutput) {
	if '${i.from}${if process_id != '' {
		'.' + process_id
	} else {
		''
	}}.${i.token.value}' in identifier_value_map {
		identifier_value_map['${i.from}${if process_id != '' {
			'.' + process_id
		} else {
			''
		}}.${i.token.value}'] = output
		return
	}

	if '${i.from}.${i.token.value}' in identifier_value_map {
		identifier_value_map['${i.from}.${i.token.value}'] = output
		return
	}

	identifier_value_map['${i.from}${if process_id != '' {
		'.' + process_id
	} else {
		''
	}}.${i.token.value}'] = output
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

	asss.variable.set_value(process_id, asss.init.eval(process_id)!)
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
	program_state_map[process_id] = ProgramState.break_
	return 1
}

pub struct ContinueStatement {}

fn (br ContinueStatement) eval(process_id string) !EvalOutput {
	program_state_map[process_id] = ProgramState.continue_
	return 1
}

pub struct ForStatement {
pub mut:
	condition ?Node
	body      []Node
}

fn (for_st ForStatement) eval(process_id string) !EvalOutput {
	new_process_id := gen_process_id()
	for {
		if new_process_id in program_state_map {
			program_state_map.delete(new_process_id)
		}

		if is_condition_met(new_process_id, for_st.condition)! {
			for st in for_st.body {
				if new_process_id !in program_state_map {
					st.eval(new_process_id)!
				} else {
					break
				}
			}
		} else {
			break
		}

		if program_state_map[new_process_id] == ProgramState.break_ {
			program_state_map.delete(new_process_id)
			break
		}
	}

	return 0
}



pub struct CallExpression {
pub mut:
	from      string @[required]
	base      Identifier
	arguments []Node
}

fn (ce CallExpression) eval(process_id string) !EvalOutput {
	new_process_id := gen_process_id()
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
