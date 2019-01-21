highlight AsyncHistorySuccess ctermfg=Green guifg=Green

highlight AsyncHistoryFailure ctermfg=Red guifg=Red

highlight AsyncHistoryAborted ctermfg=Blue guifg=Blue

highlight AsyncHistoryPending ctermfg=Yellow guifg=Yellow

function AsyncHistoryReloadHighlight()
	syn keyword AsyncHistorySuccess SUCCESS
	syn keyword AsyncHistoryFailure FAILURE
	syn keyword AsyncHistoryAborted ABORTED
	syn keyword AsyncHistoryPending PENDING
endfunction


