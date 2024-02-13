# WordPress Local Docker (WLD)

Yes, just another WordPress ~~Site~~ Local Docker environment. I wanted to create something:
* Lightweight
* Dependency free
* Takes care of common installation workflows for different architectures i.e. Multisite

## Prerequisites

- Docker: https://docs.docker.com/get-docker/
- Docker Compose: https://docs.docker.com/compose/install/

## Scaffold a site
Once you've cloned this repo, `cd` into it and scaffold a site.
```bash
sh wld scaffold
```
Answer prompts and/or hit enter/return to select defaults. Once you've responded to last prompt, you should see something resembling below

![WLD Scaffold](/docs/scaffold.png "WLD Scaffold")

If you're happy with the details, respond with `y`. This will:
* Create a local file system inside `./sites` using the domain you specified.
* Generate necessary certs, macOS or mkcert required.
* Generate site specific Nginx conf.
* Build docker-compose or restart the nginx container.