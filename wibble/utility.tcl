
proc K { x y } { set x }

# http://wiki.tcl.tk/15362
#
proc wibble::touch { file } { close [open $file] }
proc wibble::cat   { file args } { K [read {*}$args [set fp [open $file]]] [close $fp] }
proc wibble::echo {string {redirector -} {file -}} {
    set postcmd {close $fp}
    switch -- $redirector {
    	>       {set fp [open $file w]}
    	>>      {set fp [open $file a]}
    	default {set fp stdout; set postcmd ""}
        }
    puts $fp $string
    eval $postcmd
}

proc wibble::cookie { name value args } {	# Cribbed from tclhttpd/cookie.tcl
    array set opt $args
    set cookie "$name=$value ;"

    foreach extra {path domain} {
	if {[info exist opt(-$extra)]} {
	    append cookie " $extra=$opt(-$extra) ;"
	}
    }
    if {[info exist opt(-expires)]} {
	switch -glob -- $opt(-expires) {
	 + - - {
	    set expires [clock format [expr "[clock seconds] [string map { seconds {} minutes *60 hours *60*60 days *60*60*24 } $opt(-expires)]"] \
		    -format "%A, %d-%b-%Y %H:%M:%S GMT" -gmt 1]
	 }
	 *GMT {
		set expires $opt(-expires)
	 }
	 default {
		set expires [clock format [clock scan $opt(-expires)] \
		    -format "%A, %d-%b-%Y %H:%M:%S GMT" -gmt 1]
	 }
	}
	append cookie " expires=$expires ;"
    }
    if {[info exist opt(-secure)]} {
	append cookie " secure "
    }
    return $cookie
}

proc wibble::setcookie { response name value args } {
    upvar $response r
    dict lappend r header Set-Cookie [wibble::cookie $name $value {*}$args]
}

proc dict? { args } {		# This is really annoying!!
    try { dict get {*}$args
    } on error message {
	puts "dict? : $message"
    }
}

