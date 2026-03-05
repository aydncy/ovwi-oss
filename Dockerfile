FROM dart:3.3-stable AS build
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart compile exe bin/server.dart -o bin/server
FROM alpine:latest
RUN apk --no-cache add ca-certificates wget
WORKDIR /root/
COPY --from=build /app/bin/server .
EXPOSE 8080
CMD ["./server"]
