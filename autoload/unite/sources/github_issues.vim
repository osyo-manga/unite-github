scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of("unite_github")
let s:JSON = s:V.import("Web.JSON")
let s:Reunions = s:V.import("Reunions")


function! s:get_github(request_url, ...)
	let data = get(a:, 1, {})
	return s:Reunions.http_get(a:request_url, data)
endfunction


function! s:issues(user, repos, ...)
	let data = get(a:, 1, {})
	let request_url = printf("https://api.github.com/repos/%s/%s/issues", a:user, a:repos)
	return s:get_github(request_url, data)
endfunction


function! s:issues_all(user, repos, ...)
	let data = extend({ "state" : "all", "per_page" : 100 }, get(a:, 1, {}))
	return s:issues(a:user, a:repos, data)
endfunction


function! unite#sources#github_issues#define()
	return s:source
endfunction


let s:source = {
\	"name" : "github/issues",
\	"description" : "github issues list.",
\	"hooks" : {},
\	"count" : 0,
\}
let s:source.hooks.parent = s:source


function! s:source.hooks.on_init(args, context)
	let pat = '^\([^/]\+\)/\?\([^/]*\)$'
	if empty(a:args) || a:args[0] !~ pat
		return unite#print_source_message("Plase input argument.\ne.g. :Unite github/issues:osyo-manga/vim-over", "github/issues")
	endif
	let parsed = matchlist(a:args[0], pat)
	let self.parent.source__response = s:issues_all(parsed[1], parsed[2])
	let self.parent.count = 0
endfunction


function! s:source.hooks.on_close(args, context)
	if has_key(self.parent, "source__response")
		call self.parent.source__response.kill(1)
		unlet self.parent.source__response.kill
	endif
endfunction


function! s:source.async_gather_candidates(args, context)
	if !has_key(self, "source__response")
		let a:context.is_async = 0
		return [
\			{ "word" : "Plase input argument."},
\			{ "word" : "e.g. :Unite github/issues:osyo-manga/vim-over" }
\		]
	endif

	let a:context.source.unite__cached_candidates = []
	call self.source__response.update()
	if !self.source__response.is_exit()
		let self.count += 1
		return [{ "word" : "[untie-github/issues] github/issues:" . a:args[0] . " download" . repeat(".", self.count % 5) }]
	endif

	let a:context.is_async = 0
	let content = s:JSON.decode(self.source__response.get().content)
	return map(content, '{
\		"word" : (v:val.state == "open" ? "* " : "  ") .  "#" . v:val.number . " " . v:val.title,
\		"action__path" : v:val.html_url,
\		"kind" : "uri",
\		"default_action" : "start",
\	}')
endfunction


if expand("%:p") == expand("<sfile>:p")
	call unite#define_source(s:source)
endif


let &cpo = s:save_cpo
unlet s:save_cpo
