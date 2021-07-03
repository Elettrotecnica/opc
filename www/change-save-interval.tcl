ad_page_contract {
    UI to change the interval to persist collected values
}


set context [list \
		 [_ opc.change_save_interval_title]]

ad_form \
    -name change \
    -form {
	{interval:text
	    {label "#opc.change_save_interval_interval#"}
	    {help_text "[_ opc.change_save_interval_interval_helptext]"}
	}
    } -on_request {
	if {[nsv_array exists ::opc::save_value_schedule]} {
	    set interval [nsv_get ::opc::save_value_schedule interval]
	}
    } -on_submit {

	if {![regexp {^\d+(ms|s|m|d)?$} $interval m]} {
	    template::element::set_error change interval "#opc.change_save_interval_invalid_interval#"
	    break
	}
	
	opc::save_values_reschedule -interval $interval

    } -after_submit {
	ad_returnredirect .
	ad_script_abort
    }
