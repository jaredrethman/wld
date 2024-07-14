# WordPress Local Docker (WLD)

Yes, just another WordPress ~~Site~~ Local Docker environment. I wanted to create something:
* Lightweight.
* Dependency free.
* Takes care of common installation workflows for different architectures i.e. Multisite.
* Easily scaffold a `wp-content` only version controlled project.

### Prerequisites

- Docker: https://docs.docker.com/get-docker/
- Docker Compose v2: https://docs.docker.com/compose/install/

## Usage

Once you've cloned this repo, `cd` into it.<!--, then manually, or automatically, start-up a new site using one of the strategies below.-->

### `wld scaffold`
This is the automated (Recommended) approach.

```bash
sh wld scaffold
```
Answer prompts and/or hit enter/return to select defaults. Once you've responded to last prompt, you should see something resembling below.

![WLD Scaffold](/docs/scaffold.png "WLD Scaffold")

If you're happy with the details, respond with `y`. This will:
* Create a directory, housing your sites local file system, inside `./sites` using the domain you specified.
* Prompt for password and/or boimetric authentication to generate necessary certs. NB: macOS or [mkcert](https://github.com/FiloSottile/mkcert) required.
* Generate site specific Nginx conf.
* Build docker-compose or restart the nginx container.

Once above has concluded you should see the below in your terminal.
> Site created, visit: https://test.local/wp-admin

### WP CLI
For ease of use, a command for submitting [WP CLI](https://wp-cli.org/) commands to the relevant site on the PHP container was created. 

```bash
wld site test.local -- wp user list
# Or from within a `sites/test.local` directory
wld -- wp user list
```
VS.
```bash
docker compose exec php wp user list --allow-root --path="/var/www/html/test.local"
```

### Beware:
* Only subdomain Multisite is supported in `wld scaffold`
* Cert generation can only be done on macOS or if [mkcert](https://github.com/FiloSottile/mkcert) is installed
* All WordPress sites run on the same Nginx/PHP services. This might change in the future i.e. different PHP/Nginx versions per/site. This is technically possible, but would require manual intervention and remove ablity to stay in sync with this code base.