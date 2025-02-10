

# https://hub.docker.com/_/alpine/tags
FROM alpine:3.21.2 AS build
ARG TARGETARCH
WORKDIR /root/

RUN apk upgrade --no-cache
RUN apk add --no-cache alpine-sdk linux-headers git zlib-dev openssl-dev gperf cmake

RUN git clone --recursive https://github.com/tdlib/telegram-bot-api.git /root/tgbotserver
RUN cd /root/tgbotserver
RUN ls -l -a /root/tgbotserver/ /root/tgbotserver/*/

RUN rm -r -f /root/tgbotserver/build && mkdir /root/tgbotserver/build && cd /root/tgbotserver/build
RUN cmake -DCMAKE_SYSTEM_PROCESSOR=$TARGETARCH -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=/root/tgbotserver/ /root/tgbotserver/
RUN cmake --build . --target install

RUN ls -l -a /root/tgbotserver/*/



# https://hub.docker.com/_/alpine/tags
FROM alpine:3.21.2
RUN apk upgrade --no-cache
RUN apk add --no-cache openssl zlib libstdc++
COPY --from=build /root/tgbotserver/bin/telegram-bot-api /bin/tgbotserver
RUN ls -l -a /bin/tgbotserver
WORKDIR /root/
ENTRYPOINT ["/bin/tgbotserver", "--http-port=80", "--local"]


