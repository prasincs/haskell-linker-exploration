// Main application logic for the Haskell Linker Explorer WASM demo

// WASM module reference (will be initialized if available)
let wasmModule = null;
let wasmReady = false;

// Status updates
const statusElement = document.getElementById('wasm-status');

// Initialize the application
async function init() {
    console.log('Initializing Haskell Linker Explorer...');

    // Try to load WASM module (graceful fallback if not available)
    try {
        // In a full implementation, this would load the actual WASM module:
        // wasmModule = await import('../wasm/fibonacci.js');
        // await wasmModule.default();
        // wasmReady = true;

        // For now, show demo mode
        statusElement.innerHTML = '<span class="info">📊 Demo Mode - Using JavaScript fallback</span>';
        statusElement.className = 'status ready';

        console.log('Demo initialized successfully');
    } catch (error) {
        console.log('WASM not available, using JavaScript fallback:', error);
        statusElement.innerHTML = '<span class="info">⚠️ WASM not loaded - Using JavaScript fallback</span>';
        statusElement.className = 'status ready';
    }

    // Setup event listeners
    setupEventListeners();

    // Show initial visualizations
    updateVisualization();
}

// Setup all event listeners
function setupEventListeners() {
    // Fibonacci calculator
    document.getElementById('calc-button').addEventListener('click', calculateFibonacci);
    document.getElementById('fib-input').addEventListener('keypress', (e) => {
        if (e.key === 'Enter') calculateFibonacci();
    });

    // RTS component explorer
    document.querySelectorAll('.rts-component').forEach(component => {
        component.addEventListener('click', () => {
            showRTSDetails(component.dataset.component);
        });
    });

    // Benchmark runner
    document.getElementById('run-benchmark').addEventListener('click', runBenchmark);
}

// Fibonacci calculation
async function calculateFibonacci() {
    const input = document.getElementById('fib-input');
    const n = parseInt(input.value);

    if (isNaN(n) || n < 0 || n > 40) {
        alert('Please enter a number between 0 and 40');
        return;
    }

    const haskellResultEl = document.getElementById('haskell-result');
    const haskellTimeEl = document.getElementById('haskell-time');
    const jsResultEl = document.getElementById('js-result');
    const jsTimeEl = document.getElementById('js-time');
    const comparisonEl = document.getElementById('comparison');
    const comparisonTextEl = document.getElementById('comparison-text');

    // Calculate with Haskell/WASM (or JavaScript fallback)
    const haskellStart = performance.now();
    const haskellResult = wasmReady
        ? wasmModule.hs_fibonacci(n)
        : fibonacciJS(n);
    const haskellEnd = performance.now();
    const haskellTime = haskellEnd - haskellStart;

    // Calculate with pure JavaScript
    const jsStart = performance.now();
    const jsResult = fibonacciJS(n);
    const jsEnd = performance.now();
    const jsTime = jsEnd - jsStart;

    // Display results
    haskellResultEl.textContent = haskellResult.toLocaleString();
    haskellTimeEl.textContent = `${haskellTime.toFixed(3)} ms`;

    jsResultEl.textContent = jsResult.toLocaleString();
    jsTimeEl.textContent = `${jsTime.toFixed(3)} ms`;

    // Show comparison
    comparisonEl.style.display = 'block';
    if (wasmReady) {
        const speedup = (jsTime / haskellTime).toFixed(2);
        if (speedup > 1) {
            comparisonTextEl.textContent = `Haskell (WASM) is ${speedup}x faster!`;
        } else {
            comparisonTextEl.textContent = `JavaScript is ${(1/speedup).toFixed(2)}x faster`;
        }
    } else {
        comparisonTextEl.textContent = 'Using JavaScript fallback (WASM not loaded)';
    }
}

// JavaScript Fibonacci implementation (for comparison and fallback)
function fibonacciJS(n) {
    if (n <= 1) return n;

    // Iterative approach for better performance
    let a = 0, b = 1;
    for (let i = 2; i <= n; i++) {
        const temp = a + b;
        a = b;
        b = temp;
    }
    return b;
}

// RTS Component details
const rtsDetails = {
    gc: {
        title: 'Garbage Collector',
        content: `
            <p>The Haskell Runtime System includes a sophisticated garbage collector:</p>
            <ul>
                <li><strong>Generational GC</strong>: Separates young and old objects for efficiency</li>
                <li><strong>Parallel Collection</strong>: Can use multiple cores for GC</li>
                <li><strong>Incremental</strong>: Minimizes pause times</li>
                <li><strong>Compacting</strong>: Reduces memory fragmentation</li>
            </ul>
            <p>This is why Haskell programs need libHSrts.a - it contains ~2MB of GC code!</p>
        `
    },
    scheduler: {
        title: 'Scheduler',
        content: `
            <p>The scheduler manages Haskell's lightweight threads:</p>
            <ul>
                <li><strong>M:N Threading</strong>: Many Haskell threads on few OS threads</li>
                <li><strong>Work Stealing</strong>: Automatically balances load across cores</li>
                <li><strong>Millions of Threads</strong>: Can handle millions of concurrent threads</li>
                <li><strong>Fairness</strong>: Ensures all threads get CPU time</li>
            </ul>
            <p>Much more sophisticated than what a simple linker would provide!</p>
        `
    },
    heap: {
        title: 'Heap Manager',
        content: `
            <p>The heap manager enables Haskell's lazy evaluation:</p>
            <ul>
                <li><strong>Thunks</strong>: Unevaluated expressions stored on the heap</li>
                <li><strong>Lazy Evaluation</strong>: Compute values only when needed</li>
                <li><strong>Sharing</strong>: Evaluate each thunk only once</li>
                <li><strong>Infinite Data</strong>: Can represent infinite lists efficiently</li>
            </ul>
            <p>This is unique to Haskell and requires special RTS support!</p>
        `
    },
    ffi: {
        title: 'FFI Bridge',
        content: `
            <p>The Foreign Function Interface allows calling C code:</p>
            <ul>
                <li><strong>Safe Calls</strong>: Properly handle GC during foreign calls</li>
                <li><strong>Unsafe Calls</strong>: Zero-overhead for simple C functions</li>
                <li><strong>Memory Management</strong>: Coordinate between Haskell GC and C malloc</li>
                <li><strong>Callbacks</strong>: Allow C to call back into Haskell</li>
            </ul>
            <p>Remember: even with FFI, you need GHC to link everything together!</p>
        `
    }
};

function showRTSDetails(component) {
    const detailsEl = document.getElementById('rts-details');
    const titleEl = document.getElementById('detail-title');
    const contentEl = document.getElementById('detail-content');

    const details = rtsDetails[component];
    titleEl.textContent = details.title;
    contentEl.innerHTML = details.content;

    detailsEl.style.display = 'block';
    detailsEl.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
}

// Benchmark suite
async function runBenchmark() {
    const button = document.getElementById('run-benchmark');
    const progress = document.getElementById('benchmark-progress');
    const results = document.getElementById('benchmark-results');
    const table = document.getElementById('benchmark-table');

    button.disabled = true;
    progress.style.display = 'block';
    results.style.display = 'none';
    table.innerHTML = '';

    const tests = [
        { name: 'fib(10)', n: 10 },
        { name: 'fib(20)', n: 20 },
        { name: 'fib(30)', n: 30 },
        { name: 'fib(35)', n: 35 }
    ];

    const iterations = 10;
    const benchResults = [];

    for (let i = 0; i < tests.length; i++) {
        const test = tests[i];
        const progressPercent = ((i + 1) / tests.length) * 100;
        progress.querySelector('.progress-fill').style.width = progressPercent + '%';

        // Benchmark Haskell/WASM
        const haskellTimes = [];
        for (let j = 0; j < iterations; j++) {
            const start = performance.now();
            const result = wasmReady ? wasmModule.hs_fibonacci(test.n) : fibonacciJS(test.n);
            const end = performance.now();
            haskellTimes.push(end - start);
        }

        // Benchmark JavaScript
        const jsTimes = [];
        for (let j = 0; j < iterations; j++) {
            const start = performance.now();
            const result = fibonacciJS(test.n);
            const end = performance.now();
            jsTimes.push(end - start);
        }

        const haskellAvg = haskellTimes.reduce((a, b) => a + b) / iterations;
        const jsAvg = jsTimes.reduce((a, b) => a + b) / iterations;
        const speedup = jsAvg / haskellAvg;

        benchResults.push({
            name: test.name,
            haskell: haskellAvg,
            js: jsAvg,
            speedup: speedup
        });

        // Small delay to show progress
        await new Promise(resolve => setTimeout(resolve, 100));
    }

    // Display results
    benchResults.forEach(result => {
        const row = table.insertRow();
        row.insertCell(0).textContent = result.name;
        row.insertCell(1).textContent = result.haskell.toFixed(3) + ' ms';
        row.insertCell(2).textContent = result.js.toFixed(3) + ' ms';

        const speedupCell = row.insertCell(3);
        speedupCell.textContent = result.speedup.toFixed(2) + 'x';
        speedupCell.style.color = result.speedup > 1 ? 'green' : 'red';
    });

    progress.style.display = 'none';
    results.style.display = 'block';
    button.disabled = false;
}

// Update visualization
function updateVisualization() {
    // Any dynamic visualization updates would go here
    console.log('Visualizations updated');
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}

// Export for debugging
window.HaskellLinkerExplorer = {
    calculateFibonacci,
    runBenchmark,
    wasmReady: () => wasmReady
};
