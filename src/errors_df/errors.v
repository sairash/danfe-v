module errors_df

import cli_df

pub interface ErrorInterface {
	output() string
}

pub struct DfError implements IError {
	Error
pub mut:
	path     string
	while    string
	when     string
	cur_line int
	cur_col  int
	error    ErrorInterface
}

pub fn (err DfError) msg() string {
	return gen_custom_error_message(err.while, err.when, err.path, err.cur_line, err.cur_col,
		err.error)
}

pub fn gen_custom_error_message(while string, when string, path string, cur_line int, cur_col int, error_int ErrorInterface) string {
	while_when := '${while} -> ${when}'
	return gen_error_start_keyword(while_when, path, cur_line, cur_col) + error_int.output() +
		'\n${cli_df.double_underline}${gen_letter(' ', while_when.len + 23)}${cli_df.reset}\n'
}

// have to use this because I am too dumb to make (22r) work
pub fn gen_letter(letter string, times int) string {
	mut ret_string := ''
	for i := 0; i < times; i++ {
		ret_string += letter
	}
	return ret_string
}

fn gen_error_start_keyword(while_when string, path string, cur_line int, cur_col int) string {
	return '\n\n${cli_df.double_underline}${gen_letter(' ', while_when.len + 23)}${cli_df.reset}\n${cli_df.red}Error${cli_df.reset} Encountered when ${cli_df.bold}${while_when}${cli_df.reset}: \n${cli_df.underline}${path}:${cur_line}:${cur_col}${cli_df.reset}: '
}

pub struct ErrorFileIO {
pub mut:
	file_path string @[required]
}

fn (err ErrorFileIO) output() string {
	return 'Failed to open path. path: ${err.file_path}'
}

pub struct ErrorMismatch {
pub mut:
	expected string
	found    string
}

fn (err ErrorMismatch) output() string {
	return 'Was expecting ${cli_df.green}${err.expected}${cli_df.reset}, but found ${cli_df.red}${err.found}${cli_df.reset}.'
}

pub struct ErrorImportPlacement {}

fn (err ErrorImportPlacement) output() string {
	return 'The Placement of "import" should be at the start of the file before any other operation.'
}

pub struct ErrorDotCantBeEndOfIdent {
pub mut:
	token string
}

fn (err ErrorDotCantBeEndOfIdent) output() string {
	return '"." can\'t be the end of the identifier: ${err.token}'
}

pub struct ErrorImportTryingToCallSelf {}

fn (err ErrorImportTryingToCallSelf) output() string {
	return 'Trying to "import" self from self.'
}

pub struct ErrorImportCycleDetected {
pub mut:
	from_file     string
	detected_file string
}

fn (err ErrorImportCycleDetected) output() string {
	return 'Import Cycle Detected. From: ${err.from_file}, Detected: ${err.detected_file}'
}

pub struct ErrorUnexpectedToken {
pub mut:
	token string
}

fn (err ErrorUnexpectedToken) output() string {
	return 'There was an unexpected token: ${err.token}'
}

pub struct ErrorCantFindExpectedToken {
pub mut:
	token string
}

fn (err ErrorCantFindExpectedToken) output() string {
	return 'Was Expecting: ${err.token}'
}

pub struct ErrorUseOfMultipleFloatPoints {}

fn (err ErrorUseOfMultipleFloatPoints) output() string {
	return 'Attempting the use of multiple floating points "." in number.'
}

pub struct ErrorOnlyAllowed {
pub mut:
	value string
}

fn (err ErrorOnlyAllowed) output() string {
	return 'Only allowed ${err.value}'
}

pub struct ErrorUnexpectedEOF {}

fn (err ErrorUnexpectedEOF) output() string {
	return 'Unexpected End of File'
}

pub struct ErrorNeededAfterInit {
pub mut:
	init_token     string
	expected_token string
}

fn (err ErrorNeededAfterInit) output() string {
	return 'After initializing with "${err.init_token}" an ending token "${err.expected_token} is required."'
}

pub struct ErrorCannotUseIndexKeyOn {
	pub mut:
	name_of_var string
}

fn (err ErrorCannotUseIndexKeyOn) output() string {
	return 'Can only use Indexed Key (["key"]) in type "Table" or "Array". Cannot use on ${err.name_of_var}'
}

pub struct ErrorArrayOutOfRange {
	pub mut:
	total_len int
	trying_to_get string
	name_of_var string
}

fn (err ErrorArrayOutOfRange) output() string {
	return 'Array out of range: total length of array "${err.name_of_var}" is: ${err.total_len} : trying to get index ${err.trying_to_get}'
}




pub struct ErrorCanAssignToIdenifiersArrayAndTablesOnly {
}

fn (err ErrorCanAssignToIdenifiersArrayAndTablesOnly) output() string {
	return 'Can assign values to "Identifers", "Arrays" and "Tables" only.'
}

pub struct ErrorHaveToUseKeyInTable {
}

fn (err ErrorHaveToUseKeyInTable) output() string {
	return 'You have to use "Key" in "Array".'
}


pub struct ErrorCannotUseKeyInArray {
}

fn (err ErrorCannotUseKeyInArray) output() string {
	return 'You cannot use Key In Array.'
}

pub struct ErrorTableKeyCannotBeOtherThanLitreal {
}

fn (err ErrorTableKeyCannotBeOtherThanLitreal) output() string {
	return 'Key of Table ["key"=> "value"] can only be of type "number" or "string".'
}

pub struct ErrorCannotUseTokenIfBefore {
pub mut:
	token  string
	having string
}

fn (err ErrorCannotUseTokenIfBefore) output() string {
	return 'Use of "${err.having}" is not allowed before "${err.token}"'
}

pub struct ErrorUnexpected {}

fn (err ErrorUnexpected) output() string {
	return 'Unexpected Error In the compiler. Raise an Issue in Github'
}

pub struct ErrorUnsupported {}

fn (err ErrorUnsupported) output() string {
	return 'Unsupported Litreal Found'
}

pub struct ErrorEvalTypeMisMatch {
pub mut:
	left  string
	right string
	op    string
}

fn (err ErrorEvalTypeMisMatch) output() string {
	return 'Trying to run operation "${err.op}" on left: ${err.left} and right: ${err.right}'
}

pub struct ErrorBinaryOperationUnsupported {
pub mut:
	type_of_value string
	found         string
	supported     []string
}

fn (err ErrorBinaryOperationUnsupported) output() string {
	return 'Unsupported Bniary operation in literal "${err.type_of_value}", Found: ${err.found} Supported: ${err.supported}'
}

pub struct ErrorUsingElseIfAfterElse {
pub mut:
	trying_to_use string
	before_using  string
}

fn (err ErrorUsingElseIfAfterElse) output() string {
	return 'Cannot use "${err.trying_to_use}" after the use of "${err.before_using}"'
}

pub struct ErrorNoConditionsProvided {
pub mut:
	token string
}

fn (err ErrorNoConditionsProvided) output() string {
	return 'No Conditions provided for ${err.token}.'
}

pub struct ErrorDivisionByZero {}

fn (err ErrorDivisionByZero) output() string {
	return 'Division by Zero!'
}

pub struct ErrorUnexpectedWhile {
pub mut:
	while_doing string
}

fn (err ErrorUnexpectedWhile) output() string {
	return 'Unexpected Error In the compiler while ${err.while_doing}. Raise an Issue in Github'
}

pub struct ErrorUndefinedToken {
pub mut:
	token string
}

fn (err ErrorUndefinedToken) output() string {
	return 'undefined: ${err.token}'
}

pub struct ErrorUnexpectedTokenExpectedEitherOr {
pub mut:
	found    string
	either   string
	or_token string
}

fn (err ErrorUnexpectedTokenExpectedEitherOr) output() string {
	return 'Unexpected value: found ${err.found}, expecting either "${err.either}" or "${err.or_token}"'
}

pub struct ErrorTryingToUseReservedIdentifier {
pub mut:
	identifier string
}

fn (err ErrorTryingToUseReservedIdentifier) output() string {
	return 'The "${err.identifier}" identifier is reserved by Danfe and user programs cannot assign value to to it.'
}

pub struct ErrorFunctionAlreadyDeclared {
pub mut:
	function_name string
}

fn (err ErrorFunctionAlreadyDeclared) output() string {
	return 'You have already declared a function named "${err.function_name}"'
}

pub struct ErrorMissingParenthesis {
pub mut:
	missing_token string
}

fn (err ErrorMissingParenthesis) output() string {
	return 'Unexpected Error In the compiler while ${err.missing_token}. Raise an Issue in Github'
}

pub struct ErrorArgumentsMisMatch {
pub mut:
	func_name       string
	expected_amount string
	found_amount    string
}

fn (err ErrorArgumentsMisMatch) one_or_multiple(amount string) string {
	if amount == '1' {
		return '${amount} argument'
	}
	return '${amount} arguments'
}

fn (err ErrorArgumentsMisMatch) output() string {
	return 'Arguments mismatch for function "${err.func_name}" \nwant: ${err.one_or_multiple(err.expected_amount)} \nhave: ${err.one_or_multiple(err.found_amount)}'
}

// [Not an acutal Error] This Error is kept just to make it easier to end Parising
pub struct ErrorExpectedEOF {}

fn (err ErrorExpectedEOF) output() string {
	return 'End of File'
}
