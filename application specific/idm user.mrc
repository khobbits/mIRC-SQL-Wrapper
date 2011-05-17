; This is a convience function to return a single cell from a table
alias db.user.get {
  tokenize 32 $replace($lower($1-),$chr(32) $+ $chr(32),$chr(32))
  if (!$3) { putlog Syntax Error: db.get.user <table> <column> <user> - $db.safe($1-) | halt }
  if (($1 == user) || (equip_ isin $1)) {
    if (($hget($3)) && ($hget($3,money))) { return $hget($3,$2) }
  }
  dbcheck

  var %sql = SELECT `user`, `userid`, $db.tquote($2) FROM `user_alt` LEFT JOIN $db.tquote($1) USING (`userid`) WHERE `user` = $db.safe($3)
  return $iif($db.select(%sql,$2) === $null,0,$v1)
}

alias db.user.id {
  if (!$1) { putlog Syntax Error: db.user.id <user> - $db.safe($1-) | halt }
  tokenize 32 $replace($lower($1-),$chr(32) $+ $chr(32),$chr(32)) 
  dbcheck
  var %sql = SELECT `user`, `userid` FROM `user_alt` WHERE `user` = $db.safe($1)
  return $iif($db.select(%sql,userid) === $null,0,$v1)
}

alias db.user.hash {
  if (!$3) { putlog Syntax Error: /db.hget <hashtable> <table> <user> [column list] - $db.safe($1-) | halt }
  tokenize 32 $replace($lower($1-3),$chr(32) $+ $chr(32),$chr(32)) $replace($lower($4-),$chr(32), ` $+ $chr(44) $+ `)
  var %htable = $1
  var %table = $2
  var %user = $3
  var %columns = $iif($4,`user` $+ $chr(44) $+ `userid` $+ $chr(44) $+ ` $+ $4 $+ `,*)

  dbcheck
  var %sql SELECT %columns FROM `user_alt` LEFT JOIN $db.tquote(%table) USING (`userid`) WHERE `user` = $db.safe(%user)
  var %result = $db.query(%sql)
  if ($db.query_row(%result,%htable) === $null) { return $null }
  db.query_end %result
  return 1
}

; This is the convience function used to write single values to the db or update an existing value
alias db.user.set {
  dbcheck
  tokenize 32 $replace($lower($1-),$chr(32) $+ $chr(32),$chr(32))
  if (($5 isnum) && (($4 == +) || ($4 == -))) {
    var %sql = INSERT INTO $db.tquote($1) ( userid , $db.tquote($2) ) VALUES ( ( SELECT `userid` FROM `user_alt` where `user` =  $db.safe($3) ), $db.safe($5-) ) ON DUPLICATE KEY UPDATE $db.tquote($2) = $db.tquote($2) $4 $db.safe($5-)
    if ((($1 == user) || (equip_ isin $1)) && ($hget($3))) { hadd $3 $2 $calc($hget($3,$2) $4 $5- ) }
    return $db.exec(%sql)
  }
  elseif (($3) && ($4 !== $null)) {
    var %sql = INSERT INTO $db.tquote($1) ( userid , $db.tquote($2) ) VALUES ( ( SELECT `userid` FROM `user_alt` where `user` =  $db.safe($3) ), $db.safe($4-) ) ON DUPLICATE KEY UPDATE $db.tquote($2) = $db.safe($4-)
    if ((($1 == user) || (equip_ isin $1)) && ($hget($3))) { hadd $3 $2 $4- }
    return $db.exec(%sql)
  }
  else {
    putlog Syntax Error: /db.set <table> <column> <user> <value> - $db.safe($1-)
    return 0
  }
} 

alias db.user.rem {
  dbcheck
  tokenize 32 $replace($lower($1-),$chr(32) $+ $chr(32),$chr(32))
  if ($4 !== $null) {

    var %sql = DELETE FROM $db.tquote($1) WHERE userid = (SELECT `userid` from `user_alt` WHERE `user` =  $db.safe($2)) AND $db.tquote($3) = $db.safe($4)
    return $db.exec(%sql)
  }
  elseif ($2 !== $null) {
    var %sql = DELETE FROM $db.tquote($1) WHERE userid = (SELECT `userid` from `user_alt` WHERE `user` =  $db.safe($2))
    return $db.exec(%sql)
  }
  else {
    putlog Syntax Error: /db.remove <table> <user> [<column> <value>] - $db.safe($1-)
    return 0
  }
}