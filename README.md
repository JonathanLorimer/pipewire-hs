# pipewire-hs

Haskell bindings for the [PipeWire](https://pipewire.org/) multimedia framework.

## Overview

`pipewire-hs` provides type-safe Haskell bindings to PipeWire, enabling Haskell applications to interact with PipeWire's audio/video processing capabilities and session management.

## Features

- Type-safe bindings to the PipeWire C API
- Memory-safe wrappers with proper resource management
- High-level idiomatic Haskell API
- Support for key PipeWire concepts:
  - Context and Core management
  - Main loop integration
  - Node, Port, and Link handling
  - Registry and object discovery

## Installation

### Prerequisites

- GHC 9.x or later
- PipeWire development headers
- libclang (for hs-bindgen)

### Building from Source

```bash
# Clone the repository
git clone https://github.com/username/pipewire-hs.git
cd pipewire-hs

# Generate bindings (requires hs-bindgen)
hs-bindgen --config bindings-config/bindings.yaml

# Build with cabal
cabal build
```

## Usage

See the [usage guide](docs/usage.md) for detailed examples.

Basic example:

```haskell
import PipeWire.Core
import PipeWire.Context
import PipeWire.Loop

main :: IO ()
main = do
  -- Initialize PipeWire
  initialize
  
  -- Create a main loop
  loop <- createMainLoop
  
  -- Create a context
  context <- createContext loop
  
  -- Connect to PipeWire
  core <- connect context "My-App" 
  
  -- Use PipeWire...
  
  -- Cleanup
  disconnect core
  destroyContext context
  destroyMainLoop loop
  deinitialize
```

## Examples

Check the [examples](examples/) directory for complete working examples.

## Documentation

- [API Documentation](docs/)
- [PipeWire Documentation](https://docs.pipewire.org/)

## License

[LICENSE]

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.