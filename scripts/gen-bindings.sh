#!/usr/bin/env bash
set -euo pipefail

# This script discovers header files in the PipeWire development headers
# and generates Haskell bindings using hs-bindgen-cli.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
INCLUDES_DIR="$PROJECT_ROOT/.includes"
OUTPUT_DIR="$PROJECT_ROOT/src/PipeWire/Raw"

# Default values
DRY_RUN=0
SPECIFIC_FILE=""
VERBOSE=0
CLEAN=0

# Help message
show_help() {
  echo "Usage: $0 [options]"
  echo "Generate Haskell bindings for PipeWire headers"
  echo
  echo "Options:"
  echo "  -h, --help            Show this help message"
  echo "  -d, --dry-run         Show commands without executing them"
  echo "  -f, --file HEADER     Generate bindings for a specific header file"
  echo "  -v, --verbose         Show verbose output"
  echo "  -c, --clean           Clean generated files before generating"
  echo
  echo "Examples:"
  echo "  $0                    Generate all bindings"
  echo "  $0 --file core.h      Generate bindings only for core.h"
  echo "  $0 --dry-run          Show commands without executing"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    -d|--dry-run)
      DRY_RUN=1
      shift
      ;;
    -f|--file)
      SPECIFIC_FILE="$2"
      shift 2
      ;;
    -v|--verbose)
      VERBOSE=1
      shift
      ;;
    -c|--clean)
      CLEAN=1
      shift
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# Check if the local includes directory exists
if [[ ! -d "$INCLUDES_DIR" ]]; then
  echo "Error: Local includes directory not found at $INCLUDES_DIR"
  echo "Make sure you've run 'nix develop' to set up the environment"
  exit 1
fi

# Check if the symlinks are correctly set up
if [[ ! -L "$INCLUDES_DIR/pipewire" || ! -L "$INCLUDES_DIR/spa" ]]; then
  echo "Error: PipeWire or SPA symlinks not found in $INCLUDES_DIR"
  echo "Make sure you've run 'nix develop' to set up the environment"
  exit 1
fi

# Create output directory
if [[ $CLEAN -eq 1 ]]; then
  echo "Cleaning output directory: $OUTPUT_DIR"
  if [[ $DRY_RUN -eq 0 ]]; then
    rm -rf "$OUTPUT_DIR"
  fi
fi

if [[ $DRY_RUN -eq 0 ]]; then
  mkdir -p "$OUTPUT_DIR"
fi

# Get the actual paths the symlinks point to
PIPEWIRE_PATH=$(readlink -f "$INCLUDES_DIR/pipewire")
SPA_PATH=$(readlink -f "$INCLUDES_DIR/spa")

if [[ $VERBOSE -eq 1 ]]; then
  echo "PipeWire headers path: $PIPEWIRE_PATH"
  echo "SPA headers path: $SPA_PATH"
fi

# Include flags for hs-bindgen-cli
INCLUDE_ARGS="-I $INCLUDES_DIR"

# Function to convert a header file path to a module name
header_to_module() {
  local header_path=$1
  local file=$(basename "$header_path" .h)

  # Determine if this is a PipeWire or SPA header
  if [[ "$header_path" == pipewire/* ]]; then
    local dir="PipeWire"
  elif [[ "$header_path" == spa/* ]]; then
    local dir="Spa"
  else
    local dir=""
  fi

  # Capitalize first letter of file
  local file_part=$(echo "$file" | sed 's/^./\U&/;s/_\([a-z]\)/\U\1/g;s/-/_/g')

  # Special case handling
  if [[ "$file_part" == "Impl-"* ]]; then
    file_part="Impl.${file_part#Impl-}"
  fi

  # Combine into a module name
  if [[ -n "$dir" ]]; then
    echo "PipeWire.Raw.${dir}.${file_part}"
  else
    echo "PipeWire.Raw.${file_part}"
  fi
}

# Function to convert a module name to a file path
module_to_file() {
  local module=$1
  local path=${module//\./\/}
  echo "${PROJECT_ROOT}/src/${path}.hs"
}

# Function to ensure directory exists for a file
ensure_dir() {
  local file=$1
  local dir=$(dirname "$file")
  if [[ $DRY_RUN -eq 0 ]]; then
    mkdir -p "$dir"
  fi
}

# Function to generate binding for a header file
generate_binding() {
  local header=$1
  local module=$(header_to_module "$header")
  local output_file=$(module_to_file "$module")
  local full_path="$INCLUDES_DIR/$header"

  # Ensure output directory exists
  ensure_dir "$output_file"

  echo "Generating binding for $header -> $module"
  if [[ $VERBOSE -eq 1 ]]; then
    echo "Header: $full_path"
    echo "Module: $module"
    echo "Output: $output_file"
  fi

  # Build the command
  local cmd="hs-bindgen-cli preprocess -I "$GLIBC/include" $INCLUDE_ARGS -i $header -o $output_file --module $module"

  if [[ $VERBOSE -eq 1 ]]; then
    echo "Command: $cmd"
  fi

  if [[ $DRY_RUN -eq 0 ]]; then
    # Create the output directory if it doesn't exist
    mkdir -p "$(dirname "$output_file")"

    # Run the command
    (cd "$INCLUDES_DIR/.." && eval "$cmd") || echo "Warning: Error generating binding for $header"
  fi
}

# Function to collect header files
collect_headers() {
  local specific_file=$1
  local headers=()

  if [[ -n "$specific_file" ]]; then
    # Look for specific file in both pipewire and spa directories
    if [[ -f "$PIPEWIRE_PATH/$specific_file" ]]; then
      headers+=("pipewire/$specific_file")
    elif [[ -f "$SPA_PATH/$specific_file" ]]; then
      headers+=("spa/$specific_file")
    else
      echo "Error: Header file '$specific_file' not found"
      exit 1
    fi
  else
    # Find all PipeWire header files
    if [[ -d "$PIPEWIRE_PATH" ]]; then
      while IFS= read -r file; do
        local rel_file=${file#$PIPEWIRE_PATH/}
        headers+=("pipewire/$rel_file")
      done < <(find "$PIPEWIRE_PATH" -name "*.h" -type f | sort)
    fi

    # Find all SPA header files
    if [[ -d "$SPA_PATH" ]]; then
      while IFS= read -r file; do
        local rel_file=${file#$SPA_PATH/}
        headers+=("spa/$rel_file")
      done < <(find "$SPA_PATH" -name "*.h" -type f | sort)
    fi

    # Filter out problematic headers
    headers=($(printf "%s\n" "${headers[@]}" | grep -v "version" | sort))
  fi

  echo "${headers[@]}"
}

# Main function
main() {
  local all_headers=($(collect_headers "$SPECIFIC_FILE"))

  echo "Found ${#all_headers[@]} header files to process"

  # Define core headers to process first
  core_headers=(
    "pipewire/pipewire.h"
    "pipewire/core.h"
    "pipewire/context.h"
    "pipewire/loop.h"
  )

  # Process core headers first
  for core_header in "${core_headers[@]}"; do
    for header in "${all_headers[@]}"; do
      if [[ "$header" == "$core_header" ]]; then
        generate_binding "$header"
        break
      fi
    done
  done

  # Process remaining headers
  for header in "${all_headers[@]}"; do
    # Skip core headers already processed
    is_core=0
    for core_header in "${core_headers[@]}"; do
      if [[ "$header" == "$core_header" ]]; then
        is_core=1
        break
      fi
    done

    if [[ $is_core -eq 0 ]]; then
      generate_binding "$header"
    fi
  done

  echo "Binding generation complete!"
}

main
