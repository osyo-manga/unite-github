scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:HTTP = vital#of("unite_github").import("Web.HTTP")
let s:JSON = marching#vital().import("Web.JSON")

function! s:get_github(request_url, ...)
	let data = get(a:, 1, {})
	let default = get(a:, 2, [])
	let result = s:HTTP.get(a:request_url, data)
	if result.success != 1
		return default
	endif
	let content = s:JSON.decode(result.content)
	return content
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


function! s:errormsg(str)
	echohl Error
	echo "unite-github :" . a:str
	echohl NONE
endfunction



function! unite#sources#github_issues#define()
	return s:source
endfunction


let s:source = {
\	"name" : "github/issues",
\	"description" : "github issues list.",
\}


function! s:source.gather_candidates(args, context)
	let pat = '^\([^/]\+\)/\?\([^/]*\)$'
	if empty(a:args) || a:args[0] !~ pat
		call s:errormsg("Plase input argument.\ne.g. :Unite github/issues:osyo-manga/vim-over")
		return []
	endif
	let parsed = matchlist(a:args[0], pat)
	let content = s:issues_all(parsed[1], parsed[2])
	return map(content, '{
\		"word" : (v:val.state == "open" ? "* " : "  ") .  "#" . v:val.number . " " . v:val.title,
\		"action__path" : v:val.html_url,
\		"kind" : "uri",
\		"default_action" : "start",
\	}')
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo
