
var images = new Array();
images[0]= "Resources\\ColoredBalls.jpg";
images[1]= "Resources\\Sample5.cmp";
images[2]= "Resources\\ColoredPencils.jpg";
images[3]= "Resources\\NaturalFruits.jpg";
images[4]= "Resources\\ColoredWindows.jpg";

window.onload = function()
{
   ActivateImageProcessingButtons();
   setHoverProperty();
   loadXML('Resources/ImageSettings.xml');
}

var xmlDoc;
var XMLChangeContrast;
var XMLChangeHue;
var XMLChangeIntensity;
var XMLChangeSaturation;
var XMLEmboss;
var XMLGaussian;
var XMLGamma;
var XMLGrayscale;
var XMLHistogramContrast;
var XMLMedian;
var XMLRemapHue;
var XMLSharpen;
var XMLSpatialFilter;
var XMLUnsharpMask;
var XMLfreeHandWave;
var XMLHalfTone;
var XMLAutoCrop;

function loadXML(xmlFile)
{
   // code for IE
   if (window.ActiveXObject)
   {
      xmlDoc= new ActiveXObject("Microsoft.XMLDOM");
      xmlDoc.async="false";
   }
   // code for Mozilla, Firefox, Opera, etc.
   else if (document.implementation && document.implementation.createDocument)
   {
      xmlDoc=document.implementation.createDocument("","",null);
   }
   else
   {
      alert('Your browser cannot handle this script');
   }
   
   //Load the xmlFile
   try {
      xmlDoc.load(xmlFile);
   }
   catch (e) {
      // Chrome doesn't support xmlDoc.load
      var xmlhttp = new window.XMLHttpRequest();
      xmlhttp.open("GET", xmlFile, false);
      xmlhttp.send(null);
      xmlDoc = xmlhttp.responseXML.documentElement;
   }   
   
   XMLChangeContrast = xmlDoc.getElementsByTagName("ChangeContrast");
   XMLChangeHue = xmlDoc.getElementsByTagName("ChangeHue");
   XMLChangeIntensity = xmlDoc.getElementsByTagName("ChangeIntensity");
   XMLChangeSaturation = xmlDoc.getElementsByTagName("ChangeSaturation");
   XMLEmboss= xmlDoc.getElementsByTagName("Emboss");
   XMLGaussian = xmlDoc.getElementsByTagName("Gaussian");
   XMLGamma = xmlDoc.getElementsByTagName("GammaCorrect");
   XMLGrayscale = xmlDoc.getElementsByTagName("Grayscale");
   XMLHistogramContrast = xmlDoc.getElementsByTagName("HistogramContrast");
   XMLMedian = xmlDoc.getElementsByTagName("Median");
   XMLRemapHue = xmlDoc.getElementsByTagName("RemapHue");
   XMLSharpen = xmlDoc.getElementsByTagName("Sharpen");
   XMLSpatialFilter = xmlDoc.getElementsByTagName("SpatialFilter");
   XMLUnsharpMask = xmlDoc.getElementsByTagName("UnsharpMask");
   XMLfreeHandWave = xmlDoc.getElementsByTagName("freeHandWave");
   XMLHalfTone = xmlDoc.getElementsByTagName("HalfTone");
   XMLAutoCrop = xmlDoc.getElementsByTagName("AutoCrop");
}

function ActivateImageProcessingButtons()
{
   document.getElementById("btnFitWidth").onclick = function(){return btnFitWidth_onclick()};
   document.getElementById("btnView1to1").onclick = function(){return btnView1to1_onclick()};
   document.getElementById("btnFit").onclick = function(){return btnFit_onclick()};
   document.getElementById("btnZoomIn").onclick = function(){return btnZoomIn_onclick()};
   document.getElementById("btnZoomOut").onclick = function(){return btnZoomOut_onclick()};
   document.getElementById("btnFlipHor").onclick = function(){return btnFlipHor_onclick()};
   document.getElementById("btnFlipVer").onclick = function(){return btnFlipVer_onclick()};
   document.getElementById("btnPan").onclick = function(){return btnPan_onclick()};
   document.getElementById("btnAutoCrop").onclick = function(){return btnAutoCrop_onclick()};
   document.getElementById("btnChangeContrast").onclick = function(){return btnChangeContrast_onclick()};
   document.getElementById("btnChangeHue").onclick = function(){return btnChangeHue_onclick()};
   document.getElementById("btnChangeIntensity").onclick = function(){return btnChangeIntensity_onclick()};
   document.getElementById("btnChangeSaturation").onclick = function(){return btnChangeSaturation_onclick()};
   document.getElementById("btnEmboss").onclick = function(){return btnEmboss_onclick()}
   document.getElementById("btnGaussian").onclick = function(){return btnGaussian_onclick()};
   document.getElementById("btnGammaCorrect").onclick = function(){return btnGammaCorrect_onclick()};
   document.getElementById("btnGrayscale").onclick = function(){return btnGrayscale_onclick()};
   document.getElementById("btnHalfTone").onclick = function(){return btnHalfTone_onclick()};
   document.getElementById("btnHistogramContrast").onclick = function(){return btnHistogramContrast_onclick()};
   document.getElementById("btnMedian").onclick = function(){return btnMedian_onclick()};
   document.getElementById("btnRemapHue").onclick = function(){return btnRemapHue_onclick()};
   document.getElementById("btnSharpen").onclick = function(){return btnSharpen_onclick()};
   document.getElementById("btnSpatialFilter").onclick = function(){return btnSpatialFilter_onclick()};
   document.getElementById("btnUnsharpMask").onclick = function(){return btnUnsharpMask_onclick()};
   document.getElementById("btnRotate").onclick = function(){return btnRotate_onclick()};
   document.getElementById("btnfreeHandWave").onclick = function(){return btnfreeHandWave_onclick()};
   document.getElementById("btnResetImage").onclick = function(){return btnResetImage_onclick()};
}

function ShowImage(url)
{
   WebImageViewer1.OpenImageUrl(url);
}

function btnFitHeight_Click()
{
   WebImageViewer1.setSizeMode(ImageViewerSizeMode.FitHeight);
}

function btnFillWhite_onclick()
{
   var cmd = new FillCommand('white');
   WebImageViewer1.ApplyCommand(cmd);
}

function btnFillBlack_onclick()
{
   var cmd = new FillCommand('black');
   WebImageViewer1.ApplyCommand(cmd);
}

function btnFitHeight_onclick()
{
   WebImageViewer1.setSizeMode(ImageViewerSizeMode.FitHeight);
}

function btnFitWidth_onclick()
{
   WebImageViewer1.setSizeMode(ImageViewerSizeMode.FitWidth);
}

function btnView1to1_onclick()
{
   WebImageViewer1.setSizeMode(ImageViewerSizeMode.Normal);
   WebImageViewer1.setScaleFactor(1);
}

function btnFit_onclick()
{
   WebImageViewer1.setSizeMode(ImageViewerSizeMode.FitAlways);
}

function btnZoomIn_onclick()
{
   WebImageViewer1.setSizeMode(ImageViewerSizeMode.Normal);
   WebImageViewer1.getMouseInteractiveMode().setLeftButton(ImageViewerMouseInteractiveMode.ZoomIn);
}

function btnZoomOut_onclick()
{
   WebImageViewer1.setSizeMode(ImageViewerSizeMode.Normal);
   WebImageViewer1.getMouseInteractiveMode().setLeftButton(ImageViewerMouseInteractiveMode.ZoomOut);
}

function btnRotateRight_onclick()
{
   var cmd = new RotateCommand(9000, RotateCommandFlags.Bicubic | RotateCommandFlags.Resize, 'black');
   WebImageViewer1.ApplyCommand(cmd);
}

function btnFlipHor_onclick()
{
   var cmd = new FlipCommand(true);
   WebImageViewer1.ApplyCommand(cmd);
}

function btnFlipVer_onclick()
{
   var cmd = new FlipCommand(false);
   WebImageViewer1.ApplyCommand(cmd);
}

function btnPan_onclick()
{
   WebImageViewer1.getMouseInteractiveMode().setLeftButton(ImageViewerMouseInteractiveMode.Pan);
}

function ChkUseDpi_onclick()
{
   WebImageViewer1.setUseDpi(!WebImageViewer1.getUseDpi());
}

function btnAutoCrop_onclick()
{
   var index = WebThumbnailViewer1.getSelectedIndex();
   var Threshold =  parseFloat(XMLAutoCrop[index].getAttribute("Threshold"));
   var cmd = new AutoCropCommand(Threshold);
   WebImageViewer1.ApplyCommand(cmd);
}

function btnChangeContrast_onclick()
{
   var index = WebThumbnailViewer1.getSelectedIndex();
   var Contrast =  parseFloat(XMLChangeContrast[index].getAttribute("Contrast"));
   var cmd = new ChangeContrastCommand(Contrast);

   WebImageViewer1.ApplyCommand(cmd);
}

function btnChangeHue_onclick()
{
  var index = WebThumbnailViewer1.getSelectedIndex();
  var Hue=  parseFloat(XMLChangeHue[index].getAttribute("Angle"));
  var cmd = new ChangeHueCommand(Hue);
  WebImageViewer1.ApplyCommand(cmd);
}

function btnChangeIntensity_onclick()
{
   var index = WebThumbnailViewer1.getSelectedIndex();
   var Brithness=  parseFloat(XMLChangeIntensity[index].getAttribute("Brightness"));
   var cmd = new ChangeIntensityCommand(Brithness);
   WebImageViewer1.ApplyCommand(cmd);
}

function btnChangeSaturation_onclick()
{
   var index = WebThumbnailViewer1.getSelectedIndex()
   var Saturation=  parseFloat(XMLChangeSaturation[index].getAttribute("Change"));
   var cmd = new ChangeSaturationCommand(Saturation)
   WebImageViewer1.ApplyCommand(cmd);
}

function btnEmboss_onclick()
{
   var index = WebThumbnailViewer1.getSelectedIndex();
   var Depth = parseFloat(XMLEmboss[index].getAttribute("Depth"));
   var Direction= parseFloat(XMLEmboss[index].getAttribute("Direction"));
   var cmd = new EmbossCommand(Direction,Depth);
   WebImageViewer1.ApplyCommand(cmd);
}

function btnGaussian_onclick()
{
   var index = WebThumbnailViewer1.getSelectedIndex();
   var Gaussian=  parseFloat(XMLGaussian[index].getAttribute("Radius"));
   var cmd = new GaussianCommand(Gaussian);
   WebImageViewer1.ApplyCommand(cmd);
}

function btnGammaCorrect_onclick()
{
   var index = WebThumbnailViewer1.getSelectedIndex();
   var Gamma=  parseFloat(XMLGamma[index].getAttribute("Gamma"));
   var cmd = new GammaCorrectCommand(Gamma);
   WebImageViewer1.ApplyCommand(cmd);
}

function btnGrayscale_onclick()
{
   var index = WebThumbnailViewer1.getSelectedIndex();
   var GrayScale=  parseFloat(XMLGrayscale[index].getAttribute("BitsPerPixel"));
   var cmd = new GrayscaleCommand(GrayScale);
   WebImageViewer1.ApplyCommand(cmd);
}

function btnHalfTone_onclick()
{
   var index = WebThumbnailViewer1.getSelectedIndex();
   var cmd = new HalfToneCommand();
   cmd.Angle = parseFloat(XMLHalfTone[index].getAttribute("Angle"));
   cmd.Dimension = parseFloat(XMLHalfTone[index].getAttribute("Dimension"));
   cmd.Type= parseFloat(XMLHalfTone[index].getAttribute("Type"));

   WebImageViewer1.ApplyCommand(cmd);
}

function btnHistogramContrast_onclick()
{
   var index = WebThumbnailViewer1.getSelectedIndex();
   var HistogramContrast=  parseFloat(XMLHistogramContrast[index].getAttribute("Contrast"));
   var cmd = new HistogramContrastCommand(HistogramContrast);
   WebImageViewer1.ApplyCommand(cmd);
}

function btnMedian_onclick()
{
   var index = WebThumbnailViewer1.getSelectedIndex();
   var Median=  parseFloat(XMLMedian[index].getAttribute("Dimension"));
   var cmd = new MedianCommand(Median);
   WebImageViewer1.ApplyCommand(cmd);
}

function btnRemapHue_onclick()
{
   var    i;
   var    Count;
   var index = WebThumbnailViewer1.getSelectedIndex();

   //Allocate tables    
   var MaskTable = new Array(Length); 
   var HueTable =   new Array(Length); 
   var HueValue = parseFloat(XMLRemapHue[index].getAttribute("HueTableValue"));
   var MaskValue = parseFloat(XMLRemapHue[index].getAttribute("MaskTable"));
   var Length  = parseFloat(XMLRemapHue[index].getAttribute("Length"));

   //Initialize tables
   for (i = 0; i < Length ; i++)
   {
      MaskTable[i] = MaskValue;
   }
   for (i = 0; i < Length ; i++)
   {
      HueTable[i] = HueValue;
   }
   var cmd = new RemapHueCommand(MaskTable, HueTable, null, null, Length);

   WebImageViewer1.ApplyCommand(cmd);
}

function btnSharpen_onclick()
{
   var index = WebThumbnailViewer1.getSelectedIndex();
   var Sharpen=  parseFloat(XMLSharpen[index].getAttribute("Sharpness"));
   var cmd = new SharpenCommand(Sharpen);
   WebImageViewer1.ApplyCommand(cmd);
}

function btnSpatialFilter_onclick()
{
   var index = WebThumbnailViewer1.getSelectedIndex();
   var SpatialFilter=  parseFloat(XMLSpatialFilter[index].getAttribute("SpatialFilterCommandPredefined"));
   var cmd = new SpatialFilterCommand(SpatialFilter);
   WebImageViewer1.ApplyCommand(cmd);
}

function btnUnsharpMask_onclick()
{
   var index = WebThumbnailViewer1.getSelectedIndex();
   var Ammount=  parseFloat(XMLUnsharpMask[index].getAttribute("Ammount"));
   var Redius=  parseFloat(XMLUnsharpMask[index].getAttribute("Radius"));
   var Threshould=  parseFloat(XMLUnsharpMask[index].getAttribute("Threshold"));
   var ColorType=  parseFloat(XMLUnsharpMask[index].getAttribute("ColorType"));
   var index = WebThumbnailViewer1.getSelectedIndex();
   var cmd = new UnsharpMaskCommand(Ammount, Redius, Threshould, ColorType);
   WebImageViewer1.ApplyCommand(cmd);
}

function btnRotate_onclick()
{
   var cmd = new RotateCommand(9000, RotateCommandFlags.Bicubic | RotateCommandFlags.Resize, 'black');
   WebImageViewer1.ApplyCommand(cmd);
}

function btnResetImage_onclick()
{
   var index = WebThumbnailViewer1.getSelectedIndex();
   WebImageViewer1.OpenImageUrl(images[index]);
}

function btnfreeHandWave_onclick()
{
   // Prepare the command 
   userPoint = new Array(4);

   // Fill userPoint array with points that define a triangular wave
   userPoint[0] = new ltwfPoint(0, 0);
   userPoint[1] = new ltwfPoint(3, 10);
   userPoint[2] = new ltwfPoint(9, -10);
   userPoint[3] = new ltwfPoint(12, 0);

   //Draw a triangular wave according to userPoint points and store the amplitudes values in the amplitudes array.
   var amplitudes = ltwfGetCurvePoints(userPoint, CurvePointsType.Linear);
   var index = WebThumbnailViewer1.getSelectedIndex();
   var Scale=  parseFloat(XMLfreeHandWave[index].getAttribute("Scale"));
   var WaveLength=  parseFloat(XMLfreeHandWave[index].getAttribute("WaveLength"));
   var Angle=  parseFloat(XMLfreeHandWave[index].getAttribute("Angle"));
   var FillColor=  XMLfreeHandWave[index].getAttribute("FillColor");
   var Flags = parseFloat(XMLfreeHandWave[index].getAttribute("Flags"));
   cmd = new FreeHandWaveCommand(amplitudes,
      Scale,
      WaveLength,
      Angle,
      FillColor,
      Flags);
   WebImageViewer1.ApplyCommand(cmd);
}

function setHoverProperty()
{
   var button = document.getElementsByTagName("a");
   for(i=0; i<button.length; i++)
   {
      button[i].onmouseover = function(){this.className = "hover";}
      button[i].onmouseout = function(){this.className = "";}
   }
}