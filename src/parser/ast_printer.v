module parser

import ast
import os
import strings

// ============================================
// AST Printer - Generates readable AST output
// ============================================

// AstPrinter handles formatting AST nodes as text
struct AstPrinter {
mut:
	indent_level int
	output       strings.Builder
}

// print_ast writes the AST to a file
pub fn print_ast_to_file(chunk ast.Chunk, output_path string) ! {
	mut printer := AstPrinter{
		indent_level: 0
		output:       strings.new_builder(4096)
	}
	
	printer.write_line('='.repeat(60))
	printer.write_line('DANFE ABSTRACT SYNTAX TREE')
	printer.write_line('='.repeat(60))
	printer.write_line('')
	
	printer.print_chunk(chunk)
	
	os.write_file(output_path, printer.output.str())!
}

// get_ast_string returns the AST as a string
pub fn get_ast_string(chunk ast.Chunk) string {
	mut printer := AstPrinter{
		indent_level: 0
		output:       strings.new_builder(4096)
	}
	
	printer.write_line('='.repeat(60))
	printer.write_line('DANFE ABSTRACT SYNTAX TREE')
	printer.write_line('='.repeat(60))
	printer.write_line('')
	
	printer.print_chunk(chunk)
	
	return printer.output.str()
}

fn (mut p AstPrinter) write(s string) {
	p.output.write_string(s)
}

fn (mut p AstPrinter) write_line(s string) {
	p.output.write_string('  '.repeat(p.indent_level))
	p.output.write_string(s)
	p.output.write_string('\n')
}

fn (mut p AstPrinter) print_chunk(chunk ast.Chunk) {
	p.write_line('Chunk {')
	p.indent_level++
	
	if chunk.range.len > 0 {
		p.write_line('range: [${chunk.range[0]}..${chunk.range[chunk.range.len - 1]}]')
	}
	
	p.write_line('body: [')
	p.indent_level++
	
	for i, node in chunk.body {
		p.print_node(node)
		if i < chunk.body.len - 1 {
			p.write_line(',')
		}
	}
	
	p.indent_level--
	p.write_line(']')
	
	p.indent_level--
	p.write_line('}')
}

fn (mut p AstPrinter) print_node(node ast.Node) {
	match node {
		ast.Literal {
			p.print_literal(node)
		}
		ast.Identifier {
			p.print_identifier(node)
		}
		ast.Binary {
			p.print_binary(node)
		}
		ast.Logical {
			p.print_logical(node)
		}
		ast.UnaryExpression {
			p.print_unary(node)
		}
		ast.AssignmentStatement {
			p.print_assignment(node)
		}
		ast.IfStatement {
			p.print_if(node)
		}
		ast.ConditionClause {
			p.print_condition_clause(node)
		}
		ast.ForStatement {
			p.print_for(node)
		}
		ast.FunctionDeclaration {
			p.print_function_declaration(node)
		}
		ast.FunctionStore {
			p.print_function_store(node)
		}
		ast.CallExpression {
			p.print_call(node)
		}
		ast.IndexExpression {
			p.print_index(node)
		}
		ast.TableConstructorExpression {
			p.print_table_constructor(node)
		}
		ast.TableKey {
			p.print_table_key(node)
		}
		ast.ImportStatement {
			p.print_import(node)
		}
		ast.ReturnStatement {
			p.print_return(node)
		}
		ast.BreakStatement {
			p.write_line('BreakStatement {}')
		}
		ast.ContinueStatement {
			p.write_line('ContinueStatement {}')
		}
		ast.DelStatement {
			p.print_del(node)
		}
		ast.FunctionDeclared {
			p.write_line('FunctionDeclared {}')
		}
		else {
			p.write_line('UnknownNode {}')
		}
	}
}

fn (mut p AstPrinter) print_literal(lit ast.Literal) {
	hint_str := match lit.hint {
		.integer { 'integer' }
		.floating_point { 'float' }
		.str { 'string' }
		.boolean { 'boolean' }
		.null { 'null' }
	}
	p.write_line('Literal { hint: ${hint_str}, value: "${lit.value}" }')
}

fn (mut p AstPrinter) print_identifier(id ast.Identifier) {
	reserved := if id.token.reserved != '' { ', reserved: "${id.token.reserved}"' } else { '' }
	p.write_line('Identifier { name: "${id.token.value}"${reserved} }')
}

fn (mut p AstPrinter) print_binary(bin ast.Binary) {
	p.write_line('Binary {')
	p.indent_level++
	p.write_line('operator: "${bin.operator}"')
	p.write_line('left: ')
	p.indent_level++
	p.print_node(bin.left)
	p.indent_level--
	p.write_line('right: ')
	p.indent_level++
	p.print_node(bin.right)
	p.indent_level--
	p.indent_level--
	p.write_line('}')
}

fn (mut p AstPrinter) print_logical(log ast.Logical) {
	p.write_line('Logical {')
	p.indent_level++
	p.write_line('operator: "${log.operator}"')
	p.write_line('left: ')
	p.indent_level++
	p.print_node(log.left)
	p.indent_level--
	p.write_line('right: ')
	p.indent_level++
	p.print_node(log.right)
	p.indent_level--
	p.indent_level--
	p.write_line('}')
}

fn (mut p AstPrinter) print_unary(unary ast.UnaryExpression) {
	p.write_line('UnaryExpression {')
	p.indent_level++
	p.write_line('operator: "${unary.operator}"')
	p.write_line('argument: ')
	p.indent_level++
	p.print_node(unary.argument)
	p.indent_level--
	p.indent_level--
	p.write_line('}')
}

fn (mut p AstPrinter) print_assignment(assign ast.AssignmentStatement) {
	p.write_line('AssignmentStatement {')
	p.indent_level++
	p.write_line('hint: "${assign.hint}"')
	p.write_line('variable: ')
	p.indent_level++
	p.print_node(assign.variable)
	p.indent_level--
	p.write_line('init: ')
	p.indent_level++
	p.print_node(assign.init)
	p.indent_level--
	p.indent_level--
	p.write_line('}')
}

fn (mut p AstPrinter) print_if(if_stmt ast.IfStatement) {
	p.write_line('IfStatement {')
	p.indent_level++
	p.write_line('clauses: [')
	p.indent_level++
	for clause in if_stmt.clauses {
		p.print_node(clause)
	}
	p.indent_level--
	p.write_line(']')
	p.indent_level--
	p.write_line('}')
}

fn (mut p AstPrinter) print_condition_clause(clause ast.ConditionClause) {
	hint_str := match clause.hint {
		.if_clause { 'if' }
		.else_if_clause { 'else if' }
		.else_clause { 'else' }
	}
	p.write_line('ConditionClause {')
	p.indent_level++
	p.write_line('type: "${hint_str}"')
	if cond := clause.condition {
		p.write_line('condition: ')
		p.indent_level++
		p.print_node(cond)
		p.indent_level--
	}
	p.write_line('body: [')
	p.indent_level++
	for node in clause.body {
		p.print_node(node)
	}
	p.indent_level--
	p.write_line(']')
	p.indent_level--
	p.write_line('}')
}

fn (mut p AstPrinter) print_for(for_stmt ast.ForStatement) {
	p.write_line('ForStatement {')
	p.indent_level++
	if cond := for_stmt.condition {
		p.write_line('condition: ')
		p.indent_level++
		p.print_node(cond)
		p.indent_level--
	} else {
		p.write_line('condition: none (infinite loop)')
	}
	p.write_line('body: [')
	p.indent_level++
	for node in for_stmt.body {
		p.print_node(node)
	}
	p.indent_level--
	p.write_line(']')
	p.indent_level--
	p.write_line('}')
}

fn (mut p AstPrinter) print_function_declaration(func ast.FunctionDeclaration) {
	p.write_line('FunctionDeclaration {')
	p.indent_level++
	p.write_line('name: "${func.name.token.value}"')
	p.write_line('parameters: [${func.parameters.map(it.token.value).join(', ')}]')
	p.write_line('body: [')
	p.indent_level++
	for node in func.body {
		p.print_node(node)
	}
	p.indent_level--
	p.write_line(']')
	p.indent_level--
	p.write_line('}')
}

fn (mut p AstPrinter) print_function_store(func ast.FunctionStore) {
	p.write_line('FunctionStore {')
	p.indent_level++
	p.write_line('parameters: [${func.parameters.map(it.token.value).join(', ')}]')
	p.write_line('body: [')
	p.indent_level++
	for node in func.body {
		p.print_node(node)
	}
	p.indent_level--
	p.write_line(']')
	p.indent_level--
	p.write_line('}')
}

fn (mut p AstPrinter) print_call(call ast.CallExpression) {
	p.write_line('CallExpression {')
	p.indent_level++
	p.write_line('base: ')
	p.indent_level++
	p.print_node(call.base)
	p.indent_level--
	p.write_line('arguments: [')
	p.indent_level++
	for arg in call.arguments {
		p.print_node(arg)
	}
	p.indent_level--
	p.write_line(']')
	p.indent_level--
	p.write_line('}')
}

fn (mut p AstPrinter) print_index(idx ast.IndexExpression) {
	p.write_line('IndexExpression {')
	p.indent_level++
	p.write_line('base: "${idx.base.token.value}"')
	p.write_line('indexes: [')
	p.indent_level++
	for index in idx.indexes {
		p.print_node(index)
	}
	p.indent_level--
	p.write_line(']')
	p.indent_level--
	p.write_line('}')
}

fn (mut p AstPrinter) print_table_constructor(table ast.TableConstructorExpression) {
	p.write_line('TableConstructorExpression {')
	p.indent_level++
	p.write_line('fields: [')
	p.indent_level++
	for field in table.fields {
		p.print_node(field)
	}
	p.indent_level--
	p.write_line(']')
	p.indent_level--
	p.write_line('}')
}

fn (mut p AstPrinter) print_table_key(key ast.TableKey) {
	p.write_line('TableKey {')
	p.indent_level++
	p.write_line('key: "${key.key.value}"')
	p.write_line('value: ')
	p.indent_level++
	p.print_node(key.value)
	p.indent_level--
	p.indent_level--
	p.write_line('}')
}

fn (mut p AstPrinter) print_import(imp ast.ImportStatement) {
	p.write_line('ImportStatement {')
	p.indent_level++
	p.write_line('path: "${imp.path}"')
	p.write_line('module: "${imp.module_}"')
	p.write_line('from_path: "${imp.from_path}"')
	p.indent_level--
	p.write_line('}')
}

fn (mut p AstPrinter) print_return(ret ast.ReturnStatement) {
	p.write_line('ReturnStatement {')
	p.indent_level++
	p.write_line('value: ')
	p.indent_level++
	p.print_node(ret.value)
	p.indent_level--
	p.indent_level--
	p.write_line('}')
}

fn (mut p AstPrinter) print_del(del ast.DelStatement) {
	p.write_line('DelStatement {')
	p.indent_level++
	p.write_line('variable: "${del.variable.token.value}"')
	p.indent_level--
	p.write_line('}')
}

