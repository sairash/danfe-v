module cli_df


pub const version = "0.0.1"

// text color
pub const reset = '\033[0m'
pub const red = '\033[31m'
pub const green = '\033[32m'
pub const yellow = '\033[33m'
pub const blue = '\033[34m'
pub const magenta = '\033[35m'
pub const cyan = '\033[36m'
pub const white = '\033[37m'
pub const black = '\033[30m'

// Background color
pub const bg_white = '\033[107m'
pub const bg_gray = '\033[48;5;240m'

// extra decorations
pub const double_underline = '\033[21m'
pub const underline = '\033[4m'
pub const bold = '\033[1m'
pub const clear_screen = '\033[2J\033[H'