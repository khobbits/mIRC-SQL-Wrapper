/*
** mIRC MySQL v1.0.1
**
** Author: Reko Tiira [ ramirez ]
** E-mail: reko@tiira.net
** Date: 18th August 2009
** IRC: ramirez @ irc.undernet.org [ #mircscripting ]
**      ramirez @ irc.swiftirc.net [ #msl ]
*/

/*
** MySQL Constants
*/

alias MYSQL_OK                   return 0

alias MYSQL_BOTH                 return 1
alias MYSQL_NUM                  return 2
alias MYSQL_ASSOC                return 3

alias MYSQL_ALL                  return 1
alias MYSQL_BOUND                return 2

alias MYSQL_ERROR_OK             return 0
alias MYSQL_ERROR_INVALIDARG     return 3000
alias MYSQL_ERROR_BIND           return 3001
alias MYSQL_ERROR_NOMOREROWS     return 3002
alias MYSQL_ERROR_FETCH          return 3003
alias MYSQL_ERROR_NOMOREFIELDS   return 3004

/*
** On Load Event
*/

on *:LOAD:{
  echo 3 -a mIRC MySQL loaded successfully.
}

/*
** MySQL DLL Path
*/

alias -l mysql_dll return $qt($+($scriptdir,mmysql.dll))

/*
** MySQL Internals
*/

alias mysql_param return $qt($replace($1, \, \\, ", \"))

alias mysql_help {
  run $+($scriptdir,mmysql.chm)
}

alias mysql_version {
  return $dll($mysql_dll, mmysql_version,)
}

alias mysql_qt {
  return $+(',$1-,')
}

alias mysql_connect {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  if ($0 >= 3) %params = %params $mysql_param($3)
  if ($0 >= 4) %params = %params $mysql_param($4)
  return $dll($mysql_dll, mmysql_connect, %params)
}

alias mysql_close {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_close, %params)
}

alias mysql_select_db {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  return $dll($mysql_dll, mmysql_select_db, %params)
}

alias mysql_ping {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_ping, %params)
}

alias mysql_set_charset {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($1)
  return $dll($mysql_dll, mmysql_set_charset, %params)
}

alias mysql_autocommit {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($1)
  return $dll($mysql_dll, mmysql_autocommit, %params)
}

alias mysql_get_client_info {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_get_client_info, %params)
}

alias mysql_get_host_info {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_get_host_info, %params)
}

alias mysql_get_proto_info {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_get_proto_info, %params)
}

alias mysql_get_server_info {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_get_server_info, %params)
}

alias mysql_client_encoding {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_client_encoding, %params)
}

alias mysql_escape_string {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_escape_string, %params)
}

alias mysql_real_escape_string {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  return $dll($mysql_dll, mmysql_real_escape_string, %params)
}

alias mysql_query {
  var %params
  if ($0 >= 1) {
    %params = $mysql_param($1) 1
    if (!$mysql_is_valid_statement($1)) {
      %params = %params $iif($isid && $prop == file, 1, 0)
      if (!$isid) {
        var %query, %i = 2
        while (%i <= $0) {
          %query = %query $ [ $+ [ %i ] ]
          inc %i
        }
        %params = %params $mysql_param(%query)
      }
    }
    if ($isid) {
      var %i = 2
      while (%i <= $0) {
        %params = %params $mysql_param($ [ $+ [ %i ] ])
        inc %i
      }
    }      
  }
  return $dll($mysql_dll, mmysql_query, %params)
}

alias mysql_unbuffered_query {
  var %params
  if ($0 >= 1) {
    %params = $mysql_param($1) 2
    if (!$mysql_is_valid_statement($1)) {
      %params = %params $iif($isid && $prop == file, 1, 0)
      if (!$isid) {
        var %query, %i = 2
        while (%i <= $0) {
          %query = %query $ [ $+ [ %i ] ]
          inc %i
        }
        %params = %params $mysql_param(%query)
      }
    }
    if ($isid) {
      var %i = 2
      while (%i <= $0) {
        %params = %params $mysql_param($ [ $+ [ %i ] ])
        inc %i
      }
    }      
  }
  return $dll($mysql_dll, mmysql_query, %params)
}

alias mysql_exec {
  var %params
  if ($0 >= 1) {
    %params = $mysql_param($1) 3
    if (!$mysql_is_valid_statement($1)) {
      %params = %params $iif($isid && $prop == file, 1, 0)
      if (!$isid) {
        var %query, %i = 2
        while (%i <= $0) {
          %query = %query $ [ $+ [ %i ] ]
          inc %i
        }
        %params = %params $mysql_param(%query)
      }
    }
    if ($isid) {
      var %i = 2
      while (%i <= $0) {
        %params = %params $mysql_param($ [ $+ [ %i ] ])
        inc %i
      }
    }      
  }
  return $dll($mysql_dll, mmysql_query, %params)
}

alias mysql_exec_file {
  if ($isid) {
    var %params, %i = 1
    while (%i <= $0) {
      %params = $+(%params,$iif(%params,$chr(44)),$ $+ %i)
      inc %i
    }
    var %cmd = $!mysql_exec( $+ %params $+ ).file
    return [ [ %cmd ] ]
  }
  return $mysql_exec($1, $2).file
}

alias mysql_free {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_free, %params)
}

alias mysql_free_result {
  return $mysql_free($1)
}

alias mysql_num_rows {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_num_rows, %params)
}

alias mysql_num_fields {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_num_fields , %params)
}

alias mysql_affected_rows {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_affected_rows, %params)
}

alias mysql_insert_id {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_insert_id, %params)
}

alias mysql_fetch_row {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($gettok($2,1,32))
  if ($0 >= 3) %params = %params $mysql_param($3)
  return $dll($mysql_dll, mmysql_fetch_row, %params)
}

alias mysql_fetch_num {
  return $mysql_fetch_row($1, $2, $MYSQL_NUM)
}

alias mysql_fetch_assoc {
  return $mysql_fetch_row($1, $2, $MYSQL_ASSOC)
}

alias mysql_fetch_bound {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  tokenize 32 $dll($mysql_dll, mmysql_fetch_bound, %params)
  if ($0 == 1) {
    return $1
  }
  if ($0 == 3) {
    var %file = $1, %i = 1, %total = $numtok($2, 124), %offset = 0
    while (%i <= %total) {
      var %size = $gettok($2, %i, 124), %bvar = $gettok($3, %i, 124)
      bread %file %offset %size %bvar
      inc %offset %size
      inc %i
    }
    return 1
  }
  return $null
}

alias mysql_fetch_single {
  if ($0 < 2) {
    return $dll($mysql_dll, mmysql_fetch_single, $iif($0 >= 1, $mysql_param($1)))
  }
  else {
    tokenize 32 $dll($mysql_dll, mmysql_fetch_single, $mysql_param($1) $mysql_param($2))
    if ($0 == 3) {
      bread $1 0 $2 $3
      return $bvar($3, 0)
    }
    return $null
  }
}

alias mysql_fetch_field {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) {
    var %name = $iif($2 !isnum || $prop == name, 1, 0)
    %params = %params %name $mysql_param($2) 0
  }
  if ($0 < 3) {
    return $dll($mysql_dll, mmysql_fetch_field, %params)
  }
  else {
    %params = %params $mysql_param($3)
    tokenize 32 $dll($mysql_dll, mmysql_fetch_field, %params)
    if ($0 == 3) {
      bread $1 0 $2 $3
      return $bvar($3, 0)
    }
    return $null
  }
}

alias mysql_fetch_all {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  if ($0 >= 3) %params = %params $mysql_param($3)
  return $dll($mysql_dll, mmysql_fetch_all, %params)
}

alias mysql_result {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) {
    var %name = $iif($2 !isnum || $prop == name, 1, 0)
    %params = %params %name $mysql_param($2) 1
  }
  if ($0 < 3) {
    return $dll($mysql_dll, mmysql_fetch_field, %params)
  }
  else {
    %params = %params $mysql_param($3)
    tokenize 32 $dll($mysql_dll, mmysql_fetch_field, %params)
    if ($0 == 3) {
      bread $1 0 $2 $3
      return $bvar($3, 0)
    }
    return $null
  }
}

alias mysql_data_seek {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  return $dll($mysql_dll, mmysql_data_seek, %params)
}

alias mysql_is_valid_connection {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_is_valid_connection, %params)
}

alias mysql_is_valid_result {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_is_valid_result, %params)
}

alias mysql_is_valid_statement {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_is_valid_statement, %params)
}

alias mysql_begin {
  return $mysql_exec($mysql_param($1), BEGIN)
}

alias mysql_commit {
  return $mysql_exec($mysql_param($1), COMMIT)
}

alias mysql_rollback {
  return $mysql_exec($mysql_param($1), ROLLBACK)
}

alias mysql_prepare {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $iif($isid && $prop == file, 1, 0) $mysql_param($2)
  return $dll($mysql_dll, mmysql_prepare, %params)
}

alias mysql_bind_field {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) {
    var %name = $iif($2 !isnum || $prop == name, 1, 0)
    %params = %params %name $mysql_param($2)
  }
  if ($0 >= 3) {
    %params = %params $mysql_param($3)
  }
  return $dll($mysql_dll, mmysql_bind_field, %params)
}

alias mysql_bind_column {
  return $mysql_bind_field($1, $2, $3)
}

alias mysql_bind_param {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  if ($0 >= 3) %params = %params $mysql_param($3)
  return $dll($mysql_dll, mmysql_bind_param, %params)
}

alias mysql_bind_value {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  if ($0 >= 3) {
    var %value, %i = 3
    while (%i <= $0) {
      %value = %value $ [ $+ [ %i ] ]
      inc %i
    }
    %params = %params $mysql_param(%value)
  }
  return $dll($mysql_dll, mmysql_bind_value, %params)
}

alias mysql_bind_null {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  return $dll($mysql_dll, mmysql_bind_null, %params)
}

alias mysql_clear_bindings {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_bind_null, %params)
}

alias mysql_fetch_field_info {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($gettok($2,1,32))
  if ($0 >= 3) %params = %params $mysql_param($3)
  return $dll($mysql_dll, mmysql_fetch_field_info, %params)
}

alias mysql_field_info_seek {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  return $dll($mysql_dll, mmysql_field_info_seek, %params)
}

alias mysql_field_name {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  return $dll($mysql_dll, mmysql_field_name, %params)
}

alias mysql_field_type {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  return $dll($mysql_dll, mmysql_field_type, %params)
}

alias mysql_field_len {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  return $dll($mysql_dll, mmysql_field_len, %params)
}

alias mysql_field_table {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  return $dll($mysql_dll, mmysql_field_table, %params)
}

alias mysql_field_flags {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  return $dll($mysql_dll, mmysql_field_flags, %params)
}

alias mysql_safe_encode {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  return $dll($mysql_dll, mmysql_safe_encode, %params)
}

alias mysql_safe_decode {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_safe_decode, %params)
}
