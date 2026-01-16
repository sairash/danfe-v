module ast

import rand
import grammar
import token

// ============================================
// Runtime Management Functions
// ============================================

// add_args_to_table adds command line arguments to the module's __args__ table
pub fn add_args_to_table(full_module_ string, args []string) {
	args_key := '${full_module_}.__args__'
	if args_key in identifier_value_map {
		return
	}

	mut arg_table := Table{
		table:  {}
		is_arr: false
		len:    args.len
	}
	for k, v in args {
		arg_table.table[v] = i64(k)
	}
	identifier_value_map[args_key] = arg_table
}

// set_if_module_not_already_init initializes a module if not already done
pub fn set_if_module_not_already_init(full_module_ string, module_ string) bool {
	module_key := '${full_module_}.__module__'
	if module_key in identifier_value_map {
		return false
	}
	identifier_value_map[module_key] = module_
	return true
}

// delete_process_memory cleans up all variables assigned in a process/scope
fn delete_process_memory(process_id string) {
	if process_id in identifier_assignment_tracker {
		for var_name in identifier_assignment_tracker[process_id] {
			identifier_value_map.delete(var_name)
		}
		identifier_assignment_tracker.delete(process_id)
	}
}

// gen_process_id creates a new process ID or returns the existing one
pub fn gen_process_id(process_id &Process) &Process {
	if process_id.value != '' && !process_id.is_module {
		return unsafe { process_id }
	}
	return &Process{
		value:     rand.ascii(14)
		is_module: false
	}
}

// ============================================
// Identifier Key Generation (Optimized)
// ============================================

// gen_map_key generates all possible lookup keys for an identifier
// This is used for scope resolution - it generates keys from most specific to least specific
fn gen_map_key(from []string, process_id []&Process, sep_value []string) []string {
	sep_len := sep_value.len
	
	// Pre-calculate common strings
	mut value_joined := ''
	if sep_len > 1 {
		value_joined = '.' + sep_value[..sep_len - 1].join('.')
	}
	
	from_joined := from.join('.')
	last_value := sep_value[sep_len - 1]
	
	// Pre-allocate result array with estimated capacity
	mut ret_processes := []string{cap: process_id.len * 2}
	
	for process in process_id {
		base_key := if process.is_module {
			process.value
		} else {
			suffix := if process.value != '' { '.' + process.value } else { '' }
			'${from_joined}${suffix}${value_joined}'
		}
		
		ret_processes << base_key
		ret_processes << '${base_key}.${last_value}'
	}
	
	return ret_processes
}

// ============================================
// Utility Functions
// ============================================

// to_int_f64_or_str parses a string to the appropriate numeric type or returns as string
fn to_int_f64_or_str(value string) EvalOutput {
	mut has_decimal := false
	
	for ch in value {
		if ch == `.` {
			if has_decimal {
				return value  // Multiple decimals = string
			}
			has_decimal = true
		} else if !ch.is_digit() {
			return value  // Non-numeric character = string
		}
	}
	
	return if has_decimal { value.f64() } else { value.i64() }
}

// remove_space removes whitespace characters from a string
fn remove_space(s string) string {
	return s.replace(' ', '').replace('\n', '').replace('\t', '')
}

// ============================================
// Reserved Symbol Matching (Cached)
// ============================================

// match_identifier_with_reserved creates an Identifier and checks if it's reserved
fn match_identifier_with_reserved(identifier string, from []string) Identifier {
	mut reserved := ''
	
	// Check main reserved symbols
	for key, aliases in grammar.reserved_symbols {
		if identifier == key || identifier in aliases {
			reserved = key
			break
		}
	}
	
	return Identifier{
		token: token.Identifier{
			value:     identifier
			sep_value: identifier.split('.')
			reserved:  reserved
		}
		from: from
	}
}
