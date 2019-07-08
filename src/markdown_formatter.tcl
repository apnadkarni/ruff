# Copyright (c) 2019, Ashok P. Nadkarni
# All rights reserved.
# See the file license.terms.

# Ruff! formatter for Markdown.

# For compiling generated markdown to html using pandoc:
# pandoc -s -o ruff.html -c ../ruff.css --metadata pagetitle="My package" ruff.md

namespace eval ruff::formatter::markdown {
    namespace path [list ::ruff ::ruff::private]

    # navlinks is used to build the navigation links that go on the
    # left side of a page. As such since all links are within the page,
    # only anchors need to be stored without the filename portion.
    # This is cleared for every page generation (in a multifile ouput).
    variable navlinks

    # link_targets maps a program element name to a file url.
    # Unlike navlinks, it is not cleared for every page
    # generation but rather content exists for the duration of a single
    # document generation. Also since the links may be across pages,
    # it includes the filename portion as well.
    variable link_targets

    # The header levels to use for various elements
    variable header_levels
    array set header_levels {
        class  3
        proc   4
        method 4
        nonav  5
    }

    # Css header classes to use for class and proc headers
    variable header_css
    array set header_css {
        class ruffclass
        proc  ruffproc
        method ruffmethod
    }
}

# Credits: tcllib/Caius markdown module
proc ::ruff::formatter::markdown::md_inline {text {scope {}}} {
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
    set re_reflink     {\A\!?\[((?:[^\]]|\[[^\]]*?\])+)\](?:\s*\[((?:[^\]]|\[[^\]]*?\])*)\])?}
    set re_htmltag     {\A</?\w+\s*>|\A<\w+(?:\s+\w+=(?:\"[^\"]+\"|\'[^\']+\'))*\s*/?>}
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
                        append result "$del[md_inline $sub $scope]$del"
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
                        append result $pre [md_inline $txt $scope] "\](" $url " " "\"[md_inline $title $scope]\"" ")"
                        set url [escape [string trim $url {<> }]]
                        set match_found 1
                    }
                } elseif {[regexp -start $index $re_reflink $text m txt lbl]} {
                    if {$lbl eq {}} {
                        set lbl [regsub -all {\s+} $txt { }]
                    }

                    set code_link [resolve_code_link $lbl $scope]
                    if {[llength $code_link]} {
                        # RUFF CODE REFERENCE
                        lassign $code_link url txt
                        set txt [md_inline $txt $scope]
                        if {1} {
                            append result $pre $txt "\](" $url ")"
                        } else {
                            # Note: Do quotes inside $txt (SECOND occurence) need to be escaped?
                            append result $pre $txt "\](" $url " " "\"$txt\"" ")"
                        }
                        set match_found 1
                    } else {
                        # Not a Ruff! code link. Pass through as is.
                        # We do not pass text through md_inline as it is
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

proc ruff::formatter::markdown::escape {s} {
    # s - string to be escaped
    # Protects characters in $s against interpretation as
    # markdown special characters.
    #
    # Returns the escaped string

    # TBD - fix this regexp
    return [regsub -all {[\\`*_\{\}\[\]\(\)#\+\-\.!<>|]} $s {\\\0}]
}

proc ruff::formatter::markdown::symbol_link {sym {scope {}}} {
    return [md_inline [symbol_ref $sym] $scope]
}

proc ::ruff::formatter::markdown::fmtpreformatted {content} {
    return "\n```\n$content\n```\n"
}

proc ::ruff::formatter::markdown::resolve_code_link {link_label scope} {
    # Locates the target of a link.
    # link_label - the potential link to be located, for example the name
    #  of a proc.
    # scope - the namespace path to search to locate a target
    #
    # Returns a list consisting of the url and text label.
    # An empty list is returned if the link_label does not match a code element.
    variable link_targets

    # If the label falls within the specified scope, we will hide the scope
    # in the displayed label. The label may fall within the scope either
    # as a namespace (::) or a class member (.)

    # First check if this link itself is directly present
    if {[info exists link_targets($link_label)]} {
        return [list "$link_targets($link_label)" [trim_namespace $link_label $scope]]
    }

    # Only search scope if not fully qualified
    if {! [string match ::* $link_label]} {
        while {$scope ne ""} {
            # Check class (.) and namespace scope (::)
            foreach sep {. ::} {
                set qualified ${scope}${sep}$link_label
                if {[info exists link_targets($qualified)]} {
                    return [list "$link_targets($qualified)" [trim_namespace $link_label $scope]]
                }
            }
            set scope [namespace qualifiers $scope]
        }
    }

    return [list ]
}

proc ruff::formatter::markdown::anchor args {
    # Given a list of strings, constructs an anchor from them
    # and returns it. Empty arguments are ignored.
    set parts {}
    foreach arg $args {
        if {$arg ne ""} {
            lappend parts $arg
        }
    }

    # _ is a special char in markdown so use - as separator
    return [regsub -all {[^-:\w_.]} [join $parts -] -]
}

proc ruff::formatter::markdown::ns_link {ns name} {
    # Return a link for the specified name within the namespace

    # Output file has a markdown extension. Link
    # needs an html extension.
    set fn [ns_file_base $ns .html]
    if {$ns eq "::" || $name eq ""} {
        return $fn
    } else {
        return "$fn#[anchor $name]"
    }
}

proc ruff::formatter::markdown::fmtdeflist {listitems args} {

    # -preformatted is one of both, none, itemname or itemdef
    array set opts {
        -preformatted itemname
        -scope {}
        -headings {}
    }
    array set opts $args

    # TBD - for now use html tables. Later change as per
    # markdown dialect

    # Note: CommonMark does not recognize tables without a heading line
    if {1} {
        set doc "\n<table><tbody>\n"
        foreach {name desc} $listitems {
            if {$opts(-preformatted) in {none itemname}} {
                set desc [md_inline $desc $opts(-scope)]
            }
            if {$opts(-preformatted) in {none itemdef}} {
                set name [md_inline $name $opts(-scope)]
            }
            append doc "<tr><td>$name</td><td>$desc</td></tr>\n"
        }
        append doc "</tbody></table>\n"
    } else {
        set doc "\n|[lindex $opts(-headings) 0]|[lindex $opts(-headings) 1]|\n"
        append doc "|----|----|\n"
        foreach {name desc} $listitems {
            if {$opts(-preformatted) in {none itemname}} {
                set desc [md_inline $desc $opts(-scope)]
            }
            if {$opts(-preformatted) in {none itemdef}} {
                set name [md_inline $name $opts(-scope)]
            }
            append doc "|$name|$desc|\n"
        }
        append doc "\n"
    }

    return $doc
}

proc ruff::formatter::markdown::fmtparamlist {listitems args} {
    return [fmtdeflist $listitems {*}$args -headings {Parameter Description}]
}

proc ruff::formatter::markdown::fmtbulletlist {listitems {scope {}}} {
    append doc \n
    foreach item $listitems {
        append doc "- [md_inline $item $scope]\n"
    }
    append doc "\n"
    return $doc
}


proc ruff::formatter::markdown::fmtprochead {name args} {
    # Procedure for formatting proc, class and method headings
    variable navlinks
    variable link_targets

    set opts(-level) 3
    array set opts $args

    set atx [string repeat # $opts(-level)]

    set ns [namespace qualifiers $name]
    set anchor [anchor $name]
    set linkinfo [dict create tag h$opts(-level) href "#$anchor"]
    if {[info exists opts(-tooltip)]} {
        dict set linkinfo tip [escape $opts(-tooltip)]
    }
    dict set linkinfo label [namespace tail $name]
    dict set navlinks $anchor $linkinfo
    set doc "\n$atx <a name='$anchor'></a>"
    if {[string length $ns]} {
        set ns_link [symbol_link $ns]
        append doc "[escape [namespace tail $name]] \[${ns_link}\]\n"
        #append doc [md_inline "[escape [namespace tail $name]]\\\[\[$ns\]\\\]" $ns]
    } else {
        append doc "[escape $name]\n"
    }

    if {0} {
        Commented out because not clear how well this will work
        # Include a link to top of class/namespace if possible.

        if {[info exists link_targets($ns)]} {
            set linkline "<a href='$link_targets($ns)'>[namespace tail $ns]</a>, "
        }
        if {[program_option -singlepage]} {
            append linkline "<a href='#_top'>Top</a>"
        } else {
            append linkline "<a href='[ns_link :: {}]'>Top</a>"
        }
        append doc "\n<p class='linkline'>$linkline</p>"
    }

    return $doc
}

proc ruff::formatter::markdown::fmthead {text level args} {
    variable navlinks

    set opts(-link) [expr {$level > 4 ? false : true}]
    set opts(-scope) "";    # -scope allows context for headings
    array set opts $args

    set atx [string repeat # $level]

    if {$opts(-link)} {
        set anchor [anchor $opts(-scope) $text]
        set linkinfo [dict create tag h$level href "#$anchor"]
        if {[info exists opts(-tooltip)]} {
            dict set linkinfo tip [escape $opts(-tooltip)]
        }
        dict set linkinfo label $text
        dict set navlinks $anchor $linkinfo
        return "\n$atx <a name='$anchor'></a>[md_inline $text $opts(-scope)]\n"
    } else {
        return "\n$atx [md_inline $text $opts(-scope)]\n"
    }
}

proc ruff::formatter::markdown::fmtpara {text {scope {}}} {
    return "\n[md_inline [string trim $text] $scope]\n"
}

proc ruff::formatter::markdown::fmtparas {paras {scope {}}} {
    # Given a list of paragraph elements, returns
    # them appropriately formatted for html output.
    # paras - a flat list of pairs with the first element
    #  in a pair being the type, and the second the content
    #
    set doc ""
    foreach {type content} $paras {
        switch -exact -- $type {
            header {
                lassign $content level text
                append doc [fmthead $text $level -scope $scope]
            }
            paragraph {
                append doc [fmtpara $content $scope]
            }
            deflist {
                append doc [fmtdeflist $content -preformatted none -scope $scope]
            }
            bulletlist {
                append doc [fmtbulletlist $content $scope]
            }
            preformatted {
                append doc [fmtpreformatted $content]
            }
            default {
                error "Unknown paragraph element type '$type'."
            }
        }
    }
    return $doc
}

proc ruff::formatter::markdown::generate_proc_or_method {procinfo args} {
    # Formats the documentation for a proc in Markdown format
    # procinfo - proc or method information in the format returned
    #   by extract_proc or extract_ooclass
    #
    # The following options may be specified:
    #   -includesource BOOLEAN - if true, the source code of the
    #     procedure is also included. Default value is false.
    #   -hidenamespace NAMESPACE - if specified as non-empty,
    #    program element names beginning with NAMESPACE are shown
    #    with that namespace component removed.
    #   -skipsections SECTIONLIST - a list of sections to be left
    #    out from the generated document. This is generally useful
    #    if the return value is to be included as part of a larger
    #    section (e.g. constructor within a class)
    #
    # Returns the proc documentation as a Markdown formatted string.

    variable header_levels
    variable header_css

    array set opts {
        -includesource false
        -hidenamespace ""
        -skipsections {}
    }
    array set opts $args

    array set aproc $procinfo

    if {$aproc(proctype) ne "method"} {
        set scope [namespace qualifiers $aproc(name)]
    } else {
        set scope $aproc(class); # Scope is name of class
    }

    set doc "";                 # Document string

    set header_title [trim_namespace $aproc(name) $opts(-hidenamespace)]
    set proc_name [trim_namespace $aproc(name) $opts(-hidenamespace)]

    # Construct the synopsis and simultaneously the parameter descriptions
    # These are constructed as already formatted since we want
    # to format parameters etc.
    set desclist {};            # For the parameter descriptions
    set arglist {};             # Used later for synopsis
    foreach param $aproc(parameters) {
        set name [dict get $param name]
        set desc {}
        if {[dict get $param type] eq "parameter"} {
            lappend arglist [_arg $name]
            if {[dict exists $param default]} {
                lappend desc "(optional, default [_const [dict get $param default]])"
            }
        }
        if {[dict exists $param description]} {
            lappend desc [md_inline [dict get $param description] $scope]
        } elseif {$name eq "args"} {
            lappend desc "Additional options."
        }
 
        lappend desclist [_arg $name] [join $desc " "]
    }

    if {$aproc(proctype) ne "method"} {
        set synopsis "[_cmd [namespace tail $proc_name]] [join $arglist { }]"
    } else {
        switch -exact -- $aproc(name) {
            constructor {set synopsis "[_cmd $aproc(class)] [_cmd create] [join $arglist { }]"}
            destructor  {set synopsis "[_arg OBJECT] [_cmd destroy]"}
            default  {set synopsis "[_arg OBJECT] [_cmd [namespace tail $aproc(name)]] [join $arglist { }]"}
        }
    }

    if {[info exists aproc(summary)] && $aproc(summary) ne ""} {
        set summary $aproc(summary)
    } elseif {[info exists aproc(return)] && $aproc(return) ne ""} {
        set summary $aproc(return)
    }

    if {[lsearch -exact $opts(-skipsections) header] < 0} {
        # We need a fully qualified name for cross-linking purposes
        if {$aproc(proctype) eq "method"} {
            set fqn $aproc(class)::$aproc(name)
        } else {
            set fqn $aproc(name)
        }

        if {[info exists summary]} {
            append doc [fmtprochead $fqn -tooltip $summary -level $header_levels($aproc(proctype))]
        } else {
            append doc [fmtprochead $fqn -level $header_levels($aproc(proctype))]
        }
    }

    if {[info exists summary]} {
        append doc [fmtpara $summary $scope]
    }

    append doc "\n> $synopsis\n"

    if {[llength $desclist]} {
        append doc [fmthead Parameters $header_levels(nonav)]
        append doc [fmtparamlist $desclist -preformatted both]
    }

    if {[info exists aproc(return)] && $aproc(return) ne ""} {
        append doc [fmthead "Return value" $header_levels(nonav)]
        append doc [fmtpara $aproc(return) $scope]
    }

    # Loop through all the paragraphs. Note the first para is also 
    # the summary (already output) but we will show that in the general
    # description as well.
    if {[llength $aproc(description)]} {
        append doc [fmthead "Description" $header_levels(nonav)]
        append doc [fmtparas $aproc(description) $scope]
    }

    # Do we include the source code in the documentation?
    if {0 && $opts(-includesource)} {
        # TBD - -includesource not implemented for markdown
        set src_id [_new_srcid]
        if {[info exists aproc(ensemble)]} {
            set note "<em style='font-size:small;'># NOTE: showing source of procedure implementing ensemble subcommand.</em>"
        } else {
            set note ""
        }
        append doc "<div class='ruff_source'>"
        append doc "<p class='ruff_source_link'>"
        append doc "<a id='l_$src_id' href=\"javascript:toggleSource('$src_id')\">Show source</a>"
        append doc "</p>\n"
        append doc "<div id='$src_id' class='ruff_dyn_src'>$note\n<pre>\n[escape $aproc(source)]\n</pre></div>\n"
        append doc "</div>";    # class='ruff_source'
    }

    return "${doc}\n"
}

proc ruff::formatter::markdown::generate_ooclass {classinfo args} {

    # Formats the documentation for a class in HTML format
    # classinfo - class information in the format returned
    #   by extract_ooclass
    # -includesource BOOLEAN - if true, the source code of the
    #   procedure is also included. Default value is false.
    # -hidenamespace NAMESPACE - if specified as non-empty,
    #  program element names beginning with NAMESPACE are shown
    #  with that namespace component removed.
    #
    # Returns the class documentation as a HTML formatted string.

    variable header_levels
    variable header_css

    array set opts {
        -includesource false
        -hidenamespace ""
        -mergeconstructor false
    }
    array set opts $args

    array set aclass $classinfo
    set class_name [trim_namespace $aclass(name) $opts(-hidenamespace)]
    set scope [namespace qualifiers $aclass(name)]

    array set method_summaries {}

    # We want to put the class summary right after the header but cannot
    # generate it till the end so we put the header in a separate variable
    # to be merged at the end.
    append dochdr [fmtprochead $aclass(name) -level $header_levels(class)]

    set doc ""
    # Include constructor in main class definition
    if {$opts(-mergeconstructor) && [info exists aclass(constructor)]} {
        error "-mergeconstructor not implemented"
        TBD
        append doc [generate_proc_or_method $aclass(constructor) \
                        -includesource $opts(-includesource) \
                        -hidenamespace $opts(-hidenamespace) \
                        -skipsections [list header name] \
                       ]
    }

    if {[llength $aclass(superclasses)]} {
        append doc [fmthead Superclasses $header_levels(nonav)]
        # NOTE: Don't sort - order matters! 
        set class_links [symbol_refs_string [trim_namespace_multi $aclass(superclasses) $opts(-hidenamespace)]]
        append doc [fmtpara $class_links $scope]
    }
    if {[llength $aclass(mixins)]} {
        append doc [fmthead "Mixins" $header_levels(nonav)]

        # Don't sort - order matters!
        set class_links [symbol_refs_string [trim_namespace_multi $aclass(mixins) $opts(-hidenamespace)]]
        append doc [fmtpara $class_links $scope]
    }

    if {[llength $aclass(subclasses)]} {
        append doc [fmthead "Subclasses" $header_levels(nonav)]
        set class_links [symbol_refs_string [trim_namespace_multi $aclass(subclasses) $opts(-hidenamespace)]]
        append doc [fmtpara $class_links $scope]
    }

    # Inherited and derived methods are listed as such.
    if {[llength $aclass(external_methods)]} {
        array set external_methods {}
        foreach external_method $aclass(external_methods) {
            # Qualify the name with the name of the implenting class
            foreach {name imp_class} $external_method break
            if {$imp_class ne ""} {
                set imp_class [trim_namespace_multi $imp_class $opts(-hidenamespace)]
            }
            lappend external_methods($imp_class) ${imp_class}.$name
            set method_summaries($name) [dict create label [escape $name] desc [md_inline "See [symbol_ref ${imp_class}.$name]" $scope]]
        }
        append doc [fmthead "Inherited and mixed-in methods" $header_levels(nonav)]
        # Construct a sorted list based on inherit/mixin class name
        set ext_list {}
        foreach imp_class [lsort -dictionary [array names external_methods]] {
            set refs [symbol_refs_string $external_methods($imp_class)]
            lappend ext_list \
                [md_inline [symbol_ref $imp_class] $scope] \
                [md_inline $refs $imp_class]
        }
        append doc [fmtparamlist $ext_list -preformatted both]
    }
    if {[llength $aclass(filters)]} {
        append doc [fmthead "Filters" $header_levels(nonav)]
        append doc [fmtpara [join [lsort $aclass(filters)] {, }] $scope]
    }

    if {[info exists aclass(constructor)] && !$opts(-mergeconstructor)} {
        set method_summaries($aclass(name).constructor) \
            [dict create label \
                 [symbol_link $aclass(name).constructor $aclass(name)] \
                 desc \
                 "Constructor for the class" ]
        append doc [generate_proc_or_method $aclass(constructor) \
                        -includesource $opts(-includesource) \
                        -hidenamespace $opts(-hidenamespace) \
                       ]
    }
    if {[info exists aclass(destructor)]} {
        set method_summaries($aclass(name).destructor) [dict create label [symbol_link $aclass(name).destructor $aclass(name)] desc "Destructor for the class" ]
        append doc [generate_proc_or_method $aclass(destructor) \
                        -includesource $opts(-includesource) \
                        -hidenamespace $opts(-hidenamespace) \
                        ]
    }

    # We want methods and forwarded methods listed together and sorted
    array set methods {}
    foreach methodinfo $aclass(methods) {
        set methods([dict get $methodinfo name]) [list method $methodinfo]
    }
    if {[info exists aclass(forwards)]} {
        foreach forwardinfo $aclass(forwards) {
            set methods([dict get $forwardinfo name]) [list forward $forwardinfo]
        }
    }

    foreach name [lsort [array names methods]] {
        foreach {type info} $methods($name) break
        if {$type eq "method"} {
            append doc [generate_proc_or_method $info \
                            -includesource $opts(-includesource) \
                            -hidenamespace $opts(-hidenamespace) \
                           ]
            if {[dict exists $info summary]} {
                set summary [escape [dict get $info summary]]
            } elseif {[dict exists $info return]} {
                set summary [escape [dict get $info return]]
            } else {
                set summary ""
            }
            set method_summaries($aclass(name).$name) \
                [dict create label \
                     [symbol_link $aclass(name).$name $aclass(name)] \
                     desc \
                     $summary]
        } else {
            set forward_text "Method forwarded to [dict get $info forward]"
            append doc [fmtprochead $aclass(name)::$name -tooltip $forward_text -level $header_levels(method)]
            append doc [fmtpara $forward_text $scope]
            set method_summaries($aclass(name).$name) \
                [dict create label \
                     [symbol_link $aclass(name).$name $aclass(name)] \
                     desc \
                     [md_inline $forward_text $scope]]
        }
    }

    set summary_list {}
    foreach name [lsort -dictionary [array names method_summaries]] {
        lappend summary_list [dict get $method_summaries($name) label] [dict get $method_summaries($name) desc]
    }
    if {[llength $summary_list]} {
        # append dochdr [fmthead "Method summary" $header_levels(nonav)]
        append dochdr [fmtdeflist $summary_list -preformatted both -headings {Method Summary}]
    }

    return "$dochdr\n$doc\n"
}

proc ::ruff::formatter::markdown::generate_ooclasses {classinfodict args} {
    # Given a list of class information elements returns as string
    # containing class documentation formatted as Markdown.
    # classinfodict - dictionary keyed by class name and each element
    #   of which is in the format returned by extract_ooclass
    #
    # Additional parameters are passed on to the generate_ooclass procedure.

    set doc ""
    foreach name [lsort [dict keys $classinfodict]] {
        append doc \
            [generate_ooclass [dict get $classinfodict $name] {*}$args]
        append doc "\n\n"
    }

    return $doc
}
    
proc ::ruff::formatter::markdown::generate_procs {procinfodict args} {
    # Given a dictionary of proc information elements returns a string
    # containing markdown format documentation.
    # procinfodict - dictionary keyed by name of the proc with the associated
    #   value being in the format returned by extract_proc
    #
    # Additional parameters are passed on to the generate_proc procedure.
    #
    # Returns documentation string in NaturalDocs format with 
    # procedure descriptions sorted in alphabetical order
    # within each namespace.

    set doc ""
    set namespaces [sift_names [dict keys $procinfodict]]
    foreach ns [lsort -dictionary [dict keys $namespaces]] {
        foreach name [lsort -dictionary [dict get $namespaces $ns]] {
            append doc \
                [generate_proc_or_method [dict get $procinfodict $name] {*}$args]\n\n
        }
    }

    return $doc
}
    

proc ::ruff::formatter::markdown::generate_document {classprocinfodict args} {
    # Produces documentation in Markdown format from the passed in
    # class and proc metainformation.
    #   classprocinfodict - dictionary containing meta information about the 
    #    classes and procs
    # The following options may be specified:
    #   -preamble DICT - a dictionary indexed by a namespace. Each value is
    #    a flat list of pairs consisting of a heading and
    #    corresponding content. These are inserted into the document
    #    before the actual class and command descriptions for a namespace.
    #    The key "::" corresponds to documentation to be printed at
    #    the very beginning.
    #   -includesource BOOLEAN - if true, the source code of the
    #     procedure is also included. Default value is false.
    #   -hidenamespace NAMESPACE - if specified as non-empty,
    #    program element names beginning with NAMESPACE are shown
    #    with that namespace component removed.
    #   -singlepage BOOLEAN - if `true` (default) files are written
    #    as a single page. Else each namespace is written to a separate file.
    #   -titledesc STRING - the title for the documentation.
    #    Used as the title for the document.
    #    If undefined, the string "Reference" is used.
    #   -stylesheet URLLIST - if specified, the stylesheets passed in URLLIST
    #    are used instead of the built-in styles. Note the built-in YUI is always
    #    included.

    variable navlinks;          # Links generated for navigation menu
    variable link_targets;    # Links for cross-reference purposes

    # Re-initialize in case of multiple invocations
    array unset link_targets
    array set link_targets {}
    set navlinks [dict create]

    array set opts \
        [list \
             -includesource false \
             -hidenamespace "" \
             -outdir "." \
             -singlepage true \
             -titledesc "" \
             -modulename "Reference" \
             ]

    array set opts $args

    # First collect all "important" names so as to build a list of
    # linkable targets. These will be used for cross-referencing and
    # also to generate links correctly in the case of
    # duplicate names in different namespaces or classes.
    #
    # A class name is also treated as a namespace component
    # although that is not strictly true.
    foreach {class_name class_info} [dict get $classprocinfodict classes] {
        set ns [namespace qualifiers $class_name]
        set link_targets($class_name) [ns_link $ns $class_name]
        set method_info_list [concat [dict get $class_info methods] [dict get $class_info forwards]]
        foreach name {constructor destructor} {
            if {[dict exists $class_info $name]} {
                lappend method_info_list [dict get $class_info $name]
            }
        }
        foreach method_info $method_info_list {
            # The class name is the scope for methods. Because of how
            # the link target lookup works, we use the namespace
            # operator to separate the class from method. We also
            # store it a second time using the "." separator as that
            # is how they are sometimes referenced.
            set method_name [dict get $method_info name]
            set link_targets(${class_name}::${method_name}) [ns_link $ns ${class_name}::${method_name}]
            set link_targets(${class_name}.${method_name}) $link_targets(${class_name}::${method_name}) 
        }
    }
    foreach proc_name [dict keys [dict get $classprocinfodict procs]] {
        fqn! $proc_name
        set link_targets(${proc_name}) [ns_link [namespace qualifiers $proc_name] $proc_name]
    }

    set header ""
    if {0} {
        TBD - Markdown header for title etc.?
        # Generate the header used by all files
        set header {<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN">}
        append header "<html><head><title>$opts(-titledesc)</title>\n"
        if {[info exists opts(-stylesheets)]} {
            append header "<style>\n$yui_style\n</style>\n"
            foreach url $opts(-stylesheets) {
                append header "<link rel='stylesheet' type='text/css' href='$url' />"
            }
        } else {
            # Use built-in styles
            append header "<style>\n$yui_style\n$ruff_style\n</style>\n"
        }
        append header "<script>$javascript</script>"
        append header "</head>\n<body>"

        # YUI stylesheet templates
        append header "<div id='doc3' class='yui-t2'>"
        if {$opts(-titledesc) ne ""} {
            append header "<div id='hd' class='banner'>\n<a style='text-decoration:none;' href='[ns_link :: {}]'>$opts(-titledesc)</a>\n</div>\n"
        }
        append header "<div id='bd'>"
    
    }

    if {$opts(-modulename) ne ""} {
        append header [fmthead $opts(-modulename) 1 -link 0]
    }

    # Generate the footer used by all files
    set footer ""
    if {1} {
        if {[info exists opts(-copyright)]} {
            append footer "\n\n (c) [escape $opts(-copyright)]"
        }
    } else {
        append footer "</div>";        # <div id='bd'>
        append footer "<div id='ft'>"
        append footer "<div style='float: right;'>Document generated by Ruff!</div>"
        if {[info exists opts(-copyright)]} {
            append footer "<div>&copy; [escape $opts(-copyright)]</div>"
        }
        append footer "</div>\n"
        append footer "</div>";        # <div id='doc3' ...>
        append footer "</body></html>"
    }

    # Arrange procs and classes by namespace
    set info_by_ns [sift_classprocinfo $classprocinfodict]

    # Collect links to namespaces. Need to do this before generating preamble
    foreach ns [dict keys $info_by_ns] {
        set link_targets($ns) [ns_link $ns $ns]
    }

    # Now generate documentation in one of two modes: single page or separate.
    set docs [list ]

    # Generate the main page. Further sections will be either appended to
    # it or generated separately.
    set doc $header

    if {[info exists opts(-preamble)] &&
        [dict exists $opts(-preamble) ""]} {
        # Print the toplevel (global stuff)
        foreach paras [dict get $opts(-preamble) ""] {
            append doc [fmtparas $paras]
        }
    } else {
        # If no preamble was given and we are in multipage mode
        # display a generic message.
        if {!$opts(-singlepage)} {
            append doc [md_inline "Please follow the links below for documentation of individual modules."]
        }
    }

    # If not single page, append links to namespace pages and close page
    if {!$opts(-singlepage)} {
        # Add the navigation bits
        set nav_common ""
        foreach ns [lsort [dict keys $info_by_ns]] {
            set link [ns_link $ns ""]
            append nav_common "\n* \[$ns\]($link)"
        }
        append doc "\n$nav_common\n"
        append doc $footer
        lappend docs "::" $doc
    }

    foreach ns [lsort [dict keys $info_by_ns]] {
        if {!$opts(-singlepage)} {
            set doc $header
        }

        append doc [fmthead $ns 1]
 
        if {[info exists opts(-preamble)] &&
            [dict exists $opts(-preamble) $ns]} {
            # Print the preamble for this namespace
            append doc [fmtparas [dict get $opts(-preamble) $ns] $ns]
        }

        if {[dict exists $info_by_ns $ns procs]} {
            append doc [fmthead "Commands" 2 -scope $ns]
            append doc [generate_procs [dict get $info_by_ns $ns procs] \
                            -includesource $opts(-includesource) \
                            -hidenamespace $opts(-hidenamespace) \
                           ]
        }

        if {[dict exists $info_by_ns $ns classes]} {
            append doc [fmthead "Classes" 2 -scope $ns]
            append doc [generate_ooclasses [dict get $info_by_ns $ns classes] \
                            -includesource $opts(-includesource) \
                            -hidenamespace $opts(-hidenamespace) \
                           ]
        }
        if {! $opts(-singlepage)} {
            # Add the navigation bits for other pages
            append doc "## See also"
            append doc $nav_common
            append doc $footer
            lappend docs $ns $doc

            # Reset navigation links for next page
            set navlinks [dict create]
        }
    }
    if {$opts(-singlepage)} {
        append doc $footer
        lappend docs "::" $doc
    }

    return $docs
}

proc ::ruff::formatter::markdown::_const {text} {
    return "`$text`"
}

proc ::ruff::formatter::markdown::_cmd {text} {
    return "`$text`"
}

proc ::ruff::formatter::markdown::_arg {text} {
    return "*`$text`*"
}

proc ::ruff::formatter::markdown::_new_srcid {} {
    variable src_id_ctr
    if {![info exists src_id_ctr]} {
        set src_id_ctr 0
    }
    return [incr src_id_ctr]
}
