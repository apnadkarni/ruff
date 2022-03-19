# Copyright (c) 2021, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the source root directory for license.

# Ruff! formatter for nroff

namespace eval ruff::formatter {}

oo::class create ruff::formatter::Nroff {
    superclass ::ruff::formatter::Formatter

    # Data members
    variable DocumentNamespace; # Namespace being documented
    variable Header;          # Common header for all pages
    variable PageTitle;       # Page title - first line of man page
    variable Synopsis;        # Holds the synopsis
    variable Body;            # Main content
    variable Footer;          # Common footer
    variable HeaderLevels;    # Header levels for various headers
    variable SeeAlso;         # The See also section

    variable Indentation; # How much to indent in nroff units

    constructor args {
        namespace path [linsert [namespace path] 0 ::ruff::formatter::nroff]
        set HeaderLevels {
            class 3
            proc 4
            method 4
            nonav 5
            parameters 5
        }
        set Indentation 4n
        next {*}$args
    }

    method CollectReferences args {}
    method CollectHeadingReference args {}
    method CollectFigureReference args {}
    export CollectFigureReference

    method Begin {} {
        # Implements the [Formatter.Begin] method for nroff.

        next

        # Generate the header used by all files
        # Currently, it is empty but might change in the future with
        # support for specific dialects which implement metainformation.
        set Header ""

        append Header [nr_comment "\n"]
        if {[my Option? -copyright copyright]} {
            append Header [nr_comment "Copyright (c) [my Escape $copyright]\n"]
        }

        # Generate the Footer used by all files
        set Footer ""
        return
    }

    method DocumentBegin {ns} {
        # See [Formatter.DocumentBegin].
        # ns - Namespace for this document.
        set ns [string trimleft $ns :]

        next $ns

        set DocumentNamespace $ns
        set Body ""
        set Synopsis ""
        set SeeAlso ""

        return
    }

    method DocumentEnd {} {
        # See [Formatter.DocumentEnd].

        set title [my Option -title]
        set section [my Option -section 3tcl]
        set version [my Option -version 0.0]
        set product [my Option -product $DocumentNamespace]
        if {$DocumentNamespace eq ""} {
            set header_left $product
        } else {
            set header_left $DocumentNamespace
        }
        set PageTitle [nr_title "\"$header_left\" $section $version \"$product\" \"$title\""]

        # Add the navigation bits and footer
        append doc $Header $PageTitle
        append doc [nr_section NAME] \n
        if {$DocumentNamespace eq ""} {
            append doc "Introduction - $title"
        } else {
            append doc "$DocumentNamespace - Commands in namespace $DocumentNamespace"
        }
        if {$Synopsis ne ""} {
            append doc [nr_section SYNOPSIS] \n $Synopsis
        }
        append doc $Body
        if {$SeeAlso ne ""} {
            append doc [nr_section "SEE ALSO"] $SeeAlso
        }
        append doc $Footer
        set doc [nroff_postprocess $doc]

        next

        return $doc
    }

    method AddProgramElementHeading {type fqn {tooltip {}} {synopsis {}}} {
        # Adds heading for a program element like procedure, class or method.
        #  type - One of `proc`, `class` or `method`
        #  fqn - Fully qualified name of element.
        #  tooltip - The tooltip lines, if any. Ignore for nroff output.

        set level [dict get $HeaderLevels $type]
        set ns    [namespace qualifiers $fqn]
        set name  [namespace tail $fqn]
        if {[string length $ns]} {
            append Body [nr_p] [nr_inn -$Indentation] \n [nr_bldr [namespace tail $name]] " ($ns)"
        } else {
            append Body [nr_p] [nr_inn -$Indentation] \n [nr_bldr $name]
        }
        append Body [nr_out]
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

        # TBD - should $text really be passed through ToNroff? In particular do
        # commands like .SH accept embedded escapes ?
        set text [my ToNroff $text $scope]
        if {$level < 3} {
            append Body [nr_section $text]
        } elseif {$level == 3} {
            append Body [nr_subsection $text]
        } else {
            append Body [nr_p] [nr_bldr $text]
        }
        return
    }

    method AddParagraph {lines scope} {
        # See [Formatter.AddParagraph].
        #  lines  - The paragraph lines.
        #  scope - The documentation scope of the content.
        append Body [nr_p] [my ToNroff [join $lines \n] $scope]
        return
    }

    method AddDefinitions {definitions scope {preformatted none}} {
        # See [Formatter.AddDefinitions].
        #  definitions  - List of definitions.
        #  scope        - The documentation scope of the content.
        #  preformatted - One of `none`, `both`, `term` or `definition`
        #                 indicating which fields of the definition are
        #                 are already formatted.

        # Note: CommonMark does not recognize tables without a heading line
        # TBD - how do empty headers look in generated HTML?
        set autopunctuate [my Option -autopunctuate 0]
        append Body [nr_inn $Indentation]
        foreach item $definitions {
            set def [join [dict get $item definition] " "]
            if {$autopunctuate} {
                set def [string toupper $def 0 0]
                if {[regexp {[[:alnum:]]} [string index $def end]]} {
                    append def "."
                }
            }
            if {$preformatted in {none term}} {
                set def [my ToNroff $def $scope]
            }
            set term [dict get $item term]
            if {$preformatted in {none definition}} {
                set term [my ToNroff $term $scope]
            }
            append Body [nr_blt $term] "\n" $def
        }
        append Body [nr_out]

        return
    }

    method AddBullets {bullets scope} {
        # See [Formatter.AddBullets].
        #  bullets  - The list of bullets.
        #  scope    - The documentation scope of the content.
        foreach lines $bullets {
            append Body [nr_blt "\n\1\\(bu"] "\n" [my ToNroff [join $lines { }] $scope]
        }
        return
    }

    method AddPreformattedText {text scope} {
        # See [Formatter.AddPreformattedText].
        #  text  - Preformatted text.
        #  scope - The documentation scope of the content.

        append Body [nr_p] [nr_inn $Indentation] [nr_nofill]  \n
        append Body $text
        append Body [nr_fill] [nr_out]
        return
    }

    method AddFenced {lines fence_options scope} {
        # See [Formatter.AddFenced].
        # Adds a list of fenced lines to document content.
        #  lines - Preformatted text as a list of lines.
        #  fence_options - options specified with the fence, e.g. diagram ...
        #  scope - The documentation scope of the content.
        # Only obeys -caption option, ignores all else
        append Body [nr_p] [nr_inn $Indentation] [nr_nofill]  \n
        append Body [join $lines \n]
        if {[dict exists $fence_options -caption]} {
            append Body \n\n [nr_ulp [dict get $fence_options -caption]] \n
        }
        append Body [nr_fill] [nr_out]
        return
    }

    method AddSynopsis {synopsis scope} {
        # Adds a Synopsis section to the document content.
        #  synopsis - List of alternating elements comprising the command portion
        #             and the parameter list for it.
        #  scope  - The documentation scope of the content.

        append Body [nr_inn $Indentation]; # Indent the synopsis
        foreach {cmds params} $synopsis {
            set line "[nr_bldp [join $cmds { }]]"
            if {[llength $params]} {
                append line " " [nr_ulp [join $params { }]] 
            }
            append Synopsis $line [nr_br]
            append Body $line [nr_br]
        }
        append Body [nr_out] \n
        return
    }

    method Navigation {{highlight_ns {}}} {
        # TBD - right now, no navigation for markdown.
        return
    }

    method Escape {s} {
        # Escapes special characters in nroff.
        #  s - string to be escaped
        # Protects characters in $s against interpretation as
        # nroff special characters.
        #
        # Returns the escaped string

        # TBD - fix this?
        return [string map [list \\ \\\\] $s]
    }

    # Credits: tcllib/Caius markdown module
    method ToNroff {text {scope {}}} {
        # Returns $text marked up in nroff syntax
        #  text - Ruff! text with inline markup
        #  scope - namespace scope to use for symbol lookup

        # Passed in text is kinda markdown but with some extensions:
        # - [xxx] treats xxx as potentially a link to documentation for
        # some programming element.
        # - _ is not treated as a special char
        # - $var is marked as a variable name
        # Moreover, we cannot use a simple regexp or subst because
        # whether this special processing will depend on where inside
        # the input these characters occur, whether a \ preceded etc.

        set text [regsub -all -lineanchor {[ ]{2,}$} $text [nr_br]]

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
                    # If next character is a special markdown char, set that as the
                    # the character. Otherwise just pass this \ as the character.
                    set next_chr [string index $text [expr $index + 1]]
                    if {[string first $next_chr {\`*_\{\}[]()#+-.!>|}] != -1} {
                        set chr $next_chr
                        incr index
                    }
                }
                {_} {
                    # Unlike Markdown, underscores are not treated as special char
                }
                {*} {
                    # EMPHASIS
                    if {[regexp $re_whitespace [string index $result end]] &&
                        [regexp $re_whitespace [string index $text [expr $index + 1]]]} \
                        {
                            #do nothing (add character at bottom of loop)
                        } elseif {[regexp -start $index \
                                       "\\A(\\$chr{1,3})((?:\[^\\$chr\\\\]|\\\\\\$chr)*)\\1" \
                                     $text m del sub]} {
                            switch [string length $del] {
                                1 {
                                    # * - Emphasis
                                    append result "[nr_ul][my ToNroff $sub $scope][nr_fpop]"
                                }
                                2 {
                                    # ** - Strong
                                    append result "[nr_bld][my ToNroff $sub $scope][nr_fpop]"
                                }
                                3 {
                                    # *** - Strong+emphasis - no way I think. Make bold
                                    append result "[nr_bld][my ToNroff $sub $scope][nr_fpop]"
                                }
                            }

                            incr index [string length $m]
                            continue
                    }
                }
                {`} {
                    # CODE
                    # Any marked code should not be escaped as above so
                    # look for it and pass it through as is.
                    # TBD - anything needed to pass text verbatim?

                    # Collect the leading backtick sequence
                    regexp -start $index $re_backticks $text backticks
                    set start [expr $index + [string length $backticks]]

                    # Look for the matching backticks. If not found,
                    # we will not treat this as code. Otherwise pass through
                    # the entire match unchanged.
                    if {[regexp -start $start -indices $backticks $text terminating_indices]} {
                        set stop [expr {[lindex $terminating_indices 0] - 1}]

                        set sub [string trim [string range $text $start $stop]]

                        append result "[my Escape $sub]"
                        set index [expr [lindex $terminating_indices 1] + 1]
                        continue
                    }
                }
                {!} -
                "\[" {
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
                        incr index [string length $m]

                        set url [my Escape [string trim $url {<> }]]
                        set txt [my ToNroff $txt $scope]
                        set title [my ToNroff $title $scope]

                        set match_found 1
                    } elseif {[regexp -start $index $re_reflink $text m txt lbl]} {
                        if {$lbl eq {}} {
                            # Be loose in whitespace
                            set lbl [regsub -all {\s+} $txt { }]
                            set display_text_specified 0
                        } else {
                            set display_text_specified 1
                        }

                        set code_link ""
                        if {[my ResolvableReference? $lbl $scope code_link]} {
                            # RUFF CODE REFERENCE
                            set url [my Escape [dict get $code_link ref]]
                        } else {
                            set url ""
                        }
                        if {! $display_text_specified && $code_link ne ""} {
                            set txt [my Escape [dict get $code_link label]]
                        }
                        set title $txt
                        incr index [string length $m]
                        set match_found 1
                    }
                    # PRINT IMG, A TAG
                    if {$match_found} {
                        if {$ref_type eq {link}} {
                            # TBD - some nroff version support urls using .UR
                            append result [nr_ulr $txt]
                            if {$url ne ""} {
                                append result " \[URL: $url\]"
                            }
                        } else {
                            app::log_error "Warning: Image URL $url found. Images are not supported for Nroff output."
                            append result $txt " \[Image: $url\]"
                        }

                        continue
                    }
                }
                {<} {
                    # HTML TAGS, COMMENTS AND AUTOLINKS
                    # HTML tags, pass through as is without processing

                    if {[regexp -start $index $re_comment $text m]} {
                        append result [nr_comment [string range $m 4 end-3]]
                        incr index [string length $m]
                        continue
                    } elseif {[regexp -start $index $re_autolink $text m email link]} {
                        if {$link ne {}} {
                            set link [my Escape $link]
                            append result " \[URL: $link\]"
                        } else {
                            set mailto_prefix "mailto:"
                            if {![regexp "^${mailto_prefix}(.*)" $email mailto email]} {
                                # $email does not contain the prefix "mailto:".
                                set mailto "mailto:$email"
                            }
                            append result "<a href=\"$mailto\">$email</a>"
                            append result " \[$mailto\]"
                        }
                        incr index [string length $m]
                        continue
                    } elseif {[regexp -start $index $re_htmltag $text m]} {
                        app::log_error "Warning: HTML tag $m skipped. HTML tags not supported by Nroff formatter."
                        incr index [string length $m]
                        continue
                    }
                    # Else fall through to pass only the < character
                }
                {&} {
                    # ENTITIES
                    # Pass through entire entity without processing
                    # TBD - add support for more entities
                    if {[regexp -start $index $re_entity $text m]} {
                        set html_mapping [list "&quot;" \" "&apos;" ' "&amp;" & "&lt;" <  "&gt;" >]
                        append result [string map $html_mapping $m]
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
                        append result [nr_ulr $m]
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
        return 3tcl
    }

    forward FormatInline my ToNroff
}

# MODFIED/ADAPTED From tcllib - BSD license.]
namespace eval ruff::formatter::nroff {
    # -*- tcl -*-
    #
    # -- nroff commands
    #
    # Copyright (c) 2003-2019 Andreas Kupries <andreas_kupries@sourceforge.net>

    ################################################################
    # nroff specific commands
    #
    # All dot-commands (f.e. .PP) are returned with a leading \n\1,
    # enforcing that they are on a new line and will be protected as markup.
    # Any empty line created because of this is filtered out in the 
    # post-processing step.


    proc nr_lp      {}          {return \n\1.LP}
    proc nr_ta      {{text {}}} {return "\n\1.ta$text"}
    proc nr_bld     {}          {return \1\\fB}
    proc nr_bldt    {t}         {return "\n\1.B $t\n"}
    proc nr_bldr    {t}         {return \1\\fB$t[nr_rst]}
    proc nr_bldp    {t}         {return \1\\fB$t[nr_fpop]}
    proc nr_ul      {}          {return \1\\fI}
    proc nr_ulr     {t}         {return \1\\fI$t[nr_fpop]}
    proc nr_ulp     {t}         {return \1\\fI$t[nr_fpop]}
    proc nr_rst     {}          {return \1\\fR}
    proc nr_fpop    {}          {return \1\\fP}
    proc nr_p       {}          {return \n\1.PP\n}
    proc nr_comment {text}      {return "\1'\1\\\" [join [split $text \n] "\n\1'\1\\\" "]"} ; # "
    proc nr_enum    {num}       {nr_item " \[$num\]"}
    proc nr_item    {{text {}}} {return "\n\1.IP$text"}
    proc nr_vspace  {}          {return \n\1.sp\n}
    proc nr_br      {}          {return \n\1.br\n}
    proc nr_blt     {text}      {return "\n\1.TP\n$text"}
    proc nr_bltn    {n text}    {return "\n\1.TP $n\n$text"}
    proc nr_in      {}          {return \n\1.RS}
    proc nr_inn     {n}         {return "\n\1.RS $n"}
    proc nr_out     {}          {return \n\1.RE}
    proc nr_nofill  {}          {return \n\1.nf}
    proc nr_fill    {}          {return \n\1.fi}
    proc nr_title   {text}      {return "\n\1.TH $text"}
    proc nr_include {file}      {return "\n\1.so $file"}
    proc nr_bolds   {}          {return \n\1.BS}
    proc nr_bolde   {}          {return \n\1.BE}
    proc nr_read    {fn}        {return [nroffMarkup [dt_read $fn]]}
    proc nr_cs      {}          {return \n\1.CS\n}
    proc nr_ce      {}          {return \n\1.CE\n}

    proc nr_section {name} {
        if {![regexp {[ 	]} $name]} {
            return "\n\1.SH [string toupper $name]"
        }
        return "\n\1.SH \"[string toupper $name]\""
    }
    proc nr_subsection {name}   {
        if {![regexp {[ 	]} $name]} {
            return "\n\1.SS [string toupper $name]"
        }
        return "\n\1.SS \"[string toupper $name]\""
    }


    ################################################################

    # Handling of nroff special characters in content:
    #
    # Plain text is initially passed through unescaped;
    # internally-generated markup is protected by preceding it with \1.
    # The final PostProcess step strips the escape character from
    # real markup and replaces unadorned special characters in content
    # with proper escapes.
    #

    variable   markupMap
    set      markupMap [list \
                            "\\"   "\1\\" \
                            "'"    "\1'" \
                            "."    "\1." \
                            "\\\\" "\\"]
    variable   finalMap
    set      finalMap [list \
                           "\1\\" "\\" \
                           "\1'"  "'" \
                           "\1."  "." \
                           "."    "\\&." \
                           "\\"   "\\\\"]
    variable   textMap
    set      textMap [list "\\" "\\\\"]


    proc nroffEscape {text} {
        variable textMap
        return [string map $textMap $text]
    }

    # markup text --
    #	Protect markup characters in $text.
    #	These will be stripped out in PostProcess.
    #
    proc nroffMarkup {text} {
        variable markupMap
        return [string map $markupMap $text]
    }

    proc nroff_postprocess {nroff} {
        variable finalMap

        # Postprocessing final nroff text.
        # - Strip empty lines out of the text
        # - Remove leading and trailing whitespace from lines.
        # - Exceptions to the above: Keep empty lines and leading
        #   whitespace when in verbatim sections (no-fill-mode)

        set nfMode   [list \1.nf \1.CS]	; # commands which start no-fill mode
        set fiMode   [list \1.fi \1.CE]	; # commands which terminate no-fill mode
        set lines    [list]         ; # Result buffer
        set verbatim 0              ; # Automaton mode/state

        foreach line [split $nroff "\n"] {
            #puts_stderr |[expr {$verbatim ? "VERB" : "    "}]|$line|

            if {!$verbatim} {
                # Normal lines, not in no-fill mode.

                if {[lsearch -exact $nfMode [split $line]] >= 0} {
                    # no-fill mode starts after this line.
                    set verbatim 1
                }

                # Ensure that empty lines are not added.
                # This also removes leading and trailing whitespace.

                if {![string length $line]} {continue}
                set line [string trim $line]
                if {![string length $line]} {continue}

                if {[regexp {^\x1\\f[BI]\.} $line]} {
                    # We found confusing formatting at the beginning of
                    # the current line. We lift this line up and attach it
                    # at the end of the last line to remove this
                    # irregularity. Note that the regexp has to look for
                    # the special 0x01 character as well to be sure that
                    # the sequence in question truly is formatting.
                    # [bug-3601370] Only lift & attach if last line is not
                    # a directive

                    set last  [lindex   $lines end]
                    if { ! [string match "\1.*" $last] } {
                        #puts_stderr \tLIFT
                        set lines [lreplace $lines end end]
                        set line "$last $line"
                    }
                } elseif {[string match {[']*} $line]} {
                    # Apostrophes at the beginning of a line have to be
                    # quoted to prevent misinterpretation as comments.
                    # The true comments and are quoted with \1 already and
                    # will therefore not detected by the code here.
                    # puts_stderr \tQUOTE
                    set line \1\\$line
                } ; # We are not handling dots at the beginning of a line here.
                #   # We are handling them in the finalMap which will quote _all_
                #   # dots in a text with a zero-width escape (\&).
            } else {
                # No-fill mode. We remove trailing whitespace, but keep
                # leading whitespace and empty lines.

                if {[lsearch -exact $fiMode [split $line]] >= 0} {
                    # Normal mode resumes after this line.
                    set verbatim 0
                }
                set line [string trimright $line]
            }
            lappend lines $line
        }

        set lines [join $lines "\n"]

        # Now remove all superfluous .IP commands (empty paragraphs). The
        # first identity mapping is present to avoid smashing a man macro
        # definition.

        lappend map	\n\1.IP\n\1.\1.\n  \n\1.IP\n\1.\1.\n
        lappend map \n\1.IP\n\1.       \n\1.

        set lines [string map $map $lines]

        # Return the modified result buffer
        return [string trim [string map $finalMap $lines]]\n
    }
}
