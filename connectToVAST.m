addpath(vastControlPath);

if exist('vast', 'var')
   try
       vast.disconnect;
   catch
       clear vast
   end
end

% Connect to VAST at address 127.0.01 and the port
% specified by the user
assignin('base', 'vast', VASTControlClass());
vastRes = vast.connect('127.0.0.1', port, 1000);

if (vastRes == 0)
    warndlg(strcat('Connecting to VAST at 127.0.0.1, port ', port, ' failed.', 'Error'));
else
    vastInfo = vast.getinfo();
    disp(vastInfo);
end

assignin('base', 'res', vastRes')