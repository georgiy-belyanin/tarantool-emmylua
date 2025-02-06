# Tarantool EmmyLua annotations [alpha]

This repository provides experimental EmmyLua annotations for a [Tarantool in-memory computing platform](https://github.com/tarantool/tarantool).
Using it you may find out how to configure your IDE for developing Tarantool applications with static checks and autocompletion.

## Installation

1. Install [emmylua-analyzer-rust LSP](https://github.com/CppCXY/emmylua-analyzer-rust).
2. Configure your text editor to use it.

If you're using NeoVim, put this in your Lua configuration:
```lua
vim.lsp.start({
  cmd = { "emmylua_ls" },
  root_dir = vim.fn.getcwd(),
})
```
3. Clone the annotations repository
```bash
git clone https://github.com/georgiy-belyanin/tarantool-emmylua
```
4. Configure LSP to find annotations Library. Create `.emmyrc.json` with the following contents.
```json
{
  "runtime": {
    "version": "LuaJIT"
  },
  "workspace": {
    "library": [
      <path to the cloned repository>/Library"
    ]
  }
}
```

If you're using VSCode, install an extension [https://marketplace.visualstudio.com/items?itemName=tangzx.emmylua](https://marketplace.visualstudio.com/items?itemName=tangzx.emmylua).

## Contributing

If you have suggestions, ideas, etc. on the Language Server or annotations themselves feel free to leave issues, pull requests and discussions.

## References & see also

* [https://github.com/vaintrub/vscode-tarantool/](https://github.com/vaintrub/vscode-tarantool/) --- Tarantool VSCode extension for sumneko Lua server.
