
proc wibble::entropy {}     { set fp [open /dev/random];  K [read $fp 16] [close $fp] }



proc wibble::authorize { state } {
    dict with state request session {}

    set access [expr [dict? $state options access]]

    switch $access {
     1   - yes - ro  - rw  {
	 nexthandler [dict set state request session accmode $access]
     }
     default {
        dict set state response status 301
	dict set state response header location [dict? $request location]

	sendresponse $state
     }
    }
}


proc wibble::authenticate { state } {
    if { ![session check [dict get state request] } {
	set user [dict? $state request post user {}]
	set pass [dict? $state request post pass {}]

	if { [passwd check $user $pass] } {
	    nexthandler [session login $user $state]
	} else {
	    nexthandler [dict set state request session [list user guest]]
	}
    }
    nexthandler [session setup $state]
}

