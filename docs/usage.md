# PipeWire-HS Usage Guide

This document provides examples and guidelines for using the PipeWire Haskell bindings.

## Basic Usage

### Initializing PipeWire

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

### Discovering Nodes

```haskell
import PipeWire.Registry
import PipeWire.Node

-- Example function to list all audio output nodes
listAudioOutputs :: Core -> IO [Node]
listAudioOutputs core = do
  registry <- getRegistry core
  nodes <- getNodesByMediaType registry "Audio"
  filterNodesByDirection nodes DirectionOutput
```

## Resource Management

All PipeWire objects are wrapped with proper resource management. The library uses `ForeignPtr` to ensure that resources are automatically cleaned up when they are no longer needed.

```haskell
withPipewire :: (Core -> IO a) -> IO a
withPipewire action = do
  initialize
  bracket
    (createMainLoop)
    destroyMainLoop
    (\loop -> bracket 
      (createContext loop)
      destroyContext
      (\context -> bracket
        (connect context "My-App")
        disconnect
        action))
```

## Event Handling

The library provides both synchronous and callback-based APIs:

```haskell
-- Register for node events
nodeEvents <- NodeEvents {
  nodeStateChanged = \state -> putStrLn $ "Node state changed: " ++ show state,
  nodeParamsChanged = \params -> putStrLn $ "Node params changed"
}

listenerId <- addNodeListener node nodeEvents

-- Later, to remove the listener
removeListener listenerId
```

## Error Handling

Functions that can fail return `Either Error a` where appropriate:

```haskell
result <- connectToServer context "My-App"
case result of
  Left err -> putStrLn $ "Failed to connect: " ++ show err
  Right core -> putStrLn "Connected successfully!"
```

## Thread Safety

The library provides thread-safe operations using STM:

```haskell
atomically $ do
  nodes <- readTVar nodesVar
  writeTVar nodesVar (node : nodes)
```

## Working with Properties

```haskell
-- Set properties when creating objects
props <- newProperties
setProperty props "media.class" "Audio/Sink"
node <- createNode context "my-sink" props

-- Get properties
mediaClass <- getProperty node "media.class" 
```