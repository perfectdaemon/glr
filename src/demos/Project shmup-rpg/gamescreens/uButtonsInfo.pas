unit uButtonsInfo;

interface

uses
  dfHRenderer;

type
  TpdTextureType = (ttNormal, ttOver, ttClicked);

  TpdTexRegionInfo = record
    x, y: Integer;
  end;

  TpdButtonInfo = record
    x, y, width, height: Integer;
    texture: IglrTexture;
    texRegionInfo: array[TpdTextureType] of TpdTexRegionInfo;
  end;

implementation

end.
