 ################################################################################
 # Modul    : bgexec1.8.tcl                                                     #
 # Changed  : 08.10.2007                                                        #
 # Purpose  : running processes in the background, catching their output via    #
 #            event handlers                                                    #
 # Author   : M.Hoffmann                                                        #
 # To do    : - rewrite using NAMESPACEs                                        #
 # Hinweise : >&@ and 2>@stdout don't work on Windows. A work around probably   #
 #            could be using a temporay file. Beginning with Tcl 8.4.7 / 8.5    #
 #            there is another (yet undocumented) way of redirection: 2>@1.     #
 # History  :                                                                   #
 # 19.11.03 v1.0 1st version                                                    #
 # 20.07.04 v1.1 callback via UPLEVEL                                           #
 # 08.09.04 v1.2 using 2>@1 instead of 2>@stdout if Tcl >= 8.4.7;               #
 #               timeout-feature                                                #
 # 13.10.04 v1.3 bugfix in bgExecTimeout, readHandler is interruptable          #
 # 18.10.04 v1.4 bugfix: bgExecTimeout needs to be canceled when work is done;  #
 #               some optimizations                                             #
 # 14.03.05 v1.4 comments translated to english                                 #
 # 17.11.05 v1.5 If specidied, a user defined timeout handler `toExit` runs in  #
 #               case of a timeout to give chance to kill the PIDs given as     #
 #               arg. Call should be compatible (optional parameter).           #
 # 23.11.05 v1.6 User can give additional argument to his readhandler.          #
 # 03.07.07 v1.7 Some Simplifications (almost compatible, unless returned       #
 #               string where parsed):                                          #
 #               - don't catch error first then returning error to main...      #
 # 08.10.07 v1.8 fixed buggy version check!                                     #
 # ATTENTION: closing a pipe leads to error broken pipe if the opened process   #
 #             itself is a tclsh interpreter. Currently I don't know how to     #
 #             avoid this without killing the process via toExit before closing # 
 #             the pipeline.                                                    #
 ################################################################################

 package provide bgexec 1.8

 #-------------------------------------------------------------------------------
 # If the <prog>ram successfully starts, its STDOUT and STDERR is dispatched
 # line by line to the <readHandler> (via bgExecGenericHandler) as last arg.
 # <pCount> holds the number of processes called this way. If a <timeout> is
 # specified (as msecs), the process pipeline will be automatically closed after
 # that duration. If specified, and a timeout occurs, <toExit> is called with
 # the PIDs of the processes right before closing the process pipeline.
 # Returns the handle of the process-pipeline.
 #
 proc bgExec {prog readHandler pCount {timeout 0} {toExit ""}} {
      upvar #0 $pCount myCount
      set myCount [expr {[info exists myCount]?[incr myCount]:1}]
      set p [expr {[lindex [lsort -dict [list 8.4.7 [info patchlevel]]] 0] == "8.4.7"?"| $prog 2>@1":"| $prog 2>@stdout"}]
      set pH [open $p r+]
      fconfigure $pH -blocking 0; # -buffering line (does it really matter?!)
      set tID [expr {$timeout?[after $timeout [list bgExecTimeout $pH $pCount $toExit]]:{}}]
      fileevent $pH readable [list bgExecGenericHandler $pH $pCount $readHandler $tID]
      return $pH
 }
 #-------------------------------------------------------------------------------
 proc bgExecGenericHandler {chan pCount readHandler tID} {
      upvar #0 $pCount myCount
      if {[eof $chan]} {
         after cancel $tID;   # empty tID is ignored
         catch {close $chan}; # automatically deregisters the fileevent handler
                              # (see Practical Programming in Tcl an Tk, page 229)
         incr myCount -1
      } elseif {[gets $chan line] != -1} {
         # we are not blocked (manpage gets, Practical... page.233)
         lappend readHandler $line
         if {[catch {uplevel $readHandler}]} {
            # user-readHandler ended with error -> terminate the processing
            after cancel $tID
            catch {close $chan}
            incr myCount -1
         }
      }
 }
 #-------------------------------------------------------------------------------
 proc bgExecTimeout {chan pCount toExit} {
      upvar #0 $pCount myCount
      if {[string length $toExit]} {
         catch {uplevel [list $toExit [pid $chan]]}
      }
      catch {close $chan}
      incr myCount -1
 }
 #===============================================================================
