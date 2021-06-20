<master>

  <form name="opc">
    <multiple name="opc">
      <div>
	<h3>@opc.server@</h3>
	<group column="server">
	  <div>
	    <label for="@opc.server@-@opc.node@">@opc.node@</label>
	    <input id="@opc.server@-@opc.node@"
		   data-server="@opc.server@"
		   data-node="@opc.node@"
		   value="@opc.value@">
            <button class="opc-button" id="@opc.server@-@opc.node@-save">Save</button>
	  </div>
	</group>
      </div>
    </multiple>
  </form>

  <script nonce="@nonce;literal@">
    for (b of document.querySelectorAll('.opc-button')) {
	b.addEventListener('click', function (e) {
	    e.preventDefault();
	    var input = b.previousElementSibling;
	    var x = new XMLHttpRequest();
	    x.addEventListener('loadend', function() {
		if (this.status !== 200) {
		    alert('Server responded with error status code ' + this.status);
		}
	    });
	    var formData = new FormData();
	    formData.append('server', input.getAttribute('data-server'));
	    formData.append('node', input.getAttribute('data-node'));
	    formData.append('value', input.value);
	    x.open('POST', '/opc/ajax-write');
	    x.send(formData);
	});
    }

    function updateUIFromData(data) {
	data = JSON.parse(data);
	if (!data.length) {
	    data = [data];
	}
	for (d of data) {
    	    var e = document.getElementById(d.url + '-' + d.node);
	    if (e !== document.activeElement) {
		e.value = d.value;
	    }
	}
    }

    function connect(wsURI) {
	var websocket;

	// Connect to the websocket backend.
	if ('WebSocket' in window) {
            websocket = new window.WebSocket(wsURI);
	} else {
            websocket = new window.MozWebSocket(wsURI);
	}
	websocket.onopen = function (e) {
	    console.log('Connected.');
	};
	websocket.addEventListener('close', function (e) {
            console.log('Disconnected.');
	});
	websocket.addEventListener('message', function (e) {
	    updateUIFromData(e.data);
	});

	return websocket;
    }

    function pollServer() {
	var x = new XMLHttpRequest();
	x.addEventListener('loadend', function() {
	    if (this.status !== 200) {
		alert('Server responded with error status code ' + this.status);
	    } else {
		updateUIFromData(this.responseText);
	    }
	});
	x.open('GET', '/opc/ajax-read');
	x.send();

	setTimeout(pollServer, 500);
    }

    var proto = window.location.protocol;
    var host = window.location.host;
    wsURI = (proto === 'https:' ? 'wss:' : 'ws:') + '//' + host + '/opc/ws';

    try {
	var ws = connect(wsURI);
    } catch (e) {
	console.warn("Connection to websocket " + wsURI + " failed. Error is: " + e + ". Falling back to polling...");
	pollServer();
    }
  </script>
