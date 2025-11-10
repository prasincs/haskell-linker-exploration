# WebAssembly Interactive Demo

This directory contains an interactive web-based demonstration of the Haskell linker concepts using WebAssembly.

## Overview

With GHC 9.8+, Haskell can now compile to WebAssembly, allowing Haskell code to run directly in web browsers. This demo provides an interactive way to explore:

1. **Fibonacci Calculations**: See Haskell code execute in real-time in your browser
2. **Linker Visualization**: Interactive diagrams showing how GHC links Haskell programs
3. **Performance Comparison**: Compare FFI vs gRPC approaches with live benchmarks

## Features

- **Live Code Execution**: Run Haskell code compiled to WASM directly in the browser
- **Interactive Visualizations**: Explore GHC's compilation pipeline
- **Side-by-Side Comparison**: See naive linker attempts vs GHC's approach
- **Educational Tooltips**: Learn as you explore

## Prerequisites

To build the WASM demo, you need:

- GHC 9.8 or later (with WASM backend support)
- Node.js 18+ (for the web server)
- wasm32-wasi target support

## Building

### Install GHC with WASM support

```bash
# Using GHCup (recommended)
ghcup install ghc 9.8.1
ghcup set ghc 9.8.1

# Verify WASM support
ghc --info | grep wasm
```

### Build the demo

```bash
cd wasm-demo
./build.sh
```

This will:
1. Compile Haskell code to WASM
2. Generate JavaScript bindings
3. Build the web interface
4. Create a self-contained demo in `public/`

## Running

### Local development server

```bash
cd wasm-demo
npm install
npm run serve
```

Then open http://localhost:8080 in your browser.

### Static hosting

The `public/` directory contains a self-contained static site that can be hosted anywhere:

```bash
# Using Python
python3 -m http.server 8080 --directory public

# Using npx
npx serve public

# Or deploy to GitHub Pages, Netlify, Vercel, etc.
```

## What You'll See

### 1. Interactive Fibonacci Calculator

Try calculating Fibonacci numbers and see:
- The Haskell implementation running in WASM
- Execution time measurements
- Comparison with JavaScript implementation

### 2. Linker Visualization

Interactive flowchart showing:
- Source code → Object files
- Naive linker attempt (fails)
- GHC's linker orchestration (succeeds)
- All dependencies and libraries included

### 3. Runtime System Explorer

Explore the Haskell RTS components:
- Garbage Collector
- Scheduler
- Heap Manager
- FFI Bridge

Click on each component to learn more!

## Technical Details

### How It Works

1. **Haskell → WASM**: GHC compiles Haskell to WebAssembly
   ```bash
   ghc --make -optl-mexec-model=reactor \
       -o fibonacci.wasm Fibonacci.hs
   ```

2. **JavaScript Bindings**: Auto-generated glue code
   ```javascript
   import init, { fibonacci } from './fibonacci.js';
   await init();
   const result = fibonacci(10);
   ```

3. **Web Interface**: React/Vue-based interactive UI
   - Real-time code execution
   - Performance monitoring
   - Educational overlays

### Limitations

Current WASM backend limitations (as of GHC 9.8):
- No threading support (yet)
- Limited I/O operations
- Larger binary sizes than native
- Some RTS features unavailable

## Browser Compatibility

| Browser | Version | Status |
|---------|---------|--------|
| Chrome  | 91+     | ✅ Full support |
| Firefox | 89+     | ✅ Full support |
| Safari  | 15+     | ✅ Full support |
| Edge    | 91+     | ✅ Full support |

## Architecture

```
wasm-demo/
├── src/
│   ├── Fibonacci.hs          # Haskell source (compiled to WASM)
│   ├── Linker.hs             # Linker simulation
│   └── RTS.hs                # RTS explorer
├── public/
│   ├── index.html            # Main page
│   ├── js/
│   │   ├── app.js           # Main application
│   │   ├── visualizations.js # Interactive diagrams
│   │   └── wasm-loader.js   # WASM initialization
│   ├── css/
│   │   └── style.css        # Styling
│   └── wasm/
│       ├── fibonacci.wasm   # Compiled Haskell
│       └── *.js             # Generated bindings
├── build.sh                  # Build script
├── package.json             # Node dependencies
└── README.md                # This file
```

## Development

### Hot Reload

```bash
npm run dev
```

This watches for changes and automatically rebuilds.

### Adding New Features

1. **Add Haskell code**: Edit `src/*.hs`
2. **Rebuild WASM**: Run `./build.sh`
3. **Update UI**: Modify files in `public/`
4. **Test**: Open in browser and verify

### Debugging

Enable debug output:
```javascript
// In public/js/app.js
const DEBUG = true;
```

Check browser console for WASM-related messages.

## Future Enhancements

Planned features:
- [ ] Live Haskell code editor with WASM compilation
- [ ] Step-through debugger for linker process
- [ ] Performance profiling visualization
- [ ] Multi-threaded examples (when supported)
- [ ] Full RTS configuration explorer
- [ ] Comparison with other languages (Rust, C++)

## Resources

### GHC WASM Backend
- [GHC WASM Documentation](https://gitlab.haskell.org/ghc/ghc/-/wikis/javascript-backend)
- [WASM Backend Announcement](https://www.haskell.org/ghc/blog/20230914-wasm-backend.html)

### WebAssembly
- [WebAssembly Official Site](https://webassembly.org/)
- [MDN WASM Guide](https://developer.mozilla.org/en-US/docs/WebAssembly)

### Examples
- [Haskell WASM Examples](https://github.com/tweag/ghc-wasm-meta)

## Contributing

Contributions welcome! Areas of interest:
- Improved visualizations
- More interactive examples
- Better mobile support
- Accessibility enhancements

## License

MIT License - see main repository LICENSE file.
