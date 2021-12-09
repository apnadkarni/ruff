// Hacked from various web sources without any understanding of JS!
// Improvements with better Javascript most welcomed!

function myIndexInit() {
    var single, nvisible, urltext, a;

    filterElement = document.getElementById('filterText');
    urltext = myGetUrlParameter('lookup');
    if (urltext == '') {
        urltext = myGetUrlParameter('search');
    }
    if (urltext != '') {
        filterElement.value = urltext;
        myRunFilter();
    }
    filterElement.focus();
}

function myGetUrlParameter(name) {
    name = name.replace(/[\[]/, '\\[').replace(/[\]]/, '\\]');
    var regex = new RegExp('[\\?&]' + name + '=([^&#]*)');
    var results = regex.exec(location.search);
    return results === null ? '' : decodeURIComponent(results[1].replace(/\+/g, ' '));
};

var myDebounceDelay;
var myUserAgent = navigator.userAgent.toUpperCase();
if (myUserAgent.indexOf("MSIE") != -1 || myUserAgent.indexOf("TRIDENT") != -1 ) {
    //console.log("Internet Explorer");
    myDebounceDelay = 300;
}
else if (myUserAgent.indexOf("EDGE") != -1 ) {
    //console.log("Edge");
    myDebounceDelay = 300;
} else {
    //console.log(navigator.userAgent);
    myDebounceDelay = 100;
}

// From underscore.js
// See https://davidwalsh.name/javascript-debounce-function
// Returns a function, that, as long as it continues to be invoked, will not
// be triggered. The function will be called after it stops being called for
// N milliseconds. If `immediate` is passed, trigger the function on the
// leading edge, instead of the trailing.
function myDebounce(func, wait, immediate) {
    var timeout;
    return function() {
	var context = this, args = arguments;
	var later = function() {
	    timeout = null;
	    if (!immediate) func.apply(context, args);
	};
	var callNow = immediate && !timeout;
	clearTimeout(timeout);
	timeout = setTimeout(later, wait);
	if (callNow) func.apply(context, args);
    };
};

function mySetStatus(text) {
    var status;
    status    = document.getElementById("indexStatus");
    status.innerText = text;
}

function myResetStatus() {
    var status;
    status    = document.getElementById("indexStatus");
    // Set to &nbsp because blank space or empty string causes layout to change.
    status.innerText = "\xa0";
}

function myRunFilter() {
    // Declare variables
    var input, filter, filter0, ul, li, a, i, txtValue, matchSeen, firstMatch;
    input = document.getElementById('filterText');
    filter = input.value.toUpperCase();
    filter0 = filter.charAt(0);
    ul = document.getElementById("indexUL");
    li = ul.getElementsByTagName('li');
    if (filter == "") {
        myResetStatus();
        for (i = 0; i < li.length; i++) {
            li[i].style.display = "";
        }
    } else {
        // Loop through all list items, and hide those who don't match the search query
        matchSeen = 0;
        firstMatch = -1;
        for (i = 0; i < li.length; i++) {
            a = li[i].getElementsByTagName('a')[0];
            txtValue = a.textContent || a.innerText;
            txtValue = txtValue.toUpperCase();
            if ((txtValue.charAt(0) == filter0) && (txtValue.startsWith(filter))) {
                if (myLastKey == 13) {
                    myResetStatus();
                    //window.open(a.href, 'CF');
                    document.location.href = a.href;
                    return;
                } else {
                    li[i].style.display = "";
                    matchSeen++;
                    if (firstMatch == -1)
                        firstMatch = i;
                }
            } else {
                // Because index terms are sorted, if we previously saw a match
                // but this term did not match, then no more terms can match.
                if (matchSeen) {
                    break;
                }
                li[i].style.display = "none";
            }
        }
        for (; i < li.length; i++) {
            li[i].style.display = "none";
        }
        myResetStatus();
        if (matchSeen == 1) {
            //a = li[firstMatch].getElementsByTagName('a')[0];
            //window.open(a.href, 'CF');
        }
    }
}

var myFilterFunction = myDebounce(myRunFilter, myDebounceDelay);

var myLastKey = 0;
function myFilterHook() {
    myLastKey = event.keyCode;
    mySetStatus("Searching...");
    myFilterFunction();
}

