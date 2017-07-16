var margin = 16;
var maxWidth = window.innerWidth - margin;

var elements = document.getElementsByTagName('img');
for(var i=0; i<elements.length; i++)
{
  var image = elements[i];
  if (image.width > maxWidth)
  {
    var oldHeight = image.height;
    var scaleDown = maxWidth / image.width;
    image.width = scaleDown * image.width;
    if (image.height == oldHeight)
    {
      image.height = scaleDown * image.height
    }
  }
}
