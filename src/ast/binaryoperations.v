module ast

import errors_df


const num_ops = {
	'+':  fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left is int && right is int {
			return EvalOutput(left + right)
		} else if left is int && right is f64 {
			return EvalOutput(left + right)
		} else if left is f64 && right is int {
			return EvalOutput(left + right)
		} else if left is f64 && right is f64 {
			return EvalOutput(left + right)
		}
		return error_gen('eval', 'op', errors_df.ErrorUnexpectedWhile{
			while_doing: 'using "+" operator'
		})
	}
	'-':  fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left is int && right is int {
			return EvalOutput(left - right)
		} else if left is int && right is f64 {
			return EvalOutput(left - right)
		} else if left is f64 && right is int {
			return EvalOutput(left - right)
		} else if left is f64 && right is f64 {
			return EvalOutput(left - right)
		}
		return error_gen('eval', 'op', errors_df.ErrorUnexpectedWhile{
			while_doing: 'using "-" operator'
		})
	}
	'*':  fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left is int && right is int {
			return EvalOutput(left * right)
		} else if left is int && right is f64 {
			return EvalOutput(left * right)
		} else if left is f64 && right is int {
			return EvalOutput(left * right)
		} else if left is f64 && right is f64 {
			return EvalOutput(left * right)
		}
		return error_gen('eval', 'op', errors_df.ErrorUnexpectedWhile{
			while_doing: 'using "*" operator'
		})
	}
	'/':  fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left is int && right is int {
			if right == 0 {
				return error_gen('eval', 'binary', errors_df.ErrorDivisionByZero{})
			}
			return EvalOutput(left / right)
		} else if left is int && right is f64 {
			if right == 0.0 {
				return error_gen('eval', 'binary', errors_df.ErrorDivisionByZero{})
			}
			return EvalOutput(left / right)
		} else if left is f64 && right is int {
			if right == 0 {
				return error_gen('eval', 'binary', errors_df.ErrorDivisionByZero{})
			}
			return EvalOutput(left / right)
		} else if left is f64 && right is f64 {
			if right == 0.0 {
				return error_gen('eval', 'binary', errors_df.ErrorDivisionByZero{})
			}
			return EvalOutput(left / right)
		}
		return error_gen('eval', 'op', errors_df.ErrorUnexpectedWhile{
			while_doing: 'using "*" operator'
		})
	}
	'==': fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left == right {
			return EvalOutput(1)
		}
		return EvalOutput(0)
	}
}