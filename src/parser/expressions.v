module parser

import math
import strconv
import strings
import token
import ast
import grammar
import errors_df

// ============================================
// Constant Folding Optimization
// ============================================

fn try_binary_folding(left ast.Node, right ast.Node, op string, module_ []string) ?ast.Node {
	left_lit := match left {
		ast.Literal { left }
		else { return none }
	}

	right_lit := match right {
		ast.Literal { right }
		else { return none }
	}

	// String concatenation
	if left_lit.hint == .str && right_lit.hint == .str {
		if op == '+' {
			return ast.Literal{
				hint:  .str
				value: '${left_lit.value}${right_lit.value}'
				from:  module_
			}
		}
		return none
	}

	// String repetition
	if left_lit.hint == .str && (right_lit.hint == .integer || right_lit.hint == .floating_point) {
		if op == '*' {
			return ast.Literal{
				hint:  .str
				value: strings.repeat_string(left_lit.value, right_lit.value.int())
				from:  module_
			}
		}
		return none
	}

	// Floating point operations
	if left_lit.hint == .floating_point || right_lit.hint == .floating_point {
		l := strconv.atof64(left_lit.value) or { return none }
		r := strconv.atof64(right_lit.value) or { return none }

		result := match op {
			'+' { l + r }
			'-' { l - r }
			'*' { l * r }
			'/' { if r != 0.0 { l / r } else { return none } }
			'^' { math.pow(l, r) }
			'%' { math.fmod(l, r) }
			else { return none }
		}

		return ast.Literal{
			hint:  .floating_point
			value: '${result}'
			from:  module_
		}
	}

	// Integer operations
	l := left_lit.value.i64()
	r := right_lit.value.i64()

	result := match op {
		'+' { l + r }
		'-' { l - r }
		'*' { l * r }
		'/' { if r != 0 { l / r } else { return none } }
		'^' { i64(math.powi(l, r)) }
		'%' { if r != 0 { l % r } else { return none } }
		else { return none }
	}

	return ast.Literal{
		hint:  .integer
		value: '${result}'
		from:  module_
	}
}

// ============================================
// Binary and Logical Expression Parsing
// ============================================

fn (mut p Parse) parse_bin_logical_expression(precedence int) !ast.Node {
	mut left := p.parse_factor()!

	for {
		match p.cur_token.token_type {
			token.Operator {
				op := p.cur_token.token_type as token.Operator

				if op.value == '=>' {
					return left
				}

				prec := grammar.precedence[op.value] or { break }

				if prec < precedence {
					return left
				}

				p.eat(token.Token{ token_type: token.Operator{ value: op.value } })!

				// Handle pop operator
				if op.value == '>>' {
					left = ast.AssignmentStatement{
						hint:     '>>'
						variable: left
						init:     ast.Node(ast.Literal{
							hint:  .integer
							value: '0'
							from:  p.module_
						})
					}
					continue
				}

				right := p.parse_bin_logical_expression(prec)!

				match op.value {
					'&&', '||', '!=', '==', '>', '<', '>=', '<=' {
						left = ast.Logical{
							operator: op.value
							left:     left
							right:    right
						}
					}
					'=', '?=', '<<' {
						break
					}
					else {
						// Try constant folding optimization
						if folded := try_binary_folding(left, right, op.value, p.module_) {
							left = folded
						} else {
							left = ast.Binary{
								operator: op.value
								left:     left
								right:    right
							}
						}
					}
				}
			}
			token.EOL, token.Comment, token.EOF, token.Separator, token.Punctuation {
				return left
			}
			else {
				break
			}
		}
	}

	return error(errors_df.gen_custom_error_message('parsing', 'bin_op', p.lex.file_path,
		p.lex.cur_line, p.lex.cur_col, errors_df.ErrorUnexpectedToken{
		token: p.cur_token.get_value()
	}))
}

// ============================================
// Expression Parsing Entry Point
// ============================================

fn (mut p Parse) parse_expression() !ast.Node {
	match p.cur_token.token_type {
		token.String, token.Numeric, token.Identifier {
			return p.parse_bin_logical_expression(0)
		}
		token.Punctuation {
			cur_value := p.cur_token.get_value()
			if cur_value == '[' {
				return p.parse_factor()
			} else if cur_value == '(' {
				return p.parse_bin_logical_expression(0)
			}
		}
		token.Operator {
			if p.check_token(token.Token{ token_type: token.Operator{'!'} }) ||
			   p.check_token(token.Token{ token_type: token.Operator{'-'} }) {
				return p.parse_factor()!
			}
		}
		else {}
	}

	return error(errors_df.gen_custom_error_message('parsing', 'expression', p.lex.file_path,
		p.lex.cur_line, p.lex.cur_col, errors_df.ErrorUnexpectedToken{
		token: p.cur_token.get_value()
	}))
}

// ============================================
// Call Expression Parsing
// ============================================

fn (mut p Parse) parse_call_arguments() ![]ast.Node {
	mut arguments := []ast.Node{}

	p.eat(token.Token{ token_type: token.Punctuation{ open: true, value: '(' } })!

	for {
		// Check for closing paren
		if p.check_token(token.Token{ token_type: token.Punctuation{ open: false, value: ')' } }) {
			if p.check_prev_token(token.Token{ token_type: token.Separator{ value: ',' } }) {
				return error(errors_df.gen_custom_error_message('parsing', 'call_exp',
					p.lex.file_path, p.lex.cur_line, p.lex.cur_col, errors_df.ErrorCannotUseTokenIfBefore{
					having: ','
					token:  ')'
				}))
			}
			p.eat(token.Token{ token_type: token.Punctuation{ open: false, value: ')' } })!
			break
		}

		arguments << p.parse_expression()!

		// Expect comma or closing paren
		p.eat(token.Token{ token_type: token.Separator{ value: ',' } }) or {
			p.eat(token.Token{ token_type: token.Punctuation{ open: false, value: ')' } }) or {
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

	return arguments
}

fn (mut p Parse) parse_call_expression() !ast.Node {
	mut call_expression := ast.CallExpression{
		base:      ast.Identifier{
			token: p.cur_token.token_type as token.Identifier
			from:  p.module_
		}
		call_path: p.cur_file
	}

	p.eat_with_name_token(token.Token{ token_type: token.Identifier{} })!
	call_expression.arguments = p.parse_call_arguments()!

	return call_expression
}

// ============================================
// Index Expression Parsing
// ============================================

fn (mut p Parse) parse_index_expression() !ast.Node {
	mut index_exp := ast.IndexExpression{
		base:    ast.Identifier{
			token: p.cur_token.token_type as token.Identifier
			from:  p.module_
		}
		indexes: []
	}

	p.eat_with_name_token(token.Token{ token_type: token.Identifier{} })!

	// Parse all index brackets
	for {
		if !p.check_token(token.Token{ token_type: token.Punctuation{ open: true, value: '[' } }) {
			break
		}
		p.eat(token.Token{ token_type: token.Punctuation{ open: true, value: '[' } })!
		index_exp.indexes << p.parse_expression()!
		p.eat(token.Token{ token_type: token.Punctuation{ open: false, value: ']' } })!
	}

	// Check if this is a method call
	if p.check_token(token.Token{ token_type: token.Punctuation{ open: true, value: '(' } }) {
		mut call_expression := ast.CallExpression{
			base:      index_exp
			call_path: p.cur_file
		}
		call_expression.arguments = p.parse_call_arguments()!
		return call_expression
	}

	return index_exp
}

// ============================================
// Table Constructor Expression
// ============================================

fn (mut p Parse) parse_table_constructor_expression() ![]ast.Node {
	mut ret_node := []ast.Node{}

	for {
		if p.check_token(token.Token{ token_type: token.Punctuation{ open: false, value: ']' } }) {
			break
		}

		match p.cur_token.token_type {
			token.String, token.Numeric, token.Identifier, token.Punctuation {
				parsed_exp := p.parse_expression()!

				// Check for key => value syntax
				if p.check_token(token.Token{ token_type: token.Operator{ value: '=>' } }) {
					p.eat(token.Token{ token_type: token.Operator{ value: '=>' } })!

					match parsed_exp {
						ast.Literal {
							ret_node << ast.TableKey{
								key:   parsed_exp
								value: p.parse_expression()!
							}
						}
						else {
							return error(errors_df.gen_custom_error_message('parsing',
								'key_constructor', p.lex.file_path, p.lex.cur_line, p.lex.cur_col,
								errors_df.ErrorTableKeyCannotBeOtherThanLiteral{}))
						}
					}
				} else {
					ret_node << parsed_exp
				}
			}
			token.EOL {
				p.eat(token.Token{ token_type: token.EOL{} })!
			}
			token.Comment {
				p.eat(token.Token{ token_type: token.Comment{} })!
			}
			else {
				return error(errors_df.gen_custom_error_message('parsing', 'table_constructor',
					p.lex.file_path, p.lex.cur_line, p.lex.cur_col, errors_df.ErrorUnexpectedToken{
					token: p.cur_token.get_value()
				}))
			}
		}

		// Optional comma
		p.eat(token.Token{ token_type: token.Separator{ value: ',' } }) or {}
	}

	return ret_node
}

