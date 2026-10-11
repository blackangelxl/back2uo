/*
	Back2Uo v2.1 - String utilities: explode, strip, splitArray, findStr.
*/

/*
=============
explode

Splits a string on a single-character delimiter. Empty fields are kept.
Params: s - string to split
		delimiter - one character
Returns: array of substrings
=============
*/
explode(s,delimiter)
{
	j=0;
	temparr[j] = "";

	for(i=0;i<s.size;i++)
	{
		if(s[i]==delimiter)
		{
			j++;
			temparr[j] = "";
		}
		else
			temparr[j] += s[i];
	}

	return temparr;
}

/*
=============
strip

Removes leading and trailing spaces (spaces only, not tabs).
Params: s - string to trim
Returns: trimmed string
=============
*/
strip(s)
{
	if(s=="") return "";

	s2="";
	s3="";
	i=0;

	// Skip leading spaces.
	while(i<s.size && s[i]==" ")

		i++;

	if(i==s.size) return "";

	for(;i<s.size;i++)
	{
		s2 += s[i];
	}

	// Find the last non-space character.
	i=s2.size-1;

	while(s2[i]==" " && i>0)

		i--;

	for(j=0;j<=i;j++)
	{
		s3 += s2[j];
	}

	return s3;
}

/*
=============
splitArray

Splits a string into a (possibly nested) array. Each character of sep is one nesting
level: sep[0] splits the top level, sep[1] splits each field again, and so on.
Separators inside quote characters are ignored.
Params: str - string to split
		sep - separator characters, one per level (default ";")
		quote - quote character (default none)
		skipEmpty - if defined (any value), empty fields are dropped
Returns: array of strings for a single level; for nested levels each element is
		 an array with ["str"] (raw field) and ["fields"] (sub-split)
=============
*/
splitArray( str, sep, quote, skipEmpty )
{
	if(!isdefined(str) || str == "") return ( [] );

	if(!isdefined(sep) || sep == "") sep = ";";	// Default separator

	if(!isdefined(quote)) quote = "";

	// Only presence matters: any defined value enables skipping.
	skipEmpty = isdefined( skipEmpty );
	a = _splitRecur( 0, str, sep, quote, skipEmpty );

	return ( a );
}

/*
=============
_splitRecur

Recursive worker for splitArray; splits str on sep[iter] and recurses for deeper levels.
Params: iter - current nesting level (index into sep)
		str, sep, quote, skipEmpty - see splitArray
Returns: array for this level
=============
*/
_splitRecur( iter, str, sep, quote, skipEmpty )
{
	s = sep[ iter ];
	_a = [];
	_s = "";
	doQuote = false;

	for(i = 0; i < str.size; i++)
	{
		ch = str[i];

		if(ch == quote)
		{
			doQuote = !doQuote;

			// Keep the quote characters while deeper levels still need them.
			if(iter + 1 < sep.size) _s += ch;
		}
		else
			if(ch == s && !doQuote )
			{
				// End of a field.
				if( _s != "" || !skipEmpty)
				{
					_l = _a.size;

					if(iter + 1 < sep.size)
					{
						_x = _splitRecur( iter + 1, _s,	sep, quote, skipEmpty );

						if(_x.size > 0 || !skipEmpty)
						{
							_a[ _l ][ "str" ] = _s;
							_a[ _l ][ "fields" ] = _x;
						}
					}
					else
						_a[ _l ] = _s;
				}

				_s = "";
		}
		else
			_s += ch;
	}

	// Flush the last field (no trailing separator).
	if( _s != "")
	{
		_l = _a.size;

		if(iter + 1 < sep.size)
		{
			_x = _splitRecur( iter + 1, _s, sep, quote, skipEmpty);

			if(_x.size > 0 )
			{
				_a[ _l ][ "str" ] = _s;
				_a[ _l ][ "fields" ] = _x;
			}
		}
		else
			_a[ _l ] = _s;
	}

	return ( _a );
}

/*
=============
findStr

Searches for a substring.
Params: find - substring to look for
		str - string to search in
		pos - "start" (match only at the beginning), "end" (match only at the end),
			  anything else searches the whole string
Returns: index of the match, or -1
=============
*/
findStr( find, str, pos )
{
	if ( !isdefined( find ) || ( find == "" ) || !isdefined( str ) || !isdefined( pos ) || ( find.size > str.size ) ) return ( -1 );

	fsize = find.size;
	ssize = str.size;

	switch ( pos )
	{
	case "start":
		place = 0 ;
		break;

	case "end":
		place = ssize - fsize;
		break;

	default:
		place = 0 ;
		break;
	}

	for ( i = place; i < ssize; i++ )
	{
		if ( i + fsize > ssize ) break;

		// Compare character by character; j reaches fsize on a full match.
		for ( j = 0; j < fsize; j++ )

			if ( str[ i + j ] != find[ j ] ) break;

		if ( j >= fsize ) return ( i );

		// "start" only checks position 0.
		if ( pos == "start" ) break;
	}

	return ( -1 );
}
