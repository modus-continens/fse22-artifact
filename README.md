TODO for submission:
- PDF abstract
- README describing what the artifact does, where obtainable, and how to repeat paper results.
- REQUIREMENTS file, what hardware/software needed.
- STATUS file saying what badges applying for.
- LICENSE file
- INSTALL file, with installation instructions
- Copy of accepted paper

# Modus Artifact - Overview

Our artifact provides a Dockerfile used to build a container image with the relevant programs and data to build the images relevant to our case study, using Modus and Docker.
This is enabled using [Docker in Docker](https://hub.docker.com/_/docker).

We have considered a balance between deviating from the original source (Zenodo submission) and getting a working artifact. 
This consideration is necessary primarily because some of the links we used are no longer available.
Therefore, we:
- Serve some binaries locally (using nginx), and perform a search and replace on our source files to point to localhost where needed.
- Remove checks that verify the `sha256sum` of binaries, since some binaries are no longer fetched from the original endpoint.

Note that this would reduce the build time, because serving locally reduces the delay from fetching over the network.

# Reproducing the Main Results

TODO
