ad_page_contract {
    AJAX enpoint to retrieve the values from the OPC backend. Used as
    a fallback when websockets are not supported.
} {
}

auth::require_login

if {[nsv_array exists ::opc::status_json]} {
    set data [lindex [nsv_array get ::opc::status_json] 1]
} else {
    set data [list]
}

ns_return 200 application/json [::json::write array {*}[dict values $data]]
