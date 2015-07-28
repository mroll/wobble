proc wibble::authorize { state } {
    dict with state request session {}

    set access [expr [dict? $state options access]]

    switch $access {
        1   - yes - ro  - rw  {
            nexthandler [dict set state request session accmode $access]
        }
        default {
             dict set state response status 301
             dict set state response header location [dict? $state request location]

            sendresponse $state
        }
    }
}

