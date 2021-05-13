ad_library {
    Start monitoring all configured servers at startup.
}

package require topcua
package require json
package require json::write

opc::read_conf

opc::monitor_servers
