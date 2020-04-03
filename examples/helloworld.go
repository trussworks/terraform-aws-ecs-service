package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
)

type RequestLog struct {
	RemoteAddr    string              `json:"remote_addr"`
	Method        string              `json:"method"`
	RequestURI    string              `json:"request_uri"`
	Host          string              `json:"host"`
	ContentLength int64               `json:"content_length"`
	Header        map[string][]string `json:"header"`
	Protocol      string              `json:"protocol"`
}

func main() {
	port1, err := strconv.Atoi(os.Getenv("PORT1"))
	if err != nil {
		panic(err)
	}
	port2, err := strconv.Atoi(os.Getenv("PORT2"))
	if err != nil {
		panic(err)
	}

	finish := make(chan bool)

	server1 := http.NewServeMux()
	server1.HandleFunc("/", helloWorld)
	server2 := http.NewServeMux()
	server2.HandleFunc("/", helloWorld)

	go func() {
		log.Fatal(http.ListenAndServe(fmt.Sprintf(":%d", port1), server1))
	}()

	go func() {
		log.Fatal(http.ListenAndServe(fmt.Sprintf(":%d", port2), server2))
	}()

	<-finish
}

func helloWorld(w http.ResponseWriter, r *http.Request) {
	_, err := w.Write([]byte("Hello, world!\n"))
	if err != nil {
		log.Fatal(err)
	}
	requestLog := RequestLog{
		RemoteAddr:    r.RemoteAddr,
		Method:        r.Method,
		RequestURI:    r.RequestURI,
		Host:          r.Host,
		ContentLength: r.ContentLength,
		Header:        r.Header,
		Protocol:      r.Proto,
	}
	jsonLog, err := json.Marshal(requestLog)
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("%s\n", jsonLog)

}
