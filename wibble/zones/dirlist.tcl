# Generate directory listings.
#
proc ::wibble::zone::dirlist {state} {

    dict with state request {}; dict with state options {}
    if {![file isdirectory $fspath]} {
        # Pass if the requested object is not a directory or doesn't exist.
    } elseif {[file readable $fspath]} {
        # If the directory is readable, generate a listing.
        dict set state response status 200
        dict set state response header content-type "" text/html
        dict set state response content [template {
<html><body>
% if {$path ne "$prefix/"} {
    <li><a href="../">../</a></li>
% }
% foreach elem [lsort [glob -nocomplain -tails -types d -directory $fspath *]] {
    <li><a href="[enhex $prefix$suffix$elem/]">[enhtml $elem/]</a></li>
% }
% foreach elem [lsort [glob -nocomplain -tails -types f -directory $fspath *]] {
    <li><a href="[enhex $prefix$suffix$elem]">[enhtml $elem]</a></li>
% }
</body></html>}]
        sendresponse [dict get $state response]
    } else {
        # But if it isn't readable, generate a 403.
        forbidden $state
    }
}

