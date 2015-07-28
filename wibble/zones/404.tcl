# Send a 404 Not Found.
#
proc ::wibble::notfound {state} {
    dict set state response status 404
    dict set state response header content-type {"" text/plain charset utf-8}
    dict set state response content "not found: [dict get $state request uri]\n"
    sendresponse [dict get $state response]
}

interp alias {} ::wibble::zone::404 {} ::wibble::zone::notfound


