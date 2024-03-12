const https = require("https")

const FIRST_COMMIT = 'fc4267d4707e992d8881826bd6f880ea2a37974a'
const LAST_COMMIT  = 'da0d00866db4d3fec8dcdbfd5a3f3ed48611d933'
const REPO = 'AndreRH/wine'
const EXTRA = ''

//const FIRST_COMMIT = '3079dbd172eb6b38fa69411033b4ecea76eb17bf'
//const LAST_COMMIT  = '68033cf25e0ded85a2e21fd696dc305bdc458ca7'
//const REPO = 'AndreRH/FEX'
//const EXTRA = '&sha=68033cf25e0ded85a2e21fd696dc305bdc458ca7'

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
        console.log(incommits.reverse().join(' '))
    })
}).end()