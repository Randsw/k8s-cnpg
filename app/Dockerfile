FROM golang:1.26 AS builder
WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY . .

RUN CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build -a -o server main.go

FROM gcr.io/distroless/static:nonroot
WORKDIR /
COPY --from=builder /workspace/server .
EXPOSE 8080
CMD ["./server"]
