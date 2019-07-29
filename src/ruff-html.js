function toggleSource( id )
{
    /* Copied from Rails */
    var elem
    var link

    if( document.getElementById )
    {
        elem = document.getElementById( id )
        link = document.getElementById( "l_" + id )
    }
    else if ( document.all )
    {
        elem = eval( "document.all." + id )
        link = eval( "document.all.l_" + id )
    }
    else
        return false;

    if( elem.style.display == "block" )
    {
        elem.style.display = "none"
        link.innerHTML = "Show source"
    }
    else
    {
        elem.style.display = "block"
        link.innerHTML = "Hide source"
    }
}
