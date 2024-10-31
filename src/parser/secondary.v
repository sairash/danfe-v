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
	p.eat_with_name_token(token.Token{ token_type: token.Identifier{} })!

	if !p.check_token_with_name(token.Token{
		token_type: token.String{}
	}) {
		return error(errors_df.gen_custom_error_message('parsing', 'import', p.lex.file_path,
			p.lex.cur_line, p.lex.cur_col, errors_df.ErrorCantFindExpectedToken{
			token: '"file" after import for eg. (import "./file_name.df") or (import "file_name") or (import "file_name" as "my_file")'
		}))
	}

	mut import_statement := ast.ImportStatement{
		from_path:    p.cur_file
		from_module_: p.module_
		path:         resolve_absolute_path(p.cur_file, (p.parse_factor()! as ast.Litreal).value)
	}

	if !p.check_current_identifier_reserved('as') {
		import_statement.module_ = p.strip_filename(import_statement.path)!
	} else {
		p.eat_with_name_token(token.Token{ token_type: token.Identifier{} })!
		if !p.check_token_with_name(token.Token{
			token_type: token.String{}
		}) {
			return error(errors_df.gen_custom_error_message('parsing', 'import', p.lex.file_path,
				p.lex.cur_line, p.lex.cur_col, errors_df.ErrorCantFindExpectedToken{
				token: '"file_aliases" after as for eg. (import "./file_name.df" as "my_file")'
			}))
		}
		import_statement.module_ = (p.parse_factor()! as ast.Litreal).value
	}

	return import_statement
}
