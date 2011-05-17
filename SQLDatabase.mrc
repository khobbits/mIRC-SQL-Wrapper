alias dbcheck {
  if (!%db) {
    dbinit
  }
}

; Secures the db from exploits through injection.
alias db.safe {
  var %psafe $strip($lower($1-))
  if (%psafe === $null) putlog NULL Input - $1
  var %safe $mysql_qt($mysql_real_escape_string(%db,%psafe))
  if (!%safe) putlog NULL DB.SAFE - $1
  return %safe
}

; Adds the quotes around a table or column define
alias db.tquote {
  return ` $+ $lower($1-) $+ `
}

; This is a convience function to return a single cell from a table
alias db.get {
  tokenize 32 $replace($lower($1-),$chr(32) $+ $chr(32),$chr(32))
  if (!$4) { putlog Syntax Error: db.get <table> <column> <match col> <match data> - $db.safe($1-) | halt }
  dbcheck

  var %sql = SELECT $db.tquote($2) FROM $db.tquote($1) WHERE $db.tquote($3) = $db.safe($4)
  return $iif($db.select(%sql,$2) === $null,0,$v1)
}

; This function retrieves a single cell from a database and returns the value
alias db.select {
  if (!$2) { putlog Syntax Error: db.select <sql> <column> - $db.safe($1-) | halt }
  var %fail 0
  :dbselect
  dbcheck
  var %sql = $1
  var %col = $2
  var %request = $mysql_query(%db, %sql)
  if (%request) {
    var %result = $mysql_result(%request, %col)
    mysql_free %request
    if (%debugq == $me) echo 12 -s Query %sql returned %result
    return %result
  }
  else {
    inc %fail
    if (%fail < 3) goto dbselect
    mysqlderror %mysql_errno Error executing query: %mysql_errstr - %mysql_errno - Query %sql
    return $null
  }
}

alias db.hash {
  if (!$3) { putlog Syntax Error: /db.hash <hashtable> <table> <matchtext> <first column> [columns 2+] - $db.safe($1-) | halt }
  tokenize 32 $replace($lower($1-3),$chr(32) $+ $chr(32),$chr(32)) $4 $iif($5,$replace($lower($4-),$chr(32), ` $+ $chr(44) $+ `),*)
  var %htable = $1
  var %table = $2
  var %match = $3
  var %matchcol = $4
  var %columns = $5
  if (%columns != *) { var %columns $db.tquote(%columns) }

  dbcheck
  var %sql SELECT %columns FROM $db.tquote(%table) WHERE $db.tquote(%matchcol) = $db.safe(%match)
  var %result = $db.query(%sql)
  if ($db.query_row(%result,%htable) === $null) { return $null }
  db.query_end %result
  return 1
}

; These functions are used to get more complicated results from the db
alias db.query {
  if (!$1) { putlog Syntax Error: db.query <sql> $db.safe($1-) | halt }
  var %fail 0
  :dbquery
  dbcheck
  var %sql = $1-
  var %request = $mysql_query(%db, %sql)
  if (%request) {
    if (%debugq == $me) echo 12 -s Query %sql returned token %request
    return %request
  }
  else {
    inc %fail
    if (%fail < 3) goto dbquery
    mysqlderror %mysql_errno Error executing query: %mysql_errstr - %mysql_errno - Query %sql
    return $null
  }
}

alias db.query_row_data {
  var %request = $1
  var %col = $2
  var %result = $mysql_fetch_field( %request, %col )
  if (%debugq == $me) echo 12 -s Fetched column %col - Result %result
  return %result
}

alias db.query_row {
  var %request = $1
  var %htable = $2
  if ($hget(%htable)) hfree %htable
  var %result = $mysql_fetch_row( %request, %htable )
  return %result
}

alias db.query_num_rows {
  var %request = $1
  var %result = $mysql_num_rows(%request)
  return %result
}

alias db.query_end {
  var %request = $1
  mysql_free %request
}

alias db.set {
  dbcheck
  tokenize 32 $replace($lower($1-),$chr(32) $+ $chr(32),$chr(32))
  if (($6 isnum) && (($5 == +) || ($5 == -))) {
    var %sql = INSERT INTO $db.tquote($1) ( $db.tquote($3) , $db.tquote($2) ) VALUES ( $db.safe($4) , $db.safe($6-) ) ON DUPLICATE KEY UPDATE $db.tquote($2) = $db.tquote($2) $5 $db.safe($6-)
    return $db.exec(%sql)
  }
  elseif ($5 !== $null) {
    var %sql = INSERT INTO $db.tquote($1) ( $db.tquote($3) , $db.tquote($2) ) VALUES ( $db.safe($4) , $db.safe($5-) ) ON DUPLICATE KEY UPDATE $db.tquote($2) = $db.safe($5-)
    return $db.exec(%sql)
  }
  else {
    putlog Syntax Error: /db.set <table> <column> <match col> <match text> <value> - $db.safe($1-)
    return 0
  }
} 

alias db.rem {
  dbcheck
  tokenize 32 $replace($lower($1-),$chr(32) $+ $chr(32),$chr(32))
  if ($5 !== $null) {
    var %sql = DELETE FROM $db.tquote($1) WHERE $db.tquote($2) = $db.safe($3) AND $db.tquote($4) = $db.safe($5)
    return $db.exec(%sql)
  }
  elseif ($3 !== $null) {
    var %sql = DELETE FROM $db.tquote($1) WHERE $db.tquote($2) = $db.safe($3)
    return $db.exec(%sql)
  }
  else {
    putlog Syntax Error: /db.remove <table> [<column> <value>] - $db.safe($1-)
    return 0
  }
}

alias db.clear {
  dbcheck
  tokenize 32 $replace($lower($1-),$chr(32) $+ $chr(32),$chr(32))
  if ($2 !== $null) {
    var %sql UPDATE $db.tquote($1) SET $db.tquote($2) = 0 $iif($3,WHERE $db.tquote($2) = $db.safe($3))
    return $db.exec(%sql)
  }
  else {
    putlog Syntax Error: /db.clear <table> <column> [value] - $db.safe($1-)
    return 0
  }
}

; This is the raw db exec function used to run any sql
alias db.exec {
  if (!$1) { putlog Syntax Error: db.exec <sql> - $db.safe($1-) | halt }
  var %fail 0
  :dbexec
  dbcheck
  if (!$isid || !$2) {
    var %sql = $1-
    if (!$mysql_exec(%db, %sql)) {
      inc %fail
      if (%fail < 3) goto dbexec
      mysqlderror %mysql_errno Error executing query: %mysql_errstr - %mysql_errno - Query %sql
      return $null
    }
  }
  else {
    var %sql = $1
    if (!$mysql_exec(%db, %sql, $2, $3, $4, $5, $6, $7, $8, $9)) {
      inc %fail
      if (%fail < 3) goto dbexec
      mysqlderror %mysql_errno Error executing query: %mysql_errstr - %mysql_errno - Query %sql - $2-
      return $null
    }  
  }
  if (%debugq == $me) echo 12 -s Query %sql executed
  return 1
}


alias mysqlderror {
  echo 4 -s $2-
  putlog 3BotError - $me $+ 4 $2- 
  if (($1 == 3000) || ($1 == 1)) { dbinit }
  mysql_ping %db
}

on *:START: {
  unset %db
  load -rs " $+ $mircdirmysql/mmysql.mrc"
  dbinit
}

alias dbinit {
  mysql_close %db
  unset %db
  var %host = localhost
  var %user = user
  var %pass = pass
  var %database = database

  set %db $mysql_connect(%host, %user, %pass)
  if (!%db) {
    var %bk_mysql_errno %mysql_errno
    var %bk_mysql_errstr %mysql_errstr
    if (%dbfail <= 4) { mysqlderror Error: %mysql_errstr - %mysql_errno }
    if (%dbfail == 4) { putlog 4Error: %bk_mysql_errstr - %bk_mysql_errno 4,1[BOT DISABLED] }
    if (%bk_mysql_errno isnum 1000-2999) { inc %dbfail 1 | halt }
    return
  }
  else {
    if (!$mysql_select_db(%db, %database)) {
      putlog Failed selecting database %database
      mysql_close %db
      inc %dbfail 1
      halt
    }
    set %dbfail 0
    if (!timer(dbinit)) timerdbinit off
    putlog MySQL Connection Established.
  }
}

alias putlog {
  echo 4 -s MYSQL: $1-
} 