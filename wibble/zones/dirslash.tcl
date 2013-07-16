# Redirect when a directory is requested without a trailing slash.
#
proc ::wibble::zone::dirslash {state} {
    dict with state request {}; dict with state options {}
    if {[file isdirectory $fspath] && [string index $suffix end] ni {/ ""}} {
        append path /
        if {[info exists rawquery]} {
            append path $rawquery
        }
        redirect $path
    }
}

