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
 * NOTE: for file URL's local storage is per-file so is not maintained between files.
 * It will still persist for http urls.
 * Someone who actually knows Javascript please rewrite this!
*/

function ruffSetTheme(themeName) {
    console.log(themeName);
    localStorage.ruff_theme = themeName;
    document.documentElement.className = "ruff-theme-".concat(themeName);
}

function ruffNextTheme() {
    themeNames = JSON.parse(localStorage.ruff_themes);
    currentTheme = localStorage.ruff_theme;
    if (currentTheme === undefined) {
        themeIndex = 0;
    } else {
        themeIndex = themeNames.indexOf(currentTheme);
        ++themeIndex;
        if (themeIndex >= themeNames.length) {
            themeIndex = 0;
        }
    }
    ruffSetTheme(themeNames[themeIndex]);
}

// Immediately invoked function to set the theme on initial load
(function () {
    // Store list of ruff themes since they may change between releases
    themeNames = ["v1", "dark", "light"];
    // localStorage can only contain strings
    localStorage.ruff_themes = JSON.stringify(themeNames);
    currentTheme = localStorage.ruff_theme;
    if (currentTheme === undefined || themeNames.indexOf(currentTheme) < 0) {
        currentTheme = "v1";
    }
    ruffSetTheme(currentTheme);
})();
