---
title: 1.4 bytecode.rs - Blob
---

# 1.4 bytecode.rs - Blob

We need to represent the `Dmo` data as a serialized binary blob (a bunch of
`u8`), and a function which can read that and reconstruct the `Dmo` from it.

~~~ rust
pub trait Bytecode {
    fn to_bytecode(&self) -> Vec<u8>;
    fn from_bytecode(data: Vec<u8>) -> Dmo;
}
~~~

There is no pre-defined way here, we can take the values in any order and
convert them to bytes, only that we have to follow the same order to make sense
of it when deserializing from the bytecode.

~~~ rust
// bytecode.rs

impl Bytecode for Dmo {
    fn to_bytecode(&self) -> Vec<u8> {
        let mut res: Vec<u8> = Vec::new();

        // Sprites
        // - u8: number of sprites
        // - u8: length of the sprite
        // - [u8]: sprite
        // ...

        res.push(self.context.sprites.len() as u8);

        // ASCII sprites can be unicode UTF-32, so expect the 4-byte char
        // instead of u8
        for sprite in self.context.sprites.iter() {
            // length in chars, not in bytes
            res.push(sprite.chars().count() as u8);

            let v: Vec<char> = sprite.chars().collect();
            for ch in v.iter() {
                push_u32(&mut res, *ch as u32)
            }
        }
        
        // ... and on to the rest of the data until we return the result.

        res
    }
}
~~~

When reading it back from a `Vec<u8>` it helps to use a struct with some helper
methods to read certain types at a time, such a 4-byte integer or a 4-byte
float.

~~~ rust
pub struct DataBlob {
    data: Vec<u8>,
    idx: usize,
}

impl DataBlob {
    pub fn read_u32(&mut self) -> u32 {
        let bytes: &[u8] = &self.data[self.idx .. self.idx+4];

        let mut number: u32 = 0;
        unsafe {
            ptr::copy_nonoverlapping(
                bytes.as_ptr(),
                &mut number as *mut u32 as *mut u8,
                4);
        };
        number.to_le();

        self.idx += 4;
        number
    }

    pub fn read_f32(&mut self) -> f32 {
        let number: f32 = unsafe { mem::transmute(self.read_u32()) };
        number
    }
}
~~~

But other than that we just follow the serializing steps:

~~~ rust
// bytecode.rs

impl Bytecode for Dmo {
    fn from_bytecode(data: Vec<u8>) -> Dmo {
        let mut blob = DataBlob::new(data);

        let mut context = Context::new();

        let mut n_sprites = blob.read_u8();

        while n_sprites >= 1 {
            // length of the sprite in chars, not in u8
            let l = blob.read_u8();

            let v = blob.read_char_vec(l as usize);
            let s: String = v.into_iter().collect();

            context.sprites.push(s);

            n_sprites -= 1;
        }
        
        // ... and on and on until we reconstructed everything.
        
        Dmo {
            context: context,
            operators: operators,
        }
    } 
}
~~~
