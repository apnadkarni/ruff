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
        set parts [lmap arg $args {
            if {$arg eq ""} continue
            set arg
        }]

        return [regsub -all {[^-:\w_.]} [join $parts -] _]
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
            set tip "[my ToMarkdown [string trim [join $tooltip { }]] $ns]\n"
            dict set linkinfo tip $tip
        }
        set name [namespace tail $fqn]
        dict set linkinfo label $name
        dict set NavigationLinks $anchor $linkinfo
        append Document "\n$atx <a name='$anchor'></a>"
        if {[string length $ns]} {
            set ns_link [my ToMarkdown [markup_reference $ns]]
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
                set tip "[my ToMarkdown [join $tooltip { }] $scope]\n"
                dict set linkinfo tip $tip
            }
            dict set linkinfo label $text
            dict set NavigationLinks $anchor $linkinfo
            # NOTE: <a></a> empty because the text itself may contain anchors.
            set heading "<a name='$anchor'></a>[my ToMarkdown $text $scope]"
        } else {
            set heading [my ToMarkdown $text $scope]
        }
        append Document "\n" $atx " " $heading "\n"
        return
    }

    method AddParagraph {lines scope} {
        # See [Formatter.AddParagraph].
        #  lines  - The paragraph lines.
        #  scope - The documentation scope of the content.
        append Document "\n" [my ToMarkdown [join $lines \n] $scope] "\n"
        return
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
                # use ToHtml and not ToMarkdown here. Huh? TBD
                if {$preformatted in {none term}} {
                    set def [my ToMarkdown $def $scope]
                }
                set term [dict get $item term]
                if {$preformatted in {none definition}} {
                    set term [my ToMarkdown $term $scope]
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
                    set def [my ToMarkdown $def $scope]
                }
                set term [dict get $item term]
                if {$preformatted in {none definition}} {
                    set term [my ToMarkdown $term $scope]
                }
                append Document "|$term|$def|\n"
            }
            append Document "\n"
        }
        return
    }

    method AddBullets {bullets scope} {
        # See [Formatter.AddBullets].
        #  bullets  - The list of bullets.
        #  scope    - The documentation scope of the content.
        append Document "\n"
        foreach lines $bullets {
            append Document "- [my ToMarkdown [join $lines { }] $scope]\n"
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
        append Document \n $fence \n [join $lines \n] \n $fence \n
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
            append Document "\n> `[join $cmds { }]` *`[join $params { }]`*<br>"
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
        return [regsub -all {[\\`*_\{\}\[\]\(\)#\+\-\.!<>|]} $s {\\\0}]
    }

    # Credits: tcllib/Caius markdown module
    method ToMarkdown {text {scope {}}} {
        # Returns $text marked up in markdown syntax
        #  text - Ruff! text with inline markup
        #  scope - namespace scope to use for symbol lookup

        # We cannot just pass through our marked-up text as is because
        # it is not really markdown but rather with some extensions:
        # - [xxx] treats xxx as potentially a link to documentation for
        # some programming element.
        # - _ is not treated as a special char
        # - $var is marked as a variable name
        # Moreover, we cannot use a simple regexp or subst because
        # whether this special processing will depend on where inside
        # the input these characters occur, whether a \ preceded etc.

        set text [regsub -all -lineanchor {[ ]{2,}$} $text <br/>]

        set index 0
        set result {}

        set re_backticks   {\A`+}
        set re_whitespace  {\s}
        set re_inlinelink  {\A\!?\[((?:[^\]]|\[[^\]]*?\])+)\]\s*\(\s*((?:[^\s\)]+|\([^\s\)]+\))+)?(\s+([\"'])(.*)?\4)?\s*\)}
        # Changed from markdown to require second optional [] to follow first []
        # without any intervening space. This is to allow consecutive symbol references
        # not to be interpreted as [ref] [text] instead of [ref] [ref]
        # set re_reflink     {\A\!?\[((?:[^\]]|\[[^\]]*?\])+)\](?:\s*\[((?:[^\]]|\[[^\]]*?\])*)\])?}
        set re_reflink     {\A\!?\[((?:[^\]]|\[[^\]]*?\])+)\](?:\[((?:[^\]]|\[[^\]]*?\])*)\])?}
        set re_htmltag     {\A</?\w+\s*>|\A<\w+(?:\s+\w+=(?:\"[^\"]*\"|\'[^\']*\'))*\s*/?>}
        set re_autolink    {\A<(?:(\S+@\S+)|(\S+://\S+))>}
        set re_comment     {\A<!--.*?-->}
        set re_entity      {\A\&\S+;}

        while {[set chr [string index $text $index]] ne {}} {
            switch $chr {
                "\\" {
                    # If the next character is a special markdown character
                    # that we do not treat as special, it should be treated
                    # as a backslash-prefixed ordinary character.
                    # So double the backslash and prefix the character.
                    set next_chr [string index $text [expr $index + 1]]
                    if {$next_chr eq "_"} {
                        append result "\\\\\\_"
                        incr index; # Move past \_
                        continue
                    }
                    # Other characters, special or not, are treated just
                    # like markdown would so pass through as is at bottom
                    # of loop.
                }
                {_} {
                    # Unlike Markdown, do not treat underscores as special char
                    append result \\; # Add an escape prefix
                    # $chr == _ will be added at bottom of loop
                }
                {*} {
                    # EMPHASIS
                    if {[regexp $re_whitespace [string index $result end]] &&
                        [regexp $re_whitespace [string index $text [expr $index + 1]]]} \
                        {
                            #do nothing (add character at bottom of loop)
                        } \
                        elseif {[regexp -start $index \
                                     "\\A(\\$chr{1,3})((?:\[^\\$chr\\\\]|\\\\\\$chr)*)\\1" \
                                     $text m del sub]} \
                        {
                            append result "$del[my ToMarkdown $sub $scope]$del"
                            incr index [string length $m]
                            continue
                        }
                }
                {`} {
                    # CODE
                    # Any marked code should not be escaped as above so
                    # look for it and pass it through as is.

                    # Collect the leading backtick sequence
                    regexp -start $index $re_backticks $text backticks
                    set start [expr $index + [string length $backticks]]

                    # Look for the matching backticks. If not found,
                    # we will not treat this as code. Otherwise pass through
                    # the entire match unchanged.
                    if {[regexp -start $start -indices $backticks $text terminating_indices]} {
                        set stop [lindex $terminating_indices 1]
                        # Copy the entire substring including leading and trailing
                        # backticks to output as is as we do not want those
                        # characters to undergo the special processing above.
                        set passthru [string range $text $index $stop]
                        append result $passthru
                        incr index [string length $passthru]
                        continue
                    }
                }
                {!} -
                {[} {
                    # LINKS AND IMAGES
                    if {$chr eq {!}} {
                        set ref_type img
                        set pre "!\["
                    } else {
                        set ref_type link
                        set pre "\["
                    }

                    set match_found 0
                    if {[regexp -start $index $re_inlinelink $text m txt url ign del title]} {
                        # INLINE
                        if {1} {
                            append result $m
                            set match_found 1
                        } else {
                            # Note: Do quotes inside $title need to be escaped?
                            append result $pre [my ToMarkdown $txt $scope] "\](" $url " " "\"[my ToMarkdown $title $scope]\"" ")"
                            set url [escape [string trim $url {<> }]]
                            set match_found 1
                        }
                    } elseif {[regexp -start $index $re_reflink $text m txt lbl]} {
                        if {$lbl eq {}} {
                            set lbl [regsub -all {\s+} $txt { }]
                            set display_text_specified 0
                        } else {
                            set display_text_specified 1
                        }

                        if {[my ResolvableReference? $lbl $scope code_link]} {
                            # RUFF CODE REFERENCE
                            set url [my Escape [dict get $code_link ref]]
                            if {! $display_text_specified} {
                                set txt [my Escape [dict get $code_link label]]
                            }
                            if {1} {
                                append result $pre $txt "\](" $url ")"
                            } else {
                                # Note: Do quotes inside $txt (SECOND occurence) need to be escaped?
                                append result $pre $txt "\](" $url " " "\"$txt\"" ")"
                            }
                            set match_found 1
                        } else {
                            # Not a Ruff! code link. Pass through as is.
                            # We do not pass text through ToMarkdown as it is
                            # treated as a markdown reference and will need
                            # to match the reference entry.
                            app::log_error "Warning: no target found for link \"$lbl\". Assuming markdown reference."
                            append result $m
                            set match_found 1
                        }
                    }
                    # PRINT IMG, A TAG
                    if {$match_found} {
                        incr index [string length $m]
                        continue
                    }
                }
                    {<} {
                        # HTML TAGS, COMMENTS AND AUTOLINKS
                        # HTML tags, pass through as is without processing
                        if {[regexp -start $index $re_comment $text m] ||
                            [regexp -start $index $re_autolink $text m email link] ||
                            [regexp -start $index $re_htmltag $text m]} {
                            append result $m
                            incr index [string length $m]
                            continue
                        }
                        # Else fall through to pass only the < character
                    }
                    {&} {
                        # ENTITIES
                        # Pass through entire entity without processing
                        if {[regexp -start $index $re_entity $text m]} {
                            append result $m
                            incr index [string length $m]
                            continue
                        }
                        # Else fall through to processing this single &
                    }
                    {$} {
                        # Ruff extension - treat $var as variables name
                        # Note: no need to escape characters but do so
                        # if you change the regexp below
                        if {[regexp -start $index {\$\w+} $text m]} {
                            append result "`$m`"
                            incr index [string length $m]
                            continue
                        }
                    }
                    {>} -
                    {'} -
                    "\"" {
                        # OTHER SPECIAL CHARACTERS
                        # Pass through
                    }
                    default {}
                }

                append result $chr
                incr index
            }

            return $result
        }

        method extension {} {
            # Returns the default file extension to be used for output files.
            return md
        }

        forward FormatInline my ToMarkdown
    }
