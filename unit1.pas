unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  {$ifdef mswindows}
  Windows,
{$endif}
  Classes, SysUtils,  Forms, Controls, Graphics, Dialogs, CheckLst,
  StdCtrls, Buttons, ExtCtrls, IniFiles, process, Unit2, Unit3, Fileutil;

type

  { TForm1 }

  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    BitBtn5: TBitBtn;
    BitBtn6: TBitBtn;
    Button1: TButton;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    ComboBox1: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    ListBox1: TListBox;
    Memo1: TMemo;
    Monitorpanel: TPanel;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Process1: TProcess;
    SaveDialog1: TSaveDialog;
    Splitter1: TSplitter;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure BitBtn6Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure CheckBox1Change(Sender: TObject);
    procedure CheckBox2Change(Sender: TObject);
    procedure EditffmpeglinebtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
    procedure Newffmpeglinebtn1Click(Sender: TObject);
    procedure Processinifile;

  private
    conf:TIniFile;
    cancelling:boolean;
  public
    ffminta:TStringlist;
    ffmintacim:TStringlist;
    ffmintaext:TstringList;
    ffmintapar:TStringList;
    ffmintainputopt:TStringList;
    Tempfilename:String;
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.ProcessInifile;
var i:integer;
   ext,par,cim,inputopt:String;
begin
ffminta.clear;
conf.ReadSection('Mintak',ffminta);
ffmintacim.clear;
Combobox1.Items.Clear;
ffmintapar.clear;
ffmintaext.clear;
ffmintainputopt.clear;
For i:= 0 to ffminta.Count -1 Do
  Begin
      cim:=conf.ReadString('Mintak', ffminta[i],'def');
      //rögtön az ext és par/cmd is beolvasva...
      ext:=conf.ReadString(ffminta[i],'ext','.avi');
      par:=conf.readstring(ffminta[i],'cmd',' -codec copy ');
      inputopt:=conf.readstring(ffminta[i],'inputopt','');
      ffmintacim.add(cim);
      ffmintapar.add(par);
      ffmintaext.add(ext);
      ffmintainputopt.add(inputopt);
      End;
Combobox1.Items.Assign(ffmintacim);
end;

procedure TForm1.FormDragDrop(Sender, Source: TObject; X, Y: Integer);
begin

end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
 // Form2.Showmodal;
end;

procedure TForm1.BitBtn3Click(Sender: TObject);
begin

end;

procedure TForm1.BitBtn6Click(Sender: TObject);
var Form3:TForm3;
   conffilename:string;
   begin
Form3:=Tform3.Create(self);
conffilename:=conf.Filename;
Form3.Memo1.Lines.LoadfromFile(conffilename);
Form3.showModal;
if Form3.ModalResult = mrOK then begin
   conf.Free;
   Form3.Memo1.Lines.SavetoFile(conffilename);
   conf:=TInifile.Create(conffilename);
   Processinifile;
 end;
Form3.free;
end;

procedure TForm1.Button1Click(Sender: TObject);
var i,j:integer;
  cmdline:string;
 params:TstringList;
 tempfile:Textfile;
 Buffer: pointer;
 SStream: TStringStream;
 nread: longint;
 mtsconcat:string;
 detectdirmism:boolean;
 ext,origext:string;

procedure Split (const Delimiter: Char; Input: string; const Strings: TStrings);
begin
   Assert(Assigned(Strings)) ;
   Strings.Clear;
   Strings.StrictDelimiter := true;
   Strings.Delimiter := Delimiter;
   Strings.DelimitedText := Input;
end;

procedure doupdatememo;
begin
Getmem(Buffer, 2048);
SStream := TStringStream.Create('');
while process1.Running do
begin
  nread := process1.Output.Read(Buffer^, 2048);
  if nread = 0 then begin
     application.processmessages;
    sleep(100);
  end
  else
    begin
      SStream.size := 0;
      SStream.Write(Buffer^, nread);
      Memo1.Lines.Text := Memo1.Lines.Text + SStream.DataString;
      Memo1.SelStart := Length(Memo1.Lines.Text);
      Application.ProcessMessages;
    end;
end;
repeat
  nread := process1.Output.Read(Buffer^, 2048);
  if nread > 0 then
  begin
    SStream.size := 0;
    SStream.Write(Buffer^, nread);
    Memo1.Lines.Text := Memo1.Lines.Text + SStream.Datastring;
     Memo1.SelStart := Length(Memo1.Lines.Text);
      Application.ProcessMessages;
  end
until nread = 0;
Freemem(buffer);
SStream.Free;
end;

procedure processinputoptions;
var  opts:TStringList;
     cnt:integer;
begin
  if ffmintainputopt[combobox1.itemindex] <> '' then begin
                             opts:=TStringList.Create;
                             Split(' ',ffmintainputopt[combobox1.itemindex],opts);
                              for cnt:=0 to opts.count-1 do begin
                                  cmdline:=opts[cnt];
                                  process1.parameters.add(cmdline);
                                  end;
                             opts.Free;
                             end;
end;

begin
 if (Combobox1.Itemindex > -1) And Not process1.Running then begin
  Memo1.Lines.clear;
  Listbox1.enabled:=false;
  Bitbtn1.Enabled:=false;
  Bitbtn2.Enabled:=false;
  Bitbtn3.Enabled:=false;
  Combobox1.Enabled:=False;
  Button1.Caption:='Stop!';

  If Not CheckBox1.Checked Then Begin
      for i:= 0 to Listbox1.items.count - 1 do
        if not cancelling then begin

      process1.parameters.clear;
      params:=TStringList.Create;

      processinputoptions;

      process1.parameters.add('-i');
      process1.parameters.add(listbox1.items.strings[i]);
 // mégsem kell     ExtractFileExt(listbox1.items.strings[i]);

      Split(' ',ffmintapar[combobox1.itemindex],params);
      for j:=0 to params.count-1 do begin
        cmdline:=params[j];
        process1.parameters.add(cmdline);
      end;
      params.free;
      if Checkbox3.Checked Then
          cmdline:= listbox1.Items.strings[i]+'.konvert'+ffmintaext[combobox1.itemindex]
          Else
          cmdline:= listbox1.Items.strings[i]+ffmintaext[combobox1.itemindex];
      process1.parameters.add(cmdline);
      process1.parameters.add ('-y');
      Listbox1.Itemindex:=i;
      process1.execute;
      doupdatememo;
      end;
     end
     else begin
     if CheckBox2.Checked Then begin
        process1.parameters.clear;
        processinputoptions;
        process1.parameters.add('-i');
        detectdirmism:=false;
        mtsconcat:='concat:';
      //  cmdline:=ExtractFilepath( listbox1.Items.strings[0]);
        for j:=0 to listbox1.Items.count-1 do begin
            mtsconcat:=mtsconcat+ listbox1.Items.strings[j] + '|';  // ExtractFilename(listbox1.Items.strings[j]) + '|';
           // if (ExtractFilepath(listbox1.Items.strings[j]) <> cmdline) Then detectdirmism:=true ;
        end;
        delete(mtsconcat,length(mtsconcat),1);
        process1.parameters.add(mtsconcat);
        //delete(cmdline,length(cmdline),1);
        //process1.CurrentDirectory := cmdline;
         params:=TStringList.Create;
          Split(' ',ffmintapar[combobox1.itemindex],params);
          for j:=0 to params.count-1 do begin
            cmdline:=params[j];
            process1.parameters.add(cmdline);
          end;
          params.free;
         if detectdirmism then begin
            Showmessage('A concat protokollhoz egy könyvtárban kell lenniük a fájloknak');
            end else
          if SaveDialog1.Execute Then begin
             cmdline:=Savedialog1.FileName+'.konvert'+ffmintaext[combobox1.itemindex] ;
             process1.Parameters.Add(cmdline);
             process1.parameters.add('-y');
             cmdline:='';
             for j:=0 to process1.parameters.count-1 do
                  cmdline:=cmdline+process1.parameters[j]+' ';
             process1.Execute;
             doupdatememo;
          End;
      end else begin
         AssignFile(tempfile,TempFilename);
         Rewrite(tempfile);
         for i:=0 to Listbox1.Count -1 do begin
            cmdline:='file ''';
            cmdline:=cmdline+listbox1.Items.strings[i];
            cmdline:=cmdline+'''';
            writeln(tempfile,cmdline);
         end;
         closefile(tempfile);

         process1.parameters.clear;
         processinputoptions;
         process1.parameters.add('-safe');
         process1.parameters.add('0');
         process1.parameters.add('-f');
         process1.parameters.add('concat');
         process1.parameters.add('-i');
         process1.Parameters.add(tempfilename);
         params:=TStringList.Create;
          Split(' ',ffmintapar[combobox1.itemindex],params);
          for j:=0 to params.count-1 do begin
            cmdline:=params[j];
            process1.parameters.add(cmdline);
          end;
          params.free;
          if SaveDialog1.Execute Then begin
             cmdline:=Savedialog1.FileName+'.konvert'+ffmintaext[combobox1.itemindex] ;
             process1.Parameters.Add(cmdline);
             process1.parameters.add('-y');
             process1.Execute;
             doupdatememo;
          End;
          Erase(tempfile);
     end;

  end;
 Memo1.Lines.Add('Kész, ennyi...');
 Listbox1.Enabled:=true;
  Bitbtn1.Enabled:=true;
  Bitbtn2.Enabled:=true;
  Bitbtn3.Enabled:=true;
  Combobox1.Enabled:=true;
  Button1.Caption:='Konvert!';
  cancelling:=false;

end else if process1.Running then begin
    cancelling:=true;
    process1.terminate(i);
  end;
end;


procedure TForm1.Button2Click(Sender: TObject);
var i:integer;
begin
If Listbox1.Count > 0 Then begin
      i:=0;
      if Not Listbox1.Selected [0] Then Begin
           while i <= Listbox1.items.count-1 do
           if Listbox1.selected[i] Then Begin
                                        Listbox1.items.Move(i, i-1);
                                        Listbox1.Selected[i-1]:=True;

           end
           Else i:=i+1;
          End;
End;
end;

procedure TForm1.Button3Click(Sender: TObject);
var i:integer;
begin
If Listbox1.Count > 0 Then begin
          i:=Listbox1.Count-1;
          if Not Listbox1.Selected [i] Then Begin;
           while i >= 0  do
           if Listbox1.selected[i] Then Begin
                                        Listbox1.items.Move(i, i+1);
                                        Listbox1.Selected[i+1]:=True;

           end
           Else i:=i-1;
End;
End;
end;

procedure TForm1.Button4Click(Sender: TObject);
var i:Integer;
begin
  i:=0;
  while i <= Listbox1.items.count-1 do
  if Listbox1.selected[i] Then Listbox1.items.Delete(i)
  Else i:=i+1;
end;

procedure TForm1.CheckBox1Change(Sender: TObject);
begin
  CheckBox2.Enabled:=CheckBox1.Checked;
end;

procedure TForm1.CheckBox2Change(Sender: TObject);
begin

end;

procedure TForm1.EditffmpeglinebtnClick(Sender: TObject);
var Form2:TForm2;
begin
if Combobox1.Itemindex>-1 Then Begin
Form2:=TForm2.Create(Self);
Form2.Edit1.Text:= ffmintainputopt[Combobox1.Itemindex];
Form2.Edit2.Text:= ffmintapar[Combobox1.Itemindex];
Form2.Edit3.Text:= ffmintaext[Combobox1.Itemindex];
Form2.Edit4.Text := ffminta[Combobox1.Itemindex];
Form2.Edit4.Readonly:=True;
Form2.Edit5.Text:= Combobox1.Text;
Form2.Edit5.Readonly:=True;
Form2.Showmodal;
if Form2.Modalresult =mrOK Then Begin
   conf.WriteString(ffminta[Combobox1.Itemindex],'ext',Form2.Edit3.Text);
   conf.WriteString(ffminta[Combobox1.Itemindex],'cmd',Form2.Edit2.Text);
   conf.WriteString(ffminta[Combobox1.Itemindex],'inputopt',Form2.Edit1.Text);
    ffmintainputopt[Combobox1.Itemindex] := Form2.Edit1.Text;
    ffmintapar[Combobox1.Itemindex] := Form2.Edit2.Text;
    ffmintaext[Combobox1.Itemindex] := Form2.Edit3.Text;
 End;


Form2.Free;
End;
end;

procedure TForm1.FormCreate(Sender: TObject);
   var
     i:integer;
    ext:string;
    konfigname:string;
    defaultkonf,konfigdir:string;
    {$IFDEF MSWINDOWS}        PIDL : PItemIDList;    {$ENDIF}
    Folder : array[0..MAX_PATH] of Char;
begin

{$IFDEF MSWINDOWS}
  SHGetSpecialFolderLocation(0,  $0028, PIDL);
  SHGetPathFromIDList(PIDL, Folder);
 konfigdir:=Folder+'\';
 //konfigname:=Extractfilepath(paramstr(0))+'konverter.conf';


 //konfigname:='c:\konverter.conf';
{$ENDIF}
{$IFDEF UNIX}
konfigdir :=  Extractfilepath(GetAppConfigDir(false));
konfigname:=konfigdir+'konverter.conf';

{$ENDIF}
cancelling:=false;
if Not FileExists(konfigname) Then Begin
   defaultkonf:=  Extractfilepath(paramstr(0))+'konverter.conf';
   ForceDirectories(konfigdir);
   if Not CopyFile(defaultkonf,konfigname) Then
   Messagedlg('Konfigurációs fájl','Az alapértelmezett konfigurációs fájlt nem sikerült a helyére tenni.',mtWarning,[mbOK],0);

 End;
conf:=TIniFile.Create(konfigname);
//conf.UpdateFile ;

  ffminta:=TStringlist.Create;
  ffmintacim:=TStringlist.Create;
  ffmintapar:=TStringList.Create;
  ffmintaext:=TStringList.Create;
  ffmintainputopt:=TStringList.Create;
  {$IFDEF MSWINDOWS}
  ext:= conf.ReadString('alap','ffmpeg','.');
  if ext='.' Then ext:=Extractfilepath(paramstr(0))+'ffmpeg.exe';
  {$ENDIF}
  {$IFDEF UNIX}
  ext:= conf.ReadString('alap','ffmpeg','ffmpeg');

  {$ENDIF}
  process1.executable:=ext;

  Processinifile;

  Tempfilename:=Gettempfilename(Gettempdir(False),'');

end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  ffmintaext.free;
  ffmintacim.free;
  ffmintapar.free;
  ffminta.free;
  ffmintainputopt.free;
  conf.free;
end;

procedure TForm1.FormDropFiles(Sender: TObject; const FileNames: array of String
  );
var
  i: Integer;
function Acceptable(input: string):boolean;
begin
Result:=false;
Case Uppercase(input) of
'.MOV': Result:=True;
'.AVI': Result:=true;
'.MTS': Result:=true;
'.MP4': Result:=True;
'.MP3': Result:=True;
'.WAV': Result:=True;
'.MKV': Result:=true;
'.FLAC':Result:=True;
'.MPG':Result:=True;
'.MPEG':Result:=True;
'.APE':Result:=True;
'.AU':Result:=True;
'.VOB':Result:=True;
'.M4A':Result:=True;
'.M4V':Result:=True;
'.OGG':Result:=True;

end;


end;

begin
   for i := Low(FileNames) to High(FileNames) do begin
      if Acceptable (Extractfileext(FileNames[i])) Then
          ListBox1.Items.Add(FileNames[i]);
    end;
 end;

procedure TForm1.Newffmpeglinebtn1Click(Sender: TObject);
var Form2:TForm2;
  done:boolean;
newidi:integer;
newids:string;

function checknewid(ID:String):Boolean;
var k:integer;
  found: boolean;
begin
k:=0; found :=false;
while (k< ffminta.count) and not found  do begin
      found:=( ffminta[k] = ID) ;
      k:=k+1;
   end;
Result:=found;
end;

begin
Form2:=TForm2.Create(Self);
Form2.Edit1.Text:= '' ; //ffmintainputopt[Combobox1.Itemindex];
Form2.Edit2.Text:= ''; //ffmintapar[Combobox1.Itemindex];
Form2.Edit3.Text:= '' ;//ffmintaext[Combobox1.Itemindex];
newidi:=ffminta.count;
repeat
newids:=inttostr(newidi);
newidi:=newidi+1;
until not checknewid(newids);

Form2.Edit4.Text := newids; //ffminta[Combobox1.Itemindex];
//Form2.Edit4.Readonly:=True;

Form2.Edit5.Text:= ''; //Combobox1.Text;
//Form2.Edit5.Readonly:=True;
Done:=False;
Repeat

Form2.Showmodal;
newids:=Form2.Edit4.Text;
if Form2.Modalresult =mrOK Then Begin
   if checknewid(newids) then begin
        Done:=( Messagedlg('ID nem egyedi','Az ID nem egyedi, így nem lehet elmenteni.'+#13+'Módosítod?',mtError,[mbOK,mbCancel],'') = mrCancel );
   end
   else begin
      //itt ki lehet írni az új adatot
   ffminta.Add(newids);
   Combobox1.Items.Add(Form2.Edit5.Text);
   ffmintainputopt.Add(Form2.Edit1.Text);
   ffmintapar.Add(Form2.Edit2.Text);
   ffmintaext.Add(Form2.Edit3.Text);

   conf.WriteString(newids,'ext',Form2.Edit3.Text);
   conf.WriteString(newids,'cmd',Form2.Edit2.Text);
   conf.WriteString(newids,'inputopt',Form2.Edit1.Text);

   conf.Writestring('Mintak',newids,Form2.Edit5.Text);
   Done:=True
   end;
 End Else Done:=True;

Until Done;

Form2.Free;

end;

end.

