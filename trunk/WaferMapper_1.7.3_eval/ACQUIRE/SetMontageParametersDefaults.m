function SetMontageParametersDefaults()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
global GuiGlobalsStruct;

%default Wafer Parameters
GuiGlobalsStruct.MontageParameters.TileFOV_microns = 40.96;
GuiGlobalsStruct.MontageParameters.TileWidth_pixels = 4096;
GuiGlobalsStruct.MontageParameters.TileDwellTime_microseconds = 1;

GuiGlobalsStruct.MontageParameters.MontageNorthAngle = 0;
GuiGlobalsStruct.MontageParameters.NumberOfTileRows = 3;
GuiGlobalsStruct.MontageParameters.NumberOfTileCols = 3;
GuiGlobalsStruct.MontageParameters.PercentTileOverlap = 6;
GuiGlobalsStruct.MontageParameters.XOffsetFromAlignTargetMicrons = 0;
GuiGlobalsStruct.MontageParameters.YOffsetFromAlignTargetMicrons = 0;
GuiGlobalsStruct.MontageParameters.MicronsPerPixel = (GuiGlobalsStruct.MontageParameters.TileFOV_microns/GuiGlobalsStruct.MontageParameters.TileWidth_pixels);

GuiGlobalsStruct.MontageParameters.AF_X_Offset_Microns = 0;
GuiGlobalsStruct.MontageParameters.AF_Y_Offset_Microns = 0;

GuiGlobalsStruct.MontageParameters.AutoFocusStartMag = 25000;
GuiGlobalsStruct.MontageParameters.IsPerformQualityCheckOnEveryAF = false;
GuiGlobalsStruct.MontageParameters.AFQualityThreshold = 3;
GuiGlobalsStruct.MontageParameters.IsPerformQualCheckAfterEachImage = false;
GuiGlobalsStruct.MontageParameters.ImageQualityThreshold = 3;

GuiGlobalsStruct.MontageParameters.IsSingle_AF_ForWholeMontage = false;
GuiGlobalsStruct.MontageParameters.IsSingle_AFASAF_ForWholeMontage = true;
GuiGlobalsStruct.MontageParameters.IsAFOnEveryTile = false;
GuiGlobalsStruct.MontageParameters.IsAFASAFOnEveryTile = false;
GuiGlobalsStruct.MontageParameters.IsPlaneFit = false;
GuiGlobalsStruct.MontageParameters.IsXFit = false;
GuiGlobalsStruct.MontageParameters.RowDistBetweenAFPointsMicrons = 50;
GuiGlobalsStruct.MontageParameters.ColDistBetweenAFPointsMicrons = 50;
GuiGlobalsStruct.MontageParameters.AutofunctionScanrate = 1;


GuiGlobalsStruct.MontageParameters.IsAcquireOverviewImage = false;
GuiGlobalsStruct.MontageParameters.MontageOverviewImageFOV_microns = 409.6;
GuiGlobalsStruct.MontageParameters.MontageOverviewImageWidth_pixels = 4096;
GuiGlobalsStruct.MontageParameters.MontageOverviewImageHeight_pixels = 4096;
GuiGlobalsStruct.MontageParameters.MontageOverviewImageDwellTime_microseconds = 1;

end

