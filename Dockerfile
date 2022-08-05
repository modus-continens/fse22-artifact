# Build like `docker build .`
# Run with `docker run -v /var/run/docker.sock:/var/run/docker.sock --privileged -it ...` so the 'top-level' Docker is used.
FROM docker:20.10.17-alpine3.16
RUN echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && apk update
RUN apk add --no-cache cargo gcompat curl ca-certificates nginx bash datamash@testing parallel fd git python3 py3-regex py3-scipy dpkg jq sed gawk
ENV PATH "/root/.cargo/bin:$PATH"
RUN cargo install modus --version 0.1.11

# Install gum for better entrypoint script
RUN wget 'https://github.com/charmbracelet/gum/releases/download/v0.4.0/gum_0.4.0_linux_x86_64.tar.gz'
RUN tar xf 'gum_0.4.0_linux_x86_64.tar.gz' gum --directory=/usr/bin

# Trust our self-signed certificate so curl and others won't complain.
COPY cert.pem /usr/local/share/ca-certificates/cert.crt
COPY cert.pem /etc/nginx/cert.pem
COPY key.pem /etc/nginx/key.pem
RUN cat /usr/local/share/ca-certificates/cert.crt >> /etc/ssl/certs/ca-certificates.crt

COPY nginx.conf /etc/nginx/nginx.conf

WORKDIR /openjdk-images-case-study/
RUN curl https://raw.githubusercontent.com/modus-continens/openjdk-images-case-study/ec0ca73649e91233b9440b438a03bcff5c13d89c/facts.Modusfile > facts.Modusfile
RUN curl https://raw.githubusercontent.com/modus-continens/openjdk-images-case-study/ec0ca73649e91233b9440b438a03bcff5c13d89c/linux.Modusfile > linux.Modusfile

WORKDIR /
RUN git clone https://github.com/docker-library/openjdk.git ./docker-library-openjdk && cd docker-library-openjdk && git checkout b5df7f69163346b6813883cd68bd2f43f82fd784
RUN git clone https://github.com/modus-continens/docker-hub-eval.git

COPY ./entrypoint.sh ./entrypoint.sh
