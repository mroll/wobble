# http://tools.ietf.org/html/draft-robinson-www-interface-00
#
# This code is cribbed from in tclhttpd/lib/cgi.tcl
#

# options
#
# timeout	Seconds before pipe to CGI program is closed
# env		List of environment variables to pass to the script
# match		List of extension / interpreter pairs to force
#
proc wibble::matchlist { script match } {
    foreach { pattern interp } $match {
	if { [string match $pattern $script] } { return $interp }
    }
    return {}
}

# Copy the client data to the CGI process. UnChunking as necessary.
#
proc wibble::cgi-copy { out to coroutine } {

}

# Read the output from the CGI and fashion it into a response.
#
proc wibble::cgi-read { out to coroutine } {

    # Read header value.
    #

    # Copy results
    #

}
proc wibble::cgi-kill { pid } { exec kill -9 $pid }

proc wibble::cgi { state } {
    set sock [dict get $state chan]

    array set options {
	interp  {}
	timeout 300000
	kill    cgi-kill
    }
    array set options [dict get $state options]

    set script   $options(root)
    set interps  $options(interp)

    set pathlist [file split [dict get $state path]]
    set i 0


    foreach component $pathlist {
	set script [file join $script $component]

	if { [file isfile $script]		\
	&& ( [file executable $script]		\
	  || [matchlist $script $interplist ne {} ) } {
	    set extra [lrange $pathlist $i end]
	    break
	}
	incr i
    }

    if { ![info exists extra] } { return }

    set interp [matchlist $script $interplist]
    if { $interp ne {} } {
	set script "$interp $script"
    }

    set extra [join extra $extra /]

    # Found a script, Setup ENV and run it.
    #
    foreach var [dict get $state env] {
	catch { lappend vars $var $::env($var) }
    }
    lappend vars AUTH_TYPE=''
    lappend vars GATEWAY_INTERFACE='CGI/1.1'
    lappend vars PATH_INFO='$extra'
    lappend vars PATH_TRANSLATED='$script/$extra'
    lappend vars QUERY_STRING='[dict set $state rawquery]'
    lappend vars REMOTE_ADDR='[dict get $state peerhost]'
    lappend vars REMOTE_HOST='[dict get $state peerport]'
    lappend vars REQUEST_METHOD='[dict get $state method]'
    lappend vars SCRIPT_NAME='script'
    lappend vars SERVER_NAME='[exec hostname]'
    lappend vars SERVER_PORT='[dict get $state port]'
    lappend vars SERVER_PROTOCOL='HTTP/1.0'
    lappend vars SERVER_SOFTWARE='Wibble/1.0'

    catch { lappend vars CONTENT_LENGTH='[dict get $state header CONTENT_LENGTH]' }
    catch { lappend vars CONTENT_TYPE='[dict get $state header CONTENT_TYPE]' }
    foreach { var value } [dict get $state header] {
	if { [string match $var "Authorization"] } { continue }

	lappend vars HTTP_[string toupper [string map { - _ } $var]]='$value'
    }

    # Call the CGI script via the unix "env" command.  This allows the servers 
    # env to remain intact.
    #
    try { set cgi [open "| env -i $vars $script $args 2>@1"]
    } on error {
	puts stderr "$script : $error"
	return
    }
    if { $options(timeout) } { set to [after $options(timeout) [list $options(kill) [pid $cgi]]]
    } else { set to {} }

    fconfigure $cgi -blocking 0
    fileevent  $cgi readable [list ::wibble::cgi-read $cgi $to [info coroutine]]
    fileevent  $cgi writable [list ::wibble::cgi-copy $cgi $to [info coroutine]]

    return -code 7  ; # Release the socket from normal Wibble responce processing.
}

