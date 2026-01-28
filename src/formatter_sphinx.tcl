# Copyright (c) 2024, Sphinx formatter for Ruff!
# Ruff! formatter for Sphinx documentation

namespace eval ruff::formatter {}

oo::class create ruff::formatter::Sphinx {
    superclass ::ruff::formatter::Formatter

    # Data members
    variable Document;        # Current document
    variable DocumentNamespace; # Namespace being documented
    variable Footer;          # Common footer
    variable HeaderLevels;    # Header levels for various headers
    variable HeaderMarkers;   # Characters to use for each header level
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
        return [my MakeSphinxId $ns $heading]
    }

    method SymbolReference {ns symbol} {
        # Implements the [Formatter.SymbolReference] method for Sphinx.

        return [my MakeSphinxId $symbol]
    }

    method FigureReference {ns caption} {
        # Implements the [Formatter.FigureReference] method for Sphinx.
        return [my MakeSphinxId $ns $caption]
        return "[ns_file_base $ns .html]#[my MakeSphinxId $ns $caption]"
    }

    method Begin {} {
        # Implements the [Formatter.Begin] method for Sphinx.

        next

        # Generate the header used by all files
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

        set    Document ""
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

    method AddAnchor {anchor} {
        # Adds an anchor (link target) to the document 
        #  anchor - The anchor id to add

        append Document "\n.. _$anchor:\n\n"
        return
    }

    method AddProgramElementHeading {type fqn {tooltip {}} {synopsis {}}} {
        # Adds heading for a program element like procedure, class or method.
        #  type - One of `proc`, `class` or `method`
        #  fqn - Fully qualified name of element.
        #  tooltip - The tooltip lines, if any, to be displayed in the
        #    navigation pane. Not used for Sphinx.
        # Uses Sphinx directives for better semantic markup and indexing.

        set level    [dict get $HeaderLevels $type]
        set ns       [namespace qualifiers $fqn]
        set anchor   [my MakeSphinxId $fqn]

        # Track anchors for navigation
        set linkinfo [dict create tag h$level href "#$anchor"]
        set name [namespace tail $fqn]
        dict set linkinfo label $name

        # Use Sphinx function/class/method directive based on type
        append Document "\n"

        # Use generic function directive with special index role
        set ns_label [string trimleft $ns :]
        if {$ns_label eq ""} {
            set ns_label global
        }
        append ns_label " " [expr {$type eq "method" ? "class" : "namespace"}]
        if {[number_of_symbol_occurrences $name] > 1} {
            append Document ".. index::\n   pair: $ns_label;$name\n\n"
        } else {
            append Document ".. index::\n   single: $name\n"
            append Document ".. index::\n   single: $ns_label;$name\n\n"
        }

        append Document ".. _$anchor:\n\n"

        set heading [my ProcessLiteral [namespace tail $name]]
        if {0 && [string length $ns]} {
            # Links to class/namespace - disabled as it clutters the Sphinx
            # navigation bar
            set ns_link [my FormatInline [markup_reference $ns]]
            append heading " \[${ns_link}\]"
        }

        set char [lindex $HeaderMarkers $level]
        set underline [string repeat $char [string length $heading]]
        append Document "$heading\n$underline\n"
    }

    method AddHeading {level text scope {tooltip {}}} {
        # See [Formatter.AddHeading].
        #  level   - The numeric or semantic heading level.
        #  text    - The heading text.
        #  scope   - The documentation scope of the content.
        #  tooltip - Tooltip to display in navigation link. Not used for Sphinx.

        if {![string is integer -strict $level]} {
            set level [dict get $HeaderLevels $level]
        }
        set do_link [expr {$level < [dict get $HeaderLevels nonav]}]

        if {$do_link} {
            set anchor [my MakeSphinxId $scope $text]
            set linkinfo [dict create tag h$level href "#$anchor"]
            dict set linkinfo label $text
            append Document "\n.. _$anchor:\n\n"
        }

        set heading_text [my FormatInline $text $scope]

        # RST heading with underline
        if {$do_link} {
            set char [lindex $HeaderMarkers $level]
            set underline [string repeat $char [string length $heading_text]]
            append Document \n $heading_text \n $underline \n
        } else {
            append Document \n ".. rubric:: $heading_text" \n
        }

        return
    }

    method AddParagraph {lines scope} {
        # See [Formatter.AddParagraph].
        #  lines  - The paragraph lines.
        #  scope - The documentation scope of the content.

        append Document \n [my FormatInline [join $lines \n] $scope] \n
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
            append Document "    " [my FormatInline $line $scope] \n
        }
        append Document "\n"
        return
    }

    method AddDefinitions {definitions scope {preformatted none}} {
        # See [Formatter.AddDefinitions].
        #  definitions  - List of definitions.
        #  scope        - The documentation scope of the content.
        #  preformatted - One of `none`, `both`, `term` or `definition`

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
                set def [my FormatInline $def $scope]
            }
            set term [dict get $item term]
            if {$preformatted in {none definition}} {
                set term [my FormatInline $term $scope]
            }

            # Use field list format for parameters. If the term itself is a
            # reference link, do not double colons
            if {[string match ":ref:`*`" $term]} {
                append Document "$term\n   $def\n"
            } else {
                append Document ":$term:\n   $def\n"
            }
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
                set cell_text [my FormatInline $cell $scope]
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
                set cell_text [my FormatInline $cell $scope]
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
            set bullet_text [my FormatInline [join $lines { }] $scope]
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
        append Document "\n.. code-block:: none\n\n"
        set lines [split $text \n]
        foreach line $lines {
            append Document "   $line\n"
        }
        append Document "\n"
        return
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
            # Cannot align an image in Sphinx.
            # Using ..figure allows for a caption but then floats the image
            # Using ..image does not float the image but cannot have a caption
            append Document "\n"
            if {$anchor ne ""} {
                append Document ".. _$anchor:\n\n"
            }
            append Document ".. figure:: $image_url\n"

            if {$display_caption ne ""} {
                append Document "\n   $display_caption\n"
            }
            append Document "\n"
        } else {
            # Use Sphinx code-block directive with enhanced options
            set lang [dict get $fence_options Language]
            if {$lang eq ""} {
                set lang none; # Prevent random syntax highlighting
            }

            append Document "\n"
            if {$anchor ne ""} {
                append Document ".. _$anchor:\n\n"
            }
            append Document ".. code-block:: $lang\n"

            if {$display_caption ne ""} {
                append Document "   :caption: $display_caption\n"
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
        append Document ".. parsed-literal::\n\n"
        # Use parsed-literal for better formatting
        foreach {cmds params} $synopsis {
            append Document "   **[join $cmds { }]**"
            if {[llength $params]} {
                append Document " *[join $params { }]*"
            }
            append Document "\n"
        }
        append Document "\n"
        return
    }

    method Navigation {{highlight_ns {}}} {
        # Sphinx can generate its own TOC with .. toctree::
        # so we don't need to manually create navigation
        return
    }

    method Escape {text} {
        # Escapes special characters in ReStructuredText inline markup
        #  text - string to be escaped
        # Returns the escaped string with proper context-aware escaping
        #

        # RST inline markup rules:
        # - Markup start characters need whitespace/punctuation before them
        #   and non-whitespace after
        # - We only need to check for markup START since we're escaping BEFORE
        #   parsing
        # - Backslashes always need escaping
        #
        # The actual rules at https://docutils.sourceforge.io/docs/ref/rst/restructuredtext.html#inline-markup
        # are indecipherable to me so the following likely has bugs.
        #
        # It also seems to be the case that escapes are dependent on the context
        # (for example, part of definition term vs definition description vs text)
        # Further, the Sphinx builders like sphinx-build for HTML have their own
        # rules so strings that resemble HTML tags needs escaping.

        set result {}
        set len [string length $text]

        for {set i 0} {$i < $len} {incr i} {
            set chr [string index $text $i]

            # Check if character could start markup
            # Markup can start if preceded by whitespace/punctuation (or at start)
            # and followed by non-whitespace/punctuation
            set prev_chr [string index $text $i-1]
            set next_chr [string index $text $i+1]

            # Escape based on character type. Check common case first.
            if {[string match {[ a-zA-Z0-9]} $chr]} {
                append result $chr
            } elseif {$chr eq "\\"} {
                # Backslashes always need escaping
                append result "\\" $chr
            } elseif {$chr in {* _ ` |} &&
                      ($prev_chr == "" || [regexp {[\s\(\[\{<'"]} $prev_chr]) &&
                      ($next_chr ne "" && ![regexp {[\s\)\]\}>'"]} $next_chr])} {
                # Escape markup start characters at boundaries
                append result "\\" $chr
            } else {
                append result $chr
            }
        }

        return $result
    }

    method ProcessEmphasis {text delim scope} {
        # Returns markup for emphasized text.
        #  text - string to be emphasized
        #  delim - one of `*`, `**` or `***` indicating level of emphasis
        #  scope - Documentation scope for resolving references.
        #

        # Note: reST does not support ***. Treat as **
        if {$delim eq "***"} {
            set delim "**"
        }
        switch -exact $delim {
            * -
            ** {
                return [string cat $delim [my FormatInline $text $scope] $delim]
            }
            default {
                error "Invalid emphasis delimiter length [string length $delim]."
            }
        }
    }

    method ProcessLiteral {text} {
        # Returns markup for literal text.
        #  text - string to be formatted as a literal

        return [string cat `` $text ``]
    }

    method ProcessInlineLink {url text title scope {link_type {}}} {
        # Returns the markup for URL links
        #  url - the URL to link to
        #  text - the link text
        #  title - not used
        #  scope - not used
        #  link_type - not used

        return [string cat ` $text " <" $url ">`_"]
    }

    method ProcessInlineImage {url text title scope {link_type {}}} {
        # Returns a RST link to the image url and registers it as a substitution
        #  url - the URL to link to
        #  text - the link text
        #  title - not used
        #  scope - not used
        #  link_type - not used
        set rst_id [my MakeSphinxId $url]
        dict set Images $rst_id [dict create url $url alt $text]
        return "|$rst_id|"
    }

    method ProcessInternalLink {code_link text scope} {
        # Returns the markup for internal Ruff links.
        #  code_link - dictionary holding resolvable internal link information
        #  text - the link text. If empty the label from `code_link` is used.
        #  scope - Documentation scope for resolving references.
        # The default implementation assumes HTML output format. Derived classes
        # can override the method.

        # Return Sphinx refs as the default will only work for HTML.
        if {1} {
            if {$text eq ""} {
                set text [my Escape [dict get $code_link label]]
                # Need to escape <> so sphinx-build will not interpret as HTML tag
                set text [string map {< \\< > \\>} $text]
            }
            return [string cat ":ref:`" $text " <" [dict get $code_link ref] ">`"]
        } else {
            return [next $code_link $text $scope]
        }
    }

    method ProcessComment {text} {
        # Returns the markup for a comment.
        #
        set comment \n
        foreach line [split $text \n] {
            append comment ".. " [my Escape $line] \n
        }
        return $comment
    }

    method InlineHtmlSupported {} {
        # Returns boolean indicating whether the formatter supports inline HTML.
        #
        return false
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
        puts $fd "   genindex"
        close $fd

        # Ensure directory for static assets used by Sphinx exists
        file mkdir [file join $output_dir _static]

        # Standard settings for conf.py
        set fd [open [file join $output_dir conf.py] w]
        puts $fd "# Configuration file for the Sphinx documentation builder."
        puts $fd "# Generated by Ruff!"
        if {![my Option? -product product]} {
            set product "unspecified"
        }
        puts $fd "project = '$product'"
        if {[my Option? -copyright copyright]} {
            puts $fd "copyright = '$copyright'"
        }
        if {[my Option? -version version]} {
            puts $fd "version = '$version'"
        }

        puts $fd {templates_path = ['_templates']}
        puts $fd {exclude_paths = ['build', 'Thumbs.db', '.DS_Store']}
        puts $fd {html_static_path = ['_static']}
        close $fd

        return
    }

}
