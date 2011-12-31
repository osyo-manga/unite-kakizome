scriptencoding utf-8

function! s:window(width, height, back)
	let self = {}

	let self.width  = a:width
	let self.height = a:height
	let self.back = a:back
	let self.code_size = len(a:back)/2+1
	let self.buffer = map(range(self.height), "join(map(range(self.width), 'self.back'), '')")

	function! self.get_line(y)
		return self.buffer[a:y]
	endfunction

	function! self.set_line(y, line)
		let self.buffer[a:y] = a:line
	endfunction

	function! self.dot(x, y, c)
		if 1 <= a:x && a:x <= self.width-2 && 1 <= a:y && a:y <= self.height-2
			call self.dot_over(a:x, a:y, a:c)
		endif
	endfunction

	function! self.dot_over(x, y, c)
		let line  = self.get_line(a:y)
		let left  = a:x > 0 ? line[ : a:x-1] : ""
		let right = a:y < self.width ? line[a:x+1 : ] : ""
		call self.set_line(a:y, left. a:c .right)
	endfunction

	function! self.reset()
		let width  = self.width
		let height = self.height
		for y in range(height)
			call self.set_line(y, join(map(range(self.width), 'self.back'), ''))
		endfor
		if self.code_size == 2
			let right  = "｜"
			let left   = "｜"
			let top    = "ー"
			let bottom = "ー"
			let point  = "＋"
		else
			let right  = "|"
			let left   = "|"
			let top    = "-"
			let bottom = "-"
			let point  = "+"
		endif
		call self.set_line(0, join(map(range(width), "top"), ""))
		call self.set_line(height-1, join(map(range(width), "bottom"), ""))
		for y in range(height)
			call self.dot_over(0, y, left)
			call self.dot_over(width-1, y, right)
		endfor
		call self.dot_over(0, 0, point)
		call self.dot_over(width-1, 0, point)
		call self.dot_over(width-1,height-1,  point)
		call self.dot_over(0, height-1, point)
	endfunction
	call self.reset()
	
	function! self.buffer_copy()
		return deepcopy(self.buffer)
	endfunction

	return self
endfunction


function! unite#sources#kakizome#define()
	return s:source
endfunction

let s:source = {
\	"name" : "kakizome",
\	"description" : "kakizome",
\	"syntax" : "uniteSource_kakizome",
\	"hooks" : {},
\	"kakizome" : {}
\}

let s:source.hooks.source = s:source


function! s:source.hooks.on_init(args, context)
	let self.source.kakizome.black = ","
	let self.source.kakizome.white = "_"

	let code_size = len(self.source.kakizome.black)/2+1
	let width  = winwidth(0)/code_size-8/code_size
	let height = winheight(0) - 5

	let self.source.kakizome.window = s:window(width, height, self.source.kakizome.white)
	call map(self.source.kakizome.window.buffer, '{"word" : v:val, "dummy" : 1}')
	let self.source.kakizome.window.kakizome = self.source.kakizome

	function! self.source.kakizome.window.get_line(y)
		return self.buffer[a:y].word
	endfunction

	function! self.source.kakizome.window.set_line(y, line)
		let self.buffer[a:y].word = a:line
	endfunction
	function! self.source.kakizome.window.on_click(x, y, button)
		let offset ={}
		let offset.x = 5
		let offset.y = 3
		let x = (a:x-offset.x)/self.code_size
		let y = (a:y-offset.y)
		let color = a:button == "left" ? self.kakizome.black : self.kakizome.white
		call self.dot(x, y, color)
		call self.dot(x-1, y, color)
	endfunction

endfunction


function! s:draw_paint(window, button)
	let cursor = getpos(".")
	call a:window.on_click(cursor[2], cursor[1], a:button)
endfunction

function! s:source.hooks.on_syntax(args, context)
	syntax clear
	execute "syntax match black /".self.source.kakizome.black."/ containedin=uniteSource_kakizome"
	highlight black ctermfg=black ctermbg=black guibg=black guifg=black
	execute "syntax match white /".self.source.kakizome.white."/ containedin=uniteSource_kakizome"
	highlight white ctermfg=white ctermbg=white guibg=white guifg=white

	let b:unite_kakizome_window = self.source.kakizome.window

	nnoremap <silent><buffer> 1 :call b:unite_kakizome_window.reset()<CR>

	nnoremap <silent><buffer> <LeftMouse>
		\ <LeftMouse>:call <SID>draw_paint(b:unite_kakizome_window, "left")<CR>
	nnoremap <silent><buffer> <LeftDrag>
		\ <LeftMouse>:call <SID>draw_paint(b:unite_kakizome_window, "left")<CR>
	nnoremap <silent><buffer> <LeftRelease>
		\ <LeftMouse>:call <SID>draw_paint(b:unite_kakizome_window, "left")<CR>

	nnoremap <silent><buffer> <RightMouse>
		\ <LeftMouse>:call <SID>draw_paint(b:unite_kakizome_window, "right")<CR>
	nnoremap <silent><buffer> <RightDrag>
		\ <LeftMouse>:call <SID>draw_paint(b:unite_kakizome_window, "right")<CR>
	nnoremap <silent><buffer> <RightRelease>
		\ <LeftMouse>:call <SID>draw_paint(b:unite_kakizome_window, "right")<CR>

	highlight clear Visual
	highlight clear Cursor
" 	highlight visual ctermfg=white ctermbg=white guibg=white guifg=white

endfunction


function! s:source.async_gather_candidates(args, context)
	let a:context.source.unite__cached_candidates = []
	return self.kakizome.window.buffer
endfunction

