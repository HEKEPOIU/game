# Notes:

If you xbox controller trigger can only work one side please see this [link](https://www.reddit.com/r/xbox/comments/qer8pv/xbox_controller_right_and_left_trigger_merged/),
basically Microsoft change they driver that make controller trigger merge into one value,
I just can't solve this, but later when we support xinput it should be fix easily.


## Odin Notes:

```odin
// #subtype are same as using, but can't access the field member via parent struct
// Almost all use case of subtype in odin Source lib are winddows DOM Object
SubType_Example :: struct {
 #subtype IUnknown: win.IUnknown,
}
Using_Example :: struct {
 using IUnknown: win.IUnknown,
}

S : SubType_Example
U : Using_Example

// S.lpVtbl //error
U.lpVtbl // ok

```
