{$mainresource minesweeper.res}
program Minesweeper;

uses
  ABCObjects, GraphABC, Stack, System.Windows.Forms, Timers;

const
  font = 'Segoe UI';
  size_of_cell = 35;

type
  cell = record
    mine, opened, flag, query: boolean;
    neig: byte;
    image: PictureABC;
  end;

var
  field: array[,] of cell;
  sizeX, sizeY, sizeXc, sizeYc: byte;
  stack: list;
  mines, minesc, time: word;
  first_step, gameover: boolean;
  mines_str, temp_str, folder: string;
  
  NewG, RestartG, Skin, Beginner, Intermediate, Expert, Custom,
  TimerBox, InfoBox, FlagBox: RectangleABC;
  closed, opened, flag, query, mine, exploded, tick, wrong,
  one, two, three, four, five, six, seven, eight: Picture;
  settings: text;

procedure TimerProc();
begin
  Inc(time);
  Str(time, temp_str);
  TimerBox.Text := 'Time ' + temp_str;
  TimerBox.RedrawNow;
end;

var
  objTimer := Timer.Create(1000, TimerProc);

procedure SmoothRedraw(x, y: integer);
var
  divX, divY, direction: byte;
begin
  divX := round(x div round((sizeX * size_of_cell) / 2));
  divY := round(y div round((sizeY * size_of_cell + 40) / 2));
  
  if (divX = 0) and (divY = 0) then
    if (x < y) then 
      direction := 1 else 
      direction := 3 else
  if (divX = 1) and (divY = 0) then
    if (Window.Width - x < y) then 
      direction := 2 else 
      direction := 3 else
  if (divX = 1) and (divY = 1) then
    if (Window.Width - x < (Window.Height - 60) - y) then 
      direction := 2 else 
      direction := 4 else
  if (divX = 0) and (divY = 1) then
    if (x < (Window.Height - 60) - y) then
      direction := 1 else 
      direction := 4;
  
  case (direction) of
    1:
      for var posX := 0 to sizeX - 1 do
        for var posY := 0 to sizeY - 1 do
          field[posX, posY].image.RedrawNow;
    2:
      for var posX := sizeX - 1 downto 0 do
        for var posY := sizeY - 1 downto 0 do
          field[posX, posY].image.RedrawNow;
    3:
      for var posY := 0 to sizeY - 1 do
        for var posX := 0 to sizeX - 1 do
          field[posX, posY].image.RedrawNow;
    4:
      for var posY := sizeY - 1 downto 0 do
        for var posX := sizeX - 1 downto 0 do
          field[posX, posY].image.RedrawNow;
  end;
end;

function RandomExc(range, exc: byte): byte;
begin
  repeat
    result := Random(range);
  until (result <> exc - 1) and
        (result <> exc) and
        (result <> exc + 1);
end;

procedure SetMines(excX, excY: byte);
var
  x, y: byte;
begin
  for var i := 1 to mines do 
  begin
    repeat
      x := Random(sizeX);
      if (x = excX - 1) or (x = excX) or (x = excX + 1) then
        y := RandomExc(sizeY, excY) else
        y := Random(sizeY);
      if (y = excY - 1) or (y = excY) or (y = excY + 1) then 
        x := RandomExc(sizeX, excX);
    until (not field[x, y].mine);
    field[x, y].mine := true;
  end;
end;

function CalculateNeibFlags(x, y: byte): byte;
var
  i, j: shortint;
  posX, posY: byte;
begin
  for i := -1 to 1 do 
  begin
    posX := x + i;
    for j := -1 to 1 do 
    begin
      posY := y + j;
      if (posX >= 0) and (posX < sizeX) and
         (posY >= 0) and (posY < sizeY) then
        if (field[posX, posY].flag) then 
          Inc(result);
    end;
  end;
end;

function CalculateFlags(): word;
begin
  for var i := 0 to sizeX - 1 do
    for var j := 0 to sizeY - 1 do
      if (field[i, j].flag) then 
        Inc(result);
end;

function Lose(): boolean;
begin
  for var i := 0 to sizeX - 1 do
    for var j := 0 to sizeY - 1 do
      if (field[i, j].mine) and 
         (field[i, j].opened) then
      begin
        result := true;
        field[i, j].image.ChangePicture(exploded);
      end;
  
  if (result) then
    gameover := true;
end;

function Win(): boolean;
begin
  result := true;
  for var i := 0 to sizeX - 1 do
    for var j := 0 to sizeY - 1 do
      if (not field[i, j].opened) and
         (not field[i, j].mine) then
      begin
        result := false;
        exit;
      end;
  
  if (result) then 
    gameover := true;
end;

procedure UpdateStatus(x, y: byte);
begin
  if (not field[x, y].opened) then 
  begin
    if(field[x, y].flag) then
      field[x, y].image.ChangePicture(flag) else
    if(field[x, y].query) then
      field[x, y].image.ChangePicture(query) else
      field[x, y].image.ChangePicture(closed);
  end else
    case (field[x, y].neig) of
      0: field[x, y].image.ChangePicture(opened);
      1: field[x, y].image.ChangePicture(one);
      2: field[x, y].image.ChangePicture(two);
      3: field[x, y].image.ChangePicture(three);
      4: field[x, y].image.ChangePicture(four);
      5: field[x, y].image.ChangePicture(five);
      6: field[x, y].image.ChangePicture(six);
      7: field[x, y].image.ChangePicture(seven);
      8: field[x, y].image.ChangePicture(eight);
    end;
end;

procedure ResetField(flag, mine: boolean);
begin
  for var x := 0 to sizeX - 1 do
    for var y := 0 to sizeY - 1 do 
    begin
      if (flag) then 
      begin
        field[x, y].flag := false;
        field[x, y].query := false;
      end;
      if (mine) then 
      begin
        field[x, y].mine := false;
        field[x, y].neig := 0;
      end;
      
      field[x, y].opened := false;
      UpdateStatus(x, y);
    end;
end;

procedure CalculateNeighborMines();
var
  i, j: shortint;
  posX, posY: byte;
begin
  for var x := 0 to sizeX - 1 do
    for var y := 0 to sizeY - 1 do 
      if (not field[x, y].mine) then 
        for i := -1 to 1 do 
        begin
          posX := x + i;
          for j := -1 to 1 do 
          begin
            posY := y + j;
            if (PosX >= 0) and (PosX < sizeX) and
               (PosY >= 0) and (PosY < sizeY) then 
              if(field[posX, posY].mine) then 
                Inc(field[x, y].neig);
          end;
        end;
end;

procedure NewGame();
begin
  objTimer.Stop;
  ResetField(true, true);
  first_step := true;
  gameover := false;
  time := 0;
  
  InfoBox.Text := '';
  Str(mines, mines_str);
  Str(CalculateFlags, temp_str);
  FlagBox.Text := 'Flags ' + temp_str + '/' + mines_str;
  Str(time, temp_str);
  TimerBox.Text := 'Time ' + temp_str;
  
  SmoothRedraw(Random(sizeX * size_of_cell), 
               Random(sizeY * size_of_cell + 41));
  RedrawObjects;
  objTimer.Start;
end;

function NeibNonFlagedMine(x, y: byte): boolean;
var
  i, j: shortint;
  posX, posY: byte;
begin
  for i := -1 to 1 do 
  begin
    posX := x + i;
    for j := -1 to 1 do 
    begin
      posY := y + j;
      if (posX >= 0) and (posX < sizeX) and
         (posY >= 0) and (posY < sizeY) then
        if (field[posX, posY].mine) and 
           (not field[posX, posY].flag) then
        begin
          result := true;
          exit;
        end;
    end;
  end;
end;

procedure RestartGame();
begin
  objTimer.Stop;
  ResetField(true, false);
  gameover := false;
  time := 0;
  
  InfoBox.Text := '';
  Str(calculateflags, temp_str);
  FlagBox.Text := 'Flags ' + temp_str + '/' + mines_str;
  Str(time, temp_str);
  TimerBox.Text := 'Time ' + temp_str;
  
  SmoothRedraw(Random(sizeX * size_of_cell), 
               Random(sizeY * size_of_cell + 41));
  RedrawObjects;
  objTimer.Start;
end;

procedure CreatePictures();
begin
  closed := Picture.Create(folder + 'closed.png');
  opened := Picture.Create(folder + 'opened.png');
  flag := Picture.Create(folder + 'flag.png');
  query := Picture.Create(folder + 'query.png');
  mine := Picture.Create(folder + 'mine.png');
  exploded := Picture.Create(folder + 'exploded.png');
  tick := Picture.Create(folder + 'tick.png');
  wrong := Picture.Create(folder + 'wrong.png');
  one := Picture.Create(folder + '1.png');
  two := Picture.Create(folder + '2.png');
  three := Picture.Create(folder + '3.png');
  four := Picture.Create(folder + '4.png');
  five := Picture.Create(folder + '5.png');
  six := Picture.Create(folder + '6.png');
  seven := Picture.Create(folder + '7.png');
  eight := Picture.Create(folder + '8.png');
end;

procedure ChangePictures();
begin
  closed.Load(folder + 'closed.png');
  opened.Load(folder + 'opened.png');
  flag.Load(folder + 'flag.png');
  query.Load(folder + 'query.png');
  mine.Load(folder + 'mine.png');
  exploded.Load(folder + 'exploded.png');
  tick.Load(folder + 'tick.png');
  wrong.Load(folder + 'wrong.png');
  one.Load(folder + '1.png');
  two.Load(folder + '2.png');
  three.Load(folder + '3.png');
  four.Load(folder + '4.png');
  five.Load(folder + '5.png');
  six.Load(folder + '6.png');
  seven.Load(folder + '7.png');
  eight.Load(folder + '8.png');
end;

procedure InitWindow();
begin
  SetWindowSize(560, 620);
  Window.Fill(folder + 'background.png');
  Redraw;
  CenterWindow;
  
  NewG := RectangleABC.Create(0, 0, 187, 20, clTransparent);
  NewG.FontName := font;
  NewG.Text := 'New Game';
  NewG.FontColor := clWhite;
  NewG.TextScale := 1;
  NewG.Bordered := false;
  
  RestartG := RectangleABC.Create(187, 0, 187, 20, clTransparent);
  RestartG.FontName := font;
  RestartG.Text := 'Restart Game';
  RestartG.FontColor := clWhite;
  RestartG.TextScale := 1;
  RestartG.Bordered := false;
  
  Skin := RectangleABC.Create(373, 0, 186, 20, clTransparent);
  Skin.FontName := font;
  Skin.Text := 'Skin';
  Skin.FontColor := clWhite;
  Skin.TextScale := 1;
  Skin.Bordered := false;
  
  Beginner := RectangleABC.Create(0, 20, 140, 20, clTransparent);
  Beginner.FontName := font;
  Beginner.Text := 'Beginner';
  Beginner.FontColor := clWhite;
  Beginner.TextScale := 1;
  Beginner.Bordered := false;
  
  Intermediate := RectangleABC.Create(140, 20, 140, 20, clTransparent);
  Intermediate.FontName := font;
  Intermediate.Text := 'Intermediate';
  Intermediate.FontColor := clWhite;
  Intermediate.TextScale := 1;
  Intermediate.Bordered := false;
  
  Expert := RectangleABC.Create(280, 20, 140, 20, clTransparent);
  Expert.FontName := font;
  Expert.Text := 'Expert';
  Expert.FontColor := clWhite;
  Expert.TextScale := 1;
  Expert.Bordered := false;
  
  Custom := RectangleABC.Create(420, 20, 140, 20, clTransparent);
  Custom.FontName := font;
  Custom.Text := 'Custom';
  Custom.FontColor := clWhite;
  Custom.TextScale := 1;
  Custom.Bordered := false;
  
  TimerBox := RectangleABC.Create(0, 600, 187, 20, clTransparent);
  TimerBox.FontName := font;
  TimerBox.FontColor := clWhite;
  TimerBox.TextScale := 1;
  TimerBox.Bordered := false;
  
  InfoBox := RectangleABC.Create(187, 600, 187, 20, clTransparent);
  InfoBox.FontName := font;
  InfoBox.FontStyle := fsBold;
  InfoBox.TextScale := 1;
  InfoBox.Bordered := false;
  
  FlagBox := RectangleABC.Create(373, 600, 186, 20, clTransparent);
  FlagBox.FontName := font;
  FlagBox.FontColor := clWhite;
  FlagBox.TextScale := 1;
  FlagBox.Bordered := false;
  
  SetLength(field, sizeX, sizeY);
  for var i := 0 to sizeX - 1 do
    for var j := 0 to sizeY - 1 do 
      field[i, j].image := PictureABC.Create(size_of_cell * i, 
                                             size_of_cell * j + 40, closed);
  
  RedrawObjects;
end;

procedure ResizeWindow(x, y: byte; m: word);
begin
  for var i := 0 to sizeX - 1 do
    for var j := 0 to sizeY - 1 do
      field[i, j].image.Destroy;
  
  sizeX := x;
  sizeY := y;
  mines := m;
  SetLength(field, sizeX, sizeY);
  
  SetWindowSize(sizeX * size_of_cell, sizeY * size_of_cell + 60);
  Window.Fill(folder + 'background.png');
  Redraw;
  CenterWindow;
  
  NewG.Width := (round((sizeX * size_of_cell) / 3));
  
  RestartG.Left := (round((sizeX * size_of_cell) / 3));
  RestartG.Width := (round((sizeX * size_of_cell) / 3));
  
  Skin.Left := (sizeX * size_of_cell) - 
                (round((sizeX * size_of_cell) / 3));
  Skin.Width := (round((sizeX * size_of_cell) / 3));
  
  Beginner.Width := round((sizeX * size_of_cell) / 4);
  
  Intermediate.Left := round(((sizeX * size_of_cell) / 2) - 
                             ((sizeX * size_of_cell) / 4));
  Intermediate.Width := round((sizeX * size_of_cell) / 4);
  
  Expert.Left := round((sizeX * size_of_cell) / 2);
  Expert.Width := round((sizeX * size_of_cell) / 4);
  
  Custom.Left := round((sizeX * size_of_cell) - 
                      ((sizeX * size_of_cell) / 4));
  Custom.Width := round((sizeX * size_of_cell) / 4);
  
  TimerBox.Top := sizeY * size_of_cell + 40;
  TimerBox.Width := (round((sizeX * size_of_cell) / 3));
  
  InfoBox.Left := (round((sizeX * size_of_cell) / 3));
  InfoBox.Top := sizeY * size_of_cell + 40;
  InfoBox.Width := (round((sizeX * size_of_cell) / 3));
  
  FlagBox.Left := (sizeX * size_of_cell) - 
                  (round((sizeX * size_of_cell) / 3));
  FlagBox.Top := sizeY * size_of_cell + 40;
  FlagBox.Width := (round((sizeX * size_of_cell) / 3));
  
  RedrawObjects;
  
  for var i := 0 to sizeX - 1 do
    for var j := 0 to sizeY - 1 do 
      field[i, j].image := PictureABC.Create(size_of_cell * i, 
                                             size_of_cell * j + 40, closed);
  
  RedrawObjects;
  NewGame;
end;

procedure ClearExit();
begin
  closed := nil;
  opened := nil;
  flag := nil;
  query := nil;
  mine := nil;
  exploded := nil;
  tick := nil;
  wrong := nil;
  one := nil;
  two := nil;
  three := nil;
  four := nil;
  five := nil;
  six := nil;
  seven := nil;
  eight := nil;
  NewG := nil;
  RestartG := nil;
  Skin := nil;
  Beginner := nil;
  Intermediate := nil;
  Expert := nil;
  Custom := nil;
  TimerBox := nil;
  InfoBox := nil;
  FlagBox := nil;
  objTimer := nil;
  field := nil;
  Delete(stack);
end;

procedure ChangeSkin();
begin
  if (not gameover) then 
  begin
    if (folder = 'deep_green/') then
      folder := 'royal_blue/' else
    if (folder = 'royal_blue/') then
      folder := 'deep_green/';
    
    Window.Fill(folder + 'background.png');
    ChangePictures;
    for var i := 0 to sizeX - 1 do
      for var j := 0 to sizeY - 1 do
        UpdateStatus(i, j);
    
    Redraw;
    RedrawObjects;
  end;
end;

procedure KeyDown(key: integer);
begin
  case (key) of
    VK_Escape: 
      begin
        ClearExit;
        Halt; 
      end;
  end;
end;

procedure Open(x, y: byte);
var
  i, j: shortint;
  posX, posY: byte;
begin
  if (not field[x, y].opened) and 
     (not field[x, y].flag) then
  begin
    field[x, y].opened := true;
    UpdateStatus(x, y);
    if (field[x, y].neig = 0) and
       (not field[x, y].mine) then
      PushTwo(x, y, stack);
    while (not Empty(stack)) do 
    begin
      for i := -1 to 1 do 
      begin
        posX := x + i;
        for j := -1 to 1 do 
        begin
          posY := y + j;
          if (posX >= 0) and (posX < sizeX) and
             (posY >= 0) and (posY < sizeY) then 
            if (field[posX, posY].neig >= 0) and 
               (not field[posX, posY].opened) and
               (not field[posX, posY].flag) then 
            begin
              field[posX, posY].opened := true;
              UpdateStatus(posX, posY);
              if (field[posX, posY].neig = 0) and
                 (not field[posX, posY].mine) then
                PushTwo(posX, posY, stack);
            end;
        end;
      end;
      x := Pop(stack);
      y := Pop(stack);
    end;
  end;
end;

procedure FinalScreen(win: boolean);
begin
  objTimer.Stop;
  
  if (not win) then begin
    InfoBox.Text := 'You Lose!';
    InfoBox.FontColor := clRed;
    for var i := 0 to sizeX - 1 do
      for var j := 0 to sizeY - 1 do 
      begin
        if (field[i, j].mine) and 
           (field[i, j].flag) and 
           (not field[i, j].opened) then
          field[i, j].image.ChangePicture(tick) else
        if (field[i, j].flag) and 
           (not field[i, j].mine) and 
           (not field[i, j].opened) then
          field[i, j].image.ChangePicture(wrong) else
        if (field[i, j].mine) and 
           (not field[i, j].opened) then
          field[i, j].image.ChangePicture(mine);
      end;
  end else 
  begin
    InfoBox.Text := 'You Win!';
    InfoBox.FontColor := clLime;
    for var i := 0 to sizeX - 1 do
      for var j := 0 to sizeY - 1 do
        if (field[i, j].mine) then 
          field[i, j].image.ChangePicture(tick);
  end;
  
  InfoBox.RedrawNow;
end;

procedure MouseClick(x, y, mb: integer);
var
  i, j: shortint;
  posX, posY: byte;
  supX, supY: byte;
begin
  if (not gameover) and 
     (y >= 40) and 
     (y < sizeY * size_of_cell + 40) then
  begin
    posX := x div size_of_cell;
    posY := (y - 40) div size_of_cell;
    
    if (mb = 1) and 
       (not field[posX, posY].flag) then
    begin
      
      if (first_step) then
      begin
        ResetField(false, true);
        SetMines(posX, posY);
        CalculateNeighborMines;
        first_step := false;
      end;
      
      if (not field[posX, posY].opened) then
      begin
        Open(posX, posY);
        if (field[posX, posY].neig > 0) then
          field[posX, posY].image.RedrawNow;
      end else
      if (field[posX, posY].neig > 0) and
         (CalculateNeibFlags(posX, posY) = field[posX, posY].neig) then
        if (not NeibNonFlagedMine(posX, posY)) then
        begin
          for i := -1 to 1 do 
          begin
            supX := posX + i;
            for j := -1 to 1 do 
            begin
              supY := posY + j;
              if (supX >= 0) and (supX < sizeX) and
                 (supY >= 0) and (supY < sizeY) and
                 (not gameover) and (not field[supX, supY].opened) then
                Open(supX, supY);
            end;
          end;
        end else
        begin
          for i := -1 to 1 do 
          begin
            supX := posX + i;
            for j := -1 to 1 do 
            begin
              supY := posY + j;
              if (supX >= 0) and (supX < sizeX) and
                 (supY >= 0) and (supY < sizeY) and
                 (not gameover) and (field[supX, supY].mine) then
                Open(supX, supY);
            end;
          end;
        end;
      
      if (Win) then 
      begin
        FinalScreen(true);
        SmoothRedraw(x, y);
      end else
      if (Lose) then
      begin
        FinalScreen(false);
        SmoothRedraw(x, y);
      end;
      
      if (not gameover) then
        SmoothRedraw(x, y);
    end else
    if (mb = 2) and 
       (not field[posX, posY].opened) then
    begin
      if (not field[posX, posY].flag) and 
         (not field[posX, posY].query) then
        field[posX, posY].flag := true else
      if (field[posX, posY].flag) and 
         (not field[posX, posY].query) then 
      begin
        field[posX, posY].flag := false;
        field[posX, posY].query := true;
      end else
      if (not field[posX, posY].flag) and 
         (field[posX, posY].query) then
        field[posX, posY].query := false;
      
      Str(CalculateFlags, temp_str);
      FlagBox.Text := 'Flags ' + temp_str + '/' + mines_str;
      FlagBox.RedrawNow;
      
      UpdateStatus(posX, posY);
      field[posX, posY].image.RedrawNow;
    end;
  end;
  
  if (mb = 1) then
    if NewG.PtInside(x, y) then NewGame else
    if RestartG.PtInside(x, y) then RestartGame else
    if Beginner.PtInside(x, y) then ResizeWindow(9, 9, 10) else
    if Intermediate.PtInside(x, y) then ResizeWindow(16, 16, 40) else
    if Expert.PtInside(x, y) then ResizeWindow(30, 16, 99) else
    if Custom.PtInside(x, y) then ResizeWindow(sizeXc, sizeYc, minesc) else
    if Skin.PtInside(x, y) then ChangeSkin;
end;

procedure Resize();
begin
  Redraw;
  RedrawObjects;
end;

begin
  SetWindowTitle('Minesweeper');
  SetWindowIsFixedSize(true);
  
  Randomize;
  
  if (random(2) = 0) then 
    folder := 'deep_green/' else
    folder := 'royal_blue/';
  
  CreatePictures;
  LockDrawing;
  LockDrawingObjects;
  
  sizeX := 16;
  sizeY := 16;
  mines := 40;
  
  assign(settings, 'custom.ini');
  reset(settings);
  readln(settings, sizeXc, sizeYc);
  readln(settings, minesc);
  close(settings);
  
  if (sizeXc < 9) then 
    sizeXc := 9 else
  if (sizeXc > 30) then
    sizeXc := 30;
  if ((Screen.PrimaryScreen.Bounds.Width div size_of_cell) - 1 < sizeXc) then
    sizeXc := (Screen.PrimaryScreen.Bounds.Width div size_of_cell) - 1;
  
  if (sizeYc < 9) then
    sizeYc := 9 else
  if (sizeYc > 24) then
    sizeYc := 24;
  if (((Screen.PrimaryScreen.Bounds.Height - 60) div size_of_cell) - 1 < sizeYc) then
    sizeYc := ((Screen.PrimaryScreen.Bounds.Height - 60) div size_of_cell) - 1;
  
  if (minesc < 10) then
    minesc := 10 else
  if (minesc > (sizeXc - 1) * (sizeYc - 1)) then
    minesc := (sizeXc - 1) * (sizeYc - 1);
  
  InitWindow;
  NewGame;
  
  OnMouseDown := MouseClick;
  OnKeyDown := KeyDown;
  OnResize := Resize;
  OnClose := ClearExit;
end.