# Guess the content type from the URI extension.
#
proc ::wibble::zone::contenttype {state} {
    dict with state request {}; dict with state options {}
    set extension [string tolower [string range [file extension $path] 1 end]]
    foreach {type pattern} $typetable {
        if {[regexp -nocase -- $pattern $extension]} {
            dict set state response header content-type "" $type
            nexthandler $state
        }
    }
}

