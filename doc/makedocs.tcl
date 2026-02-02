set dir [file normalize [file dirname [info script]]]

source [file join $dir .. src ruff.tcl]
source [file join $dir sample.tcl]

set formats $::argv
if {[llength $formats] == 0} {
    set formats [ruff::formatters]
}

foreach fmt $formats {
    set outdir [file join $dir out $fmt]
    file mkdir [file join $outdir assets]
    file copy -force \
        [file join .. src assets ruff-logo.png] \
        [file join $outdir assets ruff-logo.png]

    ruff::private::main \
        --format $fmt \
        --compact \
        --copyright "[clock format [clock seconds] -format %Y] Ashok P. Nadkarni" \
        --directory $outdir \
        --html-navigation=sticky \
        --locale en \
        --only-exports \
        --preamble @[file join $dir preamble.ruff] \
        --product Ruff! \
        --punctuate \
        --split namespace \
        -v [ruff::version] \
        --with-source \
        ::ruff ::ruff::app ::ruff::sample
}

