function test_makevar()

TPMdata = 123123123;
%create dialog with variable list or 
            basevars = evalin('base','who'); %variables in base
            
            varname = 'TPMdata';
            
            hDlg = dialog('Name','Specify Output Variable',...
                'units','characters',...
                'position',[0,0,50,30],...
                'CloseRequestFcn',@CancelCB);
            movegui(hDlg,'center');
            
            
            
            hOK = uicontrol('parent',hDlg,...
                             'style','pushbutton',...
                             'units','characters',...
                             'position',[0,0,24.5,2],...
                             'string','OK',...
                             'Callback',@OKCB);
            hCancel = uicontrol('parent',hDlg,...
                             'style','pushbutton',...
                             'units','characters',...
                             'position',[25.5,0,24.5,2],...
                             'string','Cancel',...
                             'Callback',@CancelCB);
                         
            uicontrol('parent',hDlg,...
                'style','text',...
                'units','characters',...
                'position',[0,2.4,10,1.2],...
                'string','Name:');
            
            hStr = uicontrol('parent',hDlg,...
                             'style','edit',...
                             'units','characters',...
                             'String',varname,...
                             'position',[10.5,2,39.5,2],...
                             'Callback',@EditCB);
            
            hLst = uicontrol('parent',hDlg,...
                        'style','listbox',...
                        'units','characters',...
                        'position',[0,5,50,30-5],...
                        'String',basevars,...
                        'max',1,'min',0,...
                        'Callback',@ListCB);
            
            uiwait(hDlg);
            
            if ~isempty(varname)
            	assignin('base',varname,TPMdata);
            end
            
    function OKCB(~,~)
        varname = get(hStr,'string');
        delete(hDlg);
    end
            
    function CancelCB(~,~)
        varname = [];
        delete(hDlg);
    end
    
    function ListCB(~,~)
        set(hStr,'String',basevars{get(hLst,'Value')});
    end
    function EditCB(~,~)
        %set(hLst,'Value',[]);
    end
end