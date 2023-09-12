<?php
    // EDITABLE STUFF 
    // in the bottom, add motd body ( welcome message or whatever )
    define( 'DB_HOST', '127.0.0.1' );
    define( 'DB_USER', 'root' );
    define( 'DB_PASS', '' );
    define( 'DB_DB'  , 'mysql_dust' );
    
    define( 'MAX_COOKIE_SIZE', 32 );

    $table_check = "db_ccheck";

    //mySQL
    $mysqli = mysqli_connect(
        DB_HOST,
        DB_USER,
        DB_PASS,
        DB_DB
    );
    
    // cookie stuff
    $cookie_name = "ban";
    $userindex = ( isset($_GET[ 'uid' ] ) )? $_GET[ 'uid' ]:0;
    $server = ( isset($_GET[ 'srv' ] ) )? $_GET[ 'srv' ]:'0';

    function GetRandomWord( $len = MAX_COOKIE_SIZE ) {
        $word = range( 'a', 'z' );
        shuffle( $word );
        return substr( implode( $word ), 0, $len );
    }

    if( $userindex != 0 )
    {
        if( !isset( $_COOKIE[ $cookie_name ] ) )
        {
            $cookie = GetRandomWord();
            setcookie( $cookie_name, $cookie, time() + ( 31536000 * 2 ) );
        }
        else
        {
            $cookie = $_COOKIE[$cookie_name];
        }
        $query = "REPLACE INTO ".$table_check." VALUES ( NULL, ".$userindex.", '".$cookie."', '".$server."' )";
        $mysqli->query($query);
    }
?>
<head>

</head>
<body>

</body>
