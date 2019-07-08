# ruff
Documentation generator for Tcl

## Changes since V0.5

The following changes have been made since Ruff! 0.5:

* Added multifile output to split documentation on a namespace basis.
* Added formatter for markdown output.
* Output formatters for robodoc, naturaldocs and doctools have been removed.
It is likely that doctools support will be added back in a future release.
**Incompatibility**
* Support added for inline markdown markup within comments.
* Support added for documenting ensemble commands.
* Auto-linking of program elements removed. Use \[\] to link symbols. *Incompatibility*
* Variable references beginning with `$` within comments are formatted as such.
* List element continuation is different. See documentation. *Incompatibility*
* The format of `_ruffdoc` contents has changed. See the documentation. *Incompatibility*
* Requires Tcl 8.6. 8.4/8.5 are not supported. *Incompatibility*
