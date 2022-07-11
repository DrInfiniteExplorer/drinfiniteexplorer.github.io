
var modal = document.getElementById("ClickyImage");

// Get the image and insert it inside the modal - use its "alt" text as a caption
//var img = document.getElementById("myImg");
var modalImg = document.getElementById("img01");
var captionText = document.getElementById("caption");

var images = []

document.querySelectorAll('.clickyImg > img,img.clickyImg').forEach(function(img) {
    console.log(img)
    img.onclick=function() {
        modal.style.display = "block";
        modalImg.src = img.src;
        captionText.innerHTML = img.alt;
    }
    images += (img)
});

// Get the <span> element that closes the modal
var span = document.getElementsByClassName("close")[0];
// When the user clicks on <span> (x), close the modal
span.onclick = function() { 
    //modal.style.display = "none";
}

modal.onclick = function() { 
    modal.style.display = "none";
}

console.log(images)