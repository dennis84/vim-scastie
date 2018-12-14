function! s:has_webapi()
  if !exists("*webapi#http#post")
    try
      call webapi#http#post()
    catch
    endtry
  endif
  return exists("*webapi#http#post")
endfunction

function! scastie#Run(count, line1, line2, ...) abort
  redraw

  let scastie_url = 'https://scastie.scala-lang.org'

  if !s:has_webapi()
    echohl ErrorMsg | echomsg ':Scastie depends on webapi.vim (https://github.com/mattn/webapi-vim)' | echohl None
    return
  endif

  let bufname = bufname('%')
  if a:count < 1
    let content = join(getline(a:line1, a:line2), "\n")
  else
    let save_regcont = @"
    let save_regtype = getregtype('"')
    silent! normal! gvy
    let content = @"
    call setreg('"', save_regcont, save_regtype)
  endif

  let payload = webapi#json#encode({
    \ 'code': content,
    \ 'libraries': [],
    \ 'librariesFromList': [],
    \ 'sbtConfigExtra': '',
    \ 'sbtPluginsConfigExtra': '',
    \ 'target': {'scalaVersion': '2.12.8', 'tpe': 'Jvm'},
    \ '_isWorksheetMode': function('webapi#json#true'),
    \ 'isShowingInUserProfile': function('webapi#json#false'),
    \ })

  let res = webapi#http#post(scastie_url.'/api/run', payload, {
    \ 'Content-Type': 'application/json',
    \ })

  let obj = webapi#json#decode(res.content)
  let url = printf('%s/%s', scastie_url, obj.base64UUID)

  redraw | echomsg 'Done: '.url
endfunction

command! -range=% Scastie :call scastie#Run(<count>, <line1>, <line2>, <f-args>)
