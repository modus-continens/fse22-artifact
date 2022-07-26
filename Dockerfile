# Build like `docker build .`
# Run with `docker run -v /var/run/docker.sock:/var/run/docker.sock --privileged -it ...` so the 'top-level' Docker is used.
FROM docker:20.10.17-alpine3.16
RUN apk add --no-cache cargo gcompat curl ca-certificates nginx bash
ENV PATH "/root/.cargo/bin:$PATH"
RUN cargo install modus --version 0.1.11

# Trust our self-signed certificate so curl and others won't complain.
COPY cert.pem /usr/local/share/ca-certificates/cert.crt
COPY cert.pem /etc/nginx/cert.pem
COPY key.pem /etc/nginx/key.pem
RUN cat /usr/local/share/ca-certificates/cert.crt >> /etc/ssl/certs/ca-certificates.crt

COPY nginx.conf /etc/nginx/nginx.conf
COPY ./data /data

WORKDIR /openjdk-images-case-study/
RUN curl https://raw.githubusercontent.com/modus-continens/openjdk-images-case-study/ec0ca73649e91233b9440b438a03bcff5c13d89c/facts.Modusfile > facts.Modusfile
RUN curl https://raw.githubusercontent.com/modus-continens/openjdk-images-case-study/ec0ca73649e91233b9440b438a03bcff5c13d89c/linux.Modusfile > linux.Modusfile

COPY ./entrypoint.sh ./entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]

# TODO:
# Copy over other relevant files, e.g. case study
