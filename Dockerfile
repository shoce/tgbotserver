
# https://hub.docker.com/_/alpine/tags
FROM alpine:3.20.2 as build

RUN apk upgrade --no-cache
RUN apk add --no-cache alpine-sdk linux-headers git zlib-dev openssl-dev gperf cmake

RUN cd /root/
RUN git clone --recursive https://github.com/tdlib/telegram-bot-api.git /root/tgbotserver
RUN cd /root/tgbotserver
RUN ls -l -a /root/tgbotserver/ /root/tgbotserver/*/

RUN rm -r -f /root/tgbotserver/build && mkdir /root/tgbotserver/build && cd /root/tgbotserver/build
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=/root/tgbotserver/ /root/tgbotserver/
RUN cmake --build . --target install

RUN cd /root/
RUN ls -l -a /root/tgbotserver/*/



# https://hub.docker.com/_/alpine/tags
FROM alpine:3.20.2
RUN apk upgrade --no-cache
RUN apk add --no-cache openssl zlib libstdc++
COPY --from=build /root/tgbotserver/bin/telegram-bot-api /opt/tgbotserver/tgbotserver
WORKDIR /opt/tgbotserver/
ENTRYPOINT ["/opt/tgbotserver/tgbotserver", "--http-port=80", "--local", "--log=/dev/stdout"]

