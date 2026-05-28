window.onload = function()
{
   activateButtons();
   setHoverProperty();
}

function activateButtons() {
    document.getElementById("btnFitWidth").onclick = function() { return btnFitWidth_onclick() };
    document.getElementById("btnView1to1").onclick = function() { return btnView1to1_onclick() };
    document.getElementById("btnFit").onclick = function() { return btnFit_onclick() };
    document.getElementById("btnZoomIn").onclick = function() { return btnZoomIn_onclick() };
    document.getElementById("btnZoomOut").onclick = function() { return btnZoomOut_onclick() };
    document.getElementById("btnRotate180Degrees").onclick = function() { return btnRotate180Degrees_onclick() };
    document.getElementById("btnRotateLeft90").onclick = function() { return btnRotateLeft90_onclick() };
    document.getElementById("btnRotateRight").onclick = function() { return btnRotateRight_onclick() };
    document.getElementById("btnFlipHor").onclick = function() { return btnFlipHor_onclick() };
    document.getElementById("btnFlipVer").onclick = function() { return btnFlipVer_onclick() };
    document.getElementById("btnPan").onclick = function() { return btnPan_onclick() };
//    document.getElementById("btnInvertImg").onclick = function() { return btnInvertImg_onclick() };
//    document.getElementById("btnErode").onclick = function() { return btnErode_onclick() };
//    document.getElementById("btnDilate").onclick = function() { return btnDilate_onclick() };
//    document.getElementById("btnDeskew").onclick = function() { return btnDeskew_onclick() };
//    document.getElementById("btnDespeckle").onclick = function() { return btnDespeckle_onclick() };
//    document.getElementById("btnRemoveBorder").onclick = function() { return btnRemoveBorder_onclick() };
//    document.getElementById("btnDotRemove").onclick = function() { return btnDotRemove_onclick() };
//    document.getElementById("btnRemoveHolePunch").onclick = function() { return btnRemoveHolePunch_onclick() };
//    document.getElementById("btnInvertText").onclick = function() { return btnInvertText_onclick() };
//    document.getElementById("btnLineRemove").onclick = function() { return btnLineRemove_onclick() };
//    document.getElementById("btnSmooth").onclick = function() { return btnSmooth_onclick() };
//    document.getElementById("btnResetImage").onclick = function() { return btnResetImage_onclick() };
}

function ShowImage(url)
{
    ctl00_PageBody_WebImageViewer1.OpenImageUrl(url);
}

function btnFitWidth_onclick()
{
    ctl00_PageBody_WebImageViewer1.setSizeMode(ImageViewerSizeMode.FitWidth);
}

function btnView1to1_onclick()
{
    ctl00_PageBody_WebImageViewer1.setSizeMode(ImageViewerSizeMode.Normal);
    ctl00_PageBody_WebImageViewer1.setScaleFactor(1);
}

function btnFit_onclick() {
    ctl00_PageBody_WebImageViewer1.setSizeMode(ImageViewerSizeMode.FitAlways);
   //WebImageViewer1.setSizeMode(ImageViewerSizeMode.FitAlways);
}

function btnZoomIn_onclick() {
    ctl00_PageBody_WebImageViewer1.setSizeMode(ImageViewerSizeMode.Normal);
    ctl00_PageBody_WebImageViewer1.getMouseInteractiveMode().setLeftButton(ImageViewerMouseInteractiveMode.ZoomIn);
    //   WebImageViewer1.setSizeMode(ImageViewerSizeMode.Normal);
    //   WebImageViewer1.getMouseInteractiveMode().setLeftButton(ImageViewerMouseInteractiveMode.ZoomIn);
}

function btnZoomOut_onclick()
{
    ctl00_PageBody_WebImageViewer1.setSizeMode(ImageViewerSizeMode.Normal);
    ctl00_PageBody_WebImageViewer1.getMouseInteractiveMode().setLeftButton(ImageViewerMouseInteractiveMode.ZoomOut);
}

function btnRotate180Degrees_onclick()
{
   var cmd = new RotateCommand(18000, RotateCommandFlags.Bicubic | RotateCommandFlags.Resize, 'black');
   ctl00_PageBody_WebImageViewer1.ApplyCommand(cmd);
}

function btnRotateLeft90_onclick()
{
   var cmd = new RotateCommand(27000, RotateCommandFlags.Bicubic | RotateCommandFlags.Resize, 'black');
   ctl00_PageBody_WebImageViewer1.ApplyCommand(cmd);
}

function btnRotateRight_onclick()
{
   var cmd = new RotateCommand(9000, RotateCommandFlags.Bicubic | RotateCommandFlags.Resize, 'black');
   ctl00_PageBody_WebImageViewer1.ApplyCommand(cmd);
}

function btnFlipHor_onclick()
{
   var cmd = new FlipCommand(true);
   ctl00_PageBody_WebImageViewer1.ApplyCommand(cmd);
}

function btnFlipVer_onclick()
{
   var cmd = new FlipCommand(false);
   ctl00_PageBody_WebImageViewer1.ApplyCommand(cmd);
}

function btnPan_onclick()
{
    ctl00_PageBody_WebImageViewer1.getMouseInteractiveMode().setLeftButton(ImageViewerMouseInteractiveMode.Pan);
}

function btnInvertImg_onclick()
{
   var cmd = new InvertCommand();
   ctl00_PageBody_WebImageViewer1.ApplyCommand(cmd);
}

function btnErode_onclick()
{
   var cmd = new  MaximumCommand(2);
   ctl00_PageBody_WebImageViewer1.ApplyCommand(cmd);
}

function btnDilate_onclick()
{
   var cmd = new MinimumCommand(2);
   ctl00_PageBody_WebImageViewer1.ApplyCommand(cmd);
}

function btnDeskew_onclick()
{
   cmd = new DeskewCommand('White',
      DeskewCommandFlags.DoNotFillExposedArea | DeskewCommandFlags.DeskewImage);
   ctl00_PageBody_WebImageViewer1.ApplyCommand(cmd);
}

function btnDespeckle_onclick()
{
   cmd = new DespeckleCommand();
   ctl00_PageBody_WebImageViewer1.ApplyCommand(cmd);
}

function btnRemoveBorder_onclick()
{
   var cmd = new BorderRemoveCommand(BorderRemoveCommandFlags.None,
      BorderRemoveBorderFlags.All,
      20,
      9,
      3);
   ctl00_PageBody_WebImageViewer1.ApplyCommand(cmd);
}

function btnResetImage_onclick()
{
   var index = WebThumbnailViewer1.getSelectedIndex();
   ctl00_PageBody_WebImageViewer1.OpenImageUrl("Resources\\DocCleanImages.tif", index);
}

function ChkUseDpi_onclick()
{
    ctl00_PageBody_WebImageViewer1.setUseDpi(!WebImageViewer1.getUseDpi());
}

function btnDotRemove_onclick()
{
   var cmd = new DotRemoveCommand(DotRemoveCommandFlags.UseSize | DotRemoveCommandFlags.UseDiagonals,
      6,
      6,
      8,
      8);
   ctl00_PageBody_WebImageViewer1.ApplyCommand(cmd);
}

function btnRemoveHolePunch_onclick()
{
   var cmd = new HolePunchRemoveCommand(HolePunchRemoveCommandFlags.UseDpi | HolePunchRemoveCommandFlags.UseCount | HolePunchRemoveCommandFlags.UseLocation,
      HolePunchRemoveCommandLocation.Left,
      2,
      4,
      0,
      0,
      0,
      0);
   ctl00_PageBody_WebImageViewer1.ApplyCommand(cmd);
}

function btnInvertText_onclick()
{
   var cmd;
   if (ctl00_PageBody_WebThumbnailViewer1.getSelectedIndex() != 7)
   {
      cmd = new InvertedTextCommand(InvertedTextCommandFlags.UseDpi,
         300,
         20,
         75,
         95);
   }
   else
   {
      cmd = new InvertedTextCommand(InvertedTextCommandFlags.None,
         14,
         16,
         0,
         100);
   }

   ctl00_PageBody_WebImageViewer1.ApplyCommand(cmd);
}

function btnLineRemove_onclick()
{
   var cmd = new LineRemoveCommand(LineRemoveCommandFlags.UseGap | LineRemoveCommandFlags.UseVariance,
      400,
      9,
      15,
      10,
      3,
      3,
      LineRemoveCommandType.Horizontal);
   ctl00_PageBody_WebImageViewer1.ApplyCommand(cmd);
}
function btnSmooth_onclick()
{
   var cmd = new SmoothCommand(SmoothCommandFlags.None,1);
   ctl00_PageBody_WebImageViewer1.ApplyCommand(cmd);
}

function setHoverProperty()
{
   /*var button = document.getElementsByTagName("a");
   for(i=0; i<button.length; i++)
   {
      button[i].onmouseover = function(){this.className = "hover";}
      button[i].onmouseout = function(){this.className = "";}
   }*/
}