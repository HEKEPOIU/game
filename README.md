# The Game

This is a game project that barely not using any third party library.

The following are the list of implemented/working features:

- keyboard input
- controller support via HID api and parsing SDL controller database. (need more testing, and will add other api like xinput)
- audio support via wasapi (working on, now just playing some sine wav.) 
    - muliti thread audio, audio mixing... are not implemented yet, it will done when I need it.



# Notes:

If you xbox controller trigger can only work one side please see this [link](https://www.reddit.com/r/xbox/comments/qer8pv/xbox_controller_right_and_left_trigger_merged/),
basically Microsoft change they driver that make controller trigger merge into one value,
I just can't solve this for new, when we support xinput it should be fix easily.


## Docs
the [docs](docs/) folder contains some design decisions, and the goal of system went to achieve.

Not api docs, api docs will be written on top of function.

## Conventions



## Some Odin Notes:

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


```odin
// Matrix in odin are column major, that means is:
m := matrix[2, 3]f32{
    00, 10, 20,
    01, 11, 21,
}
// internally will be :
t := [3][2]f32{{00, 01}, {10, 11}, {20, 21}} // = matrix[2, 3]f32

```
