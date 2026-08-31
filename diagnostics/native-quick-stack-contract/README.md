# Native Quick Stack Contract Probe

This one-shot development-only UE4SS Lua probe resolves current-build native
Quick Stack helper functions and logs their reflected parameter layouts. It
never invokes a function and never reads or changes inventory data.

The contract was captured on 2026-08-30 from Palworld Steam build `24575825`
with Workshop UE4SS `3.0.1`. The recorded conclusions are in
`docs/runtime-contract.md`.

The probe is not part of the Quick Stack release payload. Remove its installed
mod directory immediately after capturing the result.
