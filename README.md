# postgres-init

A containerized script to provision a new database and user on a Postgres instance. Ideal for running as a k8s init container or other orchestration setup.

## Build

```sh
docker build --tag postgres-init:v0.0.1 -d ./Dockerfile .
```

## Configuration

Parameter | Required | Default | Description
--- | --- | --- | ---
`PG_HOST` | Y | | The hostname or IP address of the target Postgres instance
`PG_PORT` | N | 5432 | The port of the target Postgres instance.
`PG_USERNAME` | N | postgres | The username of Postgres user with DDL privileges.
`PG_PASSWORD` | Y | | The password of Postgres user with DDL privileges.
`PG_PASSWORD_FILE` | N | | The `PG_PASSWORD` parameter, supplied as a file (via Docker secrets).
`DB_USERNAME` | Y | | The database and username to be created.
`DB_PASSWORD` | Y | | The password for the user to be created.
`DB_PASSWORD_FILE` | N | | The `DB_PASSWORD` parameter, supplied as a file (via Docker secrets).

## Examples

### Standalone
```sh
docker run \
  --rm \
  --env PG_HOST=host.docker.internal \
  --env PG_PORT=5432 \
  --env PG_USERNAME=postgres \
  --env PG_PASSWORD=pgadmin \
  --env DB_USERNAME=mynewdatabase \
  --env DB_PASSWORD=mynewpassword \
  postgres-init:v0.0.1
```

### Docker compose/swarm
```yaml
services:

  postgres:
    image: postgres:16-alpine
    ports:
      - 5432:5432
    environment:
      - POSTGRES_PASSWORD=pgadmin

  postgres-init:
    image: postgres-init:v0.0.1
    environment:
      - PG_HOST=host.docker.internal
      - PG_PORT=5432
      - PG_USERNAME=postgres
      - PG_PASSWORD=pgadmin
      - DB_USERNAME=mynewdatabase
      - DB_PASSWORD=mynewpassword
```

### Docker compose/swarm w/ secrets
```yaml
services:

  postgres-init:
    image: postgres-init:v0.0.1
    secrets:
      - pg_password
      - db_password
    environment:
      - PG_HOST=host.docker.internal
      - PG_PORT=5432
      - PG_USERNAME=postgres
      - PG_PASSWORD_FILE=/run/secrets/pg_password
      - DB_USERNAME=mynewdatabase
      - DB_PASSWORD_FILE=/run/secrets/db_password

secrets:
  pg_password:
    external: true
  db_password:
    external: true
```

### Kubernetes init container
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
  labels:
    app.kubernetes.io/name: MyApp
spec:

  # Some app that needs a Postgres database
  containers:
  - name: myapp-container
    image: busybox:1.28

  # DB init container to ensure database is created before app starts
  initContainers:
  - name: init-db
    image: postgres-init:v0.0.1
    env:
    - name: PG_HOST
      value: host.docker.internal
    - name: PG_PORT
      value: 5432
    - name: PG_USERNAME
      value: postgres
    - name: PG_PASSWORD
      value: pgadmin
    - name: DB_USERNAME
      value: mynewdatabase
    - name: DB_PASSWORD
      value: mynewpassword
```

> NOTE: For illustrative purposes only. Production code should likely use ConfigMaps and/or Secrets.
