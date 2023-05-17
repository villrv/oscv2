const form = document.getElementById("sdb-search-form");

#form.addEventListener('submit', handleSubmit);

var errModal      = document.getElementById("errModal");
var errModalClose = document.getElementsByClassName("close")[0];
var errList       = document.getElementById("problemsList");


errModalClose.Close = function() {
    errModal.style.display = "none";
}

window.onclick = function(event) {
  if (event.target == errModal) {
    errModal.style.display = "none";
  }
} 

//
// Expect a json object.
//
function showProblems (ret) {
    errList.innerHTML = '';
    problems = ret.problems;
    problems.map(function(p) {var li = document.createelement("li"); li.appendChild(document.createTextNode(p)); errList.appendChild(li);});
    errModal.style.display = "block";
}

function redirectOk (id) {
    location.href = '/rise-proposal/success?id='+id;
}

function handleSubmit (e) {
    e.preventDefault();
    var http = new XMLHttpRequest();
    console.log("hello, ron\n");
    if (formIsValid(form)) {
	fetch(form.action, {method:'post', body: new FormData(form)}).then(response => response.json()).then(data => {console.log(data); if (data.ok) {redirectOk(data.projectId);} else {showProblems(data); } return data; } );
    }
//    http.open("POST", "https://riseprojects.vmhost.psu.edu/rise-proposal/process", true);
//    http.setRequestHeader("Content-type","application/x-www-form-urlencoded");
}

function formIsValid (form) {
    console.log("form:");
    console.log(form);
    valid = true;
    var problems = [];
    for (i=0; i<form.elements.length; i++) {
	elem = form.elements[i];
	elem.checkValidity();
	if (!elem.validity.valid) {
	    console.log("Not valid:");
	    console.log(elem);
	    console.log(elem.validationMessage);
	}
    }
    return true;
}

