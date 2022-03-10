# Plug-ins for processing diagrams

namespace eval ruff::diagram {
    namespace path [list [namespace parent] [namespace parent]::private]

    namespace eval generators {
        namespace path [namespace eval [namespace parent] {namespace path}]
    }

}

proc ruff::diagram::generate {text generator {input_format ditaa} args} {
    set commands [info commands generators::$generator]
    if {[llength $commands] == 1} {
        return [[lindex $commands 0] $text $input_format {*}$args]
    }
    error "Unknown diagram generator \"$generator\"."
}

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

proc ruff::diagram::generators::kroki {text input_format args} {
    variable kroki_image_counter
    kroki_init
    set url "assets/kroki[incr kroki_image_counter].svg"
    set fd [open [file join [program_option -outdir] $url] wb]
    try {
        kroki_generate $text $input_format $fd
    } finally {
        close $fd
    }
    return $url
}
