unit uPlayer;

interface

uses
  glr, glrMath, uGlobal,
  uWorldObjects;

const
//  PLAYER_W = 32;
//  PLAYER_H = PLAYER_W;

  PLAYER_PICKUP_RADIUS = 10;
  PLAYER_DROP_RADIUS = 100;

  PLAYER_MAX_SPEECHES_IN_ORDER = 5;
  PLAYER_SPEECHES_BREAK_TIME = 0.5;

  //Максимальные занчения параметров выживания
  PLAYER_MAX_PARAM = 100.0;
  PLAYER_START_HEALTH  = PLAYER_MAX_PARAM * 0.9;
  PLAYER_START_HUNGER  = PLAYER_MAX_PARAM * 0.85;
  PLAYER_START_THIRST  = PLAYER_MAX_PARAM * 0.78;
  PLAYER_START_FATIGUE = PLAYER_MAX_PARAM * 0.7;
  PLAYER_START_MIND    = PLAYER_MAX_PARAM * 0.62;

  PLAYER_MAX_SPEED = 150;

  //Скорость убывания
  PLAYER_HEALTH_PER_SEC = 0.07;
  PLAYER_HUNGER_PER_SEC = 0.32;
  PLAYER_THIRST_PER_SEC = 0.34;
  PLAYER_MIND_PER_SEC   = 0.13;

  //Скорость восстановления запаса сил, когда игрок не двигается
  PLAYER_FATIGUE_REST_PER_SEC = 0.7;
  //(Дополнительно)Скорость восстановления запаса сил, когда игрок рядом с костром
  PLAYER_FATIGUE_NEARFIRE_PER_SEC = 1.2;
  //Скорость убывания запаса сил при ходьбе
  PLAYER_FATIGUE_MOVING_PER_SEC = 1.40;
  //(Дополнительно) убывание сил в воде
  PLAYER_FATIGUE_SWIMMING_PER_SEC = 1.4;

  PLAYER_SAY_ORIGIN_X = -90;
  PLAYER_SAY_ORIGIN_Y = -80;

  MOVETOPOINT_ARROW_OFFSET = 15;
  MOVETOPOINT_AMPLITUDE = 10;

type
  //Класс инкапсулирует в себе указатель места, куда пойдет игрок.
  //Скрытие, показ, анимация и прочее.
  TpdMoveToPoint = class
  private
    FArrows: array[0..3] of IglrSprite;
    FTime: Double;
    FVisible: Boolean;
    FPos: TdfVec2f;
    constructor Create(); virtual;
    destructor Destroy(); override;
    procedure SetPos(const Value: TdfVec2f);
    procedure SetVisible(const Value: Boolean);
  public
    class function Initialize(aScene: Iglr2DScene): TpdMoveToPoint;

    procedure Update(const dt: Double);

    property Visible: Boolean read FVisible write SetVisible;
    property Position: TdfVec2f read FPos write SetPos;
  end;

  //Контроллер фраз игрока. Позволяет помещать фразы в очередь

  TpdPlayerSpeech = record
    active: Boolean;
    text: WideString;
    timeToShow: Single;
    color: TdfVec4f;
  end;

  TpdPlayerSpeechController = class
  private
    FTextObject: IglrText;
    FUsualPos: TdfVec2f; //Обыная позиция текста. Нужна для расчета по строкам
    FSpeeches: array[0..PLAYER_MAX_SPEECHES_IN_ORDER - 1] of TpdPlayerSpeech;
    FCurrent, FLast: Integer; //Индекс текущей фразы, индекс последней фразы

    procedure CleanAll();
    procedure Clean(aIndex: Integer);
    procedure TrySwitchToNext();
    procedure SwitchTo(aIndex: Integer);

    constructor Create(); virtual;
    destructor Destroy(); override;
  public
    class function Initialize(aScene: Iglr2DScene): TpdPlayerSpeechController;

    procedure Update(const dt: Double);

    procedure Say(aText: WideString; aTimeToShow: Single; aForce: Boolean = True); overload;
    procedure Say(aText: WideString; aTimeToShow: Single; aColor: TdfVec4f;
      aForceSay: Boolean = True); overload;
  end;


  TpdParamThreshold = (t10, t25, t50, t75, t100);

const
  PLAYER_THRESHOLD_LEVELS: array[TpdParamThreshold] of Integer = (10, 25, 50, 75, 100);

  PLAYER_HEALTH_THRESHOLD_SAY: array[TpdParamThreshold] of WideString = (
    'Еще чуть-чуть и я умру...',
    'Опять печенькой отравился',
    'Пока жив, но бывало и лучше',
    '',
    'Здоров как бык — хоть'#13#10'сейчас в космонавты');

  PLAYER_HUNGER_THRESHOLD_SAY: array[TpdParamThreshold] of WideString = (
    'Какая аппетитная кепка...',
    'Сожрать бы кого-нибудь',
    'Эх ,червячка бы заморить!',
    '',
    'Вот это я понимаю — наелся!');

  PLAYER_THIRST_THRESHOLD_SAY: array[TpdParamThreshold] of WideString = (
    'Воды! Воды...',
    'В горле совсем пересохло',
    'Глотнуть бы чего-нибудь',
    '',
    'Ух, пора искать кустики! Хотя, '#13#10'кого я обманываю, можно'#13#10'прямо здесь');

  PLAYER_FATIGUE_THRESHOLD_SAY: array[TpdParamThreshold] of WideString = (
    'Еще пару шагов и я упаду...',
    'Надо было меньше курить',
    'Эх, не зря я в молодости'#13#10'по гаражам прыгал!',
    '',
    'Полон сил и энергии');

  PLAYER_MIND_THRESHOLD_SAY: array[TpdParamThreshold] of WideString = (
    'Сколько весит килограмм крокодилов,'#13#10'если козыри — пики?',
    'Я никогда не спасусь...',
    'Перспективы безрадостные...',
    '',
    'Человек всегда побеждает природу!');

  PLAYER_PARAM_ANIMATION_TIMEOUT = 3;

type
  TpdPlayer = class
  private
    FScene: Iglr2DScene;
    //Player HUD
    FHealthBar, FHealthBarContour,
    FHungerBar, FHungerBarContour,
    FThirstBar, FThirstBarContour,
    FFatigueBar, FFatigueBarContour,
    FMindBar, FMindBarContour: IglrSprite;
    FBarInitialWidth: Integer;

    FMoveToPoint: TpdMoveToPoint;

    //Таймаут после каждого произнесения, дабы не повтооряться
    FThresholdsTime: array[TpdParam] of Single;
    //Таймаут для добавления анимации + или - параметра
    FAnimationTimeOut: array[TpdParam] of Single;

    //Какой объект поднять/использовать после окончания движения
    FObjectToCollect: TpdWorldObject;
    FNearCampFire: Boolean;

    //Достигнута ли дистанция для взаимодействия
    function IsPickupDistanceReached(aObject: TpdWorldObject): Boolean;
    //Понизить параметр (только для внутреннего использования)
    procedure ChangeParam(aParam: TpdParam; aValue: Single);
    //Обновляем текстурные координаты полосок, предотвращая сжатие текстуры
    procedure UpdateBarTexCoords(const aBar: IglrSprite);
    //Проверяем - не нужно ли скзаать какую-нибудь фразу исходя из текущих
    //параметров. Если да - говорим ее
    procedure ProcessThresholdsSpeeches(const dt: Double);
    procedure Die(aReason: TpdParam);

    constructor Create(); virtual;
    destructor Destroy(); override;
    procedure SetNearCampFire(const Value: Boolean);
  public
    sprite: IglrSprite;
    moveVec, moveToPoint: TdfVec2f;
    isMoving: Boolean;
    inWater: Boolean;
    isMovingPermanently: Boolean; //для движения сзажатой кнопкой мыши

    speed: Single;

    speech: TpdPlayerSpeechController;

    OnDie: TpdDieCallback;

    //Параметры выживания
    params: array[TpdParam] of Single;

    class function Initialize(aScene, aHUDScene: Iglr2DScene): TpdPlayer;

    procedure Update(const dt: Single);
    procedure MoveTo(aPos: TdfVec2f; showMovePoint: Boolean = True);
    procedure GoAndCollect(aObject: TpdWorldObject);

    //Добавление/снятие параметра при действиях. Вызывает анимацию
    procedure AddParam(aParam: TpdParam; aValue: Single);

    procedure SetTextureWithBackpack();
    property NearCampFire: Boolean read FNearCampFire write SetNearCampFire;
  end;

var
  player: TpdPlayer;

procedure InitializePlayer();
procedure UpdatePlayer(const dt: Double);
procedure DeinitializePlayer();

function PlayerOnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState): Boolean;
function PlayerOnMouseDown(X, Y: Integer;  MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState): Boolean;
function PlayerOnMouseUp(X, Y: Integer;  MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState): Boolean;

implementation

uses
  uWater,
  SysUtils,
  dfTweener;

const
  EPS = 0.05;

{ TpdPlayer }

procedure TpdPlayer.AddParam(aParam: TpdParam; aValue: Single);

  procedure AddAnim(aValue: PSingle; aStart, aMiddle: Single);
  begin
    if FAnimationTimeOut[aParam] <= 0 then
    begin
//      Tweener.AddTweenPSingle(aValue, tsExpoEaseIn, aStart, aMiddle, 3, 0);
      Tweener.AddTweenPSingle(aValue, tsExpoEaseIn, aMiddle, aStart, 4, 2);
      FAnimationTimeOut[aParam] := PLAYER_PARAM_ANIMATION_TIMEOUT;
    end;
  end;

begin
  params[aParam] := Clamp(params[aParam] + aValue, 0, PLAYER_MAX_PARAM);
  if aValue > 0 then
    case aParam of
      pHealth:  AddAnim(@FHealthBarContour.Material.PDiffuse.y, 0, 1);
      pHunger:  AddAnim(@FHungerBarContour.Material.PDiffuse.y, 0, 1);
      pThirst:  AddAnim(@FThirstBarContour.Material.PDiffuse.y, 0, 1);
      pFatigue: AddAnim(@FFatigueBarContour.Material.PDiffuse.y, 0, 1);
      pMind:    AddAnim(@FMindBarContour.Material.PDiffuse.y, 0, 1);
    end
  else
    case aParam of
      pHealth:  AddAnim(@FHealthBarContour.Material.PDiffuse.x, 0, 1);
      pHunger:  AddAnim(@FHungerBarContour.Material.PDiffuse.x, 0, 1);
      pThirst:  AddAnim(@FThirstBarContour.Material.PDiffuse.x, 0, 1);
      pFatigue: AddAnim(@FFatigueBarContour.Material.PDiffuse.x, 0, 1);
      pMind:    AddAnim(@FMindBarContour.Material.PDiffuse.x, 0, 1);
    end

end;

function TpdPlayer.IsPickupDistanceReached(aObject: TpdWorldObject): Boolean;
begin
  //Костыль, надо делать у всех WorldObject отдельный radius
  if aObject is TpdWater then
    Result := sprite.Position.Dist(aObject.sprite.Position) < (aObject as TpdWater).radius
  else
    Result := sprite.Position.Dist(aObject.sprite.Position)
      < PLAYER_PICKUP_RADIUS + sprite.Width / 2 + aObject.sprite.Width / 2;
end;

procedure TpdPlayer.ChangeParam(aParam: TpdParam; aValue: Single);
begin
  params[aParam] := Clamp(params[aParam] + aValue, 0, PLAYER_MAX_PARAM);
end;

constructor TpdPlayer.Create;
begin
  inherited;
  moveVec := dfVec2f(0, 0);
  moveToPoint := dfVec2f(0, 0);
  isMoving := False;
  sprite := Factory.NewSprite();

  FHealthBar := Factory.NewHudSprite();
  FHungerBar := Factory.NewHudSprite();
  FThirstBar := Factory.NewHudSprite();
  FFatigueBar := Factory.NewHudSprite();
  FMindBar := Factory.NewHudSprite();

  FHealthBarContour := Factory.NewHudSprite();
  FHungerBarContour := Factory.NewHudSprite();
  FThirstBarContour := Factory.NewHudSprite();
  FFatigueBarContour := Factory.NewHudSprite();
  FMindBarContour := Factory.NewHudSprite();
end;

destructor TpdPlayer.Destroy;
begin
  FMoveToPoint.Free();
  speech.Free();
  inherited;
end;

procedure TpdPlayer.Die(aReason: TpdParam);
begin
  if Assigned(OnDie) then
    OnDie(aReason);
end;

procedure TpdPlayer.GoAndCollect(aObject: TpdWorldObject);
begin
  FObjectToCollect := nil;
  if (IsPickupDistanceReached(aObject)) then
  begin
    aObject.OnCollect();
  end
  else
  begin
    MoveTo(aObject.sprite.Position); //Тут обнуляется FObjectToCollect в силу кривости архитектуры
    FObjectToCollect := aObject;     //Поэтому ставим ее после
  end;
end;

class function TpdPlayer.Initialize(aScene, aHUDScene: Iglr2DScene): TpdPlayer;
const
  PLAYER_NORM = 'player_norm.png';

  HEALTH_BAR = 'bar_health.png';
  HUNGER_BAR = 'bar_hunger.png';
  THIRST_BAR = 'bar_thrist.png';
  FATIGUE_BAR = 'bar_fatigue.png';
  MIND_BAR   = 'bar_mind.png';

  CONTOUR_BAR = 'bar_bounds.png';

  procedure InitializeBar(var aBar, aBarContour: IglrSprite;
    const aTexture: String; aPosition: TdfVec2f);
  begin
    with aBar do
    begin
      Material.Texture := atlasGame.LoadTexture(aTexture);
      UpdateTexCoords();
      PivotPoint := ppTopRight;
      Position := aPosition;
      SetSizeToTextureSize();
      Z := Z_HUD;
    end;

    with aBarContour do
    begin
      Material.Texture := atlasGame.LoadTexture(CONTOUR_BAR);
      Material.Texture.CombineMode := tcmModulate;
      Material.Diffuse := dfVec4f(0, 0, 0, 1);
      UpdateTexCoords();
      PivotPoint := ppTopRight;
      Position := aPosition;
      SetSizeToTextureSize();
      Z := Z_HUD + 1;
    end;

    aHUDScene.RegisterElement(aBar);
    aHUDScene.RegisterElement(aBarContour);
  end;

begin
  Result := TpdPlayer.Create();
  with Result do
  begin
    FScene := aScene;

    NearCampFire := False;
    isMoving := False;
    inWater := False;

    sprite.Position := dfVec2f(R.WindowWidth div 2, R.WindowHeight div 2);
    sprite.PivotPoint := ppCenter;
    sprite.Z := Z_PLAYER;
    sprite.Material.Texture := atlasGame.LoadTexture(PLAYER_NORM);
    sprite.UpdateTexCoords();
    sprite.SetSizeToTextureSize();
    FScene.RegisterElement(sprite);

    speed := PLAYER_MAX_SPEED;
    params[pHealth] := PLAYER_START_HEALTH;
    params[pHunger] := PLAYER_START_HUNGER;
    params[pThirst] := PLAYER_START_THIRST;
    params[pFatigue] := PLAYER_START_FATIGUE;
    params[pMind] := PLAYER_START_MIND;

    //--Инициализируем "полоски"
    InitializeBar(FHealthBar, FHealthBarContour, HEALTH_BAR, dfVec2f(R.WindowWidth - 20, 20));
    InitializeBar(FHungerBar, FHungerBarContour, HUNGER_BAR, dfVec2f(R.WindowWidth - 20, 50));
    InitializeBar(FThirstBar, FThirstBarContour, THIRST_BAR, dfVec2f(R.WindowWidth - 20, 80));
    InitializeBar(FFatigueBar, FFatigueBarContour, FATIGUE_BAR, dfVec2f(R.WindowWidth - 20, 110));
    InitializeBar(FMindBar,   FMindBarContour,   MIND_BAR,   dfVec2f(R.WindowWidth - 20, 140));

    FBarInitialWidth := FHealthBar.Material.Texture.Width;

    //-- Этот кусок надо оптимизировать, имхо.
    FHealthBar.Width := (params[pHealth] / PLAYER_MAX_PARAM) * FBarInitialWidth;
    FHungerBar.Width := (params[pHunger] / PLAYER_MAX_PARAM) * FBarInitialWidth;
    FThirstBar.Width := (params[pThirst] / PLAYER_MAX_PARAM) * FBarInitialWidth;
    FFatigueBar.Width := (params[pFatigue] / PLAYER_MAX_PARAM) * FBarInitialWidth;
    FMindBar.Width := (params[pMind] / PLAYER_MAX_PARAM) * FBarInitialWidth;
    UpdateBarTexCoords(FHealthBar);
    UpdateBarTexCoords(FHungerBar);
    UpdateBarTexCoords(FThirstBar);
    UpdateBarTexCoords(FFatigueBar);
    UpdateBarTexCoords(FMindBar);
    //--

    //--Инициализируем текст
    speech := TpdPlayerSpeechController.Initialize(hudScene);

    FMoveToPoint := TpdMoveToPoint.Initialize(aScene);
  end;
end;

procedure TpdPlayer.MoveTo(aPos: TdfVec2f; showMovePoint: Boolean = True);
begin
  FObjectToCollect := nil;
  moveToPoint := aPos;
  moveVec := (moveToPoint - sprite.Position).Normal;
  isMoving := True;

  if showMovePoint then
    FMoveToPoint.Position := aPos
  else
    FMoveToPoint.Visible := False;

  Tweener.AddTweenPSingle(sprite.PRotation, tsExpoEaseIn, sprite.Rotation, moveVec.GetRotationAngle(), 1.0, 0);
end;

procedure TpdPlayer.ProcessThresholdsSpeeches(const dt: Double);

  procedure SayAndExit(aParam: TpdParam; aThreshold: TpdParamThreshold);
  var
    color: TdfVec4f;
    aForce: Boolean;
  begin
    if aThreshold = t10 then
      color := colorRed
    else
      color := colorWhite;
    aForce := (aThreshold = t10);
    case aParam of
      pHealth: player.speech.Say(PLAYER_HEALTH_THRESHOLD_SAY[aThreshold], 3, color, aForce);
      pHunger: player.speech.Say(PLAYER_HUNGER_THRESHOLD_SAY[aThreshold], 3, color, aForce);
      pThirst: player.speech.Say(PLAYER_THIRST_THRESHOLD_SAY[aThreshold], 3, color, aForce);
      pFatigue: player.speech.Say(PLAYER_FATIGUE_THRESHOLD_SAY[aThreshold], 3, color, aForce);
      pMind: player.speech.Say(PLAYER_MIND_THRESHOLD_SAY[aThreshold], 3, color, aForce);
    end;
    FThresholdsTime[aParam] := 5;
  end;

var
  i: TpdParam;
begin
  for i := Low(params) to High(params) do
  begin
    if FThresholdsTime[i] > 0 then
    begin
      FThresholdsTime[i] := FThresholdsTime[i] - dt;
      Continue;
    end;
    if Abs(params[i] - PLAYER_THRESHOLD_LEVELS[t100]) < EPS then
      SayAndExit(i, t100)
    else if Abs(params[i] - PLAYER_THRESHOLD_LEVELS[t75]) < EPS then
      SayAndExit(i, t75)
    else if Abs(params[i] - PLAYER_THRESHOLD_LEVELS[t50]) < EPS then
      SayAndExit(i, t50)
    else if Abs(params[i] - PLAYER_THRESHOLD_LEVELS[t25]) < EPS then
      SayAndExit(i, t25)
    else if Abs(params[i] - PLAYER_THRESHOLD_LEVELS[t10]) < EPS then
      SayAndExit(i, t10);
  end;
end;

procedure TpdPlayer.SetNearCampFire(const Value: Boolean);
begin
  if FNearCampFire <> Value then
  begin
    FNearCampFire := Value;
    if FNearCampFire then
      player.speech.Say('Я чувствую, как ко мне'#13#10'возвращаются силы!', 4)
    else
      player.speech.Say('Вдали от костра неуютно...', 3);
  end;
end;

procedure TpdPlayer.SetTextureWithBackpack;
const
  PLAYER_BACKPACK = 'player_backpack.png';
begin
  sprite.Material.Texture := atlasGame.LoadTexture(PLAYER_BACKPACK);
  sprite.UpdateTexCoords();
  sprite.SetSizeToTextureSize();
end;

procedure TpdPlayer.Update(const dt: Single);
var
  i: TpdParam;
begin
  ChangeParam(pHealth, - PLAYER_HEALTH_PER_SEC * dt);
  ChangeParam(pHunger, - PLAYER_HUNGER_PER_SEC * dt);
  ChangeParam(pThirst, - PLAYER_THIRST_PER_SEC * dt);
  ChangeParam(pMind, - PLAYER_MIND_PER_SEC * dt);

  //--Расчет запаса сил
  //Двигается
  if isMoving then
  begin
    if inWater then
      AddParam(pFatigue, - (PLAYER_FATIGUE_MOVING_PER_SEC + PLAYER_FATIGUE_SWIMMING_PER_SEC) * dt)
      //ChangeParam(pFatigue, - (PLAYER_FATIGUE_MOVING_PER_SEC + PLAYER_FATIGUE_SWIMMING_PER_SEC) * dt)
    else
      ChangeParam(pFatigue, - (PLAYER_FATIGUE_MOVING_PER_SEC) * dt);
//      AddParam(pFatigue, - (PLAYER_FATIGUE_MOVING_PER_SEC) * dt);
  end
  //Не двигается
  else
    if inWater then
      AddParam(pFatigue, - (PLAYER_FATIGUE_MOVING_PER_SEC + PLAYER_FATIGUE_SWIMMING_PER_SEC) * dt)
      //ChangeParam(pFatigue, - (PLAYER_FATIGUE_SWIMMING_PER_SEC) * dt)
    else
    begin
      //TODO - проверка на близлежащий костер
      ChangeParam(pFatigue, (PLAYER_FATIGUE_REST_PER_SEC) * dt);
//      AddParam(pFatigue, (PLAYER_FATIGUE_REST_PER_SEC) * dt);
    end;

  for i := Low(params) to High(params) do
  begin
    //Проверяем, не стоит ли уже наконец умереть
    if ((params[i] <= EPS) and (i <> pFatigue))
        or ((i = pFatigue)and(params[i] < EPS) and (inWater)) then
      Die(i);

    //Проверяем таймауты по анимациям
    if FAnimationTimeOut[i] > 0 then
      FAnimationTimeOut[i] := FAnimationTimeOut[i] - dt;
  end;

  FHealthBar.Width := (params[pHealth] / PLAYER_MAX_PARAM) * FBarInitialWidth;
  FHungerBar.Width := (params[pHunger] / PLAYER_MAX_PARAM) * FBarInitialWidth;
  FThirstBar.Width := (params[pThirst] / PLAYER_MAX_PARAM) * FBarInitialWidth;
  FFatigueBar.Width := (params[pFatigue] / PLAYER_MAX_PARAM) * FBarInitialWidth;
  FMindBar.Width := (params[pMind] / PLAYER_MAX_PARAM) * FBarInitialWidth;

  UpdateBarTexCoords(FHealthBar);
  UpdateBarTexCoords(FHungerBar);
  UpdateBarTexCoords(FThirstBar);
  UpdateBarTexCoords(FFatigueBar);
  UpdateBarTexCoords(FMindBar);

//  if R.Input.IsKeyDown(37) then
//    AddParam(pHealth, dt);
//  if R.Input.IsKeyDown(38) then
//    AddParam(pHunger, dt);
//  if R.Input.IsKeyDown(39) then
//    AddParam(pThirst, dt);
//  if R.Input.IsKeyDown(40) then
//    AddParam(pMind, dt);

  FMoveToPoint.Update(dt);
  speech.Update(dt);

  ProcessThresholdsSpeeches(dt);

  if Assigned(FObjectToCollect) then
    if IsPickupDistanceReached(FObjectToCollect) then
    begin
      FObjectToCollect.OnCollect();
      FObjectToCollect := nil;
      isMoving := False;
      FMoveToPoint.Visible := False;
    end;

  if sprite.Position.Dist(moveToPoint) < 5 then
  begin
    isMoving := False;
    FMoveToPoint.Visible := False;
  end;

  //Если запас сил исчерпан
  if params[pFatigue] <= EPS then
  begin
    isMoving := False;
    FMoveToPoint.Visible := False;
    player.speech.Say('Нет сил идти дальше!', 3, colorRed);
    FObjectToCollect := nil;
  end;

  if isMoving then
  begin
    sprite.Position := sprite.Position + moveVec * dt * speed;;
  end;
end;

procedure TpdPlayer.UpdateBarTexCoords(const aBar: IglrSprite);
begin
  with aBar.Material.Texture.GetTexDesc do
  begin
    aBar.TexCoords[2] := dfVec2f((X + FBarInitialWidth - aBar.Width )/ Width, Y / Height);
    aBar.TexCoords[3] := dfVec2f(aBar.TexCoords[2].x,
      (Y + RegionHeight) / Height);
  end;
end;


procedure InitializePlayer();
begin
  if Assigned(player) then
    player.Free();

  player := TpdPlayer.Initialize(mainScene, hudScene);
end;

procedure UpdatePlayer(const dt: Double);
begin
  player.Update(dt);
end;

function PlayerOnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState): Boolean;
begin
  Result := False;
  if (ssLeft in Shift) and (player.isMovingPermanently) then
  begin
    player.MoveTo(dfVec2f(X, Y) - mainScene.Origin, False);
    Result := True;
  end;             
end;

function PlayerOnMouseDown(X, Y: Integer;  MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState): Boolean;
begin
  Result := False;
  if MouseButton = mbLeft then
  begin
//    player.MoveTo(dfVec2f(X, Y) - mainScene.Origin);
    player.isMovingPermanently := True;    
    Result := True;
  end;
end;

function PlayerOnMouseUp(X, Y: Integer;  MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState): Boolean;
begin
  Result := False;
  if player.isMovingPermanently then
  begin
    player.isMovingPermanently := False;
    player.MoveTo(dfVec2f(X, Y) - mainScene.Origin);
    Result := True;
  end;
end;

procedure DeinitializePlayer();
begin
  if Assigned(player) then
  begin
    player.Free();
    player := nil;
  end;
end;

{ TpdMoveToPoint }

constructor TpdMoveToPoint.Create;
var
  i: Integer;
begin
  inherited;
  for i := 0 to High(FArrows) do
    FArrows[i] := Factory.NewHudSprite();
end;

destructor TpdMoveToPoint.Destroy;
begin

  inherited;
end;

class function TpdMoveToPoint.Initialize(aScene: Iglr2DScene): TpdMoveToPoint;
const
  ARROW_TEXTURE = 'moveto_point.png';
var
  i: Integer;
begin
  Result := TpdMoveToPoint.Create();
  with Result do
  begin
    FVisible := False;
    FPos := dfVec2f(0, 0);
    for i := 0 to High(FArrows) do
      with FArrows[i] do
      begin
        Material.Texture := atlasGame.LoadTexture(ARROW_TEXTURE);
        UpdateTexCoords();
        SetSizeToTextureSize();
        ScaleMult(0.6);
        Visible := False;
        PivotPoint := ppCenter;
        Rotation := 90 * i;
        Z := Z_HUD - 1;
        aScene.RegisterElement(FArrows[i]);
      end;
  end;
end;

procedure TpdMoveToPoint.SetPos(const Value: TdfVec2f);
begin
  FPos := Value;
  Visible := True;
  FTime := 0;
  FArrows[0].Position := FPos + dfVec2f(0, -MOVETOPOINT_ARROW_OFFSET);
  FArrows[1].Position := FPos + dfVec2f(MOVETOPOINT_ARROW_OFFSET, 0);
  FArrows[2].Position := FPos + dfVec2f(0, MOVETOPOINT_ARROW_OFFSET);
  FArrows[3].Position := FPos + dfVec2f(-MOVETOPOINT_ARROW_OFFSET, 0);
end;

procedure TpdMoveToPoint.SetVisible(const Value: Boolean);
var
  i: Integer;
begin
  FVisible := Value;
  for i := 0 to High(FArrows) do
    FArrows[i].Visible := Value;
end;

procedure TpdMoveToPoint.Update(const dt: Double);
begin
  if not FVisible then
    Exit();

  FTime := FTime + dt;

  if FTime < 1 then
  begin
    FArrows[0].PPosition.y := FArrows[0].PPosition.y - MOVETOPOINT_AMPLITUDE*dt;
    FArrows[1].PPosition.x := FArrows[1].PPosition.x + MOVETOPOINT_AMPLITUDE*dt;
    FArrows[2].PPosition.y := FArrows[2].PPosition.y + MOVETOPOINT_AMPLITUDE*dt;
    FArrows[3].PPosition.x := FArrows[3].PPosition.x - MOVETOPOINT_AMPLITUDE*dt;
  end
  else if FTime < 2 then
  begin
    FArrows[0].PPosition.y := FArrows[0].PPosition.y + MOVETOPOINT_AMPLITUDE*dt;
    FArrows[1].PPosition.x := FArrows[1].PPosition.x - MOVETOPOINT_AMPLITUDE*dt;
    FArrows[2].PPosition.y := FArrows[2].PPosition.y - MOVETOPOINT_AMPLITUDE*dt;
    FArrows[3].PPosition.x := FArrows[3].PPosition.x + MOVETOPOINT_AMPLITUDE*dt;
  end
  else
    FTime := 0;
end;

{ TpdPlayerSpeechController }

procedure TpdPlayerSpeechController.Clean(aIndex: Integer);
begin
  with FSpeeches[aIndex] do
  begin
    active := False;
    text := '';
    timeToShow := 0;
    color := dfVec4f(1, 1, 1, 1);
  end;
end;

procedure TpdPlayerSpeechController.CleanAll;
var
  i: Integer;
begin
  for i := 0 to High(FSpeeches) do
    Clean(i);
end;

constructor TpdPlayerSpeechController.Create;
begin
  inherited;
  FTextObject := Factory.NewText();
  CleanAll();
end;

destructor TpdPlayerSpeechController.Destroy;
begin
  inherited;
end;

class function TpdPlayerSpeechController.Initialize(
  aScene: Iglr2DScene): TpdPlayerSpeechController;
begin
  Result := TpdPlayerSpeechController.Create();
  with Result do
  begin
    FCurrent := -1;
    FLast := -1;
    with FTextObject do
    begin
      Font := fontCooper;
      Material.Diffuse := dfVec4f(1, 1, 1, 1);
      Z := Z_HUD + 3;
      Position := dfVec2f(R.WindowWidth div 2 + PLAYER_SAY_ORIGIN_X,
        R.WindowHeight div 2 + PLAYER_SAY_ORIGIN_Y);
      FUsualPos := Position;
      ScaleMult(0.8);
      aScene.RegisterElement(FTextObject);
    end;
  end;
end;

procedure TpdPlayerSpeechController.Say(aText: WideString; aTimeToShow: Single;
  aColor: TdfVec4f; aForceSay: Boolean);
begin
  if aForceSay then
  begin
    CleanAll();
    FCurrent := -1;
    FLast := 0;
  end
  else
    if FLast = High(FSpeeches) then
      //Затираем первую фразу
      FLast := 0
    else
      //Иначе - как обычно
      FLast := FLast + 1;

  with FSpeeches[FLast] do
  begin
    active := True;
    text := aText;
    timeToShow := aTimeToShow;
    color := aColor;
  end;
  if FCurrent = -1 then
    SwitchTo(FLast);

end;

procedure TpdPlayerSpeechController.SwitchTo(aIndex: Integer);

  function CountPos(const subText: WideString; Text: WideString): Integer;
  begin
    if (Length(subText) = 0) or (Length(Text) = 0) or (Pos(subText, Text) = 0) then
      Result := 0
    else
      Result := (Length(Text) - Length(StringReplace(Text, subText, '', [rfReplaceAll]))) div Length(subText);
  end;

var
  lines: Integer;
begin
  FCurrent := aIndex;
  FTextObject.Material.Diffuse := FSpeeches[FCurrent].color;
  Tweener.AddTweenPSingle(@FTextObject.Material.PDiffuse.w, tsExpoEaseIn, 0.0, 1.0, 1.5);
  //Считаем количество строк в тексте
  lines := CountPos(#13#10, FSpeeches[FCurrent].text);
  FTextObject.Text := FSpeeches[FCurrent].text;
  FTextObject.Position := FUsualPos + dfVec2f(0, - 20 * lines);
end;

procedure TpdPlayerSpeechController.TrySwitchToNext;
var
  next: Integer;
begin
  if FCurrent = High(FSpeeches) then
    next := 0
  else
    next := FCurrent + 1;
  if FSpeeches[next].active then
  begin
    SwitchTo(next);
  end
  else
  begin
    FTextObject.Text := '';
    FCurrent := -1;
  end;
end;

procedure TpdPlayerSpeechController.Say(aText: WideString; aTimeToShow: Single; aForce: Boolean = True);
begin
  Say(aText, aTimeToShow, dfVec4f(1, 1, 1, 1), aForce);
end;

procedure TpdPlayerSpeechController.Update(const dt: Double);
begin
  if FCurrent = -1 then
    Exit();

  if not FSpeeches[FCurrent].active then
    Exit();

  with FSpeeches[FCurrent] do
  begin
    timeToShow := timeToShow - dt;
    if timeToShow < 0 then
    begin
      Clean(FCurrent);
      TrySwitchToNext();
    end;
  end;
end;

end.
