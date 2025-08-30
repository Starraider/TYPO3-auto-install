Create a Bash script that automatically installs TYPO3 version 13 using DDEV.
The project’s configuration is read from the install.config.
PHP version 8.3 and typo3/cms-base-distribution should be used.
Afterwards, it should be helhum/typo3-console, helhum/dotenv-connector and bk2k/bootstrap-package installed with Composer.
Then create an admin account with "ddev typo3 backend:createadmin sven2209 SKom1970sven!".
Then create a packages folder.
Add the following to the composer.json:
----
{
	"version": "13.0.0",
	"authors": [
		{
			"name": "Sven Kalbhenn",
			"email": "sven@skom.de",
			"homepage": "http://www.skom.de/",
			"role": "Developer"
		}
	],
	"repositories": [
		{
			"type": "path",
			"url": "packages/*"
		},
		{
			"type": "composer",
			"url": "https://composer.typo3.org/"
		}
	],
}
----
Then create a TYPO3 sitepackage inside the packages folder with the name "skom/<projectname>_sitepackage".
Install vite-sidecar with "ddev get s2b/ddev-vite-sidecar".
Initialize npm with "ddev npm init"
Install vite with "ddev npm install --save-dev vite vite-plugin-typo3 vite-plugin-live-reload".
Install vite-asset-collector with "ddev composer req praetorius/vite-asset-collector".
Install node packages with "ddev npm install --save-dev sass bootstrap bootstrap-icons @popperjs/core".

## Removing a test project
```bash
ddev delete test --omit-snapshot
```
