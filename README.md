# epitech-norm package
###### By [Matthieu Kern](mailto:matthieukern@gmail.com)

## Use
* To activate the norm-compliant style, use the `epitech-norm:enable` command.
* To disable it, use the `epitech-norm:disable` command.
* Some commands are given so you can bind it to other keys :
  * `epitech-norm:indent`: Indent the current line.
  * `epitech-norm:insertTab`: Insert a tab (initially bind to `alt-i`).
  * `epitech-norm:newLine`: Insert a new line (need some work on it).
* To check the norm, you can use the `epitech-norm:checkNorm` command. All errors aren't detected yet.

## Config
* Auto Activate On C Source: Auto activate the norm-compliant style on C source files.
* Auto Check Norm: Auto activate the norm linter. Warning, this option could slow down your editor, some optimizations are still necessary.

## Todo
* Fix the new line command to be more user friendly.
* Detect missing norm errors on .c source files.
* Detect errors on .h source files.
* Adapt the plugin to Makefiles.
* Add some snippets.
