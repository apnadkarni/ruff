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


/***
 * Color theming support from https://dev.to/ananyaneogi/create-a-dark-light-mode-switch-with-css-variables-34l8
 *
 * NOTE: for file URL's local storage is per-file so is not maintained between files.
 * It will still persist for http urls.
*/



function ruffSetTheme(themeName) {
    localStorage.setItem('ruff_theme', themeName);
    document.documentElement.className = themeName;
}

// function to toggle between light and dark theme
function ruffToggleTheme() {
    if (localStorage.getItem('ruff_theme') === 'ruff-theme-dark') {
        ruffSetTheme('ruff-theme-light');
    } else {
        ruffSetTheme('ruff-theme-dark');
    }
}

// Immediately invoked function to set the theme on initial load
(function () {
    if (localStorage.getItem('ruff_theme') === 'ruff-theme-dark') {
        ruffSetTheme('ruff-theme-dark');
    } else {
        ruffSetTheme('ruff-theme-light');
    }
})();
