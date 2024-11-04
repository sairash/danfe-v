module parser

import os
import ast
import token
import errors_df

pub fn format_path(input_str string) string {
	mut result := input_str

	if !result.ends_with('.df') {
		result += '.df'
	}

	if !result.contains('/') {
		result = './' + result
	}

	return result
}

fn (mut p Parse) parse_function() !ast.Node {
	p.eat_with_name_token(token.Token{ token_type: token.Identifier{} })!

	var_name := p.cur_token.token_type

	p.eat_with_name_token(token.Token{
		token_type: token.Identifier{}
	})!

	mut ret_func := ast.FunctionDeclaration{
		name:       ast.Identifier{
			token: var_name as token.Identifier
			from:  p.module_
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
					if p.check_prev_token(token.Token{
						token_type: token.Seperator{
							value: ','
						}
					})
					{
						return error(errors_df.gen_custom_error_message('parsing', 'function_declaration',
							p.lex.file_path, p.lex.cur_line, p.lex.cur_col, errors_df.ErrorCannotUseTokenIfBefore{
							having: ','
							token:  ')'
						}))
					}
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

		parsed_factor := p.parse_factor()!
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

pub fn resolve_absolute_path(base_path string, relative_path_old string) string {
	relative_path := format_path(relative_path_old)
	if relative_path.starts_with('/') {
		return relative_path
	}

	base_dir := if base_path.contains('.') {
		base_path.all_before_last('/')
	} else {
		base_path
	}

	mut base_components := base_dir.trim_string_left('/').split('/')
	relative_components := relative_path.split('/')

	mut result_components := base_components.clone()

	for i := 0; i < relative_components.len - 1; i++ {
		component := relative_components[i]
		match component {
			'.' {}
			'..' {
				if result_components.len > 0 {
					result_components.delete_last()
				}
			}
			'' {}
			else {
				result_components << component
			}
		}
	}

	last_component := relative_components.last()
	match last_component {
		'.' {}
		'..' {
			if result_components.len > 0 {
				result_components.delete_last()
			}
		}
		'' {}
		else {
			result_components << last_component
		}
	}

	return '/' + result_components.join('/')
}

fn (p Parse) strip_filename(path string) !string {
	base := os.base(path)
	parts := os.file_name(base).split('.')

	if parts.len > 1 {
		return parts[0..parts.len - 1].join('.')
	}

	return error(errors_df.gen_custom_error_message('parsing', 'file_name', p.lex.file_path,
		p.lex.cur_line, p.lex.cur_col, errors_df.ErrorFileIO{
		file_path: path
	}))
}

fn (mut p Parse) parse_import_statement() !ast.Node {
	if !p.lex.can_import {
		return error(errors_df.gen_custom_error_message('parsing', 'import_placement',
			p.lex.file_path, p.lex.cur_line, p.lex.cur_col, errors_df.ErrorImportPlacement{}))
	}
	p.eat_with_name_token(token.Token{ token_type: token.Identifier{} })!

	if !p.check_token_with_name(token.Token{
		token_type: token.String{}
	})  {
		return error(errors_df.gen_custom_error_message('parsing', 'import', p.lex.file_path,
			p.lex.cur_line, p.lex.cur_col, errors_df.ErrorCantFindExpectedToken{
			token: '"file" after import for eg. (import "./file_name.df") or (import "file_name") or (import "file_name" as my_file)'
		}))
	}

	mut import_statement := ast.ImportStatement{
		from_path:    p.cur_file
		from_module_: p.module_
		path:         resolve_absolute_path(p.cur_file, ( p.parse_factor()! as ast.Litreal).value)
	}

	if import_statement.from_path == import_statement.path {
		return error(errors_df.gen_custom_error_message('parsing', 'import_self', p.lex.file_path,
			p.lex.cur_line, p.lex.cur_col, errors_df.ErrorImportTryingToCallSelf{}))
	}

	if !p.check_current_identifier_reserved('as') {
		import_statement.module_ = p.strip_filename(import_statement.path)!
	} else {
		p.eat_with_name_token(token.Token{ token_type: token.Identifier{} })!
		if !p.check_token_with_name(token.Token{
		token_type: token.Identifier{}
	}) {
			return error(errors_df.gen_custom_error_message('parsing', 'import', p.lex.file_path,
				p.lex.cur_line, p.lex.cur_col, errors_df.ErrorCantFindExpectedToken{
				token: '"file_aliases" after as for eg. (import "./file_name.df" as my_file)'
			}))
		}
		mut as_value := p.parse_factor()!

		match mut as_value {
			ast.Identifier{
				as_value = ast.Litreal{
					hint: .str
					from: as_value.from
					value: as_value.token.value
				}
			}
			else {}
		}
		import_statement.module_ = (as_value as ast.Litreal).value
	}

	return import_statement
}

fn (mut p Parse) parse_index_expression() !ast.Node {
	mut index_exp := ast.IndexExpression{
		base:   ast.Identifier{
			token: p.cur_token.token_type as token.Identifier
			from:  p.module_
		}
		indexes: []
	}

	p.eat_with_name_token(token.Token{
		token_type: token.Identifier{}
	})!

	for {
		if !p.check_token(token.Token{
			token_type: token.Punctuation{
				open:  true
				value: '['
			}
		}) {
			break
		}

		p.eat(token.Token{
			token_type: token.Punctuation{
				open:  true
				value: '['
			}
		})!

		index_exp.indexes << p.parse_expression()!

		p.eat(token.Token{
			token_type: token.Punctuation{
				open:  false
				value: ']'
			}
		})!
	}

	return index_exp
}

fn (mut p Parse) parse_table_constructor_expression() ![]ast.Node {
	mut ret_node := []ast.Node{}
	for {
		if p.check_token(token.Token{
			token_type: token.Punctuation{
				open:  false
				value: ']'
			}
		})
		{
			break
		}

		match p.cur_token.token_type {
			token.String, token.Numeric, token.VBlock, token.Identifier {
				parsed_exp := p.parse_expression()!

				if p.check_token(token.Token{
					token_type: token.Operator{
						value: '=>'
					}
				})
				{
					p.eat(token.Token{
						token_type: token.Operator{
							value: '=>'
						}
					})!

					match parsed_exp {
						ast.Litreal {
							ret_node << ast.TableKey{
								key:   parsed_exp
								value: p.parse_expression()!
							}
						}
						else {
							return error(errors_df.gen_custom_error_message('parsing',
								'key_constructor', p.lex.file_path, p.lex.cur_line, p.lex.cur_col,
								errors_df.ErrorTableKeyCannotBeOtherThanLitreal{}))
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

		p.eat(token.Token{
			token_type: token.Seperator{
				value: ','
			}
		}) or {}
	}

	return ret_node
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
				from: p.module_
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

			if p.check_next_token(token.Token{
				token_type: token.Punctuation{
					open:  true
					value: '['
				}
			})
			{
				return p.parse_index_expression()
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
						from: p.module_
					}
				}
				'nil' {
					return ast.Litreal{
						hint:  ast.LitrealType.null
						value: x.reserved
						from: p.module_
					}
				}
				else {}
			}

			return ast.Identifier{
				token: x
				from:  p.module_
			}
		}
		token.VBlock {
			return ast.VBlock{
				v_code: p.cur_token.get_value()
				from:   p.module_
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
				from: p.module_
			}
		}
		token.Punctuation {
			if p.check_token(token.Token{
				token_type: token.Punctuation{
					open:  true
					value: '('
				}
			})
			{
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

			if p.check_token(token.Token{
				token_type: token.Punctuation{
					open:  true
					value: '['
				}
			})
			{
				p.eat(token.Token{
					token_type: token.Punctuation{
						open:  true
						value: '['
					}
				})!
				mut table_constructor := ast.TableConstructorExpression{
					fields: p.parse_table_constructor_expression()!
				}
				p.eat(token.Token{
					token_type: token.Punctuation{
						open:  false
						value: ']'
					}
				})!
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
