module main

import parser
import os
import cli
import cli_df
import repl
import ast

fn main() {
	mut app := cli.Command{
		name:        'Danfe'
		description: 'A programming language implementation in vlang.'
		version:     cli_df.version
		execute:     fn (cmd cli.Command) ! {
			mut repl_cur := repl.init()
			repl_cur.start()!
			return
		}
		commands:    [
			cli.Command{
				name:          'run'
				description:   'Run a Danfe program'
				required_args: 1
				usage:         '<file.df> [-t] [-a <output.txt>]'
				execute:       fn (cmd cli.Command) ! {
					file_path := os.abs_path(parser.format_path(cmd.args[0]))
					
					mut ast_output := ''
					mut i := 1
					for i < cmd.args.len {
						arg := cmd.args[i]
						if arg == '-a' && i + 1 < cmd.args.len {
							ast_output = cmd.args[i + 1]
							i += 2
						} else {
							i += 1
						}
					}
					
					return interpreter('i', file_path, ['main'], 'main', cmd.args, ast_output)
				}
			},
		]
	}
	app.setup()
	app.parse(os.args)
}

fn interpreter(parent_path string, child_path string, full_module_name []string, module_name string, args []string, ast_output string) ! {
	joined_module := full_module_name.join('.')
	ast.add_import(parent_path, child_path)!
	ast.set_if_module_not_already_init(joined_module, module_name)
	ast.add_args_to_table(joined_module, args)

	mut pars := parser.Parse.new(child_path, full_module_name)!
	pars.walk_main()!

	if ast_output != '' && full_module_name == ['main'] {
		parser.print_ast_to_file(pars.ast, ast_output)!
		println('AST written to: ${ast_output}')
	}

	for i := 0; i < pars.ast.body.len; i += 1 {
		cur := pars.ast.body[i]
		match cur {
			ast.ImportStatement {
				mut prev_module_name := cur.from_module_.clone()
				prev_module_name << cur.module_
				interpreter(cur.from_path, cur.path, prev_module_name, cur.module_, args, '')!
			}
			else {
				cur.eval([ast.get_empty_process()])!
			}
		}
	}
}
