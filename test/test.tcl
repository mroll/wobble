
proc ? { name 1 2 } {
    set start [clock milliseconds]

    puts -nonewline [format %-40s $name]
    if { [set x [eval $1]] eq $2 } {
	puts "Pass [format %.2f [expr ([clock milliseconds] - $start)/1000]]"
    } else {
	puts "Fail : $x != $2"
    }
}
