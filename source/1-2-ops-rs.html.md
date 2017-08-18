---
title: 1.2 ops.rs - Operators
---

# 1.2 ops.rs - Operators

The operations are defined as a trait in [jit/ops.rs][code]. They are `sysv64`
extern functions. In the JIT, we put their memory addresses in the `rax`
register and `call rax`.

The actual implementation of the functions is on the `Context` struct. They
mostly operate on the `Context`, and in the case of a large number of such
operations, this helps to keep their implementation organized.

[code]: https://github.com/make-a-demo-tool-in-rust/fish-in-a-jit/tree/master/src/jit/ops.rs

So the JIT function makes calls to functions in our Rust code. The operations
are implemented by taking a pointer to `Context` as the first argument, and the
other arguments can come from destructuring the `enum`.

For example, when building the JIT, `Operator::Exit(30.0)` will be translated to
a function call:

~~~ rust
Ops::op_exit as extern "sysv64" fn(&mut Context, f32)
~~~

Before the function call, in the JIT we will have to arrange argument values in
the CPU registers and the stack, according to the conventions of the CPU
hardware and how the OS uses that CPU.

We tag the `extern` function with the ABI we are using in the JIT. Here we are
using `sysv64` ([System V AMD64 ABI][sysv64]) which is the expected on Linux and
Mac, but Rust will compile it accordingly on Windows as well.

So far this was easy. When writing the JIT, there will be a wee bit more
documentation-digging.

[sysv64]: https://en.wikipedia.org/wiki/X86_calling_conventions#System_V_AMD64_ABI

