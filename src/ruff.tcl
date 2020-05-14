# Copyright (c) 2009-2019, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the source root directory for license.

# Ruff! - RUntime Formatting Function
# ...a document generator using introspection
#

package require Tcl 8.6
if {[catch {
    package require textutil::adjust
    package require textutil::tabify
} msg ropts]} {
    puts stderr "Ruff! needs packages textutil::adjust and textutil::tabify from tcllib."
    return -options $ropts $msg
}

namespace eval ruff {
    # If you change version here, change in pkgIndex.tcl as well
    variable version 1.0.4
    proc version {} {
        # Returns the Ruff! version.
        variable version
        return $version
    }

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
        Ruff! produces documentation that not only requires less duplication
        of effort from the programmer, but is also more complete, more
        accurate and more maintainable.

        * Comments in source code do not have to be
        reproduced for documentation purposes.

        * Ruff! requires minimal markup in the comments making it lightweight
        as well as reducing clutter.

        * Supports inline formatting using Markdown syntax.

        * Program elements like command arguments, defaults and 
        class relationships like inheritance are automatically derived.

        * Maintenance is less of a burden as documentation is automatically
        updated with source modification such as changes to defaults, addition of
        mix-ins etc.

        On the output side,

        * Ruff! supports multiple formats (currently HTML and Markdown).
        Additional formats can be added through subclassing.

        * Generated documentation can optionally be split across multiple pages.

        * Hyperlinks between program elements, and optionally source code,
        make navigation easy and efficient.

        * In object oriented code, class relationships are extracted
        and the full API for a class, with inherited and mixed-in methods, is
        flattened and summarized.

        The Ruff! documentation itself is produced with Ruff!. For a larger
        example, see the
        [CAWT](http://www.cawt.tcl3d.org/download/CawtReference.html)
        reference manual or
        the reference pages for [Woof!](http://woof.sourceforge.net/woof-ug-0.5/html/_woof/woof_manual.html) (though the latter is with an older version of Ruff!).

        ## Documentation

        The [::ruff] reference page describes the Ruff! documentation generation
        API. The [::ruff::sample] page shows some sample output for some of the
        Ruff! features along with the associated source code from which
        it was generated.

        ## Downloads and Install


        Download the Ruff! distribution from
        <https://sourceforge.net/projects/magicsplat/files/ruff/>. The
        source code repository is at <https://github.com/apnadkarni/ruff>.

        To install, extract the distribution to a directory listed in your
        Tcl `auto_path` variable.

        ## Credits

        Ruff! is authored by [Ashok P. Nadkarni](https://www.magicsplat.com).

        It uses the `textutil` package from
        [tcllib](https://core.tcl-lang.org/tcllib) and a modified version of the
        Markdown inline parser from the
        [Caius](http://caiusproject.com/) project.
    }

    variable _ruff_preamble {

        ## Usage

        Ruff! is not intended to be a standalone script. Rather the package
        provides commands that should be driven from a script that controls
        which particular namespaces, classes etc. are to be included.

        To document a package, first load it into a Tcl interpreter.
        Then load `ruff` and invoke the [document] command to document
        classes and commands within one or more namespaces.

        For example, the following command will document the `NS` namespace using
        the built-in HTML formatter.
        ````
        package require ruff
        ::ruff::document ::NS
        ````
        The output will be written to `NS.html`.

        The following will document the namespace `NS`, `NS2` and their children,
        splitting the output across multiple pages.
        ````
        ::ruff::document {::NS ::NS2} -output docs.html -recurse true -pagesplit namespace
        ````
        Refer to [document] for various other options.

        ## Documenting procedures

        Ruff! generates documentation using Tcl's runtime system to gather
        proc and class definitions. Comments in procedure and method
        bodies are further parsed to extract the documentation.

        The structure Ruff! expects is described below. In practice,
        the structure is simple and intuitive though the description may be
        a bit long winded. You can simply look at the documentation
        of the [sample] namespace instead, and click on the **Show source**
        links for each procedure or method there to see the formatting.

        An example procedure may look as follows:
        ```
        proc ruff::sample::character_at {text {pos 0}} {
            # Get the character from a string.
            #  text - Text string.
            #  pos  - Character position. 
            # The command will treat negative values of $pos as offset from
            # the end of the string.
            #
            # Returns the character at index $pos in string $text.
            set n [string length $text]
            if {[tcl::mathfunc::abs $pos] >= [string length $text]} {
                #ruff
                # An error exception is raised if $pos is not within bounds.
                error "Index $pos out of bounds."
            }
            if {$pos < 0} {
                return [string index $text end$pos]
            } else {
                return [string index $text $pos]
            }
        }
        ```
        You can see the generated documentation for the above at 
        [sample::character_at].

        The first block of comments within a procedure *before
        the first line of code* are always processed by Ruff!. Note preceding
        blank lines are OK. We will refer to this block as the lead comment
        block. It is terminated by either a line of code or a blank line.

        Any comments appearing after the first line of code are not
        processed by Ruff! unless immediately preceded by a line beginning
        with `#ruff` which indicates the start of another Ruff! comment
        block.

        The lead comment block begins with a summary that will be used anywhere
        the document output inserts a procedure summary, for example, a tooltip.
        The summary is terminated with a blank comment or by the parameter
        block.

        The parameter block is a definition list (see below) and follows its
        syntactic structure. It only differs from definition lists in that
        it must directly follow the summary line and receives special
        treatment in that the default value, if any for the argument, is
        automatically inserted by Ruff!. Options and switches may also be
        documented here. The parameter block
        is terminated in the same fashion as definition blocks.

        Any blocks following the parameter block, whether part of the lead
        block or appearing in a subsequent comment block marked with a
        leading `#ruff`, are processed as follows.

        * All processed lines are stripped of the leading `#` character and a
        single following space if there is one.

        * A blank line (after the comment character is stripped) ends the
        previous block. Note in the case of lists, it ends the list element
        but not the list itself.

        * A line containing 3 or more consecutive backquote (\`) characters
        with only surrounding whitespace on the line starts a fenced
        block. The block is terminated by the same sequence and
        all intervening lines are passed through to the output unchanged.

        * Lines starting with a `-` or a `*` character followed by at least one
        space begins a bulleted list item block. A list item may be continued
        across multiple lines and is terminated by another list item, a blank
        line or a line with lesser indentation. Note in particular that lines of
        other types will not terminate a list item unless they have less
        indentation.

        * Lines containing a `-` surrounded by whitespace begins a definition
        list element. The text before the `-` separator is the definition term
        and the text after is the description. Both the term and description are
        subject to inline formatting. Definition blocks follow the same rules
        for termination as bullet lists described above.

        * Parameter blocks have the same format as definition lists and are
        distinguished from them only by their presence in the lead block. Unlike
        definition blocks, the term is assumed to be the name of an argument and
        is automatically formatted and not subject to inline formatting.

        * If the line is indented 4 or more spaces, it is treated a
        preformatted line and passed through to the output with the
        the first 4 spaces stripped. No other processing is done on the line.

        * Any line beginning with the word `Returns` is treated as
        description of the return value. It follows the same rules as normal
        paragraphs below.

        * A line beginning with `See also:` (note the colon) is assumed to begin
        a reference block consisting of a list of program element names
        (such as procedures, classes etc.) and Markdown links. These
        are then automatically linked and listed in the **See also** section of a
        procedure documentation. The list may continue over multiple lines
        following normal paragraph rules. Each line must be parsable as a Tcl list.
        Note the program element names can,
        but need not be, explicitly marked as a program element reference
        using surrounding square brackets. For example, within a `See also:`
        section, both `document` and `[document]` will generate a cross-reference
        link to the documentation for the `document` procedure.

        * All other lines begin a normal paragraph. The paragraph ends with
        a line of one of the above types.

        ### Differences from Markdown

        Note that the block level parsing is similar but not identical to
        Markdown. Amongst other differences, Ruff! has

        * no nested blocks
        * no numbered lists or multi-paragraph list elements
        * no blockquotes

        Ruff! adds
        * definition lists

        ## Documenting classes

        Documentation for classes primarily concerns documentation of its methods.
        The format for method documentation is exactly as described above for
        procedures. Information about class relationships is automatically
        collected and need not be explicitly provided. Note that unlike for
        procedures and methods, Tcl does not provide a means to retrieve the
        body of the class so that comments can be extracted from them. Thus
        to document information about the class as a whole, you can either
        include it in the comments for the constructor, which is often a
        reasonable place for such information, or include it in the general
        information section as described in the next section.

        ## Documenting namespaces

        In addition to procedures and classes within a namespace, there may be a
        need to document general information such as the sections you are
        currently reading. For this purpose, Ruff! looks for a variable
        `_ruff_preamble` within each namespace. The indentation of the first
        line of section content is stripped off from all subsequent lines before
        processing (This impacts what constitutes a preformatted line). The
        result is then processed in the same manner as procedure or method
        bodies except for the following differences:

        * There is (obviously) no summary or parameter block.

        * Additionally, content may contain Markdown ATX style
        headings indicated by a prefix of one or more `#` characters followed
        by at least one space.

        The documentation generated from the `_ruff_preamble` content is placed
        before the documentation of the commands in classes for that namespace.

        **Note**: Older versions supported the `_ruffdoc` variable. Though this
        will still work, it is deprecated.

        Content that should lie outside of any namespace can be passed through
        the `-preamble` option to [document]. When generating single page
        output, this is included at the top of the documentation. When
        generating multipage output this forms the content of the main
        documentation page.

        ## Inline formatting

        Once documentation blocks are parsed as above, their content is subject
        to inline formatting rules using Markdown syntax with some minor
        extensions. Markdown compatibility is only for inline elements noted
        below.

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
        relative to the namespace or class within whose documentation the link
        appears. If it is fully qualified, it is displayed relative to the
        namespace of the link location. For example,

        * `[document]` is displayed as [document]
        * `[::ruff::formatters]` is displayed as [::ruff::formatters] if
        referenced from within a section documenting the `::ruff` namespace.

        Alternatively, text different from the section heading or symbol
        can be shown by putting it in another `[]` pair immediately bfore
        the symbol or heading reference.
        For example, `[here][document]` will show as [here][document] and
        link to `document` as before.
        *Note: unlike Markdown, there must be no whitespace between the
        two pairs of `[]` else it will be treated as two separate symbol
        references. This is intentional.*


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
        Ruff! itself in a single page format:

        ```
        ruff::document ::ruff -title "Ruff! reference"
        ```

        To generate documentation, including private namespaces, in multipage
        format:
        ````
        ruff::document ::ruff -recurse true -pagesplit namespace -output full/ruff.html -title "Ruff! internal reference"
        ````

        ### Markdown formatter

        The Markdown formatter generates output in generic Markdown syntax.
        It includes cross-linking but does not include a table of contents,
        tooltips or source code display. On the other hand, it allows conversion
        to other formats using external tools.

        The following generates Ruff! documentation in Markdown format and
        then uses `pandoc` to convert it to HTML.
        ```
        ruff::document ::ruff -format markdown -output ruff.md -title "Ruff! reference"
        ```
        Then from the shell or Windows command line,
        ```
        pandoc -s -o ruff.html -c ../ruff-md.css --metadata pagetitle="My package" ruff.md
        ```

        When generating HTML from Markdown, it is generally desirable to specify
        a CSS style file. The `ruff-md.css` file provides some *minimal* CSS that
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

proc ruff::private::ns_file_base {ns_or_class {ext {}}} {
    # Returns the file name to use for documenting namespace $ns.
    # ns_or_class - the namespace or class for the file
    # ext - if non-empty, this is used as the file extension.
    #  It should include the initial period.
    variable output_file_base
    variable output_file_ext
    variable ns_file_base_cache
    variable ProgramOptions

    # Methods can also be represented as Class::method so this is a
    # hack to get the real namespace and not the class name
    if {[info object isa class $ns_or_class]} {
        set ns [namespace qualifiers $ns_or_class]
    } else {
        set ns $ns_or_class
    }
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
        {^(#+)\s+(\S.*)} {
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

proc ruff::private::extract_seealso_symbols {symbols} {
    # symbols - text line with symbols optionally separated by commas and optional
    #   surrounding square brackets
    return [lmap symbol $symbols {
        set symbol [string trim $symbol ,]; # Permit commas between elements
        if {$symbol eq ""} {
            continue
        }
        set symbol
    }]
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
    lappend state(seealso) {*}[extract_seealso_symbols [dict get $state(parsed) Text]]
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
        lappend state(seealso) {*}[extract_seealso_symbols [dict get $state(parsed) Text]]
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
                if {[info exists term]} {
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
            continuation {
                # TBD - See if we can get rid of continuation state
                # we do not really use this state.
                parse_normal_state state
            }
            normal       { parse_normal_state state }
            preformatted { parse_preformatted_state state }
            fence        { parse_fence_state state }
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
            if {$name eq "args"} {
                set definition "Optional arguments."
            } else {
                set definition "Not documented."
            }
            set paramdata [dict create term $name definition $definition type parameter]
        }

        # Check if there is a default
        if {[info exists param_default($name)]} {
            dict set paramdata default $param_default($name)
        }

        dict set paramdata type parameter
        lappend parameters $paramdata
    }

    # Add any left over parameters from the documentation in sorted
    # order.
    foreach name [lsort -dictionary [array names params]] {
        dict set params($name) type "option"; # Assume option since not in proc definition
        lappend parameters $params($name)
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

    foreach name [lsort -dictionary $all_methods] {
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
    # -excludeclasses REGEXP - If specified, any classes whose names
    #  match `REGEXPR` will not be included in the documentation.
    # -excludeprocs REGEXP - If specified, any procedures whose names
    #  match `REGEXPR` will not be included in the documentation.
    # -include LIST - `classes` and / or `procs` depending on whether one
    #     or both are to be collected.
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
        -excludeclasses {}
        -excludeprocs {}
        -include {procs classes}
        -includeprivate false
        -includeimports false
    }
    array set opts $args

    set classes [dict create]
    if {"classes" in $opts(-include)} {
        set class_names [info class instances ::oo::class $pattern]
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
            if {$opts(-excludeclasses) ne "" &&
                [regexp $opts(-excludeclasses) [namespace tail $class_name]]} {
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
    if {"procs" in $opts(-include)} {
        # Collect procs
        foreach proc_name [info procs $pattern] {
            if {$opts(-excludeprocs) ne "" &&
                [regexp $opts(-excludeprocs) [namespace tail $proc_name]]} {
                continue
            }
            if {(! $opts(-includeimports)) &&
                [namespace origin $proc_name] ne $proc_name} {
                continue;       # Do not want to include imported commands
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
            if {$opts(-excludeprocs) ne "" &&
                [regexp $opts(-excludeprocs) [namespace tail $ens_name]]} {
                continue
            }
            if {(! $opts(-includeimports)) &&
                [namespace origin $ens_name] ne $ens_name} {
                continue;       # Do not want to include imported commands
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
    foreach formatter [formatters] {
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

proc ruff::document {namespaces args} {
    # Generates documentation for commands and classes.
    # namespaces - list of namespaces for which documentation is to be generated.
    # args - Options described below.
    # -autopunctuate BOOLEAN - If `true`, the first letter of definition
    #  descriptions (including parameter descriptions) is capitalized
    #  and a period added at the end if necessary.
    # -compact BOOLEAN - If `true`, documentation is generated in a more
    #  compact form, primarily by omitting headers within procedure and method
    #  definitions.
    # -excludeclasses REGEXP - If specified, any classes whose names
    #  match `REGEXPR` will not be included in the documentation.
    # -excludeprocs REGEXP - If specified, any procedures whose names
    #  match `REGEXPR` will not be included in the documentation.
    # -format FORMAT - The output format. `FORMAT` defaults to `html`.
    # -hidenamespace NAMESPACE - By default, documentation generated by Ruff!
    #  includes namespace qualifiers in all class and proc names. It is possible
    #  to have the generated output leave out the namespace qualifers by adding
    #  the `-hidenamespace NAMESPACE` qualifier to the document generation
    #  commands. This will omit `NAMESPACE` in displayed program element names
    #  and provides a more visually pleasing output with less noise. However,
    #  it may result in ambiguities in case of names being present in more than
    #  one namespace. In particular, some formatters may not cross-link correctly
    #  in such cases.
    # -include LIST - Specifies which program elements are to be documented.
    #  `LIST` must be a list from one or both amongst `classes` or `procs`.
    #  Defaults to both.
    # -includeprivate BOOLEAN - if true private methods are also included
    #  in the generated documentation. Default is false.
    # -includesource BOOLEAN - if true, the source code of the
    #  procedure is also included. Default value is false.
    # -navigation OPTS - Options controlling appearance and position of navigation
    #  box (see below). Not supported by all formatters.
    # -output PATH - Specifies the path of the output file.
    #  If the output is to multiple files, this is the path of the
    #  documentation top. Other files will named accordingly by
    #  appending the namespace. **Existing files are overwritten.**
    #  By default, the output file is written to the current directory
    #  with a name constructed from the first namespace specified.
    # -pagesplit SPLIT - if `none`, a single documentation file is produced.
    #  If `namespace`, a separate file is output for every namespace.
    # -preamble TEXT - Any text that should be appear at the beginning
    #  outside of any namespace documentation, for example an introduction
    #  or overview of a package. `TEXT` is assumed to be in Ruff! syntax.
    # -recurse BOOLEAN - if true, child namespaces are recursively
    #  documented.
    # -sortnamespaces BOOLEAN - if `true` (default) the namespaces are
    #  sorted in the navigation otherwise they are in the order passed in.
    # -stylesheets URLLIST - if specified, the stylesheets passed in URLLIST
    #  are used instead of the built-in styles. Note the built-in YUI is
    #  always included as it used for normalization and layout. Not all formatters
    #  may support this option.
    # -title STRING - specifies the title to use for the page
    #
    # The command generates documentation for one or more namespaces
    # and writes it out to file(s) as per the options shown above.
    # See [Documenting procedures], [Documenting classes] and
    # [Documenting namespaces] for details of the expected source
    # formats and the generation process.
    #
    # The `-navigation` option takes as an argument a list of values from the
    # table below. These control the positioning and appearance of the
    # navigation box. The list should contain at most one value from each
    # row.
    #
    #  `left`, `right` - Control whether navigation box is on the left or right
    #      side of the page. (Default `left`)
    #  `narrow`, `normal`, `wide` - Controls the width of the navigation box.
    #      (Default `normal`)
    #  `scrolled`, `sticky`, `fixed` - Controls navigation box behaviour when
    #      scrolling. If `scrolled`, the navigation box will scroll vertically
    #      along with the page. Thus it may not visible at all times. If
    #      `sticky` or `fixed`, the navigation box remains visible at all times.
    #      However, this requires the number of links in the box to fit on
    #      the page as they are never scrolled. There is a slight difference
    #      between the two behaviours. If `fixed`, the navigation box stays
    #      at its original position. If `sticky`, it will scroll till the top
    #      of the viewing area and then remain fixed. Note that older browsers
    #      do not support `sticky` and will resort to scrolling behaviour.
    #      (Default `scrolled`)

    array set opts {
        -compact 0
        -excludeprocs {}
        -excludeclasses {}
        -format html
        -hidesourcecomments false
        -include {procs classes}
        -includeprivate false
        -includesource false
        -output ""
        -preamble ""
        -recurse false
        -pagesplit none
        -sortnamespaces true
        -title ""
    }

    array set opts $args
    namespace upvar private ProgramOptions ProgramOptions
    set ProgramOptions(-hidesourcecomments) $opts(-hidesourcecomments)
    if {$opts(-pagesplit) ni {none namespace}} {
        error "Option -pagesplit must be \"none\" or \"namespace\" "
    }
    set ProgramOptions(-pagesplit) $opts(-pagesplit)

    # Fully qualify namespaces
    set namespaces [lmap ns $namespaces {
        if {![string match ::* $ns]} {
            set ns "[string trimright [uplevel 1 {namespace current}] ::]::$ns"
        }
        if {![namespace exists $ns]} {
            error "Namespace $ns does not exist."
        }
        set ns
    }]
    if {[llength $namespaces] == 0} {
        error "At least one namespace needs to be specified."
    }

    set formatter [[load_formatter $opts(-format)] new]

    array unset private::ns_file_base_cache
    if {$opts(-output) eq ""} {
        set opts(-output) [namespace tail [lindex $namespaces 0]]
    }
    set private::output_file_base [file root [file tail $opts(-output)]]
    set private::output_file_ext [file extension $opts(-output)]
    if {$private::output_file_ext in {{} .}} {
        set private::output_file_ext .[$formatter extension]
    }

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
                               -excludeprocs $opts(-excludeprocs) \
                               -excludeclasses $opts(-excludeclasses) \
                               -include $opts(-include) \
                               -includeprivate $opts(-includeprivate)]

    set docs [$formatter generate_document $classprocinfodict {*}$args]
    $formatter destroy

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
    # Gets the available output formatters.
    #
    # The returned values can be passed to [document] to generate
    # documentation in that format.
    #
    # Returns a list of available formatters.
    return {html markdown}
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
                        -format html \
                        -includesource true \
                        -pagesplit namespace \
                        -includeprivate false \
                        -outdir [file join $ruff_dir .. doc] \
                        -compact 0 \
                        -autopunctuate true \
                        -navigation {left sticky}
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
                         -compact $opts(-compact) \
                         -format $opts(-format) \
                         -recurse $opts(-includeprivate) \
                         -title $title \
                         -pagesplit $opts(-pagesplit) \
                         -preamble $::ruff::_ruff_intro \
                         -autopunctuate $opts(-autopunctuate) \
                         -version $::ruff::version]
    if {$opts(-includeprivate)} {
        lappend common_args -recurse 1
    } else {
        lappend common_args -excludeprocs {^[_A-Z]}
    }
    switch -exact -- $opts(-format) {
        doctools {
            error "Formatter '$opts(-format)' not implemented for generating Ruff! documentation."
            # Not implemented yet
            document $namespaces {*}$common_args \
                -output [file join $opts(-outdir) ruff.man] \
                -hidenamespace ::ruff \
                -keywords [list "documentation generation"] \
                -modulename ::ruff
        }
        markdown {
            document $namespaces {*}$common_args \
                -output [file join $opts(-outdir) ruff.md] \
                -title $title \
                -copyright "[clock format [clock seconds] -format %Y] Ashok P. Nadkarni" \
                -includesource $opts(-includesource)
        }
        html {
            if {[info exists opts(-stylesheets)]} {
                lappend common_args -stylesheets $opts(-stylesheets)
            }
            if {[info exists opts(-navigation)]} {
                lappend common_args -navigation $opts(-navigation)
            }
            document $namespaces {*}$common_args \
                -output [file join $opts(-outdir) ruff.html] \
                -title $title \
                -copyright "[clock format [clock seconds] -format %Y] Ashok P. Nadkarni" \
                -includesource $opts(-includesource)
        }
        default {
            # The formatter may exist but we do not support it for
            # out documentation.
            error "Format '$opts(-format)' not implemented for generating Ruff! documentation."
        }
    }
    return
}

proc ruff::private::distribute {{dir {}}} {
    if {$dir eq ""} {
        set dir [file join [ruff_dir] .. dist]
    }
    set outname ruff-[version]
    set dir [file join $dir $outname]
    set zipfile [file join $dir ${outname}.zip]
    file mkdir $dir
    set files {
        pkgIndex.tcl
        ruff.tcl
        formatter.tcl
        formatter_html.tcl
        formatter_markdown.tcl
        ruff-html.js
        ruff-html.css
        ruff-md.css
        ruff-yui.css
        ../doc/sample.tcl
        ../doc/ruff.html
        ../doc/ruff_ruff.html
        ../doc/ruff_ruff_sample.html
        ../LICENSE
        ../release.md
    }
    file copy -force -- {*}[lmap file $files {file join [ruff_dir] $file}] $dir
    file delete -force -- $zipfile
    set curdir [pwd]
    try {
        cd [file join $dir ..]
        exec {*}[auto_execok zip.exe] -r ${outname}.zip $outname
    } finally {
        cd $curdir
    }
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

# If we are the main script, accept commands.
if {[info exists argv0] &&
    [file dirname [file normalize [info script]/..]] eq [file dirname [file normalize $argv0/..]]} {
    switch -exact -- [lindex $argv 0] {
        document {
            ruff::private::document_self {*}[lrange $argv 1 end]
        }
        distribute {
            ruff::private::distribute {*}[lrange $argv 1 end]
        }
        default {
            puts "Unknown command \"[lindex $argv 0]\"."
        }
    }
}
