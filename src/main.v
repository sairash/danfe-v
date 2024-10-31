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
					return interpreter(os.abs_path(parser.format_path(cmd.args[0])), 'main', 'main')
				}
			},
		]
	}
	app.setup()
	app.parse(os.args)
}

fn interpreter(path string, full_module_name string, module_name string) ! {
	
	if !ast.set_if_module_not_already_init(full_module_name, module_name) {
		return
	}

	mut pars := parser.Parse.new(path, full_module_name)!
	pars.walk_main()!

	for i := 0; i < pars.ast.body.len; i += 1 {
		cur := pars.ast.body[i]
		match cur {
			ast.ImportStatement {
				interpreter(cur.path, '${cur.from_module_}.${cur.module_}', cur.module_)!
			}
			else {
				cur.eval('')!
			}
		}
	}
}
