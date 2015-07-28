# Execute scripts.
#
proc ::wibble::script {state} {
    dict with state request {}; dict with state options {}
    if {[file readable $fspath.script]} {
        dict set state response status 200
        source $fspath.script
        sendresponse [dict get $state response]
    }
}
