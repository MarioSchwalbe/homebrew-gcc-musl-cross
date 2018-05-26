FROM scratch

WORKDIR /
ADD test-x86_64-linux-musl .
CMD ["/test-x86_64-linux-musl"]
