# Project Overview

A Haskell binding library for PipeWire, providing type-safe bindings to the PipeWire multimedia framework. This library enables Haskell applications to interact with PipeWire's audio/video processing capabilities and session management.

## Tech Stack

- **Language**: Haskell (GHC 9.x)
- **FFI**: Foreign Function Interface for C bindings
- **C Library**: PipeWire (libpipewire)
- **Build System**: Cabal or Stack
- **Key Libraries**:
  - `base`
  - `bytestring`
  - `containers`
  - `foreign` (for FFI)
  - `hs-bindgen` (for automatic binding generation)
- **Tools**: GHC, Cabal/Stack, pkg-config, PipeWire development headers, libclang

## Project Structure

```
pipewire-hs/
├── src/
│   └── PipeWire/
│       ├── Core.hs           # Core PipeWire types and functions
│       ├── Context.hs        # Context management
│       ├── Loop.hs           # Main loop handling
│       ├── Node.hs           # Node operations
│       ├── Port.hs           # Port management
│       ├── Link.hs           # Link operations
│       ├── Registry.hs       # Registry and object discovery
│       └── Raw/              # Generated raw bindings
│           ├── Core.hs       # Generated from pw_core.h
│           ├── Context.hs    # Generated from pw_context.h
│           └── ...
├── bindings-config/          # hs-bindgen configuration
│   ├── bindings.yaml         # Main binding configuration
│   └── custom-types.yaml     # Custom type mappings
├── cbits/                    # C helper functions (if needed)
├── test/                     # Test suite
├── examples/                 # Example applications
├── docs/                     # Documentation
├── pipewire-hs.cabal        # Cabal package file
└── README.md
```

## Development Guidelines

### Code Style
- Follow standard Haskell conventions (HLint-compatible)
- Use meaningful names for foreign imports and wrapper functions
- Document all foreign imports with their C counterparts
- Use newtype wrappers for C pointers and handles
- Prefer higher-level safe APIs over raw FFI exports

### FFI Guidelines
- Use hs-bindgen for automatic generation of raw bindings
- Configure type mappings in `bindings-config/` for PipeWire-specific types
- Always use safe FFI calls unless performance critical
- Wrap C resources with proper finalizers in high-level modules
- Let hs-bindgen handle basic marshalling, add safety wrappers on top
- Handle NULL pointers and error codes in the safe layer
- Document which functions are generated vs hand-written

### Testing
- Test FFI bindings with unit tests
- Include integration tests with actual PipeWire instances
- Test resource cleanup and memory management
- Run tests with valgrind to check for leaks

### Dependencies
- Minimize external dependencies
- Pin PipeWire version requirements
- Document system dependencies clearly

## Common Tasks

### Setup
```bash
# Generate bindings from PipeWire headers
hs-bindgen --config bindings-config/bindings.yaml

# Build the project
cabal build
```

### Development
```bash
# Start GHCi with the library loaded
cabal repl

# Run specific examples
cabal run example-name
```

### Testing
```bash
# Run all tests
cabal test
# or
stack test

# Run tests with PipeWire daemon
systemctl --user start pipewire
cabal test
```

### Binding Generation
```bash
# Regenerate all bindings
hs-bindgen --config bindings-config/bindings.yaml

# Generate specific module bindings
hs-bindgen --config bindings-config/bindings.yaml --module Core

# Check what headers are being processed
hs-bindgen --config bindings-config/bindings.yaml --dry-run

# Validate binding configuration
hs-bindgen --config bindings-config/bindings.yaml --validate
```

## Important Files

- `pipewire-hs.cabal` - Package configuration and dependencies
- `bindings-config/bindings.yaml` - hs-bindgen configuration
- `bindings-config/custom-types.yaml` - Custom type mappings
- `src/PipeWire/Raw/` - Generated raw bindings (don't edit manually)
- `cbits/helpers.c` - C helper functions (if needed)
- `examples/` - Working example applications

## Architecture Notes

The binding follows a layered approach:
- **Generated Layer**: Automatic bindings from hs-bindgen (Raw modules)
- **Safe Layer**: Memory-safe wrappers with proper resource management
- **High-Level Layer**: Idiomatic Haskell API with type safety

Key design decisions:
- Use hs-bindgen for automatic generation of low-level bindings
- Configure custom type mappings for PipeWire-specific types
- Use `ForeignPtr` for automatic cleanup of PipeWire objects
- Represent PipeWire enums as Haskell sum types in generated code
- Use `STM` for thread-safe state management where needed
- Provide both synchronous and callback-based APIs

## hs-bindgen Configuration

The `bindings-config/bindings.yaml` file controls:
- Which headers to process
- Type mappings for PipeWire types
- Function filtering and renaming
- Module organization
- Custom marshalling rules

## Coding Preferences

When working on this project:
- Let hs-bindgen handle the raw FFI layer automatically
- Focus on safe wrappers and high-level API design
- Configure type mappings rather than writing manual FFI code
- Use qualified imports for generated bindings (`import qualified PipeWire.Raw.Core as Raw`)
- Don't edit generated files - modify configuration instead
- Handle PipeWire errors explicitly in the safe layer
- Test binding regeneration regularly as PipeWire evolves

## Current Focus

What needs attention:
- [ ] Configure hs-bindgen for PipeWire headers
- [ ] Set up type mappings for PipeWire-specific types
- [ ] Generate and validate raw bindings
- [ ] Create safe wrappers for core functionality
- [ ] Memory management verification
- [ ] Documentation and examples
- [ ] Test binding regeneration workflow

## PipeWire-Specific Notes

### Key Concepts
- **Context**: Main PipeWire context object
- **Loop**: Event loop for async operations
- **Registry**: Object discovery and monitoring
- **Node**: Audio/video processing units
- **Port**: Connection points on nodes
- **Link**: Connections between ports

### Common Patterns
- Most PipeWire objects require a context
- Use registry listeners for object discovery
- Properties are key-value string maps
- Many operations are asynchronous with callbacks

## Resources

- [PipeWire Documentation](https://docs.pipewire.org/)
- [PipeWire C API Reference](https://docs.pipewire.org/group__api__pw__core.html)
- [hs-bindgen Documentation](https://hackage.haskell.org/package/hs-bindgen)
- [hs-bindgen Configuration Guide](https://github.com/well-typed/hs-bindgen)
- [Haskell FFI Documentation](https://wiki.haskell.org/Foreign_Function_Interface)
