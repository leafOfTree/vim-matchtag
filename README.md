# vim-matchtag

<p align="center">
<img alt="screenshot" src="https://raw.githubusercontent.com/leafOfTree/leafOfTree.github.io/master/vim_matchtag_single.png" height="135" />
<img alt="screenshot" src="https://raw.githubusercontent.com/leafOfTree/leafOfTree.github.io/master/vim_matchtag_both.png" height="135" />
<img alt="screenshot" src="https://raw.githubusercontent.com/leafOfTree/leafOfTree.github.io/master/vim_matchtag_both_react.png" height="135" />
</p>

Highlight matching tags in any files such as html, xml, js, jsx, vue, svelte.

## Installation

<details>
<summary><a>How to install</a></summary>

- [VundleVim][1]

        Plugin 'leafOfTree/vim-matchtag'

- [vim-pathogen][2]

        cd ~/.vim/bundle && \
        git clone https://github.com/leafOfTree/vim-matchtag --depth 1

- [vim-plug][3]

        Plug 'leafOfTree/vim-matchtag'

- Or manually, clone this plugin to `path/to/this_plugin`, and add it to `rtp` in vimrc

        set rtp+=path/to/this_plugin

<br />
</details>

## How it works

This plugin finds the matching tag and highlight it. Mainly inspired by vim builtin `matchparen` using `searchpairpos` and `matchaddpos`. Feel free to open an issue or a pull request.

## Configuration

Set global variable to `1` to enable or `0` to disalbe. Or a proper value to make it effective. Ex:

```vim
let g:vim_matchtag_enable_by_default = 0
let g:vim_matchtag_files = '*.html,*.xml,*.js,*.jsx,*.vue,*.svelte,*.jsp'
```

| variable                           | description                                                | default   |
|------------------------------------|------------------------------------------------------------|-----------|
| `g:vim_matchtag_enable_by_default` | Enable by default. You can always toggle it.               | 1         |
| `g:vim_matchtag_files`             | Enable on these files.                                     | *See ^*   |
| `g:vim_matchtag_both`              | Highight both the current tag and the matching tag. <br>`0` means the current tag won't be highighted <br>if the cursor is on its tagname.| 0         |
| `g:vim_matchtag_mapping_toggle`    | Key mapping to toggle highlighting.                        | `''` |
| `g:vim_matchtag_mapping_both`      | Key mapping to toggle `both` at runtim.                    | `''` |
| `g:vim_matchtag_skip`              | Syntax to skip.                                            | *See +*   |
| `g:vim_matchtag_skip_except`       | Syntax not to skip.                                        | *See +*   |
| `g:vim_matchtag_timeout`           | The search stops after timeout milliseconds.               | 50       |
| `g:vim_matchtag_disable_cache`     | Disable the cache for lines. <br>(By default the lines are cached until text changed)                                  | 0         |
| `g:vim_matchtag_debug`             | Echo debug messages.                                       | 0         |

**Note**

- ^: It is a comma separated file pattern(`:h autocmd-patterns`). It defaults to

    ```vim
    let g:vim_matchtag_files = '*.html,*.xml,*.js,*.jsx,*.ts,*.tsx,*.vue,*.svelte,*.jsp,*.php,*.erb'
    ```

- If you prefer to enable it on demand, you can set `g:vim_matchtag_enable_by_default` to `0` then toggle it manualy.

- +: Both are patterns(`:h pattern`). The default values are

    ```vim
    let g:vim_matchtag_skip = 'javascript\|css\|script\|style'
    let g:vim_matchtag_skip_except = 'html\|template'
    ```
- See [performance](#performance) if there are lags.

### Highlighting

You could change `matchTag` highlighting as follows. The default is `IncSearch`.

```vim
highlight link matchTag Search
highlight link matchTag MatchParen

" Or
highlight matchTag gui=reverse
```

If the matching tag is not found, the current tag will be highlighted as `matchTagError`, which defaults to `Error`.

```vim
highlight link matchTagError Todo
```

### Command

There are commands you can call directly or add key mapping to.

- `:MatchTagToggle` Toggle highlighting.

- `:MatchTagToggleBoth` Toggle `g:vim_matchtag_both` at runtime.

## Performance

The highlighting should take about `0.001`~`0.01` depending on the file content. If there is a freeze, you can try 

```vim
let g:vim_matchtag_skip = '<pattern>'         " Syntax to skip
let g:vim_matchtag_skip_except = '<pattern>'  " Syntax not to skip

call matchtag#ReportTime()
```
and feel free to open an issue.

You can show the syntax stack under the cursor by running
```vim
echo map(synstack(line('.'), col('.')), { _, id -> synIDattr(id, 'name') })
```

## Others

- Jump between matching tags? See `:h matchit`.

## Credits

- matchparen.vim

[1]: https://github.com/VundleVim/Vundle.vim
[2]: https://github.com/tpope/vim-pathogen
[3]: https://github.com/junegunn/vim-plug
