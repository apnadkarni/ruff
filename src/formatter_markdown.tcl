# Copyright (c) 2019, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the source root directory for license.

# Ruff! formatter for markdown
# For compiling generated markdown to html using pandoc:
#   pandoc -s -o ruff.html -c ../ruff-md.css --metadata pagetitle="My package" ruff.md
# For compiling generated markdown to manpages using pandoc
#   pandoc ruff_ruff.md -s -t man -o ruff.man
#   dos2unix ruff.man
#   tbl ruff.man | man -l -

namespace eval ruff::formatter {}

oo::class create ruff::formatter::Markdown {
    superclass ::ruff::formatter::Formatter

    # Data members
    variable Document;        # Current document
    variable DocumentNamespace; # Namespace being documented
    variable Header;          # Common header
    variable Footer;          # Common footer
    variable HeaderLevels;    # Header levels for various headers

    # NOTE: NavigationLinks are currently recorded but not used since
    # there is no standard way to have a navigation pane or ToC in
    # Markdown without resorting to HTML.
    variable NavigationLinks; # Navigation links forming ToC

    constructor args {
        set HeaderLevels {
            class 3
            proc 4
            method 4
            nonav 5
            parameters 5
        }
        next {*}$args
    }

    method Anchor args {
        # Construct an anchor from the passed arguments.
        #  args - String from which the anchor is to be constructed.
        # The anchor is formed by joining the passed strings with separators.
        # Empty arguments are ignored.
        # Returns an HTML-escaped anchor without the `#` prefix.
        return [make_id {*}$args]
    }

    method HeadingReference {ns heading} {
        # Implements the [Formatter.HeadingReference] method for Markdown.
        return "[ns_file_base $ns .html]#[my Anchor $ns $heading]"
    }

    method SymbolReference {ns symbol} {
        # Implements the [Formatter.SymbolReference] method for Markdown.
        set ref [ns_file_base $ns .html]
        # Reference to the global namespace is to the file itself.
        if {$ns eq "::" && $symbol eq ""} {
            return $ref
        }
        return [append ref "#[my Anchor $symbol]"]
    }

    method FigureReference {ns caption} {
        # Implements the [Formatter.FigureReference] method for Markdown.
        return "[ns_file_base $ns .html]#[my Anchor $ns $caption]"
    }

    method Begin {} {
        # Implements the [Formatter.Begin] method for HTML.

        next

        # Generate the header used by all files
        # Currently, it is empty but might change in the future with
        # support for specific dialects which implement metainformation.
        set Header ""
        set titledesc [my Option -title]

        # Generate the Footer used by all files
        set Footer ""
        if {[my Option? -copyright copyright]} {
            append Footer "\n\n---\n\\(c) [my Escape $copyright]\n"
        }
        return
    }

    method DocumentBegin {ns} {
        # See [Formatter.DocumentBegin].
        # ns - Namespace for this document.

        next $ns

        set    NavigationLinks [dict create]
        set    Document $Header
        set    DocumentNamespace $ns

        return
    }

    method DocumentEnd {} {
        # See [Formatter.DocumentEnd].

        # Add the navigation bits and footer
        my Navigation $DocumentNamespace
        append Document $Footer

        set doc $Document
        set Document ""

        next

        return $doc
    }

    method AddAnchor {anchor} {
        # Adds an anchor (link target) to the document 
        #  anchor - The anchor id to add
        append Document "<a id='" $anchor "'></a>"
        return
    }

    method AddProgramElementHeading {type fqn {tooltip {}} {synopsis {}}} {
        # Adds heading for a program element like procedure, class or method.
        #  type - One of `proc`, `class` or `method`
        #  fqn - Fully qualified name of element.
        #  tooltip - The tooltip lines, if any, to be displayed in the navigation pane.
        # In addition to adding the heading to the document, a link
        # is also added to the collection of navigation links.
        set level    [dict get $HeaderLevels $type]
        set atx      [string repeat # $level]
        set ns       [namespace qualifiers $fqn]
        set anchor   [my Anchor $fqn]
        set linkinfo [dict create tag h$level href "#$anchor"]
        if {[llength $tooltip]} {
            set tip "[my FormatInline [string trim [join $tooltip { }]] $ns]\n"
            dict set linkinfo tip $tip
        }
        set name [namespace tail $fqn]
        dict set linkinfo label $name
        dict set NavigationLinks $anchor $linkinfo
        append Document "\n$atx <a name='$anchor'></a>"
        if {[string length $ns]} {
            set ns_link [my FormatInline [markup_reference $ns]]
            append Document \
                [my Escape [namespace tail $name]] \
                " \[${ns_link}\]\n"
        } else {
            append Document [my Escape $name] "\n"
        }
        return
    }

    method AddHeading {level text scope {tooltip {}}} {
        # See [Formatter.AddHeading].
        #  level   - The numeric or semantic heading level.
        #  text    - The heading text.
        #  scope   - The documentation scope of the content.
        #  tooltip - Tooltip to display in navigation link.

        if {![string is integer -strict $level]} {
            set level [dict get $HeaderLevels $level]
        }
        set do_link [expr {$level >= [dict get $HeaderLevels nonav] ? false : true}]
        set atx [string repeat # $level]

        if {$do_link} {
            set anchor [my Anchor $scope $text]
            set linkinfo [dict create tag h$level href "#$anchor"]
            if {$tooltip ne ""} {
                set tip "[my FormatInline [join $tooltip { }] $scope]\n"
                dict set linkinfo tip $tip
            }
            dict set linkinfo label $text
            dict set NavigationLinks $anchor $linkinfo
            # NOTE: <a></a> empty because the text itself may contain anchors.
            set heading "<a name='$anchor'></a>[my FormatInline $text $scope]"
        } else {
            set heading [my FormatInline $text $scope]
        }
        append Document "\n" $atx " " $heading "\n"
        return
    }

    method AddParagraph {lines scope} {
        # See [Formatter.AddParagraph].
        #  lines  - The paragraph lines.
        #  scope - The documentation scope of the content.
        append Document "\n" [my FormatInline [join $lines \n] $scope] "\n"
        return
    }

    method AddBlockquote {lines scope} {
        # See [Formatter.AddBlockquote].
        #  lines  - The paragraph lines.
        #  scope - The documentation scope of the content.

        # Paragraphs may be separated by blanks lines within
        # a single block quote

        append Document \n [join [lmap line $lines {
            string cat "> " [my FormatInline $line]
        }] \n]

    }

    method AddDefinitions {definitions scope {preformatted none}} {
        # See [Formatter.AddDefinitions].
        #  definitions  - List of definitions.
        #  scope        - The documentation scope of the content.
        #  preformatted - One of `none`, `both`, `term` or `definition`
        #                 indicating which fields of the definition are
        #                 are already formatted.

        if {0} {
            # This does not escape <> properly. Moreover, cmark seems
            # to handle `` within html tags differently depending on whether
            # the tag is (e.g.) <b> or <td>
            append Document "\n<table><tbody>\n"
            foreach item $definitions {
                set def [join [dict get $item definition] " "]
                # Note: since we are generating raw HTML here, we have to
                # use ToHtml and not FormatInline here. Huh? TBD
                if {$preformatted in {none term}} {
                    set def [my FormatInline $def $scope]
                }
                set term [dict get $item term]
                if {$preformatted in {none definition}} {
                    set term [my FormatInline $term $scope]
                }
                append Document "<tr><td>" \
                    $term \
                    "</td><td>" \
                    $def \
                    "</td></tr>\n"
            }
            append Document "</tbody></table>\n"
        } else {
            # Note: CommonMark does not recognize tables without a heading line
            # TBD - how do empty headers look in generated HTML?
            append Document "\n|||\n|----|----|\n"
            foreach item $definitions {
                set def [join [dict get $item definition] " "]
                if {[my Option -autopunctuate 0]} {
                    set def [string toupper $def 0 0]
                    if {[regexp {[[:alnum:]]} [string index $def end]]} {
                        append def "."
                    }
                }
                if {$preformatted in {none term}} {
                    set def [my FormatInline $def $scope]
                }
                set term [dict get $item term]
                if {$preformatted in {none definition}} {
                    set term [my FormatInline $term $scope]
                }
                append Document "|$term|$def|\n"
            }
            append Document "\n"
        }
        return
    }

    method AddTable {table scope} {
        # Adds a table to document content.
        #  table  - Dictionary describing table
        #  scope  - The documentation scope of the content.
        # See [Formatter.AddTable].
        # The table dictionary has keys `lines`, `rows` and optionally `header`,
        # `alignments` containing the raw lines, a list of cell content, header row,
        # and a list of cell alignments respectively.

        # Markdown->Markdown. Just spit out the original lines
        append Document \n [join [dict get $table lines] \n] \n
    }

    method AddBullets {content scope} {
        # See [Formatter.AddBullets].
        #  content  - Dictionary with keys items and marker
        #  scope    - The documentation scope of the content.
        append Document "\n"
        foreach lines [dict get $content items] {
            append Document [dict get $content marker] " " \
                [my FormatInline [join $lines { }] $scope] \
                \n
        }
        append Document "\n"
        return
    }

    method AddPreformattedText {text scope} {
        # See [Formatter.AddPreformattedText].
        #  text  - Preformatted text.
        #  scope - The documentation scope of the content.
        append Document "\n```\n$text\n```\n"
        return
    }

    method AddFenced {lines fence_options scope} {
        # See [Formatter.AddFenced].
        # Adds a list of fenced lines to document content.
        #  lines - Preformatted text as a list of lines.
        #  fence_options - options specified with the fence, e.g. diagram ...
        #  scope - The documentation scope of the content.
        # Only obeys -caption option, ignores all else

        # Do not hardcode fence since the lines may themself contain something
        # that looks like a fence.
        set fence [dict get $fence_options Fence]
        set lang [dict get $fence_options Language]
        append Document \n $fence$lang \n [join $lines \n] \n $fence \n
        if {[dict exists $fence_options -caption]} {
            append Document \n\n* [dict get $fence_options -caption] *\n\n
        }

        return
    }

    method AddSynopsis {synopsis scope} {
        # Adds a Synopsis section to the document content.
        #  synopsis - List of alternating elements comprising the command portion
        #             and the parameter list for it.
        #  scope  - The documentation scope of the content.

        append Document \n
        foreach {cmds params} $synopsis {
            # pandoc gets confused with the *``* sequence so distinguish the
            # no params case.
            # Also note the two spaces before the newline. Otherwise, markdown
            # processors will combine the lines.
            if {[llength $params]} {
                append Document "> `[join $cmds { }]` *`[join $params { }]`*  \n"
            } else {
                append Document "> `[join $cmds { }]`  \n"
            }
        }
        append Document \n
        return
    }

    method Navigation {{highlight_ns {}}} {
        # TBD - right now, no navigation for markdown.
        return
    }

    method Escape {s} {
        # Escapes special characters in markdown.
        #  s - string to be escaped
        # Protects characters in $s against interpretation as
        # markdown special characters.
        #
        # Returns the escaped string

        # TBD - fix this regexp
        set s [regsub -all {[\\`*_\{\}\[\]\(\)#\+\-\.!<>|]} $s {\\\0}]
    }

    method ProcessEmphasis {text delim scope} {
        # Called to handle emphasis in the input stream
        #  text - string to be emphasized
        #  delim - one of `*`, `**` or `***` indicating level of emphasis
        #  scope - Documentation scope for resolving references.
        #
        # Returns markup for emphasized text.

        return [string cat $delim [my FormatInline $text] $delim]
    }

    method ProcessLiteral {text} {
        # Returns markup for literal text.
        #  text - string to be formatted as a literal

        return [string cat ` $text `]
    }

    method ProcessInlineLink {url text title scope {link_type {}}} {
        # Returns the markup for URL links
        #  url - the URL to link to
        #  text - the link text
        #  title - for HTML this shows up as the tooltip
        #  scope - Documentation scope for resolving references.
        #  link_type - one of `symbol`, `figure` or `heading` or empty

        if {$title eq ""} {
            if {$url eq $text} {
                return [string cat < $url >]
            } else {
                return [string cat \[ $text \] \( $url \) ]
            }
        } else {
            return [string cat \[ $text \] \( $url \" $title "\")" ]
        }
    }

    method ProcessInlineImage {url text title scope {link_type {}}} {
        # Returns the markup for URL to images
        #  url - the URL to link to
        #  text - the link text
        #  title - for HTML this shows up as the tooltip
        #  scope - Documentation scope for resolving references.
        #  link_type - one of `symbol`, `figure` or `heading` or empty

        if {$title eq ""} {
            return [string cat !\[ $text \] \( $url \) ]
        } else {
            return [string cat !\[ $text \] \( $url " \"" $title "\")" ]
        }
    }

    method ProcessInternalLink {code_link text scope} {
        # Returns the markup for internal Ruff links.
        #  code_link - dictionary holding resolvable internal link information
        #  text - the link text. If empty the label from `code_link` is used.
        #  scope - Documentation scope for resolving references.
        set url [my Escape [dict get $code_link ref]]
        set url [dict get $code_link ref]
        if {$text eq ""} {
            set text [my Escape [dict get $code_link label]]
        }
        set title $text
        return [my ProcessInlineLink $url $text "" $scope]
    }

    method extension {} {
        # Returns the default file extension to be used for output files.
        return md
    }
}
