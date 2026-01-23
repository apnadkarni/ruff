# Copyright (c) 2024, Sphinx formatter for Ruff!
# Ruff! formatter for Sphinx documentation

namespace eval ruff::formatter {}

oo::class create ruff::formatter::Sphinx {
    superclass ::ruff::formatter::Formatter

    # Data members
    variable Document;        # Current document
    variable DocumentNamespace; # Namespace being documented
    variable Header;          # Common header
    variable Footer;          # Common footer
    variable HeaderLevels;    # Header levels for various headers
    variable HeaderMarkers;   # Characters to use for each header level
    variable NavigationLinks; # Navigation links forming ToC
    variable Images;          # Dictionary holding image information

    constructor args {
        set HeaderLevels {
            class 3
            proc 3
            method 4
            nonav 5
            parameters 5
        }
        # HeaderMarkers based on Python conventions
        set HeaderMarkers [list # * = - ^ \"]
        set Images [dict create]
        next {*}$args
    }

    method MakeSphinxId args {
        # Construct an anchor from the passed arguments.
        #  args - String from which the anchor is to be constructed.
        # The anchor is constructed to work with Sphinx's reference system.
        # Returns an anchor suitable for Sphinx references.

        return [string tolower [make_id {*}$args]]
    }

    method HeadingReference {ns heading} {
        # Implements the [Formatter.HeadingReference] method for Sphinx.
        return "[ns_file_base $ns .html]#[my MakeSphinxId $ns $heading]"
    }

    method SymbolReference {ns symbol} {
        # Implements the [Formatter.SymbolReference] method for Sphinx.
        set ref [ns_file_base $ns .html]
        # Reference to the global namespace is to the file itself.
        if {$ns eq "::" && $symbol eq ""} {
            return $ref
        }
        return [append ref "#[my MakeSphinxId $symbol]"]
    }

    method FigureReference {ns caption} {
        # Implements the [Formatter.FigureReference] method for Sphinx.
        return "[ns_file_base $ns .html]#[my MakeSphinxId $ns $caption]"
    }

    method Begin {} {
        # Implements the [Formatter.Begin] method for Sphinx.

        next

        # Generate the header used by all files
        set Header ""
        set titledesc [my Option -title]

        # Generate the Footer used by all files
        set Footer ""
        if {[my Option? -copyright copyright]} {
            append Footer "\n\n----\n\n"
            append Footer ".. centered:: Copyright (c) [my Escape $copyright]\n"
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

        # Add substitutions for images
        dict for {rst_id image_info} $Images {
            append Document "\n.. |$rst_id| image:: " \
                [dict get $image_info url] "\n   :alt: " \
                [dict get $image_info alt] \n

        }
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
        # Uses Sphinx directives for better semantic markup and indexing.

        set level    [dict get $HeaderLevels $type]
        set ns       [namespace qualifiers $fqn]
        set anchor   [my MakeSphinxId $fqn]

        # Track anchors for navigation
        set linkinfo [dict create tag h$level href "#$anchor"]
        if {[llength $tooltip]} {
            set tip "[my ToSphinx [string trim [join $tooltip { }]] $ns]\n"
            dict set linkinfo tip $tip
        }
        set name [namespace tail $fqn]
        dict set linkinfo label $name
        dict set NavigationLinks $anchor $linkinfo

        # Use Sphinx function/class/method directive based on type
        append Document "\n"

        switch -exact -- $type {
            "class" {
                # Use generic function directive with special index role
                append Document ".. index::\n   single: $fqn (class)\n\n"
                append Document ".. _$anchor:\n\n"

                # Create a styled heading for class
                set text [namespace tail $name]
                set text [string cat [my Escape [string index $text 0]] \
                              [string range $text 1 end]]
                if {[string length $ns]} {
                    set ns_link [my ToSphinx [markup_reference $ns]]
                    set heading "**class** [namespace tail $text] \[${ns_link}\]"
                } else {
                    set heading "**class** $text"
                }

                set char [lindex $HeaderMarkers $level]
                set underline [string repeat $char [string length $heading]]
                append Document "$heading\n$underline\n"
            }
            "proc" {
                # Use generic function directive
                append Document ".. index::\n   single: $fqn (procedure)\n\n"
                append Document ".. _$anchor:\n\n"

                set text [namespace tail $name]
                set text [string cat [my Escape [string index $text 0]] \
                              [string range $text 1 end]]
                if {[string length $ns]} {
                    set ns_link [my ToSphinx [markup_reference $ns]]
                    set heading "[namespace tail $text] \[${ns_link}\]"
                } else {
                    set heading $text
                }

                set char [lindex $HeaderMarkers $level]
                set underline [string repeat $char [string length $heading]]
                append Document "$heading\n$underline\n"
            }
            "method" {
                # Use generic function directive with method annotation
                append Document ".. index::\n   single: $fqn (method)\n\n"
                append Document ".. _$anchor:\n\n"

                set text [namespace tail $name]
                set text [string cat [my Escape [string index $text 0]] \
                              [string range $text 1 end]]
                set heading "**method** $text"

                set char [lindex $HeaderMarkers $level]
                set underline [string repeat $char [string length $heading]]
                append Document "$heading\n$underline\n"
            }
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

        if {$do_link} {
            set anchor [my MakeSphinxId $scope $text]
            set linkinfo [dict create tag h$level href "#$anchor"]
            if {$tooltip ne ""} {
                set tip "[my ToSphinx [join $tooltip { }] $scope]\n"
                dict set linkinfo tip $tip
            }
            dict set linkinfo label $text
            dict set NavigationLinks $anchor $linkinfo
            append Document "\n.. _$anchor:\n\n"
        }

        # If the text starts with something like "*", it will be treated
        # as a list! So escape the first char.
        set text [string cat [my Escape [string index $text 0]] [string range $text 1 end]]
        set heading_text [my ToSphinx $text $scope]

        # RST heading with underline
        if {$do_link} {
            set char [lindex $HeaderMarkers $level]
            set underline [string repeat $char [string length $heading_text]]
            append Document \n $heading_text \n $underline \n
        } else {
            if {1} {
                append Document \n ".. rubric:: $heading_text" \n
            } else {
                append Document \n "**$heading_text**" \n
            }
        }

        return
    }

    method AddParagraph {lines scope} {
        # See [Formatter.AddParagraph].
        #  lines  - The paragraph lines.
        #  scope - The documentation scope of the content.

        append Document \n [my ToSphinx [join $lines \n] $scope] \n
        return
    }

    method AddBlockquote {lines scope} {
        # Adds a blockquote to document content.
        #  lines - List of lines to be quoted
        #  scope - The documentation scope of the content.
        # See [Formatter.AddBlockquote].

        append Document "\n"
        foreach line $lines {
            # RST blockquotes are created by indenting paragraphs
            append Document "    " [my ToSphinx $line $scope] \n
        }
        append Document "\n"
        return
    }

    method AddDefinitions {definitions scope {preformatted none}} {
        # See [Formatter.AddDefinitions].
        #  definitions  - List of definitions.
        #  scope        - The documentation scope of the content.
        #  preformatted - One of `none`, `both`, `term` or `definition`

        # Use Sphinx field list for better semantic markup
        append Document "\n"
        foreach item $definitions {
            set def [join [dict get $item definition] " "]
            if {[my Option -autopunctuate 0]} {
                set def [string toupper $def 0 0]
                if {[regexp {[[:alnum:]]} [string index $def end]]} {
                    append def "."
                }
            }
            if {$preformatted in {none term}} {
                set def [my ToSphinx $def $scope]
            }
            set term [dict get $item term]
            if {$preformatted in {none definition}} {
                set term [my ToSphinx $term $scope]
            }

            # Use field list format for parameters
            append Document ":$term: $def\n"
        }
        append Document "\n"
        return
    }

    method AddTable {table scope} {
        # Adds a table to document content using Sphinx list-table directive
        #  table  - Dictionary describing table
        #  scope  - The documentation scope of the content.

        # Get alignments if specified
        if {[dict exists $table alignments]} {
            set alignments [dict get $table alignments]
        } else {
            set alignments {}
        }

        append Document "\n"

        # Get header and rows
        set rows [dict get $table rows]
        set has_header [dict exists $table header]

        # Use list-table directive for better Sphinx integration
        append Document ".. list-table::\n"
        if {$has_header} {
            append Document "   :header-rows: 1\n"
        }

        # Add widths if we can calculate them
        set num_cols 0
        if {$has_header} {
            set num_cols [llength [dict get $table header]]
        } elseif {[llength $rows] > 0} {
            set num_cols [llength [lindex $rows 0]]
        }

        if {$num_cols > 0} {
            set equal_width [expr {100 / $num_cols}]
            set widths [lrepeat $num_cols $equal_width]
            append Document "   :widths: [join $widths { }]\n"
        }

        append Document "\n"

        # Add header row
        if {$has_header} {
            set header [dict get $table header]
            append Document "   * -"
            set first 1
            foreach cell $header {
                if {!$first} {
                    append Document "\n     -"
                }
                set first 0
                set cell_text [my ToSphinx $cell $scope]
                append Document " $cell_text"
            }
            append Document "\n"
        }

        # Add data rows
        foreach row $rows {
            append Document "   * -"
            set first 1
            foreach cell $row {
                if {!$first} {
                    append Document "\n     -"
                }
                set first 0
                set cell_text [my ToSphinx $cell $scope]
                append Document " $cell_text"
            }
            append Document "\n"
        }

        append Document "\n"
        return
    }

    method AddBullets {content scope} {
        # See [Formatter.AddBullets].
        #  content  - Dictionary with keys items and marker
        #  scope    - The documentation scope of the content.
        append Document "\n"
        set marker [dict get $content marker]
        set marker [expr {$marker eq "1." ? "#." : "-"}]
        foreach lines [dict get $content items] {
            set bullet_text [my ToSphinx [join $lines { }] $scope]
            # Handle multi-line bullets with proper indentation
            set bullet_lines [split $bullet_text \n]
            set first_line [lindex $bullet_lines 0]
            append Document "$marker $first_line\n"
            foreach line [lrange $bullet_lines 1 end] {
                if {$line ne ""} {
                    append Document "  $line\n"
                }
            }
        }
        append Document "\n"
        return
    }

    method AddPreformattedText {text scope} {
        # See [Formatter.AddPreformattedText].
        #  text  - Preformatted text.
        #  scope - The documentation scope of the content.

        # Use RST literal block
        append Document "\n::\n\n"
        set lines [split $text \n]
        foreach line $lines {
            append Document "    $line\n"
        }
        append Document "\n"
        return
    }

    method AddImage {url alt} {
        # Returns a RST link to the image url and registers it as a substitution
        set rst_id [my MakeSphinxId $url]
        dict set Images $rst_id [dict create url $url alt $alt]
        return "|$rst_id|"
    }

    method AddFenced {lines fence_options scope} {
        # Adds a list of fenced lines to document content.
        #  lines - Preformatted text as a list of lines.
        #  fence_options - options controlling generation and layout
        #  scope - The documentation scope of the content.
        # Uses Sphinx code-block directive with enhanced options.

        # Process caption
        if {[dict exists $fence_options -caption]} {
            set caption [dict get $fence_options -caption]
            set anchor [my MakeSphinxId $scope $caption]
            if {[my ResolvableReference? $caption $scope ref] && [dict exists $ref label]} {
                # May have "Figure X" added
                set display_caption [dict get $ref label]
            } else {
                set display_caption $caption
            }
        } else {
            set caption ""
            set display_caption ""
            set anchor ""
        }

        # Check if this is a diagram
        if {[dict exists $fence_options Command] &&
            [lindex [dict get $fence_options Command] 0] eq "diagram"} {
            set diagrammer [lrange [dict get $fence_options Command] 1 end]
            if {[llength $diagrammer] == 0} {
                set diagrammer [program_option -diagrammer]
            }

            # Generate diagram image
            set image_url [ruff::diagram::generate \
                               [join $lines \n] \
                               [ruff::private::sanitize_filename $caption] \
                               {*}$diagrammer]

            # Use Sphinx figure directive for diagrams
            append Document "\n"
            if {$anchor ne ""} {
                append Document ".. _$anchor:\n\n"
            }
            append Document ".. figure:: $image_url\n"

            # TODO - How to right align an image with a caption?
            # Using ..figure allows for a caption but then floats the image
            # Using ..image does not float the image but cannot have a caption
            if {0 && [dict exists $fence_options -align]} {
                set align_value [dict get $fence_options -align]
                append Document "   :align: $align_value\n"
            }

            if {$display_caption ne ""} {
                append Document "\n   $display_caption\n"
            }
            append Document "\n"
        } else {
            # Use Sphinx code-block directive with enhanced options
            set lang [dict get $fence_options Language]

            append Document "\n"
            if {$anchor ne ""} {
                append Document ".. _$anchor:\n\n"
            }

            # Sphinx code-block directive
            if {$lang ne ""} {
                append Document ".. code-block:: $lang\n"
            } else {
                append Document ".. code-block::\n"
            }

            # Add Sphinx-specific options
            if {$display_caption ne ""} {
                append Document "   :caption: $display_caption\n"
            }

            if {[dict exists $fence_options -linenos]} {
                append Document "   :linenos:\n"
            }

            if {[dict exists $fence_options -emphasize-lines]} {
                set lines_to_emphasize [dict get $fence_options -emphasize-lines]
                append Document "   :emphasize-lines: $lines_to_emphasize\n"
            }

            append Document "\n"
            foreach line $lines {
                append Document "   $line\n"
            }
            append Document "\n"
        }

        return
    }

    method AddSynopsis {synopsis scope} {
        # Adds a Synopsis section to the document content.
        #  synopsis - List of alternating elements comprising the command portion
        #             and the parameter list for it.
        #  scope  - The documentation scope of the content.

        append Document "\n"
        foreach {cmds params} $synopsis {
            # Use parsed-literal for better formatting
            append Document ".. parsed-literal::\n\n"
            append Document "   **[join $cmds { }]**"
            if {[llength $params]} {
                append Document " *[join $params { }]*"
            }
            append Document "\n\n"
        }
        return
    }

    method Navigation {{highlight_ns {}}} {
        # Sphinx can generate its own TOC with .. toctree::
        # so we don't need to manually create navigation
        return
    }

    method Escape {s} {
        # Escapes special characters in ReStructuredText/Sphinx.
        #  s - string to be escaped
        # Returns the escaped string

        return [string map {\\ \\\\ * \\* + \\+} $s]
    }

    method ToSphinx {text {scope {}}} {
        # Returns $text marked up in Sphinx/RST syntax
        #  text - Ruff! text with inline markup
        #  scope - namespace scope to use for symbol lookup

        set index 0
        set result {}

        set re_backticks   {\A`+}
        set re_whitespace  {\s}
        set re_inlinelink  {\A\!?\[((?:[^\]]|\[[^\]]*?\])+)\]\s*\(\s*((?:[^\s\)]+|\([^\s\)]+\))+)?(\s+([\"'])(.*)?\4)?\s*\)}
        set re_reflink     {\A\!?\[((?:[^\]]|\[[^\]]*?\])+)\](?:\[((?:[^\]]|\[[^\]]*?\])*)\])?}
        set re_entity      {\A\&\S+;}

        while {[set chr [string index $text $index]] ne {}} {
            switch $chr {
                "\\" {
                    # Handle backslash escaping
                    set next_chr [string index $text [expr $index + 1]]
                    if {$next_chr eq "_"} {
                        append result "\\\\_"
                        incr index
                        continue
                    }
                }
                {_} {
                    # Escape underscores
                    append result \\_
                    incr index
                    continue
                }
                {*} {
                    # EMPHASIS or STRONG
                    if {[regexp $re_whitespace [string index $result end]] &&
                        [regexp $re_whitespace [string index $text [expr $index + 1]]]} {
                        append result \\*
                    } elseif {[regexp -start $index \
                                   "\\A(\\$chr{1,2})((?:\[^\\$chr\\\\]|\\\\\\$chr)*)\\1" \
                                   $text m del sub]} {
                        append result "$del[my ToSphinx $sub $scope]$del"
                        incr index [string length $m]
                        continue
                    } else {
                        append result \\*
                    }
                    incr index
                    continue
                }
                {`} {
                    # CODE - inline literals
                    regexp -start $index $re_backticks $text backticks
                    set start [expr $index + [string length $backticks]]

                    if {[regexp -start $start -indices $backticks $text terminating_indices]} {
                        set stop [expr {[lindex $terminating_indices 0] - 1}]
                        set sub [string trim [string range $text $start $stop]]
                        append result "``" [my Escape $sub] "``"
                        set index [expr [lindex $terminating_indices 1] + 1]
                        continue
                    }
                }
                {!} -
                "[" {
                    # Note: "[", not {[} because latter messes Emacs indentation
                    # LINKS AND IMAGES
                    # INLINE LINKS AND IMAGES
                    set ref_type [expr {$chr eq "!" ? "img" : "link"}]
                    set match_found 0

                    if {[regexp -start $index $re_inlinelink $text m txt url ign del title]} {
                        set link_text [my ToSphinx $txt $scope]
                        set match_found 1
                    } elseif {[regexp -start $index $re_reflink $text m txt lbl]} {
                        if {$lbl eq {}} {
                            set lbl [regsub -all {\s+} $txt { }]
                            set display_text_specified 0
                        } else {
                            set display_text_specified 1
                        }

                        if {[my ResolvableReference? $lbl $scope code_link]} {
                            # RUFF CODE REFERENCE - use Sphinx :ref: role
                            set url [dict get $code_link ref]
                            if {$display_text_specified} {
                                set link_text $txt
                            } else {
                                set link_text [dict get $code_link label]
                            }
                            set match_found 1
                        } elseif {[is_builtin $lbl]} {
                            lassign [builtin_url $lbl] url lbl
                            if {$display_text_specified} {
                                set link_text $txt
                            } else {
                                set link_text $lbl
                            }
                            set match_found 1
                        } else {
                            app::log_error "Warning: no target found for link \"$lbl\". Passing through verbatim."
                            append result [my Escape $m]
                            incr index [string length $m]
                            continue
                        }
                    }

                    if {$match_found} {
                        if {$ref_type eq "img"} {
                            append result [my AddImage $url $link_text]
                        } else {
                            # Use standard external link format
                            append result "`$link_text <$url>`_"
                        }
                        incr index [string length $m]
                        continue
                    }
                }
                {$} {
                    # Ruff extension - treat $var as variable
                    if {[regexp -start $index {\$\w+} $text m]} {
                        append result "``$m``"
                        incr index [string length $m]
                        continue
                    }
                }
                {&} {
                    # ENTITIES
                    if {[regexp -start $index $re_entity $text m]} {
                        append result $m
                        incr index [string length $m]
                        continue
                    }
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
        return rst
    }

    method finalize {output_dir output_paths} {
        # Called after all output files are written out.
        #   output_dir - root of output directory
        #   output_paths - full paths to files written
        #
        # Writes out the Sphinx index.rst main content.
        set fd [open [file join $output_dir index.rst] w]
        puts $fd ".. toctree::"
        puts $fd "   :maxdepth: 5"
        puts $fd "   :caption: Contents:"
        puts $fd ""
        foreach path $output_paths {
            puts $fd "   [file tail $path]"
        }
        close $fd
        return
    }


    forward FormatInline my ToSphinx
}
