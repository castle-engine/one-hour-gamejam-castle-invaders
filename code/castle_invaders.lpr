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

{$apptype GUI}

{ "Castle Invaders" standalone game binary. }
program castle_invaders;
uses CastleWindow, CastleConfig, Game, CastleParameters, CastleLog, CastleUtils;

const
  Options: array [0..0] of TOption =
  (
    (Short:  #0; Long: 'debug-log'; Argument: oaNone)
  );

procedure OptionProc(OptionNum: Integer; HasArgument: boolean;
  const Argument: string; const SeparateArgs: TSeparateArgs; Data: Pointer);
begin
  case OptionNum of
    0: InitializeLog;
    else raise EInternalError.Create('OptionProc');
  end;
end;

begin
  Parameters.Parse(Options, @OptionProc, nil);

  Window.Width := 800;
  Window.Height := 600;

  UserConfig.Load;
  Window.OpenAndRun;
  UserConfig.Save;
end.
