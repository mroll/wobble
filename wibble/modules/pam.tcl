
package require critcl 2.0

#
#   pam.tcl
#
#   Tcl interface to the *nix PAM library
#

package require critcl
package provide pam 1.0

if {![critcl::compiling]} {
    puts stderr "This extension cannot be compiled without critcl enabled"
	exit 1
}

namespace eval pam {

    critcl::clibraries -lpam
	::critcl::config I /usr/include

	critcl::ccode {
	    #include <stdio.h>
	    #include <security/pam_appl.h>
	    //#include <security/pam_misc.h>

	    static int conversation(int num_msg, const struct pam_message **msg,
		    struct pam_response **resp, void *appdata_ptr)
	    {
		/* just return the supplied password back to PAM */
		*resp = calloc(num_msg, sizeof(struct pam_response));
		(*resp)[0].resp = strdup((char *) appdata_ptr);
		(*resp)[0].resp_retcode = 0;
		return ((*resp)[0].resp ? PAM_SUCCESS : PAM_CONV_ERR);
	    }
	}

    critcl::cproc authenticate { char* service char* user char* passwd } int {
	struct pam_conv conv = { conversation, passwd };
	pam_handle_t *pamh = NULL;
	int code, ret;

	if (pam_start(service, user, &conv, &pamh) != PAM_SUCCESS) {
	    return 0;
	}
	if (pam_authenticate(pamh, 0) == PAM_SUCCESS) {
	    ret = 1;
	} else {
	    ret = 0;
	}
	if (pam_end(pamh, 0) != PAM_SUCCESS) {
	    ret = 0;
	}
	return ret;
    }
}
