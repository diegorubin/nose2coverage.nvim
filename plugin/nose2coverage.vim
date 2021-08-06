augroup Nose2Coverage
  autocmd!
augroup end

command! Nose2CoverageDisplay lua require'nose2coverage'.display()
command! Nose2CoverageHide lua require'nose2coverage'.hide()
