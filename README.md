# ruff

Ruff! (Runtime function formatter) is a documentation generation system
for programs written in the Tcl programming language. Ruff! uses runtime
introspection in conjunction with comment analysis to generate reference
manuals for Tcl programs with minimal effort on the programmer's part.

See https://ruff.magicsplat.com for benefits and reference documentation. 

## Changelog

This release is **not** compatible with Ruff! releases prior to 0.9 due
to the following changes.

* Added optional multifile output to split documentation on a namespace basis.
* Added formatter for markdown output.
* Output formatters for robodoc, naturaldocs and doctools have been removed.
This last may be added back in a future release on demand.
**Incompatibility**
* Support added for inline markdown markup within comments.
* Support added for documenting ensemble commands.
* Support for a *See also* section.
* Auto-linking of program elements removed. Use \[\] to link symbols or use the *See also* feature. *Incompatibility*
* Variable references beginning with `$` within comments are formatted as such.
* List element continuation is different, particularly with respect to leading
whitespace. *Incompatibility*
* The use of `_ruffdoc` is deprecated. Use _ruff_preamble instead.
* Requires Tcl 8.6. 8.4/8.5 are not supported. *Incompatibility* Note this does not mean you cannot use Ruff! to document packages that support those versions!
