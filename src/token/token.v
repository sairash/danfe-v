module token

// Balancing Depth for token
pub type BalancingDepthType = i32

// Punctuation for eg: { } [ ] ( )
pub struct Punctuation {
pub mut:
	open    bool
	balance BalancingDepthType
	value   u8
}

// Seperator for eg: , ;
pub struct Seperator {
pub mut:
	value u8
}

// Comment Block
pub struct Comment {}

// End of line
pub struct EOL {}

// End of file
pub struct EOF {}

// The only 2 types allowed in the language
pub enum NumericType {
	i64
	f64
}

// Numbers frome 0 .. 9
pub struct Numeric {
pub mut:
	value string
	hint  NumericType
}

// String Type
pub struct String {
pub mut:
	value string
}

// Sequence of characters to define value
pub struct Identifier {
pub mut:
	value string
}

// Actions for eg: + - *
pub struct Operator {
pub mut:
	value string
}

// for if else print and other symboles
pub struct ReservedSymbol {
pub mut:
	value string
}

pub type TokenType = EOL
	| EOF
	| Punctuation
	| Seperator
	| Numeric
	| String
	| Identifier
	| Operator
	| ReservedSymbol
	| Comment

pub struct Token {
	pub mut:
	token_type TokenType
	range      []i64
}
