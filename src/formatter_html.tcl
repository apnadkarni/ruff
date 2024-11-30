# Copyright (c) 2019-2022, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the source root directory for license.

namespace eval ruff::formatter {}

oo::class create ruff::formatter::Html {
    superclass ::ruff::formatter::Formatter

    # Data members
    variable Document;        # Current document
    variable DocumentNamespace; # Namespace being documented
    variable Header;          # Common header
    variable Footer;          # Common footer
    variable NavigationLinks; # Navigation links forming ToC
    variable HeaderLevels;    # Header levels for various headers
    variable CssClasses;      # CSS classes for various elements
    variable GlobalIndex;     # Like NavigationLinks but across *all* documents

    constructor args {
        set HeaderLevels {
            class 3
            proc 3
            method 4
            nonav 5
            parameters 5
        }
        set CssClasses {
            class ruffclass
            proc  ruffproc
            method ruffmethod
        }
        set GlobalIndex [dict create]
        next {*}$args
    }

    method NewSourceId {} {
        # Returns a new id to use for a source listing.
        variable SourceIdCounter
        if {![info exists SourceIdCounter]} {
            set SourceIdCounter 0
        }
        return [incr SourceIdCounter]
    }

    method Anchor args {
        # Construct an anchor from the passed arguments.
        #  args - String from which the anchor is to be constructed.
        # The anchor is formed by joining the passed strings with separators.
        # Empty arguments are ignored.
        # Returns an HTML-escaped anchor without the `#` prefix.
        set parts [lmap arg $args {
            if {$arg eq ""} continue
            my Escape $arg
        }]
        return [join $parts -]
    }

    method HeadingReference {ns heading} {
        # Implements the [Formatter.HeadingReference] method for HTML.
        return "[ns_file_base $ns]#[my Anchor $ns $heading]"
    }

    method FigureReference {ns caption} {
        # Returns a link name to use for a figure
        return "[ns_file_base $ns]#[my Anchor $ns $caption]"
    }


    method SymbolReference {ns symbol} {
        # Implements the [Formatter.SymbolReference] method for HTML.
        set ref [ns_file_base $ns]
        # Reference to the global namespace is to the file itself.
        if {$ns eq "::" && $symbol eq ""} {
            return $ref
        }
        return [append ref "#[my Anchor $symbol]"]
    }

    method Begin {} {
        # Implements the [Formatter.Begin] method for HTML.

        next

        # Generate the header used by all files
        # set Header {<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN">}
        set Header "<!DOCTYPE html>"
        append Header "<html><head><meta charset=\"utf-8\"/>\n"
        # append Header "<link rel='stylesheet' href='https://fonts.googleapis.com/css?family=Open+Sans|Noto+Serif|Droid+Sans+Mono'>"
        set titledesc [my Option -title]
        append Header "<title>$titledesc</title>\n"

        if {[my Option -linkassets 1]} {
            append Header [my LinkAsset ruff-min.css ruff.css]
            append Header [my LinkAsset ruff-min.js ruff.js]
        } else {
            append Header [my GetAsset ruff-min.css ruff.css]
            append Header [my GetAsset ruff-min.js ruff.js]
        }

        append Header "</head>\n"

        # If we are not splitting pages, h1 headings are shown in navigation alongside
        # h2.. headers so the latter need to be offset further.
        if {[my Option -pagesplit none] eq "none"} {
            append Header "<body style='--ruff-nav-toc-offset: 1em;'>\n"
        } else {
            append Header "<body>\n"; # Take default of 0 defined in ruff css
        }
        append Header "<div class='ruff-layout'>\n"

        append Header "<header class='ruff-layout-header ruff-hd'>\n"
        if {$titledesc ne ""} {
            if {[my Option? -version version]} {
                append Header "<a style='text-decoration:none;' href='[my SymbolReference :: {}]'>$titledesc (v$version)</a>\n\n"
            } else {
                append Header "<a style='text-decoration:none;' href='[my SymbolReference :: {}]'>$titledesc</a>\n\n"
            }
        }
        # Theme control button
        append Header {
            <div id="ruffButtonBar">
            <button id="ruffNavMove" onclick="ruffMoveNavPane()"></button>
            <button id="ruffToggleTheme" onclick="ruffNextTheme()"></button>
            </div>
        }
        append Header </header>

        # Generate the Footer used by all files
        append Footer "<footer class='ruff-layout-footer ruff-ft'>"
        append Footer "<div style='float: right;'>Document generated by <a href='https://ruff.magicsplat.com'>Ruff!</a></div>"
        if {[my Option? -copyright copyright]} {
            append Footer "<div>&copy; [my Escape $copyright]</div>"
        }
        append Footer "</footer>\n"

        append Footer "</div></body></html>"

        return
    }

    method DocumentBegin {ns} {
        # See [Formatter.DocumentBegin].
        # ns - Namespace for this document.

        next $ns

        set    NavigationLinks [dict create]
        set    Document $Header
        append Document "<main class='ruff-layout-main ruff-bd'>"
        set    DocumentNamespace $ns

        return
    }

    method DocumentEnd {} {
        # See [Formatter.DocumentEnd].

        # Close off <div class='yui-b'><div id=yui-main> from DocumentBegin
        #append Document "</div></div>"

        append Document "</main>"

        # Add the navigation bits and footer
        my Navigation $DocumentNamespace
        append Document $Footer

        next

        set doc $Document
        set Document ""
        return $doc
    }

    method DocumentIndex {} {
        # See [Formatter.DocumentIndex]
        #   references - namespace keyed nested dictionary
        #
        my DocumentBegin Index

        set entries {}
        dict for {key link} $GlobalIndex {
            lappend entries [dict get $link label] $link
        }
        set entries [lsort -stride 2 -dictionary $entries]

        append Document "<h1 class='ruff'>Index</h1><p>"
        append Document "<div class='ruff_index'>\n"
        append Document {<input style='width:100%;' accesskey='s' type='text' id='filterText' onkeyup='myFilterHook()' placeholder='Enter index term'>}
        append Document {
            <div id='indexStatus'>
            <ul>
            <li>Type the index terms you want to search for in the text input field.
            <li>Matching terms will be shown incrementally as you type.
            <li>Press <kbd>Enter</kbd> to navigate to the target of the first displayed
            index entry.
            <li>Alternatively, <kbd>Tab</kbd> to move to the index entry of interest and then press
            <kbd>Enter</kbd> to navigate to that documentation page.
            <li>To jump to this page from any other documentation page,
            press browser-specific shortcut modifiers with <kbd>i</kbd>.
            For example, on IE and Edge this would be
            <kbd>Alt-i</kbd> while on Firefox and Chrome <kbd>Alt-Shift-i</kbd>.
            Other browsers and platforms may differ.
            </ul>
            </div>
        }
        append Document "\n<ul id='indexUL'>\n"

        foreach {label link} $entries {
            set label [my Escape [string trimleft $label :]]
            # set tag  [dict get $link tag]
            set tag li
            set href [dict get $link href]
            set ns ""
            if {[dict exists $link ns]} {
                set ns [dict get $link ns]
                if {$ns ne ""} {
                    set ns " [my Escape $ns]"
                }
            }
            if {[dict exists $link tip]} {
                append Document "<$tag class='ruff-tip'><a href='$href'>$label</a><span class='ruff-tiptext'>[dict get $link tip]</span>$ns</$tag>"
            } else {
                append Document "<$tag><a href='$href'>$label</a>$ns</$tag>"
            }
        }
        append Document "\n</ul>\n"
        append Document "</div>"
        append Document [my GetAsset ruff-index-min.js ruff-index.js]
        append Document "<script>\nmyIndexInit();</script>\n"

        return [my DocumentEnd]
    }

    method AddProcedureDetail {procinfo} {
        # Adds the detailed information about a procedure or method
        #  procinfo - dictionary describing the procedure. See [AddProcedure]
        #
        #  The concrete implementation can override this.

        if {[my Option -compact 0]} {
            append Document "<details><summary class='ruff-expand'><span>Details</span></summary>\n"
        }
        next $procinfo
        if {[my Option -compact 0]} {
            append Document "</details>\n"
        }
    }

    method AddProgramElementHeading {type fqn {tooltip {}} {synopsis {}}} {
        # Adds heading for a program element like procedure, class or method.
        #  type - One of `proc`, `class` or `method`
        #  fqn - Fully qualified name of element.
        #  tooltip - The tooltip lines, if any, to be displayed in navigation pane.
        #  synopsis - The synopsis to be displayed along with tooltip. Alternating
        #     list of command name and argument list.
        # In addition to adding the heading to the document, a link
        # is also added to the collection of navigation links.

        set level    [dict get $HeaderLevels $type]
        set ns       [namespace qualifiers $fqn]
        set anchor   [my Anchor $fqn]
        set href     [my SymbolReference $ns $fqn]
        set linkinfo [dict create level $level href $href ns $ns]

        # Construct tooltip from synopsis and tooltip
        if {[llength $synopsis]} {
            set tip "<pre>[join [my SynopsisToHtml $synopsis] \n]</pre>"
        }
        if {[llength $tooltip]} {
            append tip "[my ToHtml [string trim [join $tooltip { }]] $ns]\n"
        }
        if {[info exists tip]} {
            dict set linkinfo tip $tip
        }

        set name [namespace tail $fqn]
        dict set linkinfo label $name
        dict set NavigationLinks $anchor [dict create LinkInfo $linkinfo Type $type]
        dict set GlobalIndex $anchor $linkinfo
        if {[string length $ns]} {
            set ns_link [my ToHtml [markup_reference $ns]]
            set heading "<a name='$anchor'>[my Escape $name]</a><span class='ns_scope'> \[${ns_link}\]</span>"
        } else {
            set heading "<a name='$anchor'>[my Escape $fqn]</a>"
        }
        append Document [my HeadingWithUplink $level $heading $ns [dict get $CssClasses $type]]
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
            set anchor [my Anchor $scope $text]
            set linkinfo [dict create level $level href "#$anchor"]
            if {$tooltip ne ""} {
                set tip "[my ToHtml [string trim [join $tooltip { }]] $scope]\n"
                dict set linkinfo tip $tip
            }
            dict set linkinfo label $text

            # NOTE: <a></a> empty because the text itself may contain anchors.
            set heading "<a name='$anchor'></a>[my ToHtml $text $scope]"

            # Namespace headers do not get a navigation link if page splitting
            # because they are already highlighted in the namespaces section in
            # navigation. Hack - this assumes level 1 heading is not used within
            # the content.
            if {$level > 1 || [my Option -pagesplit none] eq "none"} {

                dict set NavigationLinks $anchor [dict create LinkInfo $linkinfo Type heading]
            }
        } else {
            set heading [my ToHtml $text $scope]
        }
        append Document [my HeadingWithUplink $level $heading $scope]
        return
    }

    method AddParagraph {lines scope} {
        # See [Formatter.AddParagraph].
        #  lines  - The paragraph lines.
        #  scope - The documentation scope of the content.
        append Document "<p class='ruff'>[my ToHtml [string trim [join $lines { }]] $scope]</p>\n"
        return
    }

    method AddDefinitions {definitions scope {preformatted none}} {
        # See [Formatter.AddDefinitions].
        #  definitions  - List of definitions.
        #  scope        - The documentation scope of the content.
        #  preformatted - One of `none`, `both`, `term` or `definition`
        #                 indicating which fields of the definition are
        #                 are already formatted.
        append Document "<table class='ruff_deflist'>\n"
        foreach item $definitions {
            set def [join [dict get $item definition] " "]
            if {[my Option -autopunctuate 0]} {
                set def [string toupper $def 0 0]
                if {[regexp {[[:alnum:]]} [string index $def end]]} {
                    append def "."
                }
            }
            if {$preformatted in {none term}} {
                set def [my ToHtml $def $scope]
            }
            set term [dict get $item term]
            if {$preformatted in {none definition}} {
                set term [my ToHtml $term $scope]
            }
            append Document "<tr><td>" \
                "<nobr>$term</nobr>" \
                "</td><td>" \
                $def \
                "</td></tr>\n"
        }
        append Document "</table>\n"
        return
    }

    method AddBullets {bullets scope} {
        # See [Formatter.AddBullets].
        #  bullets  - The list of bullets.
        #  scope    - The documentation scope of the content.
        append Document "<ul class='ruff'>\n"
        foreach lines $bullets {
            append Document "<li>[my ToHtml [join $lines { }] $scope]</li>\n"
        }
        append Document "</ul>\n"
        return
    }

    method AddPreformattedText {text scope} {
        # See [Formatter.AddPreformattedText].
        #  text  - Preformatted text.
        #  scope - The documentation scope of the content.
        append Document "<pre class='ruff'>\n" \
            [my Escape $text] \
            "\n</pre>\n"
        return
    }

    method AddFenced {lines fence_options scope} {
        # Adds a list of fenced lines to document content.
        #  lines - Preformatted text as a list of lines.
        #  fence_options - options controlling generation and layout
        #  scope - The documentation scope of the content.

        # See if it is a modifier we specialize, else just pass
        # it to default implementation.

        if {[dict exists $fence_options -caption]} {
            set caption [dict get $fence_options -caption]
            set id "id='[my Anchor $scope $caption]'"
            if {[my ResolvableReference? $caption $scope ref] && [dict exists $ref label]} {
                # May have "Figure X" added
                set display_caption [dict get $ref label]
            } else {
                set display_caption $caption
            }
        } else {
            set caption ""
            set display_caption ""
            set id ""
        }

        set fig_classes ruff-figure
        if {[dict exists $fence_options -align]} {
            append fig_classes " ruff-[dict get $fence_options -align]"
        }
        if {[dict exists $fence_options Command] &&
            [lindex [dict get $fence_options Command] 0] eq "diagram"} {
            set diagrammer [lrange [dict get $fence_options Command] 1 end]
            if {[llength $diagrammer] == 0} {
                set diagrammer [program_option -diagrammer]
            }
            append Document "\n<figure $id class='$fig_classes'>"
            set image_url [ruff::diagram::generate \
                               [join $lines \n] \
                               [ruff::private::sanitize_filename $caption] \
                               {*}$diagrammer]
            append Document "\n<img src='$image_url'></img>"
        } else {
            append Document "\n<figure $id class='ruff-snippet $fig_classes'>"
            append Document [my AddPreformattedText [join $lines \n] $scope]
        }
        if {$display_caption ne ""} {
            append Document "\n<figcaption class='ruff-caption'>$display_caption</figcaption>"
        }
        append Document "\n</figure>"
        return
    }

    method SynopsisToHtml {synopsis} {
        # Returns the a list of HTML lines for a synopsis
        #  synopsis - List of alternating elements comprising the command portion
        #             and the parameter list for it.
        set lines [list ]
        foreach {cmds params} $synopsis {
            set cmds   "<span class='ruff_cmd'>[my Escape [join $cmds { }]]</span>"
            if {[llength $params]} {
                set params "<span class='ruff_arg'>[my Escape [join $params { }]]</span>"
            } else {
                set params ""
            }
            lappend lines "$cmds $params"
        }
        return $lines
    }

    method AddSynopsis {synopsis scope} {
        # Adds a Synopsis section to the document content.
        #  synopsis - List of alternating elements comprising the command portion
        #             and the parameter list for it.
        #  scope  - The documentation scope of the content.

        set lines [my SynopsisToHtml $synopsis]
        append Document "<div class='ruff_synopsis'>[join $lines <br>]</div>\n"
        return
    }

    method AddSource {source scope procname} {
        # Adds a Source code section to the document content.
        #  source - Source code fragment.
        #  scope  - The documentation scope of the content.
        #  procname - proc name used to generate stable id - see bug #78

        # See bug #78 set src_id [my NewSourceId]
        set src_id [string map {:: _} $procname]
        set src_id [string map {: _ \" _ < _ > _ # _ $ _ ? _ ! _ . _ ( _ ) _} $src_id]
        set src_id [string trimleft $src_id _]
        if {$src_id eq {}} {
            set src_id [my NewSourceId]
        }
        append Document "<div class='ruff_source'>"
        append Document "<p class='ruff_source_link'>"
        append Document "<a id='l_$src_id' href=\"javascript:toggleSource('$src_id')\">Show source</a>"
        append Document "</p>\n"
        append Document "<div id='$src_id' class='ruff_dyn_src'><pre>[my Escape $source]</pre></div>\n"
        append Document "</div>";    # class='ruff_source'

        return
    }

    method Navigation {{highlight_ns {}}} {
        # Adds the navigation box to the document.
        #  highlight_ns - Namespace to be highlighted in navigation.

        set main_title "Start page"
        set main_ref [ns_file_base {}]
        set index_ref [ns_file_base -docindex]

        set scrolling ""
        foreach opt [my Option -navigation {}] {
            switch -exact -- $opt {
                scrolled { set scrolling "" }
                fixed -
                sticky { set scrolling "style='position: sticky; top: 0;'" }
            }
        }

        append Document "<nav class='ruff-nav'><ul $scrolling>"
        if {[my Option -pagesplit none] ne "none"} {
            # Split pages. Add navigation to each page.
            # If highlight_ns is empty, assume main page. Hack hack hack
            if {$highlight_ns eq ""} {
                append Document "<li class='ruff-toc1'><a class='ruff-highlight' style='padding-top:2px;' href='$main_ref'>$main_title</a></li>\n"
            } else {
                append Document "<li class='ruff-toc1'><a style='padding-top:2px;' href='$main_ref'>$main_title</a></li>\n"
            }
            if {[my Option -makeindex 1]} {
                # Another hack hack - Index page namespaced as Index
                if {$highlight_ns eq "Index"} {
                    append Document "<li class='ruff-toc1'><a class='ruff-highlight' href='$index_ref'>Index</a></li>\n"
                } else {
                    append Document "<li class='ruff-toc1'><a href='$index_ref' accesskey='i'>Index</a></li>\n"
                }
            }
            append Document "<hr>\n"
            if {[my Option -sortnamespaces true]} {
                set ordered_namespaces [my SortedNamespaces]
            } else {
                set ordered_namespaces [my Namespaces]
            }
            foreach ns $ordered_namespaces {
                set ref  [ns_file_base $ns]
                set text [string trimleft $ns :]
                if {$ns eq $highlight_ns} {
                    append Document "<li class='ruff-toc1'><a class='ruff-highlight' href='$ref'>$text</a></li>\n"
                } else {
                    append Document "<li class='ruff-toc1'><a href='$ref'>$text</a></li>\n"
                }
            }
            append Document <hr>
        }

        # Add on the per-namespace navigation links
        if {[dict size $NavigationLinks]} {
            set last_lead_word ""
            dict for {text navinfo} $NavigationLinks {
                set link [dict get $navinfo LinkInfo]
                set label [my Escape [string trimleft [dict get $link label] :]]
                set level  [dict get $link level]
                set href [dict get $link href]
                if {[dict get $navinfo Type] eq "proc"} {
                    catch {
                        set remain [lassign $label lead_word]
                        if {[llength $remain] > 0} {
                            if {$lead_word eq $last_lead_word} {
                                set label "<span style='visibility:hidden'>&nbsp;&nbsp;&nbsp;</span> [join $remain { }]"
                            }
                        }
                        set last_lead_word $lead_word
                    }
                }
                if {[dict exists $link tip]} {
                    append Document "<li class='ruff-toc$level ruff-tip'><a href='$href'>$label</a><span class='ruff-tiptext'>[dict get $link tip]</span></li>"
                } else {
                    append Document "<li class='ruff-toc$level'><a href='$href'>$label</a></li>"
                }
            }
        }
        append Document "</ul></nav>";
        return
    }

    method HeadingWithUplink {level heading scope {cssclass ruff}} {
        # Returns the HTML fragment wrapping the given heading.
        # level - heading level
        # heading - bare HTML fragment to use for heading
        # scope - the namespace scope to be used for uplinks
        #
        # If the heading level is less than 5, links to the namespace
        # and documentation top are inserted into the heading.

        set hlevel "h$level"
        if {$level >= 5} {
            # Plain header
            return "<$hlevel class='$cssclass'>$heading</$hlevel>"
        }

        # If the scope is the document top scope, no need to add uplink since
        # the "Top" link is essentially the same.
        if {$scope ne "" && $scope ne $DocumentNamespace && [my Reference? $scope scope_ref]} {
            set links "<a href='[dict get $scope_ref ref]'>[namespace tail $scope]</a>, "
        }
        if {[my Option -pagesplit none] eq "none"} {
            append links "<a href='#top'>Top</a>"
        } else {
            append links \
                "<a href='#top'>Top</a>, " \
                "<a href='[my SymbolReference :: {}]'>Main</a>"
            if {[my Option -makeindex true]} {
                append links ", <a href='[my SymbolReference -docindex {}]'>Index</a>"
            }
        }
        set links "<span class='ruff-uplink'>$links</span>"
        # NOTE: the div needed to reset the float from links
        return "<$hlevel class='$cssclass'>$heading$links</$hlevel>\n<div style='clear:both;'></div>\n"
    }

    method Escape {s} {
        # Returns an HTML-escaped string.
        #  s - string to be escaped
        # Protects characters in $s against interpretation as
        # HTML special characters.
        #
        # Returns the escaped string

        return [string map {
            &    &amp;
            \"   &quot;
            <    &lt;
            >    &gt;
        } $s]
    }

    method LinkAsset {asset args} {
        # Returns HTML to be included to link to an asset
        #   asset - the name of asset to be included
        #   args - files to check for ensuring $asset is up to date
        #
        set path [file join [ruff_dir] assets $asset]
        foreach arg $args {
            set arg [file join [ruff_dir] assets $arg]
            if {[file exists $arg] && [file mtime $arg] > [file mtime $path]} {
                error "Asset $arg is newer than $path. Regenerate $path."
            }
        }
        if {[file extension $asset] eq ".css"} {
            return "<link rel='stylesheet' type='text/css' href='assets/$asset' />\n"
        } else {
            return "<script type='text/javascript' src='assets/$asset'></script>\n"
        }
    }

    method GetAsset {asset args} {
        # Returns HTML to be included for an asset
        #   asset - the name of asset to be included
        #   args - files to check for ensuring $asset is up to date
        #
        set path [file join [ruff_dir] assets $asset]
        foreach arg $args {
            set arg [file join [ruff_dir] assets $arg]
            if {[file exists $arg] && [file mtime $arg] > [file mtime $path]} {
                error "Asset $arg is newer than $path. Regenerate $path."
            }
        }

        if {[file extension $asset] eq ".css"} {
            return "<style>[read_asset_file $asset utf-8]</style>\n"
        } else {
            return "<script>[read_asset_file $asset utf-8]</script>\n"
        }
    }

    method copy_assets {outdir} {
        # Copies any CSS and Javascript assets to the output directory.
        #   outdir - root directory where output files will be stored
        #

        file mkdir [file join $outdir assets]
        foreach fn {ruff-min.css ruff-min.js ruff-index-min.js} {
            file copy -force [file join [ruff_dir] assets $fn] [file join $outdir assets $fn]
        }
    }

    method extension {} {
        # Returns the default file extension to be used for output files.
        return html
    }

    forward FormatInline my ToHtml
}
