FROM postgres:12-alpine

COPY docker-entrypoint.sh .

ENTRYPOINT [ "./docker-entrypoint.sh" ]
