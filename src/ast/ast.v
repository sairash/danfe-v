module ast

pub struct Chunk {
	body []Stat
	range []i64
}

pub enum LitrealType {
	integer
	floating_point
	str
	boolean
	null
	reserved_symbol
}

pub struct Litreal {
	pub mut:
		hint LitrealType
		value string
}

pub struct Binary {
	pub mut:
		opeator string
		left Litreal
		right Litreal
}


type Expression = Litreal | Binary

type Stat = Expression