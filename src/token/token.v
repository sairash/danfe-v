module token

pub enum TokenType as u8 {
	let
	int
	float
	string
	identifier
	boolean
	operator
	punctuation
	seperator
	comment
	fi // else
	ret // return
	eol
	eof
}

pub type ExtraValue = string | int | f64 | f32 | u8 | rune 

pub struct Tokens {
	type_of  TokenType
	value string
	y int
	extravalue ExtraValue
}

