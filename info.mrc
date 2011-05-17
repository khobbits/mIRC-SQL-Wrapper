alias hlist {
  echo -aic info -
  if ($1 == $null) {
    var %i = 1, %n = $hget(0)
    WHILE %i <= %n {
      echo -aic info * %i $+ : $hget(%i) ( $+ $hget(%i,0).item $+ / $+ $hget(%i).size $+ )
      inc %i
  } } 
  else {
    var %t = $hget($1)
    var %i = 1, %n = $hget(%t,0).item
    WHILE %i <= %n {
      var %item = $hget(%t,%i).item, %data = $hget(%t,%item), %unset = $hget(%t,%item).unset
      echo -aic info * $base(%i,10,10,3) $+ : %t $+ : $iif(%unset,[[ $+ %unset $+ s]) %item = %data
      inc %i
  } }
  echo -aic info End of /HLIST: %n item(s).
  echo -aic info -
}
