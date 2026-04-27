FROM golang:1.26-alpine AS builder
WORKDIR /app
COPY . .
RUN go mod init app && go get ./... && go build -o server .

FROM alpine:latest
WORKDIR /root/
COPY --from=builder /app/server .
EXPOSE 8080
CMD ["./server"]
