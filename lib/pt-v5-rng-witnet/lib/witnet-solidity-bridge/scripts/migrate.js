/* eslint-disable camelcase */
/* eslint-disable new-cap */
/* eslint-disable no-multi-str */
/* eslint-disable no-template-curly-in-string */

require("dotenv").config()

const settings = require("../migrations/witnet.settings")
const utils = require("./utils")

if (process.argv.length < 3) {
  console.log()
  console.log("\n\
    Usage: yarn migrate <[Realm.]Network>\n\
       or: npm run migrate <[Realm.]Network>\n\n\
  ")
  process.exit(0)
}

const rn = utils.getRealmNetworkFromString(process.argv[2])
const realm = rn[0]; const network = rn[1]

if (!settings.networks[realm] || !settings.networks[realm][network]) {
  console.error(`\n!!! Network "${network}" not found.\n`)
  if (settings.networks[realm]) {
    console.error(`> Available networks in realm "${realm}":`)
    console.error(settings.networks[realm])
  } else {
    console.error("> Available networks:")
    console.error(settings.networks)
  }
  process.exit(1)
}

migrate(network)

/// ///////////////////////////////////////////////////////////////////////////////

async function migrate (network) {
  console.log(
    `> Migrating into "${realm}:${network}"...`
  )
  await new Promise((resolve) => {
    const subprocess = require("child_process").spawn(
      "npx truffle",
      [
        "migrate",
        "--reset",
        "--network",
        network,
      ],
      {
        shell: true,
        stdin: "inherit",
      }
    )
    process.stdin.pipe(subprocess.stdin)
    subprocess.stdout.pipe(process.stdout)
    subprocess.stderr.pipe(process.stderr)
    subprocess.on("close", (code) => {
      if (code !== 0) {
        process.exit(code)
      }
      resolve(subprocess.stdout)
    })
  })
}
