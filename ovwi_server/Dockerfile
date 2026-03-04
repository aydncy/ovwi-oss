FROM dart:stable

WORKDIR /app

COPY . .

RUN dart pub get
RUN dart compile exe bin/server.dart -o server

EXPOSE 8080

CMD ["./server"]
