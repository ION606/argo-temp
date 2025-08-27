const endpoints = [
	{ path: '/blahaj', title: 'bubbles greeter (blahaj)' },
	{ path: '/kelp', title: 'kelp' },
	{ path: '/coral', title: 'coral' },
	{ path: '/bubbles', title: 'bubbles' },
];

const cards = document.querySelector('#cards');

function cardDOM({ title, ok, data, error }) {
	const el = document.createElement('article');
	el.className = `card ${ok ? 'ok' : 'err'}`;

	const h2 = document.createElement('h2');
	h2.textContent = title;
	el.appendChild(h2);

	const pre = document.createElement('pre');
	pre.textContent = ok ? JSON.stringify(data, null, 2) : String(error || 'error');
	el.appendChild(pre);

	return el;
}

async function fetchOne(path) {
	const r = await fetch(path, { headers: { 'accept': 'application/json' } });
	if (!r.ok) throw new Error(`${path} -> ${r.status}`);
	return r.json();
}

async function refresh() {
	cards.textContent = ''; // clear
	for (const ep of endpoints) {
		try {
			const data = await fetchOne(ep.path);
			cards.appendChild(cardDOM({ title: ep.title, ok: true, data }));
		} catch (err) {
			cards.appendChild(cardDOM({ title: ep.title, ok: false, error: err.message }));
		}
	}
}

document.querySelector('#refresh').addEventListener('click', () => refresh());
refresh();
