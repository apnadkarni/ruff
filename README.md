# Ruff! documentation generator

Ruff! (Runtime function formatter) is a documentation generation system
for programs written in the Tcl programming language. Ruff! uses runtime
introspection in conjunction with comment analysis to generate reference
documentation for Tcl programs with minimal effort on the programmer's part.

## Why Ruff!

Ruff! produces documentation that not only requires less duplication
of effort from the programmer, but is also more complete, more
accurate and more maintainable.

* Comments in source code do not have to be reproduced for documentation
purposes.

* Ruff! requires minimal markup in the comments making it lightweight
as well as reducing clutter.

* Supports inline formatting using Markdown syntax.

* Embedded diagrams in multiple formats

* Program elements like command arguments, defaults and
class relationships like inheritance are automatically derived.

* Maintenance is less of a burden as documentation is automatically
updated with source modification such as changes to defaults, addition of
mix-ins etc.

On the output side,

* Ruff! supports multiple formats (HTML, Markdown, reStructuredText, Asciidoc
and nroff).

* Generated documentation can optionally be split across multiple pages.

* Hyperlinks between program elements, and optionally source code,
make navigation easy and efficient.

* A table of contents and optional searchable index permits quick
location of command and class documentation.

* Class relationships are extracted and the full API for a class, with inherited
and mixed-in methods and properties, is flattened and summarized.

* HTML output supports navigation and user-selectable themes.

See https://ruff.magicsplat.com for features and reference documentation.

For additional examples of Ruff! generated documentation, see

[iocp](https://iocp.magicsplat.com),
[cffi](https://cffi.magicsplat.com),
[CAWT](http://www.cawt.tcl3d.org/download/CawtReference.html),
[MAWT](https://www.tcl3d.org/mawt/download/MawtReference.html),
[PAWT](https://www.tcl3d.org/pawt/download/PawtReference.html),
[SpiceGenTcl](https://georgtree.github.io/SpiceGenTcl/),
[apave](https://aplsimple.github.io/en/tcl/pave/apave.html),
[baltip](https://aplsimple.github.io/en/tcl/baltip/baltip.html),
[hl-tcl](https://aplsimple.github.io/en/tcl/hl_tcl/hl_tcl.html),
[tcl-promise](https://tcl-promise.magicsplat.com),
[tomato](https://nico-robert.github.io/tomato/),
[obex](https://tcl-obex.magicsplat.com),
[Woof!](http://woof.sourceforge.net/woof-ug-0.5/html/_woof/woof_manual.html)
and
[tcl-vix](https://tcl-vix.magicsplat.com/).

## Release notes for 3.0

Note this is a major release and there may be subtle incompatibilities with
2.x releases in both parsing of input and generated output.

* New output formats reStructuredText (Sphinx) and Asciidoc
* Support for numbered lists
* Support for block quotes
* Support for tables
* Support for HTML entities
* Include OO class methods in documentation
* Provision for class preambles, oo::configurable property descriptions and
  Tk-like option documentation via the `_ruffClassHook_` 
  method (Tcl 9 only)
* Customizatble namespace headings
* Customizable per-namespace options
* New `-onlyexports` option to only document exported commands
* Tcl core built-ins are ignored when documenting global namespace (bugfix)

## Release notes for 2.7

* Added a copy button for fenced blocks (thanks @nico-robert).

## Release notes for 2.6

* Added `#ruff includeformatters|excludeformatters` directives to include or
exclude content for specific formatters (thanks to George Yashin).

## Release notes for 2.5

* Better documentation of TclOO properties to include custom
setter/getter descriptions
* Bug fixes in nroff output.

## Release notes for 2.4

* Support for TclOO properties in Tcl 9
* Support for language specifier in fenced blocks

## Release notes for 2.3

* Collapsible details section for procedure description option when
`-compact 1` is specified. Note generated output with `-compact 1` has changed.
* Bug fix. Ensure diagrams fit in page width
* Bug fix. Index page tooltip synopsis visibility in dark themes.

## Release notes for 2.2

* Support for embedded text formatted diagrams (ditaa, PlantUML etc.)
* Alignment and linkable numbered captions for fenced blocks and diagrams.
* Fixed minor display artifacts.

## Release notes for 2.1

This release mainly has cosmetic changes in presentation.

* Ensemble command includes table to subcommands.
* Show command synopsis in navigation pane tooltip.
* Tweaks to themes and navigation.
* Bug fix: broken link to index page.

## Release notes for 2.0

* Added Nroff formatter for Unix manpages.
* Added themes with end-user selection.
* Added end-user control for positioning navigation pane.
* Classes defined with metaclasses are recognized.
* Proc and method synopsis overrides, for example
  to distinguish invocation options.
* Web assets are linked by default (option `-linkassets`) instead
  of being embedded.
* **Incompatibility:** Generated HTML and CSS templates have changed
  and require modern browsers (no Internet Explorer support).
* **Incompatibility:** The `-stylesheets` option is not supported.
* **Incompatibility:** The `-navigation` option only takes `scrolled`
  `sticky` as valid values.
* **Incompatibility:** The `-output` option is not supported. Use
  `-outfile` and `-outdir` instead.
* **Incompatibility:** Output file names use hyphen as a separator
  instead of underscore.
* [Bug fixes](https://github.com/apnadkarni/ruff/issues?q=is%3Aissue+is%3Aclosed+milestone%3Av2.0+label%3Abug)


NOTE 2.0 HAS SEVERAL INCOMPATIBILITIES VIS-A-VIS 1.x IN OPTIONS AND GENERATED
OUTPUT FORMAT. See above Release notes for 2.0.
