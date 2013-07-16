# =================== inter-coroutine communication system ====================

# The inter-coroutine communication procedures are in the [icc] ensemble.
namespace eval ::wibble::icc {
    namespace export configure destroy get catch put
    namespace ensemble create
    variable feeds
}

# Lapse (remove) a feed that nothing's interested in anymore.
proc ::wibble::icc::lapse {fid} {
    variable feeds

    # Clean up the feed's data structures.
    set lapsescript [dict get $feeds $fid lapsescript]
    dict unset feeds $fid

    # Run the lapse script, which may be empty string.
    uplevel #0 $lapsescript
}

# Adjust an ICC feed's configuration, creating the feed in the process.
# [icc configure $fid accept|reject ?filter? ?...?]
# [icc configure $fid lapse ?timeout_milliseconds? ?lapsescript?]
proc ::wibble::icc::configure {fid operation args} {
    variable feeds

    # Initialize the feed if it doesn't already exist.
    if {![info exists feeds] || ![dict exists $feeds $fid]} {
        dict set feeds $fid {acceptable {exception timeout} lapsetime ""
            lapsescript "" lapsecancel "" suspended "" pending ""}
    }

    # Reset the feed's lapse timeout.
    after cancel [dict get $feeds $fid lapsecancel]
    dict set feeds $fid lapsecancel ""

    # Process the requested operation.
    switch $operation {
    lapse {
        # Store arguments into feed structure, defaulting to "".
        dict set feeds $fid lapsetime [lindex $args 0]
        dict set feeds $fid lapsescript [lindex $args 1]
    } accept {
        # Append the arguments to the list of accepted filters.
        dict set feeds $fid acceptable [lsort -unique [concat\
            [dict get $feeds $fid acceptable] $args]]
    } reject {
        # Remove all filters that match any of the argument patterns.
        set index 0
        foreach filter [dict get $feeds $fid acceptable] {
            foreach pattern $args {
                if {[string match $pattern $filter]
                 && $filter ni {exception timeout}} {
                    dict set feeds $fid acceptable [lreplace\
                        [dict get $feeds $fid acceptable] $index $index]
                    incr index -1
                    break
                }
            }
            incr index
        }
    }}

    # Restart the feed's lapse timeout.
    if {[dict get $feeds $fid lapsetime] ne ""} {
        dict set feeds $fid lapsecancel [after [dict get $feeds $fid lapsetime]\
            [list ::wibble::icc::lapse $fid]]
    }
}

# Destroy a feed.
proc ::wibble::icc::destroy {fid} {
    variable feeds

    # Cancel the feed's readability and timeout handlers.
    if {[namespace qualifiers $fid] eq "::wibble"
     && [set socket [namespace tail $fid]] eq [chan names $socket]} {
         chan event $socket readable ""
    }
    after cancel [dict get $feeds $fid lapsecancel]

    # Wake suspended coroutines monitoring only this feed with no timeout.
    dict for {coro filters} [dict get $feeds $fid suspended] {
        if {"timeout" ni $filters} {
            lappend suspended $coro
        }
    }
    if {[info exists suspended]} {
        dict for {fid2 data2} $feeds {
            set index 0
            foreach coro $suspended {
                if {$coro in [dict get $data2 suspended]} {
                    set suspended [lreplace $suspended $index $index]
                    incr index -1
                }
                incr index
            }
        }
        foreach coro $suspended {
            $coro
        }
    }

    # Unset the feed's data structure.
    dict unset feeds $fid
}

# Get list of events on any of the named feeds matching any of the filters.  If
# an exception event is received, execution jumps to the enclosing [icc catch].
proc ::wibble::icc::get {fids filters {timeout ""}} {
    variable feeds

    # The exception event is always permitted.
    lappend filters exception
    set code 0

    # Reset the feed lapse timeouts, and check for pending events.
    set index 0
    foreach fid $fids {
        # Reset the feed's lapse timeout.
        after cancel [dict get $feeds $fid lapsecancel]
        dict set feeds $fid lapsecancel ""

        # Gather the pending events that match the request filters.
        foreach entry [dict get $feeds $fid pending] {
            foreach filter $filters {
                if {[string match $filter [lindex $entry 0]]} {
                    if {[lindex $entry 0] eq "exception"} {
                        set code 7
                    }
                    dict set feeds $fid pending [lreplace\
                        [dict get $feeds $fid pending] $index $index]
                    lappend result $entry
                    incr index -1
                    break
                }
            }
            incr index
        }
    }

    # If no acceptable events were pending, wait for one to occur.
    if {![info exists result]} {
        # Install wake-up handlers for readability and timeout, as requested.
        set coro [info coroutine]
        if {[namespace qualifiers $coro] eq "::wibble"
         && "readable" in $filters && $coro in $fids} {
            set socket [namespace tail $coro]
            chan event $socket readable [list $coro readable]
        }
        if {$timeout ne ""} {
            lappend filters timeout
            if {$coro ni $fids} {
                lappend fids $coro
            }
            set timeoutcancel [after $timeout [list $coro timeout]]
        }

        # Wait for an event.  Maintain each feed's list of suspended coroutines.
        foreach fid $fids {
            dict set feeds $fid suspended $coro $filters
        }
        set result [list [yield]]
        if {[lindex $result 0 0] eq "exception"} {
            set code 7
        } elseif {![llength [lindex $result 0]]} { 
            set result {}
        }
        foreach fid $fids {
            if {[dict exists $feeds $fid]} {
                dict unset feeds $fid suspended $coro
            }
        }

        # Remove the readability and timeout handlers.
        if {$timeout ne "" && [lindex $result 0 0] ne "timeout"} {
            after cancel $timeoutcancel
        }
        if {[info exists socket]} {
            chan event $socket readable ""
        }
    }

    # Restart the lapse timeouts for the feeds monitored by this coroutine.
    foreach fid $fids {
        if {[dict getnull $feeds $fid lapsetime] ne ""} {
            after cancel [dict get $feeds $fid lapsecancel]
            dict set feeds $fid lapsecancel [after [dict get $feeds $fid\
                lapsetime] [list ::wibble::icc::lapse $fid]]
        }
    }

    # Return the event data.  If there was an exception event, return code 7.
    return -code $code $result
}

# Execute a script and return any exception events received by [icc get] within
# that script.  Other events may be returned too, but only if they happened in
# the same batch as an exception event.
proc ::wibble::icc::catch {script} {
    tailcall try $script on 7 events {set events} on ok "" {}
}

# Send event data to the named feeds, or all if "*".
proc ::wibble::icc::put {fids event args} {
    variable feeds

    # Expand "*" to a list of all feeds that exist at the time [put] is called.
    if {$fids eq "*"} {
        set fids [dict keys $feeds]
    }

    # Insist on running from the event loop, never from within a coroutine.
    if {[info coroutine] ne ""} {
        after 0 [concat [list ::wibble::icc::put $fids $event] $args]
        return
    }

    # Send the event to all feeds whose filters accept it.
    set argument [concat [list $event] $args]
    foreach fid $fids {
        if {[dict exists $feeds $fid]} {
            foreach filter [dict get $feeds $fid acceptable] {
                if {[string match $filter $event]} {
                    # Send event to a suspended coroutine watching the feed.
                    set found 0
                    dict for {coro filters} [dict get $feeds $fid suspended] {
                        foreach filter $filters {
                            if {[string match $filter $event]} {
                                if {[info commands $coro] ne ""} {
                                    $coro $argument
                                }
                                set found 1
                                break
                            }
                        }
                    }

                    # If no suspended coroutine, enqueue the event.
                    if {!$found} {
                        dict set feeds $fid pending [concat\
                            [dict get $feeds $fid pending] [list $argument]]
                    }
                    break
                }
            }
        }
    }
}


