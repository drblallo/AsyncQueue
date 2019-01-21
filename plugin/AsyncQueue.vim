
let s:index = 0
let s:timer = timer_start(200, 'RunNext', {'repeat': -1})
let g:commandQueue = []
let s:compleatedList = []

function! AQClean()
	let s:compleatedList = []
	let g:commandQueue = []
	let s:index = 0
	call add(s:compleatedList, s:newCommand("None"))
	let s:compleatedList[0].successfull = 1
endfunction

function! s:toString(command)
	let l:toReturn = a:command.command
	if (a:command.external)
		let l:toReturn = "!" . l:toReturn 
	endif

	if (a:command.successfull == -1)
		let l:toReturn = "[PENDING] " . l:toReturn
	endif
		
	if (a:command.successfull == 1)
		let l:toReturn = "[SUCCESS] " . l:toReturn
	endif

	if (a:command.successfull == 0)
		let l:toReturn = "[FAILURE] " . l:toReturn
	endif

	if (a:command.successfull == -2)
		let l:toReturn = "[ABORTED] " . l:toReturn
	endif

	return l:toReturn

endfunction

function! s:newExecData()
	let l:toReturn = {}
	let l:toReturn.outFile = tempname()
	return l:toReturn
endfunction

function! s:getErrFileName(cmd)
	return a:cmd.execData.outFile . ".err"
endfunction

function! s:newCondition(targetIndex, runOnSuccess, runOnFailure, runOnAborted)
	let l:toReturn = {}
	let l:toReturn.runOnSuccess = a:runOnSuccess
	let l:toReturn.runOnFailure = a:runOnFailure
	let l:toReturn.runOnAborted = a:runOnAborted
	let l:toReturn.targetIndex = a:targetIndex
	return l:toReturn
endfunction

function! s:newCommand(cmd, ...)
	let l:toReturn = {}
	let l:toReturn.command = a:cmd
	let l:toReturn.index = s:index
	let s:index = s:index + 1
	let l:toReturn.launchCondition = get(a:, 1, s:newCondition(-1, 0, 0, 0))
	let l:toReturn.successfull = -1
	let l:toReturn.external = 0

	if (a:cmd[0] == '!')
		let l:toReturn.command = a:cmd[1:]
		let l:toReturn.external = 1
		let l:toReturn.execData = s:newExecData()
	endif
	
	return l:toReturn
endfunction

function! s:isExternal(cmd)
	return (a:cmd.external)
endfunction

function! s:getTerminated(index)
	for cmd in s:compleatedList
		if (cmd.index == a:index)
			return cmd
		endif
	endfor
	return 0
endfunction

function! AQWasSuccessfull(index)
	let l:cmd = s:getTerminated(a:index)

	return (l:cmd.successfull == 1)
endfunction

function! AQGetExecutedSize()
	return len(s:compleatedList)
endfunction

function! AQWasCompleated(index)
	return (s:getTerminated(a:index).successfull != -2)
endfunction

function! s:canBeExecuted(command)
	let l:launchCondition = a:command.launchCondition
	let l:target = l:launchCondition.targetIndex

	if (l:launchCondition.runOnSuccess == 1 && !AQWasSuccessfull(l:target))
		return 0
	endif

	if (l:launchCondition.runOnFailure == 1 && AQWasSuccessfull(l:target))
		return 0
	endif

	if (!l:launchCondition.runOnAborted == !AQWasCompleated(l:target))
		return 0
	endif
	
	return 1
endfunction

function! s:addToCompleated(cmd, successState)
	let a:cmd.successfull = a:successState	
	call add(s:compleatedList, a:cmd)
endfunction

function! s:executeCommand(cmd)
	if (!s:canBeExecuted(a:cmd))
		call s:addToCompleated(a:cmd, -2)
		return 0
	endif

	if (!s:isExternal(a:cmd))
		exec a:cmd.command
		call s:addToCompleated(a:cmd, 1)
	else
		call s:runBackgroundCommand(a:cmd)	
	endif
endfunction

function! RunNext(timer)
	if (len(g:commandQueue) != 0 && !exists('g:cmd'))
		let s:command = g:commandQueue[0]
		let g:commandQueue = g:commandQueue[1:len(g:commandQueue)]

		call s:executeCommand(s:command)
	endif
endfunction

function! AQAppend(command)
	return AQAppendCond(a:command, 1, 0)
endfunction

function! AQAppendAbort(command, target)
	let l:cmd = s:newCommand(a:command, s:newCondition(a:target, 0, 0, 1))
	call add(g:commandQueue, l:cmd)
	return l:cmd.index
endfunction

function! AQAppendCond(command, ...)
	let l:outcomeExpected = get(a:, 1, -1)
	let l:targetIndex = get(a:, 2, s:index - 1)
	let l:c = s:newCondition(l:targetIndex, l:outcomeExpected, 1 - l:outcomeExpected, 0)
	let l:cmd = s:newCommand(a:command, l:c)
	call add(g:commandQueue, l:cmd)
	return l:cmd.index
endfunction

function! AQAppendOpen(...)
	let l:outcomeExpected = get(a:, 1, -1)
	let l:targetIndex = get(a:, 2, s:index - 1)
	let l:c = s:newCondition(l:targetIndex, l:outcomeExpected, 1 - l:outcomeExpected, 0)
	let l:cmd = s:newCommand("call s:openTarget(" . l:targetIndex . ")", l:c)
	call add(g:commandQueue, l:cmd)
	return l:cmd.index
endfunction

function! AQAppendOpenError(...)
	let l:target = get(a:, 1, s:index - 1)
	let l:outcomeExpected = get(a:, 1, -1)
	let l:targetIndex = get(a:, 2, s:index - 1)
	let l:c = s:newCondition(l:targetIndex, l:outcomeExpected, 1 - l:outcomeExpected, 0)
	let l:cmd = s:newCommand("call s:openErrorFile(".l:target.")", l:c)
	call add(g:commandQueue, l:cmd)
	return l:cmd.index
endfunction

function! s:openErrorFile(target)
	let s:file = s:getErrFileName(s:getTerminated(a:target))
	execute "vsp " . s:file
endfunction

function! s:openTarget(targetIndex)
	let l:cmd = s:getTerminated(a:targetIndex)
	exec "vsp " . l:cmd.execData.outFile
endfunction


" This callback will be executed when the entire command is completed
function! OnCompletion(job, exitStatus)
  let l:lastCommand = g:cmd
  let l:lastCommand.execData.outCode = a:exitStatus
  unlet g:cmd
  unlet g:job

  call s:addToCompleated(l:lastCommand, !a:exitStatus)
	
  if (a:exitStatus != 0)
	  echo "[FAILURE] ".l:lastCommand.command
  else
	  echo "[SUCCESS] ".l:lastCommand.command
  endif
endfunction

function! s:runBackgroundCommand(command)
  " Make sure we're running VIM version 8 or higher.
	if v:version < 800
		echoerr 's:runBackgroundCommand requires VIM version 8 or higher'
		return
	endif

	if exists('g:cmd')
		echo 'Already running task in background'
	else
		echo "[RUNNING] ".a:command.command
		" Notice that we're only capturing out, and not err here. This is because, for some reason, the callback
		" will not actually get hit if we write err out to the same file. Not sure if I'm doing this wrong or? 
		let g:cmd = a:command
		let s:errFile = s:getErrFileName(g:cmd)
		let s:outFile = g:cmd.execData.outFile
		let g:job = job_start(a:command.command, {'exit_cb': 'OnCompletion', 'out_io': 'file', 'err_io': 'file', 'err_name':s:errFile , 'out_name': s:outFile})
	endif
endfunction

function! AQKillJob()
	if (!exists('g:job'))
		echoerr "No pending job"		
		return
	endif
	call job_stop(g:job, "kill")
endfunction

function! AQTermJob()
	if (!exists('g:job'))
		echoerr "No pending job"		
		return
	endif
	call job_stop(g:job)
endfunction

function! s:appendCommand(buffer, cmd, extensive)
	if (!a:extensive)
		call appendbufline(a:buffer, line('$'), s:toString(a:cmd))	
	else
		call appendbufline(a:buffer, line('$'), string(a:cmd))
	endif
endfunction

function! s:showHistory(...)
	let l:all = get(a:, 1, 0)

	let l:buffer_number = bufnr('Async History')
	if (l:buffer_number != -1)
		execute "bw " . l:buffer_number
	endif

	let l:buffer_number = bufnr('Async History', 1)
	vsp
	execute "bu " .   l:buffer_number


	for cmd in s:compleatedList[1:len(s:compleatedList)]
		call s:appendCommand(l:buffer_number, cmd, l:all)
	endfor

	if (exists('g:cmd'))
		call s:appendCommand(l:buffer_number, g:cmd, l:all)
	endif

	for cmd in g:commandQueue
		call s:appendCommand(l:buffer_number, cmd, l:all)
	endfor

	call deletebufline(l:buffer_number, 1)
	setlocal nomodified
	setlocal syntax="AsyncHistory"
	setfiletype AsyncHistory
	call AsyncHistoryReloadHighlight()
endfunction

function! s:openErrorCommand()
	if (bufnr("%") != bufnr('Async History'))
		echoerr "You cannot do this outside of the AQ History Buffer"
		return
	endif

	if (!s:isExternal(s:getTerminated(line("."))))
		echoerr "You cannot open internal commands"
	endif
	
	call s:openErrorFile(line("."))	
	
endfunction

function! s:openCommand()
	if (bufnr("%") != bufnr('Async History'))
		echoerr "You cannot do this outside of the AQ History Buffer"
		return
	endif

	if (!s:isExternal(s:getTerminated(line("."))))
		echoerr "You cannot open internal commands"
	endif

	call s:openTarget(line("."))	
endfunction

command! -nargs=0 AQHistory call s:showHistory(0)
command! -nargs=0 AQInternalHistory call s:showHistory(1)
command! -nargs=0 AQClean call AQClean()
command! -nargs=0 AQKill call AQKillJob()
command! -nargs=0 AQOpenError call s:openErrorCommand()
command! -nargs=0 AQOpen call s:openCommand()

call AQClean()
