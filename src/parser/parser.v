module parser

import lexer
import token
import ast
import grammer
import errors_df

struct Parse {
pub mut:
	lex        lexer.Lex
	prev_token token.Token
	cur_token  token.Token
	nxt_token  token.Token
	ast        ast.Chunk
	module_    string @[required]
	cur_file   string
}

fn (mut p Parse) next() ! {
	p.prev_token = p.cur_token
	p.cur_token = p.nxt_token
	p.nxt_token = p.lex.next()!
	if p.check_token(token.Token{ token_type: token.EOF{} }) {
		errors_df.ErrorUnexpectedEOF{}
	}
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

fn (p &Parse) check_token(expected token.Token) bool {
	return p.cur_token.token_type == expected.token_type
}

fn (p &Parse) check_next_token(expected token.Token) bool {
	return p.nxt_token.token_type == expected.token_type
}

fn (p &Parse) check_next_identifier_reserved(expected string) bool {
	x := p.nxt_token.token_type
	match x {
		token.Identifier {
			return x.reserved == expected
		}
		else {
			return false
		}
	}
}

fn (p &Parse) check_current_identifier_reserved(expected string) bool {
	x := p.cur_token.token_type
	match x {
		token.Identifier {
			return x.reserved == expected
		}
		else {
			return false
		}
	}
}

fn (p &Parse) check_token_with_name(expected token.Token) bool {
	return p.cur_token.get_name() == expected.get_name()
}

fn (p &Parse) check_next_with_name_token(expected token.Token) bool {
	return p.nxt_token.get_name() == expected.get_name()
}

fn (mut p Parse) parse_factor() !ast.Node {
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
		token.Identifier {
			if p.check_next_token(token.Token{
				token_type: token.Punctuation{
					open:  true
					value: '('
				}
			})
			{
				return p.parse_call_expression()
			}

			x := p.cur_token.token_type as token.Identifier

			p.eat(token.Token{
				token_type: token.Identifier{
					value:    x.value
					reserved: x.reserved
				}
			})!

			match x.reserved {
				'true', 'false' {
					return ast.Litreal{
						hint:  ast.LitrealType.boolean
						value: x.reserved
					}
				}
				'nil' {
					return ast.Litreal{
						hint:  ast.LitrealType.null
						value: x.reserved
					}
				}
				else {}
			}

			return ast.Identifier{
				token: x
				from:  p.module_
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
			if x.open && x.value == '(' {
				p.eat(token.Token{
					token_type: token.Punctuation{
						open:  true
						value: '('
					}
				})!

				node := p.parse_bin_logical_expression(0)!

				p.eat(token.Token{
					token_type: token.Punctuation{
						open:  false
						value: ')'
					}
				})!

				return node
			}
		}
		else {}
	}
	return error(errors_df.gen_custom_error_message('parsing', 'parse_factor', p.lex.file_path,
		p.lex.cur_line, p.lex.cur_col, errors_df.ErrorUnexpectedToken{
		token: p.cur_token.get_value()
	}))
}

fn (mut p Parse) parse_bin_logical_expression(precedence int) !ast.Node {
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

				right := p.parse_bin_logical_expression(prec)!

				match x.value {
					'&&', '||', '!=', '==', '>', '<', '>=', '<=' {
						left = ast.Logical{
							operator: x.value
							left:     left
							right:    right
						}
					}
					else {
						left = ast.Binary{
							operator: x.value
							left:     left
							right:    right
						}
					}
				}
			}
			else {
				break
			}
		}
	}
	return left
}

fn (mut p Parse) parse_call_expression() !ast.Node {
	mut call_expression := ast.CallExpression{
		base:      ast.Identifier{
			token: p.cur_token.token_type as token.Identifier
			from:  p.module_
		}
		arguments: []
	}

	p.eat_with_name_token(token.Token{
		token_type: token.Identifier{}
	})!

	p.eat(token.Token{
		token_type: token.Punctuation{
			open:  true
			value: '('
		}
	})!

	for {
		match p.cur_token.token_type {
			token.Punctuation {
				if p.check_token(token.Token{
					token_type: token.Punctuation{
						open:  false
						value: ')'
					}
				})
				{
					p.eat(token.Token{
						token_type: token.Punctuation{
							open:  false
							value: ')'
						}
					})!

					break
				}
			}
			else {}
		}
		call_expression.arguments << p.parse_expression()!

		p.eat(token.Token{
			token_type: token.Seperator{
				value: ','
			}
		}) or {
			p.eat(token.Token{
				token_type: token.Punctuation{
					open:  false
					value: ')'
				}
			}) or {
				return error(errors_df.gen_custom_error_message('parsing', 'call_exp',
					p.lex.file_path, p.lex.cur_line, p.lex.cur_col, errors_df.ErrorUnexpectedTokenExpectedEitherOr{
					found:    p.cur_token.get_value()
					either:   ')'
					or_token: ','
				}))
			}
			break
		}
	}

	return call_expression
}

fn (mut p Parse) parse_expression() !ast.Node {
	match p.cur_token.token_type {
		token.String, token.Numeric, token.Identifier {
			return p.parse_bin_logical_expression(0)
		}
		token.Punctuation {
			if p.check_next_with_name_token(token.Token{ token_type: token.Numeric{} }) || p.check_next_with_name_token(token.Token{
				token_type: token.String{}
			}) {
				return p.parse_bin_logical_expression(0)
			}
		}
		else {}
	}
	return error(errors_df.gen_custom_error_message('parsing', 'expression', p.lex.file_path,
		p.lex.cur_line, p.lex.cur_col, errors_df.ErrorUnexpectedToken{
		token: p.cur_token.get_value()
	}))
}

fn (mut p Parse) parse_cond_statement(parse_condition bool, hint ast.Conditions) !ast.Node {
	p.eat_with_name_token(token.Token{ token_type: token.Identifier{} })!
	mut cond_clause := ast.ConditionClause{
		hint:      hint
		condition: if parse_condition { p.parse_expression()! } else { none }
		body:      []
	}

	p.eat(token.Token{
		token_type: token.Punctuation{
			open:  true
			value: '{'
		}
	})!

	cond_clause.body << p.walk()!

	p.eat(token.Token{
		token_type: token.Punctuation{
			open:  false
			value: '}'
		}
	})!

	return cond_clause
}

fn (mut p Parse) parse_if_statement() !ast.Node {
	mut else_used := false

	mut ret_statement := ast.IfStatement{
		clauses: []
	}

	ret_statement.clauses << p.parse_cond_statement(true, ast.Conditions.if_clause)!

	for {
		x := p.cur_token.token_type
		match x {
			token.Identifier {
				if x.reserved == 'else' {
					if p.check_next_identifier_reserved('if') {
						p.eat_with_name_token(token.Token{ token_type: token.Identifier{} })!
						if else_used {
							return error(errors_df.gen_custom_error_message('parsing',
								'if_statement', p.lex.file_path, p.lex.cur_line, p.lex.cur_col,
								errors_df.ErrorUsingElseIfAfterElse{
								trying_to_use: 'else if'
								before_using:  'else'
							}))
						}

						ret_statement.clauses << p.parse_cond_statement(true, ast.Conditions.else_if_clause)!
					} else {
						if else_used {
							return error(errors_df.gen_custom_error_message('parsing',
								'if_statement', p.lex.file_path, p.lex.cur_line, p.lex.cur_col,
								errors_df.ErrorUsingElseIfAfterElse{
								trying_to_use: 'else'
								before_using:  'else'
							}))
						}

						ret_statement.clauses << p.parse_cond_statement(false, ast.Conditions.else_clause)!
						else_used = true
					}
				} else {
					break
				}
			}
			else {
				break
			}
		}
	}

	return ret_statement
}

fn (mut p Parse) parse_loop_statement() !ast.Node {
	p.eat_with_name_token(token.Token{ token_type: token.Identifier{} })!
	mut loop_statement := ast.ForStatement{
		condition: if p.check_token(token.Token{
			token_type: token.Punctuation{
				open:  true
				value: '{'
			}
		})
		{
			none
		} else {
			p.parse_expression()!
		}
		body:      []
	}

	p.eat(token.Token{
		token_type: token.Punctuation{
			open:  true
			value: '{'
		}
	})!

	loop_statement.body << p.walk()!

	p.eat(token.Token{
		token_type: token.Punctuation{
			open:  false
			value: '}'
		}
	})!

	return loop_statement
}

fn (p &Parse) get_first_value_from_node(ast_nodes []ast.Node) !ast.Node {
	if ast_nodes.len > 0 {
		return ast_nodes[0]
	}
	return error(errors_df.gen_custom_error_message('parsing', 'empty_exp', p.lex.file_path,
		p.lex.cur_line, p.lex.cur_col, errors_df.ErrorUnexpected{}))
}

fn (mut p Parse) parse_identifier() !ast.Node {
	match p.cur_token.token_type {
		token.Identifier {
			ident := p.cur_token.token_type as token.Identifier
			if p.check_next_token(token.Token{
				token_type: token.Operator{
					value: '='
				}
			}) || p.check_next_token(token.Token{
				token_type: token.Operator{
					value: '?='
				}
			}) {
				p.eat_with_name_token(token.Token{
					token_type: token.Identifier{}
				})!

				operator_value := p.cur_token.get_value()

				p.eat(token.Token{
					token_type: token.Operator{
						value: operator_value
					}
				})!

				return ast.AssignmentStatement{
					hint:     operator_value
					variable: ast.Identifier{
						token: ident
						from:  p.module_
					}
					init:     p.parse_expression()!
				}
			}

			match ident.reserved {
				'if' {
					return p.parse_if_statement()
				}
				'loop' {
					return p.parse_loop_statement()
				}
				'function' {
					return p.parse_function()
				}
				'break' {
					p.eat_with_name_token(token.Token{
						token_type: token.Identifier{}
					})!
					return ast.BreakStatement{}
				}
				'continue' {
					p.eat_with_name_token(token.Token{
						token_type: token.Identifier{}
					})!
					return ast.ContinueStatement{}
				}
				'return' {
					p.eat_with_name_token(token.Token{
						token_type: token.Identifier{}
					})!
					return ast.ReturnStatement{
						value: p.parse_expression()!
					}
				}
				'import' {
					return p.parse_import_statement()!
				}
				else {}
			}

			return p.parse_expression()!
		}
		else {}
	}

	return error(errors_df.gen_custom_error_message('parsing', 'expression', p.lex.file_path,
		p.lex.cur_line, p.lex.cur_col, errors_df.ErrorUnexpectedToken{
		token: p.cur_token.get_value()
	}))
}

pub fn (mut proc Parse) walk() ![]ast.Node {
	mut return_node := []ast.Node{}

	for {
		// temprorary
		match proc.cur_token.token_type {
			token.String, token.Numeric {
				// if p.check_next_with_name_token(token.Token{
				// 	token_type: token.Operator{}
				// })
				// {
				return_node << proc.parse_expression()!
				// }
			}
			token.Punctuation {
				if proc.check_token(token.Token{
					token_type: token.Punctuation{
						open:  false
						value: '}'
					}
				})
				{
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
			else {}
		}
		proc.next() or { break }
	}

	return return_node
}

pub fn (mut p Parse) walk_main() ! {
	p.ast.body << p.walk()!
}

pub fn (Parse &Parse) error_generator(extra_info string, error_data errors_df.ErrorInterface) errors_df.DfError {
	return errors_df.DfError{
		while:    '"parsing"'
		when:     extra_info
		path:     Parse.lex.file_path
		cur_line: Parse.lex.cur_line
		cur_col:  if Parse.cur_token.range.len > 0 { int(Parse.cur_token.range[0]) } else { 0 }
		error:    error_data
	}
}

// Create New Parser
pub fn Parse.new(path string, module_name string) !&Parse {
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
	}
}

pub fn (mut p Parse) append_to_lex(input_data string) ![]ast.Node {
	p.lex.file_data += input_data
	p.lex.file_len += input_data.len

	p.nxt_token = token.Token{
		token_type: token.EOL{}
	}
	p.next()!

	p.walk_main()!

	return p.ast.body
}

pub fn Parse.new_temp(go_through_file_data string) !&Parse {
	identifier_value_map = map[string]ast.EvalOutput{}
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
		module_:  ''
		cur_file: '/tmp/sai'
	}
}
