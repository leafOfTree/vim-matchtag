# vim-matchtag

Highlight matching tags in any files such as html, xml, js, jsx, vue, svelte.

## Installation

<details>
<summary><a>How to install</a></summary>

- [VundleVim][2]

        Plugin 'leafOfTree/vim-matchtag'

- [vim-pathogen][5]

        cd ~/.vim/bundle && \
        git clone https://github.com/leafOfTree/vim-matchtag --depth 1

- [vim-plug][7]

        Plug 'leafOfTree/vim-matchtag'
        :PlugInstall

- Or manually, clone this plugin to `path/to/this_plugin`, and add it to `rtp` in vimrc

        set rtp+=path/to/this_plugin

<br />
</details>

## How it works

This plugin finds the matching tag and highlight it. Mainly inspired by vim builtin `matchparen` using `searchpairpos` and `matchaddpos`.

## Configure

Set global variable to `1` to enable or `0` to disalbe. Or a proper value to make it effective. Ex:

    let g:vim_matchtag_enable_by_default = 0
    let g:vim_matchtag_filetypes = '*.html,*.xml,*.js,*.jsx,*.vue,*.svelte,*.jsp'

| variable                           | description                                  | default                                    |
|------------------------------------|----------------------------------------------|--------------------------------------------|
| `g:vim_matchtag_enable_by_default` | Enable by default.                           | 1                                          |
| `g:vim_matchtag_mapping`           | Key mapping to toggle.                       | `'<c-t>'`                                  |
| `g:vim_matchtag_filetypes`         | Enable on these files.                       | `'*.html,*.xml,*.js,*.jsx,*.vue,*.svelte'` |
| `g:vim_matchtag_timeout`           | The search stops after timeout milliseconds. | `300`                                      |
| `g:vim_matchtag_debug`             | Echo debug messages.                         | 0                                          |

**Note**

- If you prefer to enable it when necessary, you can set `g:vim_matchtag_enable_by_default` to `0` then toggle it manualy.
- `g:vim_matchtag_filetypes` is a comma separated file pattern. See `:h autocmd-patterns` in vim.

### Highlighting

You can change `matchTag` highlighting.

```vim
highlight link matchTag Search

" Or
highlight matchTag gui=bold
```
