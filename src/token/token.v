module token

// Balancing Depth for token
pub type BalancingDepthType = i32

// Punctuation for eg: { } [ ] ( )
pub struct Punctuation {
pub mut:
	open  bool
	value string
}

// Seperator for eg: , ;
pub struct Seperator {
pub mut:
	value string
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


pub fn (t Token) get_name() string {
	match t.token_type {
		EOF{
			return "EOF"
		}
		EOL{
			return "EOL"
		}
		Punctuation{
			return "Punctuation (eg: {} or () or [])"
		}
		Seperator{
			return "Seperator (eg: ; or ,)"
		}
		Comment{
			return "Comment (eg: #)"
		}
		Numeric {
			return "Number (eg: 0..9)"
		}
		String {
			return "String (eg: \"\")"
		}
		Identifier {
			return "Identifier"
		}
		Operator {
			return "Operator (eg: + , - , * , /)"
		}
		ReservedSymbol {
			return "ReservedSymbol (eg if)"
		}
	}
}