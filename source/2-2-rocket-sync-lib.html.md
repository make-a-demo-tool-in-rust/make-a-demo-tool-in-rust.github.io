---
title: 2.2 rocket_sync lib - Variable values at a given time
---

# 2.2 rocket_sync lib - Variable values at a given time

## Summary

The sync lib works standalone, the Rocket editor is not needed.

Its purpose is to represent the tracks and key values, and provide the
interpreted value of a given track at the current time.

It is a `#![no_std]` crate so that it can be included in a replay utility which
wants to avoid the Rust standard lib for a small executable binary size.

## Code Overview

It is about ~200 sloc, see [lib.rs][sync-lib-rs].

The main interface is via `SyncDevice` which really just represents the data
needed to keep the sync moving.

~~~ rust
pub struct SyncDevice {
    /// sync tracks (the vertical columns in the editor)
    pub tracks: SmallVec<[SyncTrack; 64]>,
    /// rows per beat
    pub rpb: u8,
    /// beats per minute
    pub bpm: f64,
    /// rows per second
    pub rps: f64,
    pub is_paused: bool,
    /// current row
    pub row: u32,
    /// current time in milliseconds
    pub time: u32,
}
~~~

Then there is `SyncTrack` which holds a vector of `TrackKey`. A key has `row`,
`value` and `key_type` (interpolation type).

The whole thing will be ticking at the same speed as in the Rocket Editor
because the interpolation types are the same.

~~~ rust
impl SyncTrack {
    pub fn value_at(&self, row: u32) -> f64 {
        // ...
        match cur_key.key_type {
            Step => return a,

            Linear => return a + b * t,

            Smooth => return a + b * (t*t * (3.0 - 2.0 * t)),

            Ramp => return a + b * t*t,

            NOOP => return 0.0,
        }
        // ...
    }
}
~~~

And now let's see some graphics moving!

[sync-lib-rs]: https://github.com/make-a-demo-tool-in-rust/rocket_sync/blob/master/src/lib.rs

