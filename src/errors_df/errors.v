module errors_df

import cli_df
import os

pub interface ErrorInterface {
	output() string
}

// Debug mode - set to true for detailed error information
pub const debug_enabled = true

pub struct DfError implements IError {
	Error
pub mut:
	path      string
	while     string  // e.g., "lexing", "parsing", "eval"
	when      string  // e.g., "match_number", "parse_expression"
	cur_line  int
	cur_col   int
	range     []int   // [start, end] column positions for error highlighting
	error     ErrorInterface
}

pub fn (err DfError) msg() string {
	return err.generate_pretty_error()
}

// Generate a pretty-printed error message with source code context
fn (err DfError) generate_pretty_error() string {
	mut result := '\n'
	
	// Header with error location
	result += '${cli_df.red}${cli_df.bold}error${cli_df.reset}'
	
	if debug_enabled && err.while != '' {
		result += ' ${cli_df.cyan}[${err.while}:${err.when}]${cli_df.reset}'
	}
	
	result += ': ${err.error.output()}\n'
	
	// File location
	if err.path != '' {
		result += '  ${cli_df.blue}-->${cli_df.reset} ${cli_df.underline}${err.path}:${err.cur_line}:${err.cur_col}${cli_df.reset}\n'
	}
	
	// Try to show source code context
	if err.path != '' && os.is_file(err.path) {
		source_context := err.get_source_context() or { '' }
		if source_context != '' {
			result += source_context
		}
	}
	
	return result
}

// Get source code lines around the error for context
fn (err DfError) get_source_context() !string {
	file_content := os.read_file(err.path)!
	lines := file_content.split('\n')
	
	if err.cur_line <= 0 || err.cur_line > lines.len {
		return ''
	}
	
	mut result := '   ${cli_df.blue}|${cli_df.reset}\n'
	
	// Calculate line number width for alignment
	max_line := err.cur_line + 1
	line_width := '${max_line}'.len
	
	// Show 2 lines before the error line (if available)
	start_line := if err.cur_line > 2 { err.cur_line - 2 } else { 1 }
	
	for i := start_line; i <= err.cur_line && i <= lines.len; i++ {
		line_num := '${i}'.len
		padding := gen_letter(' ', line_width - line_num)
		
		if i == err.cur_line {
			// Error line - highlighted
			result += '${cli_df.red}${cli_df.bold}${padding}${i}${cli_df.reset} ${cli_df.blue}|${cli_df.reset} ${lines[i - 1]}\n'
			
			// Add error pointer
			result += err.generate_error_pointer(line_width, lines[i - 1])
		} else {
			// Context line
			result += '${cli_df.cyan}${padding}${i}${cli_df.reset} ${cli_df.blue}|${cli_df.reset} ${lines[i - 1]}\n'
		}
	}
	
	result += '   ${cli_df.blue}|${cli_df.reset}\n'
	
	return result
}

// Generate the error pointer (^^^^) under the problematic code
fn (err DfError) generate_error_pointer(line_width int, source_line string) string {
	padding := gen_letter(' ', line_width)
	
	mut start_col := err.cur_col - 1
	mut end_col := start_col + 1
	
	// Use range if provided
	if err.range.len >= 2 {
		start_col = err.range[0]
		end_col = err.range[1]
	}
	
	// Ensure valid bounds
	if start_col < 0 {
		start_col = 0
	}
	if end_col < start_col {
		end_col = start_col + 1
	}
	if end_col > source_line.len {
		end_col = source_line.len
	}
	
	// Calculate pointer width
	pointer_len := end_col - start_col
	pointer := if pointer_len <= 1 {
		'^'
	} else {
		gen_letter('~', pointer_len)
	}
	
	// Build the pointer line
	pre_pointer := gen_letter(' ', start_col)
	return '${padding} ${cli_df.blue}|${cli_df.reset} ${pre_pointer}${cli_df.red}${cli_df.bold}${pointer}${cli_df.reset}\n'
}

// Legacy function for compatibility
pub fn gen_custom_error_message(while string, when string, path string, cur_line int, cur_col int, error_int ErrorInterface) string {
	err := DfError{
		while:    while
		when:     when
		path:     path
		cur_line: cur_line
		cur_col:  cur_col
		range:    [cur_col - 1, cur_col]
		error:    error_int
	}
	return err.generate_pretty_error()
}

// Generate repeated characters
pub fn gen_letter(letter string, times int) string {
	if times <= 0 {
		return ''
	}
	mut ret_string := ''
	for i := 0; i < times; i++ {
		ret_string += letter
	}
	return ret_string
}

// ============================================
// Error Types
// ============================================

pub struct ErrorFileIO {
pub mut:
	file_path string @[required]
}

fn (err ErrorFileIO) output() string {
	return 'failed to open file: ${cli_df.yellow}${err.file_path}${cli_df.reset}'
}

pub struct ErrorMismatch {
pub mut:
	expected string
	found    string
}

fn (err ErrorMismatch) output() string {
	return 'expected ${cli_df.green}${err.expected}${cli_df.reset}, found ${cli_df.red}${err.found}${cli_df.reset}'
}

pub struct ErrorImportPlacement {}

fn (err ErrorImportPlacement) output() string {
	return 'import statements must be at the start of the file'
}

pub struct ErrorDotCantBeEndOfIdent {
pub mut:
	token string
}

fn (err ErrorDotCantBeEndOfIdent) output() string {
	return '"." cannot be at the end of identifier: ${cli_df.yellow}${err.token}${cli_df.reset}'
}

pub struct ErrorImportTryingToCallSelf {}

fn (err ErrorImportTryingToCallSelf) output() string {
	return 'cannot import a file from itself'
}

pub struct ErrorImportCycleDetected {
pub mut:
	from_file     string
	detected_file string
}

fn (err ErrorImportCycleDetected) output() string {
	return 'import cycle detected: ${cli_df.yellow}${err.from_file}${cli_df.reset} -> ${cli_df.yellow}${err.detected_file}${cli_df.reset}'
}

pub struct ErrorAssert {
pub mut:
	function_name string
	output        string
	expected      string
}

fn (err ErrorAssert) output() string {
	mut msg := '\n${cli_df.red}❌ FAIL${cli_df.reset}: ${err.function_name}\n'
	msg += '   ${cli_df.cyan}got${cli_df.reset}:      ${err.output}'
	if err.expected != '' {
		msg += '\n   ${cli_df.cyan}expected${cli_df.reset}: ${err.expected}'
	}
	return msg
}

pub struct ErrorCustomError {
pub mut:
	statement string
}

fn (err ErrorCustomError) output() string {
	return err.statement
}

pub struct ErrorUnexpectedToken {
pub mut:
	token string
}

fn (err ErrorUnexpectedToken) output() string {
	return 'unexpected token: ${cli_df.yellow}${err.token}${cli_df.reset}'
}

pub struct ErrorTryingToCallNonFunctionIdentifier {}

fn (err ErrorTryingToCallNonFunctionIdentifier) output() string {
	return 'cannot call non-function identifier as a function'
}

pub struct ErrorCantUseTokenOfTypeForOperation {
pub mut:
	first_token_type  string
	second_token_type string
	operator          string
}

fn (err ErrorCantUseTokenOfTypeForOperation) output() string {
	return 'cannot use ${cli_df.yellow}${err.operator}${cli_df.reset} operator between ${cli_df.cyan}${err.first_token_type}${cli_df.reset} and ${cli_df.cyan}${err.second_token_type}${cli_df.reset}'
}

pub struct ErrorCantFindExpectedToken {
pub mut:
	token string
}

fn (err ErrorCantFindExpectedToken) output() string {
	return 'expected: ${cli_df.green}${err.token}${cli_df.reset}'
}

pub struct ErrorUseOfMultipleFloatPoints {}

fn (err ErrorUseOfMultipleFloatPoints) output() string {
	return 'multiple decimal points in number literal'
}

pub struct ErrorOnlyAllowed {
pub mut:
	value string
}

fn (err ErrorOnlyAllowed) output() string {
	return 'only ${err.value} is allowed here'
}

pub struct ErrorUnexpectedEOF {}

fn (err ErrorUnexpectedEOF) output() string {
	return 'unexpected end of file'
}

pub struct ErrorNeededAfterInit {
pub mut:
	init_token     string
	expected_token string
}

fn (err ErrorNeededAfterInit) output() string {
	return 'missing ${cli_df.green}${err.expected_token}${cli_df.reset} after ${cli_df.yellow}${err.init_token}${cli_df.reset}'
}

pub struct ErrorCannotUseIndexKeyOn {
pub mut:
	name_of_var string
}

fn (err ErrorCannotUseIndexKeyOn) output() string {
	return 'cannot use index on ${cli_df.yellow}${err.name_of_var}${cli_df.reset} (only table or array types support indexing)'
}

pub struct ErrorArrayOutOfRange {
pub mut:
	total_len     int
	trying_to_get string
	name_of_var   string
}

fn (err ErrorArrayOutOfRange) output() string {
	return 'index out of range: ${cli_df.yellow}${err.name_of_var}${cli_df.reset} has length ${cli_df.cyan}${err.total_len}${cli_df.reset}, tried to access index ${cli_df.red}${err.trying_to_get}${cli_df.reset}'
}

pub struct ErrorCanAssignToIdentifiersArrayAndTablesOnly {}

fn (err ErrorCanAssignToIdentifiersArrayAndTablesOnly) output() string {
	return 'can only assign to identifiers, arrays, and tables'
}

pub struct ErrorHaveToUseKeyInTable {}

fn (err ErrorHaveToUseKeyInTable) output() string {
	return 'must use key in table initialization'
}

pub struct ErrorI64ToIntConvert {}

fn (err ErrorI64ToIntConvert) output() string {
	return 'integer value out of range: must be between ${min_int} and ${max_int}'
}

pub struct ErrorCannotUseKeyInArray {}

fn (err ErrorCannotUseKeyInArray) output() string {
	return 'cannot use string key in array (use numeric index instead)'
}

pub struct ErrorTableKeyCannotBeOtherThanLiteral {}

fn (err ErrorTableKeyCannotBeOtherThanLiteral) output() string {
	return 'table key must be a string or number literal'
}

pub struct ErrorCannotUseTokenIfBefore {
pub mut:
	token  string
	having string
}

fn (err ErrorCannotUseTokenIfBefore) output() string {
	return 'cannot use ${cli_df.yellow}${err.having}${cli_df.reset} before ${cli_df.yellow}${err.token}${cli_df.reset}'
}

pub struct ErrorCanDeleteOnlyIdentifiers {
pub mut:
	del_key string
}

fn (err ErrorCanDeleteOnlyIdentifiers) output() string {
	return '${cli_df.yellow}${err.del_key}${cli_df.reset} can only delete identifiers'
}

pub struct ErrorUnexpected {}

fn (err ErrorUnexpected) output() string {
	return 'internal compiler error (please report this issue on GitHub)'
}

pub struct ErrorUnsupported {}

fn (err ErrorUnsupported) output() string {
	return 'unsupported operation'
}

pub struct ErrorEvalTypeMisMatch {
pub mut:
	left  string
	right string
	op    string
}

fn (err ErrorEvalTypeMisMatch) output() string {
	return 'type mismatch: cannot use ${cli_df.yellow}${err.op}${cli_df.reset} between ${cli_df.cyan}${err.left}${cli_df.reset} and ${cli_df.cyan}${err.right}${cli_df.reset}'
}

pub struct ErrorBinaryOperationUnsupported {
pub mut:
	type_of_value string
	found         string
	supported     []string
}

fn (err ErrorBinaryOperationUnsupported) output() string {
	return 'unsupported operator ${cli_df.red}${err.found}${cli_df.reset} for type ${cli_df.cyan}${err.type_of_value}${cli_df.reset} (supported: ${err.supported.join(", ")})'
}

pub struct ErrorUsingElseIfAfterElse {
pub mut:
	trying_to_use string
	before_using  string
}

fn (err ErrorUsingElseIfAfterElse) output() string {
	return 'cannot use ${cli_df.yellow}${err.trying_to_use}${cli_df.reset} after ${cli_df.yellow}${err.before_using}${cli_df.reset}'
}

pub struct ErrorNoConditionsProvided {
pub mut:
	token string
}

fn (err ErrorNoConditionsProvided) output() string {
	return 'missing condition for ${cli_df.yellow}${err.token}${cli_df.reset} statement'
}

pub struct ErrorDivisionByZero {}

fn (err ErrorDivisionByZero) output() string {
	return 'division by zero'
}

pub struct ErrorUnexpectedWhile {
pub mut:
	while_doing string
}

fn (err ErrorUnexpectedWhile) output() string {
	return 'internal error during ${err.while_doing} (please report this issue on GitHub)'
}

pub struct ErrorTryingToSetOnUndefined {
pub mut:
	token string
}

fn (err ErrorTryingToSetOnUndefined) output() string {
	return 'cannot set value on undefined variable ${cli_df.yellow}${err.token}${cli_df.reset}'
}

pub struct ErrorUndefinedToken {
pub mut:
	token string
}

fn (err ErrorUndefinedToken) output() string {
	return 'undefined: ${cli_df.yellow}${err.token}${cli_df.reset}'
}

pub struct ErrorUnexpectedTokenExpectedEitherOr {
pub mut:
	found    string
	either   string
	or_token string
}

fn (err ErrorUnexpectedTokenExpectedEitherOr) output() string {
	return 'expected ${cli_df.green}${err.either}${cli_df.reset} or ${cli_df.green}${err.or_token}${cli_df.reset}, found ${cli_df.red}${err.found}${cli_df.reset}'
}

pub struct ErrorTryingToUseReservedIdentifier {
pub mut:
	identifier string
}

fn (err ErrorTryingToUseReservedIdentifier) output() string {
	return '${cli_df.yellow}${err.identifier}${cli_df.reset} is a reserved keyword'
}

pub struct ErrorFunctionAlreadyDeclared {
pub mut:
	function_name string
}

fn (err ErrorFunctionAlreadyDeclared) output() string {
	return 'function ${cli_df.yellow}${err.function_name}${cli_df.reset} is already declared'
}

pub struct ErrorMissingParenthesis {
pub mut:
	missing_token string
}

fn (err ErrorMissingParenthesis) output() string {
	return 'missing ${cli_df.green}${err.missing_token}${cli_df.reset}'
}

pub struct ErrorArgumentsMisMatch {
pub mut:
	func_name       string
	expected_amount string
	found_amount    string
}

fn (err ErrorArgumentsMisMatch) output() string {
	expected_word := if err.expected_amount == '1' { 'argument' } else { 'arguments' }
	found_word := if err.found_amount == '1' { 'argument' } else { 'arguments' }
	return 'function ${cli_df.yellow}${err.func_name}${cli_df.reset} expects ${cli_df.green}${err.expected_amount}${cli_df.reset} ${expected_word}, got ${cli_df.red}${err.found_amount}${cli_df.reset} ${found_word}'
}

// [Not an actual Error] Used to signal end of parsing
pub struct ErrorExpectedEOF {}

fn (err ErrorExpectedEOF) output() string {
	return 'end of file'
}
