# Ruff! documentation generator

Ruff! (Runtime function formatter) is a documentation generation system
for programs written in the Tcl programming language. Ruff! uses runtime
introspection in conjunction with comment analysis to generate reference
documentation for Tcl programs with minimal effort on the programmer's part.

See https://ruff.magicsplat.com for features and reference documentation.

For additional examples of Ruff! generated documentation, see
[CAWT](http://www.cawt.tcl3d.org/download/CawtReference.html),
[iocp](https://iocp.magicsplat.com),
[tcl-promise](https://tcl-promise.magicsplat.com/#::promise::ptask),
[Woof!](http://woof.sourceforge.net/woof-ug-0.5/html/_woof/woof_manual.html)
and
[tcl-vix](https://tcl-vix.magicsplat.com/).

## Release notes for 1.2.0

* Feature: The -locale option will look up message catalogs for built-in
section headings.

* Bug fix: Fixed OO constructor synopsis.

* Bug fix: Fixed background color width for pre-formatted sections.

## Release notes for 1.1.0

* Feature: For multipage output an index page is produced which allows for
a quick search across all documentation pages. Controlled by the 
`-makeindex` option which defaults to true for multipage output.
See 
[this](https://iocp.magicsplat.com/iocp_docindex.html) for an example.

* Bug fix: Do not include TclOO built-in methods when -includeprivate option
is specified.


## Release notes for 1.0.5

**NOTE:** V1.0 releases are **not** compatible with Ruff! releases prior to 0.9.

## Changes since 1.0.4

* Bug fix: link collision for non-alphanumeric single character method names.

## Changes since 1.0b3

* Added sticky options to -navigation to control navigation box scrolling.
* Permit Markdown links in See Also sections.
* Permit alternative display text when linking to program symbols.
* Added -stylesheets option to use non-default styles.

Fixes:

* Include forwarded methods in ToC
* Fix links to preamble section headings.

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
