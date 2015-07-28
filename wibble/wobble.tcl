#!/usr/local/bin/tclsh8.6
#

lappend auto_path  /home/matt/lib/tcllib1.13 /Users/matt/lib/tcllib1.13

source icc.tcl
source utility.tcl
source wibble.tcl


package require wibble

source zones/vars.tcl

source zones/301.tcl
source zones/403.tcl
source zones/404.tcl

source zones/contenttype.tcl

source zones/dirslash.tcl
source zones/dirlist.tcl
source zones/indexfile.tcl
source zones/staticfile.tcl

source zones/scriptfile.tcl
source zones/template.tcl

source zones/authenticate.tcl
source zones/authorize.tcl

source modules/passwd-1.0.tcl
source modules/cgi.tcl
source modules/websocket.tcl
source modules/session-file.tcl


proc wibble::entropy {}     { set fp [open /dev/random];  K [read $fp 16] [close $fp] }

if { 0 } {
    source secure.tcl
    wibble::secure server-public.pem server-private.pem
}

set argv [lassign $argv option]


proc ::ws-demo { event sock { data {} } } {
    switch $event {
        message { 
        puts "WS-Demo: $event $sock $data"
        }
    }
}

if {$argv0 eq [info script]} {
    set root [lindex $argv 0]
    source [lindex $argv 1]

    # Define zone handlers.
    ::wibble::handle /vars vars
    ::wibble::handle / dirslash root $root
    ::wibble::handle / indexfile root $root indexfile index.html
    ::wibble::handle / staticfile root $root
    ::wibble::handle / template root $root
    ::wibble::handle / script root $root
    ::wibble::handle / dirlist root $root
    ::wibble::handle / notfound

    ::wibble::handle /src template root $root


    catch {
        ::wibble::listen 8080
        vwait forever
    }
}
