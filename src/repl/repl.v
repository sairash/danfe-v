module repl

import readline { read_line }
import cli_df
import parser
import errors_df

pub struct Repl {
mut:
	data string
}

const spacer = 25

const available_commands = {
	'help':                 'Display this Information.'
	'list':                 'Show the program so far.'
	'reset':                'Clears the accumulated program, so you can start a fresh.'
	'Ctrl-C, Ctrl-D, exit': 'Exits the REPL.'
	'clear':                'Clears the screen.'
}

pub fn (mut rp Repl) start() ! {
	println('${cli_df.red} ┌────────────┐ ${cli_df.cyan} ┌ ${cli_df.reset}')
	println('${cli_df.red} │     _   __ │ ${cli_df.cyan} │ ${cli_df.reset}  Welcome to the Danfe REPL (for help with Danfe itself, type ${cli_df.bg_white}${cli_df.black} exit ${cli_df.reset} , then run ${cli_df.bg_gray} df help ${cli_df.reset}).')
	println('${cli_df.red} │  __| | / _|│ ${cli_df.cyan} │ ${cli_df.reset}  Note: the REPL is highly experimental. For best Danfe experience, use a text editor,')
	println('${cli_df.red} │ / _` || |_ │ ${cli_df.cyan} │ ${cli_df.reset}  save your code in a ${cli_df.bg_gray} main.df ${cli_df.reset} file and execute: ${cli_df.bg_gray} df run main.df ${cli_df.reset}')
	println('${cli_df.red} │| (_| ||  _|│ ${cli_df.cyan} │ ${cli_df.reset}  Danfe ${cli_df.bold} ${cli_df.version} ${cli_df.reset} Use ${cli_df.bg_white}${cli_df.black} list ${cli_df.reset} to see the program so far.')
	println('${cli_df.red} │ \\__,_||_|  │ ${cli_df.cyan} │ ${cli_df.reset}  Use Ctrl-C or ${cli_df.bg_white}${cli_df.black} exit ${cli_df.reset} to exit, or ${cli_df.bg_white}${cli_df.black} help ${cli_df.reset} to see other available commands.')
	println('${cli_df.red} └────────────┘ ${cli_df.cyan} └ ${cli_df.reset}')

	mut repl_parser := parser.Parse.new_temp('')!
	mut last_line_executed := 0

	for {
		mut input := read_line('\n>>> ')!
		if input == 'exit' {
			break
		} else if input == 'help' {
			println('Danfe ${cli_df.bold} ${cli_df.version} ${cli_df.reset} \n')
			for key, value in available_commands {
				print('${cli_df.bold}')
				print(key)
				print('${cli_df.reset}')
				print(errors_df.gen_letter(' ', spacer - (key.len - 1)))
				print(value)
				print('\n')
			}
		} else if input == 'reset' {
			repl_parser = parser.Parse.new_temp('')!
			rp.data = ''
			last_line_executed = 0
		} else if input == 'list' {
			println(rp.data)
		} else if input == 'clear' {
			print(cli_df.clear_screen)
		} else {
			input = '${input} \n'
			pars_current_body := repl_parser.append_to_lex(input)!
			rp.data += input

			for i := last_line_executed; i < pars_current_body.len; i += 1 {
				pars_current_body[i].eval() or { 

					println("")
					println(err)
				 }
				last_line_executed = i + 1
			}
		}
	}
}

pub fn init() Repl {
	return Repl{
		data: ''
	}
}
