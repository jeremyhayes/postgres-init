FROM alpine:3.15

RUN apk --no-cache add \
    bash \
    postgresql12-client

COPY docker-entrypoint.sh .

ENTRYPOINT [ "./docker-entrypoint.sh" ]
