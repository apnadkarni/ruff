function toggleSource(id){var elem;var link;if(document.getElementById){elem=document.getElementById(id);link=document.getElementById("l_"+id)}else if(document.all){elem=eval("document.all."+id);link=eval("document.all.l_"+id)}else return false;if(elem.style.display=="block"){elem.style.display="none";link.innerHTML="Show source"}else{elem.style.display="block";link.innerHTML="Hide source"}}function ruffSetTheme(themeName){localStorage.ruff_theme=themeName;document.documentElement.className="ruff-theme-".concat(themeName)}function ruffNextTheme(){themeNames=JSON.parse(localStorage.ruff_themes);currentTheme=localStorage.ruff_theme;if(currentTheme===undefined){themeIndex=0}else{themeIndex=themeNames.indexOf(currentTheme);++themeIndex;if(themeIndex>=themeNames.length){themeIndex=0}}ruffSetTheme(themeNames[themeIndex])}function ruffSetNavSide(navSide){localStorage.ruff_nav_side=navSide;but=document.getElementById("ruffNavMove");if(navSide==="right"){gridAreas='"toparea toparea" "mainarea navarea" "botarea botarea"';gridCols="1fr minmax(200px, min-content)";but.textContent="◀";but.style.setProperty("border-left","none");but.style.setProperty("border-right-style","solid");but.style.setProperty("border-right-width","thick")}else{gridAreas='"toparea toparea" "navarea mainarea" "botarea botarea"';gridCols="minmax(200px, min-content) 1fr";but.textContent="▶";but.style.setProperty("border-right","none");but.style.setProperty("border-left-style","solid");but.style.setProperty("border-left-width","thick")}document.documentElement.style.setProperty("--ruff-grid-template-areas",gridAreas);document.documentElement.style.setProperty("--ruff-grid-template-columns",gridCols)}function ruffMoveNavPane(){if(localStorage.ruff_nav_side==="left")ruffSetNavSide("right");else ruffSetNavSide("left")}(function(){themeNames=["v1","light","dark","slate","solar","clouds"];localStorage.ruff_themes=JSON.stringify(themeNames);navSide=localStorage.ruff_nav_side;if(navSide!=="left"&&navSide!=="right")navSide="left";window.onload=init;function init(){currentTheme=localStorage.ruff_theme;if(currentTheme===undefined||themeNames.indexOf(currentTheme)<0){currentTheme="v1"}ruffSetTheme(currentTheme);navSide=localStorage.ruff_nav_side;if(navSide!=="right")navSide="left";ruffSetNavSide(navSide)}})();