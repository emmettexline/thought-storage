if exists('g:loaded_thought_store') | finish | endif
let g:loaded_thought_store = 1

" Commands
command! ST lua require('thought_store').save_thought()
command! B lua require('thought_store').browse()
