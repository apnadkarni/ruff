# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file WOOF_LICENSE in the Woof! root directory for license

# Ruff! - RUntime Formatting Function
# ...a document generator using introspection
#

package require Tcl 8.6
package require textutil::adjust

namespace eval ruff {
    variable version 0.6.0

    variable _ruffdoc
    set _ruffdoc {
        = Introduction

        Ruff! (Runtime function formatter) is a documentation generation
        system for programs written in the Tcl programming language. Ruff! is
        included with Woof! but can be used independently of it. Ruff! uses
        runtime introspection in conjunction with comment analysis to generate
        reference manuals for Tcl programs.

        Ruff! is covered by a liberal BSD open-source license that permits use
        for any purpose.

        = Why Ruff!

        In comparison with other source code based documentation generators, Ruff!
        produces documentation that not only requires less effort from the
        programmer, but is also more complete, more accurate and more
        maintainable.

        Ruff! saves the programmer the initial effort required for
        documentation:

        * Comments in source code do not have to be
        reproduced for documentation purposes.
        * Ruff! requires minimal
        markup in the comments making it very lightweight.
        * Program elements
        like command arguments and defaults, are automatically derived.
        * In object oriented code, class relationships are extracted
        and the full API for a class, with inherited and mixed-in methods,
        is easily seen.
        * Hyperlinking between program elements, and optionally, source code
        makes navigation of documentation easy and efficient.

        Further, maintaining documentation in sync with the code is much
        easier. For example, changing the defaults for arguments, or adding
        a mix-in to a class, is taken care of with no additional
        documentation effort.

        = Usage

        Ruff! is not intended to be a standalone script. Rather the package
        provides commands that should be driven from a script that controls
        which particular namespaces, classes etc. are to be included.
        Include the following command to load the package into your script.

            package require ruff

        Once loaded, you can use the [document] command to document
        classes and commands within one or more namespaces.

        The following command will create the file 'NS.html' using the
        built-in HTML formatter.

            package require ruff
            ::ruff::document html [list ::NS] -output NS.html -recurse true

        Refer to [document] for various options that control the
        content included in the documentation.

        = Documenting procedures

        Ruff! generates documentation using Tcl's runtime system to gather
        proc definitions. Comments in procedure bodies are further parsed to
        extract the documentation for the procedure.

        The general form of a procedure is as follows:

            proc myapp::myproc {arg {optarg AVALUE} args} {
                # This first line is the summary line for documentation.
                # arg - first parameter
                # optarg - an optional parameter
                # -switch VALUE - an optional switch
                #
                # This is the general description of the procedure
                # composed of multiple paragraphs. It is separated from
                # the parameter list above by one or more empty comments.
                #
                # This is the second paragraph. The next paragraph
                # starts with the word Returns and hence will be treated
                # by Ruff! as describing the return value.
                #
                # Returns a value.
                #
                # The above Return paragraph may appear anywhere, not
                # necessarily as the last paragraph.
                #
                # A definition list has a similar form to the argument
                # list. For example, optarg may take the following values:
                #  AVALUE - one possible value
                #  BVALUE - another possible value
                #
                # Bullet lists are indicated by a starting `-` or `*` character.
                # - This is a bullet list iterm
                # * This is also a bullet list item

                # This paragraph will be ignored by Ruff! as it is not part
                # of the initial block of comments.

                some code

                #ruff
                # Thanks to the #ruff marker above, this paragraph will be
                # included by Ruff! even though it is not in the initial block
                # of comments. This is useful for putting documentation for
                # a feature right next to the code implementing it.

                some more code.
            }

        Of course, any of the comment sections may be missing. For example,
        the following suffices for a simple procedure.

            proc answer {} {
                # Returns the Answer to the Ultimate Question of Life
                return 42
            }

        The structure Ruff! expects is described below. In practice,
        the structure is simple and intuitive though the description may be
        a bit long winded.

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
        paragraph in the **Description** section of procedure The summary
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

        * If the line is indented 4 or more spaces, it is treated a
        preformatted line and passed through to the output as is without any
        of the processing described above. This takes priority over all
        other types.

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

        * All other lines are treated as part of the previous block of
        lines. In the case of list elements, including parameter blocks and
        definition lists, the line is only treated as a continuation if its
        indentation is not less than the indentation of the first line of
        that list element. Otherwise it is treated as the start of a text
        paragraph. Lines following a blank line or a blank comment line are
        also treated as the start of a normal text paragraph.

        Refer to those commands for the syntax and comment structure expected
        by Ruff!.

        = Documenting classes

        Documentation for class methods is exactly as described above for
        procedures. Information about class relationships is automatically
        collected and need not be explicitly provided. Note that unlike for
        procedures and methods, Tcl does not provide a means to retrieve the
        body of the class so that comments can be extracted from them. Thus
        to document information about the class as a whole, you can either
        include it in the comments for the constructor, which is often a
        reasonable place for such information, or include it in the general
        information section as described in the next section.

        = Documenting namespaces

        Documentation for a namespace is generated by looking for the
        variable `_ruffdoc` within the namespace. If present, its content
        should be a list of alternating pairs comprising a section title and
        section content.

        The section content is processed in the same manner as the procedure
        and method bodies except that (obviously) there is no
        summary or parameter block. The indentation of the first line
        of section content is stripped off from all subsequent lines
        before processing or Ruff! (This impacts what constitutes a
        preformatted line).

        The documentation generated from the `_ruffdoc` content is placed
        before the documentation of the commands in classes for that namespace.

        = Inline formatting

        The text within paragraphs can be formatted as bold, italic, code
        etc. by using Markdown syntax with some minor extensions. Note
        Markdown compatibility is only for inline elements. **Markdown block
        level markup is not supported.**

        In particular, the following inline markup is supported:

        \`   - `Text surrounded by backquotes is formatted as inline code`
        `*`    - *Text surrounded by single asterisks is emphasize*
        `**`   - **Text surrounded by double asterisks is bolded**
        `***`  - ***Text surrounded by triple asterisks is bold emphasized***
        `[]`   - Text surrounded by square brackets is treated as a link
        (more below).
        `<>`   - Text in angle brackets are treated as HTML tags and
        auto-links as in Markdown.
        `$`    - Words beginning with `$` are treated as variable names and
        shown as inline code similar to backquotes (non-standard Markdown).

        The default HTML formatter supports other Markdown inline elements
        but other formatters might not.

        Text enclosed in `[]` is checked whether it references another
        program element name (namespaces, classes, methods, procedures). If so,
        it is replaced by a link to the documentation of that element. If
        the text is not a fully qualified name, it is treated relative to
        namespace or class within whose documentation the link appears. If
        it is fully qualified, it is displayed relative to the namespace of
        the link location. See example below.

        `[document]` - [document]
        `[::ruff::formatters]` - [::ruff::formatters]

        If the text does not match a program element name, it is
        treated as a normal Markdown reference. 


        = Output formats

        Ruff! is designed to support multiple output formats through
        pluggable formatters. The command [formatters] returns a list of
        supported formatters.

        Currently however, only a single formatter is implemented,
        the internal `html` formatter which supports
        cross-referencing, automatic link generation and navigation.
    }

    namespace eval private {
        namespace path [namespace parent]

        variable ruff_dir
        set ruff_dir [file dirname [info script]]

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
        if {$ProgramOptions(-singlepage) || $ns eq "::"} {
            set fn "$output_file_base$output_file_ext"
        } else {
            set fn "${output_file_base}_[regsub -all {[^-\w_.]} $ns _]$output_file_ext"
        }
        set ns_file_base_cache($ns) $fn
    }
    if {$ext eq ""} {
        return $ns_file_base_cache($ns)
    } else {
        return "[file rootname $ns_file_base_cache($ns)]$ext"
    }
}

proc ruff::private::regexp_escape {s} {
    return [string map {\\ \\\\ $ \\$ ^ \\^ . \\. ? \\? + \\+ * \\* | \\| ( \\( ) \\) [ \\[ ] \\] \{ \\\{ \} \\\} } $s]
}

# TBD - is this needed
proc ruff::private::build_symbol_regexp {symlist} {
    # Builds a regular expression that matches any of the specified
    # symbols or names
    # symlist - list of symbols or names
    #
    # Returns a regular expression that 
    # will match any of the name or the namespace tail component of
    # any of the names in symlist.

    # First collect all names and tail components and then join
    # them as alternatives. Note do NOT enclose them using regexp ()
    # groups since the formatting code then loses track of the
    # position of its own () groups.
    set alternatives {}
    foreach sym $symlist {
        lappend alternatives "[regexp_escape $sym]"
        # Add the tail component
        set tail [namespace tail $sym]
        if {$tail ne "$sym"} {
            lappend alternatives "[regexp_escape $tail]"
        }
    }

    return [join $alternatives "|"]
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

proc ruff::private::sift_classprocinfo {classprocinfodict} {
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

proc ruff::private::parse {lines {mode proc}} {
    # Creates a parse structure given a list of lines that are assumed
    # to be documentation for a programming structure
    #
    # lines - a list of lines comprising the documentation
    # mode - parsing mode, must be one of `proc`, `method`, `docstring`
    #

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
        switch -regexp -matchvar matches -- $line {
            {^\s*$} {
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
            }
            {^\s{4,}} {
                #ruff
                # Lines beginning with at least 4 spaces
                # are treated as preformatted text unless they are part
                # of a list item. Preformatted text is returned as a list
                # of lines.
                switch -exact -- $result(state) {
                    preformatted -
                    bulletlist -
                    deflist -
                    parameter -
                    option {
                        # No change. Keep adding to existing block
                    }
                    default {
                        change_state preformatted result
                    }
                }
                lappend result(fragment) $line
            }
            {^(\s*)[-\*]\s+(.*)$} {
                #ruff
                # A bulleted list item starts with a '-' or '*' character
                # and is not a preformatted line.
                # A list item may be continued across multiple lines.
                # A bulleted list is returned as a list containing the list
                # items, each of which is a list of lines.
                change_state bulletlist result
                lappend result(fragment) [lindex $matches 2]
            }
            {^\s*(=+)\s*(\S.*)} {
                #ruff
                # A markdown style header line
                if {$mode ne "docstring"} {
                    error "Header markup not supported within procs and methods."; # TBD - support headers in procs
                }
                change_state header result
                set result(header_level) [string length [lindex $matches 1]]
                lappend result(fragment) [lindex $matches 2]
            }
            {^(\s*)(\S.*?)\s+-\s+(.*)$} {
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
                    [lsearch -exact {init summary postsummary parameter option} $result(state)] >= 0} {
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
            }
            {^(\s*)Returns($|\s.*$)} {
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
            }
            default {
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
    }
    change_state finish result; # To process any leftovers in result(fragment)

    # Special case where the Returns is also the summary
    if {! $result(return_added)} {
        # If the summary matches a Returns statement, use that.
        if {[string match -nocase "returns *" [lindex $result(summary) 0]]} {
                lappend result(output) return $result(summary)
        }
    }

    #ruff
    # Returns a list of key value pairs where key is one of 'header',
    # 'parameter', 'option', 'bulletlist', 'deflist', 'parameter',
    # 'preformatted', 'paragraph' or 'return',
    # and the value
    # is the corresponding value.
    return $result(output)

}


# Note new state may be same as old state
# (but a new fragment)
proc ruff::private::change_state {new v_name} {
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

            # Summary is also included in the paragraphs
            lappend result(output) paragraph $result(fragment)

            # Save in case used for Returns statement
            set result(summary) $result(fragment)
        }
        paragraph {
            lappend result(output) paragraph $result(fragment)
        }
        preformatted {
            lappend result(output) preformatted $result(fragment)
        }
        header {
            lappend result(output) header [list $result(header_level) $result(fragment)]
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

    
    set lines {}
    set state init
    foreach line [split $text \n] {
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
    # The first block of contiguous comment lines preceding the 
    # first line of code are treated as documentation lines.

    set lines {}
    set state init;             # init, collecting or searching
    foreach line [split $text \n] {
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
    # deflist - the corresponding value is another list containing
    #   definition item name and its value as a string.
    # bulletlist - the corresponding value is a list of strings
    #   each being one list item.
    # paragraph - the corresponding value is a string comprising
    #   the paragraph.
    # preformatted - the corresponding value is a string comprising
    #   preformatted text.


    set paragraphs {}

    # Loop and construct the documentation
    foreach {type content} [parse [distill_docstring $text] docstring] {
        switch -exact -- $type {
            deflist {
                # Each named list is a list of pairs
                set deflist {}
                foreach {name desc} $content {
                    lappend deflist $name [join $desc " "]
                }
                lappend paragraphs deflist $deflist
            }
            bulletlist {
                # Bullet lists are lumped with paragraphs
                set bulletlist {}
                foreach desc $content {
                    lappend bulletlist [join $desc " "]
                }
                lappend paragraphs bulletlist $bulletlist
            }
            summary {
                # Do nothing. Summaries are same as the first
                # paragraph. For docstrings, we do not show
                # them separately like we do for procs
            }
            header {
                # Content is a pair {header_level, list of lines}
                lappend paragraphs header [list [lindex $content 0] [join [lindex $content 1] " "]]
            }
            paragraph {
                lappend paragraphs paragraph [join $content " "]
            }
            preformatted {
                lappend paragraphs preformatted [join $content \n]
            }
            default {
                error "Text fragments of type '$type' not supported in docstrings"
            }
        }
    }
    return $paragraphs
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
    return [extract_proc_or_method proc $procname [info args $procname] $param_defaults [info body $procname]]
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
        app::log_error "Skipping ensemble command $ens has it has a non-empty -parameters attribute."
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
            app::log_error "Skipping subcommand \"$cmd\" for ensemble \"$ens\" because it is not a procedure."
            continue
        }
        if {[catch {extract_proc $real_cmd} result]} {
            app::log_error "Could not retrieve information for \"$real_cmd\" implementing ensemble command \"$ens $cmd\": $result"
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


proc ruff::private::extract_proc_or_method {proctype procname param_names param_defaults body {class ""}} {
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
    #   name - name of the proc or method
    #   parameters - a list of parameters. Each element of the
    #     list is a pair or a triple, consisting of the parameter name,
    #     the description and possibly the default value if there is one.
    #   options - a list of options. Each element is a pair consisting
    #     of the name and its description.
    #   description - a list of paragraphs describing the command. The
    #     list contains preformatted, paragraph, bulletlist and deflist
    #     elements as described for the extract_docstring command.
    #   return - a description of the return value of the command
    #   summary - a copy of the first paragraph if it was present
    #     before the parameter descriptions.
    #   source - the source code of the command
    #

    variable ProgramOptions
    
    array set param_default $param_defaults
    array set params {}
    array set options {}
    set paragraphs {}

    # Loop and construct the documentation
    foreach {type content} [parse [distill_body $body] $proctype] {
        switch -exact -- $type {
            parameter {
                # For each parameter, check if it is a 
                # parameter in the proc/method definition
                foreach {name desc} $content {
                    if {[lsearch -exact $param_names $name] >= 0} {
                        set params($name) [join $desc " "]
                    } else {
                        # Assume it's a parameter as well. Perhaps it
                        # might be a possible token in the args parameter
                        app::log_error "Parameter '$name' not listed in arguments for '$procname'"
                        set params($name) [join $desc " "]
                    }
                }
            }
            summary -
            return {
                set doc($type) [join $content " "]
            }
            deflist {
                # Named lists are lumped with paragraphs
                # Each named list is a list of pairs
                set deflist {}
                foreach {name desc} $content {
                    lappend deflist $name [join $desc " "]
                }
                lappend paragraphs deflist $deflist
            }
            bulletlist {
                # Bullet lists are lumped with paragraphs
                set bulletlist {}
                foreach desc $content {
                    lappend bulletlist [join $desc " "]
                }
                lappend paragraphs bulletlist $bulletlist
            }
            option {
                foreach {name desc} $content {
                    if {[lsearch -exact $param_names "args"] < 0} {
                        app::log_error "Documentation for '$procname' contains option '$name' but the procedure definition does not have an 'args' parameter"
                    }
                    set options($name) [join $desc " "]
                }
            }
            header {
                error "Headers not supported in proc or method body"; # TBD - header in proc body
            }
            paragraph {
                lappend paragraphs paragraph [join $content " "]
            }
            preformatted {
                lappend paragraphs preformatted [join $content \n]
            }
            default {
                error "Unknown text fragment type '$type'."
            }
        }
    }

    set doc(name)        $procname
    set doc(class)       $class
    set doc(description) $paragraphs
    set doc(proctype)    $proctype

    # Construct parameter descriptions. Note those not listed in the
    # actual proc definition are left out even if they are in the params
    # table
    set doc(parameters) {}
    foreach name $param_names {
        if {[info exists params($name)]} {
            set paramdata [dict create name $name description $params($name) type parameter]
        } else {
            set paramdata [dict create name $name type parameter]
        }

        # Check if there is a default
        if {[info exists param_default($name)]} {
            dict set paramdata default $param_default($name)
        }

        lappend doc(parameters) $paramdata
    }

    # Add the options into the parameter table
    foreach name [lsort [array names options]] {
        lappend doc(parameters) [dict create name $name description $options($name) type option]
    }

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
    set doc(source) $source

    return [dict create {*}[array get doc]]
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


proc ruff::private::extract {pattern args} {
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
        # We do a catch in case this Tcl version does not support objects
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
    # Returns a dictionary with keys 'classes' and 'procs'. See ruff::private::extract
    # for details.
    
    return [extract ${ns}::* {*}$args]
}

proc ruff::private::extract_namespaces {namespaces args} {
    # Extracts metainformation for procs and objects in one or more namespace
    # namespaces - list of namespace to examine
    #
    # Any additional options are passed on to the extract_namespace command.
    #
    # Returns a dictionary with keys 'classes' and 'procs'. See ruff::private::extract
    # for details.
    
    set procs [dict create]
    set classes [dict create]
    foreach ns $namespaces {
        set nscontent [extract ${ns}::* {*}$args]
        set procs   [dict merge $procs [dict get $nscontent procs]]
        set classes [dict merge $classes [dict get $nscontent classes]]
    }
    return [dict create procs $procs classes $classes]
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


proc ruff::private::load_all_formatters {} {
    # Loads all available formatter implementations
    foreach formatter [formatters] {
        load_formatter $formatter
    }
}

proc ruff::private::load_formatter {formatter {force false}} {
    # Loads the specified formatter implementation
    variable ruff_dir
    set fmt_cmd [namespace parent]::formatter::${formatter}::generate_document
    if {[info commands $fmt_cmd] eq "" || $force} {
        uplevel #0 [list source [file join $ruff_dir ${formatter}_formatter.tcl]]
    }
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
    # -append BOOLEAN - if true, the generated document is appended
    #  to the specified file instead of overwriting it.
    # -title STRING - specifies the title to use for the page
    # -recurse BOOLEAN - if true, child namespaces are recursively
    #  documented.
    # -singlepage BOOLEAN - if `true` (default) files are written
    #  as a single page. Else each namespace is written to a separate file.
    #
    # Any additional arguments are passed through to the document command.
    #
    # Returns the documentation string if the -output option is not
    # specified, otherwise returns an empty string after writing the
    # documentation to the specified file.

    array set opts {
        -append false
        -hidesourcecomments false
        -includeclasses true
        -includeprivate false
        -includeprocs true
        -includesource false
        -output ""
        -preamble ""
        -recurse false
        -singlepage true
        -title ""
    }

    array set opts $args
    namespace upvar private ProgramOptions ProgramOptions
    set ProgramOptions(-hidesourcecomments) $opts(-hidesourcecomments)
    set ProgramOptions(-singlepage) $opts(-singlepage)

    array unset private::ns_file_base_cache
    if {$opts(-output) eq ""} {
        if {! $opts(-singlepage)} {
            # Need to link across files so output must be specified.
            error "Output file must be specified with -output if -singlepage is false."
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

    set preamble [dict create]
    if {$opts(-preamble) ne ""} {
        dict lappend preamble "" {*}[extract_docstring $opts(-preamble)]
    }
    foreach ns $namespaces {
        if {[info exists ${ns}::_ruffdoc]} {
            dict lappend preamble $ns {*}[extract_docstring [set ${ns}::_ruffdoc]]
        }
    }

    set classprocinfodict [extract_namespaces $namespaces \
                               -includeclasses $opts(-includeclasses) \
                               -includeprocs $opts(-includeprocs) \
                               -includeprivate $opts(-includeprivate)]

    load_formatter $formatter
    set docs [formatter::${formatter}::generate_document \
                  $classprocinfodict \
                  {*}$args \
                  -preamble $preamble \
                  -modulename $opts(-title)]

    if {$opts(-output) eq ""} {
        return $docs
    }

    set dir [file dirname $opts(-output)]
    file mkdir $dir
    foreach {ns doc} $docs {
        set fn [private::ns_file_base $ns]
        set fd [open [file join $dir $fn] w]
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
    namespace upvar private ruff_dir ruff_dir
    set formatters {}
    set suffix "_formatter.tcl"
    foreach file [glob [file join $ruff_dir *$suffix]] {
        lappend formatters [string range [file tail $file] 0 end-[string length $suffix]]
    } 
    return $formatters
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

proc ruff::private::document_self {formatter output_dir args} {
    # Generates documentation for Ruff!
    # formatter - the formatter to use
    # output_dir - the output directory where files will be stored. Note
    #  files in this directory with the same name as the output files
    #  will be overwritten!
    # -formatterpath PATH - path to the formatter. If unspecified, the
    #  the input files for the formatter are generated but the formatter
    #  is not run. This option is ignore for the built-in HTML formatter.
    # -includesource BOOLEAN - if true, include source code in documentation.

    variable names

    array set opts {
        -formatterpath ""
        -includesource false
        -singlepage true
        -includeprivate false
    }
    array set opts $args

    load_all_formatters;       # So all will be documented!

    file mkdir $output_dir
    set title "Ruff! - Runtime Formatting Function Reference (V$::ruff::version)"
    set common_args [list \
                         -recurse $opts(-includeprivate) \
                         -titledesc $title \
                         -singlepage $opts(-singlepage) \
                         -version $::ruff::version]

    switch -exact -- $formatter {
        doctools {
            document doctools [list ::ruff] {*}$common_args \
                -output [file join $output_dir ruff.man] \
                -hidenamespace ::ruff \
                -keywords [list "documentation generation"] \
                -modulename ::ruff
        }
        markdown -
        html {
            if {$formatter eq "html"} {
                set ext .html
            } else {
                set ext .md
            }
            document $formatter [list ::ruff] {*}$common_args \
                -output [file join $output_dir ruff$ext] \
                -titledesc $title \
                -copyright "[clock format [clock seconds] -format %Y] Ashok P. Nadkarni" \
                -includesource $opts(-includesource)
        }
        default {
            # The formatter may exist but we do not support it for
            # out documentation.
            error "Formatter '$formatter' not implemented for generating Ruff! documentation."
        }
    }
    return
}


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
