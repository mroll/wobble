
package require Trf
package require tls
package require sha1

proc wibble::secure { certfile keyfile args } {			# http://wiki.tcl.tk/9414
     ::tls::init -certfile $certfile -keyfile  $keyfile \
	 -ssl2 1 -ssl3 1 -tls1 0 			\
	 -require 0 -request 0 {*}$args

    proc ::wibble::socket { args } {
	puts Secure
	::tls::socket {*}$args
    }
}
