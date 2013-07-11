# Execute scripts.
#
proc ::wibble::zone::scriptfile {state} {
    dict with state request {}; dict with state options {}
    if {[file readable $fspath.script]} {
        dict set state response status 200
        source $fspath.script
        sendresponse [dict get $state response]
    }
}

