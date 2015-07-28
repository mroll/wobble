# Send static files.
#
proc ::wibble::staticfile {state} {
    dict with state request {}; dict with state options {}
    if {![file isdirectory $fspath] && [file exists $fspath]} {
        dict set state response status 200
        dict set state response contentfile $fspath
        sendresponse [dict get $state response]
    }
}

