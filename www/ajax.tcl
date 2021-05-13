ad_page_contract {
    AJAX enpoint to set values on the OPC backend
} {
    server
    node
    value
} -validate {
    valid_server -requires server {
	if {![nsv_exists ::opc::conf $server]} {
	    ad_complain "Invalid input"
	}
    }
    valid_node -requires {valid_server node} {
	set conf [nsv_get ::opc::conf $server]
	if {$node ni [dict get $conf nodes]} {
	    ad_complain "Invalid input"
	}
    }
}

auth::require_login

set conf [nsv_get ::opc::conf $server]

set url [dict get $conf url]
set interval [dict get $conf interval]

# create client
opcua new client C

set use_encryption_p [expr {
			    [dict exists $conf client_cert] ||
			    [dict exists $conf client_key]
			}]
if {$use_encryption_p} {
    # Add the encryption certificates to the clients, when provided
    opcua cert C \
	[opc::read_file -binary [dict get $conf client_cert]] \
	[opc::read_file -binary [dict get $conf client_key]]
}

# connect to server
opcua connect C $url

opcua write C $node [opcua type C $node] $value

set value [opcua read C $node]

opcua disconnect C
opcua destroy C

ns_return 200 text/plain $value
