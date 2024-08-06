
# https://hub.docker.com/_/alpine/tags
FROM alpine:3.20.2 as build

RUN apk update && apk upgrade
RUN apk add --no-cache alpine-sdk linux-headers git zlib-dev openssl-dev gperf cmake

RUN git clone --recursive https://github.com/tdlib/telegram-bot-api.git tgbotserver
RUN cd tgbotserver

RUN rm -r -f build && mkdir build && cd build
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=.. ..
RUN cmake --build . --target install

RUN cd ../..
RUN ls -l -a tgbotserver/*/



# https://hub.docker.com/_/alpine/tags
FROM alpine:3.20.2

COPY --from=build /root/tgbotserver /opt/tgbotserver

