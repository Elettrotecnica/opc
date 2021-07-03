ad_page_contract {
    Generate the UI to retrieve and set values on configured nodes.
} {
}

auth::require_login

set context [list \
		 [_ opc.display_values_title]]

set nonce [security::csp::nonce]

template::multirow create opc server node value
foreach {url conf} [nsv_array get ::opc::conf] {
    if {[nsv_exists ::opc::status $url]} {
	set s [nsv_get ::opc::status $url]
    } else {
	set s ""
    }

    foreach n [dict get $conf nodes] {
	if {[dict exists $s $n]} {
	    set value [dict get $s $n]
	} else {
	    set value ""
	}
	template::multirow append opc $url $n $value
    }
}


