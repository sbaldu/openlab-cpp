---
marp: true
theme: gaia
paginate: true
math: mathjax
header: '![](assets/logo_cern.png) ![](assets/logo_infn.png) ![](assets/logo_unibo.png)'
---

<style>
/* pull slide titles to the top */
section {
  justify-content: flex-start !important;
  padding-top: 0.6rem !important;
  font-size: 28px;
  background: #ffffff !important;
  background-image: none !important;
  color: #1a1a2e;
}

h1, h2 {
  color: #1a237e;
}

h2 {
  margin-top: 0 !important;
  margin-bottom: 0.4em !important;
}

/* code blocks */
pre {
  background: #f0f4f8 !important;
  background-image: none !important;
  border: 1px solid #cdd5e0;
  border-radius: 6px;
}

pre code {
  background: #f0f4f8 !important;
  background-image: none !important;
  color: #1a1a2e !important;
}

code {
  background: #e8edf2 !important;
  background-image: none !important;
  color: #1a1a2e !important;
  border-radius: 3px;
}

/* highlighted / blockquote blocks */
blockquote {
  background: #fff8e1;
  border-left: 4px solid #f9a825;
  border-radius: 0 6px 6px 0;
  padding: 0.4em 0.8em;
  color: #4a3800;
}

/* Title slide */
section.title-slide {
  background: #0033A0 !important;
  background-image: none !important;
  color: white !important;
  justify-content: center !important;
  font-size: 42px !important;
}

section.title-slide h1 {
  color: white !important;
  font-size: 1.8em !important;
}

section.title-slide footer {
  position: absolute !important;
  bottom: 1rem !important;
  right: 1rem !important;
  left: auto !important;
  display: flex !important;
  gap: 1rem;
  align-items: center;
  background: transparent;
}

section.title-slide footer img {
  height: 1.8cm;
  width: auto;
  filter: brightness(0) invert(1);
}

/* header logos — top-right */
header {
  position: absolute;
  top: 0.5rem;
  right: 1rem;
  left: auto;
  display: flex;
  gap: 0.5rem;
  align-items: center;
  padding: 0;
  background: transparent;
}
header img {
  height: 0.8cm;
  width: auto;
}
</style>

<!-- _class: title-slide -->
<!-- _header: '' -->
<!-- _footer: '![](assets/logo_cern.png) ![](assets/logo_infn.png) ![](assets/logo_unibo.png)' -->
<!-- _paginate: false -->

# Introduction to Parallel Computing and GPU programming with CUDA

Simone Balducci, **Felice Pantaleo,** Aurora Perego
CERN Experimental Physics Department

---

## Content of the theoretical session

- Introduction to Parallel computing
- Heterogeneous Parallel computing systems
- CUDA Basics
- Parallel kernels
- Shared Memory and Synchronization
- Device Management
- Thrust library
- CUB library
- CuPy

---

## Content of the tutorial session

- Write and launch kernels
- Manage GPU memory
- Manage communication and synchronization
- From C++ standard algorithms to GPU execution using thrust

---

## Past systems

- Computing landscape is very different from 10-20 years ago
- Every component and its interfaces are being re-examined

<!-- image placeholder: Microprocessor, Main Memory, Storage (SSD/HDD) -->

---

## Modern systems

- Applications and technology demand novel architectures
  - Driven by huge hunger for data (Big Data), new applications (ML/AI, graph analytics, genomics), ever-greater realism
  - We can easily collect more data than we can analyze/understand
  - Five walls: Energy, reliability, complexity, security, scalability

<!-- image placeholder: FPGA, Heterogeneous Processors and Accelerators, Hybrid Memory, GPU, Persistent memory/Storage -->

---

## Accelerators

- Exceptional raw power and memory bandwidth wrt CPUs

- Lower energy to solution

- Massively parallel architecture

- Low Memory/core

<!-- image placeholder: NVIDIA GPU chip photo -->

---

## Accelerators

GPUs were traditionally used for real-time rendering/gaming.

AMD and NVIDIA main manufacturers for discrete GPUs, Intel for integrated ones

![](images/amd-logo.png) <!-- image placeholder: intel-logo --> ![](images/nvidia-logo.png)

---

## CPU vs GPU architectures

<!-- image placeholder: CPU architecture diagram (Control, ALU/Cache, Cache, DRAM) and GPU architecture diagram (many cores, DRAM), with CPU and GPU photos -->

---

## CPU vs GPU architectures

<!-- image placeholder: CPU architecture diagram (Control, ALU/Cache, Cache, DRAM) -->

- Large caches (slow memory accesses to quick cache accesses)

- SIMD

- Branch prediction/speculative

- Powerful ALU

- Pipelining

---

## Memory access patterns: cached

For optimal CPU cache utilization, the thread *a* should process element *i* and *i+1*

<!-- image placeholder: CPU architecture diagram with CPU Thread 0, CPU Thread 1, CPU Thread 2, CPU Thread 3 accessing array elements -->

---

## CPU vs GPU architectures

- Hundreds of "cores" (e.g. streaming multiprocessors, Xe cores, compute units)
- SIMT (Single-Instruction, Multiple-Thread) with hundreds of SIMD-like warps in fly
- Instructions pipelined
- Thread-level parallelism
- Instructions issued in order
- Branch predication

<!-- image placeholder: GPU architecture diagram (many cores, DRAM) and GPU photo -->

---

## Inside a GPU SM: coalesced

- L1 data cache shared among ALUs
- ALUs work in SIMD mode in groups called warps
  - Think about it as vectors on the same CPU core
- If a *load* is issued by each thread, they have to wait for all the loads in the same warp to complete before the next instruction can execute
- Coalesced memory access pattern optimal for GPUs: thread *a* should process element *i*, thread *a+1* the element and *i+1*
  - Lose an order of magnitude in performance if cached access pattern used on GPU

<!-- image placeholder: SM internal diagram, memory access coalescing diagram -->

---

## Warps

- Once a block is assigned to an SM, it is divided into units called warps.
- Thread IDs within a warp are consecutive and increasing
- Threads within a warp are executed in a SIMD fashion
- If an operand is not ready the warp will stall
- Context switch between warps when stalled
- Context switch must be very fast
- Typical values of warp size 16, 32, 64 depending on vendor

<!-- image placeholder: warp execution diagram showing active/stalled warps -->

---

<!-- _header: '' -->

## Heterogeneous Parallel Computing Systems

---

## Heterogeneous Computing

- Terminology
  - Host &nbsp;&nbsp;&nbsp; The CPU and its memory space
  - Device &nbsp; The GPU and its memory space

<!-- image placeholder: Host (CPU + RAM photo), Device (GPU card photo) -->

---

## Simple Processing Flow

<!-- image placeholder: CPU block (CPU, Bridge, CPU Memory) ↔ GPU block (GigaThread, SMs, Interconnect, L2, DRAM) -->

---

## Simple Processing Flow

1. Copy input data from CPU memory to GPU memory

<!-- image placeholder: CPU-GPU diagram with arrow showing data transfer from CPU Memory to GPU DRAM -->

---

## Simple Processing Flow

1. Copy input data from CPU memory to GPU memory
2. Load GPU program and execute, caching data on chip for performance

<!-- image placeholder: CPU-GPU diagram with arrows showing compute within GPU SMs -->

---

## Simple Processing Flow

1. Copy input data from CPU memory to GPU memory
2. Load GPU program and execute, caching data on chip for performance
3. Copy results from GPU memory to CPU memory

<!-- image placeholder: CPU-GPU diagram with arrow showing results transfer from GPU DRAM to CPU Memory -->

---

<!-- _header: '' -->

## Basics

---

## CUDA

- Small set of extensions to enable asynchronous heterogeneous computing using NVIDIA GPUs
- Straightforward APIs to manage devices, memory etc.
- Concepts learned in CUDA apply to other parallel frameworks (OpenMP, SYCL, HIP, alpaka).
- Learning Curve
  - Initial effort focuses on understanding new APIs and language constructs.
  - Core programming logic often remains unchanged.

---

## SPMD Phases

- Initialize
  - Establish localized data structure and communication channels
- Obtain a unique identifier
  - Each thread acquires a unique identifier, typically range from 0 to N-1, where N is the number of threads
- Distribute Data
  - Decompose global data into chunks and localize them, or
  - Sharing/replicating major data structure using thread ID to associate subset of the data to threads
- Run the core computation
- Finalize
  - Reconcile global data structure, prepare for the next major iteration

---

## Memory Hierarchy in GPU programming

- Registers/Shared memory:
  - Fast
  - Only accessible by the thread/block
  - Lifetime of the thread/block
- Global memory:
  - Potentially 150x slower than register or shared memory
  - Accessible from either the host or device
  - Lifetime of the application

<!-- image placeholder: Thread → per-thread local memory, Thread Block → per-block shared memory, Grid → Global memory hierarchy diagram -->

---

## Hello World!

```cpp
#include <iostream>

int main() {
    std::cout << "Hello World!\n";
}
```

Standard C++ that runs on the host
nvcc can be used to compile programs with no *device* code

```
Output:
$ nvcc hello_world.cu
$ ./a.out
Hello World!
$
```

---

## Hello World! with Device Code

```cpp
#include <iostream>

__global__ void mykernel() {}

int main() {
    cudaStream_t stream; cudaStreamCreate(&stream);
    mykernel<<<1,1,0,stream>>>();
    std::cout << "Hello World!\n";
    cudaStreamSynchronize(stream);
    cudaStreamDestroy(stream);
}
```

---

## Hello World! with Device Code

`__global__ void mykernel() {}`

- CUDA keyword `__global__` indicates a function that:
  - Runs on the device
  - Is called from host code

- `nvcc` separates source code into host and device components
  - Device functions (e.g. `mykernel()`) processed by nvcc compiler
  - Host functions (e.g. `main()`) processed by `gcc`

---

## Hello World! with Device Code

`mykernel<<<1,1,0,stream>>>();`

- Triple angle brackets mark a call from host code to device code
  - Also called a "kernel launch"
  - We'll return to the parameters in a moment

- That's all that is required to execute a function on the GPU!

---

<!-- _header: '' -->

## Parallel constructs in CUDA

---

## Addition on the Device

- A simple kernel to add two integers

```cpp
__global__ void add(const int *a, const int *b, int *c) {
    *c = *a + *b;
}
```

- As before `__global__` is a CUDA keyword meaning
  - `add()` will execute on the device
  - `add()` will be called from the host

---

## Addition on the Device

- Note that we use pointers for the variables

```cpp
__global__ void add(const int *a, const int *b, int *c) {
    *c = *a + *b;
}
```

- `add()` runs on the device, so `a`, `b` and `c` must point to device memory

- We need to allocate memory on the GPU

---

## Memory Management

- Host and device memory are separate entities
  - Device pointers point to GPU memory
    - May be passed to/from host code
    - May not be dereferenced in host code
  - Host pointers point to CPU memory
    - May be passed to/from device code
    - May not be dereferenced in device code
- Simple CUDA API for handling device memory
  - `cudaMalloc()`, `cudaFree()`, `cudaMemcpy()`
  - Similar to `malloc()`, `free()`, `memcpy()`

<!-- image placeholder: GPU card photo, RAM photo -->

---

## Addition on the Device: add()

- Returning to our `add()` kernel

```cpp
__global__ void add(const int *a, const int *b, int *c) {
    *c = *a + *b;
}
```

- Let's take a look at `main()` ...

---

```cpp
int main() {
    cudaStream_t stream;
    cudaStreamCreate(&stream);
    int *a, *b, *c;          // host copies of a, b, c
    int *d_a, *d_b, *d_c;   // device copies of a, b, c
    int size = sizeof(int);
    // Allocate space for device copies of a, b, c
    cudaMallocHost(&a,size);
    cudaMallocHost(&b,size);
    cudaMallocHost(&c,size);
    *a = 2; *b = 7;
    // Allocate memory on device
    cudaMallocAsync(&d_a, size, stream);
    cudaMallocAsync(&d_b, size, stream);
    cudaMallocAsync(&d_c, size, stream);
    // Copy inputs to device
    cudaMemcpyAsync(d_a, a, size, cudaMemcpyHostToDevice, stream);
    cudaMemcpyAsync(d_b, b, size, cudaMemcpyHostToDevice, stream);
    // Launch add() kernel on GPU
    add<<<1,1,0,stream>>>(d_a, d_b, d_c);
    // Copy result back to host
    cudaMemcpyAsync(c, d_c, size, cudaMemcpyDeviceToHost, stream);
    cudaFreeAsync(d_a,stream);
    cudaFreeAsync(d_b,stream);
    cudaFreeAsync(d_c,stream);
    // Synchronize to be able to use c
    cudaStreamSynchronize(stream);
    cudaStreamDestroy(stream);
    cudaFreeHost(a); cudaFreeHost(b); cudaFreeHost(c);
}
```

A stream is a queue of operations to be executed on the device

---

## Coordinating Host & Device

- Kernel launches are asynchronous
  - control is returned to the host thread before the device has completed the requested task
  - CPU needs to synchronize before consuming the results

| | |
|---|---|
| **`cudaMemcpy()`, `cudaMalloc()`** | Blocks the CPU thread until the copy/allocation is complete. Copy/allocation begins when all preceding CUDA calls have completed |
| **`cudaMemcpyAsync()`, `cudaMallocAsync()`** | Asynchronous, does not block the CPU thread |
| **`cudaDeviceSynchronize()`** | Blocks the CPU thread until all preceding CUDA calls have completed |
| **`cudaStreamSynchronize(stream)`** | Blocks the CPU thread until all preceding CUDA calls in the stream have completed |

---

## Moving to Parallel

- GPU computing is about massive parallelism
  - So how do we run code in parallel on the device?

```
add<<< 1, 1, 0, stream >>>();
```

↓

```
add<<< N, 1, 0, stream >>>();
```

- Instead of executing `add()` once, execute N times in parallel

---

## Vector Addition on the Device

- With `add()` running in parallel we can do vector addition
- Terminology: each parallel invocation of `add()` is referred to as a block
  - The set of blocks is referred to as a grid
  - Each invocation can refer to its block index using `blockIdx.x`

```cpp
__global__ void add(const int *a, const int *b, int *c)
{
    c[blockIdx.x] = a[blockIdx.x] + b[blockIdx.x];
}
```

- By using `blockIdx.x` to index into the array, each block handles a different index

---

## Remember SPMD?

```cpp
__global__ void add(const int *a, const int *b, int *c)
{
    c[blockIdx.x] = a[blockIdx.x] + b[blockIdx.x];
}
```

- On the device, each block can execute in parallel:

<!-- image placeholder: Block 0: c[0]=a[0]+b[0], Block 1: c[1]=a[1]+b[1], Block 2: c[2]=a[2]+b[2], Block 3: c[3]=a[3]+b[3] -->

---

## Vector Addition on the Device: add()

- Returning to our parallelized `add()` kernel

```cpp
__global__ void add(const int *a, const int *b, int *c)
{
    c[blockIdx.x] = a[blockIdx.x] + b[blockIdx.x];
}
```

- Let's take a look at `main()` ...

---

```cpp
int main() {
    cudaStream_t stream; cudaStreamCreate(&stream);
    int N = 512;
    std::vector<int> a, b, c;
    a.resize(N); b.resize(N); c.resize(N);
    int *d_a, *d_b, *d_c; // device copies of a, b, c
    int size = N * sizeof(int);
    // Alloc space for host copies of a, b, c and
    // setup input values
    my_favorite_random_ints(a, N);
    my_favorite_random_ints(b, N);
    // Alloc memory for device copies of a, b, c
    cudaMallocAsync(&d_a, size, stream);
    cudaMallocAsync(&d_b, size, stream);
    cudaMallocAsync(&d_c, size, stream);
    // Copy inputs to device
    cudaMemcpyAsync(d_a, a.data(), size, cudaMemcpyHostToDevice, stream);
    cudaMemcpyAsync(d_b, b.data(), size, cudaMemcpyHostToDevice, stream);
    // Launch add() kernel on GPU with N blocks
    add<<<N, 1, 0, stream>>>(d_a, d_b, d_c);
    // Copy result back to host
    cudaMemcpyAsync(c.data(), d_c, size, cudaMemcpyDeviceToHost, stream);
    // Cleanup
    cudaFreeAsync(d_a,stream);
    cudaFreeAsync(d_b,stream);
    cudaFreeAsync(d_c,stream);
    cudaStreamSynchronize(stream);
    // Now you can use content of the c vector…
    cudaStreamDestroy(stream);
}
```

---

## CUDA Threads

- Terminology: a block can be split into parallel threads
- Let's change add() to use parallel threads instead of parallel blocks

```cpp
__global__ void add(const int *a, const int *b, int *c) {
    c[threadIdx.x] = a[threadIdx.x] + b[threadIdx.x];
}
```

- We use `threadIdx.x` instead of `blockIdx.x`
- Need to make one change in `main()`…

---

## Combining Blocks and Threads

- We've seen parallel vector addition using:
  - Many blocks with one thread each
  - One block with many threads

Let's adapt vector addition to use both blocks and threads

Why? We'll come to that...
First let's discuss data indexing...

---

## Indexing Arrays with Blocks and Threads

- No longer as simple as using `blockIdx.x` and `threadIdx.x`
  - Consider indexing an array with one element per thread (8 threads/block)

<!-- image placeholder: array indexed by threadIdx.x 0-7 for each of blockIdx.x = 0, 1, 2, 3 -->

With `blockDim.x` threads/block a unique index for each thread is given by:
`auto index = threadIdx.x + blockIdx.x * blockDim.x;`

---

## Vector Addition with Blocks and Threads

- Use the built-in variable `blockDim.x` for threads per block
  `auto index = threadIdx.x + blockIdx.x * blockDim.x;`
- Combined version of add() to use parallel threads *and* parallel blocks

```cpp
__global__ void add(const int *a, const int *b, int *c) {
    auto index = threadIdx.x + blockIdx.x * blockDim.x;
    c[index] = a[index] + b[index];
}
```

What changes need to be made in `main()`?

---

```cpp
int main() {
    cudaStream_t stream; cudaStreamCreate(&stream);
    int N = 2048*2048;
    int threads_per_block = 512;
    std::vector<int> a, b, c;
    a.resize(N); b.resize(N); c.resize(N);
    int *d_a, *d_b, *d_c; // device copies of a, b, c
    int size = N * sizeof(int);
    // Alloc space for host copies of a, b, c and
    // setup input values
    my_favorite_random_ints(a, N);
    my_favorite_random_ints(b, N);
    // Alloc memory for device copies of a, b, c
    cudaMallocAsync(&d_a, size, stream);
    cudaMallocAsync(&d_b, size, stream);
    cudaMallocAsync(&d_c, size, stream);
    // Copy inputs to device
    cudaMemcpyAsync(d_a, a.data(), size, cudaMemcpyHostToDevice, stream);
    cudaMemcpyAsync(d_b, b.data(), size, cudaMemcpyHostToDevice, stream);
    // Launch add() kernel on GPU with N blocks
    add<<<N/threads_per_block, threads_per_block, 0, stream>>>(d_a, d_b, d_c);
    // Copy result back to host
    cudaMemcpyAsync(c.data(), d_c, size, cudaMemcpyDeviceToHost, stream);
    // Cleanup
    cudaFreeAsync(d_a,stream); cudaFreeAsync(d_b,stream);cudaFreeAsync(d_c,stream);
    cudaStreamSynchronize(stream);
    // Now you can use content of the c vector…
    cudaStreamDestroy(stream);
}
```

---

## Handling Arbitrary Vector Sizes

- Typical problems are not friendly multiples of `blockDim.x`

- Avoid accessing beyond the end of the arrays:

```cpp
__global__ void add(const int *a, const int *b, int *c, int n) {
    auto index = threadIdx.x + blockIdx.x * blockDim.x;
    if (index < n)
        c[index] = a[index] + b[index];
}
```

Update the kernel launch:
`add<<<std::ceil((float)n / nThPerBlock), nThPerBlock>>>(d_a, d_b, d_c, n);`

---

<!-- _header: '' -->

Time for the first three exercises!
https://infn-esc.github.io/esc25/gpu/cuda.html

---

<!-- _header: '' -->

## Shared Memory
## with CUDA

---

## Why Bother with Threads?

- Threads seem unnecessary
  - They add a level of complexity
  - What do we gain?

- Unlike parallel blocks, threads have mechanisms to:
  - Communicate
  - Synchronize

- To understand the gain, we need a new example…

---

## 1D Stencil

- Consider applying a 1D stencil sum to a 1D array of elements
  - Each output element is the sum of input elements within a radius
  - Example of stencil with radius 2:

<!-- image placeholder: input array [5,2,1,9,2,3,6,1] → output array [8,17,19,17,21,21,12,10] -->

---

## Sharing Data Between Threads

- Terminology: within a block, threads share data via shared memory

- Extremely fast on-chip memory, user-managed

- Declare using `__shared__`, allocated per block

- Data is not visible to threads in other blocks

---

## Implementing With Shared Memory

Cache data in shared memory

- Read `(blockDim.x + 2 * radius)` input elements from global memory to shared memory
- Compute `blockDim.x` output elements
- Write `blockDim.x` output elements to global memory
- Each block needs a halo of radius elements at each boundary

<!-- image placeholder: halo diagram with "halo on left", "blockDim.x output elements", "halo on right" -->

---

## Stencil Kernel

```cpp
__global__ void stencil_1d(const int *in, int *out, int n) {
    __shared__ int temp[BLOCK_SIZE + 2 * RADIUS];
    auto g_index = threadIdx.x + blockIdx.x * blockDim.x;
    if (g_index < n) {
        auto s_index = threadIdx.x + RADIUS;

        // Read input elements into shared memory
        temp[s_index] = in[g_index];
        if (threadIdx.x < RADIUS) {
            temp[s_index - RADIUS] = g_index - RADIUS < 0 ? 0 :
                                     in[g_index - RADIUS];
            temp[s_index + BLOCK_SIZE] = g_index + BLOCK_SIZE < n ?
                                         in[g_index + BLOCK_SIZE] : 0;
        }

        // Apply the stencil
        int result = 0;
        for (int offset = -RADIUS ; offset <= RADIUS ; offset++)
            result += temp[s_index + offset];

        // Store the result
        out[g_index] = result;
    }
}
```

<!-- image placeholder: shared memory block cube diagrams -->

---

## Race condition

- The stencil example will not work...
- A race condition occurs when multiple tasks read from and write to the same memory without proper synchronization.
- The "race" may finish correctly sometimes and therefore complete without errors, and at other times it may finish incorrectly.
- If a data race occurs, the behavior of the program is undefined.

---

## `__syncthreads()`

`void __syncthreads();`

Synchronizes all threads within a block
- Ensuring correct execution order when threads share data.
- Used to prevent race conditions

All threads must reach the barrier
- In conditional code, the condition must be uniform across the block

---

## Stencil Kernel, fixed

```cpp
__global__ void stencil_1d(const int *in, int *out, int n) {
    __shared__ int temp[BLOCK_SIZE + 2 * RADIUS];
    auto g_index = threadIdx.x + blockIdx.x * blockDim.x;
    if (g_index < n) {
        auto s_index = threadIdx.x + RADIUS;

        // Read input elements into shared memory
        temp[s_index] = in[g_index];
        if (threadIdx.x < RADIUS) {
            temp[s_index - RADIUS] = g_index - RADIUS < 0? 0 :
                                     in[g_index - RADIUS];
            temp[s_index + BLOCK_SIZE] = g_index + BLOCK_SIZE < n ?
                                         in[g_index + BLOCK_SIZE] : 0;
        }
        __syncthreads();

        // Apply the stencil
        int result = 0;
        for (int offset = -RADIUS ; offset <= RADIUS ; offset++)
            result += temp[s_index + offset];

        // Store the result
        out[g_index] = result;
    }
}
```

<!-- image placeholder: shared memory block cube diagrams with __syncthreads() barrier highlighted -->

---

## Atomic operations

- When we need to modify a variable that is shared among many threads we use atomic operations
- All atomics take as input the address of the shared variable and the value needed for the operation
  - Ex. `atomicAdd(&data, increment)`
- Atomics grant access to the shared variable to only one thread at a time
  - Hence the name, they are indivisible
- There are many different atomic operations
  - `atomicInc`, `atomicDec`, `atomicMax`, `atomicMin`, `atomicAdd`, …
- If we want block-level synchronization, we call the atomic with the _block suffix
  - Ex. `atomicAdd_block`

---

## Review

Launching parallel threads

- Launch N blocks with M threads per block with `kernel<<<N,M,0,stream>>>(…);`
- Use `blockIdx.x` to access block index within grid
- Use `threadIdx.x` to access thread index within block

Allocate elements to threads:
`auto index = threadIdx.x + blockIdx.x * blockDim.x;`

Use `__shared__` to declare a variable/array in shared memory
- Data is shared between threads in a block
- Not visible to threads in other blocks

- Use `__syncthreads()` as a barrier to prevent data hazards

---

<!-- _header: '' -->

## The thrust/roc-thrust
## libraries

---

## C++ standard algorithms

- In C++ it's very common that sequences of operations can be expressed using predefined algorithms
- The STL provides a large number of standard algorithms for this purpose
- They should (almost) always be preferred to manual for-loops
  - They are well tested and granted to work as expected
  - They are very efficient
  - They convey very well what the code is doing
- It makes sense to provide an easy way to parallelize such algorithms without writing the kernels manually

---

## Introduction to the thrust/roc-thrust libraries

- The Thrust libraries provide a C++ STL-like interface to device code
- They implements the concept of device-iterators, pointers and algorithms
- Provide host and device data structures that hide CUDA or HIP API calls behind an easy and intuitive interface
- They are both open source and there's no need to change your code when moving between the two [1][2]

- Thrust algorithms follow the same interface as the STL algorithms
  - Ex. `for_each`, `transform`, `copy`, `sort`, `find`, `min/max/minmax_element`, `reduce`, `sequence` (equivalent to `std::iota`), …
- Introduce the concept of *fancy iterators*, that make many operations easier and often avoid the need for temporary buffers

[1] https://github.com/NVIDIA/cccl/tree/main/thrust
[2] https://github.com/ROCm/rocm-libraries/tree/develop/projects/rocthrust

---

## Example: transforming a container

- Suppose we have a vector containing temperature measurements in Fahrenheit
- We want to convert them in celsius in another vector

```cpp
#include <algorithm>
#include <vector>

int main() {
    std::vector<float> f_temperatures;
    // generate data inside the f_temperatures
    std::vector<float> c_temperatures(f_temperatures.size());
    auto to_celsius = [] (float tf) { return (tf - 32.f) / 1.8f; };
    std::transform(f_temperatures.begin(),
                   f_temperatures.end(),
                   c_temperatures.begin(),
                   to_celsius);
}
```

---

## Example: transforming a container (cont.)

- We now want to run the transform on the GPU
- We need only three changes in the function call
  - use thrust namespace instead of std
  - mark the lambda as `__host__` `__device__`
  - use `thrust::host` or `thrust::device` execution policy

Found in header `thrust/execution_policy.h`

```cpp
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>

int main() {
    thrust::device_vector<float> f_temperatures;
    // generate data inside the f_temperatures
    thrust::device_vector<float> c_temperatures(f_temperatures.size());
    auto to_celsius = [] __host__ __device__ (float tf) { return (tf - 32.f) / 1.8f; };
    thrust::transform(thrust::device,
                      f_temperatures.begin(),
                      f_temperatures.end(),
                      c_temperatures.begin(),
                      to_celsius);
}
```

---

## Execution space specifier

- The `__host__` and `__device__` specifiers say which compilers should compile a function

```cpp
auto op = [] __host__ __device__ (float t) {
    return t + k * diff
}
```

- So, the specifiers say *where* a certain function *can* run
- It does not specify where the function *will* run in a certain call

<!-- image placeholder: compilation diagram: Host Compiler → vfmadd132ss (Executable by CPU), Device Compiler → fma.rn.f32 (Executable by GPU) -->

\* NVIDIA DLI

---

## Execution space specifier

<!-- image placeholder: compile time / runtime diagram showing thrust::host executing op(42.0f) on CPU and thrust::device executing op(42.0f) on GPU -->

\* NVIDIA DLI

---

## Thrust execution policies

- Execution policies are a common concept in C++
- They are unique types used to disambiguate function calls
- In the standard, they are used to target a specific parallel/vectorized execution of an algorithm
- In thrust, they are used to specify if an algorithm should run on the host or on the device

---

## Thrust host/device vectors

- Thrust provides several types of vectors
  - like `host_vector`, `device_vector`, `universal_vector`, `universal_host_pinned_vector`
- These containers provide interface and operators that allow us to use device containers as we would use a `std::vector`

```cpp
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>

thrust::host_vector<int> h_vec{1, 2, 3, 4, 5};
thrust::device_vector<int> d_vec(5);
d_vec = h_vec;
d_vec[0] = 10;
print(d_vec); // prints 10, 2, 3, 4, 5
```

---

## Example: median of a set of values

- The code below computes the median of a set of random integers
  - we only consider an odd number of values for simplicity
- How would you parallelize this code using Thrust?

```cpp
#include <algorithm>
#include <iostream>
#include <random>
#include <vector>

int main() {
    int N = 31;
    std::vector<int> values(N);

    std::mt19937 gen;
    std::uniform_int_distribution dist(1, 100);
    std::generate(values.begin(), values.end(), [&] { return dist(gen); });

    std::sort(values.begin(), values.end());
    std::cout << "The median is " << values[values.size() / 2] << std::endl;
}
```

---

## Quick overview of C++ iterators

- Iterators are a very powerful concept in C++
- They are a generalization of pointers that allow to program algorithms for different data structures in a uniform manner

<!-- image placeholder: iterator hierarchy diagram: input/output → forward → bidirectional → random_access → contiguous -->

- Depending on the type of iterator they provide different operators
  - `op[]`, `op++`, `op+=`, `op*`, `op->`, …
- Algorithms can then use the iterator operators to navigate through a container without needing to know anything about its internal structure

---

## Thrust fancy iterators

- Iterators can also be used to mimic a container
  - what's important is that I get a value when I dereference them
- Thrust provides several types of iterators that are easy to use
  - counting-iterator, transform-iterator, zip-iterator, …
- Iterators allow to iterate over ranges of values without needing to materialize extra containers in memory

---

## Example: counting iterator

Iterator that provides increasing integers from an initial value *init*

```cpp
struct counting_iterator {
    int operator[](int i) {
        return i;
    }
};
```

We can create such an iterator with the **make_counting_iterator** function

```cpp
auto begin = thrust::make_counting_iterator(1);
auto end = begin + 5;
thrust::for_each(thrust::device, begin, end, print);
// prints 1, 2, 3, 4, 5
```

---

## Example: transform iterator

Iterator that takes an initial iterator and a function object, thus producing a lightweight sequence of transformed values

```cpp
struct transform_iterator {
    int* a;

    int operator[](int i) {
        return 2 * a[i];
    }
};
```

```cpp
#include <thrust/device_vector.h>
#include <thrust/execution_policy.h>

int main() {
    auto print = [] __host__ __device__(int x) { printf("%d \n", x); };
    auto dvec = thrust::device_vector<int>{1, 2, 3, 4, 5};
    auto begin = thrust::make_transform_iterator(
        dvec.begin(), [] __host__ __device__(int x) { return x * x; });
    auto end = begin + 5;
    thrust::for_each(thrust::device, begin, end, print);
}
```

---

## Example: zip iterator

The resulting iterator allows to iterate over two containers at the same time.
When accessed returns a `thrust::tuple`.

```cpp
struct zip_iterator {
    int* a;
    int* b;

    thrust::tuple<int, int> operator[](int i) {
        return {a[i], b[i]};
    }
};
```

```cpp
#include <thrust/device_vector.h>
#include <thrust/execution_policy.h>

int main() {
    thrust::device_vector<int> v{1, 2, 3};
    thrust::device_vector<int> w{4, 5, 6};
    auto begin = thrust::make_zip_iterator(v.begin(), w.begin());
    auto end = begin + 3;
    thrust::for_each(thrust::device, begin, end, print);
    // prints (1, 4) (2, 5) (3, 6)
}
```

---

## Example: discard iterator

This iterator discards the value that it iterates over.
Its useful when an algorithms gives us an output which we don't need.

```cpp
struct wrapper {
    void operator=(int value) {
        // does nothing, the value is discarded
    }
};

struct discard_iterator {
    wrapper operator[](int i) { return {}; }
};
```

---

<!-- _header: '' -->

It's time for exercises
https://infn-esc.github.io/esc25/gpu/thrust.html

---

<!-- _header: '' -->

## Device Management

---

## CUDA Runtime system

- Threads assigned to execution resources on a block-by-block basis.
- CUDA runtime automatically reduces number of blocks assigned to each SM until resource usage is under limit.
- Runtime system:
  - maintains a list of blocks that need to execute
  - assigns new blocks to SM as they compute previously assigned blocks
- Example of SM resources:
  - threads/block or threads/SM or blocks/SM
  - number of threads that can be simultaneously tracked and scheduled
  - shared memory

---

## Context Switching

- Registers and shared memory are allocated for a block as long as that block is active
- Once a block is active it will stay active until all threads in that block have completed
- Context switching is very fast because registers and shared memory do not need to be saved and restored
- Goal: Have enough transactions in flight to saturate the memory bus
- Latency can be hidden by having more transactions in flight
- Increase active threads or Instruction Level Parallelism

---

## Maximizing asynchronous operations

- If I call the synchronous API functions, the host will needlessly wait for the GPU to finish executing
- That time could be used to launch other operations on the CPU
- In general, always prefer asynchronous API functions
  - `cudaMemcpyAsync`, `cudaMallocAsync`, `cudaFreeAsync`
- Only synchronize when needed

---

## Pinned memory

- Pinned memory is a main memory area that is not pageable by the operating system

- Ensures faster transfers (the DMA engine can work without CPU intervention)

- The only way to get closer to PCI peak bandwidth

- Needed in order for CUDA asynchronous operations to work correctly

```cpp
// allocate pinned memory
cudaMallocHost(&area, sizeof(double) * N);
// free pinned memory
cudaFreeHost(area);
```

---

## CUDA streams enable concurrency

- Simultaneous support:
  - CUDA kernels on GPU
  - 2 cudaMemcpyAsync (in opposite directions)
  - Computation on the CPU

- Requirements for Concurrency:
  - CUDA operations must be in different, non-0, streams
  - cudaMemcpyAsync with host from 'pinned' memory

---

## Concurrency for overlapping independent operations

- Using multiple streams allows to execute concurrently pieces of code that are independent
- This allows to maximize the use of the machine

<!-- image placeholder: concurrency diagram showing CPU (async copy, launch, wait, write, wait), GPU compute stream, copy stream (copy D2H), and buffer -->

\* NVIDIA DLI

---

## CUDA Streams

<!-- image placeholder: stream timeline diagram showing stream 0-3 with staggered H2D, K, D2H operations -->

```cpp
std::vector<cudaStream_t> streams(4);
// create a set of streams
for (auto& s: streams)
    cudaStreamCreate(&s);
// allocate data buffers on the host
std::vector<float*> hPtrs(4); std::vector<float*> dPtrs(4);
for (int i=0; i<4; ++i)
    cudaMallocHost(&hPtrs[i],memSize);
// allocate on device, copy data and launch kernels
for (int i=0; i<4; ++i) {
    cudaMallocAsync(&dPtrs[i],memSize, streams[i]);
    cudaMemcpyAsync(dPtrs[i],hPtrs[i], memSize, cudaMemcpyHostToDevice, streams[i]);
    kernelA<<<100,512,0,streams[i]>>>(dPtrs[i]);
    kernelB<<<100,512,0,streams[i]>>>(dPtrs[i]);
    cudaMemcpyAsync(hResults[i],dPtrs[i],memSize, cudaMemcpyDeviceToHost, streams[i]);
}
// synchronize and destroy the streams
for (auto& s: streams) {
    cudaStreamSynchronize(s);
    cudaStreamDestroy(s); // if the stream is not needed any longer
}
```

---

## Reporting Errors

- All CUDA API calls return an error code (`cudaError_t`)
  - Error in the API call itself
    OR
  - Error in an earlier asynchronous operation (e.g. kernel)

- Get the error code for the last error:
  `cudaError_t cudaGetLastError(void)`
- Get a string to describe the error:
  `char *cudaGetErrorString(cudaError_t)`

  `cudaGetErrorString(cudaGetLastError());`

---

## Timing

- You can use the standard timing facilities (host side) in an almost standard way...
  **...but remember that in general you want to operate on the GPU as asynchronously as possible**

---

## CUB algorithms inside Thrust

- Thrust algorithms internally call another layer of the CUDA Core libraries, CUB
- The calls to the Thrust algorithms are synchronized, whereas CUB algorithms are not

<!-- image placeholder: diagram showing thrust::tabulate containing cub::DeviceTransform (launch) and cudaDeviceSynchronize() (wait), with GPU compute timeline below -->

- NOTE: There is also `thrust::async` for simple applications

\* NVIDIA DLI

---

## CUB cooperative algorithms

- CUB also provides many cooperative algorithms

- Algorithms are divided into:
  - **serial**
    - invoked by one thread, executed by one
  - **parallel**
    - invoked by one thread, executed by many
  - **cooperative**
    - invoked by many threads, executed by many

<!-- image placeholder: parallel sort diagram showing serial sort steps → cooperative sort combining results -->

\* NVIDIA DLI

---

## CUB cooperative algorithms

- Cooperative algorithms make many threads cooperate to obtain the final result
- They frequently use shared memory, which allows the threads to communicate

```cpp
#include <cub/block/block_reduce.cuh>

__global__ void Kernel(const int* data, int* block_sums, int N) {
    __shared__ typename cub::BlockReduce<int, 4>::TempStorage temp_storage;

    int tidx = threadIdx.x + blockIdx.x * blockDim.x;
    int thread_data = 0;

    // Guard against out-of-bounds
    if (tidx < N)
        thread_data = data[tidx];

    // Reduce values within the block
    int block_sum = cub::BlockReduce<int, 256>(temp_storage).Sum(thread_data);

    // Write result from one thread per block
    if (threadIdx.x == 0)
        block_sums[blockIdx.x] = block_sum;
}
```

- Algorithms are templated on data type, blocksize and the algorithm implementation
- They provide a constructor and methods for executing the algorithm
- The method gets called by each thread, and the temporary storage allows cooperation

---

## Performance portability

- Started effort to make CMS online and offline event reconstruction heterogeneous in 2016

- Ability to write code that can target different hardware (NVIDIA, AMD, Intel GPUs, CPUs).
- Reduces vendor lock-in and expands deployment options.
  - While keeping more than an eye on SYCL, we ported our CUDA code to alpaka portability library

- Fortunately GPUs all work in very similar ways and once you learn one programming model and know how/if to map logical names to the hardware you can program any GPU
  - https://github.com/CHIP-SPV/chipStar
  - https://github.com/ROCm/HIPIFY

<!-- image placeholder: alpaca image with GPU vendor logos, "HOW STANDARDS PROLIFERATE" comic -->

---

## Emphasizing Parallel Algorithm Design

- Algorithm Adaptability
  - Focusing on data partitioning strategies that work across models.
  - Designing algorithms that minimize inter-thread communication and maximize concurrency.

- Optimization Techniques
  - Memory coalescing, minimizing divergence, and efficient use of shared memory are universal concerns.
  - Profiling and tuning performance using model-specific tools.

---

## Conclusion

- Programming GPUs forces you to think parallel
  - CUDA is very well mapped to the properties of the hardware
- Portable code is key for long-term maintainability, testability and support for new accelerator devices
  - It improves the CPU performance as well if done properly, aiding automatic vectorization
  - Many possible solutions, not so many viable ones, even less production ready or compatible with existing infrastructure
- Starting from a CUDA code rather than sequential C++ made our life so much easier in our portability endeavour

---

## Where to go from here?

- References for learning C++
  - *Professional C++* by M. Gregoire
  - *High-performance C++* by B. Andrist and V. Sehr
  - *Template metaprogramming* by M. Bancila
- References for mastering GPU computing
  - *Programming massively parallel processors* by W-M. Hwu, D. B. Kirk
  - *Data-oriented design* by R. Fabian
  - *NVIDIA CUDA programming guide*
