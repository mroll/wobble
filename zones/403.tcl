# Send a 403 Forbidden.
#
proc ::wibble::zone::forbidden {state} {
    dict set state response status 403
    dict set state response header content-type {"" text/plain charset utf-8}
    dict set state response content "forbidden: [dict get $state request uri]\n"
    sendresponse [dict get $state response]
}


