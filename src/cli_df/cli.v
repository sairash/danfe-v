module cli_df

import term


pub const version = "0.0.1"

pub const supports_sixel = if term.can_show_color_on_stdout() {1} else {0}

// text color
pub const reset = '\033[0m'
pub const red = '\033[31m'
pub const green = '\033[32m'
pub const yellow = '\033[33m'
pub const blue = '\033[34m'

pub const theme_purple = '\033[38;5;99m'
pub const theme_green = '\033[38;5;42m'

pub const medium_deep_blue = '\033[38;5;20m'
pub const deep_sky_blue = '\033[38;5;33m'
pub const cornflower_blue = '\033[38;5;69m'
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
pub const invert_color = '\033[7m'