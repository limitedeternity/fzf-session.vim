if !exists('g:session#loaded')
    let g:session#loaded = 1
else
    finish
endif

command! -bang Sessions      call session#sessions('<bang>')
command! -bang UnloadSession call session#unload_session('<bang>')

let g:session#unload_old_sessions = get(g:, 'session#unload_old_sessions', 1)
let g:session#save_terminals = get(g:, 'session#save_terminals', 0)
let g:session#session_dir = get(g:, 'session#session_dir', expand('~/.vim/sessions'))

function! session#synchronize_session(bang, session)
    let session = fnameescape(a:session)
    let should_load_file = s:should_load_session(session)

    if should_load_file == 'abort'
        return
    endif

    if should_load_file == 'pause'
        call s:pause_obsession()
        return
    endif

    call s:save_old_session()
    call s:pause_obsession()

    if should_load_file == 'yes'
        call session#load_session(a:bang, session)
    endif

    call s:do_mksession(session)
    call s:unpause_obsession(session)
endfunction

function! session#unload_session(bang)
    call s:pause_obsession()
    call s:unload_session(a:bang)
endfunction

function! session#load_session(bang, session)
    call s:unload_session(a:bang)
    call s:load_session(a:session)
endfunction

function! session#delete_session(session)
    let session = fnameescape(a:session)

    if session#current_session() == session
        call s:pause_obsession()
    endif

    if filewritable(session)
        call delete(fnameescape(session))
    endif
endfunction

function! session#session_state(session)
    if exists('g:this_obsession') && g:this_obsession == a:session
        return 'synchronized'
    endif

    if v:this_session == a:session
        return 'paused'
    endif

    return 'none'
endfunction

function! session#current_session()
    return get(g:, 'this_obsession', v:this_session)
endfunction

function! s:format_session_line(idx, str)
    let mod_time = s:rel_time(getftime(a:str))
    let name = fnamemodify(a:str, ':t:r')
    let fmt_str = "%s\t%2d ". printf("\t%%-%ds%%s", min([80, winwidth('') - 12]) - len(mod_time))
    let cur_session = get(g:, 'this_obsession', v:this_session)
    return printf(fmt_str, s:get_session_type(a:str), a:idx + 1, name, mod_time)
endfunction

function! s:get_session_type(str)
    if exists('g:this_obsession') && fnameescape(a:str) == g:this_obsession
        return '*'
    endif

    if v:this_session == fnameescape(a:str)
        return 'P'
    endif

    return ' '
endfunction

function! s:rel_time(time)
    let delta = localtime() - a:time
    let orders = [[60, 'second'], [60, 'minute'], [24, 'hour'], [7, 'day'], [4, 'week'], [12, 'month'], [100, 'year']]

    for [fits, name] in orders
        let cur_format = printf("%d %s%s ago", delta, name, delta % 10 == 1 ? '' : 's')

        if delta < fits
            break
        endif

        let delta /= fits
    endfor

    return cur_format
endfunction

function! s:compare_times(b, a)
    let ta = getftime(a:a)
    let tb = getftime(a:b)
    return ta == tb ? 0 : ta > tb ? 1 : -1
endfunction

function! s:parse_session_name(line)
    if a:line == s:new_session_prompt
        let session_name = input('Session Name: ')

        if empty(session_name)
            return ''
        endif

        return printf('%s/%s.vim', g:session#session_dir, session_name)
    endif

    return s:extract_name(a:line)
endfunction

function! s:extract_name(line)
    let session_idx = str2nr(split(a:line, "\t", 1)[1])
    return s:session_paths[session_idx - 1]
endfunction

function! s:session_source(patt)
    let cur_session = get(g:, 'this_obsession', v:this_session)
    let s:session_paths = sort(globpath(g:session#session_dir, '*.vim', 0, 1), "s:compare_times")
    let formatted = map(copy(s:session_paths), 's:format_session_line(v:key, v:val)')
    return formatted
endfunction

function! s:session_sink_bang(input)
    call s:session_sink('!', a:input)
endfunction

function! s:session_sink_nobang(input)
    call s:session_sink('', a:input)
endfunction

function! s:session_sink(bang, input)
    if len(a:input) != 2
        return
    endif

    let [action, lines] = a:input

    if type(lines) == type("")
        let lines = [lines]
    endif

    if empty(action)
        if len(lines) != 1
            throw "Can't delete concepts"
        endif

        let session_name = s:parse_session_name(lines[0])

        if !empty(session_name)
            call session#synchronize_session(a:bang, session_name)
        else
            echom "Empty session name"
        endif
    elseif action == 'ctrl-d'
        for line in lines
            if line == s:new_session_prompt
                throw "Can't delete concepts"
            endif

            let session_name = s:extract_name(line)
            call session#delete_session(session_name)
        endfor
    endif

    if exists('g:SessionLoad')
        unlet g:SessionLoad
    endif
endfunction

function! s:pause_obsession()
    if exists('g:this_obsession')
        unlet g:this_obsession
    endif
endfunction

function! s:load_session(session_name)
    call s:mutate_session(a:session_name)
    execute 'source ' . a:session_name
endfunction

function! s:do_mksession(session_name)
    if !isdirectory(g:session#session_dir)
        call mkdir(g:session#session_dir, 'p', 0700)
    endif

    execute 'mksession! ' . a:session_name
    let v:this_session = a:session_name
endfunction

function! s:unpause_obsession(session_name)
    let g:this_obsession = a:session_name
    let v:this_session = a:session_name
endfunction

function! s:mutate_session(session_name)
    if g:session#save_terminals
        return
    endif

    let lines = readfile(a:session_name)
    let command = "substitute(v:val, 'if bufexists(fnamemodify(\"term://.*\"', '\" terminal load deleted by fzf-session.vim', 'g')"

    call map(lines, command)
    call writefile(lines, a:session_name)
endfunction

function! s:save_old_session()
    if exists('g:this_obsession') && get(g:, 'obsession_no_bufenter', 0)
        call s:do_mksession(g:this_obsession)
    endif
endfunction

function! s:should_load_session(session)
    let def = filereadable(a:session) ? "yes" : "no"
    let state = session#session_state(a:session)

    if state == "synchronized"
        let answer = confirm('Session is already active:', "&Pause\n&Update\n&Cancel")

        if answer == 1
            return "pause"
        endif

        if answer == 2
            return "no"
        endif

        return "abort"
    endif

    if state == "paused"
        let answer = confirm('Session is paused:', "&Load\n&Update\n&Cancel")

        if answer == 1
            return def
        endif

        if answer == 2
            return "no"
        endif

        return "abort"
    endif

    return def
endfunction

function! s:unload_session(bang)
    if !g:session#unload_old_sessions
        return
    endif

    if tabpagenr('$') > 1
        execute 'tabonly' . a:bang
    endif

    if winnr('$') > 1
        execute 'only' . a:bang
    endif

    execute 'enew' . a:bang
    let last_buf = bufnr('$')

    for b in getbufinfo()
        let bufnr = b['bufnr']
        let buf_name = b['name']
        let is_listed = b['name']
        let is_loaded = b['name']

        if !is_loaded || bufnr == last_buf || !is_listed
            continue
        endif

        execute printf('silent bd %d', bufnr)
    endfor
endfunction

let s:new_session_prompt = '	  |  New Session'
let s:fzf = { a, b, c -> fzf#run(fzf#wrap(a, b, c)) }

function! session#sessions(bang, ...)
        let [query, args] = (a:0 && type(a:1) == type('')) ? [a:1, a:000[1:]] : ['', a:000]
        let callback = a:bang ? 's:session_sink_bang' : 's:session_sink_nobang'
        return s:fzf('load_session', {
        \   'source':  s:session_source(query) + [s:new_session_prompt],
        \   'sink*':   function(callback),
        \   'options': ['+m', '--multi', '--tiebreak=index', '--prompt', 'Load Session> ', '--ansi', '--extended', '--nth=2..', '--layout=reverse-list', '--tabstop=1', '--expect=ctrl-d', '--header', 'Press CTRL-D to delete a session'],
        \}, 0)
endfunction
