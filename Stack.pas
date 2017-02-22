unit Stack;

interface

type
  list = ^node;
  node = record
    data: integer;
    next: list;
  end;

procedure Push(data: integer; var stack: list);
procedure PushTwo(data1, data2: integer; var stack: list);
function Pop(var stack: list): integer;
function Top(stack: list): integer;
procedure Show(stack: list);
function Empty(stack: list): boolean;
function Count(stack: list): integer;
procedure Clear(var stack: list);
procedure Delete(var stack: list);

implementation

procedure Push(data: integer; var stack: list);
var
  temp: list;
begin
  New(temp);
  temp^.data := data;
  temp^.next := stack;
  stack := temp;
end;

procedure PushTwo(data1, data2: integer; var stack: list);
begin
  Push(data2, stack);
  Push(data1, stack);
end;

function Pop(var stack: list): integer;
var
  temp: list;
begin
  result := stack^.data;
  temp := stack;
  stack := stack^.next;
  Dispose(temp);
end;

function Top(stack: list): integer;
begin
  result := stack^.data;
end;

procedure Show(stack: list);
begin
  while (not Empty(stack)) do
  begin
    write(stack^.data, ' ');
    stack := stack^.next;
  end;
end;

function Empty(stack: list): boolean;
begin
  if (stack = nil) then 
    result := true;
end;

function Count(stack: list): integer;
begin
  if (not Empty(stack)) then
  begin
    while (not Empty(stack)) do
    begin
      stack := stack^.next;
      Inc(Result);
    end;
  end else
    Result := 0;
end;

procedure Clear(var stack: list);
begin
  while (not Empty(stack)) do
    Pop(stack);
end;

procedure Delete(var stack: list);
begin
  Clear(stack);
  Dispose(stack);
end;
end.