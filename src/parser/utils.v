module parser

import ast

// ============================================
// Path Utilities
// ============================================

// format_path normalizes a path string for import resolution
pub fn format_path(input_str string) string {
	mut result := input_str

	// Add .df extension if missing
	if !result.ends_with('.df') {
		result += '.df'
	}

	// Expand @/ to packages directory
	if result.starts_with('@/') {
		result = result.replace_once('@/', '${ast.get_base_dir_path()}/packages/')
	}

	// Ensure relative path prefix
	if !result.starts_with('/') && !result.starts_with('./') {
		result = './' + result
	}

	return result
}

// resolve_absolute_path resolves a relative path against a base path
pub fn resolve_absolute_path(base_path string, relative_path_old string) string {
	relative_path := format_path(relative_path_old)

	// Already absolute
	if relative_path.starts_with('/') {
		return relative_path
	}

	// Get base directory
	base_dir := if base_path.contains('.') {
		base_path.all_before_last('/')
	} else {
		base_path
	}

	mut base_components := base_dir.trim_string_left('/').split('/')
	relative_components := relative_path.split('/')

	mut result_components := base_components.clone()

	// Process path components (except last)
	for i := 0; i < relative_components.len - 1; i++ {
		component := relative_components[i]
		match component {
			'.' {}  // Current directory - skip
			'..' {
				// Parent directory - go up
				if result_components.len > 0 {
					result_components.delete_last()
				}
			}
			'' {}  // Empty component - skip
			else {
				result_components << component
			}
		}
	}

	// Process last component
	last_component := relative_components.last()
	match last_component {
		'.' {}
		'..' {
			if result_components.len > 0 {
				result_components.delete_last()
			}
		}
		'' {}
		else {
			result_components << last_component
		}
	}

	return '/' + result_components.join('/')
}
