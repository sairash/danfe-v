module main

import parser
import os
import cli
import cli_df
import repl

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
					mut pars := parser.Parse.new(cmd.args[0])!
					pars.walk()!
					pars_current := pars.file_process[pars.cur_file] or { return error('') }
					pars_current_body := pars_current.ast.body

					for i := 0; i < pars_current_body.len; i += 1 {
						pars_current_body[i].eval('')!
					}
					return
				}
			},
		]
	}
	app.setup()
	app.parse(os.args)
}
