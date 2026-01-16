module parser

import lexer
import token
import ast
import errors_df

// ============================================
// Parse Struct - Core Parser State
// ============================================

pub struct Parse {
pub mut:
	lex        lexer.Lex
	prev_token token.Token
	cur_token  token.Token
	nxt_token  token.Token
	ast        ast.Chunk
	module_    []string @[required]
	cur_file   string
	scope      &ast.Process @[required]
}

// ============================================
// Token Navigation Methods
// ============================================

fn (mut p Parse) next() !bool {
	p.prev_token = p.cur_token
	p.cur_token = p.nxt_token
	p.nxt_token = p.lex.next()!

	return p.check_token(token.Token{ token_type: token.EOF{} })
}

fn (mut p Parse) eat(expected token.Token) ! {
	if p.cur_token.token_type != expected.token_type {
		return p.error_generator('advance', errors_df.ErrorMismatch{
			expected: expected.get_value()
			found:    p.cur_token.get_value()
		})
	}
	p.next()!
}

fn (mut p Parse) eat_with_name_token(expected token.Token) ! {
	if p.cur_token.get_name() != expected.get_name() {
		return p.error_generator('advance', errors_df.ErrorMismatch{
			expected: expected.get_value()
			found:    p.cur_token.get_value()
		})
	}
	p.next()!
}

// ============================================
// Token Check Methods
// ============================================

fn (p &Parse) check_prev_token(expected token.Token) bool {
	return p.prev_token.token_type == expected.token_type
}

fn (p &Parse) check_token(expected token.Token) bool {
	return p.cur_token.token_type == expected.token_type
}

fn (p &Parse) check_next_token(expected token.Token) bool {
	return p.nxt_token.token_type == expected.token_type
}

fn (p &Parse) check_next_identifier_reserved(expected string) bool {
	if p.nxt_token.token_type is token.Identifier {
		return (p.nxt_token.token_type as token.Identifier).reserved == expected
	}
	return false
}

fn (p &Parse) check_current_identifier_reserved(expected string) bool {
	if p.cur_token.token_type is token.Identifier {
		return (p.cur_token.token_type as token.Identifier).reserved == expected
	}
	return false
}

fn (p &Parse) check_token_with_name(expected token.Token) bool {
	return p.cur_token.get_name() == expected.get_name()
}

fn (p &Parse) check_next_with_name_token(expected token.Token) bool {
	return p.nxt_token.get_name() == expected.get_name()
}

// ============================================
// Error Generation
// ============================================

pub fn (p &Parse) error_generator(extra_info string, error_data errors_df.ErrorInterface) errors_df.DfError {
	start_col := if p.cur_token.range.len > 0 { int(p.cur_token.range[0]) } else { p.lex.cur_col }
	end_col := if p.cur_token.range.len > 1 { int(p.cur_token.range[1]) } else { start_col + 1 }
	return errors_df.DfError{
		while:    'parsing'
		when:     extra_info
		path:     p.lex.file_path
		cur_line: p.lex.cur_line
		cur_col:  start_col
		range:    [start_col, end_col]
		error:    error_data
	}
}

// ============================================
// Main Walk Methods
// ============================================

pub fn (mut proc Parse) walk() ![]ast.Node {
	mut return_node := []ast.Node{}

	for {
		match proc.cur_token.token_type {
			token.String, token.Numeric {
				return_node << proc.parse_expression()!
			}
			token.Punctuation {
				if proc.check_token(token.Token{
					token_type: token.Punctuation{ open: false, value: '}' }
				}) {
					break
				}
				return_node << proc.parse_expression()!
			}
			token.Identifier {
				return_node << proc.parse_identifier()!
			}
			token.EOF {
				break
			}
			else {
				if proc.next()! {
					break
				}
			}
		}
	}

	return return_node
}

pub fn (mut p Parse) walk_main() ! {
	p.ast.body << p.walk()!
}

// ============================================
// Constructor Methods
// ============================================

pub fn Parse.new(path string, module_name []string) !&Parse {
	mut lex := lexer.Lex.new(path, '')!

	curr := lex.next()!
	next := lex.next()!

	return &Parse{
		lex:       lex
		cur_token: curr
		nxt_token: next
		ast:       ast.Chunk{}
		module_:   module_name
		cur_file:  path
		scope:     ast.get_empty_process()
	}
}

pub fn Parse.new_temp(go_through_file_data string) !&Parse {
	return &Parse{
		lex:      lexer.Lex{
			x:               0
			file_data:       go_through_file_data
			file_path:       '/tmp/sai'
			return_path:     ''
			can_import:      true
			file_len:        go_through_file_data.len
			cur_col:         1
			cur_line:        1
			bracket_balance: []
		}
		module_:  ['']
		cur_file: '/tmp/sai'
		scope:    ast.get_empty_process()
	}
}

pub fn (mut p Parse) append_to_lex(input_data string) ![]ast.Node {
	p.lex.file_data += input_data
	p.lex.file_len += input_data.len

	p.nxt_token = token.Token{ token_type: token.EOL{} }
	p.next()!

	p.walk_main()!

	return p.ast.body
}
