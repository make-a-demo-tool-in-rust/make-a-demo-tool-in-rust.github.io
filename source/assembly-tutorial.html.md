---
title: Assembly Tutorial
---

{::comment}

- [assembly.org](~/org/notes/assembly.org)

{:/comment}

# Assembly Tutorial

This will be a basic assembly tutorial focusing on how to assemble the JIT
function `x86` instructions.

Until the fortunate arrival of that glorious day, I recommend these excellent tutorials:

- [A fundamental introduction to x86 assembly programming](https://www.nayuki.io/page/a-fundamental-introduction-to-x86-assembly-programming)
- [Guide to x86 Assembly](http://www.cs.virginia.edu/~evans/cs216/guides/x86.html), and [the same with AT&T syntax](http://flint.cs.yale.edu/cs421/papers/x86-asm/asm.html)
- [Say hello to x86_64 Assembly](https://0xax.github.io/asm_1/)
- [GNU Assembler Examples](http://cs.lmu.edu/~ray/notes/gasexamples/)
- [Where the top of the stack is on x86](http://eli.thegreenplace.net/2011/02/04/where-the-top-of-the-stack-is-on-x86/)
- [Stack frame layout on x86-64](http://eli.thegreenplace.net/2011/09/06/stack-frame-layout-on-x86-64)

## Notes

- [Passing arguments](#passing-arguments)
- [Function call ABIs](#function-call-abis)
- [Assembler Tools](#assembler-tools)
- [Debuggers](#debuggers)

## Passing arguments

In 64-bit x86 code, you pass the first few parameters in registers.

Exactly which registers you use depends on the CPU arch and how the OS uses it.

On x86-64 Linux the first six parameters go into:

    rdi, rsi, rdx, rcx, r8, r9

On Windows x64, the first four parameters go into:

    rcx, rdx, r8, r9

On 32-bit x86 systems parameters are passed on the stack.

## Function call ABIs

x86-32 Windows uses various ABIs for function calls. Win32 uses "stdcall" as the
default, function arguments are passed on the stack in reverse order.

x86-32 Linux can use "stdcall".

x86-64 Linux uses "System V ABI" for function calls. Pass arguments in registers.

## Assembler Tools

- [nasm](http://www.nasm.us/doc/nasmdo11.html)
- [gas, GNU Assembler](https://en.wikipedia.org/wiki/GNU_Assembler)
- [Online x86 and x64 Intel Instruction Assembler](https://defuse.ca/online-x86-assembler.htm)

## Debuggers

- gdb (Linux)
- hopper (Mac)
