const https = require("https")

//const FIRST_COMMIT = '629c2732e347ff5b2130fd7fae4b89bdb830a484'
//const LAST_COMMIT  = 'fa6ddb204f4f924b4a63dcd2408d923881f01151'
//const REPO = 'AndreRH/wine'
//const EXTRA = ''

const FIRST_COMMIT = '3079dbd172eb6b38fa69411033b4ecea76eb17bf'
const LAST_COMMIT  = '68033cf25e0ded85a2e21fd696dc305bdc458ca7'
const REPO = 'AndreRH/FEX'
const EXTRA = '&sha=68033cf25e0ded85a2e21fd696dc305bdc458ca7'

https.request(new URL(`https://api.github.com/repos/${REPO}/commits?per_page=300${EXTRA}`), {
    headers: {
        'User-Agent': 'Hangover-Commits-Fetcher'
    }
}, (res) => {
    let data = []
    res.setEncoding('utf8');
	res.on('data', (d) => data.push(d))
    res.on('end', () => {
        data = JSON.parse(data.join(''))
        let inrange = false;
        let incommits = []
        for (let i = 0; i < data.length; i++) {
            const e = data[i];
            if(e.sha === LAST_COMMIT) inrange = true;
            if(inrange) incommits.push(e.sha)
            if(e.sha === FIRST_COMMIT) break;
        }
        console.log(incommits.join(' '))
    })
}).end()