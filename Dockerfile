# build datasette

FROM python:3 as installer

# https://github.com/simonw/datasette
RUN pip wheel --wheel-dir=/wheels datasette datasette-cluster-map

# generate database

FROM python:3 as builder

# https://github.com/simonw/csvs-to-sqlite
RUN pip install csvs-to-sqlite

WORKDIR /data

COPY urls.txt .
RUN wget --input-file=urls.txt

# TODO: pass separator as build argument
RUN csvs-to-sqlite *.csv data.db --separator '¬' --skip-errors

# serve application

FROM python:3-slim

COPY --from=installer /wheels /wheels

RUN pip install --no-index --find-links=/wheels datasette datasette-cluster-map

WORKDIR /data

COPY --from=builder /data/data.db .

RUN datasette inspect data.db --inspect-file inspect-data.json

# TODO: use $PORT
CMD ["datasette", "serve", "data.db", "--host", "0.0.0.0", "--cors", "--port", "8080", "--inspect-file", "inspect-data.json"]
