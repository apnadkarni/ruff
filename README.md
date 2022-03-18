# Ruff! documentation generator

Ruff! (Runtime function formatter) is a documentation generation system
for programs written in the Tcl programming language. Ruff! uses runtime
introspection in conjunction with comment analysis to generate reference
documentation for Tcl programs with minimal effort on the programmer's part.

See https://ruff.magicsplat.com for features and reference documentation.

For additional examples of Ruff! generated documentation, see

[iocp](https://iocp.magicsplat.com),
[cffi](https://cffi.magicsplat.com),
[CAWT](http://www.cawt.tcl3d.org/download/CawtReference.html),
[apave](https://aplsimple.github.io/en/tcl/pave/apave.html),
[baltip](https://aplsimple.github.io/en/tcl/baltip/baltip.html),
[hl-tcl](https://aplsimple.github.io/en/tcl/hl_tcl/hl_tcl.html),
[tcl-promise](https://tcl-promise.magicsplat.com),
[obex](https://tcl-obex.magicsplat.com),
[Woof!](http://woof.sourceforge.net/woof-ug-0.5/html/_woof/woof_manual.html)
and
[tcl-vix](https://tcl-vix.magicsplat.com/).


## Release notes for 2.2

* Support for embedded text formatted diagrams (ditaa, PlantUML etc.)
* Alignment and captions for fenced blocks.
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



See https://ruff.magicsplat.com/ruff.html#History.

NOTE 2.0 HAS SEVERAL INCOMPATIBILITIES VIS-A-VIS 1.x IN OPTIONS AND GENERATED
OUTPUT FORMAT. See above link for details.
