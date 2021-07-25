Simple session loader that works with fzf. Sessions are stored in ~/.vim/sessions .

![Screenshot](screenshot.png)

Commands:

    :SessionLoad
        interactively load a session
    :SessionUnload
        finish the session and unload all saved files

- Enter on [New session] creates a new session
- Enter selects an existing session. This unloads all buffers of the current session and loads the new one
- Ctrl-d deletes all selected session files.

If you want to run this in your vimrc on startup you need some slight trickery:

    if (!exists('g:first_load'))
        if v:vim_did_enter
          SessionLoad
        else
         au VimEnter * SessionLoad
        endif
    endif
    let g:first_load = v:false


## Installation:

With vim-plug:

    Plug 'Tarmean/fzf-session.vim'
    Plug 'tpope/vim-obsession'
    Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': 'yes \| ./install' }
    let g:obsession_no_bufenter = 1

The plugin works perfectly fine without vim-obsession but you won't automatically store the session when quitting vim.

## Note:

Whe using SessionLoad to switch we unload all current buffers. Unsaved buffers, including terminals, are left loaded.

Terminal buffer loading is a somewhat unsolvable problem - instead neovim just reopens the program the terminal was started with.  
Since terminals are both left open and reopened this would create exponential terminal buffers when reloading repeatedly. To fix this issue, terminals are filtered out of session files. When unloading sessions, terminals and unsaved buffers are left open.
