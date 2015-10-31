// vim: ts=3:sw=3:fdm=indent :
var http = require('http');
var pg = require('pg').native;
var conString = "postgres://user:3r0oR@localhost/tspergode";

function handleRequest(request, response){
	pg.connect(conString, 
		function(err, client, done) {
			console.log(request.headers);
			if(err) return console.error('error fetching client from pool', err);
			client.query("SELECT getpage from getpage( $URL$" + request.url + "$URL$ );", [], 
				function(err, result) {
					if(err) return console.error('error running query', err);
					out=result.rows[0].getpage;
					if(out.length>0)response.writeHead(200,{
						'Content-Length':out.length,
						'Content-Type':'text/html'
						
					});
					response.end(out);
					done();
					console.log(out);
			});
		});
}
http.createServer(handleRequest).listen(80, function(){
	console.log("Server listening on: http://localhost:%s",80);
});
