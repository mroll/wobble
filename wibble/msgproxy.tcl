
 proc msgproxy-update { sock serv name args } {
     ws-send $sock "0 set $serv $name [set ::${serv}.${name}]"
 }
 proc msgproxy { event sock data } {
    switch $event {
     connect {
     }
     message {
	set data [lassign $data msgno cmd serv]
	try {
	    switch $cmd {
	     con {     msg_client $serv					}
	     get {     ws-send $sock "ack $msgno [msg_get $serv]"	}
 	     set {     ws-send $sock "ack $msgno [msg_set $serv {*}$data]"	}
	     sub {     ws-send $sock "ack $msgno [msg_sub $serv $data $serv.$data .2 [list msgproxy-update $sock $serv $data]] }
	     default { ws-send [msg_cmd $serv $data] }
	    }
	} on error message {
	    ws-send "nak $sock $message"
	}
     }
    }
 }

 wibble::handle /msgproxy	  websocket handler msgproxy

