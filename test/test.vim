function! TestAQClean()
	call AQAppend("echo 'tesing aq clean'")
	call AQAppend("call TestAQCleanFinalizer()")
endfunction

function! TestAQCleanFinalizer()
	call AQClean()

	if (AQGetExecutedSize() != 1)
		echoerr "Test AQClean failed " . AQGetExecutedSize()
	else
		echo "Test AQClean success"
	endif
endfunction

function! TestAQGetExecutedSize()
	call AQClean()
	if (AQGetExecutedSize() != 1)
		echoerr "Test AQGetExecutedSize failed "  . AQGetExecutedSize()
	endif

	call AQAppend("echo 'testing aq size'")
	call AQAppend("call TestAQGetExecutedSizeFinalizer()")
endfunction

function! TestAQGetExecutedSizeFinalizer()
	if (AQGetExecutedSize() != 2)
		echoerr "TestAQGetExecutedSize failed " . AQGetExecutedSize()
	else
		echo "Test AQGetExecutedSize success"
	endif
endfunction

function! TestAQWasSuccessfull()
	let l:t = AQAppend("!echo hello world")
	call AQAppend("call ExpectSuccesfull(".l:t.")")

	let l:t = AQAppend("!false")
	call AQAppend("call ExpectUnsuccesfull(".l:t.")")
endfunction

function! ExpectUnsuccesfull(target)
	if (AQWasSuccessfull(a:target))
		echoerr "expected target failure but was a success"
		return
	endif
	echo "Test AQWasSuccessfull success"
endfunction

function! ExpectSuccesfull(target)
	if (!AQWasSuccessfull(a:target))
		echoerr "expected target succesfull but was not"
		return
	endif
	echo "Test AQWasSuccessfull success"
endfunction

function! TestAQWasCompleated()
	call AQClean()

	let l:t = AQAppend("!echo hello world")
	call AQAppend("call ExpectTerminated(" . l:t . ")")

	let l:t = AQAppend("!false")
	let l:t = AQAppendCond("echo 'should not be called'", 1)
	call AQAppend("call ExpectedAborted(".l:t.")")
endfunction

function! ExpectTerminated(target)
	if (!AQWasCompleated(a:target))
		echoerr "Expected task compleated but was not"
		return
	endif
	echo "task succesfully terminated"
endfunction

function! ExpectedAborted(target)
	if (AQWasCompleated(a:target))
		echoerr "Expected task aborted but was not"
		return 
	endif
	echo "task intentionally aborted"
endfunction

function! TestAQAppendOnAbort()
	call AQClean()
	let l:t = AQAppend("!false")
	let l:t = AQAppendCond("echo 'should not be called'", 1)	
	let l:t = AQAppendAbort("echo 'test append abort succesfull'", l:t)
	call AQAppendCond("echoerr 'failed on abort test'", 0, l:t)
endfunction

function! TestAQAppendCond()
	call AQClean()
	let l:t = AQAppend("!false")
	call AQAppendCond("echoerr 'this should not be called'", 1)
	let l:t = AQAppendCond("echoerr 'this should not be called'", 1, l:t)
	call AQAppendCond("echoerr 'this should not be called'", 0)
	call AQAppendCond("echoerr 'this should not be called'", 0, l:t)
	call AQAppendCond("echoerr 'this should not be called'", 1, l:t)
endfunction

function! TestAQAll()
	call TestAQClean()
	call TestAQGetExecutedSize()
	call TestAQWasSuccessfull()
	call TestAQWasCompleated()
	call TestAQAppendOnAbort()
	call TestAQAppendCond()
endfunction
