# CLI Quality Checklist

## Before Release

### Functional Requirements

- [ ] **Commands**: All commands work as documented
- [ ] **Help**: `--help` shows accurate, complete information
- [ ] **Version**: `--version` shows correct version
- [ ] **Arguments**: All arguments validated with clear errors
- [ ] **Exit codes**: Meaningful (0=success, 1=error, 2=invalid args)

### User Experience

- [ ] **Error messages**: Human-readable, actionable
- [ ] **Progress**: Long operations show progress
- [ ] **Quiet mode**: `--quiet` or `-q` suppresses non-essential output
- [ ] **Verbose mode**: `--verbose` or `-v` shows debug info
- [ ] **Color**: Respects `NO_COLOR` environment variable
- [ ] **TTY detection**: Different output for pipe vs terminal

### Observability

- [ ] **Tracing**: OpenTelemetry spans for key phases
- [ ] **Events**: Decisions recorded as span events
- [ ] **Errors**: Errors recorded with span status
- [ ] **OTLP export**: `--otel` flag for collector endpoint

### Performance

- [ ] **Startup time**: Under 100ms for simple operations
- [ ] **Memory**: Bounded memory for large inputs (streaming)
- [ ] **Parallelism**: Multi-core utilization where applicable
- [ ] **Benchmarks**: Reproducible performance tests

### Reliability

- [ ] **Graceful shutdown**: Handles SIGINT/SIGTERM
- [ ] **Partial output**: No corrupt output on interrupt
- [ ] **Idempotent**: Safe to run multiple times
- [ ] **Atomic writes**: Temp file + rename pattern

### Configuration

- [ ] **Config file**: Optional config file support
- [ ] **Environment**: Environment variable support
- [ ] **Precedence**: CLI args > env vars > config file > defaults
- [ ] **Validation**: Config validated at startup

### Compatibility

- [ ] **Platforms**: Tested on target platforms (Linux, macOS, Windows)
- [ ] **Dependencies**: Runtime dependencies documented
- [ ] **Backwards compat**: Breaking changes documented

## Exit Code Convention

| Code | Meaning | Example |
|------|---------|---------|
| 0 | Success | Operation completed |
| 1 | General error | Unhandled exception |
| 2 | Invalid arguments | Missing required arg |
| 3 | IO error | File not found |
| 4 | Configuration error | Invalid config |
| 5 | Permission denied | Cannot write output |
| 6 | Network error | API unreachable |

## Error Message Format

```
error: [short description]

Cause: [detailed explanation]

Suggestion: [how to fix]

For more information, run with --verbose
```

Example:
```
error: Cannot read input file

Cause: File not found: /path/to/input.json

Suggestion: Check the file path or provide a different file with --input

For more information, run with --verbose
```

## Progress Output

For operations over 1 second:

```
Processing files...
[=====>                    ] 25% (25/100 files)
```

Or with items:
```
[1/10] Processing file1.txt
[2/10] Processing file2.txt
...
```

## Span Structure Template

```
cli_run (root span)
├── args_parse
├── config_load (if applicable)
├── input_enumerate
│   └── [per-directory or per-source spans]
├── input_read
│   └── [per-file spans]
├── process
│   └── [per-item spans with events]
├── report_generate
└── output_write
```

## Testing Checklist

### Unit Tests
- [ ] Argument parsing
- [ ] Input validation
- [ ] Core logic
- [ ] Error handling

### Integration Tests
- [ ] End-to-end with sample inputs
- [ ] Error scenarios
- [ ] Edge cases (empty input, large input)

### Performance Tests
- [ ] Baseline benchmarks
- [ ] Memory profiling
- [ ] Trace comparison

## Documentation

- [ ] README with quick start
- [ ] Installation instructions
- [ ] Command reference
- [ ] Configuration reference
- [ ] Examples for common use cases
- [ ] Troubleshooting guide

## Release

- [ ] Version bumped
- [ ] Changelog updated
- [ ] Tests passing
- [ ] Performance regression checked
- [ ] Binaries built for all platforms
