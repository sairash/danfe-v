module ast

import errors_df

struct ImportCycleNode {
	name string
mut:
	children []&ImportCycleNode
}

struct Graph {
mut:
	nodes map[string]&ImportCycleNode
}

__global import_cycle_graph = Graph{}

fn (mut g Graph) add_node(name string) !&ImportCycleNode {
	if name !in g.nodes {
		g.nodes[name] = &ImportCycleNode{
			name: name
		}
	} else {
	}
	return g.nodes[name] or { return error('Add Node') }
}

fn (mut g Graph) add_child(parent_name string, child_name string) ! {
	mut parent_node := g.add_node(parent_name)!
	mut child_node := g.add_node(child_name)!

	if g.has_cycle(child_node, parent_node) {
		return error('circular dependency detected')
	}

	parent_node.children << child_node
}

fn (g Graph) has_cycle(node &ImportCycleNode, target &ImportCycleNode) bool {
	mut visited := map[string]bool{}
	return g.dfs(node, target, mut visited)
}

fn (g Graph) dfs(node &ImportCycleNode, target &ImportCycleNode, mut visited map[string]bool) bool {
	if node == target {
		return true
	}
	visited[node.name] = true

	for child in node.children {
		if child.name !in visited && g.dfs(child, target, mut visited) {
			return true
		}
	}
	return false
}

pub fn add_import(parent string, child string) ! {
	import_cycle_graph.add_child(parent, child) or {
		return error_gen('eval', 'import_cycle', errors_df.ErrorImportCycleDetected{
			from_file:     child
			detected_file: parent
		})
	}
}
