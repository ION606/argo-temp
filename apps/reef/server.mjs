const serveFile = (path) => new Response(Bun.file(path));

const server = Bun.serve({
	port: Number(process.env.PORT || 8080),
	async fetch(req) {
		const url = new URL(req.url);
		if (url.pathname === '/') return serveFile('./public/index.html');
		if (url.pathname.startsWith('/static/')) {
			return serveFile(`.${url.pathname}`);
		}

		return serveFile('./public/index.html');
	},
});

console.log(`reef listening on ${server.port};`);
