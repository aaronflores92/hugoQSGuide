FROM ubuntu:latest
WORKDIR ~/quickStart
COPY . .
RUN apt update -y
RUN apt install wget -y
RUN wget https://github.com/gohugoio/hugo/releases/download/v0.134.2/hugo_extended_0.134.2_linux-amd64.tar.gz && \
    tar -xvzf hugo_extended_0.134.2_linux-amd64.tar.gz && \
    chmod +x hugo && \
    mv hugo /usr/local/bin/hugo && \
    rm -f hugo_extended_0.134.2_linux-amd64.tar.gz && \
    which hugo && \
    sleep 3
RUN hugo version && \
    hugo && \
    ls -l && \
    sleep 5
VOLUME [ "/public" ]
