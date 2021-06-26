addpath(vastControlPath);

if exist('vast', 'var')
   try
       vast.disconnect;
   catch
       clear vast
   end
end

assignin('base', 'vast', VASTControlClass());
vastRes = vast.connect('127.0.0.1', port, 1000);

if (vastRes == 0)
    warndlg(strcat('Connecting to VAST at 127.0.0.1, port ', port, ' failed.', 'Error'));
else
    vastInfo = vast.getinfo();
    disp(vastInfo);
end

assignin('base', 'res', vastRes')