
function! RunNext(timer)
	if (len(g:commanQueue) != 0 && !exists('g:backgroundCommandOutput'))
		let s:command = g:commanQueue[0]
		let g:commanQueue = g:commanQueue[1:len(g:commanQueue)]
		exec s:command
	endif
endfunction
let g:commanQueue = []

let timer = timer_start(200, 'RunNext', {'repeat': -1})

function! AppendInternal(command)
	call add(g:commanQueue, a:command)
endfunction

function! AppendExternal(command, ...)
	  let a:arg2 = get(a:, 1, "none")
	call add(g:commanQueue, "call RunBackgroundCommand(\"".a:command."\",\"".a:arg2."\")")
endfunction

function! AppendOpenOnFailure()
	call add(g:commanQueue, "call s:openOnFailure()")
endfunction

function! AppendRunAndOpenOnFailure(command)
	call add(g:commanQueue, "call RunBackgroundCommand(\"".a:command."\")")
	call add(g:commanQueue, "call s:openOnFailure()")
endfunction

function! AppendOpenErrorFileIfExist()
	call add(g:commanQueue, "call s:openErrorFileIfExists()")
endfunction

function! s:openErrorFileIfExists()
	let s:file = g:lastFile . ".err"
	if !empty(glob(s:file)) && !match(readfile(s:file), '\s*')
		execute "sp " . s:file
	endif
endfunction

function! AppendRunOnSuccessInternal(command)
	call AppendInternal("call s:runOnSuccessInternal(\"".a:command."\")")	
endfunction

function! AppendRunOnFailureInternal(command)
	call AppendInternal("call s:runOnFailureInternal(\"".a:command."\")")
endfunction

function! AppendRunOnSuccessExternal(command, ...)
	  let a:arg2 = get(a:, 1, "appendRUnOnSuccessNone")
	  if (a:arg2 == "appendRUnOnSuccessNone")
		call AppendInternal("call s:runOnSuccessExternal(\"".a:command."\")")	
	else
		call AppendInternal("call s:runOnSuccessExternal(\"".a:command."\", \"".a:arg2."\")")	
	endif
endfunction

function! s:runOnFailureInternal(command)
	if (g:lastExitCode != 0)
		execute a:command	
	endif
endfunction

function! s:runOnSuccessExternal(command, ...)
	  let a:arg2 = get(a:, 1, "none")
	if (g:lastExitCode == 0)
		call RunBackgroundCommand(a:command, a:arg2)	
	endif
endfunction

function! s:runOnSuccessInternal(command)
	if (g:lastExitCode == 0)
		execute a:command
	endif
endfunction

function! AppendRunOnNamedSuccessInternal(command, name)
	call AppendInternal("call s:runOnNamedSuccessInternal(\"".a:command."\",\"".a:name."\")")
endfunction

function! AppendRunOnNamedInternal(command, name)
	call AppendInternal("call s:runOnNamedInternal(\"".a:command."\",\"".a:name."\")")
endfunction

function! s:runOnNamedInternal(command, name)
	if (a:name == g:lastExecuted)
		execute a:command
	endif
endfunction

function! s:runOnNamedSuccessInternal(command, name)
	if (g:lastExitCode == 0 && a:name == g:lastExecuted)
		execute a:command
	endif
endfunction

function! s:appendOpenOnSuccess(command)
	call add(g:commanQueue, "call RunBackgroundCommand(\"".a:command."\")")
	call add(g:commanQueue, "call s:openOnSuccess()")
endfunction

function! s:openOnSuccess()
	if (g:lastExitCode == 0)
		execute "vsp " . g:lastFile
	endif
endfunction

function! s:openOnFailure()
	if (g:lastExitCode != 0)
		silent execute "vsp " . g:lastFile
	endif
endfunction

function! s:openLast()
	execute "vsp " . g:lastFile
endfunction

function! AppendOpenLast()
	call add(g:commanQueue, "call s:openLast()")
endfunction

" This callback will be executed when the entire command is completed
function! BackgroundCommandClose(job, exitStatus)
  let g:lastFile = g:backgroundCommandOutput
  let g:lastExitCode = a:exitStatus
  let g:lastExecuted = g:currentExecuting
  unlet g:backgroundCommandOutput
	
  if (g:lastExitCode != 0)
	  echo "[FAIL] ".g:lastCommand
  else
	  echo "[SUCCESS] ".g:lastCommand
  endif
endfunction

function! RunBackgroundCommand(command,...)

  let a:arg2 = get(a:, 1, "none")

  " Make sure we're running VIM version 8 or higher.
  if v:version < 800
    echoerr 'RunBackgroundCommand requires VIM version 8 or higher'
    return
  endif

  if exists('g:backgroundCommandOutput')
    echo 'Already running task in background'
  else
    echo "[RUNNING] ".a:command
    " Notice that we're only capturing out, and not err here. This is because, for some reason, the callback
    " will not actually get hit if we write err out to the same file. Not sure if I'm doing this wrong or?
	let g:currentExecuting = a:arg2
	let g:lastCommand = a:command
    let g:backgroundCommandOutput = tempname()
    call job_start(a:command, {'exit_cb': 'BackgroundCommandClose', 'out_io': 'file', 'err_io': 'file', 'err_name':g:backgroundCommandOutput . ".err" , 'out_name': g:backgroundCommandOutput})
  endif
endfunction

