# Echo request dictionary.
#
proc ::wibble::vars {state} {
    dict set state response status 200
    dict set state response header content-type "" text/html
    dict set state response content [template {
<html><head><style type="text/css">
    body {font-family: monospace}
    table {border-collapse: collapse; outline: 1px solid #000; width: 100%}
    th {white-space: nowrap; text-align: left; vertical-align: top}
    th, td {border: 1px solid #727772}
    tr:nth-child(odd) {background-color: #ded}
    tr:nth-child(even) {background-color: #eee}
    th.title {background-color: #8d958d; text-align: center}
</style></head><body><table>
% dict for {dictname dictval} $state {
    <tr><th class="title" colspan="2">[enhtml $dictname]</th></tr>
%   if {$dictname in {request response}} {
%       set dictval [dumpstate $dictval]
%   }
%   dict for {key val} $dictval {
    <tr><th>[enhtml $key]</th><td>[enhtml $val]</td></tr>
%   }
% }
</table></body></html>}]
    sendresponse [dict get $state response]
}
