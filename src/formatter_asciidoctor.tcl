# Copyright (c) 2026, Ashok P. Nadkarni
# Ruff! formatter for Asciidoctor documentation

namespace eval ruff::formatter {}

oo::class create ruff::formatter::Asciidoctor {
    superclass ::ruff::formatter::Formatter

    # Data members
    variable Document;        # Current document
    variable DocumentNamespace; # Namespace being documented
    variable Footer;          # Common footer
    variable HeaderLevels;    # Header levels for various headers
    variable Images;          # Dictionary holding image information

    constructor args {
        set HeaderLevels {
            class 3
            proc 3
            method 4
            nonav 5
            parameters 5
        }
        set Images [dict create]
        next {*}$args
    }

    method MakeAsciidocId args {
        # Construct an anchor from the passed arguments.
        #  args - String from which the anchor is to be constructed.
        # The anchor is constructed to work with Asciidoctor's reference system.
        # Returns an anchor suitable for Asciidoctor references.

        return [string tolower [make_id {*}$args]]
    }

    method HeadingReference {ns heading} {
        # Implements the [Formatter.HeadingReference] method for Asciidoctor.
        return [my MakeAsciidocId $ns $heading]
    }

    method SymbolReference {ns symbol} {
        # Implements the [Formatter.SymbolReference] method for Asciidoctor.
        return [my MakeAsciidocId $symbol]
    }

    method FigureReference {ns caption} {
        # Implements the [Formatter.FigureReference] method for Asciidoctor.
        return [my MakeAsciidocId $ns $caption]
    }

    method Begin {} {
        # Implements the [Formatter.Begin] method for Asciidoctor.

        next

        # Generate the Footer used by all files
        set Footer ""
        if {[my Option? -copyright copyright]} {
            append Footer "\n\n'''\n\n"
            append Footer "Copyright (c) [my Escape $copyright]\n"
        }
        return
    }

    method DocumentBegin {ns} {
        # See [Formatter.DocumentBegin].
        # ns - Namespace for this document.

        next $ns

        set Document ""
        set DocumentNamespace $ns

        return
    }

    method DocumentEnd {} {
        # See [Formatter.DocumentEnd].

        # Add the footer
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

        # Must use explicit macro. Using the [[anchor]] form will be ignored
        # if followed immediately by another anchor.
        append Document "\nanchor:$anchor\[\]\n"
        return
    }

    method AddProgramElementHeading {type fqn {tooltip {}} {synopsis {}}} {
        # Adds heading for a program element like procedure, class or method.
        #  type - One of `proc`, `class` or `method`
        #  fqn - Fully qualified name of element.
        #  tooltip - The tooltip lines, if any (not used in Asciidoctor).

        set level    [dict get $HeaderLevels $type]
        set ns       [namespace qualifiers $fqn]
        set anchor   [my MakeAsciidocId $fqn]
        set exported_anchor [make_exported_id $fqn]

        set linkinfo [dict create tag h$level href "#$anchor"]
        set name [namespace tail $fqn]
        dict set linkinfo label $name

        append Document "\n\[\[" $anchor "\]\]\n"
        append Document "\[\[" $exported_anchor "\]\]\n"

        set heading [my ProcessLiteral [namespace tail $name]]
        if {0 && [string length $ns]} {
            # Links to class/namespace - disabled as it clutters navigation

            # An attempt to only show heading without namespace in ToC but
            # reftext only applies to cross-references, not ToC :-(
            append Document "\[reftext=\"$heading\"\]\n"

            set ns_link [my FormatInline [markup_reference $ns]]
            append heading " \[${ns_link}\]"
        }

        # Asciidoc headings use = signs, more = means deeper level
        set marker [string repeat = $level]
        append Document "$marker $heading\n"
    }

    method AddHeading {level text scope {tooltip {}}} {
        # See [Formatter.AddHeading].
        #  level   - The numeric or semantic heading level.
        #  text    - The heading text.
        #  scope   - The documentation scope of the content.
        #  tooltip - Tooltip (not used in Asciidoctor).

        if {![string is integer -strict $level]} {
            set level [dict get $HeaderLevels $level]
        }
        set do_link [expr {$level < [dict get $HeaderLevels nonav]}]

        if {$do_link} {
            set anchor [my MakeAsciidocId $scope $text]
            set exported_anchor [make_exported_id $scope $text]
            set linkinfo [dict create tag h$level href "#$anchor"]
            dict set linkinfo label $text
            append Document "\n\[\[$anchor\]\]\n"
            append Document "\[\[$exported_anchor\]\]\n"
        }

        set heading_text [my FormatInline $text $scope]

        if {$do_link} {
            set marker [string repeat = $level]
            append Document "$marker $heading_text\n"
        } else {
            # Use discrete heading (no TOC entry)
            append Document "\n\[discrete\]\n"
            set marker [string repeat = $level]
            append Document "$marker $heading_text\n"
        }

        return
    }

    method MarkupInlineHtml {html} {
        # Returns markup to pass inline HTML.
        #  html - HTML text to inline
        return "pass:\[" $html "\]"
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

        append Document "\n\[quote\]\n"
        append Document "____\n"
        foreach line $lines {
            append Document [my FormatInline $line $scope] \n
        }
        append Document "____\n\n"
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

            # Asciidoc definition list format
            append Document "${term}::\n"
            append Document "  $def\n"
        }
        append Document "\n"
        return
    }

    method AddTable {table scope} {
        # Adds a table to document content using Asciidoctor table format
        #  table  - Dictionary describing table
        #  scope  - The documentation scope of the content.

        # Get alignments if specified
        if {[dict exists $table alignments]} {
            set alignments [dict get $table alignments]
        } else {
            set alignments {}
        }

        # Get header and rows
        set rows [dict get $table rows]
        set has_header [dict exists $table header]

        # Calculate number of columns
        set num_cols 0
        if {$has_header} {
            set num_cols [llength [dict get $table header]]
        } elseif {[llength $rows] > 0} {
            set num_cols [llength [lindex $rows 0]]
        }

        if {$num_cols == 0} {
            return
        }

        append Document "\n"
        append Document "\[cols=\""
        
        # Build column spec with alignments
        set col_specs {}
        for {set i 0} {$i < $num_cols} {incr i} {
            set align [lindex $alignments $i]
            switch -exact -- $align {
                "left" { set align_char "<" }
                "center" { set align_char "^" }
                "right" { set align_char ">" }
                default { set align_char "<" }
            }
            lappend col_specs "${align_char}1"
        }
        append Document [join $col_specs ,]
        append Document "\""
        
        if {$has_header} {
            append Document ",options=\"header\""
        }
        append Document "\]\n"
        append Document "|===\n"

        # Add header row
        if {$has_header} {
            set header [dict get $table header]
            foreach cell $header {
                set cell_text [my FormatInline $cell $scope]
                append Document "| $cell_text\n"
            }
            append Document "\n"
        }

        # Add data rows
        foreach row $rows {
            foreach cell $row {
                set cell_text [my FormatInline $cell $scope]
                append Document "| $cell_text\n"
            }
            append Document "\n"
        }

        append Document "|===\n\n"
        return
    }

    method AddBullets {content scope} {
        # See [Formatter.AddBullets].
        #  content  - Dictionary with keys items and marker
        #  scope    - The documentation scope of the content.
        
        append Document "\n"
        set marker [dict get $content marker]
        # Asciidoc uses * for bullets and . for numbered
        set marker [expr {$marker eq "1." ? "." : "*"}]
        
        foreach lines [dict get $content items] {
            set bullet_text [my FormatInline [join $lines { }] $scope]
            # Handle multi-line bullets with proper continuation
            set bullet_lines [split $bullet_text \n]
            set first_line [lindex $bullet_lines 0]
            append Document "$marker $first_line\n"
            foreach line [lrange $bullet_lines 1 end] {
                if {$line ne ""} {
                    append Document "+\n$line\n"
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

        # Use Asciidoc literal block
        append Document "\n\[listing\]\n"
        append Document "----\n"
        append Document $text \n
        append Document "----\n\n"
        return
    }

    method AddFenced {lines fence_options scope} {
        # Adds a list of fenced lines to document content.
        #  lines - Preformatted text as a list of lines.
        #  fence_options - options controlling generation and layout
        #  scope - The documentation scope of the content.

        # Process caption
        if {[dict exists $fence_options -caption]} {
            set caption [dict get $fence_options -caption]
            set anchor [my MakeAsciidocId $scope $caption]
            set exported_anchor [make_exported_id $scope $caption]
            if {[my ResolvableReference? $caption $scope ref] && [dict exists $ref label]} {
                set display_caption [dict get $ref label]
            } else {
                set display_caption $caption
            }
        } else {
            set caption ""
            set display_caption ""
            set anchor ""
            set exported_anchor ""
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

            append Document "\n"
            if {$anchor ne ""} {
                append Document "\[\[$anchor\]\]\n"
                append Document "\[\[$exported_anchor\]\]\n"
            }

            if {$display_caption ne ""} {
                append Document ".$display_caption\n"
            }

            # Process alignment
            set align_attr ""
            if {[dict exists $fence_options -align]} {
                set align_value [dict get $fence_options -align]
                set align_attr "align=$align_value"
            }

            if {$align_attr ne ""} {
                append Document "\[$align_attr\]\n"
            }
            append Document "image::$image_url\[\]\n\n"
        } else {
            # Use Asciidoc source block
            set lang [dict get $fence_options Language]
            if {$lang eq ""} {
                set lang "text"
            }

            append Document "\n"
            if {$anchor ne ""} {
                append Document "\[\[$anchor\]\]\n"
                append Document "\[\[$exported_anchor\]\]\n"
            }

            if {$display_caption ne ""} {
                append Document ".$display_caption\n"
            }

            append Document "\[source,$lang\]\n"
            append Document "----\n"
            append Document [join $lines \n] \n
            append Document "----\n\n"
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
            append Document "*[join $cmds { }]*"
            if {[llength $params]} {
                append Document " _[join $params { }]_"
            }
            append Document "\n"
        }
        append Document "\n"
        return
    }

    method Navigation {{highlight_ns {}}} {
        # Asciidoctor can generate its own TOC
        return
    }

    method Escape {text} {
        # Escapes special characters in Asciidoc inline markup
        #  text - string to be escaped
        # Returns the escaped string

        # Asciidoc special characters that need escaping in text
        # Backslash escapes most special chars
        set result {}
        set len [string length $text]

        for {set i 0} {$i < $len} {incr i} {
            set chr [string index $text $i]

            # Check common case first
            if {[string match {[a-zA-Z0-9]} $chr]} {
                append result $chr
            } elseif {$chr eq "\\"} {
                # Backslashes need escaping
                append result "\\" $chr
            } elseif {$chr in {* _ ` # + |}} {
                # These can trigger markup in certain contexts
                set prev_chr [string index $text $i-1]
                set next_chr [string index $text $i+1]
                
                # Escape if at markup boundary
                if {($prev_chr == "" || [regexp {[\s\(\[\{<'"]} $prev_chr]) &&
                    ($next_chr ne "" && ![regexp {[\s\)\]\}>'"]} $next_chr])} {
                    append result "\\" $chr
                } else {
                    append result $chr
                }
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

        # Asciidoc: _ for italic, * for bold, *_ for bold italic
        switch -exact $delim {
            * {
                return [string cat _ [my FormatInline $text $scope] _]
            }
            ** {
                return [string cat * [my FormatInline $text $scope] *]
            }
            *** {
                return [string cat *_ [my FormatInline $text $scope] _*]
            }
            default {
                error "Invalid emphasis delimiter length [string length $delim]."
            }
        }
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
        #  title - link title (not used)
        #  scope - documentation scope (not used)
        #  link_type - link type (not used)

        if {$text eq ""} {
            return $url
        } else {
            return [string cat $url "\[" $text "\]"]
        }
    }

    method ProcessInlineImage {url text title scope {link_type {}}} {
        # Returns markup for inline images
        #  url - the image URL
        #  text - alt text
        #  title - image title (not used)
        #  scope - documentation scope (not used)
        #  link_type - link type (not used)

        return [string cat "image:" $url "\[" $text "\]"]
    }

    method ProcessInternalLink {code_link text scope} {
        # Returns the markup for internal Ruff links.
        #  code_link - dictionary holding resolvable internal link information
        #  text - the link text. If empty the label from `code_link` is used.
        #  scope - Documentation scope for resolving references.

        if {$text eq ""} {
            set text [my Escape [dict get $code_link label]]
        }
        set ref [dict get $code_link ref]
        return [string cat "<<" $ref "," $text ">>"]
    }

    method ProcessComment {text} {
        # Returns the markup for a comment.

        set comment ""
        foreach line [split $text \n] {
            append comment "// " [my Escape $line] \n
        }
        return $comment
    }

    method extension {} {
        # Returns the default file extension to be used for output files.
        return adoc
    }

    method finalize {output_dir output_paths} {
        # Called after all output files are written out.
        #   output_dir - root of output directory
        #   output_paths - full paths to files written
        #
        # Writes out the Asciidoctor index.adoc main content.

        set fd [open [file join $output_dir index.adoc] w]

        if {![my Option? -product product]} {
            set product "Documentation"
        }
        puts $fd "= $product"

        if {[my Option? -version version]} {
            puts $fd ":revnumber: $version"
        }

        puts $fd ":toc: left"
        puts $fd ":toclevels: 4"

        # Asciidoctor heading levels cannot be 1 unless build type is book so
        # bump Ruff~ output by 1.
        puts $fd ":leveloffset: 1"
        puts $fd ""

        foreach path $output_paths {
            set basename [file rootname [file tail $path]]
            puts $fd "include::$basename.adoc\[\]"
            puts $fd ""
        }

        # Only certain asciidoctor backends support indexes
        puts $fd {
// NOTE: if Index is not top level heading, asciidoctor-pdf does not
// place it on a new page causing blank space at top of every index page
ifdef::backend-pdf,backend-docbook5[]
[index]
= Index
endif::[]
}
        close $fd

        return
    }
}
