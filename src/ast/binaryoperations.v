module ast

import math
import errors_df

const num_ops = {
	'+':  fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left is i64 && right is i64 {
			return EvalOutput(left + right)
		} else if left is i64 && right is f64 {
			return EvalOutput(left + right)
		} else if left is f64 && right is i64 {
			return EvalOutput(left + right)
		} else if left is f64 && right is f64 {
			return EvalOutput(left + right)
		}
		return error_gen('eval', 'op', errors_df.ErrorCantUseTokenOfTypeForOperaiton{
			first_token_type: left.get_token_type()
			second_token_type: right.get_token_type()
			operator: "+"
		})
	}
	'-':  fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left is i64 && right is i64 {
			return EvalOutput(left - right)
		} else if left is i64 && right is f64 {
			return EvalOutput(left - right)
		} else if left is f64 && right is i64 {
			return EvalOutput(left - right)
		} else if left is f64 && right is f64 {
			return EvalOutput(left - right)
		}
		return error_gen('eval', 'op', errors_df.ErrorCantUseTokenOfTypeForOperaiton{
			first_token_type: left.get_token_type()
			second_token_type: right.get_token_type()
			operator: "-"
		})
	}
	'*':  fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left is i64 && right is i64 {
			return EvalOutput(left * right)
		} else if left is i64 && right is f64 {
			return EvalOutput(left * right)
		} else if left is f64 && right is i64 {
			return EvalOutput(left * right)
		} else if left is f64 && right is f64 {
			return EvalOutput(left * right)
		}
		return error_gen('eval', 'op', errors_df.ErrorCantUseTokenOfTypeForOperaiton{
			first_token_type: left.get_token_type()
			second_token_type: right.get_token_type()
			operator: "*"
		})
	}
	'^':  fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left is i64 && right is i64 {
			return EvalOutput(i64(math.powi(left, right)))
		} else if left is f64 && right is f64 {
			return EvalOutput(math.pow(left, right))
		} 
		return error_gen('eval', 'op', errors_df.ErrorCantUseTokenOfTypeForOperaiton{
			first_token_type: left.get_token_type()
			second_token_type: right.get_token_type()
			operator: "^"
		})
	}
	'/':  fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left is i64 && right is i64 {
			if right == i64(0) {
				return error_gen('eval', 'binary', errors_df.ErrorDivisionByZero{})
			}
			return EvalOutput(left / right)
		} else if left is i64 && right is f64 {
			if right == i64(0.0) {
				return error_gen('eval', 'binary', errors_df.ErrorDivisionByZero{})
			}
			return EvalOutput(left / right)
		} else if left is f64 && right is i64 {
			if right == i64(0) {
				return error_gen('eval', 'binary', errors_df.ErrorDivisionByZero{})
			}
			return EvalOutput(left / right)
		} else if left is f64 && right is f64 {
			if right == i64(0.0) {
				return error_gen('eval', 'binary', errors_df.ErrorDivisionByZero{})
			}
			return EvalOutput(left / right)
		}
		return error_gen('eval', 'op', errors_df.ErrorCantUseTokenOfTypeForOperaiton{
			first_token_type: left.get_token_type()
			second_token_type: right.get_token_type()
			operator: "/"
		})
	}
	'%':  fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left is i64 && right is i64 {
			return EvalOutput(left % right)
		} else if left is i64 && right is f64 {
			return EvalOutput(math.fmod(left, right))
		} else if left is f64 && right is i64 {
			return EvalOutput(math.fmod(left, right))
		} else if left is f64 && right is f64 {
			return EvalOutput(math.fmod(left, right))
		}
		return error_gen('eval', 'op', errors_df.ErrorCantUseTokenOfTypeForOperaiton{
			first_token_type: left.get_token_type()
			second_token_type: right.get_token_type()
			operator: "%"
		})
	}
	'==': fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left == right {
			return i64(1)
		}
		return i64(0)
	}
	'!=': fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left != right {
			return i64(1)
		}
		return i64(0)
	}
	'||': fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left == EvalOutput(i64(1)) || right == EvalOutput(i64(1)) {
			return i64(1)
		}
		return i64(0)
	}
	'&&': fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left == EvalOutput(i64(1)) && right == EvalOutput(i64(1)) {
			return i64(1)
		}
		return i64(0)
	}
	'<':  fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left is i64 && right is i64 {
			return if left < right { i64(1) } else { i64(0) }
		} else if left is i64 && right is f64 {
			return if left < right { i64(1) } else { i64(0) }
		} else if left is f64 && right is i64 {
			return if left < right { i64(1) } else { i64(0) }
		} else if left is f64 && right is f64 {
			return if left < right { i64(1) } else { i64(0) }
		}
		return error_gen('eval', 'op', errors_df.ErrorCantUseTokenOfTypeForOperaiton{
			first_token_type: left.get_token_type()
			second_token_type: right.get_token_type()
			operator: "<"
		})
	}
	'>':  fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left is i64 && right is i64 {
			return if left > right { i64(1) } else { i64(0) }
		} else if left is i64 && right is f64 {
			return if left > right { i64(1) } else { i64(0) }
		} else if left is f64 && right is i64 {
			return if left > right { i64(1) } else { i64(0) }
		} else if left is f64 && right is f64 {
			return if left > right { i64(1) } else { i64(0) }
		}
		return error_gen('eval', 'op', errors_df.ErrorCantUseTokenOfTypeForOperaiton{
			first_token_type: left.get_token_type()
			second_token_type: right.get_token_type()
			operator: ">"
		})
	}
	'>=': fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left is i64 && right is i64 {
			return if left >= right { i64(1) } else { i64(0) }
		} else if left is i64 && right is f64 {
			return if left >= right { i64(1) } else { i64(0) }
		} else if left is f64 && right is i64 {
			return if left >= right { i64(1) } else { i64(0) }
		} else if left is f64 && right is f64 {
			return if left >= right { i64(1) } else { i64(0) }
		}
		return error_gen('eval', 'op', errors_df.ErrorCantUseTokenOfTypeForOperaiton{
			first_token_type: left.get_token_type()
			second_token_type: right.get_token_type()
			operator: ">="
		})
	}
	'<=': fn (left EvalOutput, right EvalOutput) !EvalOutput {
		if left is i64 && right is i64 {
			return if left <= right { i64(1) } else { i64(0) }
		} else if left is i64 && right is f64 {
			return if left <= right { i64(1) } else { i64(0) }
		} else if left is f64 && right is i64 {
			return if left <= right { i64(1) } else { i64(0) }
		} else if left is f64 && right is f64 {
			return if left <= right { i64(1) } else { i64(0) }
		}
		return error_gen('eval', 'op', errors_df.ErrorCantUseTokenOfTypeForOperaiton{
			first_token_type: left.get_token_type()
			second_token_type: right.get_token_type()
			operator: "<="
		})
	}
}
