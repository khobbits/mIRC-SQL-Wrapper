on $*:TEXT:/^[!@.](w|l)?top/Si:#: {
  if (# == #idm || # == $staffchan) && ($me != iDM) { halt }
  if ($isbanned($nick)) { halt }
  if ($update) { notice $nick $logo(ERROR) iDM is currently disabled, please try again shortly | halt }
  var %display = $iif(@* iswm $1,msgsafe $chan,notice $nick)
  tokenize 32 $1- 12
  if ($2 !isnum 1-12) { %display $logo(ERROR) The maximum number of users you can lookup is 12. Syntax: !top 12 | halt }
  if (w isin $1) { var %table wins }
  elseif (l isin $1) { var %table losses }
  else { var %table money }
  var %output $toplist(%table,$2,1)

  %display $logo(TOP %table) Total DM's: $s2($bytes($totalwins,bd)) %output
}

alias totalwins {
  var %sql SELECT sum(wins) as totalwins FROM `user`
  var %result = $db.query(%sql)
  if ($db.query_row(%result,>totalwins) === $null) { echo -s Error fetching total wins. - %sql }
  db.query_end %result
  return $hget(>totalwins,totalwins)
}

alias toplist {
  ; $1 = table
  ; $2 = number to show
  ; $3 = toggle on using K/M/B
  var %output, %i = 0
  var %sql = SELECT * FROM user u JOIN ( SELECT * FROM user_alt ) ua USING (userid) WHERE banned = '0' AND exclude = '0' GROUP BY userid ORDER BY $db.tquote($1) +0 DESC LIMIT $2
  var %result = $db.query(%sql)

  while ($db.query_row(%result,>row)) {
    inc %i
    %output = %output $chr(124) %i $+ . $s1($hget(>row,user))

    if ($3 == 1) { %output = %output $s2($price($hget(>row,$1))) }
    else { %output = %output $s2($bytes($hget(>row,$1),db)) }
  }
  db.query_end %result
  return %output
}

on $*:TEXT:/^[!@.]dmrank/Si:#: {
  tokenize 32 $1- $nick
  if (# == #idm || # == $staffchan) && ($me != iDM) { halt }
  if ($isbanned($nick)) { halt }
  if ($update) { notice $nick $logo(ERROR) iDM is currently disabled, please try again shortly | halt }
  var %display = $iif(@* iswm $1,msgsafe $chan,notice $nick)
  if ($2 isnum) {
    var %money = $ranks(money,$2)
    var %wins = $ranks(wins,$2)
    var %losses = $ranks(losses,$2)
    var %output = $logo(RANK) $+ $isbanned($2) $s1(Money) $+ : $s2($gettok(%money,1,58)) (with $price($gettok(%money,2,58)) $+ ) $s1(Wins) $+ : $s2($gettok(%wins,1,58)) (with $gettok(%wins,2,58) $+ ) $s1(Losses) $+ : $s2($gettok(%losses,1,58)) (with $gettok(%losses,2,58) $+ )
  }
  else {
    var %money = $ranks(money,$2)
    var %nextmoney = $price($calc($gettok($ranks(money,$calc(%money -1)),2,58) - $db.user.get(user,money,$2)))
    var %wins = $ranks(wins,$2)
    var %nextwins = $calc($gettok($ranks(wins,$calc(%wins -1)),2,58) - $db.user.get(user,wins,$2))
    var %losses = $ranks(losses,$2)
    var %nextlosses = $calc($gettok($ranks(losses,$calc(%losses -1)),2,58) - $db.user.get(user,losses,$2))

    var %output = $logo($2) $+ $isbanned($2) $s1(Money) $+ : $s2($ord(%money)) $iif(%money == 1,(\o/),( $+ %nextmoney for rank up)) $s1(Wins) $+ : $s2($ord(%wins)) $iif(%wins == 1,(\o/),( $+ %nextwins for rank up)) $s1(Losses) $+ : $s2($ord(%losses)) $iif(%losses == 1,(\o/),( $+ %nextlosses for rank up))
  }
  if (%output == $null) {
    notice $nick Syntax: !rank <name>/<1 - 10000>
  }
  else {
    %display %output
  }
}

alias isbanned {
  if ($0 != 1) { putlog Error: missing param $isbanned() }
  if ($checkisbanned($1) == 1) {
    hadd -mu120 >banned $1 1
    return 4 [Account Banned]
  }
  return
}

alias checkisbanned {
  if ($hget(>banned,$1) != $null) { return $v1 }
  elseif ($db.user.get(user,banned,$1) == 1) {
    hadd -mu120 >banned $1 1
    notice $1 This account has been banned, if you need assistance visit $supportchan $+ .  You can appeal any bans using !account.
    return 1
  }
  else {
    hadd -mu30 >banned $1 0
    return 0
  }
}

alias acc-stat {
  db.user.hash >accstat user $1
  if ($hget(>accstat,banned) == 1) return 4 [Account Banned]
  elseif ($hget(>accstat,exclude) == 1) return 9 [Account Excluded]
  return
}

alias rank {
  ; $1 = table
  ; $2 = username
  var %rank = $ranks($1,$2)
  if (%rank == $null || %rank == 0) {
    return Unknown
  }
  else {
    return $ord(%rank)
  }
}

alias ranks {
  tokenize 32 $lower($1 $2)
  ; $1 = table
  ; $2 = position or username
  if ($2 isnum 1-100000) {
    var %sql = SELECT * FROM user u JOIN ( SELECT * FROM user_alt ) ua USING (userid) WHERE banned = '0' AND exclude = '0' GROUP BY userid ORDER BY $db.tquote($1) +0 DESC LIMIT $calc($2 - 1) $+ ,1
    var %query = $db.query(%sql)
    if ($db.query_row(%query,>rrow) == 1) {
      db.query_end %query
      return $hget(>rrow,user) $+ : $+ $hget(>rrow,$1)
    }
  }
  else {
    var %sql = SELECT user, user.userid as userid FROM user,user_alt WHERE user.userid = user_alt.userid AND user = $db.safe($2) LIMIT 0,1
    if ($db.select(%sql,userid) == $null) { return Sorry user could not be found }

    var %sql = SELECT COUNT(*)+1 AS rank FROM user AS r1 $&
      INNER JOIN (SELECT $db.tquote($1) FROM user WHERE banned = '0' AND exclude = '0') AS r2 ON (r1. $+ $1 ) < (r2. $+ $1 ) $&
      WHERE r1.userid = $v1

    var %query = $db.query(%sql)
    if ($db.query_row(%query,>rrow) == 1) {
      db.query_end %query
      return $hget(>rrow,rank)
    }
  }
  return $null
}

alias userlog {
  ; $1 = type
  ; $2 = nick
  ; $3 = info
  if ($1 == win) { var %type = 1 }
  elseif ($1 == loss) { var %type = 2 }
  elseif ($1 == winstake) { var %type = 3 }
  elseif ($1 == losestake) { var %type = 4 }
  elseif ($1 == drop) { var %type = 5 }
  elseif ($1 == buy) { var %type = 6 }
  elseif ($1 == sell) { var %type = 7 }
  elseif ($1 == penalty) { var %type = 8 }
  elseif ($1 == clue) { var %type = 9 }
  else {
    putlog Error: Not a valid userlog type - $db.safe($1-)
    return
  }
  var %user ( SELECT `userid` FROM `user_alt` WHERE `user` = $db.safe($2) )
  var %append $chr(40) %user $chr(44) $db.safe($2) $chr(44) $ctime $chr(44) %type $chr(44) $db.safe($3-) $chr(41)
  set %userlog $iif(%userlog,%userlog $chr(44)) %append
  if ($len(%userlog) > 1000) { userlog.commit }
  .timercommit 1 120 userlog.commit
  return
}

alias userlog.commit {
  if ($len(%userlog) > 4) {
    dbcheck
    var %sql = INSERT INTO user_log (userid, nickname, date, type, data) VALUES %userlog
    if ($db.exec(%sql) == 1) { unset %userlog }
    else { putlog ERROR: userlog commit failed, userlog may need manual cleanup. }
  }
  return
}
