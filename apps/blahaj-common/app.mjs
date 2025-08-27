// bun, es modules, minimal deps; one file serves all three services
import http from 'http';

const serviceName = process.env.SERVICE_NAME || 'blahaj';
const emoji = process.env.SERVICE_EMOJI || '🦈';
const friend = process.env.FRIEND_NAME || 'sea-friend';
const port = Number(process.env.PORT || 8080);

const ascii = `
          __
      _.-'  \\
  _.-'  _.-'\\)   ${emoji}  // ascii blahaj says hi!
 (____.-'             ~ waves ~
`;

const server = http.createServer((req, res) => {
	const path = req.url || '/';
	const message = {
		service: serviceName,
		says: `hello, ${friend}! i am ${serviceName} ✨`,
		path,
		mascot: 'BLÅHAJ',
		fun: 'soft, cuddly shark energy',
	};
	res.setHeader('content-type', 'application/json; charset=utf-8');
	res.end(JSON.stringify({ message, ascii }));
});

server.listen(port, () => {
	console.log(`${serviceName} listening on ${port};`);
});
