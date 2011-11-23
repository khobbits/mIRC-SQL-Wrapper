on $*:TEXT:/^[!@.](dm|stake|gwd|boss|pvm)\b/Si:#: {
  if (# == $supportchan) && ($nick !isop $chan) { halt }
  if (# == #idm || # == $staffchan) && ($me != iDM) { halt }
  if ((%dm.spam [ $+ [ $nick ] ]) || (%wait. [ $+ [ $chan ] ])) { halt }
  if ($isbanned($nick)) { putlog $logo(Banned) $nick tried to dm on $chan | halt }
  if ($update) { notice $nick $logo(ERROR) iDM is currently disabled, please try again shortly | halt }
  if (*m* iswmcs $chan(#).mode && $nick(#,$me,r)) { notice $nick $logo(ERROR) You currently have +m enabled and I do not have correct access to talk, please voice me | halt }
  if ($nick == idmgod) { halt }
  if ($islogged($nick,$address,0)) { 
    startdm $nick $address $chan $1-
  }
  else {
    notice $nick Attempting iDM login using Nickserv authentication...
    logcheck $nick $address startdm $chan $1-
  }
}

alias startdm {
  var %nick = $1, %address = $2, %chan = $3
  tokenize 32 $4-
  if ($hget(%chan)) && ($istok($hget(%chan,players),%nick,44)) { halt }
  if ($hget(%nick)) { notice %nick You're already in a DM... | inc -u6 %dm.spam [ $+ [ %nick ] ] | halt }
  if ($db.user.get(user,indm,%nick)) { notice %nick You're already in a DM.. | inc -u6 %dm.spam [ $+ [ %nick ] ] | halt }
  if ($hget(%chan)) && ($hget(%chan,p2)) { notice %nick $logo(DM) People are already DMing in this channel. | inc -u8 %dm.spam [ $+ [ %nick ] ] | halt }
  if ($hget(%chan,gwd.time)) { notice %nick $logo(DM) People are already GWDing in this channel. | inc -u8 %dm.spam [ $+ [ %nick ] ] | halt }
  if ((item isin $2) || (no isin $2) || (admin isin $2)) { var %sitems 0 }
  else { var %sitems 1 }
  if ($hget(%chan)) {
    if ($numtok($hget(%chan,players),44) == 6) { notice %nick $logo(GWD) There are already $s1(6) people on this team. Please wait untill the raid is over. | halt }
    if (($hget(%chan,stake)) && (stake !isin $1)) { notice %nick There is currently a stake, please type !stake to accept the challenge. | halt }
    if (($hget(%chan,gwd.npc)) && (gwd !isin $1) && (boss !isin $1) && (pvm !isin $1)) { notice %nick There is currently a GWD, please type !gwd to join the group. | halt }
    if ($hget(%chan,stake)) {
      if ((%chan == #idm.newbies) && (%nick isreg %chan) && ($db.user.get(user,wins,%nick) > 1000)) { halt }
      if ((%chan == #idm.elites) && (%nick isreg %chan) && ($db.user.get(user,wins,%nick) < 1000)) { halt }
      var %p1 $hget(%chan,players)
      checkhosts %nick %p1
      var %stake $checkmoney(%nick,$2,$hget(%chan,stake))
      if (%stake < $hget(%chan,stake)) { notice %nick A wager of $s2($price($hget(%chan,stake))) has already been risked by %p1 $+ . To accept, type !stake. | halt }
      join.dm %chan %nick
      init.chan %p1 %nick %chan 0 0 $hget(%chan,stake)
      var %winloss $winloss(%nick,%p1,%chan)
      msgsafe %chan $logo(DM) $s1(%nick) $gettok(%winloss,1,45) has accepted $s1(%p1) $+ 's $gettok(%winloss,2,45) stake of $s1($price($hget(%chan,stake))) $+ . $s1($hget(%chan,p1)) gets the first move.
    }
    elseif ($hget(%chan,gwd.npc)) {
      join.dm %chan %nick
      msgsafe %chan $logo(GWD) $s1(%nick) joined the group to go to $+($s1($hget(%chan,gwd.npc)),!) You've joined as $s2(Player $findtok($hget(%chan,players),%nick,1,44))
      if ($timer(%chan).secs < 10) .timer $+ %chan 1 20 gwd.init %chan
    }
    else {
      if ((%chan == #idm.newbies) && (%nick isreg %chan) && ($db.user.get(user,wins,%nick) > 1000)) { halt }
      if ((%chan == #idm.elites) && (%nick isreg %chan) && ($db.user.get(user,wins,%nick) < 1000)) { halt }
      var %p1 $hget(%chan,players)
      checkhosts %nick %p1
      join.dm %chan %nick
      init.chan %p1 %nick %chan $hget(%chan,sitems) %sitems $hget(%chan,stake)
      var %winloss $winloss(%nick,%p1,%chan)
      msgsafe %chan $logo(DM) $s1(%nick) $gettok(%winloss,1,45) has accepted $s1(%p1) $+ 's $gettok(%winloss,2,45) DM $+ . $s1($hget(%chan,p1)) gets the first move.
    }
  }
  else {
    if ((%chan == #idm.newbies) && (%nick isreg %chan) && ($db.user.get(user,wins,%nick) > 1000)) { halt }
    if ((%chan == #idm.elites) && (%nick isreg %chan) && ($db.user.get(user,wins,%nick) < 1000)) { halt }
    if (stake isin $1) {
      if ($isdisabled(%chan,staking) === 1) { notice %nick $logo(ERROR) Staking in this channel has been disabled. | halt }
      var %stake $checkmoney(%nick,$2)
      if (!%stake) { notice %nick $logo(ERROR) Please enter an amount between $s1($price(10000)) and $s1($price($maxstake($db.user.get(user,money,%nick)))) $+ . (!stake 150M) | halt }
      join.dm %chan %nick
      hadd %chan stake %stake
      msgsafe %chan $logo(DM) $s1(%nick) $winloss(%nick) has requested a stake of $s2($price(%stake)) $+ ! You have $s2(30 seconds) to accept.
      .timer $+ %chan 1 30 enddm %chan
    }
    elseif ((gwd isin $1) || (boss isin $1) || (pvm isin $1)) {
      if ($isdisabled(%chan,gwd) === 1) { notice %nick $logo(ERROR) Godwars raiding in this channel has been disabled. | halt }
      hadd -m %chan gwd.npc $gwd.npc($2)
      join.dm %chan %nick
      msgsafe %chan $logo(GWD) $s1(%nick) $winloss(%nick) is gathering a group to go to $s1($hget(%chan,gwd.npc)) $+ ! You have $s2(30 seconds) to join.
      .timer $+ %chan 1 30 gwd.init %chan
    }
    else {
      join.dm %chan %nick
      hadd %chan sitems %sitems
      msgsafe %chan $logo(DM) $s1(%nick) $winloss(%nick) has requested a DM! You have $s2(40 seconds) to accept.
      .timer $+ %chan 1 40 autoidm.run %chan
    }
  }
}

alias join.dm {
  hadd -m $1 players $addtok($hget($1,players),$2,44)
  hadd -m $2 account $2
  db.user.set user indm $2 1
}

alias init.chan {
  ; $1 = player1
  ; $2 = player2
  ; $3 = chan
  ; $4 = player1 sitems
  ; $5 = player2 sitems
  ; ?$6? = stake amount
  if ($5 == $null) { putlog Syntax Error: init.chan (5) - $db.safe($1-) | halt }
  var %turn $r(1,2)
  if ($hget($1)) hfree $1
  if ($hget($2)) hfree $2
  if ($hget($3)) hfree $3
  hmake $3 10
  hadd $3 players $addtok($1,$2,44)
  if (%turn == 1) { hadd $3 p1 $1 | hadd $3 p2 $2 }
  else { hadd $3 p1 $2 | hadd $3 p2 $1 }
  if ($6) hadd $3 stake $6
  init.player $1 $3 $4
  init.player $2 $3 $5
  .timer $+ $3 off
}

alias init.player {
  ; $1 = player
  ; $2 = chan
  ; $3 = sitems
  dbcheck
  if ($3 == $null) { putlog Syntax Error: init.player (3) - $db.safe($1-) | halt }
  var %nick $autoidm.acc($1)
  db.user.set user indm %nick 1
  var %sql SELECT * FROM `user_alt` LEFT JOIN `user` USING (`userid`) LEFT JOIN `equip_armour` USING (`userid`) LEFT JOIN `equip_item` USING (`userid`) LEFT JOIN `equip_pvp` USING (`userid`)
  if ($3 == 1) { var %sql %sql LEFT JOIN `equip_staff` USING (`userid`) }
  var %sql %sql WHERE `user_alt`.`user` = $db.safe(%nick)
  var %result = $db.query(%sql)
  if ($db.query_row(%result,$1) === $null) { echo -a Error: Failure to find player. }
  db.query_end %result
  if (!$hget($1)) { putlog Data Error: init.player - hashtable empty - %sql | cancel $2 | halt }
  hadd $1 account $1
  hadd $1 chan $2
  hadd $1 hp 99
  hadd $1 mhp 99
  hadd $1 sp 4
  hadd $1 poison 0
  hadd $1 frozen 0
  hadd $1 laststyle 0
  hadd $1 sitems $3
}

alias checkmoney {
  var %money = $db.user.get(user,money,$1)
  if ($2 == max) { var %stake $maxstake(%money) }
  else { var %stake $floor($iif($right($2,1) isin kmbt,$calc($replace($remove($2-,$chr(44)),k,*1000,m,*1000000,b,*1000000000,t,*1000000000000)),$remove($2-,$chr(44)))) }
  if (%money < 60000) { notice $nick You can't stake until you have $s1($price(60000)) $+ . | halt }
  if (%stake < 10000) { notice $nick The minimum stake is $s1($price(10000)) $+ . | halt }
  if (%stake > $maxstake(%money)) { notice $nick Your maximum stake is only $s1($price($maxstake(%money))) $+ . | halt }
  if (%money < $hget($chan,stake)) { notice $nick You cannot stake $s2($price($hget($chan,stake))) $+ . Your max stake is $s2($price($maxstake(%money))) $+ . | halt }
  return %stake
}

alias maxstake return $ceil($calc( $1 ^ 0.84 ))

alias checkhosts {
  if ($address($1,2) == $address($2,2)) && ($len($address($1,2)) > 3) {
    msgsafe $chan $logo(ERROR) We no longer allow two players on the same hostmask to DM each other.  You are free to DM others. If you have recieved this error as a mistake please drop by $supportchan $+ .
    inc -u5 %dm.spam [ $+ [ $1 ] ]
    halt
  }
}

alias winloss {
  if ($2) {
    var %p1win $hget($1,wins)
    var %p2win $hget($2,wins)
    var %p1loss $hget($1,losses)
    var %p2loss $hget($2,losses)
    var %p1 $s2($chr(91)) $+ Wins $s1($iif(%p1win,$bytes($v1,bd),0)) Losses $s1($iif(%p1loss,$bytes($v1,bd),0)) $+ $s2($chr(93)) $iif($hget($1,sitems),,(NA))
    var %p2 $s2($chr(91)) $+ Wins $s1($iif(%p2win,$bytes($v1,bd),0)) Losses $s1($iif(%p2loss,$bytes($v1,bd),0)) $+ $s2($chr(93)) $iif($hget($2,sitems),,(NA))
    if ((($calc(%p1win + %p1loss) > 60) && (($calc(%p1win / %p1loss) > 4) || ($calc(%p1win / %p1loss) < 0.22))) || (($calc(%p2win + %p2loss) > 60) && (($calc(%p2win / %p2loss) > 4) || ($calc(%p2win / %p2loss) < 0.22)))) {
      msgsafe $staffchan $logo(4RATIO) $3 = $1 %p1 ( $+ $calc(%p1win / %p1loss) $+ ) - $2 %p2 ( $+ $calc(%p2win / %p2loss) $+ )
    }
    return $+(%p1,-,%p2)
  }
  elseif ($1) {
    db.user.hash >winloss user $1 wins losses
    var %p1win $hget(>winloss,wins)
    var %p1loss $hget(>winloss,losses)
    var %p1 $s2($chr(91)) $+ Wins $s1($iif(%p1win,$bytes($v1,bd),0)) Losses $s1($iif(%p1loss,$bytes($v1,bd),0)) $+ $s2($chr(93))
    return %p1
  }
}

alias pcancel {
  if ($2 == $null) { putlog Syntax Error: pcancel (2) - $db.safe($1-) | halt }
  db.user.set user indm $autoidm.acc($2) 0
  if ($hget($2)) hfree $2
  if ($hget($1)) {
    hadd $1 players $remtok($hget($1,players),$2,44)
    hadd $1 gwd.turn $remtok($hget($1,gwd.turn),$2,44)
  }
}

alias cancel {
  if ($1 == $null) { putlog Syntax Error: cancel (1) - $db.safe($1-) | halt }
  if ($1) && ($chr(35) isin $1) {
    if ($hget($1,gwd.time)) { pcancel $1 <gwd> $+ $chan }
    while ($gettok($hget($1,players),1,44)) { pcancel $1 $v1 }
    if ($hget($1)) hfree $1
    .timer $+ $1 off
    .timerc $+ $1 off
    .timercw $+ $1 off
  }
}

alias enddm {
  if ($hget($1,p2)) { halt }
  msgsafe $1 $logo(DM) Nobody has accepted $s1($hget($1,players)) $+ 's DM request, and the DM has ended.
  cancel $1
}

on $*:TEXT:/^[!@.]enddm/Si:#: {
  if (# == #idm || # == $staffchan) && ($me != iDM) { halt }
  if ($hget($chan,gwd.npc)) {
    if ($db.get(admins,rank,address,$address($nick,3)) >= 2) {
      cancel $chan
      msgsafe $chan $logo(GWD) The Gwd Team has been canceled by staff.
    }
    elseif (!$hget($chan,gwd.time) && $nick == $gettok($hget($chan,players),1,44)) {
      msgsafe $chan $logo(GWD) The Gwd Team has been canceled by the Team Leader.
      cancel $chan
    }
    elseif (!$hget($chan,gwd.time) && $istok($hget($chan,players),$nick,44)) {
      msgsafe $chan $logo(GWD) $s1($nick) runs away from the GWD, too scared to even start.
      pcancel $chan $nick
    }
  }
  elseif ($hget($chan,stake)) {
    if ($db.get(admins,rank,address,$address($nick,3)) >= 2) {
      cancel $chan
      msgsafe $chan $logo(DM) The DM has been canceled by staff.
    }
    elseif ($nick == $hget($chan,players)) {
      cancel $chan
      msgsafe $chan $logo(DM) The stake has been canceled.
    }
    else { notice $nick This is a stake, you cannot end stakes! }
  }
  elseif ($db.get(admins,rank,address,$address($nick,3)) >= 2) {
    if (!$hget($chan)) { notice $nick There is no DM. }
    else {
      msgsafe $chan $logo(DM) The DM has been canceled by staff.
      cancel $chan
    }
  }
  elseif (($nick == $hget($chan,p2))) {
    var %othernick = $hget($chan,p1)
    if (%enddm [ $+ [ $chan ] ] == 0) {
      notice $nick Please wait at least 30 seconds after the last move before ending a dm.
    }
    else {
      notice $nick $+ , $+ %othernick The DM will end in 40 seconds if %othernick does not make a move or !enddm. If the dm times out %othernick will lose $price($ceil($calc($db.user.get(user,money,%othernick) * 0.005)))
      set %enddm [ $+ [ $chan ] ] %othernick
      .timercw $+ $chan 1 20 delaycancelw $chan %othernick
      .timerc $+ $chan 1 40 delaycancel $chan %othernick
    }
  }
  elseif ($nick == $hget($chan,p1)) {
    notice $nick You can only end the dm on the other players turn.
  }
  elseif ($nick == $hget($chan,players)) {
    cancel $chan
    msgsafe $chan $logo(DM) The DM has been canceled.
  }
}

alias delaycancel {
  if (%enddm [ $+ [ $1 ] ] != $2) { return }
  var %oldmoney = $hget($2,money)
  if (%oldmoney > 100) {
    var %newmoney = $ceil($calc(%oldmoney * 0.005))
    notice $2 You got kicked out of a dm, you lose $s2($price(%newmoney)) cash.
    userlog penalty $2 %newmoney
    db.user.set user money $2 - %newmoney
  }
  cancel $1
  msgsafe $1 $logo(DM) The DM has ended due to timeout.
}

alias delaycancelw {
  if (%enddm [ $+ [ $1 ] ] == $2) { msgsafe $1 $logo(DM) The DM will end in 20s if $2 does not make a move. }
}
