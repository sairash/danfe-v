module parser

import token
import ast
import errors_df

// ============================================
// Factor Parsing - Handles atomic expressions
// ============================================

fn (mut p Parse) parse_factor() !ast.Node {
	match p.cur_token.token_type {
		token.String {
			x := p.cur_token.token_type as token.String
			p.eat(token.Token{ token_type: token.String{ value: x.value } })!

			return ast.Literal{
				hint:  ast.LiteralType.str
				value: x.value
				from:  p.module_
			}
		}
		token.Identifier {
			// Check for function call
			if p.check_next_token(token.Token{ token_type: token.Punctuation{ open: true, value: '(' } }) {
				return p.parse_call_expression()
			}

			// Check for index expression
			if p.check_next_token(token.Token{ token_type: token.Punctuation{ open: true, value: '[' } }) {
				return p.parse_index_expression()
			}

			x := p.cur_token.token_type as token.Identifier

			mut ret_value := ast.Node(ast.Identifier{
				token: x
				from:  p.module_
			})

			// Handle reserved keywords
			match x.reserved {
				'true', 'false' {
					ret_value = ast.Literal{
						hint:  ast.LiteralType.boolean
						value: x.reserved
						from:  p.module_
					}
				}
				'if' {
					return p.parse_if_statement(false)!
				}
				'nil' {
					ret_value = ast.Literal{
						hint:  ast.LiteralType.null
						value: x.reserved
						from:  p.module_
					}
				}
				else {}
			}

			p.eat_with_name_token(token.Token{ token_type: token.Identifier{} })!
			return ret_value
		}
		token.Numeric {
			x := p.cur_token.token_type as token.Numeric
			mut lit_type := ast.LiteralType.integer

			if x.hint == token.NumericType.f64 {
				lit_type = ast.LiteralType.floating_point
			}

			p.eat(token.Token{
				token_type: token.Numeric{ value: x.value, hint: x.hint }
			})!

			return ast.Literal{
				hint:  lit_type
				value: x.value
				from:  p.module_
			}
		}
		token.Operator {
			// Handle unary operators
			if p.check_token(token.Token{ token_type: token.Operator{'!'} }) ||
			   p.check_token(token.Token{ token_type: token.Operator{'-'} }) {
				op_ := p.cur_token.get_value()
				p.eat(token.Token{ token_type: token.Operator{op_} })!

				return ast.UnaryExpression{op_, p.parse_expression()!}
			}
		}
		token.Punctuation {
			// Handle parenthesized expression
			if p.check_token(token.Token{ token_type: token.Punctuation{ open: true, value: '(' } }) {
				p.eat(token.Token{ token_type: token.Punctuation{ open: true, value: '(' } })!
				node := p.parse_bin_logical_expression(0)!
				p.eat(token.Token{ token_type: token.Punctuation{ open: false, value: ')' } })!
				return node
			}

			// Handle table/array literal
			if p.check_token(token.Token{ token_type: token.Punctuation{ open: true, value: '[' } }) {
				p.eat(token.Token{ token_type: token.Punctuation{ open: true, value: '[' } })!

				mut table_constructor := ast.TableConstructorExpression{
					fields: p.parse_table_constructor_expression()!
				}

				p.eat(token.Token{ token_type: token.Punctuation{ open: false, value: ']' } })!
				return table_constructor
			}
		}
		else {}
	}

	return error(errors_df.gen_custom_error_message('parsing', 'parse_factor', p.lex.file_path,
		p.lex.cur_line, p.lex.cur_col, errors_df.ErrorUnexpectedToken{
		token: p.cur_token.get_value()
	}))
}

