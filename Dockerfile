# https://resin.io/blog/building-arm-containers-on-any-x86-machine-even-dockerhub/
# https://docs.docker.com/engine/reference/builder/

FROM alpine:latest
WORKDIR /

# install qemu and copy test app
ARG QEMU
RUN apk --no-cache add ${QEMU}
ARG APP
ADD ${APP} .

# CMD does not expand ARG
ENV QEMU=${QEMU}
ENV APP=${APP}
ENTRYPOINT exec ${QEMU} -0 ${APP} ${APP}
