module ast

import errors_df

// ============================================
// Assignment Statement
// ============================================

fn (stmt AssignmentStatement) eval(process_id []&Process) !EvalOutput {
	var_ := stmt.variable
	
	match var_ {
		Identifier {
			if var_.token.reserved != '' {
				return error_gen('eval', 'assignment', errors_df.ErrorTryingToUseReservedIdentifier{
					identifier: var_.token.value
				})
			}
			
			match stmt.hint {
				'=' {}
				'?=' {
					// Conditional assignment - only assign if current value is empty
					if !var_.eval(process_id)!.is_empty() {
						return i64(0)
					}
				}
				'<<', '>>' {
					// Push/Pop operations on tables/arrays
					mut eval_output := var_.eval(process_id)!
					token_type := eval_output.get_token_type()
					
					if token_type == 'table' || token_type == 'array' {
						return eval_output.update_indexed_value([
							Node(Literal{
								hint:  .integer
								value: '-1'
								from:  var_.from
							}),
						], stmt.init, var_.from.join('.'), process_id, stmt.hint)
					}
					return error_gen('eval', 'push_pop', errors_df.ErrorUnexpectedToken{
						token: stmt.hint
					})
				}
				else {
					return error_gen('eval', 'assignment', errors_df.ErrorUnexpectedToken{
						token: stmt.hint
					})
				}
			}

			var_.set_value(process_id, stmt.init, false, '', false)!
			return i64(1)
		}
		IndexExpression {
			match stmt.hint {
				'<<', '>>', '=' {}
				else {
					return error_gen('eval', 'index_assign', errors_df.ErrorUnexpectedToken{
						token: stmt.hint
					})
				}
			}

			if var_.base.token.reserved == 'self' {
				return stmt.eval_self_assignment(var_, process_id)
			}
			
			if var_.base.token.reserved != '' {
				return error_gen('eval', 'assignment', errors_df.ErrorTryingToUseReservedIdentifier{
					identifier: var_.base.token.value
				})
			}

			mut eval_output := var_.base.eval(process_id)!
			return eval_output.update_indexed_value(
				var_.indexes,
				stmt.init,
				var_.base.from.join('.'),
				process_id,
				stmt.hint
			)
		}
		else {}
	}

	return error_gen('eval', 'assignment', errors_df.ErrorCanAssignToIdentifiersArrayAndTablesOnly{})
}

// eval_self_assignment handles assignments to self[index]
fn (stmt AssignmentStatement) eval_self_assignment(var_ IndexExpression, process_id []&Process) !EvalOutput {
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
						mut eval_output := identifier_value_map[str_val] or { continue }
						return eval_output.update_indexed_value(
							var_.indexes,
							stmt.init,
							var_.base.from.join('.'),
							process_id,
							stmt.hint
						)
					}
				}
			}
		}
	}
	
	return error_gen('eval', 'assignment', errors_df.ErrorTryingToUseReservedIdentifier{
		identifier: var_.base.token.value
	})
}

// ============================================
// If Statement & Condition Clause
// ============================================

fn (cond &ConditionClause) eval(process_id []&Process) !EvalOutput {
	// Check that non-else clauses have a condition
	if cond.hint != Conditions.else_clause && cond.condition == none {
		return error_gen('eval', 'condition', errors_df.ErrorNoConditionsProvided{
			token: '${cond.hint}'
		})
	}

	if is_condition_met(process_id, cond.condition)! {
		// Condition is true - evaluate body
		if cond.body.len == 1 {
			return Table{
				table:  {
					'0': 'value'
					'1': cond.body[0].eval(process_id)!
				}
				is_arr: false
			}
		}
		
		for val in cond.body {
			val.eval(process_id)!
		}

		return Table{
			table:  { '0': 'value', '1': i64(1) }
			is_arr: false
		}
	}

	// Condition not met - signal to continue
	return Table{
		table:  { '0': 'continue' }
		is_arr: false
	}
}

fn (if_stmt IfStatement) eval(process_id []&Process) !EvalOutput {
	for clause in if_stmt.clauses {
		ret_value := clause.eval(process_id)! as Table
		
		status := ret_value.table['0'] or { break } as string
		if status == 'value' {
			return ret_value.table['1'] or { break }
		}
	}
	return i64(0)
}

// ============================================
// Loop Statement (For)
// ============================================

fn (for_stmt ForStatement) eval(process_id []&Process) !EvalOutput {
	// Create new scope for loop
	new_process_id := gen_process_id(process_id[process_id.len - 1])
	mut all_processes := process_id.clone()
	all_processes << new_process_id

	identifier_assignment_tracker[new_process_id.value] = []string{}
	defer {
		delete_process_memory(new_process_id.value)
	}

	// Main loop
	for {
		if !is_condition_met(all_processes, for_stmt.condition)! {
			program_state_map.delete(new_process_id.value)
			break
		}
		
		// Execute loop body
		for stmt in for_stmt.body {
			if new_process_id.value !in program_state_map {
				stmt.eval(all_processes)!
			} else {
				state := program_state_map[new_process_id.value]
				if state.hint == .@none {
					stmt.eval(all_processes)!
				} else {
					break
				}
			}
		}

		// Check for control flow changes
		if new_process_id.value in program_state_map {
			match program_state_map[new_process_id.value].hint {
				.return_ {
					break
				}
				.continue_ {
					program_state_map.delete(new_process_id.value)
				}
				.break_ {
					program_state_map.delete(new_process_id.value)
					break
				}
				.@none {}
			}
		}
	}

	return i64(1)
}

// ============================================
// Control Flow Statements
// ============================================

fn (br BreakStatement) eval(process_id []&Process) !EvalOutput {
	if process_id.len > 0 {
		program_state_map[process_id[process_id.len - 1].value] = ProgramStateStore{
			hint:  ProgramState.break_
			value: i64(0)
		}
		return i64(1)
	}
	return i64(0)
}

fn (br ContinueStatement) eval(process_id []&Process) !EvalOutput {
	if process_id.len > 0 {
		program_state_map[process_id[process_id.len - 1].value] = ProgramStateStore{
			hint:  ProgramState.continue_
			value: i64(0)
		}
		return i64(1)
	}
	return i64(0)
}

fn (rt ReturnStatement) eval(process_id []&Process) !EvalOutput {
	if process_id.len > 0 {
		rt_value := rt.value.eval(process_id)!
		program_state_map[process_id[process_id.len - 1].value] = ProgramStateStore{
			hint:  ProgramState.return_
			value: rt_value
		}
		return rt_value
	}
	return i64(0)
}

// ============================================
// Delete Statement
// ============================================

fn (ds DelStatement) eval(process_id []&Process) !EvalOutput {
	processes := gen_map_key(ds.variable.from, process_id, ds.variable.token.sep_value)

	if processes.len > 0 {
		identifier_value_map.delete(processes[0])
		return i64(1)
	}
	return i64(0)
}

// ============================================
// Import Statement
// ============================================

fn (im ImportStatement) eval(process_id []&Process) !EvalOutput {
	return '${im.from_module_.join('.')}.${im.module_}'
}
