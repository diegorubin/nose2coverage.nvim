# nose2coverage.nvim

## Requirements

- Neovim 0.4.4+

This project uses part of [https://github.com/manoelcampos/xml2lua](https://github.com/manoelcampos/xml2lua).

## Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim).

```
use {'diegorubin/nose2coverage.nvim'}
```

## Settings

```
require'nose2coverage'.setup {
    coverage_report = "./coverage.xml"
}
```

## Commands

- __Nose2CoverageDisplay__: Show coverage with signs
- __Nose2CoverageHide__: Hide coverage signs
