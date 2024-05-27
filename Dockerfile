FROM alpine:3.20

RUN apk --no-cache add \
    bash \
    postgresql16-client

COPY --chmod=0755 docker-entrypoint.sh .

ENTRYPOINT [ "./docker-entrypoint.sh" ]
