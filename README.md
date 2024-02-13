# WordPress Local Docker (WLD)

Yes, just another WordPress ~~Site~~ Local Docker environment. I wanted to create something:
* Lightweight
* Dependency free
* Takes care of common installation workflows for different architectures i.e. Multisite

## Prerequisites

- Docker: https://docs.docker.com/get-docker/
- Docker Compose: https://docs.docker.com/compose/install/

## Installation

1. **Clone the Repository**

```bash
git clone https://github.com/jaredrethman/wld.git
cd wld
```

## Scaffold a site

```bash
sh wld scaffold
```
Answer prompts and/or hit enter/return to select defaults. Once you've responded to last prompt, you should see something resembling below

![WLD Scaffold](/docs/scaffold.png "WLD Scaffold")

