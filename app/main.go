package main

import (
	"database/sql"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"os"
)

type Entry struct {
	Team    string
	Year    string
	Manager string
}

type PageData struct {
	Entries []Entry
}

var(
    writeDB *sql.DB
    readDB  *sql.DB
    tmpl = template.Must(template.New("page").Parse(`
<!DOCTYPE html>
<html>
<head><title>App</title></head>
<body>
<form method="POST" action="/save">
Team: <input type="text" name="team"><br>
Year: <input type="text" name="year"><br>
Manager: <input type="text" name="manager"><br>
<button type="submit">Save</button>
</form>
<form method="GET" action="/list"><button type="submit">List</button></form>
{{if .Entries}}
<table border="1">
<tr><th>Team</th><th>Year</th><th>Manager</th></tr>
{{range .Entries}}
<tr><td>{{.Team}}</td><td>{{.Year}}</td><td>{{.Manager}}</td></tr>
{{end}}
</table>
{{end}}
</body>
</html>
`))
)

func main() {
	var err error
	// Connection string expected via environment variable DATABASE_URL
	user := os.Getenv("POSTGRESQL_USER")
	pass := os.Getenv("POSTGRESQL_PASSWORD")
	writeURL := os.Getenv("POSTGRESQL_URL")
	if user == "" || pass == "" || writeURL == "" {
		log.Fatal("Missing required POSTGRESQL env vars for write")
	}
	writeDSN := fmt.Sprintf("postgres://%s:%s@%s?sslmode=disable", user, pass, writeURL)
	writeDB, err = sql.Open("pgx", writeDSN)
	if err != nil {
		log.Fatalf("write db open error: %v", err)
	}
	defer writeDB.Close()

	readURL := os.Getenv("POSTGRESQL_URL_R")
	if readURL == "" {
		log.Fatal("Missing POSTGRESQL_URL_R env var for read")
	}
	readDSN := fmt.Sprintf("postgres://%s:%s@%s?sslmode=disable", user, pass, readURL)
	readDB, err = sql.Open("pgx", readDSN)
	if err != nil {
		log.Fatalf("read db open error: %v", err)
	}
	defer readDB.Close()

	// Ensure table exists
	_, err = writeDB.Exec(`CREATE TABLE IF NOT EXISTS entries (team TEXT, year TEXT, manager TEXT)`)
	if err != nil {
		log.Fatalf("create table: %v", err)
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		tmpl.Execute(w, nil)
	})
	http.HandleFunc("/save", saveHandler)
	http.HandleFunc("/list", listHandler)

	fmt.Println("Listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

func saveHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Redirect(w, r, "/", http.StatusSeeOther)
		return
	}
	entry := Entry{Team: r.FormValue("team"), Year: r.FormValue("year"), Manager: r.FormValue("manager")}
	_, err := writeDB.Exec(`INSERT INTO entries (team, year, manager) VALUES ($1,$2,$3)`, entry.Team, entry.Year, entry.Manager)
	if err != nil {
		http.Error(w, "DB error", http.StatusInternalServerError)
		return
	}
	http.Redirect(w, r, "/", http.StatusSeeOther)
}

func listHandler(w http.ResponseWriter, r *http.Request) {
	rows, err := readDB.Query(`SELECT team, year, manager FROM entries`)
	if err != nil {
		http.Error(w, "DB error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	var entries []Entry
	for rows.Next() {
		var e Entry
		if err := rows.Scan(&e.Team, &e.Year, &e.Manager); err != nil {
			continue
		}
		entries = append(entries, e)
	}
	tmpl.Execute(w, PageData{Entries: entries})
}
