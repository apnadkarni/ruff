# Copyright (c) 2024, ReStructuredText formatter for Ruff!
# Ruff! formatter for ReStructuredText

namespace eval ruff::formatter {}

oo::class create ruff::formatter::Rst {
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
            nonav 4
            parameters 4
        }
        # HeaderMarkers based on Python conventions
        set HeaderMarkers [list # * = - ^ \"]
        set Images [dict create]
        next {*}$args
    }

    method MakeRst2HtmlId args {
        # Construct an anchor from the passed arguments.
        #  args - String from which the anchor is to be constructed.
        # The anchor is constructed such that no further transform is performed
        # by rst2html. Otherwise link to the anchor will fail.
        # Returns an anchor suitable for RST references.

        return [string tolower [make_id {*}$args]]
    }

    method HeadingReference {ns heading} {
        # Implements the [Formatter.HeadingReference] method for ReStructuredText.
        return "[ns_file_base $ns .html]#[my MakeRst2HtmlId $ns $heading]"
    }

    method SymbolReference {ns symbol} {
        # Implements the [Formatter.SymbolReference] method for ReStructuredText.
        set ref [ns_file_base $ns .html]
        # Reference to the global namespace is to the file itself.
        if {$ns eq "::" && $symbol eq ""} {
            return $ref
        }
        return [append ref "#[my MakeRst2HtmlId $symbol]"]
    }

    method FigureReference {ns caption} {
        # Implements the [Formatter.FigureReference] method for ReStructuredText.
        return "[ns_file_base $ns .html]#[my MakeRst2HtmlId $ns $caption]"
    }

    method Begin {} {
        # Implements the [Formatter.Begin] method for ReStructuredText.

        next

        # Generate the header used by all files
        set Header ""
        set titledesc [my Option -title]

        # Generate the Footer used by all files
        set Footer ""
        if {[my Option? -copyright copyright]} {
            append Footer "\n\n----\n\n"
            append Footer "Copyright (c) [my Escape $copyright]\n"
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
        # In addition to adding the heading to the document, a link
        # is also added to the collection of navigation links.

        set level    [dict get $HeaderLevels $type]
        set ns       [namespace qualifiers $fqn]
        set anchor   [my MakeRst2HtmlId $fqn]

        # Track anchors for navigation
        set linkinfo [dict create tag h$level href "#$anchor"]
        if {[llength $tooltip]} {
            set tip "[my ToRST [string trim [join $tooltip { }]] $ns]\n"
            dict set linkinfo tip $tip
        }
        set name [namespace tail $fqn]
        dict set linkinfo label $name
        dict set NavigationLinks $anchor $linkinfo

        # Add RST target directive
        append Document "\n.. _$anchor:\n\n"

        # Create heading text
        if {[string length $ns]} {
            set text [namespace tail $name]
            set text [string cat [my Escape [string index $text 0]] \
                          [string range $text 1 end]]
            set ns_link [my ToRST [markup_reference $ns]]
            set heading "[namespace tail $text] \[${ns_link}\]"
        } else {
            # If the name starts with something like "*", it will be treated
            # as a list! So escape the first char.
            set text [string cat [my Escape [string index $name 0]] \
                          [string range $name 1 end]]
            set heading $text
        }

        # Add heading with appropriate underline
        set char [lindex $HeaderMarkers $level]
        set underline [string repeat $char [string length $heading]]

        append Document "$heading\n$underline\n"
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
            set anchor [my MakeRst2HtmlId $scope $text]
            set linkinfo [dict create tag h$level href "#$anchor"]
            if {$tooltip ne ""} {
                set tip "[my ToRST [join $tooltip { }] $scope]\n"
                dict set linkinfo tip $tip
            }
            dict set linkinfo label $text
            dict set NavigationLinks $anchor $linkinfo
            append Document "\n.. _$anchor:\n\n"
        }

        # If the text starts with something like "*", it will be treated
        # as a list! So escape the first char.
        set text [string cat [my Escape [string index $text 0]] [string range $text 1 end]]
        set heading_text [my ToRST $text $scope]

        # RST heading with underline
        set char [lindex $HeaderMarkers $level]
        set underline [string repeat $char [string length $heading_text]]

        append Document \n $heading_text \n $underline \n
        return
    }

    method AddParagraph {lines scope} {
        # See [Formatter.AddParagraph].
        #  lines  - The paragraph lines.
        #  scope - The documentation scope of the content.
        append Document \n [my ToRST [join $lines \n] $scope] \n
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
            append Document "    " [my ToRST $line $scope] \n
        }
        append Document "\n"
        return
    }

    method AddDefinitions {definitions scope {preformatted none}} {
        # See [Formatter.AddDefinitions].
        #  definitions  - List of definitions.
        #  scope        - The documentation scope of the content.
        #  preformatted - One of `none`, `both`, `term` or `definition`
        #                 indicating which fields of the definition are
        #                 are already formatted.

        # Use RST definition list format
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
                set def [my ToRST $def $scope]
            }
            set term [dict get $item term]
            if {$preformatted in {none definition}} {
                set term [my ToRST $term $scope]
            }

            # RST definition list format
            append Document "$term\n"
            # Indent definition by 4 spaces
            set def_lines [split $def \n]
            foreach line $def_lines {
                append Document "    $line\n"
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

        # Get alignments if specified
        if {[dict exists $table alignments]} {
            set alignments [dict get $table alignments]
        } else {
            set alignments {}
        }

        append Document "\n"

        # Unlike Markdown, RST requires all rows to have same number of cells
        # and each cell to be the same width so first calculate column widths

        # Get header and rows
        set rows [dict get $table rows]
        set has_header [dict exists $table header]
        if {$has_header} {
            set rows [linsert $rows 0 [dict get $table header]]
        }

        # Calculate column widths
        set num_cols 0
        foreach row $rows {
            set row_len [llength $row]
            if {$row_len > $num_cols} {
                set num_cols $row_len
            }
        }

        if {$num_cols == 0} {
            return
        }

        # Initialize column widths
        set col_widths {}
        for {set i 0} {$i < $num_cols} {incr i} {
            lappend col_widths 0
        }

        # Loop over all cells, converting to RST and calculating
        # the cell width.
        set rst_rows {}
        foreach row $rows {
            set rst_row {}
            for {set i 0} {$i < $num_cols} {incr i} {
                set cell [my ToRST [lindex $row $i] $scope]
                lappend rst_row $cell
                set width [string length $cell]
                if {$width > [lindex $col_widths $i]} {
                    lset col_widths $i $width
                }
            }
            lappend rst_rows $rst_row
        }

        # Output the RST Grid Table
        # TODO - Grid tables do not seem to support alignment. Should
        # we use list-table directive instead? Is that RST or Sphinx-only?

        # Top border
        append Document [my TableBorder $col_widths $alignments top] "\n"
        # First row or header
        append Document [my TableRow [lindex $rst_rows 0] $col_widths $alignments] \n
        set rst_rows [lrange $rst_rows 1 end]
        if {$has_header} {
            # Header separator
            append Document [my TableBorder $col_widths $alignments header] "\n"
        } else {
            append Document [my TableBorder $col_widths $alignments bottom] "\n"
        }

        # Data rows
        foreach row $rst_rows {
            append Document [my TableRow $row $col_widths $alignments] \n
            append Document [my TableBorder $col_widths $alignments bottom] "\n"
        }

        # Bottom border
        append Document "\n"

        return
    }

    method TableRow {cells widths alignments} {
        # Returns a row formatted as a RST grid table row
        #  cells - list of cells, each already formatted for RST
        #  col_widths - width of each column
        #  alignment - alignment of each column
        set row [lmap width $widths cell $cells alignment $alignments {
            my FormatTableCell $cell $width $alignment
        }]
        return "| [join $row { | }] |"
    }

    method TableBorder {widths alignments position} {
        # Generate a table border line for RST grid tables
        #  widths - List of column widths
        #  alignments - List of column alignments
        #  position - One of top, header, or bottom

        # TODO - alignments ignored.

        set separator [expr {$position eq "header" ? "=" : "-"}]
        return [string cat + [join [lmap width $widths {
            string repeat $separator [expr {$width + 2}]
        }] +] +]
    }

    method FormatTableCell {text width align} {
        # Format a table cell with proper padding and alignment
        #  text - Cell text
        #  width - Column width
        #  align - Alignment (left, center, right, or empty)

        # TODO - alignments ignored.
        set len [string length $text]
        set padding [expr {$width - $len}]

        if {$padding < 0} {
            error "Length of text is greater than column width"
        }
        return "$text[string repeat { } $padding]"
    }

    method AddBullets {content scope} {
        # See [Formatter.AddBullets].
        #  content  - Dictionary with keys items and marker
        #  scope    - The documentation scope of the content.
        append Document "\n"
        set marker [dict get $content marker]
        set marker [expr {$marker eq "1." ? "#." : "-"}]
        foreach lines [dict get $content items] {
            set bullet_text [my ToRST [join $lines { }] $scope]
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
        set rst_id [my MakeRst2HtmlId $url]
        dict set Images $rst_id [dict create url $url alt $alt]
        return "|$rst_id|"
    }

    method AddFenced {lines fence_options scope} {
        # Adds a list of fenced lines to document content.
        #  lines - Preformatted text as a list of lines.
        #  fence_options - options controlling generation and layout
        #  scope - The documentation scope of the content.
        # Handles diagrams, captions, and alignment similar to HTML formatter.

        # Process caption
        if {[dict exists $fence_options -caption]} {
            set caption [dict get $fence_options -caption]
            set anchor [my MakeRst2HtmlId $scope $caption]
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

        # Process alignment
        set align_class ""
        if {[dict exists $fence_options -align]} {
            set align_value [dict get $fence_options -align]
            switch -exact -- $align_value {
                "left" - "center" - "right" {
                    set align_class "   :class: align-$align_value\n"
                }
            }
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

            # Use RST figure directive for diagrams
            append Document "\n"
            if {$anchor ne ""} {
                append Document ".. _$anchor:\n\n"
            }
            append Document ".. figure:: $image_url\n"
            if {$align_class ne ""} {
                # For figures, :align: is standard RST
                set align_value [dict get $fence_options -align]
                append Document "   :align: $align_value\n"
            }

            if {$display_caption ne ""} {
                append Document "\n   $display_caption\n"
            }
            append Document "\n"
        } else {
            # Regular code block - use standard RST literal block wrapped in container
            set lang [dict get $fence_options Language]

            append Document "\n"
            if {$anchor ne ""} {
                append Document ".. _$anchor:\n\n"
            }

            # Use container directive to support alignment via CSS class
            if {$align_class ne "" || $display_caption ne ""} {
                append Document ".. container:: code-block"
                if {$align_class ne ""} {
                    set align_value [dict get $fence_options -align]
                    append Document " align-$align_value"
                }
                append Document "\n\n"

                if {$display_caption ne ""} {
                    append Document "   **$display_caption**\n\n"
                }

                append Document "   ::\n\n"
                foreach line $lines {
                    append Document "      $line\n"
                }
            } else {
                # Simple literal block
                append Document "::\n\n"
                foreach line $lines {
                    append Document "   $line\n"
                }
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
            # | means line block. Maybe make it fenced block?
            append Document "| ``[join $cmds { }]"
            if {[llength $params]} {
                append Document " [join $params { }]"
            }
            append Document "``\n"
        }
        append Document "\n"
        return
    }

    method Navigation {{highlight_ns {}}} {
        # Generate table of contents if needed
        # For now, RST can generate its own TOC with .. contents::
        # so we don't need to manually create navigation
        return
    }

    method Escape {s} {
        # Escapes special characters in ReStructuredText.
        #  s - string to be escaped
        # Protects characters in $s against interpretation as
        # RST special characters.
        #
        # Returns the escaped string

        # RST has fewer special characters than Markdown
        # Main ones are backslash and asterisk in certain contexts
        return [string map {\\ \\\\ * \\* + \\+} $s]
    }

    method ToRST {text {scope {}}} {
        # Returns $text marked up in ReStructuredText syntax
        #  text - Ruff! text with inline markup
        #  scope - namespace scope to use for symbol lookup

        # Process special Ruff! markup:
        # - [xxx] treats xxx as potentially a link to documentation
        # - _ is not treated as a special char (escaped)
        # - $var is marked as a variable name
        # - Handle emphasis and strong emphasis

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
                    # Escape underscores (not special in our markup)
                    append result \\_
                    incr index
                    continue
                }
                {*} {
                    # EMPHASIS (single *) or STRONG (double **)
                    if {[regexp $re_whitespace [string index $result end]] &&
                        [regexp $re_whitespace [string index $text [expr $index + 1]]]} {
                        # Just an asterisk, escape it
                        append result \\*
                    } elseif {[regexp -start $index \
                                   "\\A(\\$chr{1,2})((?:\[^\\$chr\\\\]|\\\\\\$chr)*)\\1" \
                                   $text m del sub]} {
                        # TODO - bold+italicised does not seem to work
                        # Found emphasis or strong
                        append result "$del[my ToRST $sub $scope]$del"
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
                    set ref_type [expr {$chr eq "!" ? "img" : "link"}]
                    set match_found 0

                    if {[regexp -start $index $re_inlinelink $text m txt url ign del title]} {
                        # Inline link - convert to RST format
                        set link_text [my ToRST $txt $scope]
                        set match_found 1
                    } elseif {[regexp -start $index $re_reflink $text m txt lbl]} {
                        if {$lbl eq {}} {
                            set lbl [regsub -all {\s+} $txt { }]
                            set display_text_specified 0
                        } else {
                            set display_text_specified 1
                        }

                        if {[my ResolvableReference? $lbl $scope code_link]} {
                            # RUFF CODE REFERENCE
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
                            # Not a Ruff! code link - pass through as is
                            app::log_error "Warning: no target found for link \"$lbl\". Passing through verbatim."
                            append result [my Escape $m]
                            incr index [string length $m]
                            continue; # Skip the match_found block
                        }
                    }

                    if {$match_found} {
                        # RST external link format
                        if {$ref_type eq "img"} {
                            append result [my AddImage $url $link_text]
                        } else {
                            append result "`$link_text <$url>`_"
                        }
                        incr index [string length $m]
                        continue
                    }
                }
                {$} {
                    # Ruff extension - treat $var as variables name
                    if {[regexp -start $index {\$\w+} $text m]} {
                        append result "``$m``"
                        incr index [string length $m]
                        continue
                    }
                }
                {&} {
                    # ENTITIES - pass through
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

    forward FormatInline my ToRST
}
