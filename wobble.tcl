#!/usr/bin/env tclkit8.6
#

lappend auto_path  /home/john/lib/tcllib1.13 /Users/john/lib/tcllib1.13

source icc.tcl
source wibble.tcl

source modules/passwd-1.0.tm
source modules/cgi.tcl
source modules/socket.tcl
source modules/session-file.tcl

package require wibble
package require passwd

if { 0 } {
    source secure.tcl
    wibble::secure server-public.pem server-private.pem
}

set argv [lassign $argv option]

switch -- $option {
 server {}
 email  -
 passwd {
    lassign $argv name pass email

    wibble::passwords set $::passwords $name $option	\
    	[if { $option eq "passwd" } { wibble::hmac $pass } else { set email }]
    exit
 }
}

    set root [file normalize [file dirname [info script]]]

#    wibble::passwd data {
#	john	XXXX	john@june.com
#	may	YYYY	 may@june.com
#	june	YYYY	june@june.com
#    }
#    wibble::groups data {
#	losers { john may june }
#	lusers { $losers }
#    }

#    wibble::access data {
#	/Front+Page	{ admin  rw default ro }
#	/		{ lusers rw }
#	/data		{ data   ro }
#    }

#    wibble::passwd file etc/passwd
#    wibble::groups file etc/groups
#    wibble::access file etc/access .access

    proc ::ws-demo { event sock { data {} } } {
	switch $event {
	    message { 
		puts "WS-Demo: $event $sock $data"
	    }
	}
    }

#    wibble::handle /      authenticate
#    wibble::handle /      authorize access { $user ne guest }

    wibble::handle /vars  vars

#    wibble::handle /	  cgi 		root $root match *.sh exec yes	

    wibble::handle /      dirslash 	root $root
    wibble::handle /      indexfile 	root $root indexfile index.html
    wibble::handle /      staticfile 	root $root

#    wibble::handle /	  post-parse

    wibble::handle /      template 	root $root
    wibble::handle /      scriptfile 	root $root
    wibble::handle /      dirlist 	root $root
    wibble::handle /      notfound

    wibble::listen 8080
    vwait forever
