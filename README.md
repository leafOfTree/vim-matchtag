# vim-matchtag

<p align="center">
<img alt="screenshot" src="https://raw.githubusercontent.com/leafOfTree/leafOfTree.github.io/master/vim_matchtag_single.png" width="220" />
<img alt="screenshot" src="https://raw.githubusercontent.com/leafOfTree/leafOfTree.github.io/master/vim_matchtag_single.png" width="220" />
</p>

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
    let g:vim_matchtag_files = '*.html,*.xml,*.js,*.jsx,*.vue,*.svelte,*.jsp'

| variable                           | description                                         | default                                    |
|------------------------------------|-----------------------------------------------------|--------------------------------------------|
| `g:vim_matchtag_enable_by_default` | Enable by default.                                  | 1                                          |
| `g:vim_matchtag_files`             | Enable on these files.                              | `'*.html,*.xml,*.js,*.jsx,*.ts,*.tsx,*.vue,*.svelte,*.jsp,*.php,*.erb'` |
| `g:vim_matchtag_both`              | Highight both the current tag and the matching tag. | 0                                          |
| `g:vim_matchtag_mapping_toggle`    | Key mapping to toggle highlighting.                 | `'<c-t>'`                                  |
| `g:vim_matchtag_mapping_both`      | Key mapping to toggle `both` at runtim.         | `'<c-b>'`                                  |
| `g:vim_matchtag_timeout`           | The search stops after timeout milliseconds.        | 300                                        |
| `g:vim_matchtag_debug`             | Echo debug messages.                                | 0                                          |

**Note**

- If you prefer to enable it on demand, you can set `g:vim_matchtag_enable_by_default` to `0` then toggle it manualy.
- `g:vim_matchtag_files` is a comma separated file pattern. See `:h autocmd-patterns` in vim.
- `g:vim_matchtag_timeout` might be useful for very long lines where there can be lags.

### Highlighting

You can change `matchTag` highlighting. Default is `IncSearch`.

```vim
highlight link matchTag Search

" Or
highlight matchTag gui=reverse
```

### Command and Mapping

There are commands you can call directly or add key mapping to them.

- `:MatchTagToggle` toggle highlighting.

- `:MatchTagToggleBoth` toggle `both` at runtim.
