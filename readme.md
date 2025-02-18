Simple session loader that works with fzf. Sessions are stored in ~/.vim/sessions . Make sure this directory exists!

![Screenshot](screenshot.png)

Commands:

    :Sessions
        interactively view and manage sessions
    :UnloadSession
        finish the session and unload all buffers

- Enter on [New session] creates a new session
- Enter selects an existing session. This unloads all buffers of the current session and loads the new one
- Ctrl-d deletes the selected session file(s)

If you want to run this in your vimrc on startup you need some slight trickery:

    if (!exists('g:first_load'))
        if v:vim_did_enter
          SessionLoad
        else
         au VimEnter * SessionLoad
        endif
    endif
    let g:first_load = 0


## Installation:

With vim-plug:

    Plug 'Tarmean/fzf-session.vim'
    Plug 'tpope/vim-obsession'
    Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': 'yes \| ./install' }
    let g:obsession_no_bufenter = 1

The plugin works perfectly fine without vim-obsession but you won't automatically store the session when quitting vim.

## Note:

By default, fzf-session rewrites the session files to skip terminal buffers. If they are wanted, use:

    let g:session#unload_old_sessions = 0
