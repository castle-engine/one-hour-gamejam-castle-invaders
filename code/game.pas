{
  Copyright 2014 Michalis Kamburelis.

  This file is part of "Castle Invaders".

  "Castle Invaders" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Castle Invaders" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Implements the game logic, independent from Android / standalone. }
unit Game;

interface

uses CastleWindow, CastleLevels, CastlePlayer, CastleCameras,
  CastleSceneManager;

var
  Window: TCastleWindowCustom;

implementation

uses SysUtils,
  CastleWarnings, CastleProgress, CastleWindowProgress, CastleResources,
  CastleUIControls, CastleKeysMouse, CastleVectors, CastleGLImages, CastleImages,
  CastleFilesUtils, CastleMessages;

const
  InvX = 10;
  InvY = 5;

type
  TInvader = object
    X, Y: Single;
    Exists: boolean;
  end;
  TRocket = object
    X, Y: Single;
  end;

const
  MaxRockets = 10;
  TimeToRocketScale = 2;
var
  PlayerImage, EnemyImage, PlayerRocketImage, EnemyRocketImage, Bg: TGLImage;
  PlayerX, PlayerY: Single;
  Invaders: array [0..InvX - 1, 0..InvY - 1] of TInvader;
  PlayerRocketsCount: Integer;
  PlayerRockets: array [0..MaxRockets - 1] of TRocket;
  EnemyRocketsCount: Integer;
  EnemyRockets: array [0..MaxRockets - 1] of TRocket;
  TimeToRocket: Single;
  SwitchHMove: boolean;
  TimeToSwitchHMove: Single;

{ One-time initialization. }
procedure ApplicationInitialize;
var
  X, Y: Integer;
begin
  OnWarning := @OnWarningWrite;
  Progress.UserInterface := WindowProgressInterface;
  PlayerY := 30;
  PlayerX := 400;

  for X := 0 to InvX - 1 do
    for Y := 0 to InvY - 1 do
    begin
      Invaders[X, Y].X := X * 70;
      Invaders[X, Y].Y := Y * 70 + 200;
      Invaders[X, Y].Exists := true;
    end;

  EnemyRocketsCount := 0;
  PlayerRocketsCount := 0;

  TimeToRocket := 2 * TimeToRocketScale;
  TimeToSwitchHMove := 2;
end;

function MyGetApplicationName: string;
begin
  Result := 'castle_invaders';
end;

procedure WindowOpen(Container: TUIContainer);
begin
  PlayerImage := TGLImage.Create(ApplicationData('player.png'));
  EnemyImage := TGLImage.Create(ApplicationData('enemy1.png'));
  PlayerRocketImage := TGLImage.Create(ApplicationData('player_rocket.png'));
  EnemyRocketImage := TGLImage.Create(ApplicationData('enemy_rocket.png'));
  Bg := TGLImage.Create(ApplicationData('bg.png'), [], 800, 600, riBilinear);
end;

procedure WindowPress(Container: TUIContainer; const Event: TInputPressRelease);
var
  NewRocket: TRocket;
begin
  if Event.IsKey(K_Space) and (PlayerRocketsCount < MaxRockets) then
  begin
    NewRocket.X := PlayerX + 20;
    NewRocket.Y := PlayerY + 60;
    PlayerRockets[PlayerRocketsCount] := NewRocket;
    Inc(PlayerRocketsCount);
  end;
end;

procedure WindowUpdate(Container: TUIContainer);

  function RocketHit(const Rocket: TRocket): boolean;
  var
    X, Y: Integer;
  begin
    Result := false;

    if (Rocket.X < 0) or
       (Rocket.X > 800) or
       (Rocket.Y < 0) or
       (Rocket.Y > 600) then
      Exit(true);

    for X := 0 to InvX - 1 do
      for Y := 0 to InvY - 1 do
        if Invaders[X, Y].Exists then
        begin
          if (Rocket.X >= Invaders[X, Y].X) and
             (Rocket.X <= Invaders[X, Y].X + EnemyImage.Width) and
             (Rocket.Y >= Invaders[X, Y].Y) and
             (Rocket.Y <= Invaders[X, Y].Y + EnemyImage.Height) then
          begin
            Invaders[X, Y].Exists := false;
            Exit(true);
          end;
        end;
  end;

  function EnemyRocketHit(const Rocket: TRocket): boolean;
  begin
    Result := false;

    if (Rocket.X < 0) or
       (Rocket.X > 800) or
       (Rocket.Y < 0) or
       (Rocket.Y > 600) then
      Exit(true);

    if (Rocket.X >= PlayerX) and
       (Rocket.X <= PlayerX + PlayerImage.Width) and
       (Rocket.Y >= PlayerY) and
       (Rocket.Y <= PlayerY + PlayerImage.Height) then
    begin
      MessageOk(Window, 'You were hit by a rocket!');
      Window.Close;
    end;
  end;

var
  SecondsPassed: Single;
const
  PlayerSpeed = 300;
  PlayerRocketSpeed = 500;
  EnemyRocketSpeed = 500;
  InvadersVertSpeed = 10;
  InvadersHorizSpeed = 10;
var
  X, Y, I, J: Integer;
  NewRocket: TRocket;
  OddY, SomethingExists: boolean;
begin
  Window.Invalidate; // just redraw every frame

  SecondsPassed := Window.Fps.UpdateSecondsPassed;

  if Container.Pressed[K_A] then
    PlayerX -= SecondsPassed * PlayerSpeed;
  if Container.Pressed[K_D] then
    PlayerX += SecondsPassed * PlayerSpeed;

  for I := 0 to PlayerRocketsCount - 1 do
    PlayerRockets[I].Y += SecondsPassed * PlayerRocketSpeed;
  for I := 0 to EnemyRocketsCount - 1 do
    EnemyRockets[I].Y -= SecondsPassed * EnemyRocketSpeed;

  J := 0;
  while J < PlayerRocketsCount do
  begin
    if RocketHit(PlayerRockets[J]) then
    begin
      if J < PlayerRocketsCount - 1 then
        PlayerRockets[J] := PlayerRockets[PlayerRocketsCount - 1];
      Dec(PlayerRocketsCount);
    end else
      Inc(J);
  end;

  J := 0;
  while J < EnemyRocketsCount do
  begin
    if EnemyRocketHit(EnemyRockets[J]) then
    begin
      if J < EnemyRocketsCount - 1 then
        EnemyRockets[J] := EnemyRockets[EnemyRocketsCount - 1];
      Dec(EnemyRocketsCount);
    end else
      Inc(J);
  end;

  TimeToRocket -= SecondsPassed;

  SomethingExists := false;
  for X := 0 to InvX - 1 do
    for Y := 0 to InvY - 1 do
      if Invaders[X, Y].Exists then
      begin
        SomethingExists := true;
        OddY := Odd(Y);
        if SwitchHMove then
          OddY := not OddY;
        if OddY then
          Invaders[X, Y].X -= SecondsPassed * InvadersHorizSpeed else
          Invaders[X, Y].X += SecondsPassed * InvadersHorizSpeed;
        Invaders[X, Y].Y -= SecondsPassed * InvadersVertSpeed;

        if Invaders[X, Y].Y < 100 then
        begin
          MessageOk(Window, 'Invaders got to the bottom!');
          Window.Close;
          Exit;
        end;

        if (EnemyRocketsCount < MaxRockets) and
           (TimeToRocket <= 0) and
           (Random(80) = 0 { haaaaack! }) then
        begin
          //writeln('enemy shoot rocket');
          NewRocket.X := Invaders[X, Y].X + 20;
          NewRocket.Y := Invaders[X, Y].Y - 60;
          EnemyRockets[EnemyRocketsCount] := NewRocket;
          Inc(EnemyRocketsCount);
          TimeToRocket := TimeToRocketScale * Random / 2;
        end;
      end;

  if not SomethingExists then
  begin
    MessageOk(Window, 'You win!');
    Window.Close;
  end;

  TimeToSwitchHMove -= SecondsPassed;
  if TimeToSwitchHMove <= 0 then
  begin
    SwitchHMove := not SwitchHMove;
    TimeToSwitchHMove := 2;
  end;
end;

procedure WindowRender(Container: TUIContainer);
var
  X, Y, I: Integer;
begin
  Bg.Draw(Window.Rect);
  PlayerImage.Draw(Round(PlayerX), Round(PlayerY));

  for X := 0 to InvX - 1 do
    for Y := 0 to InvY - 1 do
      if Invaders[X, Y].Exists then
        EnemyImage.Draw(Round(Invaders[X, Y].X), Round(Invaders[X, Y].Y));

  for I := 0 to PlayerRocketsCount - 1 do
    PlayerRocketImage.Draw(Round(PlayerRockets[I].X), Round(PlayerRockets[I].Y));
  for I := 0 to EnemyRocketsCount - 1 do
    EnemyRocketImage.Draw(Round(EnemyRockets[I].X), Round(EnemyRockets[I].Y));
end;

procedure WindowResize(Container: TUIContainer);
begin
end;

initialization
  { This should be done as early as possible to mark our log lines correctly. }
  OnGetApplicationName := @MyGetApplicationName;

  { initialize Application callbacks }
  Application.OnInitialize := @ApplicationInitialize;

  { create Window and initialize Window callbacks }
  Window := TCastleWindowCustom.Create(Application);
  Window.OnOpen := @WindowOpen;
  Window.OnPress := @WindowPress;
  Window.OnUpdate := @WindowUpdate;
  Window.OnRender := @WindowRender;
  Window.OnResize := @WindowResize;
  Window.RenderStyle := rs2D;
  Window.FpsShowOnCaption := true;
  Application.MainWindow := Window;
end.
