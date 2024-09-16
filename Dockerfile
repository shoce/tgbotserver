
# https://hub.docker.com/_/alpine/tags
FROM alpine:3.20.3 as build-amd64

RUN apk upgrade --no-cache
RUN apk add --no-cache alpine-sdk linux-headers git zlib-dev openssl-dev gperf cmake

RUN cd /root/
RUN git clone --recursive https://github.com/tdlib/telegram-bot-api.git /root/tgbotserver
RUN cd /root/tgbotserver
RUN ls -l -a /root/tgbotserver/ /root/tgbotserver/*/

RUN rm -r -f /root/tgbotserver/build && mkdir /root/tgbotserver/build && cd /root/tgbotserver/build
RUN cmake -DCMAKE_SYSTEM_PROCESSOR=amd64 -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=/root/tgbotserver/ /root/tgbotserver/
RUN cmake --build . --target install

RUN cd /root/
RUN ls -l -a /root/tgbotserver/*/



# https://hub.docker.com/_/alpine/tags
FROM alpine:3.20.3 as build-aarch64

RUN apk upgrade --no-cache
RUN apk add --no-cache alpine-sdk linux-headers git zlib-dev openssl-dev gperf cmake

RUN cd /root/
RUN git clone --recursive https://github.com/tdlib/telegram-bot-api.git /root/tgbotserver
RUN cd /root/tgbotserver
RUN ls -l -a /root/tgbotserver/ /root/tgbotserver/*/

RUN rm -r -f /root/tgbotserver/build && mkdir /root/tgbotserver/build && cd /root/tgbotserver/build
RUN cmake -DCMAKE_SYSTEM_PROCESSOR=aarch64 -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=/root/tgbotserver/ /root/tgbotserver/
RUN cmake --build . --target install

RUN cd /root/
RUN ls -l -a /root/tgbotserver/*/



# https://hub.docker.com/_/alpine/tags
FROM alpine:3.20.3
RUN apk upgrade --no-cache
RUN apk add --no-cache openssl zlib libstdc++
COPY --from=build-amd64 /root/tgbotserver/bin/telegram-bot-api /opt/tgbotserver/tgbotserver.amd64
COPY --from=build-aarch64 /root/tgbotserver/bin/telegram-bot-api /opt/tgbotserver/tgbotserver.aarch64
WORKDIR /opt/tgbotserver/
ENTRYPOINT ["/opt/tgbotserver/tgbotserver", "--http-port=80", "--local", "--log=/dev/stdout"]


