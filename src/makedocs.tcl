source [file join [file dirname [file dirname [file normalize [info script]]]] src ruff.tcl]

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
                        -makeindex true \
                        -includeprivate false \
                        -compact 1 \
                        -locale en \
                        -autopunctuate true \
                        -navigation {left sticky}
                       ]
    array set opts $args
    if {![info exists opts(-outdir)]} {
        set opts(-outdir) [file join [file dirname [ruff_dir]] doc $opts(-format)]
    }

    if {![namespace exists ::ruff::sample]} {
        uplevel #0 [list source [file join [file dirname [ruff_dir]] doc sample.tcl]]
    }

    load_formatters

    file mkdir [file join $opts(-outdir) assets]
    file copy -force [file join [ruff_dir] assets ruff-logo.png] [file join $opts(-outdir) assets ruff-logo.png]

    set namespaces [list ::ruff ::ruff::app ::ruff::sample]
    set common_args [list \
                         -outdir $opts(-outdir) \
                         -compact $opts(-compact) \
                         -format $opts(-format) \
                         -recurse $opts(-includeprivate) \
                         -makeindex $opts(-makeindex) \
                         -pagesplit $opts(-pagesplit) \
                         -preamble $::ruff::_ruff_intro \
                         -autopunctuate $opts(-autopunctuate) \
                         -locale $opts(-locale) \
                         -product "Ruff!" \
                         -version $::ruff::version]
    if {$opts(-includeprivate)} {
        lappend common_args -recurse 1 -includeprivate 1
    } else {
        lappend common_args -onlyexports 1
    }
    switch -exact -- $opts(-format) {
        sphinx - rst - markdown {
            document $namespaces {*}$common_args \
                -outdir $opts(-outdir) \
                -copyright "[clock format [clock seconds] -format %Y] Ashok P. Nadkarni" \
                -includesource $opts(-includesource)
        }
        html {
            if {[info exists opts(-navigation)]} {
                if {"fixed" in $opts(-navigation)} {
                    app::log_error "Warning: \"fixed\" navigation pane option no longer supported. Falling back to \"sticky\"."
                    set opts(-navigation) sticky
                }
                lappend common_args -navigation $opts(-navigation)
            }
            document $namespaces {*}$common_args \
                -outdir $opts(-outdir) \
                -copyright "[clock format [clock seconds] -format %Y] Ashok P. Nadkarni" \
                -includesource $opts(-includesource)
        }
        nroff {
            document $namespaces {*}$common_args \
                -outdir $opts(-outdir) \
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


if {[catch {
    ruff::private::document_self -format html {*}$argv
    #ruff::private::document_self -format nroff {*}$argv
    #ruff::private::document_self -format markdown {*}$argv
    #ruff::private::document_self -format rst {*}$argv
    ruff::private::document_self -format sphinx {*}$argv
} result edict]} {
    puts stderr "Error: $result"
    puts [dict get $edict -errorinfo]
} else {
    if {$result ne ""} {
        puts stdout $result
    }
}

