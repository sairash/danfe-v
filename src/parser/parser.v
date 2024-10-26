module parser

import lexer
import token
import ast
import grammer
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
	if p.cur_token.token_type != expected.token_type {
		return p.error_generator('advance', errors_df.ErrorMismatch{
			expected: expected.get_name()
			found:    p.cur_token.get_name()
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

fn (mut p Process) parse_factor() !ast.Node {
	match p.cur_token.token_type {
		token.String {
			x := p.cur_token.token_type as token.String

			p.eat(token.Token{
				token_type: token.String{
					value: x.value
				}
			})!

			return ast.Litreal{
				hint:  ast.LitrealType.str
				value: x.value
			}
		}
		token.Numeric {
			x := p.cur_token.token_type as token.Numeric
			mut lit_type := ast.LitrealType.integer
			if x.hint == token.NumericType.f64 {
				lit_type = ast.LitrealType.floating_point
			}
			p.eat(token.Token{
				token_type: token.Numeric{
					value: x.value
					hint:  x.hint
				}
			})!
			return ast.Litreal{
				hint:  lit_type
				value: x.value
			}
		}
		token.Punctuation {
			x := p.cur_token.token_type as token.Punctuation
			if x.open && x.value == "(" {

				p.eat(token.Token{
					token_type: token.Punctuation{
						open: true
						value: '('
					}
				})!


				node := p.parse_bin_expression(0)!

				p.eat(token.Token{token_type: token.Punctuation{open: false, value: ')'}})!
				

				return node
			}
			return error(errors_df.gen_custom_error_message("parsing", "punctuation", p.lex.file_path, p.lex.cur_line, p.lex.cur_col, errors_df.ErrorMismatch{
				found: x.value,
				expected: ")"
			}))
		}
		else {}
	}
	return error(errors_df.gen_custom_error_message("parsing", "punctuation", p.lex.file_path, p.lex.cur_line, p.lex.cur_col, errors_df.ErrorUnexpected{}))
}

fn (mut p Process) parse_bin_expression(precedence int) !ast.Node {
	mut left := p.parse_factor()!

	for {
		match p.cur_token.token_type {
			token.Operator {
				x := p.cur_token.token_type as token.Operator
				prec := grammer.precedence[x.value] or { break }

				if prec < precedence {
					break
				}

				p.eat(token.Token{
					token_type: token.Operator{
						value: x.value
					}
				})!

				right := p.parse_bin_expression(prec)!

				left = ast.Binary{
					operator: x.value
					left:     left
					right:    right
				}
			}
			else {
				break
			}
		}
	}
	return left
}

fn (mut p Process) parse_expression() !ast.Node {
	match p.cur_token.token_type {
		token.String, token.Numeric{
			if p.check_next_with_name_token(token.Token{
				token_type: token.Operator{}
			})
			{
				return p.parse_bin_expression(0)
			}
		}
		token.Punctuation {
			if p.check_next_with_name_token(token.Token{token_type: token.Numeric{}}) || p.check_next_with_name_token(token.Token{token_type: token.String{}}) {
				return p.parse_bin_expression(0)
			}
		}
		else {}
	}
	return error('hh')
}

fn (p &Parse) get_process() !&Process {
	return p.file_process[p.cur_file] or {
		return p.error_generator('going through', errors_df.ErrorUnexpected{})
	}
}

pub fn (mut p Parse) walk() ! {
	for {
		mut proc := p.get_process()!

		// temprorary
		match proc.cur_token.token_type {
			token.String, token.Numeric, token.Punctuation {
				// if p.check_next_with_name_token(token.Token{
				// 	token_type: token.Operator{}
				// })
				// {
				proc.ast.body << proc.parse_expression()!
				// }
			}
			token.EOF {
				break
			}
			else {}
		}
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
		while:    '"parsing"'
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
			while:    '"parsing"'
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
