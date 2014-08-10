on $*:TEXT:/^[!.]\w/Si:#: {
  if (# == #iDM || # == $staffchan) && ($me != iDM) { halt }
  if ($isbanned($nick)) { halt }
  var %attcmd $right($1,-1)
  if ($hget($chan,gwd.time) && $findtok($hget($chan,players),$nick,44)) || ($nick == $hget($chan,p1) && $hget($chan,p2)) && ($hget($chan) && $hget($nick,chan) == $chan) {
    if ($hget($chan,p1) && $nick == $hget($chan,p1) && $hget($chan,p2)) { 
      var %p2 $hget($chan,p2)
    }
    else {
      var %p2 <gwd> $+ $chan
    }
    if (%attcmd == specpot) {
      if ($hget($chan,gwd.time)) { notice $nick Specpots are currently disabled for GWD | halt }
      if (!$hget($nick,specpot)) { notice $nick You don't have any specpots. | halt }
      if ($hget($nick,sp) == 4) { notice $nick You already have a full special bar. | halt }
      hadd $nick sp 4
      db.user.set equip_item specpot $nick - 1
      hadd $nick laststyle pot
      if ($hget(%p2,poison) >= 1) && ($hget(%p2,hp) >= 1) {
        var %extra = $iif($hget(%p2,hp) < $hget(%p2,poison),$v1,$v2)
        hdec %p2 poison
        hdec %p2 hp %extra
        msgsafe $chan $logo($iif($hget($chan,gwd.time),GWD,DM)) $s1($nick) drinks their specpot and now has 100% special.  Poison hit $s1($autoidm.nick(%p2)) for $s1(%extra) damage. $hpbar($hget(%p2,hp),$hget(%p2,mhp))
      }
      else {
        msgsafe $chan $logo($iif($hget($chan,gwd.time),GWD,DM)) $s1($nick) drinks their specpot and now has 100% special.
      }
    }
    elseif (!$attack(%attcmd)) { halt }
    else {
      if (!$hget($chan,gwd.time) && $isgwd(%attcmd)) {
        notice $nick $logo(ERROR) You can't use this attack outside of GWD.
        halt
      }
      if ($hget($chan,gwd.npc)) {
        if (!$istok($hget($chan,gwd.turn),$nick,44)) { notice $nick $logo(GWD) You have already attacked | halt }
        if ($gwd.hget($hget($chan,gwd.npc),nomelee)) && ($dmg(%attcmd,type) == melee) {
          notice $nick $logo(ERROR) You can't use a melee based attack against $gwd.hget($hget($chan,gwd.npc),name) $+ .
          halt
        }
        if ($gwd.hget($hget($chan,gwd.npc),nomagic)) && ($dmg(%attcmd,type) == magic) {
          notice $nick $logo(ERROR) You can't use a magic based attack against $gwd.hget($hget($chan,gwd.npc),name) $+ .
          halt
        }
        if ($gwd.hget($hget($chan,gwd.npc),norange)) && ($dmg(%attcmd,type) == range) {
          notice $nick $logo(ERROR) You can't use a range based attack against $gwd.hget($hget($chan,gwd.npc),name) $+ .
          halt
        }
      }
      if ($dmg(%attcmd,spec) > $hget($nick,sp)) {
        notice $nick $logo(ERROR) You need $s1($specused(%attcmd) $+ $chr(37)) spec to use this.  Weapons with * in !dmcommands require spec.
        halt
      }
      if ($isdisabled($chan,%attcmd)) {
        notice $nick $logo(ERROR) This command has been disabled for this channel.
        halt
      }
      if ($hget($nick,frozen)) && ($dmg(%attcmd,type) == melee) {
        notice $nick You're frozen and can't use melee.
        halt
      }
      var %wepitem $isweapon(%attcmd)
      if (%wepitem !== $false) {
        if (!$hget($nick,%wepitem)) {
          notice $nick You have to unlock this weapon before you can use it.  Use !dmcommands for a list of commands.
          halt
        }
      }
      if ($ispvp(%attcmd)) {
        db.user.set equip_pvp $dmg(%attcmd,item) $nick - 1
      }
      .timercw $+ $chan off
      .timerc $+ $chan off
      set -u25 %enddm [ $+ [ $chan ] ] 0
      if ($specused(%attcmd)) {
        hdec $nick sp $dmg(%attcmd,spec)
      }
      if ($hget($chan,gwd.time)) {
        gwd.att $nick <gwd> $+ $chan %attcmd $chan $2
      }
      else {
        damage $nick %p2 %attcmd #
      }
    }
    if ($hget(%p2,hp) < 1) && (!$hget($chan,gwd.npc)) {
      if (<iDM>* iswm %p2) { db.user.set user aikills $nick + 1 }
      dead $chan %p2 $nick
      halt
    }
    if ($hget($nick,hp) < 1) && (!$hget($chan,gwd.npc)) {
      if (<iDM>* iswm $nick) { db.user.set user aikills %p2 + 1 }
      dead $chan $nick %p2
      halt
    }
    if ($specused(%attcmd)) {
      notice $nick Specbar: $iif($hget($nick,sp) < 1,0,$calc(25 * $hget($nick,sp))) $+ $chr(37)
    }
    hadd $nick frozen 0
    if (!$hget($chan,gwd.time)) {
      hadd $chan p1 %p2
      hadd $chan p2 $nick
    }
    else { gwd.turn $nick $chan }
    if (<iDM>* iswm %p2) { autoidm.turn $chan }
    return
  }
}
alias damage {
  ;1 is person attacking
  ;2 is other person
  ;3 is weapon
  ;4 is chan
  if ($4 == $null) { putlog Syntax Error: damage (4) - $db.safe($1-) | halt }
  var %hp1 $hget($1,hp)
  var %hp2 $hget($2,hp)
  var %mhp1 $hget($1,mhp)
  var %mhp2 $hget($2,mhp)
  var %logo $iif($hget($4,gwd.time),GWD,DM)
  if ($3 == dh) {
    if (%hp1 < 10) { var %hit $hit(dh=9,$1,$2,$4) }
    else { var %hit $hit(dh=10,$1,$2,$4) }
  }
  else { var %hit $hit($3,$1,$2,$4) }
  var %i = 1
  var %hitshow
  while (%i <= $numtok(%hit,32)) {
    if (%i != 1) var %hitshow %hitshow -
    var %hitdmg $gettok(%hit,%i,32)
    if (%hp2 == 0) {
      var %hit $puttok(%hit,KO,%i,32)
      var %hitshow %hitshow 4KO
    }
    elseif (%hp2 <= %hitdmg) {
      var %hit $puttok(%hit,%hp2,%i,32)
      var %hitshow %hitshow $s2(%hp2)
      var %hp2 0
    }
    else {
      dec %hp2 %hitdmg
      var %hitshow %hitshow $s2(%hitdmg)
    }
    inc %i
  }
  ; Starting value for one hit acheivement
  var %dmg-dealt %hitdmg
  var %msg $logo(%logo) $s1($autoidm.nick($1)) $replace($dmg($3,what),$eval(%p2%,0),$s1($replace($autoidm.nick($2),$chr(58),$chr(32))),$eval(%attack%,0),$dmg($3,name))
  if (($dmg($3,splash)) && (%hitdmg == 0)) { var %msg %msg and splashed }
  else { var %msg %msg hitting %hitshow }

  if ($freezer($3) && ($r(1,$v1) == 1) && (%hitdmg >= 1) && (!$hget($4,gwd.time))) {
    hadd $2 frozen 1
    if (<* !iswm $2) {
      notice $2 You have been frozen and can't use melee!
      var %msg %msg and successfully 12FREEZES them
    }
  }
  if ($gettok($healer($3),1,32)) && ($r(1,$v1) == 1) && (%hitdmg != 0) && (%hp1 < %mhp1) {
    var %healer 1
    $iif($calc($floor(%hp1) + $floor($calc(%hit / $gettok($healer($3),2,32)))) > %mhp1,set %hp1 %mhp1,inc %hp1 $floor($calc(%hit / $gettok($healer($3),2,32))))
    var %msg %msg and 09HEALING
  }

  if ($gettok($poisoner($3),1,32)) && (($r(1,$v1) == 1) || (($hget($1,snake)) && (!$hget($2,poison)) && ($gettok($poisoner($3),2,32) < 8))) {
    hadd $2 poison $gettok($poisoner($3),2,32)
  }

  if ($hget($2,poison) >= 1) && (%hp2 >= 1) {
    var %extra $iif(%hp2 < $hget($2,poison),$v1,$v2)
    hdec $2 poison
    inc %dmg-dealt %extra
    dec %hp2 %extra
    var %msg %msg - 03 $+ %extra $+ 
  }

  if (%healer == 1) { var %msg %msg $+ . $s1($replace($autoidm.nick($2),$chr(58),$chr(32))) $hpbar(%hp2,%mhp2) - $s1($replace($autoidm.nick($1),$chr(58),$chr(32))) $hpbar(%hp1,%mhp1) }
  else { var %msg %msg $+ . $hpbar(%hp2,%mhp2) }
  msgsafe $4 %msg

  if ($dmg($3,type) == melee) { hadd $1 laststyle melee }
  if ($dmg($3,type) == magic) { hadd $1 laststyle mage }
  if ($dmg($3,type) == range) { hadd $1 laststyle range }

  var %temp.hit $calc($replace(%hit,$chr(32),$chr(43)))
  if ($hget($1,belong)) && ($r(1,100) >= 99) && (%hp2 >= 1) {
    var %extra $iif(%hp2 < 12,$($v1,2),12)
    inc %dmg-dealt %extra
    dec %hp2 %extra
    msgsafe $4 $logo(%logo) $s1($1) whips out their Bêlong Blade and deals $s2(%extra) extra damage. $hpbar(%hp2,%mhp2)
  }
  if ($hget($2,allegra)) && ($r(1,100) >= 99) && (%hp2 >= 1) && (%hp2 < 99) {
    var %extraup $iif(%hp2 >= 84,$calc(99- %hp2),15)
    inc %hp2 %extraup
    msgsafe $4 $logo(%logo) Allêgra gives $s1($2) Allergy pills, healing $s2(%extraup) HP. $hpbar(%hp2,%mhp2)
  }
  if ((!$hget($4,gwd.time)) && (<idm>* !iswm $1) && ($hget($2,jade)) && ($r(1,100) >= 99 || $2 == belongtome) && (%temp.hit < 70) && (%hp1 >= 1) && ($calc($replace(%hit,$chr(32),$chr(43))) != 0)) {
    dec %hp1 $floor($calc(%temp.hit * .75))
    msgsafe $4 $logo(%logo) $s1($2) goes tit for tat with $s1($1) and deals 75% of the damage back. $hpbar(%hp1,%mhp1)
  }
  elseif ($hget($2,kh)) && ($r(1,100) >= 99) && (%temp.hit < 70) && (%hp2 >= 1) && ($calc($replace(%hit,$chr(32),$chr(43))) != 0) {
    inc %hp2 %temp.hit
    msgsafe $4 $logo(%logo) KHobbits uses his KHonfound Ring to let $s1($2) avoid the damage. $hpbar(%hp2,%mhp2)
  }
  elseif ($hget($2,support)) && ($r(1,100) >= 99)  && (%temp.hit < 70) && (%hp2 >= 1) && ($calc($replace(%hit,$chr(32),$chr(43))) != 0) {
    inc %hp2 $floor($calc(%temp.hit / 2))
    msgsafe $4 $logo(%logo) $s1($2) uses THE SUPPORTER to help defend against $s1($autoidm.nick($1)) $+ 's attacks. $hpbar(%hp2,%mhp2)
  }
  if (%hp2 < 1) {
    if (($hget($2,beau)) && ($r(1,50) >= 49) ) {
      var %hp2 1
      msgsafe $4 $logo(%logo) $s1($2) $+ 's Bêaumerang brings them back to life, barely. $hpbar(%hp2,%mhp2)
    }
  }
  hadd $1 hp %hp1
  hadd $2 hp %hp2

  var %e = $hget($4,players), %x = 1
  if ((<gwd isin $1) && ($numtok(%e,44) > 1))  {
    while (%x <= $numtok(%e,44)) {
      if ($numtok(%e,44) < 5) { var %h %h $s1($gettok(%e,%x,44)) $remove($hpbar($hget($gettok(%e,%x,44),hp),$hget($gettok(%e,%x,44),mhp)),HP) }
      else { var %h %h $s1($gettok(%e,%x,44)) $remove($hpbar2($hget($gettok(%e,%x,44),hp),$hget($gettok(%e,%x,44),mhp)),HP) }
      inc %x
    }
    notice $hget($4,players) $logo(GWD) HP: %h
  }
  if (%dmg-dealt >= 99) { db.user.set achievements 1hit $1 1 }

}

alias hpbar {
  if (-* iswm $1) { tokenize 32 0 99 }
  elseif ($1 !isnum 0-9000) { tokenize 32 99 99 }
  elseif ($2 !isnum 0-9000) { tokenize 32 $1 99 }
  var %div = $ceil($calc( $2 / 20 )), %pos = $ceil($calc( $1 / %div )), %text = $iif($1 == 0,KO,$1), %ltext $calc(4 - $len(%text))
  var %p1 HP $setc(3,3) $+ $str($chr(58),$iif(%pos < 9,%pos,9))
  if (%pos < 9) return %p1 $+ $setc(4,4) $+ $str($chr(46),$calc(9 - %pos)) $+ $setc(00) $+ %text $+ $setc(4) $+ $str($chr(46),$calc(7 + %ltext)) $+ 
  elseif (%pos == 9) return %p1 $+ $setc(0,04) $+ %text $+ $setc(4,4) $+ $str($chr(46),$calc(7 + %ltext)) $+ 
  elseif (%pos < $calc(13 - %ltext) ) return %p1 $+ $setc(00) $+ $mid(%text,1,$calc(%pos - 9)) $+ $setc(0,04) $+ $mid(%text,$calc(%pos - 8),$calc(13 - %pos)) $+ $setc(4) $+ $str($chr(46),$calc(7 + %ltext)) $+ 
  else return %p1 $+ $setc(00) $+ %text $+ $setc(3) $+ $str($chr(58),$calc(%pos -13 + %ltext)) $+ $setc(4,4) $+ $str($chr(46),$calc(20 - %pos)) $+ 
}

alias hpbar2 {
  if (-* iswm $1) { tokenize 32 0 99 }
  elseif ($1 !isnum 0-99) { return $hpbar($1,$2) }
  elseif ($2 == $null) { tokenize 32 $1 99 }
  elseif ($2 !isnum 0-99) { return $hpbar($1,$2) }
  var %div = $ceil($calc( $2 / 11 )), %pos = $ceil($calc( $1 / %div )), %text = $iif($1 == 0,KO,$1), %ltext $calc(2 - $len(%text))
  var %p1 HP $setc(3,3) $+ $str($chr(58),$iif(%pos < 5,%pos,5))
  if (%pos < 5) return %p1 $+ $setc(4,4) $+ $str($chr(46),$calc(5 - %pos)) $+ $setc(00) $+ %text $+ $setc(4) $+ $str($chr(46),$calc(4 + %ltext)) $+ 
  elseif (%pos == 5) return %p1 $+ $setc(0,04) $+ %text $+ $setc(4,4) $+ $str($chr(46),$calc(4 + %ltext)) $+ 
  elseif (%pos == 6) return %p1 $+ $setc(00) $+ $mid(%text,1,1) $+ $setc(0,04) $+ $mid(%text,2,1) $+ $setc(4) $+ $str($chr(46),$calc(4 + %ltext)) $+ 
  else return %p1 $+ $setc(00) $+ %text $+ $setc(3) $+ $str($chr(58),$calc(%pos - 7 + %ltext)) $+ $setc(4,4) $+ $str($chr(46),$calc(11 - %pos)) $+ 
}

alias setc {
  if ($2) return  $+ $1 $+ , $+ $2
  return  $+ $1
}
