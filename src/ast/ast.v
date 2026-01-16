module ast

import os
import token

// ============================================
// Global Runtime State
// ============================================

// Identifier assignment tracker - maps process IDs to their assigned variables
__global identifier_assignment_tracker = map[string][]string{}

// Main identifier value storage - maps fully qualified names to their values
__global identifier_value_map = map[string]EvalOutput{}

// Program state storage - maps process IDs to their control flow state
__global program_state_map = map[string]ProgramStateStore{}

// Server URL function map (for server module)
__global server_url_function_map = EvalOutput{}

// Base directory path for resolving package imports
__global base_dir_path = os.dir(os.executable())

// Empty process singleton for use in global scope
__global empty_process = &Process{'', false}

// ============================================
// Public Accessor Functions for Globals
// ============================================

// get_empty_process returns the global empty process singleton
pub fn get_empty_process() &Process {
	return empty_process
}

// get_base_dir_path returns the base directory path
pub fn get_base_dir_path() string {
	return base_dir_path
}

// ============================================
// Core Types
// ============================================

// EvalOutput represents the possible output types from evaluating an AST node
pub type EvalOutput = string | i64 | f64 | Table | FunctionStore

// Table represents both arrays and hash maps in Danfe
pub struct Table {
pub mut:
	table  map[string]EvalOutput
	len    int
	is_arr bool
}

// Process represents an execution context/scope
@[heap]
pub struct Process {
pub:
	value     string
	is_module bool
}

// Node is the interface that all AST nodes must implement
pub interface Node {
	eval(process_id []&Process) !EvalOutput
}

// Chunk represents a block of AST nodes
pub struct Chunk {
pub mut:
	body  []Node
	range []i64
}

// ProgramState represents the control flow state
pub enum ProgramState {
	@none
	break_
	continue_
	return_
}

// ProgramStateStore holds the current program state and associated value
pub struct ProgramStateStore {
pub:
	hint  ProgramState
	value EvalOutput
}

// LiteralType represents the different types of literals
pub enum LiteralType {
	integer
	floating_point
	str
	boolean
	null
}

// Conditions represents the types of conditional clauses
pub enum Conditions {
	if_clause
	else_if_clause
	else_clause
}

// ============================================
// AST Node Structs
// ============================================

pub struct Literal {
pub mut:
	hint  LiteralType
	value string
	from  []string @[required]
}

pub struct Identifier {
pub mut:
	token token.Identifier
	from  []string @[required]
}

pub struct Binary {
pub mut:
	operator string
	left     Node
	right    Node
}

pub struct Logical {
pub mut:
	operator string
	left     Node
	right    Node
}

pub struct UnaryExpression {
pub mut:
	operator string
	argument Node
}

pub struct IndexExpression {
pub mut:
	base    Identifier
	indexes []Node
}

pub struct TableKey {
pub mut:
	key   Literal
	value Node
}

pub struct TableConstructorExpression {
pub mut:
	fields []Node
}

pub struct AssignmentStatement {
pub mut:
	hint     string @[required]
	variable Node
	init     Node
}

pub struct ConditionClause {
pub mut:
	hint      Conditions
	condition ?Node
	body      []Node
}

pub struct IfStatement {
pub mut:
	clauses []Node
}

pub struct ForStatement {
pub mut:
	condition ?Node
	body      []Node
}

pub struct BreakStatement {}

pub struct ContinueStatement {}

pub struct ReturnStatement {
pub mut:
	value Node
}

pub struct DelStatement {
pub mut:
	variable Identifier
}

pub struct ImportStatement {
pub mut:
	path         string
	module_      string
	from_path    string
	from_module_ []string
}

pub struct FunctionStore {
pub mut:
	parameters         []Identifier
	body               []Node
	scope              &Process
	declared_at_module string @[required]
}

pub struct FunctionDeclaration {
pub mut:
	name       Identifier
	parameters []Identifier
	body       []Node
	scope      &Process @[required]
	prev_scope &Process @[required]
}

pub struct FunctionDeclared {}

pub struct CallExpression {
pub mut:
	call_path string @[required]
	base      Node
	arguments []Node
}
