module ast

import token
import strconv
import errors_df

type EvalOutput = string | int | f64

__global identifier_value_map = map[string]EvalOutput{}

pub interface Node {
	eval() !EvalOutput
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

fn (li Litreal) eval() !EvalOutput {
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

fn (bi Binary) eval() !EvalOutput {
	left_eval := bi.left.eval()!
	right_eval := bi.right.eval()!

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

fn (lo Logical) eval() !EvalOutput {
	left_eval := lo.left.eval()!
	right_eval := lo.right.eval()!

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

fn (i Identifier) eval() !EvalOutput {
	return identifier_value_map['${i.from}_${i.token.value}'] or {
		return error_gen('eval', 'identifier', errors_df.ErrorUndefinedToken{ token: i.token.value })
	}
	// return error_gen('eval', 'call_exp', errors_df.ErrorUnsupported{})
}

fn (i Identifier) set_value(output EvalOutput) {
	identifier_value_map['${i.from}_${i.token.value}'] = output
}

pub struct AssignmentStatement {
pub mut:
	variable Identifier
	init     Node
}

fn (asss AssignmentStatement) eval() !EvalOutput {
	if asss.variable.token.reserved != "" {
		return error_gen('eval', 'assignment', errors_df.ErrorTryingToUseReservedIdentifier{ identifier: asss.variable.token.value })
		
	}
	asss.variable.set_value(asss.init.eval()!)
	return EvalOutput(0)
}

pub enum Conditions {
	if_clause
	else_if_clause
	else_clause
}

pub struct ConditionClause {
	pub mut:
	hint Conditions
	condition &Node
	body []Node
}

fn (c &ConditionClause) is_condition_met() !bool {
	if c.condition == unsafe { nil } {
		return false
	}
	cond_eval := c.condition.eval()!

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


fn (cond &ConditionClause) eval() !EvalOutput {
	if cond.hint == Conditions.else_clause || cond.is_condition_met()! {
		for val in cond.body {
			val.eval()!
		}
	}else {
		return error_gen('eval', 'condition', errors_df.ErrorUndefinedToken{
			token: "$cond.hint"
		}) 
	}

	return 0
}

pub struct IfStatement {
	pub mut:
	clauses []Node
}

fn (if_statement IfStatement) eval() !EvalOutput {

	for clause in if_statement.clauses {
		clause.eval()!
	}

	return 0
}

pub struct CallExpression {
pub mut:
	base      Identifier
	arguments []Node
}

fn (ce CallExpression) eval() !EvalOutput {
	match ce.base.token.reserved {
		'print' {
			print_reserved_function(ce.arguments, false)!
		}
		'println' {
			print_reserved_function(ce.arguments, true)!
		}
		'input' {
			if ce.arguments.len != 1 {
				return error_gen('eval', 'input_eval', errors_df.ErrorArgumentsMisMatch{
					func_name:       ce.base.token.value
					expected_amount: '1'
					found_amount:    '${ce.arguments.len}'
				})
			}
			return input_reserved_function(ce.arguments[0])
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
