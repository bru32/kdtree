//
// https://github.com/showcode
//

program KDTree;

uses
  Forms,
  main in 'main.pas' {MainForm},
  TreeTypes in 'TreeTypes.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
