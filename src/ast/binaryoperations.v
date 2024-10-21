module ast

import errors_df


const num_ops = {
	'+':  fn (left EvalNumberOutput, right EvalNumberOutput) !EvalOutput {
		if left is int && right is int {
			return EvalNumberOutput(left + right)
		} else if left is int && right is f64 {
			return EvalNumberOutput(left + right)
		} else if left is f64 && right is int {
			return EvalNumberOutput(left + right)
		} else if left is f64 && right is f64 {
			return EvalNumberOutput(left + right)
		}
		return error_gen('eval', 'op', errors_df.ErrorUnexpectedWhile{
			while_doing: 'using "+" operator'
		})
	}
	'-':  fn (left EvalNumberOutput, right EvalNumberOutput) !EvalOutput {
		if left is int && right is int {
			return EvalNumberOutput(left - right)
		} else if left is int && right is f64 {
			return EvalNumberOutput(left - right)
		} else if left is f64 && right is int {
			return EvalNumberOutput(left - right)
		} else if left is f64 && right is f64 {
			return EvalNumberOutput(left - right)
		}
		return error_gen('eval', 'op', errors_df.ErrorUnexpectedWhile{
			while_doing: 'using "-" operator'
		})
	}
	'*':  fn (left EvalNumberOutput, right EvalNumberOutput) !EvalOutput {
		if left is int && right is int {
			return EvalNumberOutput(left * right)
		} else if left is int && right is f64 {
			return EvalNumberOutput(left * right)
		} else if left is f64 && right is int {
			return EvalNumberOutput(left * right)
		} else if left is f64 && right is f64 {
			return EvalNumberOutput(left * right)
		}
		return error_gen('eval', 'op', errors_df.ErrorUnexpectedWhile{
			while_doing: 'using "*" operator'
		})
	}
	'/':  fn (left EvalNumberOutput, right EvalNumberOutput) !EvalOutput {
		if left is int && right is int {
			if right == 0 {
				return error_gen('eval', 'binary', errors_df.ErrorDivisionByZero{})
			}
			return EvalNumberOutput(left / right)
		} else if left is int && right is f64 {
			if right == 0.0 {
				return error_gen('eval', 'binary', errors_df.ErrorDivisionByZero{})
			}
			return EvalNumberOutput(left / right)
		} else if left is f64 && right is int {
			if right == 0 {
				return error_gen('eval', 'binary', errors_df.ErrorDivisionByZero{})
			}
			return EvalNumberOutput(left / right)
		} else if left is f64 && right is f64 {
			if right == 0.0 {
				return error_gen('eval', 'binary', errors_df.ErrorDivisionByZero{})
			}
			return EvalNumberOutput(left / right)
		}
		return error_gen('eval', 'op', errors_df.ErrorUnexpectedWhile{
			while_doing: 'using "*" operator'
		})
	}
	'==': fn (left EvalNumberOutput, right EvalNumberOutput) !EvalOutput {
		if left == right {
			return EvalNumberOutput(1)
		}
		return EvalNumberOutput(0)
	}
}