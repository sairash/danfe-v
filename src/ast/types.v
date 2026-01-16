module ast

import errors_df

// ============================================
// EvalOutput Methods
// ============================================

// get_token_type returns the string representation of the EvalOutput type
pub fn (evl EvalOutput) get_token_type() string {
	return match evl {
		string { 'string' }
		i64 { 'int' }
		f64 { 'float' }
		Table {
			if evl.is_arr { 'array' } else { 'table' }
		}
		FunctionStore { 'function' }
	}
}

// is_empty checks if the EvalOutput is empty/zero
pub fn (evl EvalOutput) is_empty() bool {
	return match evl {
		string { evl == '' }
		i64 { evl == 0 }
		f64 { evl == 0.0 }
		Table { evl.len == 0 }
		FunctionStore { false }
	}
}

// is_true checks if the EvalOutput evaluates to true
fn (evl EvalOutput) is_true() bool {
	return match evl {
		string { evl != '' }
		i64 { evl != 0 }
		f64 { evl != 0.0 }
		Table { evl.len != 0 }
		FunctionStore { false }
	}
}

// get_as_string converts EvalOutput to its string representation
pub fn (evl EvalOutput) get_as_string() string {
	return match evl {
		string { evl }
		i64, f64 { evl.str() }
		Table { evl.to_string() }
		FunctionStore { evl.to_string() }
	}
}

// ============================================
// Table Methods
// ============================================

// to_string converts a Table to its string representation
fn (t Table) to_string() string {
	if t.len == 0 {
		return '[]'
	}
	
	mut result := '['
	if t.is_arr {
		for _, val in t.table {
			result += '${val.get_as_string()}, '
		}
	} else {
		for key, val in t.table {
			result += '${key} => ${val.get_as_string()}, '
		}
	}
	return result[..result.len - 2] + ']'
}

// ============================================
// FunctionStore String Method
// ============================================

fn (fs FunctionStore) to_string() string {
	if fs.parameters.len == 0 {
		return 'function () {}'
	}
	
	mut result := 'function ( '
	for param in fs.parameters {
		result += '${param.token.value}, '
	}
	return result[..result.len - 2] + ') { ... }'
}

// ============================================
// Helper Functions
// ============================================

// is_condition_met evaluates if a condition is true
fn is_condition_met(process_id []&Process, condition ?Node) !bool {
	cond_node := condition or { return true }
	return cond_node.eval(process_id)!.is_true()
}

// error_gen creates a DfError for evaluation errors
fn error_gen(while string, extra_info string, error_data errors_df.ErrorInterface) errors_df.DfError {
	return errors_df.DfError{
		while:    'evaluation'
		when:     extra_info
		path:     ''
		cur_line: 0
		cur_col:  0
		range:    []
		error:    error_data
	}
}

// check_eval_name returns a short type name for error messages
fn check_eval_name(output EvalOutput) string {
	return match output {
		string { 'str' }
		else { 'num' }
	}
}
