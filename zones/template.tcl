# Execute templates.
#
proc ::wibble::zone::templatefile {state} {
    dict with state request {}; dict with state options {}
    if {[file readable $fspath.tmpl]} {
        set chan [open $fspath.tmpl]
        set body [chan read $chan]
        chan close $chan
        dict set state response status 200
        dict set state response content [template $body]
        sendresponse [dict get $state response]
    }
}

