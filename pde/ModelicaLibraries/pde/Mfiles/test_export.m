function varargout = test_export(varargin)
% TEST_EXPORT M-file for test_export.fig
%      TEST_EXPORT, by itself, creates a new TEST_EXPORT or raises the existing
%      singleton*.
%
%      H = TEST_EXPORT returns the handle to a new TEST_EXPORT or the handle to
%      the existing singleton*.
%
%      TEST_EXPORT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TEST_EXPORT.M with the given input arguments.
%
%      TEST_EXPORT('Property','Value',...) creates a new TEST_EXPORT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before test_export_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to test_export_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help test_export

% Last Modified by GUIDE v2.5 30-Jun-2004 15:19:08

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @test_export_OpeningFcn, ...
                   'gui_OutputFcn',  @test_export_OutputFcn, ...
                   'gui_LayoutFcn',  @test_export_LayoutFcn, ...
                   'gui_Callback',   []);
if nargin & isstr(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before test_export is made visible.
function test_export_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to test_export (see VARARGIN)

% Choose default command line output for test_export
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

matfile='';
if nargin >= 5 
    if not(strcmpi(varargin{1},'mat'))
        errordlg(['Unrecognized option: ' varargin{1}],'Input Argument Error!') 
        return
    else
        if not(exist(varargin{2},'file'))
            errordlg(['File does not exist or not a regular file: ' varargin{2}],'Input Argument Error!')
            return
        else
            matfile=varargin{2};
        end
    end
else
    matfile=uigetfile('*.mat','Open simulation result file');
    if not(exist(varargin{2},'file'))
       errordlg(['File does not exist or not a regular file: ' matfile],'Input Argument Error!')
       return
   end
end
load_variables(matfile,handles);

function load_variables(matfile, handles)
mat=dymload(matfile);
handles.matstr = mat;
femfnames=get_matching_names(mat.name,'(.*)\.domain\.grid\.triangle');
fdmfnames=get_matching_names(mat.name,'(.*)\.domain\.grid\.x1');
handles.femfnames=femfnames;
handles.fdmfnames=fdmfnames;
handles.currentvar = '-Variables-';
handles.plotfunc = @ones;
handles.interrupt = 0;
guidata(handles.figure1,handles);
set(handles.varpopup,'String',{'-Variables-' femfnames{:} fdmfnames{:} });
set(handles.varpopup,'Value',1);
set(handles.timeslider,'Max',2);
set(handles.timeslider,'Min',1);
set(handles.timeslider,'SliderStep',[1 1]);
set(handles.timeslider,'Value',1);
time=dymget(handles.matstr,'Time');
set(handles.timeedit,'String',num2str(time(1)));

% UIWAIT makes test_export wait for user response (see UIRESUME)
% uiwait(handles.figure1);

function names = get_matching_names(namearray,regxp)
[s,f,t]=regexp(namearray,regxp);
names={};
for i=1:size(t)
    if not(isempty(t{i}))
        name=namearray(i,t{i}{1}(1):t{i}{1}(2));
        names=union(names,{name});
    end
end


% --- Outputs from this function are returned to the command line.
function varargout = test_export_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes during object creation, after setting all properties.
function timeslider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timeslider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background, change
%       'usewhitebg' to 0 to use default.  See ISPC and COMPUTER.
usewhitebg = 1;
if usewhitebg
    set(hObject,'BackgroundColor',[.9 .9 .9]);
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on slider movement.
function timeslider_Callback(hObject, eventdata, handles)
% hObject    handle to timeslider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
val=get(hObject,'Value');
val=round(val);
set(hObject,'Value',val);
time=dymget(handles.matstr,'Time');
set(handles.timeedit,'String',num2str(time(val)));
update_plot(handles);

% --- Executes during object creation, after setting all properties.
function timeedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timeedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function timeedit_Callback(hObject, eventdata, handles)
% hObject    handle to timeedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of timeedit as text
%        str2double(get(hObject,'String')) returns contents of timeedit as a double


% --- Executes during object creation, after setting all properties.
function varpopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to varpopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on selection change in varpopup.
function varpopup_Callback(hObject, eventdata, handles)
% hObject    handle to varpopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns varpopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from varpopup
contents=get(hObject,'String');
fname=contents{get(hObject,'Value')};
handles.currentvar=fname;
guidata(hObject, handles);
update_plot_var(handles);


function update_plot_var(handles)
fname=handles.currentvar;
if strcmpi(fname,'-Variables-')
    return
end
steps=1;
if ismember(fname,handles.femfnames)
    handles.plotfunc=@femplot;    
else
    if ismember(fname,handles.fdmfnames)
        handles.plotfunc=@fdmplot;
    else
        handles.plotfunc=@ones;
    end
end
guidata(handles.figure1, handles);
set(handles.viewchange,'Value',0);
set(handles.timeslider,'Value',1);
steps=update_plot(handles);
if (steps == 0)
    return
end
set(handles.timeslider,'Max',steps);
set(handles.timeslider,'SliderStep',[1./steps 1./steps]);
set(handles.movieframes,'String',num2str(steps));

if (get(handles.autoscale,'Value') == 0)
    val=cell2mat(dymget(handles.matstr,[handles.currentvar '.val']));
    minval=min(val);
    minval=min(minval);
    minval=round(0.95*minval);
    maxval=max(val);
    maxval=max(maxval);
    maxval=round(1.05*maxval);
    range=[minval maxval];
    set(handles.zrange,'String',num2str(range));
    set(handles.axes,'ZLim',range);
end

function steps=update_plot(handles)
fname=handles.currentvar;
view=get(handles.axes,'View');
step=get(handles.timeslider,'Value');
if strcmpi(fname,'-Variables-')
    return;
end
f=functions(handles.plotfunc);
fn=f.function;
steps=0;
if (strcmp(fn,'femplot') | strcmp(fn,'fdmplot'))
    steps=feval(handles.plotfunc, handles.matstr,fname,step);
    set(handles.axes,'View',view);
    set(handles.viewchange,'Value',0);
    if get(handles.autoscale,'Value') == 0
        zscale = 'manual';
        set(handles.axes,'ZLim',str2num(get(handles.zrange,'String')));
    else
        zscale = 'auto';
    end
    set(handles.axes,'ZLimMode',zscale);
end



% --- Executes on button press in viewchange.
function viewchange_Callback(hObject, eventdata, handles)
% hObject    handle to viewchange (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of viewchange
if get(hObject,'Value')
    rotate3d on;
else
    rotate3d off;
end


% --- Executes during object creation, after setting all properties.
function zrange_CreateFcn(hObject, eventdata, handles)
% hObject    handle to zrange (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function zrange_Callback(hObject, eventdata, handles)
% hObject    handle to zrange (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of zrange as text
%        str2double(get(hObject,'String')) returns contents of zrange as a double
update_plot(handles);

% --- Executes on button press in autoscale.
function autoscale_Callback(hObject, eventdata, handles)
% hObject    handle to autoscale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of autoscale
update_plot(handles);


% --- Executes on button press in movie.
function movie_Callback(hObject, eventdata, handles)
% hObject    handle to movie (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
maxsteps=str2num(get(handles.movieframes,'String'));
min=get(handles.timeslider,'Min');
max=get(handles.timeslider,'Max');
if (maxsteps > max | maxsteps == 0)
    maxsteps=max;
end
step=round(max/maxsteps);
j=1;
for i=min:step:max
    set(handles.timeslider,'Value',i);
    update_plot(handles);
    M(j)=getframe;
    j=j+1;
    drawnow;
    handles=guidata(hObject);
    if (handles.interrupt==1)
        handles.interrupt==0;
        guidata(hObject,handles);
        break;
    end
end
f=figure;
movie(f,M,100);


% --- Executes on button press in abort.
function abort_Callback(hObject, eventdata, handles)
% hObject    handle to abort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.interrupt=1;
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function movieframes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to movieframes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function movieframes_Callback(hObject, eventdata, handles)
% hObject    handle to movieframes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of movieframes as text
%        str2double(get(hObject,'String')) returns contents of movieframes as a double




% --- Creates and returns a handle to the GUI figure. 
function h1 = test_export_LayoutFcn(policy)
% policy - create a new figure or use a singleton. 'new' or 'reuse'.

persistent hsingleton;
if strcmpi(policy, 'reuse') & ishandle(hsingleton)
    h1 = hsingleton;
    return;
end

h1 = figure(...
'Units','characters',...
'PaperUnits',get(0,'defaultfigurePaperUnits'),...
'Color',[0.831372549019608 0.815686274509804 0.784313725490196],...
'Colormap',[0 0 0.5625;0 0 0.625;0 0 0.6875;0 0 0.75;0 0 0.8125;0 0 0.875;0 0 0.9375;0 0 1;0 0.0625 1;0 0.125 1;0 0.1875 1;0 0.25 1;0 0.3125 1;0 0.375 1;0 0.4375 1;0 0.5 1;0 0.5625 1;0 0.625 1;0 0.6875 1;0 0.75 1;0 0.8125 1;0 0.875 1;0 0.9375 1;0 1 1;0.0625 1 1;0.125 1 0.9375;0.1875 1 0.875;0.25 1 0.8125;0.3125 1 0.75;0.375 1 0.6875;0.4375 1 0.625;0.5 1 0.5625;0.5625 1 0.5;0.625 1 0.4375;0.6875 1 0.375;0.75 1 0.3125;0.8125 1 0.25;0.875 1 0.1875;0.9375 1 0.125;1 1 0.0625;1 1 0;1 0.9375 0;1 0.875 0;1 0.8125 0;1 0.75 0;1 0.6875 0;1 0.625 0;1 0.5625 0;1 0.5 0;1 0.4375 0;1 0.375 0;1 0.3125 0;1 0.25 0;1 0.1875 0;1 0.125 0;1 0.0625 0;1 0 0;0.9375 0 0;0.875 0 0;0.8125 0 0;0.75 0 0;0.6875 0 0;0.625 0 0;0.5625 0 0],...
'DoubleBuffer','on',...
'IntegerHandle','off',...
'InvertHardcopy',get(0,'defaultfigureInvertHardcopy'),...
'MenuBar','none',...
'Name','test',...
'NumberTitle','off',...
'PaperPosition',get(0,'defaultfigurePaperPosition'),...
'PaperSize',[20.98404194812 29.67743169791],...
'PaperType',get(0,'defaultfigurePaperType'),...
'Position',[103.8 28.8990384615385 131.5 32.5625],...
'Renderer',get(0,'defaultfigureRenderer'),...
'RendererMode','manual',...
'HandleVisibility','callback',...
'Tag','figure1',...
'UserData',zeros(1,0));

setappdata(h1, 'GUIDEOptions', struct(...
'active_h', [], ...
'taginfo', struct(...
'figure', 2, ...
'slider', 2, ...
'edit', 4, ...
'axes', 2, ...
'popupmenu', 2, ...
'pushbutton', 4, ...
'text', 2, ...
'checkbox', 2), ...
'override', 0, ...
'release', 13, ...
'resize', 'none', ...
'accessibility', 'callback', ...
'mfile', 1, ...
'callbacks', 1, ...
'singleton', 1, ...
'syscolorfig', 1, ...
'blocking', 0, ...
'lastSavedFile', 'd:\home\levsa\modelica\pde\Mfiles\test.m'));


h2 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'BackgroundColor',[0.9 0.9 0.9],...
'Callback','test_export(''timeslider_Callback'',gcbo,[],guidata(gcbo))',...
'ListboxTop',0,...
'Min',1,...
'Position',[1.5 1 106.833333333333 1.3125],...
'String',{ '' },...
'Style','slider',...
'SliderStep',[1 1],...
'Value',1,...
'CreateFcn','test_export(''timeslider_CreateFcn'',gcbo,[],guidata(gcbo))',...
'Tag','timeslider');


h3 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'Callback','test_export(''timeedit_Callback'',gcbo,[],guidata(gcbo))',...
'ListboxTop',0,...
'Position',[109.833333333333 1 13.5 1.3125],...
'String','0',...
'Style','edit',...
'CreateFcn','test_export(''timeedit_CreateFcn'',gcbo,[],guidata(gcbo))',...
'Tag','timeedit');


h4 = axes(...
'Parent',h1,...
'Units','characters',...
'View',[-37.5 30],...
'CameraPosition',[-4.06571071756541 -5.45015005218426 4.83012701892219],...
'CameraPositionMode',get(0,'defaultaxesCameraPositionMode'),...
'Color',get(0,'defaultaxesColor'),...
'ColorOrder',get(0,'defaultaxesColorOrder'),...
'Position',[28.1666666666667 3.5 95.1666666666667 26.9375],...
'XColor',get(0,'defaultaxesXColor'),...
'YColor',get(0,'defaultaxesYColor'),...
'ZColor',get(0,'defaultaxesZColor'),...
'ZLim',get(0,'defaultaxesZLim'),...
'ZLimMode','manual',...
'Tag','axes');


h5 = get(h4,'title');

set(h5,...
'Parent',h4,...
'Color',[0 0 0],...
'HorizontalAlignment','center',...
'Position',[0.295988736157198 0.23412734461466 1.6339266825406],...
'VerticalAlignment','bottom',...
'HandleVisibility','off');

h6 = get(h4,'xlabel');

set(h6,...
'Parent',h4,...
'Color',[0 0 0],...
'Position',[-0.0013272934390649 -0.584945101961902 0.194924335417112],...
'VerticalAlignment','top',...
'HandleVisibility','off');

h7 = get(h4,'ylabel');

set(h7,...
'Parent',h4,...
'Color',[0 0 0],...
'HorizontalAlignment','right',...
'Position',[-0.525415166935256 -0.166757900563843 0.216965946861017],...
'VerticalAlignment','top',...
'HandleVisibility','off');

h8 = get(h4,'zlabel');

set(h8,...
'Parent',h4,...
'Color',[0 0 0],...
'HorizontalAlignment','center',...
'Position',[-0.575665587379589 0.41717529092598 0.966380735953776],...
'Rotation',90,...
'VerticalAlignment','bottom',...
'HandleVisibility','off');

h9 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'Callback','test_export(''varpopup_Callback'',gcbo,[],guidata(gcbo))',...
'ListboxTop',0,...
'Position',[1.5 28.5 21.8333333333333 1.9375],...
'String','Variables',...
'Style','popupmenu',...
'Value',1,...
'CreateFcn','test_export(''varpopup_CreateFcn'',gcbo,[],guidata(gcbo))',...
'Tag','varpopup');


h10 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'Callback','test_export(''viewchange_Callback'',gcbo,[],guidata(gcbo))',...
'ListboxTop',0,...
'Position',[1.5 4.125 13.3333333333333 1.5],...
'String','Rotate view',...
'Style','togglebutton',...
'Tag','viewchange');


h11 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'Callback','test_export(''zrange_Callback'',gcbo,[],guidata(gcbo))',...
'ListboxTop',0,...
'Position',[1.5 8.1875 13.5 1.3125],...
'String','[ 0 1 ]',...
'Style','edit',...
'CreateFcn','test_export(''zrange_CreateFcn'',gcbo,[],guidata(gcbo))',...
'Tag','zrange');


h12 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'ListboxTop',0,...
'Position',[1.5 10.0625 13.5 1.3125],...
'String','Z Range:',...
'Style','text',...
'Tag','text1');


h13 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'Callback','test_export(''autoscale_Callback'',gcbo,[],guidata(gcbo))',...
'ListboxTop',0,...
'Position',[1.5 6.125 13.5 1.3125],...
'String','Autoscale',...
'Style','checkbox',...
'Tag','autoscale');


h14 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'Callback','test_export(''movie_Callback'',gcbo,[],guidata(gcbo))',...
'ListboxTop',0,...
'Position',[1.4 13.5384615384615 13.2 1.46153846153846],...
'String','Movie',...
'Tag','movie');


h15 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'Callback','test_export(''abort_Callback'',gcbo,[],guidata(gcbo))',...
'ListboxTop',0,...
'Position',[1.4 11.4615384615385 13.2 1.76923076923077],...
'String','Abort movie',...
'Tag','abort');


h16 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'Callback','test_export(''movieframes_Callback'',gcbo,[],guidata(gcbo))',...
'ListboxTop',0,...
'Position',[15.8 13.4615384615385 9.8 1.61538461538462],...
'String',{ 'Edit Text' },...
'Style','edit',...
'CreateFcn','test_export(''movieframes_CreateFcn'',gcbo,[],guidata(gcbo))',...
'Tag','movieframes');



hsingleton = h1;


% --- Handles default GUIDE GUI creation and callback dispatch
function varargout = gui_mainfcn(gui_State, varargin)


%   GUI_MAINFCN provides these command line APIs for dealing with GUIs
%
%      TEST_EXPORT, by itself, creates a new TEST_EXPORT or raises the existing
%      singleton*.
%
%      H = TEST_EXPORT returns the handle to a new TEST_EXPORT or the handle to
%      the existing singleton*.
%
%      TEST_EXPORT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TEST_EXPORT.M with the given input arguments.
%
%      TEST_EXPORT('Property','Value',...) creates a new TEST_EXPORT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before untitled_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to untitled_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".

%   Copyright 1984-2002 The MathWorks, Inc.
%   $Revision$ $Date$

gui_StateFields =  {'gui_Name'
                    'gui_Singleton'
                    'gui_OpeningFcn'
                    'gui_OutputFcn'
                    'gui_LayoutFcn'
                    'gui_Callback'};
gui_Mfile = '';
for i=1:length(gui_StateFields)
    if ~isfield(gui_State, gui_StateFields{i})
        error('Could not find field %s in the gui_State struct in GUI M-file %s', gui_StateFields{i}, gui_Mfile);        
    elseif isequal(gui_StateFields{i}, 'gui_Name')
        gui_Mfile = [getfield(gui_State, gui_StateFields{i}), '.m'];
    end
end

numargin = length(varargin);

if numargin == 0
    % TEST_EXPORT
    % create the GUI
    gui_Create = 1;
elseif numargin > 3 & ischar(varargin{1}) & ishandle(varargin{2})
    % TEST_EXPORT('CALLBACK',hObject,eventData,handles,...)
    gui_Create = 0;
else
    % TEST_EXPORT(...)
    % create the GUI and hand varargin to the openingfcn
    gui_Create = 1;
end

if gui_Create == 0
    varargin{1} = gui_State.gui_Callback;
    if nargout
        [varargout{1:nargout}] = feval(varargin{:});
    else
        feval(varargin{:});
    end
else
    if gui_State.gui_Singleton
        gui_SingletonOpt = 'reuse';
    else
        gui_SingletonOpt = 'new';
    end
    
    % Open fig file with stored settings.  Note: This executes all component
    % specific CreateFunctions with an empty HANDLES structure.
    
    % Do feval on layout code in m-file if it exists
    if ~isempty(gui_State.gui_LayoutFcn)
        gui_hFigure = feval(gui_State.gui_LayoutFcn, gui_SingletonOpt);
    else
        gui_hFigure = local_openfig(gui_State.gui_Name, gui_SingletonOpt);            
        % If the figure has InGUIInitialization it was not completely created
        % on the last pass.  Delete this handle and try again.
        if isappdata(gui_hFigure, 'InGUIInitialization')
            delete(gui_hFigure);
            gui_hFigure = local_openfig(gui_State.gui_Name, gui_SingletonOpt);            
        end
    end
    
    % Set flag to indicate starting GUI initialization
    setappdata(gui_hFigure,'InGUIInitialization',1);

    % Fetch GUIDE Application options
    gui_Options = getappdata(gui_hFigure,'GUIDEOptions');
    
    if ~isappdata(gui_hFigure,'GUIOnScreen')
        % Adjust background color
        if gui_Options.syscolorfig 
            set(gui_hFigure,'Color', get(0,'DefaultUicontrolBackgroundColor'));
        end

        % Generate HANDLES structure and store with GUIDATA
        guidata(gui_hFigure, guihandles(gui_hFigure));
    end
    
    % If user specified 'Visible','off' in p/v pairs, don't make the figure
    % visible.
    gui_MakeVisible = 1;
    for ind=1:2:length(varargin)
        if length(varargin) == ind
            break;
        end
        len1 = min(length('visible'),length(varargin{ind}));
        len2 = min(length('off'),length(varargin{ind+1}));
        if ischar(varargin{ind}) & ischar(varargin{ind+1}) & ...
                strncmpi(varargin{ind},'visible',len1) & len2 > 1
            if strncmpi(varargin{ind+1},'off',len2)
                gui_MakeVisible = 0;
            elseif strncmpi(varargin{ind+1},'on',len2)
                gui_MakeVisible = 1;
            end
        end
    end
    
    % Check for figure param value pairs
    for index=1:2:length(varargin)
        if length(varargin) == index
            break;
        end
        try, set(gui_hFigure, varargin{index}, varargin{index+1}), catch, break, end
    end

    % If handle visibility is set to 'callback', turn it on until finished
    % with OpeningFcn
    gui_HandleVisibility = get(gui_hFigure,'HandleVisibility');
    if strcmp(gui_HandleVisibility, 'callback')
        set(gui_hFigure,'HandleVisibility', 'on');
    end
    
    feval(gui_State.gui_OpeningFcn, gui_hFigure, [], guidata(gui_hFigure), varargin{:});
    
    if ishandle(gui_hFigure)
        % Update handle visibility
        set(gui_hFigure,'HandleVisibility', gui_HandleVisibility);
        
        % Make figure visible
        if gui_MakeVisible
            set(gui_hFigure, 'Visible', 'on')
            if gui_Options.singleton 
                setappdata(gui_hFigure,'GUIOnScreen', 1);
            end
        end

        % Done with GUI initialization
        rmappdata(gui_hFigure,'InGUIInitialization');
    end
    
    % If handle visibility is set to 'callback', turn it on until finished with
    % OutputFcn
    if ishandle(gui_hFigure)
        gui_HandleVisibility = get(gui_hFigure,'HandleVisibility');
        if strcmp(gui_HandleVisibility, 'callback')
            set(gui_hFigure,'HandleVisibility', 'on');
        end
        gui_Handles = guidata(gui_hFigure);
    else
        gui_Handles = [];
    end
    
    if nargout
        [varargout{1:nargout}] = feval(gui_State.gui_OutputFcn, gui_hFigure, [], gui_Handles);
    else
        feval(gui_State.gui_OutputFcn, gui_hFigure, [], gui_Handles);
    end
    
    if ishandle(gui_hFigure)
        set(gui_hFigure,'HandleVisibility', gui_HandleVisibility);
    end
end    

function gui_hFigure = local_openfig(name, singleton)
if nargin('openfig') == 3 
    gui_hFigure = openfig(name, singleton, 'auto');
else
    % OPENFIG did not accept 3rd input argument until R13,
    % toggle default figure visible to prevent the figure
    % from showing up too soon.
    gui_OldDefaultVisible = get(0,'defaultFigureVisible');
    set(0,'defaultFigureVisible','off');
    gui_hFigure = openfig(name, singleton);
    set(0,'defaultFigureVisible',gui_OldDefaultVisible);
end

