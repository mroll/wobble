# Execute scripts.
#
proc ::wibble::script { state } {
    dict with state request {}; dict with state options {}
    if {[file readable $root$prefix.script]} {
        dict set state response status 200
        source $root$prefix.script
        sendresponse [dict get $state response]
    }
}
