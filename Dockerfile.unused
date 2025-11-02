

# https://hub.docker.com/_/alpine/tags
FROM alpine:3.22 AS build
ARG TARGETARCH

RUN apk upgrade --no-cache
RUN apk add --no-cache alpine-sdk linux-headers git zlib-dev openssl-dev gperf cmake

RUN git clone --recursive https://github.com/tdlib/telegram-bot-api.git /tgbotserver
RUN ls -l -a /tgbotserver/ /tgbotserver/*/

RUN rm -r -f /tgbotserver/build && mkdir /tgbotserver/build
WORKDIR /tgbotserver/build/
RUN cmake -DCMAKE_SYSTEM_PROCESSOR=$TARGETARCH -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=/tgbotserver/ /tgbotserver/
RUN cmake --build . --target install

RUN ls -l -a /tgbotserver/*/



# https://hub.docker.com/_/alpine/tags
FROM alpine:3.22
RUN apk upgrade --no-cache
RUN apk add --no-cache openssl zlib libstdc++
RUN mkdir /tgbotserver/
WORKDIR /tgbotserver/
COPY --from=build /tgbotserver/bin/telegram-bot-api /tgbotserver/tgbotserver
RUN ls -l -a /tgbotserver/tgbotserver
ENTRYPOINT ["/tgbotserver/tgbotserver", "--http-port=80", "--local"]


