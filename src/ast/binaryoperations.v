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
			return 1
		}
		return 0
	}
	'!=': fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left != right {
			return 1
		}
		return 0
	}
	'||': fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left == EvalOutput(1) || right == EvalOutput(1) {
			return 1
		}
		return 0
	}
	'&&': fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left == EvalOutput(1) && right == EvalOutput(1) {
			return 1
		}
		return 0
	}
	'<':  fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left is int && right is int {
			return if left < right { 1 } else { 0 }
		} else if left is int && right is f64 {
			return if left < right { 1 } else { 0 }
		} else if left is f64 && right is int {
			return if left < right { 1 } else { 0 }
		} else if left is f64 && right is f64 {
			return if left < right { 1 } else { 0 }
		}
		return error_gen('eval', 'logical', errors_df.ErrorUnexpectedWhile{
			while_doing: 'using "<" operator'
		})
	}
	'>':  fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left is int && right is int {
			return if left > right { 1 } else { 0 }
		} else if left is int && right is f64 {
			return if left > right { 1 } else { 0 }
		} else if left is f64 && right is int {
			return if left > right { 1 } else { 0 }
		} else if left is f64 && right is f64 {
			return if left > right { 1 } else { 0 }
		}
		return error_gen('eval', 'logical', errors_df.ErrorUnexpectedWhile{
			while_doing: 'using ">" operator'
		})
	}
	'>=': fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left is int && right is int {
			return if left >= right { 1 } else { 0 }
		} else if left is int && right is f64 {
			return if left >= right { 1 } else { 0 }
		} else if left is f64 && right is int {
			return if left >= right { 1 } else { 0 }
		} else if left is f64 && right is f64 {
			return if left >= right { 1 } else { 0 }
		}
		return error_gen('eval', 'logical', errors_df.ErrorUnexpectedWhile{
			while_doing: 'using ">=" operator'
		})
	}
	'<=': fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left is int && right is int {
			return if left <= right { 1 } else { 0 }
		} else if left is int && right is f64 {
			return if left <= right { 1 } else { 0 }
		} else if left is f64 && right is int {
			return if left <= right { 1 } else { 0 }
		} else if left is f64 && right is f64 {
			return if left <= right { 1 } else { 0 }
		}
		return error_gen('eval', 'logical', errors_df.ErrorUnexpectedWhile{
			while_doing: 'using "<=" operator'
		})
	}
}
