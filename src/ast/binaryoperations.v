module ast

import math
import errors_df

// Helper function to convert numeric EvalOutput to f64
fn to_f64(val EvalOutput) ?f64 {
	return match val {
		i64 { f64(val) }
		f64 { val }
		else { none }
	}
}

// Helper function to check if value is numeric (i64 or f64)
fn is_numeric(val EvalOutput) bool {
	return val is i64 || val is f64
}

// Helper function to create type error for operations
fn op_type_error(left EvalOutput, right EvalOutput, op string) errors_df.DfError {
	return error_gen('eval', 'op', errors_df.ErrorCantUseTokenOfTypeForOperation{
		first_token_type:  left.get_token_type()
		second_token_type: right.get_token_type()
		operator:          op
	})
}

// Helper for comparison operations
fn compare_numeric(left EvalOutput, right EvalOutput, op string, cmp fn (f64, f64) bool) !EvalOutput {
	left_f := to_f64(left) or { return op_type_error(left, right, op) }
	right_f := to_f64(right) or { return op_type_error(left, right, op) }
	return if cmp(left_f, right_f) { i64(1) } else { i64(0) }
}

const num_ops = {
	'+': fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left is i64 && right is i64 {
			return EvalOutput(left + right)
		}
		left_f := to_f64(left) or { return op_type_error(left, right, '+') }
		right_f := to_f64(right) or { return op_type_error(left, right, '+') }
		return EvalOutput(left_f + right_f)
	}
	'-': fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left is i64 && right is i64 {
			return EvalOutput(left - right)
		}
		left_f := to_f64(left) or { return op_type_error(left, right, '-') }
		right_f := to_f64(right) or { return op_type_error(left, right, '-') }
		return EvalOutput(left_f - right_f)
	}
	'*': fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left is i64 && right is i64 {
			return EvalOutput(left * right)
		}
		left_f := to_f64(left) or { return op_type_error(left, right, '*') }
		right_f := to_f64(right) or { return op_type_error(left, right, '*') }
		return EvalOutput(left_f * right_f)
	}
	'^': fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left is i64 && right is i64 {
			return EvalOutput(i64(math.powi(left, right)))
		} else if left is f64 && right is f64 {
			return EvalOutput(math.pow(left, right))
		}
		return op_type_error(left, right, '^')
	}
	'/': fn (left EvalOutput, right EvalOutput) !EvalOutput {
		left_f := to_f64(left) or { return op_type_error(left, right, '/') }
		right_f := to_f64(right) or { return op_type_error(left, right, '/') }
		if right_f == 0.0 {
			return error_gen('eval', 'binary', errors_df.ErrorDivisionByZero{})
		}
		return EvalOutput(left_f / right_f)
	}
	'%': fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left is i64 && right is i64 {
			return EvalOutput(left % right)
		}
		left_f := to_f64(left) or { return op_type_error(left, right, '%') }
		right_f := to_f64(right) or { return op_type_error(left, right, '%') }
		return EvalOutput(math.fmod(left_f, right_f))
	}
	'==': fn (left EvalOutput, right EvalOutput) !EvalOutput {
		return if left == right { i64(1) } else { i64(0) }
	}
	'!=': fn (left EvalOutput, right EvalOutput) !EvalOutput {
		return if left != right { i64(1) } else { i64(0) }
	}
	'||': fn (left EvalOutput, right EvalOutput) !EvalOutput {
		return if left == EvalOutput(i64(1)) || right == EvalOutput(i64(1)) { i64(1) } else { i64(0) }
	}
	'&&': fn (left EvalOutput, right EvalOutput) !EvalOutput {
		return if left == EvalOutput(i64(1)) && right == EvalOutput(i64(1)) { i64(1) } else { i64(0) }
	}
	'<': fn (left EvalOutput, right EvalOutput) !EvalOutput {
		return compare_numeric(left, right, '<', fn (a f64, b f64) bool { return a < b })
	}
	'>': fn (left EvalOutput, right EvalOutput) !EvalOutput {
		return compare_numeric(left, right, '>', fn (a f64, b f64) bool { return a > b })
	}
	'>=': fn (left EvalOutput, right EvalOutput) !EvalOutput {
		return compare_numeric(left, right, '>=', fn (a f64, b f64) bool { return a >= b })
	}
	'<=': fn (left EvalOutput, right EvalOutput) !EvalOutput {
		return compare_numeric(left, right, '<=', fn (a f64, b f64) bool { return a <= b })
	}
}
