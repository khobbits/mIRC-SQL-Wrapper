;;  This alias calculates the max hit of an attack, with and without item bonuses
;;  This alias is used by: !max
alias max {
  ; $1 = attack
  if ($1 == $null) { putlog Syntax Error: attack (1) - $db.safe($1-) | halt }
  var %dbdmg = $dmg($1, 3h)
  if ($1 == dh) { var %dbdmg = $dmg($1, 1h) }
  if ($1 == dh9) { tokenize 32 dh | var %dbdmg = $dmg($1, 3h) }
  var %dbhits = $dmg($1,hits)
  var %dbbonus = $dmg($1, atkbonus)
  if (%dbbonus == n) { return $dmg.ratio(%dbhits,%dbdmg,0,1) $dmg.ratio(%dbhits,%dbdmg,4,1) }
  elseif ($dmg($1,type) == range) {
    ;Normal Archer Ring _or_Accumulator Both
    return $dmg.ratio(%dbhits,%dbdmg,0,%dbbonus) $dmg.ratio(%dbhits,%dbdmg,4,%dbbonus) $dmg.ratio(%dbhits,%dbdmg,8,%dbbonus)
  }
  elseif ($dmg($1,type) == magic) {
    ;Normal Voidmage_or_MagesBook_or_GodCape Two_Bonuses Three_Bonuses
    return $dmg.ratio(%dbhits,%dbdmg,0,%dbbonus) $dmg.ratio(%dbhits,%dbdmg,4,%dbbonus) $dmg.ratio(%dbhits,%dbdmg,8,%dbbonus)
  }
  else {
    ;Normal Barrowgloves Firecape Both
    return $dmg.ratio(%dbhits,%dbdmg,0,%dbbonus) $dmg.ratio(%dbhits,%dbdmg,4,%dbbonus) $dmg.ratio(%dbhits,%dbdmg,8,%dbbonus)
  }
}

;;  This alias calculates the damage 'pattern', and will return the max damage hit pattern.
;;  This alias is used by: $max (!max)
alias dmg.ratio {
  ; $1 = hit pattern - 1-1-1
  ; $2 = max hit
  ; $3 = attack bonus
  ; $4 = bonus toggle
  if ($4 == $null) { putlog Syntax Error: dmg.ratio (4) - $db.safe($1-) | halt }
  var %hits
  var %i = 0
  while (%i < $numtok($1,45)) {
    inc %i
    var %hitp $gettok($1,%i,45)
    if ((%hitp < 1) || (%hitp == n)) { var %hitp 1 }    
    var %hits $iif(%hits,%hits $+ -) $+ $ceil($calc(($2 + ($3 * $4)) / %hitp))
    ;msg #idm.dev debug:     var hits $iif(%hits,%hits $+ -) ceil(  calc(( $2 + ( $3 * $4 )) / %hitp ))
  }
  return %hits
}

;;  These alias's are used as accessors for database values

alias attack { return $iif($dmg($1,name),$true,$false) }
alias ispvp { return $iif($dmg($1,pvp),$true,$false) }
alias isgwd { return $iif($dmg($1,gwd),$true,$false) }
alias isweapon {
  var %wep $dmg($1,item)
  return $iif(%wep,%wep,$false)
}
alias specused { return $calc($dmg($1,spec) * 25) }
alias poisoner { return $dmg($1,poison) $dmg($1,poisonamount) }
alias freezer { return $dmg($1,freeze) }
alias healer { return $dmg($1,heal) $dmg($1,healamount) }

;;  This alias (re)loads the weapon database into hashcache.
;;  This alias is used by $dmg.hget ($dmg)
alias dmg.hload {
  if ($hget(>weapon)) { hfree >weapon }
  hmake >weapon 200
  var %sql SELECT * FROM `weapons` ORDER BY `weapon` ASC, `main` ASC 
  var %res $db.query(%sql)
  var %i 0
  var %last -1
  while ($db.query_row(%res, >row)) {
    inc %i
    hadd >weapon $hget(>row, trigger) $+ .name $hget(>row, name)
    hadd >weapon $hget(>row, trigger) $+ .item $hget(>row, item)
    hadd >weapon $hget(>row, trigger) $+ .pvp $hget(>row, pvp)
    hadd >weapon $hget(>row, trigger) $+ .0l $gettok($hget(>row, range),1,44)
    hadd >weapon $hget(>row, trigger) $+ .0h $gettok($hget(>row, range),2,44)
    hadd >weapon $hget(>row, trigger) $+ .1l $gettok($hget(>row, low),1,44)
    hadd >weapon $hget(>row, trigger) $+ .1h $gettok($hget(>row, low),2,44)
    hadd >weapon $hget(>row, trigger) $+ .2l $gettok($hget(>row, mid),1,44)
    hadd >weapon $hget(>row, trigger) $+ .2h $gettok($hget(>row, mid),2,44)
    hadd >weapon $hget(>row, trigger) $+ .3l $gettok($hget(>row, high),1,44)
    hadd >weapon $hget(>row, trigger) $+ .3h $gettok($hget(>row, high),2,44)
    hadd >weapon $hget(>row, trigger) $+ .hits $hget(>row, hits)
    hadd >weapon $hget(>row, trigger) $+ .type $hget(>row, type)
    hadd >weapon $hget(>row, trigger) $+ .gwd $hget(>row, gwd)
    hadd >weapon $hget(>row, trigger) $+ .atkbonus $hget(>row, atkbonus)
    hadd >weapon $hget(>row, trigger) $+ .defbonus $hget(>row, defbonus)
    hadd >weapon $hget(>row, trigger) $+ .spec $hget(>row, spec)
    hadd >weapon $hget(>row, trigger) $+ .poison $hget(>row, poisonchance)
    hadd >weapon $hget(>row, trigger) $+ .poisonamount $hget(>row, poisonamount)
    hadd >weapon $hget(>row, trigger) $+ .freeze $hget(>row, freeze)
    hadd >weapon $hget(>row, trigger) $+ .heal $hget(>row, healchance)
    hadd >weapon $hget(>row, trigger) $+ .healamount $hget(>row, healamount)
    hadd >weapon $hget(>row, trigger) $+ .splash $hget(>row, splash)
    hadd >weapon $hget(>row, trigger) $+ .what $hget(>row, what)
    hadd >weapon $hget(>row, trigger) $+ .effect $hget(>row, effect)
    if (%last != $hget(>row, weapon)) {
      hadd >weapon list. $+ %i $hget(>row, trigger)
      var %list $iif(%list,%list $+ $chr(44)) $+ $hget(>row, trigger)
    }
    var %last = $hget(>row, weapon)
  }
  hadd >weapon list %list
  hadd >weapon list.0 %i
  mysql_free %res
}

;;  This alias will return the db values related to an attack.  This will load the weapons db into hashcache.
;;  This alias is used by: $dmg
alias dmg.hget {
  if (!$hget(>weapon)) { dmg.hload }
  tokenize 32 $1- 0
  return $hget(>weapon,$1 $+ . $+ $2)
}

;;  This alias is the main accessor for database values.  This method allows access to the database using multiple methods.
;;  This alias is used by: $accuracy $atkbonus $hit $damage $enablec $disablec !max !hitchance !attack
alias dmg {
  ; $1 = attack
  ; ?$2? = value
  if ($1 == $null) { putlog Syntax Error: dmg (1) - $db.safe($1-) | halt }
  if (($prop) && ($2 isnum)) return $dmg.hget($dmg.hget($gettok($1,1,61),$2),$prop)
  if ($2 != $null) return $dmg.hget($gettok($1,1,61),$2)
  if (($1 != $null) && ($1 != list)) return $iif($dmg.hget($gettok($1,1,61),name),1,0)
  return $hget(>weapon,list)

}

on $*:TEXT:/^[!@.]max/Si:#: {
  if (# == #idm) || (# == $staffchan) && ($me != iDM) { halt }
  if ($isbanned($nick)) { halt }
  if ($update) { notice $nick $logo(ERROR) iDM is currently disabled, please try again shortly | halt }
  if (!$2) { $iif($left($1,1) == @,msgsafe $chan,notice $nick) Please specify the weapon to look up. Syntax: !max whip | halt }
  var %wep $2
  if ($2 == dh9) { var %wep dh }
  if (!$attack(%wep)) {
    notice $nick $logo(ERROR) $s1(%wep) is not a recognized attack.
    halt
  }
  if (!$max(%wep)) notice $nick $logo(ERROR) $s1($2) is not a recognized attack.
  var %msg $iif($left($1,1) == @,msgsafe $chan,notice $nick) $logo(MAX) $upper($2) - $dmg(%wep,name) $iif($specused($2),$+($chr(32),$chr(40),$s1($v1 $+ $chr(37)),$chr(41)))
  var %msg %msg $+ $iif($2 == dh,$+($chr(32),$chr(40),use 'dh9' for <10 hp,$chr(41)))
  var %msg %msg $+ $iif($2 == dh9,$+($chr(32),$chr(40),use 'dh' for >10 hp,$chr(41)))
  var %msg %msg $+ : $dmg.breakdown($2,1) ( $+ $dmg(%wep,type) $+ )
  if ($dmg(%wep,gwd) == 1) { var %msg %msg $chr(124) GWD only attack }
  elseif ($dmg(%wep,atkbonus) == 0) { var %msg %msg $chr(124) No item bonuses }
  elseif ($dmg(%wep,atkbonus) == n) { var %msg %msg $chr(124) +1 damage for each extra item up to +4: $dmg.breakdown($2,2) }
  elseif ($dmg(%wep,type) == range) { var %msg %msg $chr(124) Archer Ring or Accumulator $dmg.breakdown($2,2) $chr(124) Two bonuses $dmg.breakdown($2,3) }
  elseif ($dmg(%wep,type) == magic) { var %msg %msg $chr(124) Mage Book or God Cape $dmg.breakdown($2,2) $chr(124) Two bonuses $dmg.breakdown($2,3) }
  elseif ($dmg(%wep,type) == melee) { var %msg %msg $chr(124) Barrow gloves or Fire cape $dmg.breakdown($2,2) $chr(124) Two bonuses $dmg.breakdown($2,3) }
  %msg $iif($dmg(%wep,effect),$+($chr(40),$v1,$chr(41)))
}

alias dmg.breakdown { return $s2($gettok($max($1),$2,32)) $iif($totalhit($1,$2),$+($chr(40),$s2($v1),$chr(41))) }
