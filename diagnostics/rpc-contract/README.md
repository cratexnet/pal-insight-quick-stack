# RPC Contract Probe

This is a one-shot development-only UE4SS Lua probe for Palworld build
`24575825`.

It resolves `PalNetworkItemComponent.RequestMoveToContainer_ToServer`, prints
the reflected property names and types in order, and exits. It never invokes
the function and never reads or changes an inventory.

The probe is not part of the Quick Stack release payload. Remove its installed
mod directory immediately after capturing the result.

## Captured result

Captured on 2026-08-30 from Steam build `24575825` with Workshop UE4SS
`3.0.1`:

```text
RequestID      StructProperty<Guid>
ToContainerId StructProperty<PalContainerId>
Froms         ArrayProperty<StructProperty<PalItemSlotIdAndNum>>
```

The active probe directory was moved out of `UE4SS/Mods` into the existing
`_disabled_diagnostics` isolation directory after capture. No RPC was invoked.
