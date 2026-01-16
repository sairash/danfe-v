module ast

import errors_df

// ============================================
// TableKey - Represents a key-value pair in a table literal
// ============================================

fn (tk TableKey) eval(process_id []&Process) !EvalOutput {
	return tk.value.eval(process_id)!
}

// ============================================
// TableConstructorExpression - Creates a new table/array
// ============================================

fn (te TableConstructorExpression) eval(process_id []&Process) !EvalOutput {
	mut is_arr := true
	mut set_type := false
	mut table := Table{
		table:  {}
		is_arr: true
		len:    0
	}
	mut index := 0
	
	for field in te.fields {
		match field {
			TableKey {
				// Explicit key provided - this is a table
				if !is_arr || !set_type {
					set_type = true
					is_arr = false
					table.is_arr = false
					table.table[field.key.value] = field.value.eval(process_id)!
					index++
				} else {
					// Mixing array and table syntax
					return error_gen('eval', 'table_constructor', errors_df.ErrorHaveToUseKeyInTable{})
				}
			}
			else {
				// No key - this is an array element
				if is_arr || !set_type {
					set_type = true
					is_arr = true
					table.is_arr = true
					table.table['${index}'] = field.eval(process_id)!
					index++
				} else {
					// Mixing array and table syntax
					return error_gen('eval', 'table_constructor', errors_df.ErrorHaveToUseKeyInTable{})
				}
			}
		}
	}

	table.len = index
	return table
}
