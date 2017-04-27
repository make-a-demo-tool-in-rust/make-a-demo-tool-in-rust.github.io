---
title: 1.3 jit.rs - A hand-made function
---

# 1.3 jit.rs - A hand-made function

- [Allocating memory](#allocating-memory)
- [Filling it with instructions](#filling-it-with-instructions)
- [Endianness](#endianness)
- [Operator enums to x86](#operator-enums-to-x86)
- [Calling conventions](#calling-conventions)
- [Ops breakdown: Print, Exit, Draw](#ops-breakdown-print-exit-draw)
  - [Op::Print](#opprint)
  - [Op::Exit(f32)](#opexitf32)
  - [Op::Draw(u8, u8, f32)](#opdrawu8-u8-f32)
- [Running the JIT](#running-the-jit)
- [Drop](#drop)

Using the JIT goes as follows:

- allocate some read-write memory, represented by `JitMemory`
- fill the memory with instrucion bytes while iterating over a `Vec<Operator>`
- mark the allocated memory as executable, `JitMemory::to_jit_fn()` should return a `JitFn`
- call it as a function with `JitFn::run()`, which transmutes the pointer to the
  executable memory into a function pointer and calls that pointer

This memory has to be requested in multiples of the [page size][memory-page]
supported by the CPU, for `x86_64` the smallest valid size is `4k`.

The OS will not allow a memory region to be both writable and executable at the
same time, so these stages have to be clearly separated.

`JitMemory` keeps track of the address, the size we requested and the index
offset where we are going to write the next byte.

`JitFn` maps to an address already marked as executable.

~~~ rust
// jit.rs

// Allocate memory sizes as multiples of 4k page.
const PAGE_SIZE: usize = 4096;

/// A read-write memory buffer allocated to be filled with bytes of `x86`
/// instructions.
pub struct JitMemory {
    addr: *mut u8,
    size: usize,
    /// current position for writing the next byte
    offset: usize,
}

/// An executable memory buffer filled with `x86` instructions.
pub struct JitFn {
    addr: *mut u8,
    size: usize,
}
~~~

## Allocating memory

The allocated memory block has to be aligned on a boundary of 16 bytes,
otherwise we won't be able to use it as an executable function on both Windows,
Mac and Linux.

On Linux and Mac, `libc::malloc()` simply allocates a block at the next
convenient address, and doesn't guarantee any kind of alignment.

In the [libc manual][libc-manual] we find *3.2.3.6 Allocating Aligned Memory
Blocks*, which describes `posix_memalign()`. The function signature is:

~~~ c
int posix_memalign (void **memptr, size_t alignment, size_t size)
~~~

We can use this to request an aligned memory block of a certain size, then use
`mprotect()` to mark it as read-write.

Because this memory can contain anything when we get it, it's a good idea to use
`memset()` to fill it with `ret` calls (`0xC3`), so if our function moves to an
unexpected instruction, at least it will just return.

`posix_memalign()` sets a C `**void` type pointer in the first argument. We have
to transmute this to a `*mut u8` Rust type, then we are good to go.

~~~ rust
// jit.rs

impl JitMemory {
    /// Allocates read-write memory aligned on a 16 byte boundary.
    #[cfg(any(target_os = "linux", target_os = "macos"))]
    pub fn new(num_pages: usize) -> JitMemory {
        let size: usize = num_pages * PAGE_SIZE;
        let addr: *mut u8;

        unsafe {
            // Take a pointer
            let mut raw_addr: *mut libc::c_void = mem::uninitialized();

            // Allocate aligned to page size
            libc::posix_memalign(&mut raw_addr,
                                 PAGE_SIZE,
                                 size);

            // Mark the memory as read-write
            libc::mprotect(raw_addr,
                           size,
                           libc::PROT_READ | libc::PROT_WRITE);

            // Fill with 'RET' calls (0xc3)
            libc::memset(raw_addr, 0xc3, size);

            // Transmute the c_void pointer to a Rust u8 pointer
            addr = mem::transmute(raw_addr);
        }

        JitMemory {
            addr: addr,
            size: size,
            offset: 0,
        }
    }
}
~~~

On Windows, we can use [VirtualAlloc][virtualAlloc-doc], the function signature is:

~~~ cpp
LPVOID WINAPI VirtualAlloc(
  _In_opt_ LPVOID lpAddress,
  _In_     SIZE_T dwSize,
  _In_     DWORD  flAllocationType,
  _In_     DWORD  flProtect
);
~~~

[virtualAlloc-doc]: https://msdn.microsoft.com/en-us/library/windows/desktop/aa366887(v=vs.85).aspx

And so the equivalent `JitMemory::new()` for Windows:

~~~ rust
// jit.rs

impl JitMemory {
    #[cfg(target_os = "windows")]
    pub fn new(num_pages: usize) -> JitMemory {
        let size: usize = num_pages * PAGE_SIZE;
        let addr: *mut u8;

        unsafe {
            // Take a pointer
            let raw_addr: *mut winapi::c_void;

            // Allocate aligned to page size
            raw_addr = kernel32::VirtualAlloc(
                ptr::null_mut(),
                size as u64,
                winapi::MEM_RESERVE | winapi::MEM_COMMIT,
                winapi::winnt::PAGE_READWRITE);

            if raw_addr == 0 as *mut winapi::c_void {
                panic!("Couldn't allocate memory.");
            }

            // NOTE no FillMemory() or SecureZeroMemory() in the kernel32 crate

            // Transmute the c_void pointer to a Rust u8 pointer
            addr = mem::transmute(raw_addr);

        }

        JitMemory {
            addr: addr,
            size: size,
            offset: 0,
        }
    }
}
~~~

## Filling it with instructions

The `JitAssembler` trait describes what `JitMemory` will have to implement so
that we can assemble our function.

`push_u8()` puts in single-byte values. We can use this to construct 4-byte
`u32` and 8-byte `u64` values in the memory, `fill_jit()` makes use of these.
Eventually `to_jit_fn()` marks the memory block as executable and returns a
`JitFn` where we can use `JitFn::run()` to call the function.

~~~ rust
// jit.rs

pub trait JitAssembler {

    /// Marks the memory block as executable and returns a `JitFn` containing
    /// that address.
    fn to_jit_fn(&mut self) -> JitFn;

    /// Fills the memory block with `x86` instructions while iterating over a
    /// list of `Operator` enums.
    fn fill_jit(&mut self, context: &mut Context, operators: &Vec<Op>);

    /// Writes one byte to the memory at the current index offset and increments
    /// the offset.
    fn push_u8(&mut self, value: u8);

    /// Writes a 4-byte value. `x86` specifies Little-Endian encoding,
    /// least-significant byte first.
    fn push_u32(&mut self, value: u32);

    /// Writes an 8-byte value.
    fn push_u64(&mut self, value: u64);
}
~~~

Implementing `push_u8()` assigns the value to the byte at `addr + offset` and
increments the offset.

~~~ rust
// jit.rs

fn push_u8(&mut self, value: u8) {
    unsafe { *self.addr.offset(self.offset as _) = value };
    self.offset += 1;
}
~~~

## Endianness

Implementing `push_u32()` and `push_u64()` has to construct these multi-byte
values from single bytes, and the CPU architecture will specify if we must use
either Little-Endian or Big-Endian encoding, or can do both.

At least this doesn't vary between OSes, the CPU specifies it, and
the [Endianness table][endian-table] tells us that all the `x86` CPUs stick to
Little-Endian (LE).

The naming is counter-intuitive, the "end" refers to the front- or starting end
(first byte by pointer address), not to the "final portion" end (last byte by
pointer address).

There are advantages in this for the machine. The pointer address points to the
first byte, and casting between interger types doesn't need to relocate the
bytes, just ignore or append to the end.

For small intergers it will even preserve the value:

| type    | bytes (LE)      |     value |
| :------ | :-------------- |     :---- |
| `u32`   | `7A 00 00 00`   |       122 |
| `u16`   | `7A 00`         |       122 |
| `u32`   | `0D 0C 0B 0A`   | 168496141 |
| `u16`   | `0D 0C`         |      3085 |

![Endianness](/images/Little-Endian.svg.png)

(Diagram from the [Endianness][endianness] Wikipedia page.)

Implementing it means bit-shifting the value, zeroing the higher bits by taking
a bitwise `&` with `0xFF` and what's left is an `u8` byte:

~~~ rust
// jit.rs

fn push_u32(&mut self, value: u32) {
    self.push_u8(((value >>  0) & 0xFF) as u8);
    self.push_u8(((value >>  8) & 0xFF) as u8);
    self.push_u8(((value >> 16) & 0xFF) as u8);
    self.push_u8(((value >> 24) & 0xFF) as u8);
}
~~~

## Operator enums to x86

We expressed the operations we want to happen with a list of enums, it's time to
fill the JIT (that is, write the instructions to memory) with a function that
iterates over those enums, while also passing an `&mut Context` pointer so we
can manipulate the application's state.

~~~ rust
fn fill_jit(&mut self, context: &mut Context, operators: &Vec<Operator>);
~~~

By convention we have to start our program with the function prologue and end
with the epilogue. If you were writing assembly in Linux or Mac:

~~~ asm
; prologue
push rbp
mov rbp, rsp

; ... action and excitement

; epilogue
mov rsp, rbp
pop rbp
ret
~~~

{::comment}
TODO explain what the prologue and epilogue does

TODO explain how to figure out opcode bytes
{:/comment}

And so we have to put the equivalent byte opcodes in the memory. To preserve our
sanity we will compose small functions which put in a few bytes at a time.

This way, when we have our `JitMemory`, we can call these one after the other as
if writing assembly.

For example the `push_rbp()` and `mov_rbp_rsp()` would be:

~~~ rust
// jit.rs

impl JitMemory {
    pub fn push_rbp(&mut self) {
        self.push_u8(0x55);
    }

    pub fn mov_rbp_rsp(&mut self) {
        self.push_u8(0x48);
        self.push_u8(0x89);
        self.push_u8(0xe5);
    }
}
~~~

And then we can use this in `fill_jit()` to start and end our hand-made
function, and in between we can implement action and excitement!

~~~ rust
// jit.rs

impl JitAssembler for JitMemory {

    #[cfg(any(target_os = "linux", target_os = "macos"))]
    fn fill_jit(&mut self, context: &mut Context, operators: &Vec<Op>) {
        // prologue
        self.push_rbp();
        self.mov_rbp_rsp();

        for op in operators.iter() {
            match *op {
                Op::NOOP => (),
                Op::Draw(sprite_idx, offset, speed) => {
                    /* push x86 byte instructions to memory as if writing
                    assembly, but we are assembling the machine code directly */
                },
                Op::Print => { /* ... */ },
                Op::Clear(charcode) => { /* ... */ },
                Op::Exit(limit) => { /* ... */ },
            }
        }

        // epilogue
        self.mov_rsp_rbp();
        self.pop_rbp();
        self.ret();
    }
}
~~~

## Calling conventions

### Linux and Mac

The Linux `x86_64` ABI is `sysv64`, the first few arguments are passed in
registers, any remaining ones are passed on the stack.

The **first six** integer arguments are passed in:

    rdi, rsi, rdx, rcx, r8, r9

Floating-point arguments are passed in `xmm0` - `xmm7`.

The function prologue and epilogue will be:

~~~ asm
; prologue
push rbp
mov rbp, rsp

; function body

; - put function arguments in registers
; - put the Rust function pointer in rax

call rax

; epilogue
mov rsp, rbp
pop rbp
ret
~~~

The `rsp` register must point to an address on a 16-byte boundary before the
`call` jumps. Remember that `call` will `push rdi`, moving `rsp` with -8 bytes
immediately before the jump.

In the prologue we made one `push` (`rsp` moved -8 bytes), and `call` will add
another `push` (-8 again), which is -16, so we don't have to `sub` the value in
`rsp` to adjust.

At that point we can call the address of the Rust function which corresponds to
the operator enum.

If we were counting wrong, we would find out here, because our JIT function
would segfault.

After the call, it is good to note that if we didn't have enough registers for
the function arguments and we pushed the remaining ones to the stack, then here
we would have to clean up (the stack) by adding to the address value of `rsp`.

But there is no cleaning to do at this time and we can just finish after the
call.

### Windows

In Windows x64 only the **first four** arguments can be passed in registers.

Integer arguments:

    rcx, rdx, r8, r9

Floating-point arguments can be passed in `xmm0` - `xmm3`.

The arguments are numbered by their argument position, and so for example if the
third argument is a float and the fourth is an integer, the third will be taken
from `xmm2` and the fourth will be taken from `r9`.

In Windows x64 the function prologue and epilogue the `rsp` doesn't have to be
pushed on the stack.

However, if your function is going to make a `call`, the `rsp` still has to be
16-byte aligned.

We move the `rsp` with -8 at the beginning of our function so that when the
`call` happens, `rsp` is aligned. Then at the end we restore the `rsp` position
by adding 8.

~~~ asm
; prologue
sup rbp, 8

; function body

; - put function arguments in registers
; - put the Rust function pointer in rax

call rax

; epilogue
add rsp, 8
ret
~~~

## Ops breakdown: Print, Exit, Draw

### Op::Print

`Op::Print` is a simple business. Remember that we want to call from the JIT to
a Rust function, where `&self` is a `&Context`, so the first argument is that
pointer address (integer value).

On Linux and Mac the operator's Rust functions will be `sysv64` on Windows they
will be `C`, that's the only difference.

~~~ rust
// ops_unix.rs

impl Ops for Context {

    /// Prints the text buffer, followed by a `\r` rewind
    extern "sysv64" fn print(&self) {
        let s: String = self.buffer.iter().cloned().collect();
        let text = format!("     {}\r", s);
        print!("{}", text)
    }

}
~~~

And so in `fill_jit()`:

~~~ rust
// jit.rs

// Linux and Mac
Op::Print => {
    // rdi: pointer to Context (pointer is an integer value)
    self.movabs_rdi_u64( unsafe { mem::transmute(context as *mut _) });

    // put the address of the function in rax
    self.movabs_rax_u64( unsafe { mem::transmute(
        Ops::print as extern "sysv64" fn(&Context)
    )});

    // call the function address in rax
    self.call_rax();
},

// ...

// Windows
Op::Print => {
    self.movabs_rcx_u64( unsafe { mem::transmute(context as *mut _) });
    self.movabs_rax_u64( unsafe { mem::transmute(
        Ops::print as extern "C" fn(&Context)
    )});
    self.call_rax();
},
~~~

### Op::Exit(f32)

The main drawing loop of the application is controlled with the `.is_running`
bool in the `Context`.

The `Exit(f32)` operator will translate to a call to `exit()`:

~~~ rust
// ops_unix.rs

impl Ops for Context {
    extern "sysv64" fn exit(&mut self, limit: f32) {
        if self.time > limit {
            self.is_running = false;
        }
    }
}
~~~

When adding instructions for this operator, in addition to a `&mut Context`
pointer, we also have to pass a floating point argument.

~~~ rust
// jit.rs

// Linux and Mac
Op::Exit(limit) => {
    // rdi: pointer to Context (pointer is an integer value)
    self.movabs_rdi_u64( unsafe { mem::transmute(context as *mut _) });

    // xmm0: limit argument (floating point)
    self.movss_xmm_n_f32(0, limit);

    // put the address of the function in rax
    self.movabs_rax_u64( unsafe { mem::transmute(
        Ops::exit as extern "sysv64" fn(&mut Context, f32)
    ) });

    // call the function address in rax
    self.call_rax();
},

// ...

// Windows
Op::Exit(limit) => {
    self.movabs_rcx_u64( unsafe { mem::transmute(context as *mut _) });
    self.movss_xmm_n_f32(1, limit);

    self.movabs_rax_u64( unsafe { mem::transmute(
        Ops::exit as extern "C" fn(&mut Context, f32)
    ) });

    self.call_rax();
},
~~~

### Op::Draw(u8, u8, f32)

Great! For this we are passing a mixture of arguments as well:

~~~ rust
// jit.rs

// Linux and Mac
Op::Draw(sprite_idx, offset, speed) => {
    // rdi: pointer to Context (pointer is an integer value)
    self.movabs_rdi_u64( unsafe { mem::transmute(context as *mut _) });
    // rsi: sprite_idx arg. (interger)
    self.movabs_rsi_u64(sprite_idx as u64);
    // rdx: offset arg. (interger)
    self.movabs_rdx_u64(offset as u64);
    // xmm0: speed arg. (floating point)
    self.movss_xmm_n_f32(0, speed);

    self.movabs_rax_u64( unsafe { mem::transmute(
        Ops::draw as extern "sysv64" fn(&mut Context, u8, u8, f32)
    )});
    self.call_rax();
},

// ...

// Windows

Op::Draw(sprite_idx, offset, speed) => {
    self.movabs_rcx_u64( unsafe { mem::transmute(context as *mut _) });
    self.movabs_rdx_u64(sprite_idx as u64);
    self.movabs_r8_u64(offset as u64);
    self.movss_xmm_n_f32(3, speed);

    self.movabs_rax_u64( unsafe { mem::transmute(
        Ops::draw as extern "C" fn(&mut Context, u8, u8, f32)
    )});
    self.call_rax();
},
~~~

## Running the JIT

There will come a time when this function that we crated byte-by-byte is ready
to be executed.

In the main drawing loop, we call the JIT function at every frame, passing it a
`&mut Context` pointer.

~~~ rust
// jit.rs

impl JitFn {
    pub fn run(&self, context: &mut Context) {
        unsafe {
            // type signature of the jit function
            let fn_ptr: extern fn(&mut Context);
            // transmute the pointer of the executable memory to a pointer of the jit function
            fn_ptr = mem::transmute(self.addr);
            // use the function pointer
            fn_ptr(context)
        }
    }
}
~~~

## Drop

Since we allocated this piece of memory manually, we are also responsible for
freeing it. `libc::munmap` and `kernel32::VirtualFree()` will do the job. The
signatures:

~~~ cpp
// Linux and Mac
int munmap (void *addr, size_t length)

// Windows
BOOL WINAPI VirtualFree(
  _In_ LPVOID lpAddress,
  _In_ SIZE_T dwSize,
  _In_ DWORD  dwFreeType
);
~~~

The `Drop` trait is used to implement actions when a variable goes out of scope,
so let's implement that for `JitMemory` and `JitFn`:

~~~ rust
// jit.rs

impl Drop for JitMemory {
    #[cfg(any(target_os = "linux", target_os = "macos"))]
    fn drop(&mut self) {
        unsafe { libc::munmap(self.addr as *mut _, self.size); }
    }

    #[cfg(target_os = "windows")]
    fn drop(&mut self) {
        unsafe { kernel32::VirtualFree(self.addr as *mut _, 0, winapi::MEM_RELEASE); }
    }
}

impl Drop for JitFn {
    #[cfg(any(target_os = "linux", target_os = "macos"))]
    fn drop(&mut self) {
        unsafe { libc::munmap(self.addr as *mut _, self.size); }
    }

    #[cfg(target_os = "windows")]
    fn drop(&mut self) {
        unsafe { kernel32::VirtualFree(self.addr as *mut _, 0, winapi::MEM_RELEASE); }
    }
}
~~~

[sysv64]: https://en.wikipedia.org/wiki/X86_calling_conventions#System_V_AMD64_ABI
[memory-page]: https://en.wikipedia.org/wiki/Page_%28computer_memory%29
[libc-manual]: https://www.gnu.org/software/libc/manual/
[endian-table]: https://en.wikipedia.org/wiki/Comparison_of_instruction_set_architectures#Endianness
[endianness]: https://en.wikipedia.org/wiki/Endianness
