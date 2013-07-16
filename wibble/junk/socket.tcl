package require sha1
package require base64

# Utility proc to frame and send strings up to 64k chars
#
proc ::wibble::ws-send { sock message } {
    if { [string length $message] < 126 } {
	puts -nonewline $sock [binary format cc 0x81 [string length $message]]$message
    } else {
	puts -nonewline $sock [binary format cc 0x81 126 s [string length $message]]$message
    }
    flush $sock
}

# WebSocket handler proc to receive short (up to 126 chars) text format frames
#
proc ::wibble::ws-handle { handler sock } {

    if { [chan eof $sock] } {
	close $sock
    } else {
	binary scan [read $sock 1] c opcode
	binary scan [read $sock 1] c length

	set opcode [expr $opcode & 0x0F]
	set length [expr $length & 0x7F]

	binary scan [read $sock 4]       c* mask
	binary scan [read $sock $length] c* data

	set msg {}
	set i    0
	foreach char $data {
	    append msg [binary format c [expr { $char^[lindex $mask [expr { $i%4 }]] }]]
	    incr i
	}

	$handler message $sock $msg
    }
}

# Zone handler
#
proc ::wibble::websocket { state } {
    set upgrade    {}
    set connection {}

    dict with state request header {}

    if { $connection ne "Upgrade" || $upgrade ne "websocket" } {
	return
    }

    set sock [dict get $state request socket]

    set response [base64::encode [sha1::sha1 -bin ${sec-websocket-key}258EAFA5-E914-47DA-95CA-C5AB0DC85B11]]
    set handler  [dict get $state options handler]

    puts $sock "HTTP/1.1 101 WebSocket Protocol Handshake"
    puts $sock "Upgrade:    websocket"
    puts $sock "Connection: Upgrade"
    puts $sock "Sec-WebSocket-Accept: $response"
    puts $sock ""

    chan configure $sock -translation binary
    chan event     $sock readable [list ::wibble::ws-handle $handler $sock]

    $handler connect $sock

    return -code 7
}
