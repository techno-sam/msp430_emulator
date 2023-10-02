#!/bin/bash
echo "Building Rust..."
cargo build --release
echo "Building Flutter..."
flutter build windows --release
echo "Done"