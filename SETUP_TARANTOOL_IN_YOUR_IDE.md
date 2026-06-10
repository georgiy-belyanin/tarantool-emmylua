# How to set up Tarantool for development inside your IDE or text editor?

## Visual Studio Code (or its forks such as Cursor)

It's the simplest one to do! Just set up [Tarantool VS Code extension](https://marketplace.visualstudio.com/items?itemName=tarantool.tarantool)
for everything to work.

## NeoVim

NeoVim installation is a bit trickier since there is no official Tarantool
plugin for NeoVim.

* You need to install [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
  extension. If you're new to NeoVim simply run the following command. Though
  generally NeoVim users prefer 3rd party package managers such as [Lazy](https://github.com/folke/lazy.nvim),
  [Packer](https://github.com/wbthomason/packer.nvim) or others.

```bash
git clone https://github.com/neovim/nvim-lspconfig ~/.config/nvim/pack/nvim/start/nvim-lspconfig
```

* Install [emmylua-analyzer-rust](https://github.com/EmmyLuaLs/emmylua-analyzer-rust).
  You will need to have Rust installed in your system.

```bash
cargo install emmylua_ls
```

* Add 

```bash
require'lspconfig'.emmylua_ls.setup{}
```

## Sublime text
