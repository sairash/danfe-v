module ast

import errors_df

// ============================================
// FunctionStore - Stores function definition
// ============================================

fn (fs FunctionStore) eval(process_id []&Process) !EvalOutput {
	return i64(1)
}

fn (fs FunctionStore) execute(ce CallExpression, process_id []&Process) !EvalOutput {
	// Validate argument count
	if fs.parameters.len != ce.arguments.len {
		base_ident := ce.base as Identifier
		return error_gen('eval', 'call_exp', errors_df.ErrorMismatch{
			expected: '${fs.parameters.len} parameters for function ${base_ident.from}.${base_ident.token.value}(${fs.parameters.map(it.token.value).join(', ')})'
			found:    '${ce.arguments.len} parameters were passed'
		})
	}

	// Bind parameters to arguments
	for i := 0; i < fs.parameters.len; i++ {
		fs.parameters[i].set_value(process_id, ce.arguments[i], true, '', false)!
	}

	// Execute function body
	mut ret_val := EvalOutput(i64(1))
	for stmt in fs.body {
		ret_val = stmt.eval(process_id)!
		
		// Check for return statement
		for proc in process_id.reverse() {
			if proc.value in program_state_map {
				state := program_state_map[proc.value]
				match state.hint {
					.return_ {
						program_state_map.delete(proc.value)
						return state.value
					}
					.@none {}
					else { break }
				}
			}
		}
	}

	return ret_val
}

// ============================================
// FunctionDeclaration - Declares a new function
// ============================================

pub fn (fd FunctionDeclaration) eval(process_id []&Process) !EvalOutput {
	// Check for reserved keyword usage
	if fd.name.token.reserved != '' {
		return error_gen('eval', 'function_declaration', errors_df.ErrorTryingToUseReservedIdentifier{
			identifier: fd.name.token.value
		})
	}

	// Build process list with previous scope
	mut new_processes := process_id.clone()
	new_processes << fd.prev_scope

	// Generate map keys
	processes := gen_map_key(fd.name.from, new_processes, fd.name.token.sep_value)

	// Check for duplicate declaration
	target_key := processes[processes.len - 1]
	if target_key in identifier_value_map {
		return error_gen('eval', 'function_declaration', errors_df.ErrorFunctionAlreadyDeclared{
			function_name: fd.name.token.value
		})
	}

	// Store the function
	identifier_value_map[target_key] = FunctionStore{
		parameters:         fd.parameters
		body:               fd.body
		scope:              fd.scope
		declared_at_module: fd.name.from[..fd.name.from.len - 1].join('.')
	}

	return i64(1)
}

// ============================================
// FunctionDeclared - Placeholder for declared functions
// ============================================

fn (fdd FunctionDeclared) eval(process_id []&Process) !EvalOutput {
	return i64(1)
}

// ============================================
// CallExpression - Function call
// ============================================

fn (ce CallExpression) eval(process_id []&Process) !EvalOutput {
	// Create new scope for function execution
	new_process_id := gen_process_id(empty_process)
	mut all_processes := process_id.clone()
	all_processes << new_process_id

	identifier_assignment_tracker[new_process_id.value] = []string{}
	defer {
		delete_process_memory(new_process_id.value)
	}

	base := ce.base

	match base {
		IndexExpression {
			return ce.eval_index_call(base, all_processes, new_process_id)
		}
		Identifier {
			return ce.eval_identifier_call(base, all_processes)
		}
		else {
			return error_gen('eval', 'call_exp', errors_df.ErrorTryingToCallNonFunctionIdentifier{})
		}
	}
}

// eval_index_call handles calls like obj.method() or obj["method"]()
fn (ce CallExpression) eval_index_call(base IndexExpression, all_processes []&Process, new_process_id &Process) !EvalOutput {
	func_value := base.eval(all_processes[..all_processes.len - 1])!
	
	match func_value {
		FunctionStore {
			// Find the object reference for 'self'
			processes := gen_map_key(base.base.from, all_processes, base.base.token.sep_value)
			mut in_process := ''
			for proc in processes {
				if proc in identifier_value_map {
					in_process = proc
					break
				}
			}

			// Store self reference
			program_state_map[new_process_id.value] = ProgramStateStore{
				hint:  .@none
				value: in_process
			}

			return func_value.execute(ce, all_processes)
		}
		else {
			return error_gen('eval', 'call_exp', errors_df.ErrorTryingToCallNonFunctionIdentifier{})
		}
	}
}

// eval_identifier_call handles direct function calls like func()
fn (ce CallExpression) eval_identifier_call(base Identifier, all_processes []&Process) !EvalOutput {
	map_all_processes := gen_map_key(base.from, all_processes, base.token.sep_value)

	// Check for reserved/built-in functions
	if base.token.reserved != '' {
		if base.token.reserved in default_call_operations {
			return default_call_operations[base.token.reserved](all_processes, base, ce.arguments)
		}
		return error_gen('eval', 'call_exp', errors_df.ErrorUndefinedToken{
			token: base.token.value
		})
	}

	// Check for standard library functions
	if base.token.value in std_functions {
		std_func := std_functions[base.token.value]
		if ce.call_path == '${base_dir_path}${std_func.path}' {
			return std_func.func(all_processes, ce.arguments)
		}
	}

	// Look up user-defined function
	for proc in map_all_processes {
		if proc in identifier_value_map {
			func := identifier_value_map[proc] or { continue }
			match func {
				FunctionStore {
					mut processes_with_scope := all_processes.clone()
					processes_with_scope << func.scope
					return func.execute(ce, processes_with_scope)
				}
				else {
					return error_gen('eval', 'call_exp', errors_df.ErrorTryingToCallNonFunctionIdentifier{})
				}
			}
		}
	}

	return error_gen('eval', 'call_exp', errors_df.ErrorUndefinedToken{
		token: base.token.value
	})
}
