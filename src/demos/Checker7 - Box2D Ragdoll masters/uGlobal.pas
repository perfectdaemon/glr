unit uGlobal;

interface

uses
  dfHRenderer, dfMath, dfHUtility, uBox2DImport, uGUI;



var
  R: IglrRenderer;
  Factory: IglrObjectFactory;
  mainScene, hudScene: Iglr2DScene;

  fpsCounter: TglrFPSCounter;

  b2w: Tglrb2World;

  gui: TglrInGameGUI;

procedure InitializeGlobal();
procedure FinalizeGlobal();

implementation

procedure InitializeGlobal();
begin
  fpsCounter := TglrFPSCounter.Create(hudScene, 'FPS:', 1, nil);
  fpsCounter.TextObject.Material.MaterialOptions.Diffuse := dfVec4f(0, 0, 0, 1);
  gui := TglrInGameGUI.Create(hudScene);
end;

procedure FinalizeGlobal();
begin
  fpsCounter.Free();
  gui.Free();
end;

end.
