source [file join [file dirname [file dirname [file normalize [info script]]]] src ruff.tcl]

proc ruff::private::distribute {{dir {}}} {

    if {$dir eq ""} {
        set dir [file join [file dirname [ruff_dir]] dist]
    }
    set outname ruff-[version]
    set dir [file join $dir $outname]
    file delete -force $dir;    # Empty it out
    file mkdir $dir
    set files {
        pkgIndex.tcl
        ruff.tcl
        formatter.tcl
        formatter_html.tcl
        formatter_markdown.tcl
        formatter_nroff.tcl
        ../doc/sample.tcl
        ../doc/ruff.html
        ../doc/ruff_ruff.html
        ../doc/ruff_ruff_sample.html
        ../LICENSE
        ../README.md
        ../ruff_logo.png
    }
    file copy -force -- {*}[lmap file $files {file join [ruff_dir] $file}] $dir
    file copy -force -- [file join [ruff_dir] msgs] $dir

    # Copy assets
    # Ensure minimized versions are up to date
    set assets_dir [file join $dir assets]
    file mkdir $assets_dir
    foreach {max min} {
        ruff.css ruff-min.css
        ruff.js ruff-min.js
        ruff-index.js ruff-index-min.js
    } {
        # Minimization: csso -i ruff-html.css -o ruff-html-min.css
        # Minimization: uglifyjs ruff.js -b beautify=false -b ascii_only=true -o ruff-min.js
        set max [file join [ruff_dir] assets $max]
        set min [file join [ruff_dir] assets $min]
        if {[file mtime $max] > [file mtime $min]} {
            app::log_error "File $max is newer than $min. Please regenerate $min."
            exit 1
        }
        file copy -force -- $min $assets_dir
    }
    file copy -force [file join [ruff_dir] assets ruff-md.css] $assets_dir

    # Zip it all
    set zipfile [file join $dir ${outname}.zip]
    file delete -force -- $zipfile
    set curdir [pwd]
    try {
        cd [file join $dir ..]
        exec {*}[auto_execok zip.exe] -r ${outname}.zip $outname
    } finally {
        cd $curdir
    }
}

if {[catch {
    ruff::private::distribute {*}$argv
} result]} {
    puts stderr $result
} else {
    puts stdout $result
}

