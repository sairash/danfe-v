module ast

import errors_df
import rand

// ============================================
// Binary Expression - Handles arithmetic operations
// ============================================

fn (bi Binary) eval(process_id []&Process) !EvalOutput {
	left_eval := bi.left.eval(process_id)!
	right_eval := bi.right.eval(process_id)!

	// Handle numeric operations
	if (left_eval is f64 && right_eval is f64) || (left_eval is i64 && right_eval is i64) {
		if bi.operator in num_ops {
			return num_ops[bi.operator](left_eval, right_eval)
		}
		return error_gen('eval', 'binary', errors_df.ErrorBinaryOperationUnsupported{
			type_of_value: 'num'
			supported:     num_ops.keys()
			found:         bi.operator
		})
	}
	
	// Handle string operations
	if left_eval is string {
		match right_eval {
			string {
				if bi.operator != '+' {
					return error_gen('eval', 'binary', errors_df.ErrorBinaryOperationUnsupported{
						type_of_value: 'str'
						supported:     ['+']
						found:         bi.operator
					})
				}
				return '${left_eval}${right_eval}'
			}
			i64 {
				if bi.operator != '*' {
					return error_gen('eval', 'binary', errors_df.ErrorBinaryOperationUnsupported{
						type_of_value: 'str'
						supported:     ['*']
						found:         bi.operator
					})
				}
				return errors_df.gen_letter(left_eval, int(right_eval))
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

// ============================================
// Logical Expression - Handles comparison and logical operations
// ============================================

fn (lo Logical) eval(process_id []&Process) !EvalOutput {
	left_eval := lo.left.eval(process_id)!
	right_eval := lo.right.eval(process_id)!

	if lo.operator in num_ops {
		return num_ops[lo.operator](left_eval, right_eval)
	}

	return error_gen('eval', 'logical', errors_df.ErrorUnexpectedToken{
		token: lo.operator
	})
}

// ============================================
// Unary Expression - Handles unary operators (-, !)
// ============================================

fn (unary_ &UnaryExpression) eval(process_id []&Process) !EvalOutput {
	match unary_.operator {
		'-' {
			arg_eval := unary_.argument.eval(process_id)!
			match arg_eval {
				i64 { return arg_eval * -1 }
				f64 { return arg_eval * -1 }
				else {
					return error_gen('eval', 'unary', errors_df.ErrorNeededAfterInit{
						init_token:     '-'
						expected_token: arg_eval.get_token_type()
					})
				}
			}
		}
		'!' {
			return if !is_condition_met(process_id, unary_.argument)! { i64(1) } else { i64(0) }
		}
		else {
			return error_gen('eval', 'unary', errors_df.ErrorUnexpectedToken{
				token: unary_.operator
			})
		}
	}
	return i64(0)
}

// ============================================
// Index Expression - Handles array/table indexing
// ============================================

fn (ie IndexExpression) eval(process_id []&Process) !EvalOutput {
	mut output_val := EvalOutput(i64(0))
	mut name_of_var := ie.base.token.value
	
	if ie.base.token.reserved == 'self' {
		output_val = ie.resolve_self(process_id) or {
			return error_gen('eval', 'self_lookup', errors_df.ErrorTryingToUseReservedIdentifier{
				identifier: ie.base.token.value
			})
		}
	} else {
		output_val = ie.base.eval(process_id)!
	}
	
	// Apply all indexes
	for index in ie.indexes {
		output_val, name_of_var = output_val.get_indexed_value(
			index.eval(process_id)!,
			name_of_var
		)!
	}
	
	return output_val
}

// resolve_self finds the current 'self' reference in the call stack
fn (ie IndexExpression) resolve_self(process_id []&Process) ?EvalOutput {
	for proc in process_id.reverse() {
		if (proc.value == '' || proc.is_module) && proc.value !in program_state_map {
			continue
		}
		
		if proc.value in program_state_map {
			process_value := program_state_map[proc.value]
			if process_value.hint == .@none {
				if process_value.value is string {
					str_val := process_value.value as string
					if str_val in identifier_value_map {
						return identifier_value_map[str_val] or { continue }
					}
				}
			}
		}
	}
	return none
}

// ============================================
// Table/Array Indexing Methods
// ============================================

// get_indexed_value retrieves a value from a Table or string by index
pub fn (evl EvalOutput) get_indexed_value(value EvalOutput, name_of_var string) !(EvalOutput, string) {
	match evl {
		Table {
			if evl.is_arr {
				// Array access - must use integer index
				match value {
					i64 {
						if value >= 0 && value < evl.len {
							key := '${value}'
							if key in evl.table {
								return evl.table[key] or { return i64(0), key }, key
							}
						}
						return error_gen('eval', 'array_index', errors_df.ErrorArrayOutOfRange{
							total_len:     evl.len
							trying_to_get: '${value}'
							name_of_var:   name_of_var
						})
					}
					else {
						return error_gen('eval', 'array_index', errors_df.ErrorArrayOutOfRange{
							total_len:     evl.len
							trying_to_get: value.get_as_string()
							name_of_var:   name_of_var
						})
					}
				}
			}
			// Table access - use string key
			key := value.get_as_string()
			return evl.table[key] or { i64(0) }, key
		}
		string {
			// String character access
			match value {
				i64 {
					if value >= 0 && value < evl.len {
						return evl[value].ascii_str(), '${value}'
					}
				}
				else {}
			}
			return error_gen('eval', 'string_index', errors_df.ErrorArrayOutOfRange{
				total_len:     evl.len
				trying_to_get: value.get_as_string()
				name_of_var:   name_of_var
			})
		}
		else {}
	}
	
	return error_gen('eval', 'index', errors_df.ErrorCannotUseIndexKeyOn{
		name_of_var: name_of_var
	})
}

// update_indexed_value updates a value in a Table by index
pub fn (mut evl EvalOutput) update_indexed_value(indexes []Node, node Node, name_of_var string, process_id []&Process, insert_op string) !EvalOutput {
	// Evaluate the new value
	mut value := EvalOutput(i64(1))
	match node {
		FunctionStore {
			value = EvalOutput(node)
		}
		else {
			value = node.eval(process_id)!
		}
	}

	// Navigate to the target location
	mut evaluation := evl
	mut name := name_of_var

	for i := 0; i < indexes.len - 1; i++ {
		evaluation, name = evaluation.get_indexed_value(
			indexes[i].eval(process_id)!,
			name_of_var
		)!
	}

	last_index := indexes[indexes.len - 1].eval(process_id)!
	
	// Handle push/pop operators
	if (insert_op == '<<' || insert_op == '>>') && evaluation is Table {
		mut tbl := evaluation as Table
		if tbl.is_arr && last_index != EvalOutput(i64(-1)) {
			evaluation, name = evaluation.get_indexed_value(last_index, name_of_var)!
		} else if !tbl.is_arr && last_index.get_as_string() in tbl.table {
			evaluation, name = evaluation.get_indexed_value(last_index, name_of_var)!
		}
	}

	// Perform the update
	match mut evaluation {
		Table {
			return evaluation.update_value(last_index, value, name, insert_op)
		}
		else {}
	}

	return error_gen('eval', 'update_index', errors_df.ErrorCannotUseIndexKeyOn{
		name_of_var: name
	})
}

// update_value updates a Table with a new value
fn (mut t Table) update_value(index EvalOutput, value EvalOutput, name string, op string) !EvalOutput {
	if t.is_arr {
		// Array operations
		if op == '<<' {
			// Push
			t.table['${t.len}'] = value
			t.len += 1
			return i64(1)
		} else if op == '>>' {
			// Pop
			if t.len <= 0 {
				return error_gen('eval', 'pop', errors_df.ErrorArrayOutOfRange{
					total_len:     t.len
					trying_to_get: '${value}'
					name_of_var:   name
				})
			}
			t.len -= 1
			key := '${t.len}'
			popped := t.table[key] or { i64(0) }
			t.table.delete(key)
			return popped
		}
		
		// Direct assignment
		match index {
			i64 {
				if index < t.len {
					t.table['${index}'] = value
					t.len = t.table.keys().len
					return i64(1)
				}
				return error_gen('eval', 'array_assign', errors_df.ErrorArrayOutOfRange{
					total_len:     t.len
					trying_to_get: '${value}'
					name_of_var:   name
				})
			}
			string {
				// Convert array to table
				t.table[index] = value
				t.len = t.table.keys().len
				t.is_arr = false
				return i64(1)
			}
			else {
				return error_gen('eval', 'array_assign', errors_df.ErrorArrayOutOfRange{
					total_len:     t.len
					trying_to_get: value.get_as_string()
					name_of_var:   name
				})
			}
		}
	}
	
	// Table operations
	if op == '<<' {
		t.table[rand.uuid_v4()] = value
		t.len += 1
		return i64(1)
	} else if op == '>>' {
		if t.len <= 0 {
			return error_gen('eval', 'pop', errors_df.ErrorArrayOutOfRange{
				total_len:     t.len
				trying_to_get: '${value}'
				name_of_var:   name
			})
		}
		keys := t.table.keys()
		last_key := keys[t.len - 1]
		t.len -= 1
		popped := Table{
			table:  {
				'0': last_key
				'1': t.table[last_key] or { i64(0) }
			}
			is_arr: true
			len:    2
		}
		t.table.delete(last_key)
		return popped
	}
	
	// Direct table assignment
	t.table[index.get_as_string()] = value
	t.len = t.table.keys().len
	return i64(1)
}
