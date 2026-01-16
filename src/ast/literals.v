module ast

import strconv
import errors_df

// ============================================
// Literal - Represents literal values (numbers, strings, booleans, nil)
// ============================================

fn (li Literal) eval(process_id []&Process) !EvalOutput {
	return match li.hint {
		.integer {
			EvalOutput(li.value.i64())
		}
		.floating_point {
			EvalOutput(strconv.atof64(li.value)!)
		}
		.str {
			EvalOutput(replace_identifier_in_string(li.value, li.from, process_id)!)
		}
		.boolean {
			if li.value == 'true' { EvalOutput(i64(1)) } else { EvalOutput(i64(0)) }
		}
		.null {
			EvalOutput(i64(0))
		}
	}
}

// ============================================
// Identifier - Represents variable references
// ============================================

fn (i Identifier) eval(process_id []&Process) !EvalOutput {
	processes := gen_map_key(i.from, process_id, i.token.sep_value)
	
	for process in processes {
		if process in identifier_value_map {
			return identifier_value_map[process] or { continue }
		}
	}
	
	return error_gen('eval', 'identifier', errors_df.ErrorUndefinedToken{
		token: i.token.value
	})
}

fn (i Identifier) assign(process_id []&Process, process string, value EvalOutput) {
	// Track assignment for cleanup when scope ends
	if process_id.len > 0 {
		last_process := process_id[process_id.len - 1]
		if last_process.value != '' && !last_process.is_module {
			identifier_assignment_tracker[last_process.value] << process
		}
	}
	identifier_value_map[process] = value
}

fn (i Identifier) set_value(process_id []&Process, node Node, force bool, eval_output EvalOutput, use_eval bool) ! {
	processes := gen_map_key(i.from, process_id, i.token.sep_value)

	// Check if identifier exists (unless force is true)
	if !force {
		mut found := false
		for cur_process in processes {
			if cur_process in identifier_value_map || '${cur_process}.__module__' in identifier_value_map {
				found = true
				break
			}
		}
		
		if !found {
			return error_gen('eval', 'identifier', errors_df.ErrorTryingToSetOnUndefined{
				token: i.token.value
			})
		}
	}

	// Evaluate the value
	mut value := eval_output
	if !use_eval {
		match node {
			FunctionStore {
				value = EvalOutput(node)
			}
			else {
				value = node.eval(process_id)!
			}
		}
	}

	// Set the value in the first matching scope
	for process in processes.reverse() {
		if process in identifier_value_map {
			identifier_value_map[process] = value
			return
		}
		
		if force {
			i.assign(process_id, process, value)
			return
		}
	}

	// Default: assign to the last process
	if processes.len > 0 {
		i.assign(process_id, processes[processes.len - 1], value)
	}
}

// ============================================
// String Interpolation Helper
// ============================================

// replace_identifier_in_string handles string interpolation (%i{identifier})
fn replace_identifier_in_string(string_value string, from []string, process_id []&Process) !string {
	mut result := ''
	mut start_idx := 0
	mut cur_idx := 0
	
	for {
		// Find next interpolation marker
		cur_idx = string_value.index_after('%i{', cur_idx) or { break }
		
		// Find closing brace
		end_idx := string_value.index_after('}', cur_idx) or {
			return error_gen('eval', 'string_interpolation', errors_df.ErrorNeededAfterInit{
				init_token:     '%i{'
				expected_token: '}'
			})
		}
		
		// Extract and validate identifier
		ident_str := remove_space(string_value[cur_idx + 3..end_idx])
		ident := match_identifier_with_reserved(ident_str, from)
		
		if ident.token.reserved != '' {
			return error_gen('eval', 'string_interpolation', errors_df.ErrorOnlyAllowed{
				value: 'identifiers (cannot use reserved keyword "${ident.token.value}")'
			})
		}
		
		// Append prefix and evaluated identifier
		result += string_value[start_idx..cur_idx]
		result += ident.eval(process_id)!.get_as_string()
		
		cur_idx = end_idx + 1
		start_idx = cur_idx
	}
	
	// Append remaining string
	result += string_value[start_idx..]
	return result
}
