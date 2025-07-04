# Claude Commands

This directory contains reusable command patterns for AI agents. These commands provide tested, reliable patterns for common development tasks.

## Command Structure

Each command file should follow this format:
```markdown
# Command: [Name]
Purpose: [Brief description]
Category: [testing|development|deployment|analysis]

## Usage
[How to use this command]

## Command
```bash
[The actual command(s)]
```

## Example
[Example usage with expected output]

## Notes
[Any important considerations or variations]
```

## Available Commands

### Testing Commands
- `run_tests_with_coverage.md` - Run tests with coverage reporting
- `run_specific_test.md` - Run a specific test file or function
- `run_tests_watch_mode.md` - Run tests in watch mode

### Development Commands
- `start_dev_server.md` - Start the development server
- `install_dependencies.md` - Install project dependencies
- `update_dependencies.md` - Update dependencies safely

### Code Quality Commands
- `lint_and_format.md` - Run linting and formatting
- `type_check.md` - Run type checking
- `security_scan.md` - Run security vulnerability scan

### Git Commands
- `create_feature_branch.md` - Create a new feature branch
- `squash_commits.md` - Squash commits for clean history
- `update_from_main.md` - Update branch from main

### Debugging Commands
- `debug_with_breakpoint.md` - Add and use breakpoints
- `profile_performance.md` - Profile code performance
- `memory_profiling.md` - Profile memory usage

## Creating New Commands

When adding a new command:
1. Use descriptive filename (snake_case)
2. Include all variations and edge cases
3. Test the command before documenting
4. Add to appropriate category in this README
5. Include error handling examples

## Tips for AI Agents

- Commands can be referenced with: `@.claude/commands/command_name.md`
- Always check command exists before referencing
- Commands are meant to be adapted, not blindly copied
- Combine multiple commands for complex workflows