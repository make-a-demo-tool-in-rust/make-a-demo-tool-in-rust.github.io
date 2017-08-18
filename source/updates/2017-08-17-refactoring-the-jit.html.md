---
title: "Refactoring the JIT"
categories: [ "updates", ]
date: 2017-08-17
---

# Refactoring the JIT

Updated the [Fish in a JIT][fish] chapter and [code] with some refactoring ideas.

Mostly about only using `sysv64` ABI and making `JitMemory` private to avoid
having both a `JitMemory` and `JitFn` storing (and possibly trying to free) the
same allocated memory address.

[fish]: https://make-a-demo-tool-in-rust.github.io/1-0-fish-in-a-jit.html
[code]: https://github.com/make-a-demo-tool-in-rust/fish-in-a-jit
