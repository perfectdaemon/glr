unit uMainFunctions;

interface

uses
  dfHRenderer, dfMath, dfHEngine,
  //box2d
  uBox2DImport, UPhysics2D, UPhysics2DControllers, UPhysics2DTypes,

  uSingletons;



//var
//  R: IdfRenderer;

//  b2World: Tdfb2World;
//  b2e1, b2e2, b2e3: Tb2Body;
//  borders: array[0..3] of Tb2Body;
//
//  se1, se2, se3: IdfSprite;

  procedure SetSpriteParams(var aSprite: IglrSprite; aPos: TdfVec2f; W, H, Rot: Single; Dif: TdfVec4f; pp: Tglr2DPivotPoint);

//  procedure InitPhysics();
//  procedure InitEarth();
//
//
//  procedure DeInitSprite();
//  procedure DeInitEarth();
//  procedure DeInitPhysics();


implementation

uses
  uUtils;

procedure SetSpriteParams(var aSprite: IglrSprite; aPos: TdfVec2f; W, H, Rot: Single; Dif: TdfVec4f; pp: Tglr2DPivotPoint);
begin
  with aSprite do
  begin
    Position := aPos;
    PivotPoint := pp;
    Width := W;
    Height := H;
    Material.MaterialOptions.Diffuse := Dif;
    Rotation := Rot;
  end;
end;

{$REGION ' [ Init functions ] '}
//  procedure InitPhysics();
//  var
//
//  begin
//
//  end;
//
//  procedure InitEarth();
//  begin
//    {init borders}
//    borders[0] := dfb2InitBoxStatic(b2World, dfVec2f(0, 300), dfVec2f(5, 600), 0, 1, 1, 0, $0004, $0002);
//    borders[1] := dfb2InitBoxStatic(b2World, dfVec2f(800, 300), dfVec2f(5, 600), 0, 1, 1, 0, $0004, $0002);
//    //Без верха
////    borders[2] := dfb2InitBoxStatic(b2World, dfVec2f(400, 0), dfVec2f(800, 2), 0, 1, 1, 0, $0004, $0002);
//    borders[3] := dfb2InitBoxStatic(b2World, dfVec2f(400, 600), dfVec2f(800, 2), 0, 1, 1, 0, $0004, $0002);
//
//    se1 := dfNewSpriteWithNode(R.RootNode);
//    SetSpriteParams(se1, dfVec2f(100, 120), 200, 20, 0, dfVec4f(0.3, 0.8, 0.3, 1), ppCenter);
//    b2e1 := dfb2InitBoxStatic(b2World, se1, 1, 1, 0, $0004, $0002);
//
//    se2 := dfNewSpriteWithNode(R.RootNode);
//    SetSpriteParams(se2, dfVec2f(400, 180), 200, 20, 0, dfVec4f(0.3, 0.8, 0.3, 1), ppCenter);
//    b2e2 := dfb2InitBoxStatic(b2World, se2, 1, 1, 0, $0004, $0002);
//
//    se3 := dfNewSpriteWithNode(R.RootNode);
//    SetSpriteParams(se3, dfVec2f(350, 380), 680, 20, 0, dfVec4f(0.3, 0.8, 0.3, 1), ppCenter);
//    b2e3 := dfb2InitBoxStatic(b2World, se3, 1, 1, 0, $0004, $0002);
//  end;
{$ENDREGION}

{$REGION ' [ Deinit functions ] '}

//procedure DeInitSprite();
//begin
//
//end;
//
//procedure DeInitEarth();
//begin
//
//end;
//
//procedure DeInitPhysics();
//begin
//  b2World.Free;
//end;

{$ENDREGION}

end.
