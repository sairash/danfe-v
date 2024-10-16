module parser

import lexer
import token
import ast
import errors_df

struct Process {
pub mut:
	lex       lexer.Lex
	cur_token token.Token
	nxt_token token.Token
	ast       ast.Chunk
}

pub struct Parse {
pub mut:
	file_process  map[string]&Process
	cur_file      string
	starting_file string
}

fn (mut p Process) next() ! {
	p.cur_token = p.nxt_token
	p.nxt_token = p.lex.next()!
	if p.check_token(token.Token{ token_type: token.EOF{} }) {
		errors_df.ErrorUnexpectedEOF{}
	}
}

fn (mut p Process) eat(expected token.Token) ! {
	if p.nxt_token.token_type != expected.token_type {
		return p.error_generator('advance', errors_df.ErrorMismatch{
			expected: expected.get_name()
			found:    p.nxt_token.get_name()
		})
	}
	p.next()!
}

fn (p &Process) check_token(expected token.Token) bool {
	return p.cur_token.token_type == expected.token_type
}

fn (p &Process) check_next_token(expected token.Token) bool {
	return p.nxt_token.token_type == expected.token_type
}

fn (p &Process) check_next_with_name_token(expected token.Token) bool {
	return p.nxt_token.get_name() == expected.get_name()
}

fn (mut p Process) parse_bin_expression() !ast.Expression {
	match p.cur_token.token_type {
		token.String {}
		else {}
	}
	return error('')
}

fn (mut p Process) parse_expression() !ast.Expression {
	match p.cur_token.token_type {
		token.String {
			if p.check_next_with_name_token(token.Token{
				token_type: token.Operator{}
			})
			{
				println('yes')
			}
		}
		else {}
	}
	return error('')
}

fn (p &Parse) get_process() !&Process {
	return p.file_process[p.cur_file] or {
		return p.error_generator('going through', errors_df.ErrorUnexpected{})
	}
}

pub fn (mut p Parse) walk() ! {
	for {
		mut proc := p.get_process()!

		proc.parse_expression()!
		proc.next() or { break }
	}
}

pub fn (mut p Parse) add_new_file_to_parse(path string, return_path string) ! {
	mut lex := lexer.Lex.new(path, '')!

	curr := lex.next()!
	next := lex.next()!

	p.file_process[path] = &Process{
		lex:       lex
		cur_token: curr
		nxt_token: next
		ast:       ast.Chunk{}
	}
}

pub fn (process &Process) error_generator(extra_info string, error_data errors_df.ErrorInterface) errors_df.DfError {
	return errors_df.DfError{
		while:    'parsing'
		when:     extra_info
		path:     process.lex.file_path
		cur_line: process.lex.cur_line
		cur_col:  int(process.cur_token.range[0])
		error:    error_data
	}
}

pub fn (p &Parse) error_generator(extra_info string, error_data errors_df.ErrorInterface) errors_df.DfError {
	process := p.file_process[p.cur_file] or {
		return errors_df.DfError{
			while:    'parsing"'
			when:     extra_info
			path:     p.cur_file
			cur_line: 0
			cur_col:  0
			error:    errors_df.ErrorUnexpected{}
		}
	}

	return process.error_generator(extra_info, error_data)
}

// Create New Parser
pub fn Parse.new(path string) !&Parse {
	mut parse_file := &Parse{
		file_process:  {}
		cur_file:      path
		starting_file: path
	}
	parse_file.add_new_file_to_parse(path, '')!
	return parse_file
}
