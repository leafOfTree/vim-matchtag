<img src="https://raw.githubusercontent.com/leafOfTree/leafOfTree.github.io/master/vim-matchtag.svg" width="60" height="60" alt="icon" align="left"/>

# vim-matchtag

<p align="center">
<img alt="screenshot" src="https://raw.githubusercontent.com/leafOfTree/leafOfTree.github.io/master/vim_matchtag_single.png" height="135" />
<img alt="screenshot" src="https://raw.githubusercontent.com/leafOfTree/leafOfTree.github.io/master/vim_matchtag_both.png" height="135" />
<img alt="screenshot" src="https://raw.githubusercontent.com/leafOfTree/leafOfTree.github.io/master/vim_matchtag_both_react.png" height="135" />
</p>

Highlight matching tags in any files such as html, xml, js, jsx, ts, tsx, vue, svelte, astro.

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

Self-closing tags like `<div />`, void elements like `<img>` and components like `<Counter>` without a closing tag are highlighted as a single tag.

## Configuration

Set global variable to `1` to enable or `0` to disable. Or a proper value to make it effective. Ex:

```vim
let g:vim_matchtag_enable_by_default = 1
let g:vim_matchtag_files = '*.html,*.xml,*.js,*.jsx,*.ts,*.tsx,*.vue,*.svelte,*.jsp,*.php,*.erb,*.astro'
```

| variable                             | description                                         | default |
|--------------------------------------|-----------------------------------------------------|---------|
| g:vim_matchtag_files               | Enable on these files.                              | *See ^* |
| g:vim_matchtag_enable_by_default   | Enable by default.                                  | 1       |
| g:vim_matchtag_highlight_cursor_on | Highlight the tag when the cursor is on it. | 0       |
| **Mappings / Performance / debug related** |||
| g:vim_matchtag_mapping_toggle                     | Key mapping to toggle highlighting.                     | `''`    |
| g:vim_matchtag_mapping_toggle_highlight_cursor_on | Key mapping to toggle `highlight_cursor_on`. | `''`    |
| g:vim_matchtag_skip          | Syntax to skip.                                                                       | *See +* |
| g:vim_matchtag_skip_except   | Syntax not to skip.                                                                   | *See +* |
| g:vim_matchtag_timeout       | The search stops after timeout milliseconds.                                          | 50      |
| g:vim_matchtag_disable_cache | Disable the cache for lines. <br>(By default the lines are cached until text changed) | 0       |
| g:vim_matchtag_debug         | Echo debug messages.                                                                  | 0       |

**Note**

- If you prefer to enable it on demand, you can set `g:vim_matchtag_enable_by_default` to `0` then toggle it by `:MatchTagToggle`.

- ^: It is a comma separated file pattern (`:h autocmd-patterns`). It defaults to

    ```vim
    let g:vim_matchtag_files = '*.html,*.xml,*.js,*.jsx,*.ts,*.tsx,*.vue,*.svelte,*.jsp,*.php,*.erb,*.astro'
    ```
- +: Both are patterns (`:h pattern`) matched against the syntax stack under the cursor. Tags are skipped when any syntax name matches `g:vim_matchtag_skip`, unless one also matches `g:vim_matchtag_skip_except`. This avoids taking `<` in code like `a < b` as a tag. If there is no syntax, e.g. with treesitter highlighting, nothing is skipped. The default values are

    ```vim
    let g:vim_matchtag_skip = 'javascript\|css\|script\|style'
    let g:vim_matchtag_skip_except = 'html\|template\|tsx\|jsx'
    ```
- See [troubleshooting](#troubleshooting) if tags are not highlighted, or [performance](#performance) if there are lags.

### Highlighting

When the matching tag is found, the highlight group is `matchTag` (by default `Visual`). Otherwise, it's `matchTagError` (by default `Error`).

You could change them as follows.

```vim
highlight link matchTag Search
highlight link matchTag MatchParen
highlight matchTag gui=reverse

highlight link matchTagError Todo
```

If these don't take effect, try putting them at the end of your vimrc.

### Commands

There are commands you can call directly or add key mapping to.

- `:MatchTagToggle` Toggle highlighting.

- `:MatchTagToggleHighlightCursorOn` Toggle highlighting of the tag when the cursor is on it.

## Performance

The highlighting should take about `0.001`~`0.01` seconds depending on the file content. If there is a freeze, you can try 

```vim
let g:vim_matchtag_skip = '<pattern>'         " Syntax to skip
let g:vim_matchtag_skip_except = '<pattern>'  " Syntax not to skip

call matchtag#ReportTime()
```
and feel free to open an issue.

## Troubleshooting

If tags are not highlighted in some files

- Check that the file matches `g:vim_matchtag_files`.
- Check the syntax stack on a tag by running

    ```vim
    echo map(synstack(line('.'), col('.')), { _, id -> synIDattr(id, 'name') })
    ```

    If a name matches `g:vim_matchtag_skip` but none matches `g:vim_matchtag_skip_except`, the tag is skipped. Add a pattern for the tag's syntax name to `g:vim_matchtag_skip_except`, like

    ```vim
    let g:vim_matchtag_skip_except = 'html\|template\|tsx\|jsx\|<tag syntax>'
    ```

    Feel free to open an issue with the output and the syntax plugin you use.

## Others

- Jump between matching tags with `%`? This plugin only highlights tags. Jumping is provided by the builtin `matchit`, see `:h matchit`. For filetypes it doesn't support by default, like svelte, set `b:match_words` (`:h matchit-newlang`) or use a plugin such as [vim-svelte-plugin][4] or [vim-vue-plugin][5].

## Credits

- matchparen.vim

[1]: https://github.com/VundleVim/Vundle.vim
[2]: https://github.com/tpope/vim-pathogen
[3]: https://github.com/junegunn/vim-plug
[4]: https://github.com/leafOfTree/vim-svelte-plugin
[5]: https://github.com/leafOfTree/vim-vue-plugin
