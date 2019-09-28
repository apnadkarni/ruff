# Ruff! documentation generator

Ruff! (Runtime function formatter) is a documentation generation system
for programs written in the Tcl programming language. Ruff! uses runtime
introspection in conjunction with comment analysis to generate reference
documentation for Tcl programs with minimal effort on the programmer's part.

See https://ruff.magicsplat.com for features and reference documentation. 

## Release notes for 1.0b3

**NOTE:** V1.0 releases are **not** compatible with Ruff! releases prior to 0.9.

## Changes since 1.0b2

* Added -sortnamespaces option

## Changes since 1.0b1

* Added -navigation option to change position and width of navigation pane.
* Added -compact option to generate a more compact form of documentation. 

## Changes since 0.6

* The API has been reduced to a single new command `document`.
* Support for inline markdown formatting.
* Optional multifile output to split documentation on a namespace basis.
* Formatter for markdown output.
* Output formatters for robodoc, naturaldocs and doctools have been removed.
This last may be added back in a future release on demand.
*Incompatibility*
* Support for documenting ensemble commands.
* Support for a *See also* section.
* Auto-linking of program elements removed. Use \[\] to link symbols or use the *See also* feature. *Incompatibility*
* Variable references beginning with `$` within comments are formatted as such.
* List element continuation is different, particularly with respect to leading
whitespace. *Incompatibility*
* The use of `_ruffdoc` is deprecated. Use `_ruff_preamble` instead.
* Requires Tcl 8.6. 8.4/8.5 are not supported. *Incompatibility* Note this does not mean you cannot use Ruff! to document packages that support those versions!
