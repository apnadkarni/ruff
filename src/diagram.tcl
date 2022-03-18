# Plug-ins for processing diagrams

namespace eval ruff::diagram {
    namespace path [list [namespace parent] [namespace parent]::private]

    namespace eval generators {
        namespace path [namespace eval [namespace parent] {namespace path}]
    }

}

proc ruff::diagram::OBSOLETEparse_command {command} {
    # Parses a diagram command
    #  command - the diagram command line
    #
    # The first word of the command line is expected to be
    # the word "diagram". Following is a list of option value pairs that begin
    # character `-` followed by the diagrammer command.
    #
    # If the diagrammer command is not present, a default is supplied.
    #
    # Returns a pair consisting of a (possibly empty) option dictionary and the
    # diagrammer command.

    set command [lassign $command first]
    if {$first ne "diagram"} {
        error "Internal error: command is not a diagram."
    }
    if {[llength $command] == 0} {
        return [list [dict create] [program_option -diagrammer]]
    }

    set n [llength $command]
    set options [dict create]
    for {set i 0} {$i < $n} {incr i} {
        set option [lindex $command $i]
        if {[string index $option 0] ne "-"} {
            # End of options
            break
        }
        if {[incr i] == $n} {
            error "Missing value to go with option \"[lindex $command $i]\" in diagram."
        }
        dict set options $option [lindex $command $i]
    }
    if {$i == $n} {
        set diagrammer [program_option -diagrammer]
    } else {
        set diagrammer [lrange $command $i end]
    }
    return [list $options $diagrammer]
}

proc ruff::diagram::generate {text filename generator args} {
    variable diagram_counter

    if {$filename eq ""} {
        set filename diagram[incr diagram_counter]
    }
    set url "assets/$filename.svg"
    set fd [open [file join [program_option -outdir] $url] wb]
    try {
        set commands [info commands generators::$generator]
        if {[llength $commands] == 1} {
            [lindex $commands 0] $fd $text {*}$args
            return $url
        }
    } finally {
        close $fd
    }
    error "Unknown diagram generator \"$generator\"."
}

###
# kroki diagrammer
proc ruff::diagram::generators::kroki_init {} {
    # If a command line kroki exists, we will use it
    if {[llength [auto_execok kroki]]} {
        interp alias {} [namespace current]::kroki_generate {} [namespace current]::kroki_generate_cli
        proc kroki_init {} {}
        return
    }

    # If no command line kroki, need to use HTTP over TLS to the online server
    uplevel #0 package require http

    # For Windows try twapi first

    if {$::tcl_platform(platform) eq "windows" &&
        ![catch { uplevel #0 package require twapi_crypto }]} {
        http::register https 443 twapi::tls_socket
    } else {
        uplevel #0 package require tls
        tls::init -autoservername true
        http::register https 443 tls::socket
    }

    # Not windows or no twapi
    interp alias {} [namespace current]::kroki_generate {} [namespace current]::kroki_generate_http
    proc kroki_init {} {}
    return
}

proc ruff::diagram::generators::kroki_generate_cli {text input_format fd} {
    set kroki_fd [open |[list {*}[auto_execok kroki] convert - -f svg -t $input_format -o -] r+]
    puts $kroki_fd $text
    close $kroki_fd w
    puts $fd [read $kroki_fd]
    close $kroki_fd
}

proc ruff::diagram::generators::kroki_generate_http {text input_format fd} {
    # See https://wiki.tcl-lang.org/page/dia2kroki
    set b64 [string map {+ - / _ = ""}  [binary encode base64 [zlib compress $text]]]
    set uri https://kroki.io/$input_format/svg/$b64
    set tok [http::geturl $uri]
    if {[http::status $tok] ne "ok"} {
        error "Failed to get image from $uri"
    }
    puts $fd [http::data $tok]
    return
}

proc ruff::diagram::generators::kroki {fd text {input_format ditaa} args} {
    variable kroki_image_counter
    kroki_init
    kroki_generate $text $input_format $fd
}

###
# ditaa diagrammer

proc ruff::diagram::generators::ditaa {fd text args} {
    variable ditaa_image_counter

    set image_fd [open |[list {*}[auto_execok ditaa] - - --svg {*}$args] r+]
    puts $image_fd $text
    close $image_fd w
    puts $fd [read $image_fd]
    close $image_fd
}
