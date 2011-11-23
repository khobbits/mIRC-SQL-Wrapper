on $*:TEXT:/^[!@.]money/Si:#: {
  tokenize 32 $1- $nick
  if (# == #idm || # == $staffchan) && ($me != iDM) { halt }
  if ($isbanned($nick)) { halt }
  if ($update) { notice $nick $logo(ERROR) iDM is currently disabled, please try again shortly | halt }
  $iif($left($1,1) == @,msgsafe $chan,notice $nick) $logo($2) $+ $acc-stat($2) $money($2) $clan($2) $s1(Profile) $+ : http://idm-bot.com/u/ $+ $webstrip($2,1) 
}

on $*:TEXT:/^[!@.]equip/Si:#: {
  tokenize 32 $1- $nick
  if (# == #idm || # == $staffchan) && ($me != iDM) { halt }
  if ($isbanned($nick)) { halt }
  if ($update) { notice $nick $logo(ERROR) iDM is currently disabled, please try again shortly | halt }
  $iif($left($1,1) == @,msgsafe $chan,notice $nick) $logo($2) $+ $acc-stat($2) $equipment($2) $s1(Spec Pots) $+ : $iif($db.user.get(equip_item,specpot,$2),$v1,0)
  if ($sitems($2)) || ($pvp($2)) $iif($left($1,1) == @,msgsafe $chan,notice $nick) $logo($2) $+ $isbanned($2) $iif($sitems($2),$s1(Special Items) $+ : $sitems($2)) $iif($pvp($2),$s1(PvP Items) $+ : $pvp($2))
}

alias money {
  if ($1 == $null) { putlog Syntax Error: money (1) - $db.safe($1-) | halt }
  db.user.hash >userm user $1

  var %money = $hget(>userm,money)
  var %rank = $rank(money,$1)
  var %wins = $hget(>userm,wins)
  var %losses = $hget(>userm,losses)
  var %ratio = $s1(W/L Ratio) $+ :  $s2($round($calc(%wins / %losses),2)) ( $+ $s2($+($round($calc(%wins / $calc(%wins + %losses) *100),1),$chr(37)))) $+ )

  return $s1(Money) $+ : $iif(%money,$s2($bytes($v1,bd)) $+ gp ( $+ %rank $+ ),$s2(0) $+ gp) $iif($maxstake(%money),$s1(Max Stake) $+ : $s2($price($maxstake(%money)))) $s1(Wins) $+ : $iif(%wins,$s2($bytes($v1,bd)),$s2(0)) $s1(Losses) $+ : $iif(%losses,$s2($bytes($v1,bd)),$s2(0)) %ratio
}

alias store.hload {
  if ($hget(>store)) { hfree >store }
  hmake >store 10
  var %sql SELECT * FROM sale_item
  var %res $db.query(%sql)
  var %i 0
  while ($db.query_row(%res, >row)) {
    inc %i
    hadd >store $hget(>row, item) $+ .name $hget(>row, name)
    hadd >store $hget(>row, item) $+ .sname $hget(>row, sname)
    hadd >store $hget(>row, item) $+ .table $hget(>row, table)
    hadd >store $hget(>row, item) $+ .buy $hget(>row, purchase_price)
    hadd >store $hget(>row, item) $+ .sell $hget(>row, sell_price)
    hadd >store $hget(>row, item) $+ .status $hget(>row, status)
    hadd >store $hget(>row, item) $+ .wins $hget(>row, required_wins)
    hadd >store list. $+ %i $hget(>row, item)
    var %list $iif(%list,%list $+ $chr(44)) $+ $hget(>row, item)
  }
  hadd >store list %list
  hadd >store list.0 %i
  mysql_free %res
}

alias store {
  ; $1 = item
  ; ?$2? = value
  if ($1 == $null) { putlog Syntax Error: store (1) - $db.safe($1-) | halt }
  if (!$hget(>store)) { store.hload }
  if (($prop) && ($2 isnum)) return $hget(>store,$hget(>store, $gettok($1,1,95) $+ . $+ $2) $+ . $+ $prop)
  if ($2 != $null) return $hget(>store, $gettok($1,1,95) $+ . $+ $2)
  if (($1 != $null) && ($1 != list)) return $iif($hget(>store, $gettok($1,1,95) $+ .name),1,0)
  return $hget(>store,list)
}

alias equipment {
  if ($1 == $null) { putlog Syntax Error: equipment (1) - $db.safe($1-) | halt }
  db.user.hash >equip_item equip_item $1
  db.user.hash >equip_armour equip_armour $1
  var %wealth = 0
  var %i 1
  while ($store(list,%i)) {
    var %wep $store(list,%i)
    var %sname $store(list,%i).sname
    var %table $store(list,%i).table
    var %price $store(list,%i).sell
    inc %i
    if ($hget(> $+ %table,%wep)) {
      var %e %e %sname $+ $iif($v1 > 1,$+($chr(40),$v1,$chr(41)))
      inc %wealth $calc($v1 * %price)
    }
  }
  if ($hget(>equip_item,clue)) { var %e %e Clue:Scroll }
  if ($hget(>equip_item,snow)) { var %e %e Snow:Globe $+ $iif($v1 > 1,$+($chr(40),$v1,$chr(41))) }
  if ($hget(>equip_item,corr)) { var %e %e Cutlass:of:Corruption $+ $iif($v1 > 1,$+($chr(40),$v1,$chr(41))) }
  if ($hget(>equip_item,admin)) { var %e %e Magical:Ring }
  return $s1(Equipment) ( $+ $price(%wealth) $+ ): $iif(%e,$replace(%e,$chr(32),$chr(44) $+ $chr(32),$chr(58),$chr(32)),None) 
}

alias clan {
  return $s1(Clan) $+ : $s2($iif($getclanname($1),$v1,N/A))
}

alias sitems {
  if ($1 == $null) { putlog Syntax Error: sitems (1) - $db.safe($1-) | halt }
  db.user.hash >equips equip_staff $1

  if ($hget(>equips,belong)) { var %e %e Bêlong:Blade }
  if ($hget(>equips,allegra)) { var %e %e Allergy:Pills }
  if ($hget(>equips,beau)) { var %e %e Bêaumerang }
  if ($hget(>equips,snake)) { var %e %e $replace(One:Eyed:Trouser:Snake,e,$chr(233),E,É) }
  if ($hget(>equips,kh)) { var %e %e KHonfound:Ring }
  if ($hget(>equips,satan)) { var %e %e Satanic:Thingy }
  if ($hget(>equips,support)) { var %e %e The:Supporter }
  if ($hget(>equips,cookies)) { var %e %e Cookies( $+ $v1 $+ ) }

  return $iif(%e,$replace(%e,$chr(32),$chr(44) $+ $chr(32),$chr(58),$chr(32)))
}

alias pvp {
  if ($1 == $null) { putlog Syntax Error: pvp (1) - $db.safe($1-) | halt }
  db.user.hash >equipp equip_pvp $1

  if ($hget(>equipp,vspear)) { var %e %e $+(Vesta's:Spear,$chr(91),$s1($v1),$chr(93)) }
  if ($hget(>equipp,statius)) { var %e %e $+(Statius's:Warhammer,$chr(91),$s1($v1),$chr(93)) }
  if ($hget(>equipp,MJavelin)) { var %e %e $+(Morrigan's:Javelin,$chr(91),$s1($v1),$chr(93)) }

  return $iif(%e,$replace(%e,$chr(32),$chr(44) $+ $chr(32),$chr(58),$chr(32)))
}


on $*:TEXT:/^[!@.]ViewItems$/Si:%staffchans: {
  if ($db.get(admins,rank,address,$address($nick,3)) >= 2 && $me == iDM) {
    var %sql SELECT sum(belong = '1') as belong,sum(allegra = '1') as allegra,sum(beau = '1') as beau,sum(snake = '1') as snake,sum(kh = '1') as kh,sum(if(support = '0',0,1)) as support FROM `equip_staff`
    var %result = $db.query(%sql)
    if ($db.query_row(%result,>equip) === $null) { echo -s Error fetching Staff items totals. - %sql }
    db.query_end %result
    $iif($left($1,1) == @,msgsafe $chan,notice $nick) $logo(Special Items) Belong Blade: $s2($hget(>equip,belong)) Allergy Pills: $s2($hget(>equip,allegra)) $&
      Beaumerang: $s2($hget(>equip,beau)) One Eyed Trouser Snake: $s2($hget(>equip,snake)) KHonfound Ring: $s2($hget(>equip,kh)) $&
      The Supporter: $s2($hget(>equip,support))
  }
}

on $*:TEXT:/^[!@.]GiveItem .*/Si:%staffchan: {
  if ($db.get(admins,rank,address,$address($nick,3)) >= 3 && $me == iDM) {
    if (!$2) { notice You need to include a name you want to give your item too. }
    elseif ($whichitem($nick)) {
      var %item $v1
      if ($db.user.get(equip_staff,%item,$2) == 1) { notice $nick $logo(ERROR) $nick $2 already has your item | halt }
      db.user.set equip_staff %item $2 $iif(%item == support,$nick,1)
      $iif($left($1,1) == @,msgsafe $chan,notice $nick) $logo(Give-Item) Gave your item to $s2($2)
    }
    else { return }
  }
}

On $*:TEXT:/^[!@.]TakeItem .*/Si:%staffchan: {
  if ($db.get(admins,rank,address,$address($nick,3)) >= 3 && $me == iDM) {
    if (!$2) { notice You need to include a name you want to give your item too. }
    elseif ($whichitem($nick)) {
      var %item $v1
      if ($db.user.get(equip_staff,%item,$2) == 0) { notice $nick $logo(ERROR) $nick $2 doesn't have your item | halt }
      db.user.set equip_staff %item $2 0
      $iif($left($1,1) == @,msgsafe $chan,notice $nick) $logo(Take-Item) Took your item from $s2($2)
    }
    else { return }
  }
}

alias whichitem {
  if ($db.get(admins,name,address,$address($nick,3))) return $v1
  else return 0
}

alias webstrip {
  var %return = $1
  var %return = $strip($replace(%return,/,))
  if ($2) {
    var %return = $replace(%return,$chr(35),$wchr(23),$chr(63),$wchr(3F),$chr(38),$wchr(26),$chr(91),$wchr(5B),$chr(93),$wchr(5D),$chr(34),$wchr(22))
  }
  return %return
}

alias wchr {
  return $chr(37) $+ $1
}
