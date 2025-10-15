/* Ruff! JS helpers
   To minimize:

   uglifyjs ruff.js -o ruff-min.js

 */

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

function ruffSetNavSide(navSide) {
    localStorage.ruff_nav_side = navSide;
    but = document.getElementById("ruffNavMove");
    // Note we set individual border properties as we do not want color to change */
    if (navSide === "right") {
        gridAreas = '"toparea toparea" "mainarea navarea" "botarea botarea"';
        gridCols = "1fr minmax(200px, min-content)";
        but.textContent = "\u25c0";
        but.style.setProperty("border-left", "none");
        but.style.setProperty("border-right-style", "solid");
        but.style.setProperty("border-right-width", "thick");
    } else {
        gridAreas = '"toparea toparea" "navarea mainarea" "botarea botarea"';
        gridCols = "minmax(200px, min-content) 1fr";
        but.textContent = "\u25b6";
        but.style.setProperty("border-right", "none");
        but.style.setProperty("border-left-style", "solid");
        but.style.setProperty("border-left-width", "thick");
    }
    document.documentElement.style.setProperty("--ruff-grid-template-areas", gridAreas);
    document.documentElement.style.setProperty("--ruff-grid-template-columns", gridCols);
}

function ruffMoveNavPane() {
    if (localStorage.ruff_nav_side === "left")
        ruffSetNavSide("right");
    else
        ruffSetNavSide("left");
}

// Immediately invoked function to set the theme on initial load
(function () {
    // Set up the themes
    themeNames = ["v1", "light", "dark", "slate", "solar", "clouds", "maroon"];
    // Store list of ruff themes since they may change between releases
    // localStorage can only contain strings
    localStorage.ruff_themes = JSON.stringify(themeNames);
    navSide = localStorage.ruff_nav_side;
    if (navSide !== "left" && navSide !== "right")
        navSide = "left";

    // Actual updating of DOM only to be done AFTEr load is done
    window.onload = init;
    function init () {
        currentTheme = localStorage.ruff_theme;
        if (currentTheme === undefined || themeNames.indexOf(currentTheme) < 0) {
            currentTheme = "v1";
        }
        ruffSetTheme(currentTheme);

        // Set up the navigation layout
        navSide = localStorage.ruff_nav_side;
        if (navSide !== "right")
            navSide = "left";
        ruffSetNavSide(navSide);
    }
})();

// Global icon SVGs for the copy button.
const COPY_ICON_SVG = `<svg viewBox="0 0 24 24">
    <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
    <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
</svg>`;

const COPIED_ICON_SVG = `<svg viewBox="0 0 24 24">
    <polyline points="20 6 9 17 4 12"></polyline>
</svg>`;

// Create the copy button automatically after the DOM is loaded.
document.addEventListener('DOMContentLoaded', function() {
    const figures = document.querySelectorAll('.ruff-snippet.ruff-figure');
    
    figures.forEach(function(figure) {
        const button = document.createElement('button');
        button.className = 'ruff-copy-btn';
        button.title = 'Copy text';
        button.onclick = function() {copyTextRuffFigure(this);};
        button.innerHTML = COPY_ICON_SVG;
        figure.insertBefore(button, figure.firstChild);
    });
});

// Copies the content of a figure element to the clipboard.
function copyTextRuffFigure(bouton) {
    const figure = bouton.closest('.ruff-figure');
    const pre = figure.querySelector('pre');
    const texte = pre.innerText;
    
    navigator.clipboard.writeText(texte).then(() => {
        bouton.innerHTML = COPIED_ICON_SVG;
        bouton.classList.add('copied');
        
        setTimeout(() => {
            // Reset the button after a short delay.
            bouton.innerHTML = COPY_ICON_SVG;
            bouton.classList.remove('copied');
        }, 1000);
    }).catch(err => {
        console.error('Error copying text:', err);
        alert('Not possible to copy the text.');
    });
}