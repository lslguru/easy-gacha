define( [ ] , function( ) {
    'use strict';

    // With high praise to http://www.linuxjournal.com/article/9585
    // Finally someone who gets it! Now... to clean it up and make it
    // Comtraya!
    function validateEmailAddress( addressString )
    {
        var atIndex = addressString.lastIndexOf("@");
        if( -1 == atIndex || 0 == atIndex || undefined == atIndex || null == atIndex ) return false;

        var local = addressString.substr( 0 , atIndex );
        var localLen = local.length;

        var domain = addressString.substr( atIndex + 1 );
        var domainLen = domain.length;

        var rTwoConsecutiveDots = new RegExp(/\.\./);
        var rFullStringValidDomainChars = new RegExp(/^[A-Za-z0-9-.]+$/);
        var rFullStringValidLocalChars = new RegExp(/^(\\.|[A-Za-z0-9!#%&`_=\/$'*+?^{}|~.-])+$/);
        var rStringQuoted = new RegExp(/^"(\\"|[^"])+"$/);

        if( localLen < 1 ) return false; // local part too short
        if( localLen > 64 ) return false; // local part too long
        if( domainLen < 1 ) return false; // domain part too short
        if( domainLen > 255 ) return false; // domain part too long
        if( local.substr(0,1) == '.' ) return false; // local part starts with '.'
        if( local.substr( localLen - 1 ) == '.' ) return false; // local ends with '.'
        if( domain.substr( domainLen - 1 ) == '.' ) return false; // domian ends with '.'

        if( rTwoConsecutiveDots.test( local ) ) return false; // local part has two consecutive dots
        if( rTwoConsecutiveDots.test( domain ) ) return false; // domain part has two consecutive dots
        if( ! rFullStringValidDomainChars.test( domain ) ) return false; // character not valid in domain part
        if( ! ( rFullStringValidLocalChars.test( local ) || rStringQuoted.test( local ) ) ) return false; // character not valid in local part unless local part is quoted

        return true;
    }

    return validateEmailAddress;

} );
