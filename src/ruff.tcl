# Copyright (c) 2009-2019, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the source root directory for license.

# Ruff! - RUntime Formatting Function
# ...a document generator using introspection
#

package require Tcl 8.6
package require textutil::adjust
package require textutil::tabify

namespace eval ruff {
    variable version 0.6.0

    variable _ruff_intro {
        ## Introduction

        Ruff! (Runtime function formatter) is a documentation generation system
        for programs written in the Tcl programming language. Ruff! uses runtime
        introspection in conjunction with comment analysis to generate reference
        manuals for Tcl programs.

        Ruff! is covered by a liberal BSD open-source license that permits use
        for any purpose.

        ## Why Ruff!

        In comparison with other source code based documentation generators,
        Ruff! produces documentation that not only requires less effort from the
        programmer, but is also more complete, more accurate and more
        maintainable.

        Ruff! saves the programmer the initial effort required for
        documentation:

        * Comments in source code do not have to be
        reproduced for documentation purposes.
        * Ruff! requires minimal
        markup in the comments making it very lightweight.
        * Program elements
        like command arguments and defaults and relatonships like
        inheritance are automatically derived.

        Further, maintaining documentation in sync with the code is much
        easier. For example, changing the defaults for arguments, or adding
        a mix-in to a class, is taken care of with no additional
        effort needed to document the changes.

        On the output side,

        * Ruff! supports multiple formats (currently HTML and Markdown).

        * Generated documentation can be within a single page or across multiple
          pages, one per namespace.

        * Hyperlinks between program elements, and optionally source code,
        making navigation easy and efficient.

        * In object oriented code, class relationships are extracted
        and the full API for a class, with inherited and mixed-in methods, is
        easily seen.

        The Ruff! documentation itself is produced with Ruff!.
        For larger examples (though with older versions)
        are the reference pages for [Woof!](http://woof.sourceforge.net/woof-ug-0.5/html/_woof/woof_manual.html)
        and [CAWT](http://www.posoft.de/download/extensions/Cawt/CawtReference-1.2.0.html).

        ## Documentation

        The [::ruff] reference page describes the Ruff! documentation generation
        API. The [::ruff::sample] page shows some sample output for some of the
        Ruff! features along with the associated source code from which
        it was generated.

    }
    variable _ruff_preamble {
        ## Usage

        Ruff! is not intended to be a standalone script. Rather the package
        provides commands that should be driven from a script that controls
        which particular namespaces, classes etc. are to be included.
        Include the following command to load the package into your script.

            package require ruff

        Once loaded, you can use the [document] command to document
        classes and commands within one or more namespaces.

        The following command will create the file `NS.html` using the
        built-in HTML formatter.
        ````
        package require ruff
        ::ruff::document html [list ::NS] -output NS.html -recurse true
        ````
        Refer to [document] for various options that control the
        content included in the documentation.

        ## Documenting procedures

        Ruff! generates documentation using Tcl's runtime system to gather
        proc definitions. Comments in procedure bodies are further parsed to
        extract the documentation for the procedure.

        The structure Ruff! expects is described below. In practice,
        the structure is simple and intuitive though the description may be
        a bit long winded. You can simply look at the documentation
        of the [sample] namespace instead, and click on the `Show source`
        links for each procedure or class there to see the formatting.

        The first block of comments within a procedure that appear before
        the first line of code are always processed by Ruff!. Note preceding
        blank lines are OK. We will refer to this block as the lead comment
        block. It is terminated by either a line of code or a completely
        blank line (without even the comment character).

        Any comments appearing after the first line of code are not
        processed by Ruff! unless immediately preceded by a line beginning
        with `#ruff` which indicates the start of another Ruff! comment
        block.

        The lead comment block begins with a summary line that will be used
        anywhere the document output inserts a procedure summary, for
        example, in the Table of Contents. It also appears as the first
        paragraph in the **Description** section of procedure. The summary
        line is terminated with a blank comment or by the parameter block.

        The parameter block is a definition list (see below) and follows its
        syntactic structure. It only differs from definition lists in that
        it must directly follow the summary line and receives special
        treatment in that the default value, if any for the argument, is
        automatically inserted by Ruff!. Options and switches may also be
        documented here as shown in the example above. The parameter block
        is terminated by a blank comment or a blank line or code.

        Any blocks following the parameter block, whether part of the lead
        block or appearing in a subsequent comment block marked with a
        leading `#ruff`, are processed as follows.

        * All processed lines are stripped of the leading `#` character and a
        single following space if there is one.

        * A line containing 3 or more consecutive backquote (\`) characters
        with only surrounding whitespace on the line starts a preformatted
        block. The block is terminated by another such sequence and
        all intervening lines are passed through to the output unchanged.

        * If the line is indented 4 or more spaces, it is treated a
        preformatted line and passed through to the output with the
        the first 4 spaces stripped. No other processing is done on the line.

        * Lines starting with a `-` or a `*` character followed by at least
        one space are treated as a bulleted list item.

        * Lines containing a `-` surrounded by whitespace is treated as a
        definition list element. The text before the `-` separator is the
        definition term and the text after is the description. The built-in
        HTML formatter displays definition lists as tables. Note parameter
        blocks have the same format and are distringuished from definition
        lists only by their presence in the lead block.

        * Any line beginning with the word `Returns` is treated as
        description of the return value.

        * A line beginning with `See also:` (note the colon) is
        assumed to be a list of program element names. These are then
        automatically linked and listed in the *See also* section of
        a procedure documentation.

        * All other lines are treated as part of the previous block of
        lines. In the case of list elements, including parameter blocks and
        definition lists, the line is only treated as a continuation if its
        indentation is not less than the indentation of the first line of
        that list element. Otherwise it is treated as the start of a text
        paragraph. Lines following a blank line or a blank comment line are
        also treated as the start of a normal text paragraph.

        Refer to those commands for the syntax and comment structure expected
        by Ruff!.

        ### Differences from Markdown

        * no nested blocks
        * no numbered lists or multi-paragraph list elements
        * no blockquotes

        * definition lists

        ## Documenting classes

        Documentation for class methods is exactly as described above for
        procedures. Information about class relationships is automatically
        collected and need not be explicitly provided. Note that unlike for
        procedures and methods, Tcl does not provide a means to retrieve the
        body of the class so that comments can be extracted from them. Thus
        to document information about the class as a whole, you can either
        include it in the comments for the constructor, which is often a
        reasonable place for such information, or include it in the general
        information section as described in the next section.

        ## Documenting namespaces

        Documentation for a namespace is generated by looking for the
        variable `_ruff_premble` within the namespace. If present, its content
        should be a list of alternating pairs comprising a section title and
        section content.

        The section content is processed in the same manner as the procedure
        and method bodies except that (obviously) there is no
        summary or parameter block. The indentation of the first line
        of section content is stripped off from all subsequent lines
        before processing or Ruff! (This impacts what constitutes a
        preformatted line).

        Additionally, section content may contain Markdown ATX style
        headings indicated by a prefix of one or more `#` characters.

        The documentation generated from the `_ruff_preamble` content is placed
        before the documentation of the commands in classes for that namespace.

        ## Inline formatting

        The text within paragraphs can be formatted as bold, italic, code
        etc. by using Markdown syntax with some minor extensions. Note
        Markdown compatibility is only for inline elements. **Markdown block
        level markup is not supported.**

        In particular, the following inline markup is supported:

        \`   - `Text surrounded by backquotes is formatted as inline code`.
        `*`    - *Text surrounded by single asterisks is emphasized*.
        `**`   - **Text surrounded by double asterisks is bolded**.
        `***`  - ***Text surrounded by triple asterisks is bold emphasized***.
        `[]`   - Text surrounded by square brackets is treated as a link
        (more below).
        `<>`   - Text in angle brackets are treated as HTML tags and
        auto-links as in Markdown.
        `$`    - Words beginning with `$` are treated as variable names and
        shown as inline code similar to backquotes (non-standard Markdown).

        The default HTML formatter supports other Markdown inline elements
        but other formatters might not.

        Text enclosed in `[]` is checked whether it references a section heading
        or a program element name (namespaces, classes, methods, procedures). If
        so, it is replaced by a link to the section or documentation of that
        element. If the text is not a fully qualified name, it is treated
        relative to namespace or class within whose documentation the link
        appears. If it is fully qualified, it is displayed relative to the
        namespace of the link location. For example,

        * `[document]` is displayed as [document]
        * `[::ruff::formatters]` is displayed as [::ruff::formatters] if
        referenced from within a section documenting the `::ruff` namespace.

        If the text does not match a section heading or program element name, it
        is treated as a normal Markdown reference but a warning is emitted.

        ## Output

        Ruff! is designed to support multiple output formats through pluggable
        formatters. The command [formatters] returns a list of supported
        formatters. Currently formatters for producing HTML and Markdown are
        implemented.

        In addition, the output may be produced in single or multipage format.

        ### Multipage output

        The generated documentation may be either in a single output file or
        spread across multiple files. This is controlled
        by the `-pagesplit` option to the [document] command. Some formatters
        may not support this feature.

        When generating multipage output, the toplevel generated page contains
        links to the other pages which contain per-namespace documentation.
        The preamble (passed as the `-preamble` option to the [document] command) 
        is also placed in this page.

        ### HTML formatter

        The internal HTML formatter offers (in the author's humble opinion) the
        best cross-linking and navigation support with a table of contents in
        addition to cosmetic enhancements such as tooltips and optional
        hiding/display of source code. It is also the simplest to use as no
        other external tools are required.

        The following is a simple example of generating the documentation for
        Ruff! itself:

        ```
        ruff::document html ::ruff -output ruff.html -title "Ruff! reference"
        ```

        ### Markdown formatter

        The Markdown formatter generates output in generic Markdown syntax.
        It includes cross-linking but does not include a table of contents,
        tooltips or source code display. On the other hand, it allows conversion
        to other formats using external tools.

        The following generates Ruff! documentation in Markdown format and
        then uses `pandoc` to convert it to HTML.
        ```
        ruff::document markdown ::ruff -output ruff.md -title "Ruff! reference"
        ```
        Then from the shell command line,
        ```
        pandoc -s -o ruff.html -c ruff.css ruff.md
        ```

        When generating HTML from Markdown, it is generally desirable to specify
        a CSS style file. The `ruff.css` file provides some minimal CSS that
        resembles the output of the internal HTML formatter.

    }

    namespace eval private {
        namespace path [namespace parent]

        variable ruff_dir
        set ruff_dir [file dirname [info script]]
        proc ruff_dir {} {
            variable ruff_dir
            return $ruff_dir
        }
        proc read_ruff_file {fn} {
            set fd [open [file join [ruff_dir] $fn] r]
            set data [read $fd]
            close $fd
            return $data
        }
        variable names
        set names(display) "Ruff!"
        set names(longdisplay) "Runtime Function Formatter"

        # Base file name for output. Needed for linking.
        variable output_file_base ""
        # Extension of base output file
        variable output_file_ext ""
    } 
    namespace path private
}

# TBD - is this needed
proc ruff::private::identity {s} {
    # Returns the passed string unaltered.
    # Used as a stub to "no-op" some transformations
    return $s
}

proc ruff::private::ns_canonicalize {name} {
    return [regsub {:::*} $name ::]
}

proc ruff::private::fqn? {name} {
    # Returns `1` if $name is fully qualified, else `0`.
    return [string match ::* $name]
}

proc ruff::private::fqn! {name} {
    # Raises an error if $name is not a fully qualified name.
    if {![fqn? $name]} {
        error "\"name\" is not fully qualified."
    }
}

proc ruff::private::ns_member! {fqns name} {
    if {[namespace qualifiers [ns_canonicalize $name]] ne [ns_canonicalize $fqns]} {
        error "Name \"$name\" does not belong to the \"$fqns\" namespace."
    }
}

proc ruff::private::program_option {opt} {
    variable ProgramOptions
    return $ProgramOptions($opt)
}

proc ruff::private::ns_file_base {ns {ext {}}} {
    # Returns the file name to use for documenting namespace $ns.
    # ns - the namespace for the file
    # ext - if non-empty, this is used as the file extension.
    #  It should include the initial period.
    variable output_file_base
    variable output_file_ext
    variable ns_file_base_cache
    variable ProgramOptions
    if {![info exists ns_file_base_cache($ns)]} {
        if {$ProgramOptions(-pagesplit) eq "none" || $ns eq "::"} {
            set fn "$output_file_base$output_file_ext"
        } else {
            set fn "${output_file_base}[regsub -all {:+|[^-\w_.]} $ns _]$output_file_ext"
        }
        set ns_file_base_cache($ns) $fn
    }
    if {$ext eq ""} {
        return $ns_file_base_cache($ns)
    } else {
        return "[file rootname $ns_file_base_cache($ns)]$ext"
    }
}

proc ruff::private::markup_escape {text} {
    # Escapes any characters that might be treated as special for markup.
    #  text - The text to escape.
    return [regsub -all {[\\\[\]`*_{}()#]} $text {\\\0}]
}

proc ruff::private::markup_emphasis {text} {
    # Returns the markup text for emphasis.
    #  text - The text to emphasize.

    return "*[markup_escape $text]*"

}
proc ruff::private::markup_reference {symbol} {
    # Returns the markup text for cross-referencing a symbol.
    #  symbol - the symbol to reference
    return "\[$symbol\]"
}

proc ruff::private::markup_code {text} {
    # Returns $text marked up as code using Ruff! syntax.
    #  text - String to markup.

    # If text contains backticks, markup is more complicated.
    if {[string first "`" $text] < 0} {
        return "`$text`"
    }

    # Find the longest consecutive sequence of `
    set matches [regexp -all -inline {`+} $text]
    set n 0
    foreach match $matches {
        if {[string length $match] > $n} {
            set n [string length $match]
        }
    }
    # Number of backticks required is one more than max length of matches
    set sep [string repeat ` [incr n]]
    # Need to separate with spaces.
    return "$sep $text $sep"
}

proc ruff::private::regexp_escape {s} {
    return [string map {
        \\ \\\\ $ \\$ ^ \\^ . \\. ? \\? + \\+ * \\*
        | \\| ( \\( ) \\) [ \\[ ] \\] \{ \\\{ \} \\\}
    } $s]
}

proc ruff::private::namespace_tree {nslist} {
    # Return list of namespaces under the specified namespaces
    array set done {}
    while {[llength $nslist]} {
        set ns [lindex $nslist 0]
        set nslist [lrange $nslist 1 end]
        if {[info exists done($ns)]} {
            # Already recursed this namespace
            continue
        }
        set done($ns) true
        lappend nslist {*}[namespace children $ns]
    }

    return [array names done]
}

proc ruff::private::trim_namespace {name ns} {
    # Removes a namespace (::) or class qualifier (.) from the specified name.
    # name - name from which the namespace is to be removed
    # ns - the namespace to be removed. If empty, $name
    #  is returned as is. To trim the root namespace
    #  pass :: as the value
    #
    # Returns the remaining string after removing $ns
    # from $name. If $name does not begin with $ns, returns
    # it as is.

    if {$ns eq ""} {
        # Note this check must come BEFORE the trim below
        return $name
    }

    # The "namespace" may be either a Tcl namespace or a class
    # in which case the separator is a "." and not ::
    set ns [string trimright $ns :.]
    set nslen [string length $ns]
    if {[string equal ${ns} [string range $name 0 [expr {$nslen-1}]]]} {
        # Prefix matches.
        set tail [string range $name $nslen end]
        # See if next chars are :: or .
        if {[string range $tail 0 1] eq "::"} {
            # Namespace
            return [string range $tail 2 end]
        }
        if {[string index $tail 0] eq "."} {
            # Class
            return [string range $tail 1 end]
        }
    }

    return $name
}

proc ruff::private::trim_namespace_multi {namelist ns} {
    # See trim_namespace for a description. Only difference
    # is that this command takes a list of names instead
    # of a single name.
    set result {}
    foreach name $namelist {
        lappend result [trim_namespace $name $ns]
    }
    return $result
}

proc ruff::private::symbol_ref {word} {
    # Wraps $word with `[]` to mark it as a markdown reference.
    # word - the word to be marked as reference.
    # Returns the marked-up word.
    return "\[$word\]"
}

proc ruff::private::symbol_refs {words} {
    # Wraps elements of a list with `[]` to mark them as markdown references.
    # words - the list of words to be marked as references.
    # Returns the list of marked-up words.
    return [lmap word $words {
        set word "\[$word\]"
    }]
}

proc ruff::private::symbol_refs_string {words {separator {, }}} {
    # Constructs a string from elements of a list with `[]` to mark them as markdown references
    # words - the list of words to be marked as references.
    # separator - string to use as separator between elements
    # Returns a string containing the marked-up words separated by $separator.
    return [join [symbol_refs $words] $separator]
}

proc ruff::private::ensembles {pattern} {
    # Returns list of ensembles matching the pattern
    # pattern - fully namespace qualified pattern to match

    return [lmap cmd [info commands $pattern] {
        if {![namespace ensemble exists $cmd]} {
            continue
        }
        set cmd
    }]
}


proc ruff::private::sift_names {names} {
    # Given a list of names, separates and sorts them based on their namespace
    # names - a list of names
    #
    # Returns a dictionary indexed by namespace names with corresponding
    # values being a sorted list of names belong to that namespace.

    set namespaces [dict create]
    foreach name [lsort -dictionary $names] {
        set ns [namespace qualifiers $name]
        dict lappend namespaces $ns $name
    }

    return $namespaces
}

proc ruff::private::TBDNEEDED?sift_classprocinfo {classprocinfodict} {
    # Sifts through class and proc meta information based
    # on namespace
    #
    # Returns a dictionary with keys namespaces and values
    # being dictionaries with keys "classes" and "procs"
    # containing metainformation.

    set result [dict create]
    dict for {name procinfo} [dict get $classprocinfodict procs] {
        set ns [namespace qualifiers $name]
        if {$ns eq ""} {
            set ns "::"
        }
        dict set result $ns procs $name $procinfo
    }

    dict for {name classinfo} [dict get $classprocinfodict classes] {
        set ns [namespace qualifiers $name]
        if {$ns eq ""} {
            set ns "::"
        }
        dict set result $ns classes $name $classinfo
    }

    return $result
}

proc ruff::private::parse_line {line mode current_indent}  {
    # Parses a documentation line and returns its meta information.
    # line - line to be parsed
    # mode - parsing mode, must be one of `proc`, `method`, `docstring`
    # current_indent   - the indent of the containing block

    if {![regexp -indices {^\s*(\S.*)$} $line -> indices]} {
        return [list Type blank Indent $current_indent Text ""]
    }
    # indices contains the indices of text after leading whitespace

    set indent [lindex $indices 0]
    set text   [string trimright [string range $line $indent end]]

    # Indent exceeds more than 4 beyond current indent plus the
    # continuation indent if any, it is preformatted.
    set preformatted_min_indent [expr {$current_indent+4}]
    if {$indent >= $preformatted_min_indent} {
        # Note we use $line here, not $text as we want to preserve trailing
        # and leading spaces except for the 4 spaces that mark it as preformatted.
        return [list Type preformatted \
                    Indent $indent \
                    Text [string range $line $preformatted_min_indent end]]
    }

    # Note that $text starts AND ends with a non-whitespace character.
    # Also note order of match cases in switch is importent.
    switch -regexp -matchvar matches -indexvar indices -- $text {
        {^(#+)\s*(\S.*)} {
            # = A Header
            return [list Type heading \
                        Indent $indent \
                        Level [string length [lindex $matches 1]] \
                        Text [lindex $matches 2]]
        }
        {^[-\*]\s+(.*)$} {
            # - a bullet list element
            # Return: bullet lineindent relativetextindent marker text
            return [list Type bullet \
                        Indent $indent \
                        RelativeIndent [lindex $indices 1 0] \
                        Marker [string index $text 0] \
                        Text [lindex $matches 1]]
        }
        {^(\S+)(\s+\S+)?\s+-\s+(.*)$} {
            # term ?term2? - description
            return [list Type definition \
                        Indent $indent \
                        RelativeIndent [lindex $indices 2 0] \
                        Term "[lindex $matches 1][lindex $matches 2]" \
                        Text [lindex $matches 3]]
        }
        {^(`{3,})$} {
            # ```` Fenced code block
            return [list Type fence Indent $indent Text $text]
        }
        default {
            # Normal text line
            if {$mode ne "docstring"} {
                # Within procs and methods, look for special
                # proc-specific keywords
                if {[regexp {^See also\s*:\s*(.*)$} $line -> match]} {
                    return [list Type seealso Indent $indent Text $match]
                }
                if {[regexp {^Returns($|\s.*$)} $line]} {
                    return [list Type returns Indent $indent Text $text]
                }
            }
            if {$indent > $current_indent} {
                return [list Type continuation \
                            Indent $indent \
                            Text $text]
            } else {
                return [list Type normal\
                            Indent $indent \
                            Text $text]
            }
        }
    }
}

proc ruff::private::parse_preformatted_state {statevar} {
    upvar 1 $statevar state

    # Gobble up all lines that are indented starting
    # with the current line. Blank lines are included
    # even if they have fewer than the required indent.
    # However, leading blank lines and trailing blank
    # lines are not included even if they start
    # with leading 4 spaces.

    # Note the Text dictionary element already has
    # the leading 4 spaces stripped.

    set text [dict get $state(parsed) Text]
    unset state(parsed);    # Since we do not maintain this for further lines

    # If a blank line, do not treat as start of
    # preformatted section (Markdown compatibility).
    if {[regexp {^\s*$} $text]} {
        incr state(index)
        return
    }

    set code_block          [list $text]
    set intermediate_blanks [list ]
    while {[incr state(index)] < $state(nlines)} {
        set line [lindex $state(lines) $state(index)]
        regexp -indices {^(\s*)} $line -> leader
        set nspaces [expr {[lindex $leader 1]+1}]
        if {$nspaces == [string length $line]} {
            # Empty or all blanks
            # Intermediate empty lines do not terminate block
            # even if not prefixed by 4 spaces. Collect them
            # to add later if more preformatted lines follow.
            lappend intermediate_blanks [string range $line 4 end]
        } elseif {$nspaces < 4} {
            # Not preformatted
            break
        } else {
            lappend code_block {*}$intermediate_blanks
            set intermediate_blanks {}
            lappend code_block [string range $line 4 end]
        }
    }
    set state(state) body
    lappend state(body) preformatted $code_block
}

proc ruff::private::parse_fence_state {statevar} {
    upvar 1 $statevar state
    set marker [dict get $state(parsed) Text]
    set marker_indent  [dict get $state(parsed) Indent]
    set code_block {}

    # Gobble up any lines until the matching fence
    while {[incr state(index)] < $state(nlines)} {
        set line [lindex $state(lines) $state(index)]
        # Explicit check is faster than calling parse_line
        # Note neither pandoc not cmark require marker indentation
        # to be the same.
        if {[regexp "^\s*$marker\s*$" $line]} {
            incr state(index);  # Inform caller which line to look at next
            unset state(parsed); # To indicate next line has not been parsed
            break;  # Found end marker
        } else {
            # Remove the indentation of original marker if present.
            # Smaller indentation is reduced to 0.
            regexp -indices {^(\s*)} $line -> spaces
            set start [lindex $spaces 1]; # Could be -1 also
            incr start
            if {$start < $marker_indent} {
                set line [string range $line $start end]
            } else {
                set line [string range $line $marker_indent end]
            }
            lappend code_block $line
        }
    }
    lappend state(body) preformatted $code_block
    set state(state) body
}

proc ruff::private::parse_seealso_state {statevar} {
    upvar 1 $statevar state

    if {$state(mode) eq "docstring"} {
        # parse_line should not have returned this for docstrings
        error "Internal error: Got seealso in docstring mode."
    }
    set block_indent [dict get $state(parsed) Indent]
    # The text is a list of symbols separated by spaces
    # and optionally commas.
    set symbols [string map {, { }} [dict get $state(parsed) Text]]
    lappend state(seealso) {*}$symbols
    while {[incr state(index)] < $state(nlines)} {
        set line [lindex $state(lines) $state(index)]
        set state(parsed) [parse_line $line $state(mode) $block_indent]
        switch -exact -- [dict get $state(parsed) Type] {
            heading -
            fence -
            bullet -
            definition -
            blank -
            returns {
                break
            }
            normal {
                # If the indent is less than the block indent,
                # treat as a new paragraph.
                if {[dict get $state(parsed) Indent] < $block_indent} {
                    break
                }
                # Append symbols at bottom of loop
            }
            preformatted -
            continuation {
                # Append symbols at bottom of loop
            }
            default {
                error "Unexpected type [dict get $state(parsed) Type]"
            }
        }
        set symbols [string map {, { }} [dict get $state(parsed) Text]]
        lappend state(seealso) {*}$symbols
    }
    set state(state) body
}

proc ruff::private::parse_returns_state {statevar} {
    upvar 1 $statevar state

    set block_indent [dict get $state(parsed) Indent]
    set lines [list [dict get $state(parsed) Text]]
    while {[incr state(index)] < $state(nlines)} {
        set line [lindex $state(lines) $state(index)]
        set state(parsed) [parse_line $line $state(mode) $block_indent]
        set text [dict get $state(parsed) Text]
        switch -exact -- [dict get $state(parsed) Type] {
            heading -
            fence -
            bullet -
            definition -
            blank -
            seealso -
            preformatted -
            returns {
                # All special lines terminate normal paragraphs
                break
            }
            continuation {
                lappend lines $text
            }
            normal {
                # If the indent is less than the block indent,
                # treat as a new paragraph.
                if {[dict get $state(parsed) Indent] < $block_indent} {
                    break
                }
                lappend lines $text
            }
            default {
                error "Unexpected type [dict get $state(parsed) Type]"
            }
        }
    }
    if {[llength $lines]} {
        if {$state(mode) eq "docstring"} {
            lappend state(body) paragraph $lines
        } else {
            lappend state(returns) {*}$lines
        }
    } 
    if {$state(mode) ne "docstring" && $state(state) eq "init"} {
        set state(state) postsummary
    } else {
        set state(state) body
    }
}

proc ruff::private::parse_bullets_state {statevar} {
    upvar 1 $statevar state

    set list_block {}
    set list_elem [list [dict get $state(parsed) Text]]
    set marker    [dict get $state(parsed) Marker]
    set block_indent [dict get $state(parsed) Indent]

    # between_bullets keeps track of blank lines. If a list item follow
    # a sequence of blank lines, it continues the list. Any other line
    # type will terminate the list.
    set between_bullets false
    while {[incr state(index)] < $state(nlines)} {
        set line [lindex $state(lines) $state(index)]
        set state(parsed) [parse_line $line $state(mode) $block_indent]
        set text [dict get $state(parsed) Text]
        switch -exact -- [dict get $state(parsed) Type] {
            heading -
            returns -
            fence -
            definition -
            seealso {
                # If we are between bullets, this does not continue the list.
                if {$between_bullets} {
                    break
                }
                if {[dict get $state(parsed) Indent] <= $block_indent} {
                    # List element and list terminated if a block starter
                    # appears at the same or less indentation. Note this is
                    # DIFFERENT from normal lines which add to the list
                    # item if at the same indent level.
                    break
                }
                # Note cannot use $text here since that will not contain
                # the full line for these elements
                lappend list_elem [string trimleft $line]
            }
            continuation {
                lappend list_elem $text
                set between_bullets false
            }
            normal {
                # If we are between bullets, this does not continue the list.
                if {$between_bullets} {
                    break
                }

                # If the indent is less than that of list element
                # treat as a new paragraph. This differs from Markdown
                # which treats it as part of the list item.
                if {[dict get $state(parsed) Indent] < $block_indent} {
                    break
                }
                lappend list_elem $text
            }
            preformatted {
                # If we are between bullets, this does not continue the list.
                if {$between_bullets} {
                    break
                }
                # As in markdown list continuation prioritized over preformatted
                lappend list_elem [string trim $text]
            }
            blank {
                # Current list item is terminated but not the list.
                # The check for list_elem length is to deal with
                # multiple consecutive blank lines. These should not
                # result in spurious list items.
                if {[llength $list_elem]} {
                    lappend list_block $list_elem
                    set list_elem {}
                }
                set between_bullets true
            }
            bullet {
                if {[dict get $state(parsed) Marker] ne $marker} {
                    break;      # Different list item type
                }
                if {[llength $list_elem]} {
                    lappend list_block $list_elem
                }
                set list_elem [list $text]
                set between_bullets false
            }
            default {
                error "Unexpected type [dict get $state(parsed) Type]"
            }
        }
    }

    if {[llength $list_elem]} {
        lappend list_block $list_elem
    }

    lappend state(body) bullets $list_block
    set state(state) body
}

proc ruff::private::parse_definitions_state {statevar} {
    upvar 1 $statevar state

    set definition_block {}
    set term         [dict get $state(parsed) Term]
    set definition   [list [dict get $state(parsed) Text]]
    set block_indent [dict get $state(parsed) Indent]

    while {[incr state(index)] < $state(nlines)} {
        set line [lindex $state(lines) $state(index)]
        set state(parsed) [parse_line $line $state(mode) $block_indent]
        set type [dict get $state(parsed) Type]
        # If $term is empty, then this line just followed a blank line.
        # In that case, we continue with the definition list only
        # if the line is a definition format or is itself blank.
        if {$type ni { definition blank } && ![info exists term]} {
            break
        }
        set text [dict get $state(parsed) Text]
        switch -exact -- $type {
            heading -
            returns -
            fence -
            bullet -
            seealso {
                if {[dict get $state(parsed) Indent] <= $block_indent} {
                    # List element and list terminated if a block starter
                    # appears at the same or less indentation. Note this is
                    # DIFFERENT from normal lines which add to the list
                    # item if at the same indent level.
                    break
                }
                # Note cannot use $text here since that will not contain
                # the full line for these elements
                lappend definition [string trimleft $line]
            }
            continuation {
                lappend definition $text
            }
            normal {
                # If the indent is less than that of list element
                # treat as a new paragraph. This differs from Markdown
                # which treats it as part of the list item.
                if {[dict get $state(parsed) Indent] < $block_indent} {
                    break
                }
                lappend definition $text
            }
            preformatted {
                # As in markdown list continuation prioritized over preformatted
                lappend definition [string trim $text]
            }
            blank {
                # Current definition is terminated but not the list.
                # The check for term is to deal with
                # multiple consecutive blank lines. These should not
                # result in spurious items.
                if {[info exists term]} {
                    lappend definition_block [dict create term $term definition $definition]
                    unset term
                }
            }
            definition {
                if {[string length $term]} {
                    lappend definition_block [dict create term $term definition $definition]
                }
                set term       [dict get $state(parsed) Term]
                set definition [list [dict get $state(parsed) Text]]
            }
            default {
                error "Unexpected type [dict get $state(parsed) Type]"
            }
        }
    }

    if {[info exists term]} {
        lappend definition_block [dict create term $term definition $definition]
    }

    if {$state(mode) ne "docstring" && $state(state) in {init postsummary}} {
        set state(state) body
        set state(parameters) $definition_block
    } else {
        lappend state(body) definitions $definition_block
    }
}

proc ruff::private::parse_normal_state {statevar} {
    upvar 1 $statevar state

    set block_indent [dict get $state(parsed) Indent]
    set paragraph [list [dict get $state(parsed) Text]]
    while {[incr state(index)] < $state(nlines)} {
        set line [lindex $state(lines) $state(index)]
        set state(parsed) [parse_line $line $state(mode) $block_indent]
        switch -exact -- [dict get $state(parsed) Type] {
            heading -
            fence -
            bullet -
            definition -
            blank -
            seealso -
            preformatted -
            returns {
                # All special lines terminate normal paragraphs
                break
            }
            continuation -
            normal {
                # Append text at bottom
            }
            default {
                error "Unexpected type [dict get $state(parsed) Type]"
            }
        }
        lappend paragraph [string trim [dict get $state(parsed) Text]]
    }
    if {$state(mode) ne "docstring" && $state(state) eq "init"} {
        set state(summary) $paragraph
        set state(state) postsummary
    } else {
        set state(state) body
        lappend state(body) paragraph $paragraph
    }
}

proc ruff::private::parse_lines {lines {mode proc}} {
    # Creates a documentation parse structure.
    # lines - List of lines comprising the documentation
    # mode - Parsing mode, must be one of `proc`, `method`, `docstring`
    #
    # Returns a dictionary representing the documentation.
    #
    # The parse structure is a dictionary with the following keys:
    # summary - Contains the summary paragraph.
    #           Not applicable if $mode is `docstring`.
    # parameters - List of parameter name and description paragraph pairs.
    #           Not applicable if $mode is `docstring`.
    # body - The main body stored as a list of alternating type and
    #        content elements. The type may be one of `heading`,
    #        `paragraph`, `list`, `definitions` or `preformatted`.
    # seealso - The *See also* section containing a list of program element
    #           references. Not applicable if $mode is `docstring`.
    # returns - A paragraph describing the return value.
    #           Not applicable if $mode is `docstring`.
    #
    # Not all elements may be present in the dictionary.
    # A paragraph is returned as a list of lines.

    # The parsing engine is distributed among procedures that carry
    # state around in the state array.

    set state(state)  init
    set state(mode)   $mode
    set state(lines)  $lines
    set state(nlines) [llength $lines]
    set state(index)  0
    set state(body)  {};        # list of alternating type and content
    # Following may be set during parsing
    # set state(summary) {};      # Summary paragraph
    # set state(returns)  {};      # list of paragraphs
    # set state(seealso) {};      # list of symbol references
    # set state(parameters) {};   # Parameter definition list

    while {$state(index) < $state(nlines)} {
        # The loop is structured such that the outer loop detects block
        # starts and then for each block type the state function
        # slurps in all lines for that block.
        if {![info exists state(parsed)]} {
            set state(parsed) [parse_line \
                                   [lindex $state(lines) $state(index)] \
                                   $state(mode) \
                                   0]
        }
        set state(block_indent) [dict get $state(parsed) Indent]
        # All state procs expect state(parsed) to contain the
        # parsed format of the line at position state(index) that causes
        # transition to that state.
        switch -exact -- [dict get $state(parsed) Type] {
            blank {
                incr state(index)
                unset state(parsed)
            }
            heading {
                # Headings have to be on a single line
                lappend state(body) heading [list [dict get $state(parsed) Level] [dict get $state(parsed) Text]]
                incr state(index)
                unset state(parsed)
                set state(state) body
            }
            bullet       { parse_bullets_state state }
            definition   { parse_definitions_state state }
            returns      { parse_returns_state state }
            seealso      { parse_seealso_state state }
            normal       { parse_normal_state state }
            preformatted { parse_preformatted_state state }
            fence        { parse_fence_state state }
            continuation -
            default {
                error "Internal error: Unknown or unexpected line type\
                       \"[dict get $state(parsed) Type]\" returned in top-level\
                       parse of line \"[lindex $state(lines) $state(index)]\"."
            }
 
        }
    }

    set result [dict create body $state(body)]
    foreach elem {summary parameters seealso returns} {
        if {[info exists state($elem)]} {
            dict set result $elem $state($elem)
        }
    }
    return $result
}

proc ruff::private::TBDparse {lines {mode proc}} {
    # Creates a parse structure given a list of lines that are assumed
    # to be documentation for a programming structure
    #
    # lines - a list of lines comprising the documentation
    # mode - parsing mode, must be one of `proc`, `method`, `docstring`
    #

    # A fence is 3 or more consecutive backticks surrounded by whitespace
    # TBD - are parens around \s in re_return, deflist, bullet necessary?
    set re_fence {^\s*`{3,}\s*$}
    set re_blankline {^\s*$}
    set re_preformatted {^\s{4,}}
    set re_bullet {^(\s*)[-\*]\s+(.*)$}
    set re_header {^\s*(#+)\s*(\S.*)}
    set re_deflist {^(\s*)(\S.*?)\s+-\s+(.*)$}
    set re_return {^(\s*)Returns($|\s.*$)}
    set re_seealso {^\s*See also\s*:\s*(.*)$}

    if {$mode ni {proc method docstring}} {
        error "Argument \"mode\" must be one of \"proc\", \"method\" or \"docstring\""
    }
    set result(name) ""
    set result(listcollector) {}
    set result(fragment) {}
    set result(state) init
    set result(output) {}
    set result(return_added) 0
    set result(summary) ""
    set result(indent) 0
    set result(header_level) 1

    foreach line $lines {
        # The fenced state is treated differently in that
        # it is terminated only by a fence so it's easier to
        # handle that separately here rather than within each
        # line pattern below.
        if {$result(state) eq "fenced"} {
            if {[regexp $re_fence $line]} {
                # End of fence block
                # Should we change to the preceding state instead? TBD
                change_state blank result
            } else {
                lappend result(fragment) $line
            }
            continue
        }
        switch -regexp -matchvar matches -- $line \
            $re_fence {
                # Start of a fence block
                change_state fenced result
            } $re_blankline {
                #ruff
                # Empty lines or lines with only whitespace
                # terminate the preceding
                # text block (such as a paragraph or a list).
                switch -exact -- $result(state) {
                    init -
                    postsummary {
                        # No change
                    }
                    summary {
                        change_state postsummary result
                    }
                    default {
                        change_state blank result
                    }
                }
            } $re_preformatted {
                #ruff
                # Lines beginning with at least 4 spaces
                # are treated as preformatted text unless they are part
                # of a list item. Preformatted text is returned as a list
                # of lines.
                switch -exact -- $result(state) {
                    bulletlist -
                    deflist -
                    parameter -
                    option {
                        # No change. Keep adding to existing block
                    }
                    preformatted {
                        # Add line with initial 4 spaces stripped
                        set line [string range $line 4 end]
                    }
                    default {
                        change_state preformatted result
                        # Add line with initial 4 spaces stripped
                        set line [string range $line 4 end]
                    }
                }
                lappend result(fragment) $line
            } $re_bullet {
                #ruff
                # A bulleted list item starts with a '-' or '*' character
                # and is not a preformatted line.
                # A list item may be continued across multiple lines.
                # A bulleted list is returned as a list containing the list
                # items, each of which is a list of lines.
                change_state bulletlist result
                lappend result(fragment) [lindex $matches 2]
            } $re_header {
                #ruff
                # A markdown style header line
                if {$mode ne "docstring"} {
                    # TBD - support headers in procs
                    error "Header markup not supported within procs and methods."
                }
                change_state header result
                set result(header_level) [string length [lindex $matches 1]]
                lappend result(fragment) [lindex $matches 2]
            } $re_deflist {
                #ruff
                # A definition list or parameter list element that is not
                # preformatted and contains a `-` character surrounded by
                # whitespace. The text before the `-` separator is the
                # definition term and the text after is the description.
                # Whether it is treated as a parameter list or a
                # definition list depends on whether it occurs in the comment
                # block. If it occurs at the beginning or just after the
                # summary line, it is treated as a parameter list.
                # In all other cases, it is treated as a definition list.
                # Note that when $mode is `docstring` it is always treated
                # as a definition list.
                # Like a bulleted list, each list item may be continued
                # on succeeding lines by indenting them.
                # Definition and parameter lists
                # are returned as flat list
                # of alternating list item name and list item value
                # pairs. The list item value is itself a list of lines.
                set result(indent) [string length [lindex $matches 1]]
                if {$mode ne "docstring" &&
                    $result(state) in {init summary postsummary parameter option}} {
                    #ruff
                    # As a special case, a parameter definition where the
                    # term begins with a `-` is treated as a option definition.
                    if {[string index [lindex $matches 2] 0] eq "-"} {
                        change_state option result
                    } else {
                        change_state parameter result
                    }
                } else {
                    change_state deflist result
                }
                set result(name) [lindex $matches 2]
                lappend result(fragment) [lindex $matches 3]
            } $re_return {
                #ruff
                # If $mode is not `docstring`,
                # any paragraph that begins with the word 'Returns' is treated
                # as a description of the return value irrespective of where
                # it occurs. It is returned as a list of lines.
                # TBD - fix to be normal line if in docstring mode

                set result(indent) [string length [lindex $matches 1]]
                if {$result(state) eq "init"} {
                    change_state summary result
                } else {
                    change_state return result
                }
                lappend result(fragment) [string trimleft $line]
            } $re_seealso {
                #ruff
                # A block beginning with `See also` is treated as
                # cross references. There may be multiple such blocks.
                # Their contents are accumulated.
                change_state seealso result
                lappend result(fragment) [lindex $matches 1]
            } default {
                #ruff
                # All other lines either continue an existing paragrapsh
                # or list element, or begin a new paragraph.
                # Paragraphs may extend across multiple lines and are
                # terminated either when the line is recognized as
                # preformatted or matches one of the list
                # items patterns, or an empty line.
                # Paragraphs are returned as a list of lines.

                switch -exact -- $result(state) {
                    init {
                        if {$mode eq "docstring"} {
                            change_state paragraph result
                        } else {
                            change_state summary result
                        }
                    }
                    postsummary -
                    blank -
                    preformatted { change_state paragraph result }
                    bulletlist -
                    parameter -
                    deflist -
                    option {
                        #ruff
                        # For list items, the line should not be indented
                        # less than the leading list item indent.
                        if {[regexp {^(\s*)} $line -> spaces]} {
                            set indent [string length $spaces]
                        } else {
                            set indent 0
                        }
                        if {$indent < $result(indent)} {
                            change_state paragraph result
                        } else {
                            # Stay in same state
                        }
                    }
                    default {
                        # Stay in same state
                    }
                }
                lappend result(fragment) $line
            } 
        }

    change_state finish result; # To process any leftovers in result(fragment)

    # Special case where the Returns is also the summary
    if {! $result(return_added)} {
        # If the summary matches a Returns statement, use that.
        if {[string match -nocase "returns *" [lindex $result(summary) 0]]} {
                lappend result(output) return $result(summary)
        }
    }

    if {[info exists result(seealso)]} {
        lappend result(output) seealso $result(seealso)
    }

    #ruff
    # Returns a list of key value pairs where key is one of 'header',
    # 'parameter', 'option', 'bulletlist', 'deflist', 'parameter',
    # 'preformatted', 'paragraph' or 'return',
    # and the value
    # is the corresponding value.
    return $result(output)

}


# Note new state may be same as old state (but a new fragment)
proc ruff::private::TBDchange_state {new v_name} {
    upvar 1 $v_name result

    # Close off existing state
    switch -exact -- $result(state) {
        bulletlist -
        deflist -
        parameter -
        option {
            if {$result(state) eq "bulletlist"} {
                lappend result(listcollector) $result(fragment)
            } else {
                lappend result(listcollector) $result(name) $result(fragment)
            }
            # If are collecting a list, and new state is same, then
            # this is just another item in the same list and we do not
            # store to output.
            if {$result(state) ne $new} {
                # List type has changed or changing to non-list type
                if {[lindex $result(output) end-1] eq "$result(state)"} {
                    # If the previous output item was the same type, append
                    # the new items to it rather than creating a new item.
                    # This is a hack because I did not realize early enough
                    # that markdown treats list elements separated by blank lines
                    # as belonging to the same list.
                    set last_list [lindex $result(output) end]
                    lappend last_list {*}$result(listcollector)
                    lset result(output) end $last_list
                    set result(listcollector) {}
                } else {
                    # Previous item was not a list of the same type
                    lappend result(output) $result(state) $result(listcollector)
                    set result(listcollector) {}
                }
            }
        }
        return  {
            lappend result(output) return $result(fragment)
            set result(return_added) 1
        }
        summary {
            lappend result(output) summary $result(fragment)

            # Disabled - Summary is also included in the paragraphs
            # lappend result(output) paragraph $result(fragment)

            # Save in case used for Returns statement
            set result(summary) $result(fragment)
        }
        paragraph {
            lappend result(output) paragraph $result(fragment)
        }
        fenced -
        preformatted {
            lappend result(output) preformatted $result(fragment)
        }
        header {
            lappend result(output) header [list $result(header_level) $result(fragment)]
        }
        seealso {
            lappend result(output) seealso $result(fragment)
        }
        postsummary -
        init -
        blank {
            # Nothing to do
        }
        default {
            error "Unknown parse state $result(state)"
        }
    }
    set result(state) $new;     # Restart for next fragment
    set result(name) ""
    set result(fragment) {}
}

proc ruff::private::distill_docstring {text} {
    # Splits a documentation string to return the documentation lines
    # as a list.
    # text - documentation string to be parsed
    #
    # If any tabs are present, they are replaced with spaces assuming
    # a tab stop width of 8.
    
    set lines {}
    set state init
    foreach line [split $text \n] {
        set line [textutil::tabify::untabify2 $line]
        if {[regexp {^\s*$} $line]} {
            #ruff
            # Initial blank lines are skipped and 
            # multiple empty lines are compressed into one empty line.
            if {$state eq "collecting"} {
                lappend lines ""
                set state empty
            }
            continue
        }
        #ruff
        # The very first non empty line determines the margin. This will
        # be removed from all subsequent lines. Note that this assumes that
        # if tabs are used for indentation, they are used on all lines
        # in consistent fashion.
        if {$state eq "init"} {
            regexp {^(\s*)\S} $line dontcare prefix
            set prefix_len [string length $prefix]
        }
        set state collecting

        # Remove the prefix if it exists from the line
        if {[string match ${prefix}* $line]} {
            set line [string range $line $prefix_len end]
        }

        lappend lines $line
    }

    # Returns a list of lines.
    return $lines
}

proc ruff::private::distill_body {text} {
    # Given a procedure or method body,
    # returns the documentation lines as a list.
    # text - text to be processed to collect all documentation lines.
    #
    # The first block of contiguous comment lines preceding the 
    # first line of code are treated as documentation lines.
    # If any tabs are present, they are replaced with spaces assuming
    # a tab stop width of 8.
    set lines {}
    set state init;             # init, collecting or searching
    foreach line [split $text \n] {
        set line [textutil::tabify::untabify2 $line]
        set line [string trim $line]; # Get rid of whitespace
        if {$line eq ""} {
            # Blank lines.
            # If in init state, we will stay in init state
            if {$state ne "init"} {
                set state searching
            }
            continue
        }

        if {[string index $line 0] ne "#"} {
            # Not a comment
            set state searching
            continue
        }

        # At this point, the line is a comment line
        if {$state eq "searching"} {
            #ruff
            # The string #ruff at the beginning of a comment line
            # anywhere in the passed in text is considered the start
            # of a documentation block. All subsequent contiguous
            # comment lines are considered documentation lines.
            if {[string match "#ruff*" $line]} {
                set state collecting
                #ruff
                # Note a #ruff on a line by itself will terminate
                # the previous text block.
                set line [string trimright $line]
                if {$line eq "#ruff"} {
                    lappend lines {}
                } else {
                    #ruff If #ruff is followed by additional text
                    # on the same line, it is treated as a continuation
                    # of the previous text block.
                    lappend lines [string range $line 6 end]
                }
            }
        } else {
            # State is init or collecting

            if {$line eq "#"} {
                # Empty comment line
                lappend lines {}
                continue;       # No change in state
            }

            #ruff
            # The leading comment character and a single space (if present)
            # are trimmed from the returned lines.
            if {[string index $line 1] eq " "} {
                lappend lines [string range $line 2 end]
            } else {
                lappend lines [string range $line 1 end]
            }
            set state collecting
            continue
        }
    }

    # Returns a list of lines that comprise the raw documentation.
    return $lines
}

proc ruff::private::extract_docstring {text} {
    # Parses a documentation string to return a structured text representation.
    # text - documentation string to be parsed
    #
    # The command extracts structured text from the given string
    # as described in the documentation for the distill_docstring
    # and parse commands. The result is further processed to
    # return a list of type and value elements described below:
    #
    # heading   - The corresponding value is a list comprising the heading level
    #             and text.
    # paragraph - The corresponding values is a list containing the lines
    #             for that paragraph.
    # list      - The corresponding value is a list of lists with the outer
    #             list elements being the list items the contents of which
    #             are the lines.
    # definitions - The corresponding value is a list of dictionaries, each
    #             with the keys `term` and `definition`, the latter being
    #             the list of lines making up the definition.
    # preformatted - The corresponding value is a list of lines that should
    #             not be formatted.
    #
    # Each element may occur multiple times and are expected to be displayed
    # in the order of their occurence.

    set doc [parse_lines [distill_docstring $text] docstring]
    set result [dict get $doc body]
    # Just error checking - should not have anykeys other than body
    dict unset doc body
    if {[llength [dict keys $doc]]} {
        app::log_error "Internal error: docstring contains unexpected keys [join [dict keys $doc]]."
    }
    return $result
}

proc ruff::private::extract_proc {procname} {

    # Extracts meta information from a Tcl procedure.
    # procname - name of the procedure
    #
    # The command retrieves metainformation about
    # a Tcl procedure. See the command extract_proc_or_method
    # for details.
    #
    # Returns a dictionary containing metainformation for the command.
    #

    set param_names [info args $procname]
    set param_defaults {}
    foreach name $param_names {
        if {[info default $procname $name val]} {
            lappend param_defaults $name $val
        }
    }
    return [extract_proc_or_method proc \
                $procname \
                [info args $procname] \
                $param_defaults \
                [info body $procname]]
}

proc ruff::private::extract_ensemble {ens} {
    # Extracts metainformation for all subcommands in an ensemble command
    # ens - fully qualified names of the ensemble command
    #
    # Only ensemble commands that satisfy the following are supported:
    # - the ensemble implementation must be in the form of Tcl procedures
    # - the ensemble must not have been configured with the `-parameters`
    #   option as that changes location of arguments
    #
    # Each element of the returned list is of the form returned by [extract_proc]
    # with two changes. The `name` key in the dictionary element is the
    # includes the ensemble name. Secondly, an additional key `ensemble` is
    # added to indicate which ensemble the element belongs to.
    #
    # Returns a list of elements each of the form returned by [extract_proc].

    array set ens_config [namespace ensemble configure $ens]
    if {[llength $ens_config(-parameters)]} {
        app::log_error "Skipping ensemble command $ens (non-empty -parameters attribute)."
    }

    if {[llength $ens_config(-subcommands)]} {
        set cmds $ens_config(-subcommands)
    } elseif {[dict size $ens_config(-map)]} {
        set cmds [dict keys $ens_config(-map)]
    } else {
        set exported [namespace eval $ens_config(-namespace) {namespace export}]
        set cmds {}
        foreach pat $exported {
            foreach cmd [info commands ${ens_config(-namespace)}::$pat] {
                lappend cmds [namespace tail $cmd]
            }
        }
    }

    return [lmap cmd $cmds {
        if {[dict exists $ens_config(-map) $cmd]} {
            set real_cmd [dict get $ens_config(-map) $cmd]
        } else {
            set real_cmd $cmd
        }
        if {![string match ::* $real_cmd]} {
            set real_cmd "${ens_config(-namespace)}::$real_cmd"
        }
        if {[info procs $real_cmd] ne "$real_cmd"} {
            app::log_error "Skipping subcommand \"$cmd\" for ensemble \"$ens\"\
                            because it is not a procedure."
            continue
        }
        if {[catch {extract_proc $real_cmd} result]} {
            app::log_error "Could not retrieve information for \"$real_cmd\"\
                            implementing ensemble command \"$ens $cmd\": $result"
            continue
        }
        dict set result name "$ens $cmd"
        dict set result ensemble $ens
        set result
    }]
}

proc ruff::private::extract_ooclass_method {class method} {

    # Extracts metainformation for the method in oo:: class
    # class - name of the class
    #
    # The command retrieves metainformation about
    # a Tcl class method. See the command extract_proc_or_method
    # for details.
    #
    # Returns a dictionary containing documentation related to the command.
    #


    switch -exact -- $method {
        constructor {
            foreach {params body} [info class constructor $class] break
        }
        destructor  {
            set body [info class destructor $class]
            set params {}
        }
        default {
            foreach {params body} [info class definition $class $method] break
        }
    }


    set param_names {}
    set param_defaults {}
    foreach param $params {
        lappend param_names [lindex $param 0]
        if {[llength $param] > 1} {
            lappend param_defaults [lindex $param 0] [lindex $param 1]
        }
    }

    return [extract_proc_or_method method $method $param_names $param_defaults $body $class]
}


proc ruff::private::extract_proc_or_method {proctype procname param_names
                                            param_defaults body {class ""}} {
    # Helper procedure used by extract_proc and extract_ooclass_method to
    # construct metainformation for a method or proc.
    #  proctype - should be either 'proc' or 'method'
    #  procname - name of the proc or method
    #  param_names - list of parameter names in order
    #  param_defaults - list of parameter name and default values
    #  body - the body of the proc or method
    #  class - the name of the class to which the method belongs. Not used
    #   for proc types.
    #
    # The command parses the $body parameter as described by the distill_body
    # and parse commands and then constructs the metainformation for
    # the proc or method using this along with the other passed arguments.
    # The metainformation is returned as a dictionary with the following keys:
    #  name - name of the proc or method
    #  parameters - a list of parameters. Each element of the
    #   list is a dictionary with keys term, definition and optionally default.
    #  body - a list of paragraphs describing the command. The
    #   list contains heading, preformatted, paragraph, list and definitions
    #   as described for the [extract_docstring] command.
    #  returns - a description of the return value of the command (optional)
    #  summary - a copy of the first paragraph if it was present (optional)
    #  source - the source code of the command (optional)
    #  seealso - the corresponding value is a list of symbols (optional).
    #

    variable ProgramOptions

    array set param_default $param_defaults
    array set params {}
    array set options {}
    set paragraphs {}

    set doc [parse_lines [distill_body $body] $proctype]
    # doc -> dictionary with keys summary, body, parameters, returns, seealso
    dict set doc name $procname
    dict set doc class $class
    dict set doc proctype $proctype

    # Match up the parameter docs with the passed in parameter info.
    # First collect the documented parameters
    if {[dict exists $doc parameters]} {
        foreach param [dict get $doc parameters] {
            # param is a dict with keys term and definition
            set name [dict get $param term]
            set params($name) $param
        }
    }

    # Construct parameter descriptions. Note those not listed in the
    # actual proc definition are left out even if they are in the params
    # table
    set parameters {}
    foreach name $param_names {
        if {[info exists params($name)]} {
            set paramdata $params($name)
            unset params($name)
        } else {
            set paramdata [dict create term $name definition "Not documented." type parameter]
        }

        # Check if there is a default
        if {[info exists param_default($name)]} {
            dict set paramdata default $param_default($name)
        }

        dict set paramdata type parameter
        lappend parameters $paramdata
    }

    # Add any left over parameters from the documentation.
    foreach {name paramdata} [array get params] {
        dict set paramdata type "option"; # Assume option since not in proc definition
        lappend parameters $paramdata
    }
    dict set doc parameters $parameters

    # TBD - do we need to extract source even if -includesource is not specified
    set source "$proctype $procname "
    set param_list {}
    foreach name $param_names {
        if {[info exists param_default($name)]} {
            lappend param_list [list $name $param_default($name)]
        } else {
            lappend param_list $name
        }
    }


    append source "{$param_list} {\n"
    # We need to reformat the body. If nested inside a namespace eval
    # for example, the body will be indented too much. So we undent the
    # least indented line to 0 spaces and then add 4 spaces for each line.
    append source [::textutil::adjust::indent [::textutil::adjust::undent $body] "    "]
    append source "\n}"
    if {$ProgramOptions(-hidesourcecomments)} {
        regsub -line -all {^\s*#.*$} $source "" source
        regsub -all {\n{2,}} $source "\n" source
    }
    dict set doc source $source
    return $doc
}


proc ruff::private::extract_ooclass {classname args} {
    # Extracts metainformation about the specified class
    # classname - name of the class to be documented
    # -includeprivate BOOLEAN - if true private methods are also included
    #  in the metainformation. Default is false.
    #
    # The metainformation. returned is in the form of a dictionary with
    # the following keys:
    # name - name of the class
    # methods - a list of method definitions for this class in the form
    #  returned by extract_ooclass_method with the additional key
    #  'visibility' which may have values 'public' or 'private'.
    # external_methods - a list of names of methods that are
    #  either inherited or mixed in
    # filters - a list of filters defined by the class
    # forwards - a list of forwarded methods, each element in the
    #  list being a dictionary with keys 'name' and 'forward'
    #  corresponding to the forwarded method name and the forwarding command.
    # mixins - a list of names of classes mixed into the class
    # superclasses - a list of names of classes which are direct
    #   superclasses of the class
    # subclasses - a list of classes which are direct subclasses of this class
    # constructor - method definition for the constructor in the format
    #   returned by extract_ooclass_method
    # destructor - method definition for the destructor
    #   returned by extract_ooclass_method
    #
    # Each method definition is in the format returned by the 
    # extract_ooclass_method command with an additional keys:
    # visibility - indicates whether the method is 'public' or 'private'

    array set opts {-includeprivate false}
    array set opts $args

    set result [dict create methods {} external_methods {} \
                    filters {} forwards {} \
                    mixins {} superclasses {} subclasses {} \
                    name $classname \
                   ]

    if {$opts(-includeprivate)} {
        set all_local_methods [info class methods $classname -private]
        set all_methods [info class methods $classname -all -private]
    } else {
        set all_local_methods [info class methods $classname]
        set all_methods [info class methods $classname -all]
    }
    set public_methods [info class methods $classname -all]
    set external_methods {}
    foreach name $all_methods {
        set implementing_class [locate_ooclass_method $classname $name]
        if {[lsearch -exact $all_local_methods $name] < 0} {
            # Skip the destroy method which is standard and 
            # appears in all classes.
            if {$implementing_class ne "::oo::object" ||
                $name ne "destroy"} {
                lappend external_methods [list $name $implementing_class]
            }
            continue
        }

        # Even if a local method, it may be hidden by a mixin
        if {$implementing_class ne $classname} {
            # TBD - should we make a note in the documentation somewhere ?
            app::log_error "Method $name in class $classname is hidden by class $implementing_class."
        }

        if {[lsearch -exact $public_methods $name] >= 0} {
            set visibility public
        } else {
            set visibility private
        }

        if {! [catch {
            set method_info [extract_ooclass_method $classname $name]
        } msg]} {
            dict set method_info visibility $visibility
            #dict set method_info name $name
            dict lappend result methods $method_info
        } else {
            # Error, may be it is a forwarded method
            if {! [catch {
                set forward [info class forward $classname $name]
            }]} {
                dict lappend result forwards [dict create name $name forward $forward]
            } else {
                ruff::app::log_error "Could not introspect method $name in class $classname"
            }
        }
    }

    foreach name {constructor destructor} {
        if {[info class $name $classname] ne ""} {
            # Class has non-empty constructor or destructor
            dict set result $name [extract_ooclass_method $classname $name]
        }
    }

    dict set result name $classname;   # TBD - should we fully qualify this?
    dict set result external_methods $external_methods
    dict set result filters [info class filters $classname]
    dict set result mixins [info class mixins $classname]
    dict set result subclasses [info class subclasses $classname]
    # We do not want to list ::oo::object which is a superclass
    # of all classes.
    set classes {}
    foreach class [info class superclasses $classname] {
        if {$class ne "::oo::object"} {
            lappend classes $class
        }
    }
    dict set result superclasses $classes

    return $result
}


proc ruff::private::extract_procs_and_classes {pattern args} {
    # Extracts metainformation for procs and classes 
    #
    # pattern - glob-style pattern to match against procedure and class names
    # -includeclasses BOOLEAN - if true (default), class information
    #     is collected
    # -includeprocs - if true (default), proc information is
    #     collected
    # -includeprivate BOOLEAN - if true private methods are also included.
    #  Default is false.
    # -includeimports BOOLEAN - if true commands imported from other
    #  namespaces are also included. Default is false.
    #
    # The value of the classes key in the returned dictionary is
    # a dictionary whose keys are class names and whose corresponding values
    # are in the format returned by extract_ooclass.
    # Similarly, the procs key contains a dictionary whose keys
    # are proc names and whose corresponding values are in the format
    # as returned by extract_proc.
    #
    # Note that only the program elements in the same namespace as
    # the namespace of $pattern are returned.
    #
    # Returns a dictionary with keys 'classes' and 'procs'

    array set opts {
        -includeclasses true
        -includeprocs true
        -includeprivate false
        -includeimports false
    }
    array set opts $args

    set classes [dict create]
    if {$opts(-includeclasses)} {
        # TBD - We do a catch in case this Tcl version does not support objects
        set class_names {}
        catch {set class_names [info class instances ::oo::class $pattern]}
        foreach class_name $class_names {
            # This covers child namespaces as well which we do not want
            # so filter those out. The differing pattern interpretations in
            # Tcl commands 'info class instances' and 'info procs'
            # necessitates this.
            if {[namespace qualifiers $class_name] ne [namespace qualifiers $pattern]} {
                # Class is in not in desired namespace
                # TBD - do we need to do -includeimports processing here?
                continue
            }
            # Names beginning with _ are treated as private
            if {(!$opts(-includeprivate)) &&
                [string index [namespace tail $class_name] 0] eq "_"} {
                continue
            }

            if {[catch {
                set class_info [extract_ooclass $class_name -includeprivate $opts(-includeprivate)]
            } msg]} {
                app::log_error "Could not document class $class_name: $msg"
            } else {
                dict set classes $class_name $class_info
            }
        }
    }

    set procs [dict create]
    if {$opts(-includeprocs)} {
        # Collect procs
        foreach proc_name [info procs $pattern] {
            if {(! $opts(-includeimports)) &&
                [namespace origin $proc_name] ne $proc_name} {
                continue;       # Do not want to include imported commands
            }
            # Names beginning with _ are treated as private
            if {(!$opts(-includeprivate)) &&
                [string index [namespace tail $proc_name] 0] eq "_"} {
                continue
            }

            if {[catch {
                set proc_info [extract_proc $proc_name]
            } msg]} {
                app::log_error "Could not document proc $proc_name: $msg"
            } else {
                dict set procs $proc_name $proc_info
            }
        }
        # Collect ensembles
        foreach ens_name [ensembles $pattern] {
            if {(! $opts(-includeimports)) &&
                [namespace origin $ens_name] ne $ens_name} {
                continue;       # Do not want to include imported commands
            }
            # Names beginning with _ are treated as private
            if {(!$opts(-includeprivate)) &&
                [string index [namespace tail $ens_name] 0] eq "_"} {
                continue
            }

            if {[catch {
                set ens_cmds [extract_ensemble $ens_name]
            } msg]} {
                app::log_error "Could not document ensemble command $ens_name: $msg"
            } else {
                foreach ens_info $ens_cmds {
                    dict set procs [dict get $ens_info name] $ens_info
                }
            }
        }
    }

    return [dict create classes $classes procs $procs]
}


proc ruff::private::extract_namespace {ns args} {
    # Extracts metainformation for procs and objects in a namespace
    # ns - namespace to examine
    #
    # Any additional options are passed on to the extract command.
    #
    # Returns a dictionary containing information for the namespace.

    # The returned dictionary has keys `preamble`, `classes` and `procs`.
    # See [extract_docstring] for format of the `preamble` value
    # and [extract_procs_and_classes] for the others.

    set result [extract_procs_and_classes ${ns}::* {*}$args]
    set preamble [list ]
    if {[info exists ${ns}::_ruff_preamble]} {
        set preamble [extract_docstring [set ${ns}::_ruff_preamble]]
    } elseif {[info exists ${ns}::_ruffdoc]} {
        foreach {heading text} [set ${ns}::_ruffdoc] {
            lappend preamble {*}[extract_docstring "## $heading"]
            lappend preamble {*}[extract_docstring $text]
        }
    }
    dict set result preamble $preamble
    return $result
}

proc ruff::private::extract_namespaces {namespaces args} {
    # Extracts metainformation for procs and objects in one or more namespace
    # namespaces - list of namespace to examine
    #
    # Any additional options are passed on to the extract_namespace command.
    #
    # The dictionary returned is keyed by namespace with nested
    # keys 'classes' and 'procs'. See [extract] for details.
    #
    # Returns a dictionary with the namespace information.

    set result [dict create]
    foreach ns $namespaces {
        dict set result $ns [extract_namespace $ns {*}$args]
    }
    return $result
}


proc ruff::private::get_ooclass_method_path {class_name method_name} {
    # Calculates the class search order for a method of the specified class
    # class_name - name of the class to which the method belongs
    # method_name - method name being searched for
    #
    # A method implementation may be provided by the class itself,
    # a mixin or a superclass.
    # This command calculates the order in which these are searched
    # to locate the method. The primary purpose is to find exactly
    # which class actually implements a method exposed by the class.
    #
    # If a class occurs multiple times due to inheritance or
    # mixins, the LAST occurence of the class is what determines
    # the priority of that class in method selection. Therefore
    # the returned search path may contain repeated elements.
    #
    # Note that this routine only applies to a class and cannot be
    # used with individual objects which may have their own mix-ins.


    # TBD - do we need to distinguish private/public methods

    set method_path {}
    #ruff
    # Search algorithm:
    #  - Filters are ignored. They may be invoked but are not considered
    #    implementation of the method itself.
    #  - The mixins of a class are searched even before the class itself
    #    as are the superclasses of the mixins.
    foreach mixin [info class mixins $class_name] {
        # We first need to check if the method name is in the public interface
        # for this class. This step is NOT redundant since a derived
        # class may unexport a method from an inherited class in which
        # case we should not have the inherited classes in the path
        # either.
        if {[lsearch -exact [info class methods $mixin -all] $method_name] < 0} {
            continue
        }

        set method_path [concat $method_path [get_ooclass_method_path $mixin $method_name]]
    }

    #ruff - next in the search path is the class itself
    if {[lsearch -exact [info class methods $class_name] $method_name] >= 0} {
        lappend method_path $class_name
    }

    #ruff - Last in the search order are the superclasses (in recursive fashion)
    foreach super [info class superclasses $class_name] {
        # See comment in mixin code above.
        if {[lsearch -exact [info class methods $super -all] $method_name] < 0} {
            continue
        }
        set method_path [concat $method_path [get_ooclass_method_path $super $method_name]]
    }


    #ruff
    # Returns an ordered list containing the classes that are searched
    # to locate a method for the specified class.
    return $method_path
}

proc ruff::private::locate_ooclass_method {class_name method_name} {
    # Locates the classe that implement the specified method of a class
    # class_name - name of the class to which the method belongs
    # method_name - method name being searched for
    #
    # The matching class may implement the method itself or through
    # one of its own mix-ins or superclasses.
    #
    # Returns the name of the implementing class or an empty string
    # if the method is not implemented.

    # Note: we CANNOT just calculate a canonical search path for a
    # given class and then search along that for a class that
    # implements a method. The search path itself will depend on the
    # specific method being searched for due to the fact that a
    # superclass may not appear in a particular search path if a
    # derived class hides a method (this is just one case, there may
    # be others). Luckily, get_ooclass_method_path does exactly this.


    set class_path [get_ooclass_method_path $class_name $method_name]

    if {[llength $class_path] == 0} {
        return "";              # Method not found
    }

    # Now we cannot just pick the first element in the path. We have
    # to find the *last* occurence of each class - that will decide
    # the priority order
    set order [dict create]
    set pos 0
    foreach path_elem $class_path {
        dict set order $path_elem $pos
        incr pos
    }

    return [lindex $class_path [lindex [lsort -integer [dict values $order]] 0] 0]
}


proc ruff::private::load_formatters {} {
    # Loads all available formatter implementations
    foreach formatter {html markdown} {
        load_formatter $formatter
    }
}

proc ruff::private::load_formatter {formatter} {
    # Loads the specified formatter implementation
    variable ruff_dir
    set class [namespace parent]::formatter::[string totitle $formatter]
    if {![info object isa class $class]} {
        uplevel #0 [list source [file join $ruff_dir formatter_${formatter}.tcl]]
    }
    return $class
}

proc ruff::document {formatter namespaces args} {
    # Generates documentation for the specified namespaces using the
    # specified formatter.
    # formatter - the formatter to be used to produce the documentation
    # namespaces - list of namespaces for which documentation is to be generated
    # -includeclasses BOOLEAN - if true (default), class information
    #     is collected
    # -includeprocs BOOLEAN - if true (default), proc information is
    #     collected
    # -includeprivate BOOLEAN - if true private methods are also included
    #  in the generated documentation. Default is false.
    # -includesource BOOLEAN - if true, the source code of the
    #  procedure is also included. Default value is false.
    # -output PATH - if specified, the generated document is written
    #  to the specified file which will overwritten if it already exists.
    # -title STRING - specifies the title to use for the page
    # -recurse BOOLEAN - if true, child namespaces are recursively
    #  documented.
    # -pagesplit SPLIT - if `none`, a single documentation file is produced.
    #  If `namespace`, a separate file is output for every namespace.
    #
    # Any additional arguments are passed through to the document command.
    #
    # Returns the documentation string if the -output option is not
    # specified, otherwise returns an empty string after writing the
    # documentation to the specified file.

    array set opts {
        -hidesourcecomments false
        -includeclasses true
        -includeprivate false
        -includeprocs true
        -includesource false
        -output ""
        -preamble ""
        -recurse false
        -pagesplit none
        -title ""
    }

    array set opts $args
    namespace upvar private ProgramOptions ProgramOptions
    set ProgramOptions(-hidesourcecomments) $opts(-hidesourcecomments)
    if {$opts(-pagesplit) ni {none namespace}} {
        error "Option -pagesplit must be \"none\" or \"namespace\" "
    }
    set ProgramOptions(-pagesplit) $opts(-pagesplit)

    array unset private::ns_file_base_cache
    if {$opts(-output) eq ""} {
        if {$opts(-pagesplit) ne "none"} {
            # Need to link across files so output must be specified.
            error "Output file must be specified with -output if -pagesplit option is not \"none\"."
        }
    } else {
        set private::output_file_base [file root [file tail $opts(-output)]]
        set private::output_file_ext [file extension $opts(-output)]
    }

    # Fully qualify namespaces
    set namespaces [lmap ns $namespaces {
        if {[string match ::* $ns]} {
            set ns
        } else {
            return -level 0 "[uplevel 1 {namespace current}]::$ns"
        }
    }]

    if {$opts(-recurse)} {
        set namespaces [namespace_tree $namespaces]
    }

    # TBD - make sane the use of -modulename
    lappend args -modulename $opts(-title)

    if {$opts(-preamble) ne ""} {
        # TBD - format of -preamble argument passed to formatters
        # is different so override what was passed in.
        lappend args -preamble [extract_docstring $opts(-preamble)]
    }

    set classprocinfodict [extract_namespaces $namespaces \
                               -includeclasses $opts(-includeclasses) \
                               -includeprocs $opts(-includeprocs) \
                               -includeprivate $opts(-includeprivate)]

    set obj [[load_formatter $formatter] new]
    set docs [$obj generate_document $classprocinfodict {*}$args]
    $obj destroy

    if {$opts(-output) eq ""} {
        return $docs
    }

    set dir [file dirname $opts(-output)]
    file mkdir $dir
    foreach {ns doc} $docs {
        set fn [private::ns_file_base $ns]
        set fd [open [file join $dir $fn] w]
        fconfigure $fd -encoding utf-8
        if {[catch {
            puts $fd $doc
        } msg]} {
            close $fd
            error $msg
        }
        close $fd
    }
    return
}

proc ruff::formatters {} {
    # Get the list of supported formatters.
    #
    # Ruff! can produce documentation in several formats each of which
    # is produced by a specific formatter. This command returns the list
    # of such formatters that can be used with commands like
    # document.
    #
    # Returns a list of available formatters.
    return [lsort [lmap ns [namespace children formatter] {
        namespace tail $ns
    }]]
}

# TBD - where is this used
proc ruff::private::wrap_text {text args} {
    # Wraps a string such that each line is less than a given width
    # and begins with the specified prefix.
    # text - the string to be reformatted
    # The following options may be specified:
    # -width INTEGER - the maximum width of each line including the prefix 
    #  (defaults to 60)
    # -prefix STRING - a string that every line must begin with. Defaults
    #  to an empty string.
    # -prefix1 STRING - prefix to be used for the first line. If unspecified
    #  defaults to the value for the -prefix option if specified
    #  and an empty string otherwise.
    #
    # The given text is transformed such that it consists of
    # a series of lines separated by a newline character
    # where each line begins with the specified prefix and
    # is no longer than the specified width.
    # Further each line is filled with as many characters
    # as possible without breaking a word across lines.
    # Blank lines and leading and trailing spaces are removed.
    #
    # Returns the wrapped and indented text

    set opts [dict merge [dict create -width 60 -prefix ""] $args]

    if {![dict exists $opts -prefix1]} {
        dict set opts -prefix1 [dict get $opts -prefix]
    }

    set prefix [dict get $opts -prefix]
    set prefix1 [dict get $opts -prefix1]

    set width [dict get $opts -width]
    # Reduce the width by the longer prefix length
    if {[string length $prefix] > [string length $prefix1]} {
        incr width  -[string length $prefix]
    } else {
        incr width  -[string length $prefix1]
    }

    # Note the following is not optimal in the sense that
    # it is possible some lines could fit more words but it's
    # simple and quick.

    # First reformat
    set text [textutil::adjust::indent \
                  [::textutil::adjust::adjust $text -length $width] \
                  $prefix]

    # Replace the prefix for the first line. Note that because of
    # the reduction in width based on the longer prefix above,
    # the max specified width will not be exceeded.
    return [string replace $text 0 [expr {[string length $prefix]-1}] $prefix1]
}

proc ruff::private::document_self {args} {
    # Generates documentation for Ruff!
    # -formatter FORMATTER - the formatter to use (default html)
    # -outdir DIRPATH - the output directory where files will be stored. Note
    #  files in this directory with the same name as the output files
    #  will be overwritten! (default sibling `doc` directory)
    # -includesource BOOLEAN - if `true`, include source code in documentation.
    #  Default is `false`.

    variable ruff_dir
    variable names

    array set opts [list \
                        -formatter html \
                        -includesource true \
                        -pagesplit namespace \
                        -includeprivate false \
                        -outdir [file join $ruff_dir .. doc] \
                       ]
    array set opts $args

    if {![namespace exists ::ruff::sample]} {
        if {[file exists [file join $ruff_dir sample.tcl]]} {
            uplevel #0 [list source [file join $ruff_dir sample.tcl]]
        } else {
            uplevel #0 [list source [file join $ruff_dir .. doc sample.tcl]]
        }
    }
 
    load_formatters

    file mkdir $opts(-outdir)
    set namespaces [list ::ruff ::ruff::sample]
    set title "Ruff! - Runtime Formatting Function Reference (V$::ruff::version)"
    set common_args [list \
                         -recurse $opts(-includeprivate) \
                         -titledesc $title \
                         -pagesplit $opts(-pagesplit) \
                         -preamble $::ruff::_ruff_intro \
                         -version $::ruff::version]
    switch -exact -- $opts(-formatter) {
        doctools {
            error "Formatter '$opts(-formatter)' not implemented for generating Ruff! documentation."
            # Not implemented yet
            document doctools $namespaces {*}$common_args \
                -output [file join $opts(-outdir) ruff.man] \
                -hidenamespace ::ruff \
                -keywords [list "documentation generation"] \
                -modulename ::ruff
        }
        markdown -
        html {
            if {$opts(-formatter) eq "html"} {
                set ext .html
            } else {
                set ext .md
            }
            document $opts(-formatter) $namespaces {*}$common_args \
                -output [file join $opts(-outdir) ruff$ext] \
                -titledesc $title \
                -copyright "[clock format [clock seconds] -format %Y] Ashok P. Nadkarni" \
                -includesource $opts(-includesource)
        }
        default {
            # The formatter may exist but we do not support it for
            # out documentation.
            error "Formatter '$opts(-formatter)' not implemented for generating Ruff! documentation."
        }
    }
    return
}

source [file join $::ruff::private::ruff_dir formatter.tcl]

################################################################
#### Application overrides

# The app namespace is for commands the application might want to
# override
namespace eval ruff::app {
}


proc ruff::app::log_error {msg} {
    # Stub function to log Ruff! errors.
    # msg - the message to be logged
    #
    # When Ruff! encounters errors, it calls this command to
    # notify the user. By default, the command writes $msg
    # to stderr output. An application using the ruff package
    # can redefine this command after loading ruff.
    puts stderr "$msg"
}




package provide ruff $::ruff::version
