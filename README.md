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

# Acquiring the Artifact

You may acquire the artifact from GitHub. 

Simply `git clone https://github.com/modus-continens/fse22-artifact.git && cd fse22-artifact`, ready to run.

# Reproducing the Main Results

The following command will have side effects, read [this](#side-effects) first.

1. Assuming the [requirements](./REQUIREMENTS) are met and you're in the artifact repo's main directory, run the script with `./run.sh`.
This will set up Docker in Docker and execute an interactive script.
2. The main results are the build times for building OpenJDK images, and the other Docker Hub images.
First, select `OpenJDK - Build Images`, and enter `n = 10` runs. This may take about 2-3 hours.
3. Select `Docker Hub Evaluation`, and enter `n = 10` runs. This may also take about 2-3 hours.

The results are stored in a `benchmarks/` directory, accessible after the container exits.

## Side Effects

The Docker commands executed by the script will have side effects, including deleting any unused `volumes`, creating new `volume`s, removing any containers named `dind-docker`. 
This is likely safe to do on your host machine (you do not *need* a VM), unless you happen to be using Docker volumes, networks, or containers that match the names used in our script and do not want these changes.
Skim through the script `run.sh` to verify this.

# Validating Results

Our artifact script produces data relevant to different sections of our paper.
- The `OpenJDK - Build Images` choice will generate CSV data similar to Table 5 of our paper.
The computed build times would be consistently shorter than in the paper, because half of the binaries are served locally, as described above.
On a similar machine to that mentioned in the paper (AWS' c5.2xlarge), you should be able to validate the claim that Modus is faster overall, that is, including the template processing time.
- The `OpenJDK - Code Size` choice will generate data similar to Table 4 of our paper.
Refer to Table 4 to understand the output format, it matches that of the `wc` command.
We use a slightly different version of the code repositories in this artifact, so the code size data differs.
You should still be able to validate the claim that Modus uses far fewer words than DOBS.
- The `Docker Hub Evaluation` choice will generate data similar to Table 3 of our paper.
