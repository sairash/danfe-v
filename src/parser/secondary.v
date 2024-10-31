module parser

import ast
import token
import errors_df

fn (mut p Process) parse_function(from string) !ast.Node {
	p.eat_with_name_token(token.Token{ token_type: token.Identifier{} })!

	var_name := p.cur_token.token_type

	p.eat_with_name_token(token.Token{
		token_type: token.Identifier{}
	})!

	mut ret_func := ast.FunctionDeclaration{
		from:       from
		name:       ast.Identifier{
			token: var_name as token.Identifier
			from:  from
		}
		parameters: []
	}

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

		parsed_factor := p.parse_factor(from)!
		match parsed_factor {
			ast.Identifier {
				ret_func.parameters << parsed_factor
			}
			else {
				return error(errors_df.gen_custom_error_message('parsing', 'function_declaration',
					p.lex.file_path, p.lex.cur_line, p.lex.cur_col, errors_df.ErrorCantFindExpectedToken{
					token: token.Token{
						token_type: token.Identifier{}
					}.get_name()
				}))
			}
		}

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
				return error(errors_df.gen_custom_error_message('parsing', 'function_declaration',
					p.lex.file_path, p.lex.cur_line, p.lex.cur_col, errors_df.ErrorUnexpectedTokenExpectedEitherOr{
					found:    p.cur_token.get_value()
					either:   ')'
					or_token: ','
				}))
			}
			break
		}
	}

	p.eat(token.Token{
		token_type: token.Punctuation{
			open:  true
			value: '{'
		}
	})!

	ret_func.body << p.walk()!

	p.eat(token.Token{
		token_type: token.Punctuation{
			open:  false
			value: '}'
		}
	})!

	return ret_func
}
