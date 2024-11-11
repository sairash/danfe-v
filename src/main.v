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
				required_args: 1
				execute:       fn (cmd cli.Command) ! {
					for _, x in cmd.args {
						if x != "-t" {
							return interpreter('i', os.abs_path(parser.format_path(cmd.args[0])),
							'main', 'main', cmd.args)
						}
					}
				}
			},
		]
	}
	app.setup()
	app.parse(os.args)
}

fn interpreter(parent_path string, child_path string, full_module_name string, module_name string, args []string) ! {
	ast.add_import(parent_path, child_path)!
	ast.set_if_module_not_already_init(full_module_name, module_name)
	ast.add_args_to_table(full_module_name, args)

	mut pars := parser.Parse.new(child_path, full_module_name)!
	pars.walk_main()!

	for i := 0; i < pars.ast.body.len; i += 1 {
		cur := pars.ast.body[i]
		match cur {
			ast.ImportStatement {
				interpreter(cur.from_path, cur.path, '${cur.from_module_}.${cur.module_}',
					cur.module_, args)!
			}
			else {
				cur.eval([''])!
			}
		}
	}
}
