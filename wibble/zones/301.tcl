# Send a 301 Moved Permanently.
#
proc ::wibble::redirect {newurl {state ""}} {
    dict set state response status 301
    dict set state response header location $newurl
    sendresponse [dict get $state response]
}

