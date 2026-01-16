module parser

import os
import ast
import token
import errors_df

// ============================================
// Identifier Statement Parsing
// ============================================

fn (mut p Parse) parse_identifier() !ast.Node {
	match p.cur_token.token_type {
		token.Identifier {
			parse_asm := p.parse_assignment()!

			match parse_asm {
				ast.Identifier {
					match parse_asm.token.reserved {
						'if' {
							return p.parse_if_statement(true)
						}
						'loop' {
							return p.parse_loop_statement()
						}
						'function' {
							return p.parse_function()
						}
						'break' {
							p.eat_with_name_token(token.Token{ token_type: token.Identifier{} })!
							return ast.BreakStatement{}
						}
						'continue' {
							p.eat_with_name_token(token.Token{ token_type: token.Identifier{} })!
							return ast.ContinueStatement{}
						}
						'return' {
							p.eat_with_name_token(token.Token{ token_type: token.Identifier{} })!
							return ast.ReturnStatement{
								value: p.parse_expression()!
							}
						}
						'del' {
							p.eat_with_name_token(token.Token{ token_type: token.Identifier{} })!

							if !p.check_token_with_name(token.Token{ token_type: token.Identifier{} }) {
								return error(errors_df.gen_custom_error_message('parsing',
									'ident exper', p.lex.file_path, p.lex.cur_line, p.lex.cur_col,
									errors_df.ErrorCanDeleteOnlyIdentifiers{
									del_key: p.prev_token.get_value()
								}))
							}

							parse_iden := p.parse_factor()!
							match parse_iden {
								ast.Identifier {
									return ast.DelStatement{ variable: parse_iden }
								}
								else {}
							}

							return error(errors_df.gen_custom_error_message('parsing',
								'ident exper', p.lex.file_path, p.lex.cur_line, p.lex.cur_col,
								errors_df.ErrorCanDeleteOnlyIdentifiers{
								del_key: p.prev_token.get_value()
							}))
						}
						'import' {
							return p.parse_import_statement()!
						}
						else {}
					}
					return p.parse_expression()!
				}
				else {
					return parse_asm
				}
			}
		}
		else {}
	}

	return error(errors_df.gen_custom_error_message('parsing', 'ident exper', p.lex.file_path,
		p.lex.cur_line, p.lex.cur_col, errors_df.ErrorUnexpectedToken{
		token: p.cur_token.get_value()
	}))
}

// ============================================
// Assignment Parsing
// ============================================

fn (mut p Parse) parse_assignment() !ast.Node {
	mut var_ := ast.Node(ast.Identifier{
		token: p.cur_token.token_type as token.Identifier
		from:  p.module_
	})

	// Check for index expression
	if p.check_next_token(token.Token{ token_type: token.Punctuation{ open: true, value: '[' } }) {
		var_ = p.parse_index_expression()!
	}

	cur_value := p.cur_token.get_value()
	next_value := p.nxt_token.get_value()

	// Check for assignment operators
	if cur_value == '=' || cur_value == '?=' || cur_value == '<<' ||
	   next_value == '=' || next_value == '?=' || next_value == '<<' {

		match var_ {
			ast.Identifier {
				p.eat_with_name_token(token.Token{ token_type: token.Identifier{} })!
			}
			else {}
		}

		operator_value := p.cur_token.get_value()
		p.eat(token.Token{ token_type: token.Operator{ value: operator_value } })!

		// Check for anonymous function assignment
		if p.check_current_identifier_reserved('function') {
			p.eat_with_name_token(token.Token{ token_type: token.Identifier{} })!

			previous_scope := p.scope
			p.scope = ast.gen_process_id(ast.get_empty_process())

			mut assignment_func_store := ast.FunctionStore{
				scope:              p.scope
				declared_at_module: p.module_.join('.')
			}
			assignment_func_store.parameters, assignment_func_store.body = p.parse_function_inner()!

			p.scope = previous_scope

			return ast.AssignmentStatement{
				hint:     operator_value
				variable: var_
				init:     assignment_func_store
			}
		}

		return ast.AssignmentStatement{
			hint:     operator_value
			variable: var_
			init:     p.parse_expression()!
		}
	}

	return var_
}

// ============================================
// Conditional Statement Parsing
// ============================================

fn (mut p Parse) parse_cond_statement(parse_condition bool, hint ast.Conditions) !ast.Node {
	p.eat_with_name_token(token.Token{ token_type: token.Identifier{} })!

	mut cond_clause := ast.ConditionClause{
		hint:      hint
		condition: if parse_condition { p.parse_expression()! } else { none }
		body:      []
	}

	p.eat(token.Token{ token_type: token.Punctuation{ open: true, value: '{' } })!
	cond_clause.body << p.walk()!
	p.eat(token.Token{ token_type: token.Punctuation{ open: false, value: '}' } })!

	return cond_clause
}

fn (mut p Parse) parse_if_statement(skip_space bool) !ast.Node {
	mut else_used := false
	mut ret_statement := ast.IfStatement{ clauses: [] }

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
			token.EOL {
				if skip_space {
					p.eat_with_name_token(token.Token{ token_type: token.EOL{} })!
				} else {
					break
				}
			}
			token.Comment {
				if skip_space {
					p.eat_with_name_token(token.Token{ token_type: token.Comment{} })!
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

// ============================================
// Loop Statement Parsing
// ============================================

fn (mut p Parse) parse_loop_statement() !ast.Node {
	p.eat_with_name_token(token.Token{ token_type: token.Identifier{} })!

	mut loop_statement := ast.ForStatement{
		condition: if p.check_token(token.Token{ token_type: token.Punctuation{ open: true, value: '{' } }) {
			none
		} else {
			p.parse_expression()!
		}
		body: []
	}

	p.eat(token.Token{ token_type: token.Punctuation{ open: true, value: '{' } })!
	loop_statement.body << p.walk()!
	p.eat(token.Token{ token_type: token.Punctuation{ open: false, value: '}' } })!

	return loop_statement
}

// ============================================
// Function Declaration Parsing
// ============================================

fn (mut p Parse) parse_function_inner() !([]ast.Identifier, []ast.Node) {
	mut params := []ast.Identifier{}
	mut body := []ast.Node{}

	p.eat(token.Token{ token_type: token.Punctuation{ open: true, value: '(' } })!

	for {
		// Check for closing paren
		if p.check_token(token.Token{ token_type: token.Punctuation{ open: false, value: ')' } }) {
			if p.check_prev_token(token.Token{ token_type: token.Separator{ value: ',' } }) {
				return error(errors_df.gen_custom_error_message('parsing', 'function_declaration',
					p.lex.file_path, p.lex.cur_line, p.lex.cur_col, errors_df.ErrorCannotUseTokenIfBefore{
					having: ','
					token:  ')'
				}))
			}
			p.eat(token.Token{ token_type: token.Punctuation{ open: false, value: ')' } })!
			break
		}

		parsed_factor := p.parse_factor()!
		match parsed_factor {
			ast.Identifier {
				params << parsed_factor
			}
			else {
				return error(errors_df.gen_custom_error_message('parsing', 'function_declaration',
					p.lex.file_path, p.lex.cur_line, p.lex.cur_col, errors_df.ErrorCantFindExpectedToken{
					token: token.Token{ token_type: token.Identifier{} }.get_name()
				}))
			}
		}

		// Expect comma or closing paren
		p.eat(token.Token{ token_type: token.Separator{ value: ',' } }) or {
			p.eat(token.Token{ token_type: token.Punctuation{ open: false, value: ')' } }) or {
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

	p.eat(token.Token{ token_type: token.Punctuation{ open: true, value: '{' } })!
	body << p.walk()!
	p.eat(token.Token{ token_type: token.Punctuation{ open: false, value: '}' } })!

	return params, body
}

fn (mut p Parse) parse_function() !ast.Node {
	p.eat_with_name_token(token.Token{ token_type: token.Identifier{} })!

	var_name := p.cur_token.token_type
	p.eat_with_name_token(token.Token{ token_type: token.Identifier{} })!

	mut ret_func := ast.FunctionDeclaration{
		name:       ast.Identifier{
			token: var_name as token.Identifier
			from:  p.module_
		}
		parameters: []
		scope:      ast.gen_process_id(ast.get_empty_process())
		prev_scope: p.scope
	}
	p.scope = ret_func.scope

	ret_func.parameters, ret_func.body = p.parse_function_inner()!

	p.scope = ret_func.prev_scope

	return ret_func
}

// ============================================
// Import Statement Parsing
// ============================================

fn (mut p Parse) parse_import_statement() !ast.Node {
	if !p.lex.can_import {
		return error(errors_df.gen_custom_error_message('parsing', 'import_placement',
			p.lex.file_path, p.lex.cur_line, p.lex.cur_col, errors_df.ErrorImportPlacement{}))
	}

	p.eat_with_name_token(token.Token{ token_type: token.Identifier{} })!

	if !p.check_token_with_name(token.Token{ token_type: token.String{} }) {
		return error(errors_df.gen_custom_error_message('parsing', 'import', p.lex.file_path,
			p.lex.cur_line, p.lex.cur_col, errors_df.ErrorCantFindExpectedToken{
			token: '"file" after import for eg. (import "./file_name.df") or (import "file_name") or (import "file_name" as my_file)'
		}))
	}

	mut import_statement := ast.ImportStatement{
		from_path:    p.cur_file
		from_module_: p.module_
		path:         resolve_absolute_path(p.cur_file, (p.parse_factor()! as ast.Literal).value)
	}

	if import_statement.from_path == import_statement.path {
		return error(errors_df.gen_custom_error_message('parsing', 'import_self', p.lex.file_path,
			p.lex.cur_line, p.lex.cur_col, errors_df.ErrorImportTryingToCallSelf{}))
	}

	if !p.check_current_identifier_reserved('as') {
		import_statement.module_ = p.strip_filename(import_statement.path)!
	} else {
		p.eat_with_name_token(token.Token{ token_type: token.Identifier{} })!

		if !p.check_token_with_name(token.Token{ token_type: token.Identifier{} }) {
			return error(errors_df.gen_custom_error_message('parsing', 'import', p.lex.file_path,
				p.lex.cur_line, p.lex.cur_col, errors_df.ErrorCantFindExpectedToken{
				token: '"file_aliases" after as for eg. (import "./file_name.df" as my_file)'
			}))
		}

		mut as_value := p.parse_factor()!
		match mut as_value {
			ast.Identifier {
				as_value = ast.Literal{
					hint:  .str
					from:  as_value.from
					value: as_value.token.value
				}
			}
			else {}
		}
		import_statement.module_ = (as_value as ast.Literal).value
	}

	return import_statement
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

fn (p &Parse) get_first_value_from_node(ast_nodes []ast.Node) !ast.Node {
	if ast_nodes.len > 0 {
		return ast_nodes[0]
	}
	return error(errors_df.gen_custom_error_message('parsing', 'empty_exp', p.lex.file_path,
		p.lex.cur_line, p.lex.cur_col, errors_df.ErrorUnexpected{}))
}

