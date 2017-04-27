---
title: 1.2 ops.rs - Operators
---

# 1.2 ops.rs - Operators

In the [source repo][code] you will see an **ops_unix.rs** and
**ops_windows.rs**. The only difference is that the `extern` functions use the
`sysv64` ABI on Linux and Mac, while they use the `C` ABI on Windows.

[code]: https://github.com/make-a-demo-tool-in-rust/fish-in-a-jit/tree/master/src

The JIT function makes calls to functions in our Rust code. The operations are
implemented by taking a pointer to `Context` as the first argument, and the
other arguments can come from destructuring the `enum`.

For example, when building the JIT, `Operator::Exit(30.0)` will be translated to
a function call:

~~~ rust
Ops::exit as extern "sysv64" fn(&mut Context, f32)
~~~

Which is implemented as:

~~~ rust
// ops.rs

impl Ops for Context {

    /// We use `.is_running` as the break condition for the main drawing loop.
    /// This sets `.is_running` to `false` if `.time` is over the `limit`.
    extern "sysv64" fn exit(&mut self, limit: f32) {
        if self.time > limit {
            self.is_running = false;
        }
    }

}
~~~

These are the calls which are arranged with `x86` instructions. Before the
actual function call, in the JIT we will have to arrange argument values on the
stack and in CPU registers according to the conventions of the CPU hardware and
how the OS uses that CPU.

`x86_32` expects function arguments on the stack, so you'd have to push values
onto the stack before making the call.

`x86_64` expects function arguments in the registers in a certain order, but
this order is different on Windows and Linux.

Because, why should general-purpose operating systems agree on how to use the
same general-purpose processor? Let go and move on.

So we have to anticipate that convention when putting in the `x86` instructions,
and the Rust compiler also has to know what convention to use for the `extern`
function on the given OS and arch.

When writing the `extern` functions, we just have to tag it accordingly. We only
target `x86_64`. On Linux and Mac the ABI is `sysv64` for
the [System V AMD64 ABI][sysv64], and on Windows it is `C` which effecively
means the [Windows x64 calling convention][win-x64].

When writing the JIT, there will be a wee bit more documentation-digging.

[sysv64]: https://en.wikipedia.org/wiki/X86_calling_conventions#System_V_AMD64_ABI
[win-x64]: https://msdn.microsoft.com/en-us/library/7kcdt6fy.aspx

