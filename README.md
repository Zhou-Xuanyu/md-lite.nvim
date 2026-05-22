# md-lite.nvim 

A very lite plugin to provide limited enhancement to markdown editing.

## Use

Currently, it has only one feature: render ordered list in time.

```markdown
1. one
1. two
    1. one
1. three
```

will be rendered as

```markdown
1. one
2. two
    1. one
3. three
```

## Install

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "Zhou-Xuanyu/md-lite.nvim",
    ft = "markdown",
}
```
