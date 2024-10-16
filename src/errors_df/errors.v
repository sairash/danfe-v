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
	return gen_error_start_keyword(err.while, err.when, err.path, err.cur_line, err.cur_col) +
		err.error.output()
}

// have to use this because I am too dumb to make (22r) work
fn gen_letter(letter string, times int) string {
	mut ret_string := ''
	for i := 0; i <= times; i++ {
		ret_string += letter
	}
	return ret_string
}

fn gen_error_start_keyword(while string, when string, path string, cur_line int, cur_col int) string {
	while_when := '${while} -> ${when}'
	return '\n${cli_df.double_underline}          ${cli_df.reset}\n${cli_df.red}Error${cli_df.reset} Encountered when ${cli_df.bold}${while_when}${cli_df.reset}: \n${gen_letter(' ',
		while_when.len + 23)}${cli_df.underline}${path}:${cur_line}:${cur_col}${cli_df.reset}: '
}

pub struct ErrorFileIO {}

fn (err ErrorFileIO) output() string {
	return 'Failed to open path.'
}

pub struct ErrorMismatch {
pub mut:
	expected string
	found    string
}

fn (err ErrorMismatch) output() string {
	return 'Was expecting ${cli_df.green}${err.expected}${cli_df.reset}, but found ${cli_df.red}${err.found}${cli_df.reset}.'
}

pub struct ErrorUnexpectedToken {
pub mut:
	token string
}

fn (err ErrorUnexpectedToken) output() string {
	return 'There was an unexpected token: ${err.token}'
}

pub struct ErrorUseOfMultipleFloatPoints {}

fn (err ErrorUseOfMultipleFloatPoints) output() string {
	return 'Attempting the use of multiple floating points "." in number.'
}

pub struct ErrorUnexpectedEOF {}

fn (err ErrorUnexpectedEOF) output() string {
	return 'Unexpected End of File'
}

pub struct ErrorUnexpected {}

fn (err ErrorUnexpected) output() string {
	return 'Unexpected Error In the compiler. Raise an Issue in Github'
}

// [Not an acutal Error] This Error is kept just to make it easier to end Parising
pub struct ErrorExpectedEOF {}

fn (err ErrorExpectedEOF) output() string {
	return 'End of File'
}
